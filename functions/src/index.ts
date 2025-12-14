import vision, {type protos} from '@google-cloud/vision';
import * as admin from 'firebase-admin';
import {FieldValue} from 'firebase-admin/firestore';
import {logger} from 'firebase-functions/v2';
import {type CallableRequest, HttpsError, onCall} from 'firebase-functions/v2/https';

type IWebDetection = protos.google.cloud.vision.v1.IWebDetection;

admin.initializeApp();
const auth = admin.auth();
const firestore = admin.firestore();

/**
 * Cloud Function to delete a user account and all associated data.
 * Removes user preferences, likes/dislikes from image documents,
 * and deletes the Firebase Auth user.
 * @param {CallableRequest} request - The callable request
 * @return {Promise<{success: boolean, message: string}>} Result of deletion
 */
export const deleteUserAccount = onCall(async (request: CallableRequest) => {
  try {
    const userId = request.auth?.uid;
    if (!userId) {
      throw new Error('request.auth?.uid was null');
    }

    console.log(`User ${userId} is being removed`);

    await firestore.collection('preferences').doc(userId).delete();
    console.log(`Document preferences/${userId} deleted successfully`);

    const likedSnapshot = await firestore
      .collection('image-docs')
      .where('liked', 'array-contains', userId)
      .get();

    for (const doc of likedSnapshot.docs) {
      await doc.ref.update({liked: FieldValue.arrayRemove(userId)});
    }

    console.log(`${likedSnapshot.docs.length} likes removed`);

    const dislikedSnapshot = await firestore
      .collection('image-docs')
      .where('disliked', 'array-contains', userId)
      .get();

    for (const doc of dislikedSnapshot.docs) {
      await doc.ref.update({disliked: FieldValue.arrayRemove(userId)});
    }

    console.log(`${dislikedSnapshot.docs.length} dislikes removed`);

    await auth.deleteUser(userId);

    console.log('Firebase Auth User was removed');

    return {
      success: true,
      message:
        `Removed ${likedSnapshot.docs.length} likes and ` +
        `${dislikedSnapshot.docs.length} dislikes for user ${userId}`,
    };
  } catch (error) {
    logger.error('Error deleting user account:', error);
    throw new HttpsError(
      'internal',
      'Failed to delete user account',
      error instanceof Error ? error.message : String(error),
    );
  }
});

const STORAGE_BASE_URL = 'https://storage.googleapis.com/tindart-8c83b.firebasestorage.app';

/**
 * Transform Vision API web detection response into a simplified format.
 * @param {IWebDetection} webDetection - Raw web detection response from Vision API
 * @return {object} Transformed web detection data
 */
function transformWebDetection(webDetection: IWebDetection) {
  return {
    webEntities:
      webDetection.webEntities?.map((e) => ({
        entityId: e.entityId,
        description: e.description,
        score: e.score,
      })) ?? [],
    fullMatchingImages:
      webDetection.fullMatchingImages?.map((i) => ({
        url: i.url,
      })) ?? [],
    partialMatchingImages:
      webDetection.partialMatchingImages?.map((i) => ({
        url: i.url,
      })) ?? [],
    pagesWithMatchingImages:
      webDetection.pagesWithMatchingImages?.map((p) => ({
        url: p.url,
        pageTitle: p.pageTitle,
      })) ?? [],
    visuallySimilarImages:
      webDetection.visuallySimilarImages?.map((i) => ({
        url: i.url,
      })) ?? [],
    bestGuessLabels:
      webDetection.bestGuessLabels?.map((l) => ({
        label: l.label,
        languageCode: l.languageCode,
      })) ?? [],
  };
}

/**
 * Cloud Function to perform web detection on an image using Google Vision API.
 * Supports caching via imageDocId to avoid repeated API calls.
 * @param {CallableRequest} request - The callable request
 * @return {Promise<{success: boolean, data: object|null, cached?: boolean}>}
 */
export const detectWeb = onCall(async (request: CallableRequest) => {
  try {
    const userId = request.auth?.uid;
    if (!userId) {
      throw new HttpsError('unauthenticated', 'User must be authenticated');
    }

    const imageDocId = request.data?.imageDocId;
    const imageUrl = request.data?.imageUrl;

    // Support both imageDocId (preferred, enables caching) and legacy imageUrl
    if (!imageDocId && (!imageUrl || typeof imageUrl !== 'string')) {
      throw new HttpsError('invalid-argument', 'imageDocId or imageUrl is required');
    }

    // If we have imageDocId, check cache first
    if (imageDocId) {
      const docRef = firestore.collection('image-docs').doc(imageDocId);
      const doc = await docRef.get();

      if (doc.exists) {
        const data = doc.data();

        // Return cached result if available
        if (data?.webDetection) {
          console.log(`Cache hit for ${imageDocId} (user: ${userId})`);
          return {
            success: true,
            data: data.webDetection,
            cached: true,
          };
        }

        // No cache - call Vision API and store result
        const fileName = data?.name;
        if (fileName) {
          const url = `${STORAGE_BASE_URL}/${fileName}`;
          console.log(`Cache miss for ${imageDocId}, calling Vision API`);

          const client = new vision.ImageAnnotatorClient();
          const [result] = await client.webDetection(url);
          const webDetection = result.webDetection;

          const webDetectionData = webDetection
            ? {
                ...transformWebDetection(webDetection),
                cachedAt: FieldValue.serverTimestamp(),
              }
            : null;

          // Cache the result for future requests
          if (webDetectionData) {
            await docRef.update({webDetection: webDetectionData});
          }

          return {
            success: true,
            data: webDetectionData,
            cached: false,
          };
        }
      }
    }

    // Fallback: use imageUrl directly (legacy, no caching)
    if (imageUrl) {
      console.log(`Legacy call with imageUrl (user: ${userId}): ${imageUrl}`);
      const client = new vision.ImageAnnotatorClient();
      const [result] = await client.webDetection(imageUrl);
      const webDetection = result.webDetection;

      if (!webDetection) {
        return {success: true, data: null};
      }

      return {
        success: true,
        data: transformWebDetection(webDetection),
      };
    }

    throw new HttpsError('not-found', 'Image document not found');
  } catch (error) {
    // Re-throw HttpsErrors as-is (they're intentional)
    if (error instanceof HttpsError) {
      throw error;
    }
    logger.error('Error in web detection:', error);
    throw new HttpsError(
      'internal',
      'Failed to perform web detection',
      error instanceof Error ? error.message : String(error),
    );
  }
});
