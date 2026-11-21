import AsyncStorage from '@react-native-async-storage/async-storage';
import {
  FamilyMember,
  FamilyEvent,
  PhotoPost,
  ShoppingItem,
  FamilyQuote,
  EmergencyContact,
} from '../types';

const STORAGE_KEYS = {
  CURRENT_USER: '@tribu_current_user',
  MEMBERS: '@tribu_members',
  EVENTS: '@tribu_events',
  POSTS: '@tribu_posts',
  SHOPPING: '@tribu_shopping',
  QUOTES: '@tribu_quotes',
  CONTACTS: '@tribu_contacts',
};

const INITIAL_MEMBERS: FamilyMember[] = [
  {
    id: '1',
    name: 'Mémère Denise',
    role: 'Grand-mère',
    birthDate: '1942-12-05',
    phone: '0612345678',
    allergies: 'Aucune',
    bloodType: 'O+',
    isChild: false,
    wishlist: [
      { id: 'w-1', title: 'Nouvelles pantoufles chaudes (pointure 38)', priceEstimate: '35€' },
      { id: 'w-2', title: 'Boîte de chocolats fins pralinés', priceEstimate: '20€', isReservedBy: 'Marc-Alban' },
    ],
    createdAt: new Date().toISOString(),
  },
  {
    id: '2',
    name: 'Papa',
    role: 'Père',
    birthDate: '1968-04-18',
    phone: '0698765432',
    bloodType: 'A+',
    isChild: false,
    wishlist: [
      { id: 'w-3', title: 'Livre histoire de la bourse & finance', priceEstimate: '25€' },
      { id: 'w-4', title: 'Set de couteaux de cuisine pro', priceEstimate: '80€' },
    ],
    createdAt: new Date().toISOString(),
  },
  {
    id: '3',
    name: 'Maman',
    role: 'Mère',
    birthDate: '1970-09-22',
    phone: '0611223344',
    bloodType: 'O+',
    isChild: false,
    wishlist: [
      { id: 'w-5', title: 'Écharpe en cachemire beige', priceEstimate: '60€', isReservedBy: 'Papa' },
    ],
    createdAt: new Date().toISOString(),
  },
  {
    id: '4',
    name: 'Lucas',
    role: 'Fils / Petit-fils',
    birthDate: '2016-12-14',
    allergies: 'Arachides (attention)',
    isChild: true,
    parentId: '2',
    wishlist: [
      { id: 'w-6', title: 'Lego Star Wars Vaisseau X-Wing', priceEstimate: '49€' },
      { id: 'w-7', title: 'Jeu Nintendo Switch Pokémon', priceEstimate: '45€', isReservedBy: 'Mémère Denise' },
    ],
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

const INITIAL_SHOPPING: ShoppingItem[] = [
  { id: 's-1', name: 'Pain frais de campagne (2 boules)', category: 'epicerie', addedByName: 'Mémère Denise', isBought: false, quantity: '2' },
  { id: 's-2', name: 'Lait entier bio & Beurre doux', category: 'frais', addedByName: 'Maman', isBought: true, quantity: '6L + 1 plaquette' },
  { id: 's-3', name: 'Clémentines de Corse & Pommes', category: 'fruits-legumes', addedByName: 'Marc-Alban', isBought: false, quantity: '2 kg' },
  { id: 's-4', name: 'Paquet de couches taille 4', category: 'bebe', addedByName: 'Maman', isBought: false },
  { id: 's-5', name: 'Café en grains espresso', category: 'epicerie', addedByName: 'Papa', isBought: true },
];

const INITIAL_QUOTES: FamilyQuote[] = [
  {
    id: 'q-1',
    quoteText: "Mémère, est-ce que le Père Noël il a aussi des lunettes pour voir s'il y a du verglas ?",
    authorName: 'Lucas (5 ans)',
    context: 'En regardant la météo avec Mémère',
    date: 'Décembre 2021',
    likesCount: 8,
  },
  {
    id: 'q-2',
    quoteText: "La bourse c'est simple : tu achètes bas et tu vends haut... sauf quand c'est l'heure de passer à table !",
    authorName: 'Papa',
    context: 'Pendant le déjeuner du dimanche',
    date: 'Octobre 2026',
    likesCount: 6,
  },
];

const INITIAL_CONTACTS: EmergencyContact[] = [
  { id: 'c-1', title: 'Médecin traitant de famille (Dr. Martin)', detail: '02 35 12 34 56', category: 'sante' },
  { id: 'c-2', title: 'Pédiatre de Lucas (Dr. Leroy)', detail: '02 35 78 90 12', category: 'sante' },
  { id: 'c-3', title: 'Code Wi-Fi Maison Mémère', detail: 'FamilleMillet2026!', category: 'pratique' },
  { id: 'c-4', title: 'SAMU / Urgence Médicale', detail: '15', category: 'urgence' },
  { id: 'c-5', title: 'Pharmacie de garde', detail: '3237', category: 'urgence' },
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

// MEMBERS
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

// EVENTS
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

// SHOPPING LIST
export async function getStoredShopping(): Promise<ShoppingItem[]> {
  try {
    const json = await AsyncStorage.getItem(STORAGE_KEYS.SHOPPING);
    if (!json) {
      await AsyncStorage.setItem(STORAGE_KEYS.SHOPPING, JSON.stringify(INITIAL_SHOPPING));
      return INITIAL_SHOPPING;
    }
    return JSON.parse(json);
  } catch {
    return INITIAL_SHOPPING;
  }
}

export async function saveStoredShopping(items: ShoppingItem[]): Promise<void> {
  await AsyncStorage.setItem(STORAGE_KEYS.SHOPPING, JSON.stringify(items));
}

// FAMILY QUOTES
export async function getStoredQuotes(): Promise<FamilyQuote[]> {
  try {
    const json = await AsyncStorage.getItem(STORAGE_KEYS.QUOTES);
    if (!json) {
      await AsyncStorage.setItem(STORAGE_KEYS.QUOTES, JSON.stringify(INITIAL_QUOTES));
      return INITIAL_QUOTES;
    }
    return JSON.parse(json);
  } catch {
    return INITIAL_QUOTES;
  }
}

export async function saveStoredQuotes(quotes: FamilyQuote[]): Promise<void> {
  await AsyncStorage.setItem(STORAGE_KEYS.QUOTES, JSON.stringify(quotes));
}

// CONTACTS & HEALTH
export async function getStoredContacts(): Promise<EmergencyContact[]> {
  try {
    const json = await AsyncStorage.getItem(STORAGE_KEYS.CONTACTS);
    if (!json) {
      await AsyncStorage.setItem(STORAGE_KEYS.CONTACTS, JSON.stringify(INITIAL_CONTACTS));
      return INITIAL_CONTACTS;
    }
    return JSON.parse(json);
  } catch {
    return INITIAL_CONTACTS;
  }
}

export async function saveStoredContacts(contacts: EmergencyContact[]): Promise<void> {
  await AsyncStorage.setItem(STORAGE_KEYS.CONTACTS, JSON.stringify(contacts));
}

// POSTS
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
