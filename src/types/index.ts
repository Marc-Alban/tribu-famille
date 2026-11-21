export interface FamilyMember {
  id: string;
  name: string;
  role: string; // "Papa", "Mémère", "Tonton", "Cousin", etc.
  birthDate: string; // ISO format YYYY-MM-DD
  avatarUrl?: string;
  phone?: string;
  isChild?: boolean;
  parentId?: string;
  createdAt: string;
}

export interface FamilyEvent {
  id: string;
  title: string;
  date: string; // YYYY-MM-DD
  location?: string;
  description?: string;
  items: EventTaskItem[];
}

export interface EventTaskItem {
  id: string;
  title: string;
  category: 'aperitif' | 'entree' | 'plat' | 'dessert' | 'boisson' | 'autre';
  assignedToName?: string;
  isCompleted: boolean;
}

export interface PhotoPost {
  id: string;
  authorName: string;
  caption: string;
  imageUrl: string;
  createdAt: string;
  likesCount: number;
}

export interface FamilyTribe {
  id: string;
  name: string;
  code: string;
  members: FamilyMember[];
}
