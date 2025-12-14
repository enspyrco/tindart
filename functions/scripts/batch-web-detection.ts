#!/usr/bin/env npx ts-node
/**
 * Batch script to run Vision API web detection on all images
 * and store results in Firestore for caching.
 *
 * Run with: ./src/batch-web-detection.ts
 * Or after build: node lib/batch-web-detection.js
 *
 * Requires: gcloud auth application-default login
 */

import vision from '@google-cloud/vision';
import * as admin from 'firebase-admin';

const PROJECT_ID = 'tindart-8c83b';

// Initialize Firebase Admin with explicit project ID
admin.initializeApp({projectId: PROJECT_ID});
const firestore = admin.firestore();
const visionClient = new vision.ImageAnnotatorClient({projectId: PROJECT_ID});

const STORAGE_BASE_URL = 'https://storage.googleapis.com/tindart-8c83b.firebasestorage.app';
const DELAY_MS = 500; // Delay between API calls to respect rate limits

interface WebDetectionData {
  webEntities: Array<{
    entityId: string | null | undefined;
    description: string | null | undefined;
    score: number | null | undefined;
  }>;
  fullMatchingImages: Array<{url: string | null | undefined}>;
  partialMatchingImages: Array<{url: string | null | undefined}>;
  pagesWithMatchingImages: Array<{
    url: string | null | undefined;
    pageTitle: string | null | undefined;
  }>;
  visuallySimilarImages: Array<{url: string | null | undefined}>;
  bestGuessLabels: Array<{
    label: string | null | undefined;
    languageCode: string | null | undefined;
  }>;
  cachedAt: admin.firestore.Timestamp;
}

/**
 * Sleep for the specified number of milliseconds.
 * @param {number} ms - Milliseconds to sleep
 * @return {Promise<void>}
 */
async function sleep(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

/**
 * Process a single image through the Vision API.
 * @param {string} docId - Firestore document ID
 * @param {string} fileName - Image filename in storage
 * @return {Promise<WebDetectionData | null>} Web detection results or null
 */
async function processImage(docId: string, fileName: string): Promise<WebDetectionData | null> {
  const imageUrl = `${STORAGE_BASE_URL}/${fileName}`;
  console.log(`Processing: ${docId} -> ${imageUrl}`);

  try {
    const [result] = await visionClient.webDetection(imageUrl);
    const webDetection = result.webDetection;

    if (!webDetection) {
      console.log(`  No web detection results for ${docId}`);
      return null;
    }

    const data: WebDetectionData = {
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
      cachedAt: admin.firestore.Timestamp.now(),
    };

    console.log(
      `  Found ${data.webEntities.length} entities, ` +
        `${data.visuallySimilarImages.length} similar images`,
    );

    return data;
  } catch (error) {
    console.error(`  Error processing ${docId}:`, error);
    return null;
  }
}

/**
 * Main entry point - processes only active images from doc-id-lists.
 * @return {Promise<void>}
 */
async function main(): Promise<void> {
  console.log('Starting batch web detection...\n');

  // Get the list of active image IDs
  const listDoc = await firestore.collection('doc-id-lists').doc('RMCevRY4dGpUTTcrltun').get();
  const listData = listDoc.data();
  const activeIds: string[] = listData?.ids ?? listData?.docIds ?? [];

  if (activeIds.length === 0) {
    console.error('No active image IDs found in doc-id-lists/RMCevRY4dGpUTTcrltun');
    process.exit(1);
  }

  console.log(`Found ${activeIds.length} active images to process\n`);

  let processed = 0;
  let skipped = 0;
  let errors = 0;

  for (const docId of activeIds) {
    const docRef = firestore.collection('image-docs').doc(docId);
    const doc = await docRef.get();

    if (!doc.exists) {
      console.log(`Skipping ${docId} - document not found`);
      skipped++;
      continue;
    }

    const data = doc.data()!;

    // Skip if already cached with actual data (not empty error results)
    if (data.webDetection && data.webDetection.webEntities?.length > 0) {
      console.log(`Skipping ${docId} - already cached`);
      skipped++;
      continue;
    }

    const fileName = data.name;
    if (!fileName) {
      console.log(`Skipping ${docId} - no filename`);
      skipped++;
      continue;
    }

    const webDetectionData = await processImage(docId, fileName);

    if (webDetectionData) {
      await docRef.update({webDetection: webDetectionData});
      processed++;
    } else {
      // Store empty result to avoid re-processing
      await docRef.update({
        webDetection: {
          webEntities: [],
          fullMatchingImages: [],
          partialMatchingImages: [],
          pagesWithMatchingImages: [],
          visuallySimilarImages: [],
          bestGuessLabels: [],
          cachedAt: admin.firestore.Timestamp.now(),
        },
      });
      errors++;
    }

    // Rate limiting
    await sleep(DELAY_MS);
  }

  console.log('\n=== Summary ===');
  console.log(`Processed: ${processed}`);
  console.log(`Skipped (already cached): ${skipped}`);
  console.log(`Errors/Empty: ${errors}`);
  console.log(`Total: ${activeIds.length}`);

  process.exit(0);
}

main().catch((error) => {
  console.error('Fatal error:', error);
  process.exit(1);
});
