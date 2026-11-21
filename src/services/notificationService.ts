import * as Notifications from 'expo-notifications';
import { Platform } from 'react-native';
import { FamilyMember } from '../types';

Notifications.setNotificationHandler({
  handleNotification: async () => ({
    shouldShowAlert: true,
    shouldPlaySound: true,
    shouldSetBadge: true,
    shouldShowBanner: true,
    shouldShowList: true,
  }),
});

export async function requestNotificationPermissions(): Promise<boolean> {
  if (Platform.OS === 'web') return false;

  const { status: existingStatus } = await Notifications.getPermissionsAsync();
  let finalStatus = existingStatus;

  if (existingStatus !== 'granted') {
    const { status } = await Notifications.requestPermissionsAsync();
    finalStatus = status;
  }

  return finalStatus === 'granted';
}

export function calculateDaysUntilBirthday(birthDateStr: string): { daysRemaining: number; nextAge: number; nextDate: Date } {
  const [yearStr, monthStr, dayStr] = birthDateStr.split('-');
  const birthYear = parseInt(yearStr, 10);
  const birthMonth = parseInt(monthStr, 10) - 1; // 0-indexed
  const birthDay = parseInt(dayStr, 10);

  const now = new Date();
  const currentYear = now.getFullYear();

  let nextBirthday = new Date(currentYear, birthMonth, birthDay, 9, 0, 0);

  // If birthday already passed this year, next one is next year
  if (nextBirthday.getTime() < now.getTime()) {
    nextBirthday = new Date(currentYear + 1, birthMonth, birthDay, 9, 0, 0);
  }

  const diffTime = nextBirthday.getTime() - now.getTime();
  const daysRemaining = Math.ceil(diffTime / (1000 * 60 * 60 * 24));
  const nextAge = nextBirthday.getFullYear() - birthYear;

  return { daysRemaining, nextAge, nextDate: nextBirthday };
}

export async function scheduleBirthdayNotifications(members: FamilyMember[]) {
  if (Platform.OS === 'web') return;

  const hasPermission = await requestNotificationPermissions();
  if (!hasPermission) return;

  // Cancel previous birthday alerts to avoid duplicates
  await Notifications.cancelAllScheduledNotificationsAsync();

  for (const member of members) {
    const { daysRemaining, nextAge, nextDate } = calculateDaysUntilBirthday(member.birthDate);

    // Notification Jour J (le jour de l'anniversaire à 9h00)
    const triggerDate = new Date(nextDate);
    triggerDate.setHours(9, 0, 0, 0);

    if (triggerDate.getTime() > Date.now()) {
      await Notifications.scheduleNotificationAsync({
        content: {
          title: `🎂 C'est l'anniversaire de ${member.name} !`,
          body: `Aujourd'hui ${member.name} fête ses ${nextAge} ans ! N'oublie pas de lui envoyer un petit mot ou de l'appeler.`,
          sound: true,
          data: { memberId: member.id },
        },
        trigger: {
          type: Notifications.SchedulableTriggerInputTypes.DATE,
          date: triggerDate,
        },
      });
    }

    // Notification J-7 (7 jours avant pour penser au cadeau)
    const jMinus7Date = new Date(nextDate.getTime() - 7 * 24 * 60 * 60 * 1000);
    jMinus7Date.setHours(9, 0, 0, 0);

    if (jMinus7Date.getTime() > Date.now()) {
      await Notifications.scheduleNotificationAsync({
        content: {
          title: `🎁 Anniversaire de ${member.name} dans 7 jours`,
          body: `${member.name} aura ${nextAge} ans le ${nextDate.toLocaleDateString('fr-FR', { day: 'numeric', month: 'long' })}. As-tu pensé à son cadeau ?`,
          sound: true,
          data: { memberId: member.id },
        },
        trigger: {
          type: Notifications.SchedulableTriggerInputTypes.DATE,
          date: jMinus7Date,
        },
      });
    }
  }
}

export async function sendInstantTestNotification(memberName: string, age: number) {
  if (Platform.OS === 'web') return;
  await requestNotificationPermissions();

  await Notifications.scheduleNotificationAsync({
    content: {
      title: `🎂 Anniversaire de ${memberName} (Test Alerte)`,
      body: `Alerte Tribu : C'est l'anniversaire de ${memberName} (${age} ans) ! Ouvre l'app pour lui souhaiter en 1 clic.`,
      sound: true,
    },
    trigger: null, // Send immediately
  });
}
