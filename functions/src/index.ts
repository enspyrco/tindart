import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import {FieldValue} from 'firebase-admin/firestore';

admin.initializeApp();
const auth = admin.auth();
const firestore = admin.firestore();

export const deleteUserAccount = functions.https.onCall(
  async (request: functions.https.CallableRequest) => {
    try {
      const userId = request.auth?.uid;
      if (!userId) {
        throw new Error('request.auth?.uid was null');
      }

      console.log(`User ${userId} is being removed`);

      firestore.collection('preferences').doc(userId).delete();
      console.log(`Document preferences/${userId} deleted successfully`);

      const likedSnapshot = await firestore.collection('image-docs')
        .where('liked', 'array-contains', userId)
        .get();

      for (const doc of likedSnapshot.docs) {
        doc.ref.update({liked: FieldValue.arrayRemove(userId)});
      }

      console.log(`${likedSnapshot.docs.length} likes removed`);

      const dislikedSnapshot = await firestore.collection('image-docs')
        .where('disliked', 'array-contains', userId)
        .get();

      for (const doc of dislikedSnapshot.docs) {
        doc.ref.update({disliked: FieldValue.arrayRemove(userId)});
      }

      console.log(`${dislikedSnapshot.docs.length} dislikes removed`);

      await auth.deleteUser(userId);

      console.log('Firebase Auth User was removed');

      return {
        success: true,
        message: `Removed ${likedSnapshot.docs.length} likes and ` +
          `${dislikedSnapshot.docs.length} dislike for user ${userId}}`,
      };
    } catch (error) {
      functions.logger.error('Error deleting user account:', error);
      throw new functions.https.HttpsError(
        'internal',
        'Failed to delete user account',
        error instanceof Error ? error.message : String(error)
      );
    }
  }
);
