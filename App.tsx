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
} from 'lucide-react-native';

import { FamilyMember, FamilyEvent, EventTaskItem, PhotoPost } from './src/types';
import {
  getStoredMembers,
  addMemberToTribe,
  getStoredEvents,
  saveStoredEvents,
  getStoredPosts,
  saveStoredPosts,
} from './src/services/storage';
import {
  calculateDaysUntilBirthday,
  scheduleBirthdayNotifications,
  sendInstantTestNotification,
  requestNotificationPermissions,
} from './src/services/notificationService';

export default function App() {
  const [activeTab, setActiveTab] = useState<'birthdays' | 'events' | 'gazette'>('birthdays');
  const [members, setMembers] = useState<FamilyMember[]>([]);
  const [events, setEvents] = useState<FamilyEvent[]>([]);
  const [posts, setPosts] = useState<PhotoPost[]>([]);

  // Modals
  const [showAddMemberModal, setShowAddMemberModal] = useState(false);
  const [showAddItemModal, setShowAddItemModal] = useState(false);
  const [showPostModal, setShowPostModal] = useState(false);
  const [isMemereMode, setIsMemereMode] = useState(false);

  // New Member Form
  const [newName, setNewName] = useState('');
  const [newRole, setNewRole] = useState('Membre');
  const [newBirthDate, setNewBirthDate] = useState('1990-01-01');
  const [newPhone, setNewPhone] = useState('');
  const [isChild, setIsChild] = useState(false);

  // New Event Item Form
  const [newItemTitle, setNewItemTitle] = useState('');
  const [newItemCategory, setNewItemCategory] = useState<'aperitif' | 'entree' | 'plat' | 'dessert' | 'boisson' | 'autre'>('plat');

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

    setMembers(loadedMembers);
    setEvents(loadedEvents);
    setPosts(loadedPosts);

    // Schedule local push notifications for all birthdays
    await scheduleBirthdayNotifications(loadedMembers);
  }

  // Trier les anniversaires par ordre du plus proche au plus lointain
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
      isChild,
    });

    setMembers(updated);
    await scheduleBirthdayNotifications(updated);

    setShowAddMemberModal(false);
    setNewName('');
    setNewPhone('');
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

    const updatedPosts = [newPost, ...posts];
    setPosts(updatedPosts);
    await saveStoredPosts(updatedPosts);
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

      <ScrollView style={styles.scrollArea} showsVerticalScrollIndicator={false}>
        {/* BANNIÈRE PROCHAIN ANNIVERSAIRE (HERO CARD) */}
        {nextBirthdayMember && nextBirthdayStats && (
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
                <Text style={styles.testAlertBtnText}>Tester l'Alerte iOS</Text>
              </TouchableOpacity>
            </View>
          </View>
        )}

        {/* TABS NAVIGATION */}
        <View style={styles.tabsNav}>
          <TouchableOpacity
            style={[styles.tabButton, activeTab === 'birthdays' && styles.tabButtonActive]}
            onPress={() => setActiveTab('birthdays')}
          >
            <Calendar size={18} color={activeTab === 'birthdays' ? '#6366F1' : '#94A3B8'} />
            <Text
              style={[styles.tabButtonText, activeTab === 'birthdays' && styles.tabButtonTextActive]}
            >
              Anniversaires
            </Text>
          </TouchableOpacity>

          <TouchableOpacity
            style={[styles.tabButton, activeTab === 'events' && styles.tabButtonActive]}
            onPress={() => setActiveTab('events')}
          >
            <Gift size={18} color={activeTab === 'events' ? '#6366F1' : '#94A3B8'} />
            <Text
              style={[styles.tabButtonText, activeTab === 'events' && styles.tabButtonTextActive]}
            >
              Qui ramène quoi ?
            </Text>
          </TouchableOpacity>

          <TouchableOpacity
            style={[styles.tabButton, activeTab === 'gazette' && styles.tabButtonActive]}
            onPress={() => setActiveTab('gazette')}
          >
            <Heart size={18} color={activeTab === 'gazette' ? '#6366F1' : '#94A3B8'} />
            <Text
              style={[styles.tabButtonText, activeTab === 'gazette' && styles.tabButtonTextActive]}
            >
              Gazette Mémère
            </Text>
          </TouchableOpacity>
        </View>

        {/* ONGLET 1 : TOUS LES ANNIVERSAIRES */}
        {activeTab === 'birthdays' && (
          <View style={styles.contentSection}>
            <View style={styles.sectionTitleRow}>
              <Text style={styles.sectionTitle}>Calendrier des Anniversaires</Text>
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
                      <Text style={styles.memberExactDate}>
                        Né(e) le{' '}
                        {new Date(member.birthDate).toLocaleDateString('fr-FR', {
                          day: 'numeric',
                          month: 'long',
                          year: 'numeric',
                        })}
                      </Text>
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

        {/* ONGLET 2 : QUI RAMÈNE QUOI (NOËL / ÉVÉNEMENTS) */}
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
                        <Text
                          style={[styles.taskTitle, item.isCompleted && styles.taskTitleDone]}
                        >
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

        {/* ONGLET 3 : GAZETTE POUR MÉMÈRE */}
        {activeTab === 'gazette' && (
          <View style={styles.contentSection}>
            <View style={styles.gazetteControls}>
              <TouchableOpacity
                style={[styles.memereToggle, isMemereMode && styles.memereToggleActive]}
                onPress={() => setIsMemereMode(!isMemereMode)}
              >
                <Sparkles size={16} color={isMemereMode ? '#FFFFFF' : '#6366F1'} />
                <Text
                  style={[
                    styles.memereToggleText,
                    isMemereMode && styles.memereToggleTextActive,
                  ]}
                >
                  {isMemereMode ? 'Mode Mémère Activé (Gros textes)' : 'Activer Mode Mémère'}
                </Text>
              </TouchableOpacity>

              <TouchableOpacity
                style={styles.addPhotoBtn}
                onPress={() => setShowPostModal(true)}
              >
                <Camera size={16} color="#FFFFFF" />
                <Text style={styles.addPhotoBtnText}>Poster photo</Text>
              </TouchableOpacity>
            </View>

            {posts.map((post) => (
              <View
                key={post.id}
                style={[styles.postCard, isMemereMode && styles.postCardMemere]}
              >
                <View style={styles.postHeader}>
                  <View style={styles.postAvatar}>
                    <Text style={styles.postAvatarText}>{post.authorName.charAt(0)}</Text>
                  </View>
                  <View>
                    <Text
                      style={[styles.postAuthor, isMemereMode && styles.textMemereTitle]}
                    >
                      {post.authorName}
                    </Text>
                    <Text style={styles.postDate}>{post.createdAt}</Text>
                  </View>
                </View>

                <View style={styles.postPhotoPlaceholder}>
                  <Text style={styles.postPlaceholderEmoji}>📸 👨‍👩‍👧‍👦</Text>
                  <Text style={styles.postPlaceholderText}>Photo de famille partagée</Text>
                </View>

                <Text
                  style={[styles.postCaption, isMemereMode && styles.textMemereCaption]}
                >
                  "{post.caption}"
                </Text>

                <View style={styles.postFooter}>
                  <View style={styles.likesRow}>
                    <Heart size={18} color="#EF4444" fill="#EF4444" />
                    <Text style={styles.likesText}>{post.likesCount} personnes adorent</Text>
                  </View>
                  <TouchableOpacity
                    onPress={() =>
                      Alert.alert(
                        'Gazette Mensuelle',
                        'Cette photo sera imprimée dans la Gazette de fin de mois pour Mémère !'
                      )
                    }
                  >
                    <Text style={styles.gazettePill}>Dans la gazette mensuelle 🗞️</Text>
                  </TouchableOpacity>
                </View>
              </View>
            ))}
          </View>
        )}

        <View style={{ height: 40 }} />
      </ScrollView>

      {/* MODAL AJOUTER UN MEMBRE / ENFANT */}
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
              placeholder="Ex : Mémère, Tonton Marc, Julie..."
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

            <Text style={styles.label}>Numéro de téléphone (optionnel) :</Text>
            <TextInput
              style={styles.input}
              placeholder="06..."
              placeholderTextColor="#94A3B8"
              keyboardType="phone-pad"
              value={newPhone}
              onChangeText={setNewPhone}
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
              <Text style={styles.checkboxLabel}>
                C'est un enfant (pas de téléphone individuel)
              </Text>
            </TouchableOpacity>

            <TouchableOpacity style={styles.submitBtn} onPress={handleAddMember}>
              <Text style={styles.submitBtnText}>Enregistrer dans le calendrier</Text>
            </TouchableOpacity>
          </View>
        </View>
      </Modal>

      {/* MODAL AJOUTER ELEMENT EVENEMENT */}
      <Modal visible={showAddItemModal} animationType="slide" transparent>
        <View style={styles.modalOverlay}>
          <View style={styles.modalContainer}>
            <View style={styles.modalHeader}>
              <Text style={styles.modalTitle}>Qui ramène quoi ?</Text>
              <TouchableOpacity onPress={() => setShowAddItemModal(false)}>
                <X size={24} color="#64748B" />
              </TouchableOpacity>
            </View>

            <Text style={styles.label}>Nom de l'élément à apporter :</Text>
            <TextInput
              style={styles.input}
              placeholder="Ex : 2 baguettes, bûche glacée, vin blanc..."
              placeholderTextColor="#94A3B8"
              value={newItemTitle}
              onChangeText={setNewItemTitle}
            />

            <TouchableOpacity style={styles.submitBtn} onPress={handleAddItemToEvent}>
              <Text style={styles.submitBtnText}>Ajouter à la liste de Noël</Text>
            </TouchableOpacity>
          </View>
        </View>
      </Modal>

      {/* MODAL NOUVELLE PHOTO GAZETTE */}
      <Modal visible={showPostModal} animationType="slide" transparent>
        <View style={styles.modalOverlay}>
          <View style={styles.modalContainer}>
            <View style={styles.modalHeader}>
              <Text style={styles.modalTitle}>Publier une nouvelle photo</Text>
              <TouchableOpacity onPress={() => setShowPostModal(false)}>
                <X size={24} color="#64748B" />
              </TouchableOpacity>
            </View>

            <Text style={styles.label}>Votre prénom :</Text>
            <TextInput
              style={styles.input}
              value={newPostAuthor}
              onChangeText={setNewPostAuthor}
            />

            <Text style={styles.label}>Petite légende pour Mémère et la famille :</Text>
            <TextInput
              style={[styles.input, { height: 80 }]}
              placeholder="Ex: Belle journée au parc avec les enfants !"
              placeholderTextColor="#94A3B8"
              multiline
              value={newPostCaption}
              onChangeText={setNewPostCaption}
            />

            <TouchableOpacity style={styles.submitBtn} onPress={handleAddPost}>
              <Text style={styles.submitBtnText}>Partager sur le mur familial</Text>
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
    backgroundColor: '#0F172A',
  },
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingHorizontal: 20,
    paddingTop: 12,
    paddingBottom: 16,
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
  scrollArea: {
    flex: 1,
    paddingHorizontal: 16,
  },
  heroCard: {
    backgroundColor: '#1E1B4B',
    borderRadius: 20,
    padding: 18,
    marginTop: 16,
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
  tabsNav: {
    flexDirection: 'row',
    backgroundColor: '#1E293B',
    borderRadius: 14,
    padding: 4,
    marginTop: 16,
  },
  tabButton: {
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: 6,
    paddingVertical: 10,
    borderRadius: 10,
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
  contentSection: {
    marginTop: 16,
  },
  sectionTitleRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 12,
  },
  sectionTitle: {
    fontSize: 16,
    fontWeight: '700',
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
    backgroundColor: '#1E293B',
    borderRadius: 14,
    padding: 14,
    marginBottom: 10,
    borderWidth: 1,
    borderColor: '#334155',
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
  memberExactDate: {
    fontSize: 11,
    color: '#64748B',
    marginTop: 1,
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
    backgroundColor: '#1E293B',
    borderRadius: 16,
    padding: 16,
    borderWidth: 1,
    borderColor: '#334155',
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
  gazetteControls: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 12,
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
  postCard: {
    backgroundColor: '#1E293B',
    borderRadius: 16,
    padding: 14,
    marginBottom: 14,
    borderWidth: 1,
    borderColor: '#334155',
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
  postFooter: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginTop: 12,
    paddingTop: 10,
    borderTopWidth: 1,
    borderTopColor: '#334155',
  },
  likesRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
  },
  likesText: {
    color: '#F87171',
    fontSize: 12,
    fontWeight: '600',
  },
  gazettePill: {
    color: '#A5B4FC',
    fontSize: 11,
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
