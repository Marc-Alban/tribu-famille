import jwt
import time
import urllib.request
import json
import os
import sys
import base64

def get_private_key():
    if "ASC_PRIVATE_KEY_BASE64" in os.environ and os.environ["ASC_PRIVATE_KEY_BASE64"]:
        return base64.b64decode(os.environ["ASC_PRIVATE_KEY_BASE64"]).decode("utf-8")
    key_path = os.environ.get("ASC_PRIVATE_KEY_PATH", "AuthKey.p8")
    with open(key_path, "r") as f:
        return f.read()

def distribute(bundle_id, key_id=None, issuer_id=None, max_wait_minutes=25):
    key_id = key_id or os.environ.get("ASC_KEY_ID")
    issuer_id = issuer_id or os.environ.get("ASC_ISSUER_ID")
    private_key_content = get_private_key()

    def get_token():
        payload = {"iss": issuer_id, "exp": int(time.time()) + 1200, "aud": "appstoreconnect-v1"}
        return jwt.encode(payload, private_key_content, algorithm="ES256", headers={"kid": key_id})

    def api_call(url, method="GET", body=None):
        headers = {"Authorization": f"Bearer {get_token()}", "Content-Type": "application/json"}
        data = json.dumps(body).encode("utf-8") if body else None
        req = urllib.request.Request(url, data=data, headers=headers, method=method)
        try:
            with urllib.request.urlopen(req) as resp:
                content = resp.read().decode("utf-8")
                return json.loads(content) if content else {}
        except urllib.error.HTTPError as e:
            err = e.read().decode("utf-8")
            return {"error": e.code, "detail": err}

    print(f"Finding App with Bundle ID: {bundle_id}...")
    apps = api_call(f"https://api.appstoreconnect.apple.com/v1/apps?filter[bundleId]={bundle_id}")
    if not apps.get("data"):
        print(f"App with bundle ID {bundle_id} not found!")
        return False

    app_id = apps["data"][0]["id"]
    app_name = apps["data"][0]["attributes"]["name"]
    print(f"Found App: {app_name} (ID: {app_id})")

    start_time = time.time()
    latest_build = None

    print(f"Waiting for latest build of {app_name} to become VALID (timeout {max_wait_minutes}m)...")
    while time.time() - start_time < max_wait_minutes * 60:
        builds_resp = api_call(f"https://api.appstoreconnect.apple.com/v1/builds?filter[app]={app_id}&sort=-uploadedDate&limit=1")
        if builds_resp.get("data") and len(builds_resp["data"]) > 0:
            latest_build = builds_resp["data"][0]
            build_id = latest_build["id"]
            version = latest_build["attributes"]["version"]
            state = latest_build["attributes"]["processingState"]
            print(f"[{time.strftime('%H:%M:%S')}] Latest build: v{version} (ID: {build_id}, State: {state})")
            if state == "VALID":
                break
            elif state in ["FAILED", "INVALID"]:
                print(f"Build failed processing with state: {state}")
                return False
        time.sleep(20)

    if not latest_build or latest_build["attributes"]["processingState"] != "VALID":
        print("Timeout waiting for build to become VALID.")
        return False

    build_id = latest_build["id"]
    version = latest_build["attributes"]["version"]
    print(f"Processing VALID build v{version} (ID: {build_id})...")

    # 1. Enable autoNotify on build
    print("Enabling autoNotifyEnabled on build...")
    api_call(f"https://api.appstoreconnect.apple.com/v1/buildBetaDetails/{build_id}", method="PATCH", body={
        "data": {
            "type": "buildBetaDetails",
            "id": build_id,
            "attributes": {"autoNotifyEnabled": True}
        }
    })

    # 2. Attach build to all External Beta Groups
    groups = api_call(f"https://api.appstoreconnect.apple.com/v1/betaGroups?filter[app]={app_id}")
    for group in groups.get("data", []):
        is_internal = group["attributes"].get("isInternalGroup", False)
        g_id = group["id"]
        g_name = group["attributes"]["name"]
        if is_internal:
            print(f"Skipping internal group '{g_name}' (automatic access)")
            continue
        print(f"Attaching build v{version} to external group '{g_name}' ({g_id})...")
        link_res = api_call(f"https://api.appstoreconnect.apple.com/v1/betaGroups/{g_id}/relationships/builds", method="POST", body={
            "data": [{"type": "builds", "id": build_id}]
        })
        print(f"Attached to '{g_name}':", "OK" if "error" not in link_res else link_res)

    # 3. Check / Submit for Beta Review if not already submitted or approved
    sub_check = api_call(f"https://api.appstoreconnect.apple.com/v1/builds/{build_id}/betaAppReviewSubmission")
    if sub_check and sub_check.get("data"):
        rev_state = sub_check["data"]["attributes"].get("betaReviewState")
        print(f"Build v{version} review state: {rev_state}")
    else:
        print("Submitting for Apple Beta App Review...")
        sub_res = api_call("https://api.appstoreconnect.apple.com/v1/betaAppReviewSubmissions", method="POST", body={
            "data": {
                "type": "betaAppReviewSubmissions",
                "relationships": {
                    "build": {"data": {"type": "builds", "id": build_id}}
                }
            }
        })
        if "error" in sub_res:
            print("Beta review submission notice:", sub_res.get("detail", sub_res))
        else:
            print("Submitted successfully for Beta Review!")

    print(f"ALL DONE: Build v{version} of {app_name} is active on TestFlight with auto-notifications enabled!")
    return True

if __name__ == "__main__":
    bundle_id = sys.argv[1] if len(sys.argv) > 1 else os.environ.get("APP_BUNDLE_ID", "fr.tribufamille.app")
    distribute(bundle_id)
