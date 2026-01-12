const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();
const db = admin.firestore();

/**
 * Firestore Gen-1 trigger: swipes/{swipeId}
 * Creates a match when likes are reciprocal.
 */
exports.onSwipeCreated = functions
  .region('us-central1')
  .firestore.document('swipes/{swipeId}')
  .onCreate(async (snap, context) => {
    const swipe = snap.data();
    if (!swipe || swipe.value !== 'like') return null;

    const fromUid = swipe.fromUid;
    const toPlaycardId = swipe.toPlaycardId;

    // Find the target playcard owner
    const pcDoc = await db.collection('playcards').doc(toPlaycardId).get();
    if (!pcDoc.exists) return null;
    const otherUid = pcDoc.data().ownerUid;
    if (!otherUid || otherUid === fromUid) return null;

    // Get this user's playcards
    const myCardsSnap = await db.collection('playcards')
      .where('ownerUid', '==', fromUid).get();
    const myCardIds = myCardsSnap.docs.map(d => d.id);
    if (myCardIds.length === 0) return null;

    // Did the other user already like any of my cards?
    // Firestore 'in' max 10 — fine for MVP
    const reciprocal = await db.collection('swipes')
      .where('fromUid', '==', otherUid)
      .where('value', '==', 'like')
      .where('toPlaycardId', 'in', myCardIds.slice(0, 10))
      .get();

    if (reciprocal.empty) return null;

    // Deterministic matchId to avoid duplicates
    const [a, b] = [fromUid, otherUid].sort();
    const matchId = `${a}_${b}`;

    const matchRef = db.collection('matches').doc(matchId);
    const matchDoc = await matchRef.get();
    if (!matchDoc.exists) {
      await matchRef.set({
        userA: a,
        userB: b,
        participants: [a, b],
        playcardA: toPlaycardId,
        playcardB: reciprocal.docs[0].data().toPlaycardId,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        lastMessage: "C’est un match ! Dites bonjour 👋"
      });

      await db.collection('chats').doc(matchId).collection('messages').add({
        fromUid: null,
        text: "C’est un match ! Dites bonjour 👋",
        type: "system",
        sentAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }
    return null;
  });
