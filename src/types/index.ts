export interface FamilyMember {
  id: string;
  name: string;
  role: string; // "Papa", "Mémère", "Tonton", "Cousin", etc.
  birthDate: string; // ISO format YYYY-MM-DD
  avatarUrl?: string;
  phone?: string;
  allergies?: string;
  bloodType?: string;
  isChild?: boolean;
  parentId?: string;
  wishlist?: WishlistItem[];
  createdAt: string;
}

export interface WishlistItem {
  id: string;
  title: string;
  priceEstimate?: string;
  url?: string;
  isReservedBy?: string; // Nom de la personne qui a réservé en secret
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

export interface ShoppingItem {
  id: string;
  name: string;
  category: 'frais' | 'fruits-legumes' | 'epicerie' | 'boissons' | 'bebe' | 'maison';
  addedByName: string;
  isBought: boolean;
  quantity?: string;
}

export interface FamilyQuote {
  id: string;
  quoteText: string;
  authorName: string; // Qui a dit ça ? (ex: "Lucas (4 ans)")
  context?: string; // Circonstance (ex: "Au repas de Noël devant la bûche")
  date: string;
  likesCount: number;
}

export interface EmergencyContact {
  id: string;
  title: string; // "Médecin traitant", "Pédiatre", "Code Wi-Fi Maison", "Plombier", etc.
  detail: string; // Numéro ou code
  category: 'sante' | 'pratique' | 'urgence';
}

export interface PhotoPost {
  id: string;
  authorName: string;
  caption: string;
  imageUrl: string;
  createdAt: string;
  likesCount: number;
}
