import React, { useState, useEffect } from 'react';
import {
  StyleSheet,
  Text,
  View,
  ScrollView,
  TouchableOpacity,
  TextInput,
  Modal,
  SafeAreaView,
  StatusBar,
  Alert,
  Linking,
  Platform,
} from 'react-native';
import {
  Calendar,
  Gift,
  Users,
  CheckCircle2,
  Circle,
  Plus,
  Bell,
  Heart,
  Share2,
  Sparkles,
  Phone,
  MessageCircle,
  X,
  Camera,
  ShoppingCart,
  Smile,
  ShieldCheck,
  Check,
  Lock,
  Wifi,
} from 'lucide-react-native';

import {
  FamilyMember,
  FamilyEvent,
  EventTaskItem,
  PhotoPost,
  ShoppingItem,
  FamilyQuote,
  EmergencyContact,
} from './src/types';
import {
  getStoredMembers,
  addMemberToTribe,
  saveStoredMembers,
  getStoredEvents,
  saveStoredEvents,
  getStoredPosts,
  saveStoredPosts,
  getStoredShopping,
  saveStoredShopping,
  getStoredQuotes,
  saveStoredQuotes,
  getStoredContacts,
} from './src/services/storage';
import {
  calculateDaysUntilBirthday,
  scheduleBirthdayNotifications,
  sendInstantTestNotification,
  requestNotificationPermissions,
} from './src/services/notificationService';

export default function App() {
  const [activeTab, setActiveTab] = useState<'birthdays' | 'events' | 'shopping' | 'wishlist' | 'tribu'>('birthdays');
  const [members, setMembers] = useState<FamilyMember[]>([]);
  const [events, setEvents] = useState<FamilyEvent[]>([]);
  const [posts, setPosts] = useState<PhotoPost[]>([]);
  const [shoppingItems, setShoppingItems] = useState<ShoppingItem[]>([]);
  const [quotes, setQuotes] = useState<FamilyQuote[]>([]);
  const [contacts, setContacts] = useState<EmergencyContact[]>([]);

  // Modals
  const [showAddMemberModal, setShowAddMemberModal] = useState(false);
  const [showAddItemModal, setShowAddItemModal] = useState(false);
  const [showAddShoppingModal, setShowAddShoppingModal] = useState(false);
  const [showAddQuoteModal, setShowAddQuoteModal] = useState(false);
  const [showPostModal, setShowPostModal] = useState(false);
  const [isMemereMode, setIsMemereMode] = useState(false);

  // New Member Form
  const [newName, setNewName] = useState('');
  const [newRole, setNewRole] = useState('Membre');
  const [newBirthDate, setNewBirthDate] = useState('1990-01-01');
  const [newPhone, setNewPhone] = useState('');
  const [newAllergies, setNewAllergies] = useState('');
  const [isChild, setIsChild] = useState(false);

  // New Event Item Form
  const [newItemTitle, setNewItemTitle] = useState('');
  const [newItemCategory, setNewItemCategory] = useState<'aperitif' | 'entree' | 'plat' | 'dessert' | 'boisson' | 'autre'>('plat');

  // New Shopping Item Form
  const [newShoppingName, setNewShoppingName] = useState('');
  const [newShoppingCategory, setNewShoppingCategory] = useState<'frais' | 'fruits-legumes' | 'epicerie' | 'boissons' | 'bebe' | 'maison'>('epicerie');
  const [newShoppingQty, setNewShoppingQty] = useState('');

  // New Quote Form
  const [newQuoteText, setNewQuoteText] = useState('');
  const [newQuoteAuthor, setNewQuoteAuthor] = useState('');
  const [newQuoteContext, setNewQuoteContext] = useState('');

  // New Post Form
  const [newPostCaption, setNewPostCaption] = useState('');
  const [newPostAuthor, setNewPostAuthor] = useState('Marc-Alban');

  useEffect(() => {
    loadData();
    requestNotificationPermissions();
  }, []);

  async function loadData() {
    const loadedMembers = await getStoredMembers();
    const loadedEvents = await getStoredEvents();
    const loadedPosts = await getStoredPosts();
    const loadedShopping = await getStoredShopping();
    const loadedQuotes = await getStoredQuotes();
    const loadedContacts = await getStoredContacts();

    setMembers(loadedMembers);
    setEvents(loadedEvents);
    setPosts(loadedPosts);
    setShoppingItems(loadedShopping);
    setQuotes(loadedQuotes);
    setContacts(loadedContacts);

    await scheduleBirthdayNotifications(loadedMembers);
  }

  // Trier les anniversaires par ordre du plus proche
  const sortedMembers = [...members].sort((a, b) => {
    const daysA = calculateDaysUntilBirthday(a.birthDate).daysRemaining;
    const daysB = calculateDaysUntilBirthday(b.birthDate).daysRemaining;
    return daysA - daysB;
  });

  const nextBirthdayMember = sortedMembers[0];
  const nextBirthdayStats = nextBirthdayMember
    ? calculateDaysUntilBirthday(nextBirthdayMember.birthDate)
    : null;

  async function handleAddMember() {
    if (!newName.trim()) {
      Alert.alert('Erreur', 'Veuillez saisir au moins un prénom.');
      return;
    }

    const updated = await addMemberToTribe({
      name: newName.trim(),
      role: newRole,
      birthDate: newBirthDate,
      phone: newPhone.trim() || undefined,
      allergies: newAllergies.trim() || undefined,
      isChild,
    });

    setMembers(updated);
    await scheduleBirthdayNotifications(updated);

    setShowAddMemberModal(false);
    setNewName('');
    setNewPhone('');
    setNewAllergies('');
    setIsChild(false);
    Alert.alert('Succès !', `${newName} a été ajouté(e) au calendrier de la Tribu.`);
  }

  async function handleToggleEventItem(eventId: string, itemId: string) {
    const updatedEvents = events.map((ev) => {
      if (ev.id === eventId) {
        return {
          ...ev,
          items: ev.items.map((it) => {
            if (it.id === itemId) {
              const willBeCompleted = !it.isCompleted;
              return {
                ...it,
                isCompleted: willBeCompleted,
                assignedToName: willBeCompleted ? it.assignedToName || 'Marc-Alban' : undefined,
              };
            }
            return it;
          }),
        };
      }
      return ev;
    });

    setEvents(updatedEvents);
    await saveStoredEvents(updatedEvents);
  }

  async function handleAddItemToEvent() {
    if (!newItemTitle.trim()) return;

    const currentEvent = events[0];
    if (!currentEvent) return;

    const newItem: EventTaskItem = {
      id: 'item_' + Date.now(),
      title: newItemTitle.trim(),
      category: newItemCategory,
      assignedToName: undefined,
      isCompleted: false,
    };

    const updatedEvents = events.map((ev) => {
      if (ev.id === currentEvent.id) {
        return {
          ...ev,
          items: [...ev.items, newItem],
        };
      }
      return ev;
    });

    setEvents(updatedEvents);
    await saveStoredEvents(updatedEvents);
    setNewItemTitle('');
    setShowAddItemModal(false);
  }

  async function handleToggleShopping(itemId: string) {
    const updated = shoppingItems.map((item) => {
      if (item.id === itemId) {
        return { ...item, isBought: !item.isBought };
      }
      return item;
    });
    setShoppingItems(updated);
    await saveStoredShopping(updated);
  }

  async function handleAddShoppingItem() {
    if (!newShoppingName.trim()) return;
    const newItem: ShoppingItem = {
      id: 'shop_' + Date.now(),
      name: newShoppingName.trim(),
      category: newShoppingCategory,
      quantity: newShoppingQty.trim() || undefined,
      addedByName: 'Marc-Alban',
      isBought: false,
    };
    const updated = [newItem, ...shoppingItems];
    setShoppingItems(updated);
    await saveStoredShopping(updated);
    setNewShoppingName('');
    setNewShoppingQty('');
    setShowAddShoppingModal(false);
  }

  async function handleReserveWish(memberId: string, wishId: string) {
    const updated = members.map((m) => {
      if (m.id === memberId && m.wishlist) {
        return {
          ...m,
          wishlist: m.wishlist.map((w) => {
            if (w.id === wishId) {
              const alreadyReserved = w.isReservedBy;
              return {
                ...w,
                isReservedBy: alreadyReserved ? undefined : 'Marc-Alban (Secret)',
              };
            }
            return w;
          }),
        };
      }
      return m;
    });
    setMembers(updated);
    await saveStoredMembers(updated);
  }

  async function handleAddQuote() {
    if (!newQuoteText.trim()) return;
    const newQuote: FamilyQuote = {
      id: 'quote_' + Date.now(),
      quoteText: newQuoteText.trim(),
      authorName: newQuoteAuthor.trim() || 'Membre de la famille',
      context: newQuoteContext.trim() || 'Au repas de famille',
      date: 'Aujourd’hui',
      likesCount: 1,
    };
    const updated = [newQuote, ...quotes];
    setQuotes(updated);
    await saveStoredQuotes(updated);
    setNewQuoteText('');
    setNewQuoteAuthor('');
    setNewQuoteContext('');
    setShowAddQuoteModal(false);
  }

  async function handleAddPost() {
    if (!newPostCaption.trim()) return;
    const newPost: PhotoPost = {
      id: 'post_' + Date.now(),
      authorName: newPostAuthor,
      caption: newPostCaption.trim(),
      imageUrl: 'https://images.unsplash.com/photo-1543269865-cbf427effbad?auto=format&fit=crop&w=800&q=80',
      createdAt: "À l'instant",
      likesCount: 1,
    };
    const updated = [newPost, ...posts];
    setPosts(updated);
    await saveStoredPosts(updated);
    setNewPostCaption('');
    setShowPostModal(false);
  }

  function handleSendWish(member: FamilyMember) {
    const stats = calculateDaysUntilBirthday(member.birthDate);
    const text = encodeURIComponent(
      `Joyeux anniversaire ${member.name} ! 🎉 Plein de bonheur pour tes ${stats.nextAge} ans ! Bisous de toute la famille ❤️`
    );

    if (member.phone) {
      Linking.openURL(`sms:${member.phone}?body=${text}`).catch(() => {
        Alert.alert('Message préparé', `SMS pré-rempli pour ${member.name}`);
      });
    } else {
      Alert.alert(
        `Souhaiter à ${member.name}`,
        `"Joyeux anniversaire ${member.name} ! 🎉 Plein de bonheur pour tes ${stats.nextAge} ans !"`
      );
    }
  }

  return (
    <SafeAreaView style={styles.container}>
      <StatusBar barStyle="light-content" />

      {/* HEADER */}
      <View style={styles.header}>
        <View>
          <View style={styles.titleRow}>
            <Text style={styles.appTitle}>Tribu Famille</Text>
            <View style={styles.badge}>
              <Text style={styles.badgeText}>MILLET</Text>
            </View>
          </View>
          <Text style={styles.subTitle}>
            {members.length} membres • Code : <Text style={styles.codeText}>FAM-MILLET</Text>
          </Text>
        </View>

        <TouchableOpacity
          style={styles.addMemberBtn}
          onPress={() => setShowAddMemberModal(true)}
          activeOpacity={0.8}
        >
          <Plus size={18} color="#FFFFFF" />
          <Text style={styles.addMemberBtnText}>Membre</Text>
        </TouchableOpacity>
      </View>

      {/* TOP SCROLLABLE NAVIGATION */}
      <ScrollView horizontal showsHorizontalScrollIndicator={false} style={styles.tabsScroll}>
        <View style={styles.tabsNav}>
          <TouchableOpacity
            style={[styles.tabButton, activeTab === 'birthdays' && styles.tabButtonActive]}
            onPress={() => setActiveTab('birthdays')}
          >
            <Calendar size={16} color={activeTab === 'birthdays' ? '#6366F1' : '#94A3B8'} />
            <Text style={[styles.tabButtonText, activeTab === 'birthdays' && styles.tabButtonTextActive]}>
              Anniversaires
            </Text>
          </TouchableOpacity>

          <TouchableOpacity
            style={[styles.tabButton, activeTab === 'events' && styles.tabButtonActive]}
            onPress={() => setActiveTab('events')}
          >
            <Gift size={16} color={activeTab === 'events' ? '#6366F1' : '#94A3B8'} />
            <Text style={[styles.tabButtonText, activeTab === 'events' && styles.tabButtonTextActive]}>
              Qui ramène quoi ?
            </Text>
          </TouchableOpacity>

          <TouchableOpacity
            style={[styles.tabButton, activeTab === 'shopping' && styles.tabButtonActive]}
            onPress={() => setActiveTab('shopping')}
          >
            <ShoppingCart size={16} color={activeTab === 'shopping' ? '#6366F1' : '#94A3B8'} />
            <Text style={[styles.tabButtonText, activeTab === 'shopping' && styles.tabButtonTextActive]}>
              Courses
            </Text>
          </TouchableOpacity>

          <TouchableOpacity
            style={[styles.tabButton, activeTab === 'wishlist' && styles.tabButtonActive]}
            onPress={() => setActiveTab('wishlist')}
          >
            <Sparkles size={16} color={activeTab === 'wishlist' ? '#6366F1' : '#94A3B8'} />
            <Text style={[styles.tabButtonText, activeTab === 'wishlist' && styles.tabButtonTextActive]}>
              Cadeaux secrets
            </Text>
          </TouchableOpacity>

          <TouchableOpacity
            style={[styles.tabButton, activeTab === 'tribu' && styles.tabButtonActive]}
            onPress={() => setActiveTab('tribu')}
          >
            <Heart size={16} color={activeTab === 'tribu' ? '#6366F1' : '#94A3B8'} />
            <Text style={[styles.tabButtonText, activeTab === 'tribu' && styles.tabButtonTextActive]}>
              Gazette & Mémère
            </Text>
          </TouchableOpacity>
        </View>
      </ScrollView>

      <ScrollView style={styles.scrollArea} showsVerticalScrollIndicator={false}>
        {/* HERO PROCHAIN ANNIVERSAIRE (VISIBLE SUR LES ONGLETS PRINCIPAUX) */}
        {activeTab === 'birthdays' && nextBirthdayMember && nextBirthdayStats && (
          <View style={styles.heroCard}>
            <View style={styles.heroHeader}>
              <View style={styles.heroTag}>
                <Sparkles size={14} color="#F59E0B" />
                <Text style={styles.heroTagText}>PROCHAIN ANNIVERSAIRE</Text>
              </View>
              <View style={styles.daysBadge}>
                <Text style={styles.daysBadgeText}>
                  {nextBirthdayStats.daysRemaining === 0
                    ? "AUJOURD'HUI ! 🎂"
                    : `Dans ${nextBirthdayStats.daysRemaining} j`}
                </Text>
              </View>
            </View>

            <View style={styles.heroBody}>
              <View style={styles.avatarCircle}>
                <Text style={styles.avatarInitial}>{nextBirthdayMember.name.charAt(0)}</Text>
              </View>
              <View style={styles.heroInfo}>
                <Text style={styles.heroName}>{nextBirthdayMember.name}</Text>
                <Text style={styles.heroDetails}>
                  Fêtera ses <Text style={styles.ageHighlight}>{nextBirthdayStats.nextAge} ans</Text> (
                  {nextBirthdayMember.role})
                </Text>
                <Text style={styles.heroDate}>
                  {nextBirthdayStats.nextDate.toLocaleDateString('fr-FR', {
                    weekday: 'long',
                    day: 'numeric',
                    month: 'long',
                  })}
                </Text>
              </View>
            </View>

            <View style={styles.heroActions}>
              <TouchableOpacity
                style={styles.wishBtn}
                onPress={() => handleSendWish(nextBirthdayMember)}
                activeOpacity={0.8}
              >
                <MessageCircle size={16} color="#FFFFFF" />
                <Text style={styles.wishBtnText}>Lui Souhaiter</Text>
              </TouchableOpacity>

              <TouchableOpacity
                style={styles.testAlertBtn}
                onPress={() =>
                  sendInstantTestNotification(
                    nextBirthdayMember.name,
                    nextBirthdayStats.nextAge
                  )
                }
                activeOpacity={0.8}
              >
                <Bell size={16} color="#4F46E5" />
                <Text style={styles.testAlertBtnText}>Tester Alerte iOS</Text>
              </TouchableOpacity>
            </View>
          </View>
        )}

        {/* 1. ONGLET ANNIVERSAIRES */}
        {activeTab === 'birthdays' && (
          <View style={styles.contentSection}>
            <View style={styles.sectionTitleRow}>
              <Text style={styles.sectionTitle}>Calendrier de la Famille</Text>
              <Text style={styles.countBadge}>{sortedMembers.length} inscrits</Text>
            </View>

            {sortedMembers.map((member) => {
              const stats = calculateDaysUntilBirthday(member.birthDate);
              return (
                <View key={member.id} style={styles.memberCard}>
                  <View style={styles.memberLeft}>
                    <View
                      style={[
                        styles.memberAvatar,
                        member.isChild && { backgroundColor: '#F59E0B' },
                      ]}
                    >
                      <Text style={styles.memberAvatarText}>{member.name.charAt(0)}</Text>
                    </View>
                    <View style={styles.memberMeta}>
                      <View style={styles.memberNameRow}>
                        <Text style={styles.memberName}>{member.name}</Text>
                        {member.isChild && (
                          <View style={styles.childPill}>
                            <Text style={styles.childPillText}>Enfant</Text>
                          </View>
                        )}
                      </View>
                      <Text style={styles.memberSub}>
                        {member.role} • Aura {stats.nextAge} ans
                      </Text>
                      {member.allergies && (
                        <Text style={styles.memberAllergy}>⚠️ {member.allergies}</Text>
                      )}
                    </View>
                  </View>

                  <View style={styles.memberRight}>
                    <View style={styles.daysBubble}>
                      <Text style={styles.daysBubbleNum}>{stats.daysRemaining}</Text>
                      <Text style={styles.daysBubbleLabel}>jours</Text>
                    </View>
                    <TouchableOpacity
                      style={styles.iconAction}
                      onPress={() => handleSendWish(member)}
                    >
                      <Phone size={16} color="#6366F1" />
                    </TouchableOpacity>
                  </View>
                </View>
              );
            })}
          </View>
        )}

        {/* 2. ONGLET ÉVÉNEMENTS (NOËL / REPAS) */}
        {activeTab === 'events' && (
          <View style={styles.contentSection}>
            {events.map((event) => (
              <View key={event.id} style={styles.eventCard}>
                <View style={styles.eventTop}>
                  <View>
                    <Text style={styles.eventTitle}>{event.title}</Text>
                    <Text style={styles.eventLocation}>📍 {event.location}</Text>
                  </View>
                  <TouchableOpacity
                    style={styles.addItemBtn}
                    onPress={() => setShowAddItemModal(true)}
                  >
                    <Plus size={16} color="#FFFFFF" />
                    <Text style={styles.addItemBtnText}>Ajouter</Text>
                  </TouchableOpacity>
                </View>

                <Text style={styles.eventDesc}>{event.description}</Text>

                <View style={styles.tasksList}>
                  {event.items.map((item) => (
                    <TouchableOpacity
                      key={item.id}
                      style={[styles.taskRow, item.isCompleted && styles.taskRowDone]}
                      onPress={() => handleToggleEventItem(event.id, item.id)}
                      activeOpacity={0.7}
                    >
                      {item.isCompleted ? (
                        <CheckCircle2 size={22} color="#10B981" />
                      ) : (
                        <Circle size={22} color="#94A3B8" />
                      )}

                      <View style={styles.taskInfo}>
                        <Text style={[styles.taskTitle, item.isCompleted && styles.taskTitleDone]}>
                          {item.title}
                        </Text>
                        <Text style={styles.taskAssigned}>
                          {item.assignedToName ? (
                            <Text style={{ color: '#10B981', fontWeight: '600' }}>
                              Pris en charge par : {item.assignedToName}
                            </Text>
                          ) : (
                            <Text style={{ color: '#F59E0B' }}>À prendre (Touchez pour réserver)</Text>
                          )}
                        </Text>
                      </View>
                    </TouchableOpacity>
                  ))}
                </View>
              </View>
            ))}
          </View>
        )}

        {/* 3. ONGLET COURSES PARTAGÉES */}
        {activeTab === 'shopping' && (
          <View style={styles.contentSection}>
            <View style={styles.sectionTitleRow}>
              <Text style={styles.sectionTitle}>Liste de Courses de la Tribu</Text>
              <TouchableOpacity
                style={styles.addItemBtn}
                onPress={() => setShowAddShoppingModal(true)}
              >
                <Plus size={16} color="#FFFFFF" />
                <Text style={styles.addItemBtnText}>Article</Text>
              </TouchableOpacity>
            </View>
            <Text style={styles.shoppingHint}>
              💡 Tout ce qui manque à la maison est noté ici. Cochez en magasin au fur et à mesure !
            </Text>

            <View style={styles.tasksList}>
              {shoppingItems.map((item) => (
                <TouchableOpacity
                  key={item.id}
                  style={[styles.taskRow, item.isBought && styles.taskRowDone]}
                  onPress={() => handleToggleShopping(item.id)}
                >
                  {item.isBought ? (
                    <CheckCircle2 size={22} color="#10B981" />
                  ) : (
                    <Circle size={22} color="#94A3B8" />
                  )}
                  <View style={styles.taskInfo}>
                    <Text style={[styles.taskTitle, item.isBought && styles.taskTitleDone]}>
                      {item.name} {item.quantity && <Text style={{ color: '#F59E0B' }}>({item.quantity})</Text>}
                    </Text>
                    <Text style={styles.shoppingSub}>
                      Demandé par {item.addedByName} • Rayon {item.category}
                    </Text>
                  </View>
                </TouchableOpacity>
              ))}
            </View>
          </View>
        )}

        {/* 4. ONGLET WISHLISTS & IDÉES CADEAUX SECRÈTES */}
        {activeTab === 'wishlist' && (
          <View style={styles.contentSection}>
            <View style={styles.sectionTitleRow}>
              <Text style={styles.sectionTitle}>Idées Cadeaux & Wishlists</Text>
            </View>
            <Text style={styles.shoppingHint}>
              🔒 Réservez un cadeau en secret : la personne ne verra pas qui l'a pris, mais les autres éviteront d'acheter la même chose !
            </Text>

            {members.map((member) => (
              <View key={member.id} style={styles.wishCard}>
                <View style={styles.wishHeader}>
                  <Text style={styles.wishMemberName}>🎁 Liste de {member.name} ({member.role})</Text>
                </View>

                {member.wishlist && member.wishlist.length > 0 ? (
                  member.wishlist.map((wish) => (
                    <View key={wish.id} style={styles.wishItemRow}>
                      <View style={{ flex: 1 }}>
                        <Text style={styles.wishItemTitle}>{wish.title}</Text>
                        {wish.priceEstimate && (
                          <Text style={styles.wishItemPrice}>Env. {wish.priceEstimate}</Text>
                        )}
                        {wish.isReservedBy && (
                          <Text style={styles.wishReservedLabel}>
                            🔒 Réservé par : {wish.isReservedBy}
                          </Text>
                        )}
                      </View>

                      <TouchableOpacity
                        style={[
                          styles.reserveBtn,
                          wish.isReservedBy && styles.reserveBtnActive,
                        ]}
                        onPress={() => handleReserveWish(member.id, wish.id)}
                      >
                        <Text
                          style={[
                            styles.reserveBtnText,
                            wish.isReservedBy && styles.reserveBtnTextActive,
                          ]}
                        >
                          {wish.isReservedBy ? 'Déjà réservé' : 'Je m’en occupe'}
                        </Text>
                      </TouchableOpacity>
                    </View>
                  ))
                ) : (
                  <Text style={styles.emptyText}>Aucun souhait pour l’instant.</Text>
                )}
              </View>
            ))}
          </View>
        )}

        {/* 5. ONGLET TRIBU, GAZETTE & MÉMÈRE */}
        {activeTab === 'tribu' && (
          <View style={styles.contentSection}>
            {/* BOUTONS GAZETTE */}
            <View style={styles.gazetteControls}>
              <TouchableOpacity
                style={[styles.memereToggle, isMemereMode && styles.memereToggleActive]}
                onPress={() => setIsMemereMode(!isMemereMode)}
              >
                <Sparkles size={16} color={isMemereMode ? '#FFFFFF' : '#6366F1'} />
                <Text style={[styles.memereToggleText, isMemereMode && styles.memereToggleTextActive]}>
                  {isMemereMode ? 'Mode Mémère Activé' : 'Mode Mémère (Gros Textes)'}
                </Text>
              </TouchableOpacity>

              <TouchableOpacity
                style={styles.addPhotoBtn}
                onPress={() => setShowPostModal(true)}
              >
                <Camera size={16} color="#FFFFFF" />
                <Text style={styles.addPhotoBtnText}>Photo</Text>
              </TouchableOpacity>
            </View>

            {/* SECTIONS MOTS D'ENFANTS / PERLES */}
            <View style={styles.quotesSection}>
              <View style={styles.sectionTitleRow}>
                <Text style={styles.sectionTitle}>💬 Les Perles & Mots d'Enfants</Text>
                <TouchableOpacity onPress={() => setShowAddQuoteModal(true)}>
                  <Text style={{ color: '#A5B4FC', fontWeight: '700', fontSize: 13 }}>+ Noter</Text>
                </TouchableOpacity>
              </View>

              {quotes.map((q) => (
                <View key={q.id} style={styles.quoteCard}>
                  <Text style={styles.quoteText}>"{q.quoteText}"</Text>
                  <Text style={styles.quoteMeta}>
                    — <Text style={{ fontWeight: '700', color: '#FCD34D' }}>{q.authorName}</Text> • {q.context}
                  </Text>
                </View>
              ))}
            </View>

            {/* TROUSSEAU PRATIQUE & SANTÉ */}
            <View style={styles.contactsSection}>
              <View style={styles.sectionTitleRow}>
                <Text style={styles.sectionTitle}>🏥 Trousseau & Numéros Utiles</Text>
              </View>
              {contacts.map((contact) => (
                <View key={contact.id} style={styles.contactRow}>
                  <View style={{ flex: 1 }}>
                    <Text style={styles.contactTitle}>{contact.title}</Text>
                    <Text style={styles.contactDetail}>{contact.detail}</Text>
                  </View>
                  <TouchableOpacity
                    style={styles.iconAction}
                    onPress={() => {
                      if (contact.detail.includes('0')) {
                        Linking.openURL(`tel:${contact.detail}`);
                      } else {
                        Alert.alert(contact.title, contact.detail);
                      }
                    }}
                  >
                    <Phone size={14} color="#6366F1" />
                  </TouchableOpacity>
                </View>
              ))}
            </View>

            {/* MUR DE PHOTOS */}
            <View style={{ marginTop: 20 }}>
              <Text style={styles.sectionTitle}>📸 Journal de Famille</Text>
              {posts.map((post) => (
                <View key={post.id} style={[styles.postCard, isMemereMode && styles.postCardMemere]}>
                  <View style={styles.postHeader}>
                    <View style={styles.postAvatar}>
                      <Text style={styles.postAvatarText}>{post.authorName.charAt(0)}</Text>
                    </View>
                    <View>
                      <Text style={[styles.postAuthor, isMemereMode && styles.textMemereTitle]}>
                        {post.authorName}
                      </Text>
                      <Text style={styles.postDate}>{post.createdAt}</Text>
                    </View>
                  </View>

                  <View style={styles.postPhotoPlaceholder}>
                    <Text style={styles.postPlaceholderEmoji}>📸 👨‍👩‍👧‍👦</Text>
                    <Text style={styles.postPlaceholderText}>Photo de famille partagée</Text>
                  </View>

                  <Text style={[styles.postCaption, isMemereMode && styles.textMemereCaption]}>
                    "{post.caption}"
                  </Text>
                </View>
              ))}
            </View>
          </View>
        )}

        <View style={{ height: 60 }} />
      </ScrollView>

      {/* MODAL AJOUT MEMBRE */}
      <Modal visible={showAddMemberModal} animationType="slide" transparent>
        <View style={styles.modalOverlay}>
          <View style={styles.modalContainer}>
            <View style={styles.modalHeader}>
              <Text style={styles.modalTitle}>Ajouter un membre</Text>
              <TouchableOpacity onPress={() => setShowAddMemberModal(false)}>
                <X size={24} color="#64748B" />
              </TouchableOpacity>
            </View>

            <Text style={styles.label}>Prénom :</Text>
            <TextInput
              style={styles.input}
              placeholder="Ex : Mémère, Lucas, Marie..."
              placeholderTextColor="#94A3B8"
              value={newName}
              onChangeText={setNewName}
            />

            <Text style={styles.label}>Rôle dans la famille :</Text>
            <TextInput
              style={styles.input}
              placeholder="Ex : Grand-mère, Mère, Petit-fils..."
              placeholderTextColor="#94A3B8"
              value={newRole}
              onChangeText={setNewRole}
            />

            <Text style={styles.label}>Date de naissance (AAAA-MM-JJ) :</Text>
            <TextInput
              style={styles.input}
              placeholder="Ex: 1985-06-24"
              placeholderTextColor="#94A3B8"
              value={newBirthDate}
              onChangeText={setNewBirthDate}
            />

            <Text style={styles.label}>Allergies alimentaires (optionnel) :</Text>
            <TextInput
              style={styles.input}
              placeholder="Ex : Arachides, gluten, fruits de mer..."
              placeholderTextColor="#94A3B8"
              value={newAllergies}
              onChangeText={setNewAllergies}
            />

            <TouchableOpacity
              style={[styles.checkboxRow, isChild && styles.checkboxRowActive]}
              onPress={() => setIsChild(!isChild)}
            >
              {isChild ? (
                <CheckCircle2 size={20} color="#6366F1" />
              ) : (
                <Circle size={20} color="#94A3B8" />
              )}
              <Text style={styles.checkboxLabel}>C'est un enfant (sans téléphone individuel)</Text>
            </TouchableOpacity>

            <TouchableOpacity style={styles.submitBtn} onPress={handleAddMember}>
              <Text style={styles.submitBtnText}>Enregistrer dans la Tribu</Text>
            </TouchableOpacity>
          </View>
        </View>
      </Modal>

      {/* MODAL COURSES */}
      <Modal visible={showAddShoppingModal} animationType="slide" transparent>
        <View style={styles.modalOverlay}>
          <View style={styles.modalContainer}>
            <View style={styles.modalHeader}>
              <Text style={styles.modalTitle}>Ajouter aux Courses</Text>
              <TouchableOpacity onPress={() => setShowAddShoppingModal(false)}>
                <X size={24} color="#64748B" />
              </TouchableOpacity>
            </View>
            <Text style={styles.label}>Nom de l'article :</Text>
            <TextInput
              style={styles.input}
              placeholder="Ex: Beurre, Lait, Pommes, Couches..."
              placeholderTextColor="#94A3B8"
              value={newShoppingName}
              onChangeText={setNewShoppingName}
            />
            <Text style={styles.label}>Quantité / Précision :</Text>
            <TextInput
              style={styles.input}
              placeholder="Ex: 2 packs, 1 kg..."
              placeholderTextColor="#94A3B8"
              value={newShoppingQty}
              onChangeText={setNewShoppingQty}
            />
            <TouchableOpacity style={styles.submitBtn} onPress={handleAddShoppingItem}>
              <Text style={styles.submitBtnText}>Ajouter sur la liste</Text>
            </TouchableOpacity>
          </View>
        </View>
      </Modal>

      {/* MODAL CITATION / PERLE */}
      <Modal visible={showAddQuoteModal} animationType="slide" transparent>
        <View style={styles.modalOverlay}>
          <View style={styles.modalContainer}>
            <View style={styles.modalHeader}>
              <Text style={styles.modalTitle}>Noter un Mot d'Enfant / Perle</Text>
              <TouchableOpacity onPress={() => setShowAddQuoteModal(false)}>
                <X size={24} color="#64748B" />
              </TouchableOpacity>
            </View>
            <Text style={styles.label}>Ce qui a été dit :</Text>
            <TextInput
              style={[styles.input, { height: 70 }]}
              placeholder="Ex: Mémère, pourquoi tes dents dorment dans un verre ?"
              placeholderTextColor="#94A3B8"
              multiline
              value={newQuoteText}
              onChangeText={setNewQuoteText}
            />
            <Text style={styles.label}>Qui a dit ça ?</Text>
            <TextInput
              style={styles.input}
              placeholder="Ex: Lucas (4 ans), Tonton..."
              placeholderTextColor="#94A3B8"
              value={newQuoteAuthor}
              onChangeText={setNewQuoteAuthor}
            />
            <TouchableOpacity style={styles.submitBtn} onPress={handleAddQuote}>
              <Text style={styles.submitBtnText}>Garder ce souvenir</Text>
            </TouchableOpacity>
          </View>
        </View>
      </Modal>

      {/* MODAL NOUVELLE PHOTO */}
      <Modal visible={showPostModal} animationType="slide" transparent>
        <View style={styles.modalOverlay}>
          <View style={styles.modalContainer}>
            <View style={styles.modalHeader}>
              <Text style={styles.modalTitle}>Partager une photo de famille</Text>
              <TouchableOpacity onPress={() => setShowPostModal(false)}>
                <X size={24} color="#64748B" />
              </TouchableOpacity>
            </View>
            <Text style={styles.label}>Légende :</Text>
            <TextInput
              style={[styles.input, { height: 80 }]}
              placeholder="Ex: Dimanche au jardin tous ensemble !"
              placeholderTextColor="#94A3B8"
              multiline
              value={newPostCaption}
              onChangeText={setNewPostCaption}
            />
            <TouchableOpacity style={styles.submitBtn} onPress={handleAddPost}>
              <Text style={styles.submitBtnText}>Publier pour la famille</Text>
            </TouchableOpacity>
          </View>
        </View>
      </Modal>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#0B0F19',
  },
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingHorizontal: 20,
    paddingTop: 10,
    paddingBottom: 14,
    borderBottomWidth: 1,
    borderBottomColor: '#1E293B',
  },
  titleRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
  },
  appTitle: {
    fontSize: 22,
    fontWeight: '800',
    color: '#FFFFFF',
    letterSpacing: -0.5,
  },
  badge: {
    backgroundColor: '#312E81',
    paddingHorizontal: 8,
    paddingVertical: 2,
    borderRadius: 6,
    borderWidth: 1,
    borderColor: '#4338CA',
  },
  badgeText: {
    color: '#C7D2FE',
    fontSize: 10,
    fontWeight: '700',
  },
  subTitle: {
    color: '#94A3B8',
    fontSize: 13,
    marginTop: 2,
  },
  codeText: {
    color: '#A5B4FC',
    fontWeight: '700',
  },
  addMemberBtn: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
    backgroundColor: '#4F46E5',
    paddingHorizontal: 12,
    paddingVertical: 8,
    borderRadius: 10,
  },
  addMemberBtnText: {
    color: '#FFFFFF',
    fontSize: 13,
    fontWeight: '700',
  },
  tabsScroll: {
    paddingHorizontal: 16,
    paddingVertical: 10,
    maxHeight: 56,
  },
  tabsNav: {
    flexDirection: 'row',
    backgroundColor: '#1E293B',
    borderRadius: 12,
    padding: 3,
    gap: 4,
  },
  tabButton: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
    paddingHorizontal: 12,
    paddingVertical: 8,
    borderRadius: 8,
  },
  tabButtonActive: {
    backgroundColor: '#0F172A',
  },
  tabButtonText: {
    fontSize: 12,
    color: '#94A3B8',
    fontWeight: '600',
  },
  tabButtonTextActive: {
    color: '#FFFFFF',
    fontWeight: '700',
  },
  scrollArea: {
    flex: 1,
    paddingHorizontal: 16,
  },
  heroCard: {
    backgroundColor: '#1E1B4B',
    borderRadius: 20,
    padding: 18,
    marginTop: 10,
    borderWidth: 1,
    borderColor: '#3730A3',
  },
  heroHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 12,
  },
  heroTag: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
  },
  heroTagText: {
    color: '#F59E0B',
    fontSize: 11,
    fontWeight: '800',
    letterSpacing: 0.5,
  },
  daysBadge: {
    backgroundColor: '#4338CA',
    paddingHorizontal: 10,
    paddingVertical: 4,
    borderRadius: 12,
  },
  daysBadgeText: {
    color: '#EEF2FF',
    fontSize: 12,
    fontWeight: '800',
  },
  heroBody: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 14,
  },
  avatarCircle: {
    width: 54,
    height: 54,
    borderRadius: 27,
    backgroundColor: '#6366F1',
    alignItems: 'center',
    justifyContent: 'center',
  },
  avatarInitial: {
    fontSize: 24,
    fontWeight: '800',
    color: '#FFFFFF',
  },
  heroInfo: {
    flex: 1,
  },
  heroName: {
    fontSize: 20,
    fontWeight: '800',
    color: '#FFFFFF',
  },
  heroDetails: {
    fontSize: 14,
    color: '#C7D2FE',
    marginTop: 2,
  },
  ageHighlight: {
    color: '#FCD34D',
    fontWeight: '700',
  },
  heroDate: {
    fontSize: 12,
    color: '#94A3B8',
    marginTop: 2,
    textTransform: 'capitalize',
  },
  heroActions: {
    flexDirection: 'row',
    gap: 10,
    marginTop: 16,
  },
  wishBtn: {
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: 8,
    backgroundColor: '#10B981',
    paddingVertical: 10,
    borderRadius: 12,
  },
  wishBtnText: {
    color: '#FFFFFF',
    fontSize: 13,
    fontWeight: '700',
  },
  testAlertBtn: {
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: 6,
    backgroundColor: '#312E81',
    paddingVertical: 10,
    borderRadius: 12,
  },
  testAlertBtnText: {
    color: '#C7D2FE',
    fontSize: 12,
    fontWeight: '700',
  },
  contentSection: {
    marginTop: 14,
  },
  sectionTitleRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 10,
  },
  sectionTitle: {
    fontSize: 16,
    fontWeight: '800',
    color: '#F8FAFC',
  },
  countBadge: {
    fontSize: 12,
    color: '#94A3B8',
  },
  memberCard: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    backgroundColor: '#161F30',
    borderRadius: 14,
    padding: 14,
    marginBottom: 10,
    borderWidth: 1,
    borderColor: '#243247',
  },
  memberLeft: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 12,
    flex: 1,
  },
  memberAvatar: {
    width: 44,
    height: 44,
    borderRadius: 22,
    backgroundColor: '#4F46E5',
    alignItems: 'center',
    justifyContent: 'center',
  },
  memberAvatarText: {
    fontSize: 18,
    fontWeight: '700',
    color: '#FFFFFF',
  },
  memberMeta: {
    flex: 1,
  },
  memberNameRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
  },
  memberName: {
    fontSize: 16,
    fontWeight: '700',
    color: '#FFFFFF',
  },
  childPill: {
    backgroundColor: '#F59E0B20',
    paddingHorizontal: 6,
    paddingVertical: 1,
    borderRadius: 6,
  },
  childPillText: {
    color: '#F59E0B',
    fontSize: 10,
    fontWeight: '700',
  },
  memberSub: {
    fontSize: 12,
    color: '#94A3B8',
    marginTop: 2,
  },
  memberAllergy: {
    fontSize: 11,
    color: '#F87171',
    marginTop: 2,
  },
  memberRight: {
    alignItems: 'center',
    flexDirection: 'row',
    gap: 10,
  },
  daysBubble: {
    alignItems: 'center',
    backgroundColor: '#0F172A',
    paddingHorizontal: 8,
    paddingVertical: 6,
    borderRadius: 10,
    minWidth: 46,
  },
  daysBubbleNum: {
    fontSize: 15,
    fontWeight: '800',
    color: '#A5B4FC',
  },
  daysBubbleLabel: {
    fontSize: 9,
    color: '#64748B',
    textTransform: 'uppercase',
  },
  iconAction: {
    backgroundColor: '#312E81',
    width: 34,
    height: 34,
    borderRadius: 17,
    alignItems: 'center',
    justifyContent: 'center',
  },
  eventCard: {
    backgroundColor: '#161F30',
    borderRadius: 16,
    padding: 16,
    borderWidth: 1,
    borderColor: '#243247',
  },
  eventTop: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'flex-start',
  },
  eventTitle: {
    fontSize: 18,
    fontWeight: '800',
    color: '#FFFFFF',
  },
  eventLocation: {
    fontSize: 13,
    color: '#94A3B8',
    marginTop: 3,
  },
  addItemBtn: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
    backgroundColor: '#10B981',
    paddingHorizontal: 10,
    paddingVertical: 6,
    borderRadius: 8,
  },
  addItemBtnText: {
    color: '#FFFFFF',
    fontSize: 12,
    fontWeight: '700',
  },
  eventDesc: {
    fontSize: 13,
    color: '#C7D2FE',
    marginTop: 8,
    marginBottom: 14,
  },
  tasksList: {
    gap: 8,
  },
  taskRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 12,
    backgroundColor: '#0F172A',
    padding: 12,
    borderRadius: 12,
    borderWidth: 1,
    borderColor: '#334155',
  },
  taskRowDone: {
    borderColor: '#059669',
    backgroundColor: '#064E3B20',
  },
  taskInfo: {
    flex: 1,
  },
  taskTitle: {
    fontSize: 14,
    fontWeight: '700',
    color: '#FFFFFF',
  },
  taskTitleDone: {
    textDecorationLine: 'line-through',
    color: '#94A3B8',
  },
  taskAssigned: {
    fontSize: 12,
    marginTop: 2,
  },
  shoppingHint: {
    color: '#94A3B8',
    fontSize: 12,
    marginBottom: 12,
    lineHeight: 18,
  },
  shoppingSub: {
    fontSize: 11,
    color: '#64748B',
    marginTop: 2,
  },
  wishCard: {
    backgroundColor: '#161F30',
    borderRadius: 14,
    padding: 14,
    marginBottom: 12,
    borderWidth: 1,
    borderColor: '#243247',
  },
  wishHeader: {
    borderBottomWidth: 1,
    borderBottomColor: '#243247',
    paddingBottom: 8,
    marginBottom: 10,
  },
  wishMemberName: {
    fontSize: 15,
    fontWeight: '800',
    color: '#FCD34D',
  },
  wishItemRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingVertical: 8,
    borderBottomWidth: 1,
    borderBottomColor: '#1E293B',
  },
  wishItemTitle: {
    color: '#FFFFFF',
    fontSize: 14,
    fontWeight: '600',
  },
  wishItemPrice: {
    color: '#10B981',
    fontSize: 12,
    fontWeight: '700',
    marginTop: 2,
  },
  wishReservedLabel: {
    color: '#F59E0B',
    fontSize: 11,
    fontWeight: '700',
    marginTop: 2,
  },
  reserveBtn: {
    backgroundColor: '#4F46E5',
    paddingHorizontal: 10,
    paddingVertical: 6,
    borderRadius: 8,
  },
  reserveBtnActive: {
    backgroundColor: '#3730A3',
  },
  reserveBtnText: {
    color: '#FFFFFF',
    fontSize: 11,
    fontWeight: '700',
  },
  reserveBtnTextActive: {
    color: '#FCD34D',
  },
  emptyText: {
    color: '#64748B',
    fontSize: 12,
    fontStyle: 'italic',
  },
  gazetteControls: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 14,
    gap: 8,
  },
  memereToggle: {
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: 6,
    backgroundColor: '#1E293B',
    paddingVertical: 10,
    borderRadius: 10,
    borderWidth: 1,
    borderColor: '#3730A3',
  },
  memereToggleActive: {
    backgroundColor: '#4F46E5',
    borderColor: '#6366F1',
  },
  memereToggleText: {
    color: '#A5B4FC',
    fontSize: 12,
    fontWeight: '700',
  },
  memereToggleTextActive: {
    color: '#FFFFFF',
  },
  addPhotoBtn: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
    backgroundColor: '#EC4899',
    paddingHorizontal: 12,
    paddingVertical: 10,
    borderRadius: 10,
  },
  addPhotoBtnText: {
    color: '#FFFFFF',
    fontSize: 12,
    fontWeight: '700',
  },
  quotesSection: {
    backgroundColor: '#161F30',
    borderRadius: 16,
    padding: 14,
    marginBottom: 16,
    borderWidth: 1,
    borderColor: '#243247',
  },
  quoteCard: {
    backgroundColor: '#0F172A',
    borderRadius: 10,
    padding: 12,
    marginBottom: 8,
    borderLeftWidth: 3,
    borderLeftColor: '#F59E0B',
  },
  quoteText: {
    color: '#E2E8F0',
    fontSize: 13,
    fontStyle: 'italic',
    lineHeight: 18,
  },
  quoteMeta: {
    color: '#94A3B8',
    fontSize: 11,
    marginTop: 6,
  },
  contactsSection: {
    backgroundColor: '#161F30',
    borderRadius: 16,
    padding: 14,
    marginBottom: 16,
    borderWidth: 1,
    borderColor: '#243247',
  },
  contactRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingVertical: 8,
    borderBottomWidth: 1,
    borderBottomColor: '#1E293B',
  },
  contactTitle: {
    color: '#FFFFFF',
    fontSize: 13,
    fontWeight: '700',
  },
  contactDetail: {
    color: '#A5B4FC',
    fontSize: 12,
    marginTop: 2,
  },
  postCard: {
    backgroundColor: '#161F30',
    borderRadius: 16,
    padding: 14,
    marginBottom: 14,
    borderWidth: 1,
    borderColor: '#243247',
  },
  postCardMemere: {
    padding: 20,
    backgroundColor: '#1E1B4B',
    borderColor: '#6366F1',
  },
  textMemereTitle: {
    fontSize: 22,
    fontWeight: '800',
  },
  textMemereCaption: {
    fontSize: 18,
    lineHeight: 26,
    fontWeight: '600',
    color: '#FFFFFF',
  },
  postHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 10,
    marginBottom: 10,
  },
  postAvatar: {
    width: 36,
    height: 36,
    borderRadius: 18,
    backgroundColor: '#EC4899',
    alignItems: 'center',
    justifyContent: 'center',
  },
  postAvatarText: {
    color: '#FFFFFF',
    fontWeight: '700',
  },
  postAuthor: {
    color: '#FFFFFF',
    fontWeight: '700',
    fontSize: 14,
  },
  postDate: {
    color: '#64748B',
    fontSize: 11,
  },
  postPhotoPlaceholder: {
    height: 160,
    backgroundColor: '#0F172A',
    borderRadius: 12,
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: 10,
  },
  postPlaceholderEmoji: {
    fontSize: 36,
  },
  postPlaceholderText: {
    color: '#64748B',
    fontSize: 12,
    marginTop: 6,
  },
  postCaption: {
    color: '#E2E8F0',
    fontSize: 14,
    fontStyle: 'italic',
    lineHeight: 20,
  },
  modalOverlay: {
    flex: 1,
    backgroundColor: 'rgba(0, 0, 0, 0.75)',
    justifyContent: 'flex-end',
  },
  modalContainer: {
    backgroundColor: '#1E293B',
    borderTopLeftRadius: 24,
    borderTopRightRadius: 24,
    padding: 24,
    maxHeight: '85%',
  },
  modalHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 20,
  },
  modalTitle: {
    fontSize: 18,
    fontWeight: '800',
    color: '#FFFFFF',
  },
  label: {
    color: '#CBD5E1',
    fontSize: 13,
    fontWeight: '600',
    marginTop: 10,
    marginBottom: 6,
  },
  input: {
    backgroundColor: '#0F172A',
    borderWidth: 1,
    borderColor: '#334155',
    borderRadius: 10,
    paddingHorizontal: 14,
    paddingVertical: 10,
    color: '#FFFFFF',
    fontSize: 14,
  },
  checkboxRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 10,
    marginTop: 16,
    backgroundColor: '#0F172A',
    padding: 12,
    borderRadius: 10,
    borderWidth: 1,
    borderColor: '#334155',
  },
  checkboxRowActive: {
    borderColor: '#6366F1',
  },
  checkboxLabel: {
    color: '#E2E8F0',
    fontSize: 13,
    flex: 1,
  },
  submitBtn: {
    backgroundColor: '#4F46E5',
    borderRadius: 12,
    paddingVertical: 14,
    alignItems: 'center',
    marginTop: 22,
    marginBottom: 10,
  },
  submitBtnText: {
    color: '#FFFFFF',
    fontSize: 15,
    fontWeight: '700',
  },
});
