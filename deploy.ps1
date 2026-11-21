Write-Host "Poussée des modifications vers GitHub pour déclencher le build Native iOS (SwiftUI)..." -ForegroundColor Cyan
git add .
git commit -m "build: trigger native ios testflight build via github actions"
git push origin main
