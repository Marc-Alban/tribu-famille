import AsyncStorage from '@react-native-async-storage/async-storage';
import { FamilyMember, FamilyEvent, PhotoPost, FamilyTribe } from '../types';

const STORAGE_KEYS = {
  CURRENT_USER: '@tribu_current_user',
  CURRENT_TRIBE: '@tribu_info',
  MEMBERS: '@tribu_members',
  EVENTS: '@tribu_events',
  POSTS: '@tribu_posts',
};

// Données initiales d'exemple pour une expérience immédiate
const INITIAL_MEMBERS: FamilyMember[] = [
  {
    id: '1',
    name: 'Mémère Denise',
    role: 'Grand-mère',
    birthDate: '1942-12-05',
    phone: '0612345678',
    isChild: false,
    createdAt: new Date().toISOString(),
  },
  {
    id: '2',
    name: 'Papa',
    role: 'Père',
    birthDate: '1968-04-18',
    phone: '0698765432',
    isChild: false,
    createdAt: new Date().toISOString(),
  },
  {
    id: '3',
    name: 'Maman',
    role: 'Mère',
    birthDate: '1970-09-22',
    phone: '0611223344',
    isChild: false,
    createdAt: new Date().toISOString(),
  },
  {
    id: '4',
    name: 'Lucas',
    role: 'Fils / Petit-fils',
    birthDate: '2016-12-14',
    isChild: true,
    parentId: '2',
    createdAt: new Date().toISOString(),
  },
];

const INITIAL_EVENTS: FamilyEvent[] = [
  {
    id: 'event-noel-2026',
    title: 'Grand Réveillon de Noël 2026 🎄',
    date: '2026-12-24',
    location: 'Chez Mémère (19h30)',
    description: 'Chacun ramène sa spécialité ! Pensez à cocher ce que vous apportez.',
    items: [
      { id: 'item-1', title: 'Apéritif & Toasts de Saumon', category: 'aperitif', assignedToName: 'Marc-Alban', isCompleted: true },
      { id: 'item-2', title: 'Foie Gras maison & Pain d’épices', category: 'entree', assignedToName: 'Papa', isCompleted: true },
      { id: 'item-3', title: 'Chapon rôti & Marrons', category: 'plat', assignedToName: 'Mémère Denise', isCompleted: true },
      { id: 'item-4', title: 'Plateau de 5 fromages affinés', category: 'plat', assignedToName: undefined, isCompleted: false },
      { id: 'item-5', title: 'Bûche Pâtissière Chocolat-Praliné', category: 'dessert', assignedToName: 'Maman', isCompleted: true },
      { id: 'item-6', title: 'Champagne & Vins de fête', category: 'boisson', assignedToName: undefined, isCompleted: false },
      { id: 'item-7', title: 'Chocolats & Clémentines pour les enfants', category: 'autre', assignedToName: undefined, isCompleted: false },
    ],
  },
];

const INITIAL_POSTS: PhotoPost[] = [
  {
    id: 'post-1',
    authorName: 'Marc-Alban',
    caption: 'Super dimanche en famille ! Mémère était en pleine forme ❤️',
    imageUrl: 'https://images.unsplash.com/photo-1511895426328-dc8714191300?auto=format&fit=crop&w=800&q=80',
    createdAt: 'Il y a 2 jours',
    likesCount: 5,
  },
];

export async function getStoredMembers(): Promise<FamilyMember[]> {
  try {
    const json = await AsyncStorage.getItem(STORAGE_KEYS.MEMBERS);
    if (!json) {
      await AsyncStorage.setItem(STORAGE_KEYS.MEMBERS, JSON.stringify(INITIAL_MEMBERS));
      return INITIAL_MEMBERS;
    }
    return JSON.parse(json);
  } catch {
    return INITIAL_MEMBERS;
  }
}

export async function saveStoredMembers(members: FamilyMember[]): Promise<void> {
  await AsyncStorage.setItem(STORAGE_KEYS.MEMBERS, JSON.stringify(members));
}

export async function addMemberToTribe(member: Omit<FamilyMember, 'id' | 'createdAt'>): Promise<FamilyMember[]> {
  const current = await getStoredMembers();
  const newMember: FamilyMember = {
    ...member,
    id: 'member_' + Date.now(),
    createdAt: new Date().toISOString(),
  };
  const updated = [...current, newMember];
  await saveStoredMembers(updated);
  return updated;
}

export async function getStoredEvents(): Promise<FamilyEvent[]> {
  try {
    const json = await AsyncStorage.getItem(STORAGE_KEYS.EVENTS);
    if (!json) {
      await AsyncStorage.setItem(STORAGE_KEYS.EVENTS, JSON.stringify(INITIAL_EVENTS));
      return INITIAL_EVENTS;
    }
    return JSON.parse(json);
  } catch {
    return INITIAL_EVENTS;
  }
}

export async function saveStoredEvents(events: FamilyEvent[]): Promise<void> {
  await AsyncStorage.setItem(STORAGE_KEYS.EVENTS, JSON.stringify(events));
}

export async function getStoredPosts(): Promise<PhotoPost[]> {
  try {
    const json = await AsyncStorage.getItem(STORAGE_KEYS.POSTS);
    if (!json) {
      await AsyncStorage.setItem(STORAGE_KEYS.POSTS, JSON.stringify(INITIAL_POSTS));
      return INITIAL_POSTS;
    }
    return JSON.parse(json);
  } catch {
    return INITIAL_POSTS;
  }
}

export async function saveStoredPosts(posts: PhotoPost[]): Promise<void> {
  await AsyncStorage.setItem(STORAGE_KEYS.POSTS, JSON.stringify(posts));
}

export async function getCurrentUser(): Promise<FamilyMember | null> {
  try {
    const json = await AsyncStorage.getItem(STORAGE_KEYS.CURRENT_USER);
    return json ? JSON.parse(json) : null;
  } catch {
    return null;
  }
}

export async function saveCurrentUser(user: FamilyMember): Promise<void> {
  await AsyncStorage.setItem(STORAGE_KEYS.CURRENT_USER, JSON.stringify(user));
}
