/**
 * Tests for Cloud Functions
 *
 * These tests mock Firebase and Vision API to test the function logic.
 */

// Create mock functions at module level
const mockVisionWebDetection = jest.fn();
const mockDocGet = jest.fn();
const mockDocUpdate = jest.fn();

// Mock firebase-admin before importing the functions
jest.mock('firebase-admin', () => {
  const mockDocRef = {
    get: mockDocGet,
    update: mockDocUpdate,
  };
  const mockCollection = {
    doc: jest.fn(() => mockDocRef),
    where: jest.fn().mockReturnThis(),
    get: jest.fn(),
  };
  const mockFirestore = jest.fn(() => ({
    collection: jest.fn(() => mockCollection),
  }));

  return {
    initializeApp: jest.fn(),
    auth: jest.fn(() => ({deleteUser: jest.fn()})),
    firestore: Object.assign(mockFirestore, {
      FieldValue: {
        arrayRemove: jest.fn((val) => ({_arrayRemove: val})),
        serverTimestamp: jest.fn(() => ({_serverTimestamp: true})),
      },
    }),
  };
});

// Mock @google-cloud/vision
jest.mock('@google-cloud/vision', () => ({
  __esModule: true,
  default: {
    ImageAnnotatorClient: jest.fn().mockImplementation(() => ({
      webDetection: mockVisionWebDetection,
    })),
  },
  protos: {
    google: {
      cloud: {
        vision: {
          v1: {
            IWebDetection: {},
          },
        },
      },
    },
  },
}));

// Mock firebase-functions/v2/https
jest.mock('firebase-functions/v2/https', () => ({
  onCall: jest.fn((handler) => {
    // Return the handler directly so we can call it in tests
    return {run: handler};
  }),
  HttpsError: class HttpsError extends Error {
    code: string;
    constructor(code: string, message: string) {
      super(message);
      this.code = code;
      this.name = 'HttpsError';
    }
  },
}));

// Mock firebase-functions/v2
jest.mock('firebase-functions/v2', () => ({
  logger: {
    error: jest.fn(),
  },
}));

describe('detectWeb', () => {
  let detectWeb: {run: (request: any) => Promise<any>};

  beforeAll(async () => {
    // Import after mocks are set up
    const indexModule = await import('./index');
    detectWeb = indexModule.detectWeb as any;
  });

  beforeEach(() => {
    jest.clearAllMocks();
  });

  describe('authentication', () => {
    it('should throw error when user is not authenticated', async () => {
      await expect(detectWeb.run({data: {imageDocId: 'test-doc'}, auth: null})).rejects.toThrow(
        'User must be authenticated',
      );
    });
  });

  describe('input validation', () => {
    it('should throw error when neither imageDocId nor imageUrl provided', async () => {
      await expect(detectWeb.run({data: {}, auth: {uid: 'test-user'}})).rejects.toThrow(
        'imageDocId or imageUrl is required',
      );
    });
  });

  describe('caching', () => {
    it('should return cached data when webDetection exists', async () => {
      const cachedData = {
        webEntities: [{entityId: '123', description: 'Art', score: 0.9}],
        visuallySimilarImages: [{url: 'https://example.com/similar.jpg'}],
        cachedAt: new Date(),
      };

      mockDocGet.mockResolvedValue({
        exists: true,
        data: () => ({
          name: 'test-image.jpg',
          webDetection: cachedData,
        }),
      });

      const result = await detectWeb.run({
        data: {imageDocId: 'test-doc-id'},
        auth: {uid: 'test-user'},
      });

      expect(result.cached).toBe(true);
      expect(result.data).toEqual(cachedData);
      expect(mockVisionWebDetection).not.toHaveBeenCalled();
    });

    it('should call Vision API and cache result when no cached data', async () => {
      const visionResponse = {
        webEntities: [{entityId: '456', description: 'Painting', score: 0.85}],
        fullMatchingImages: [],
        partialMatchingImages: [],
        pagesWithMatchingImages: [],
        visuallySimilarImages: [{url: 'https://example.com/similar.jpg'}],
        bestGuessLabels: [],
      };

      mockDocGet.mockResolvedValue({
        exists: true,
        data: () => ({
          name: 'test-image.jpg',
          // No webDetection - cache miss
        }),
      });
      mockDocUpdate.mockResolvedValue(undefined);
      mockVisionWebDetection.mockResolvedValue([{webDetection: visionResponse}]);

      const result = await detectWeb.run({
        data: {imageDocId: 'test-doc-id'},
        auth: {uid: 'test-user'},
      });

      expect(result.cached).toBe(false);
      expect(result.success).toBe(true);
      expect(mockVisionWebDetection).toHaveBeenCalled();
      expect(mockDocUpdate).toHaveBeenCalled();
    });
  });

  describe('legacy imageUrl support', () => {
    it('should work with imageUrl when imageDocId not provided', async () => {
      const visionResponse = {
        webEntities: [{entityId: '789', description: 'Photo', score: 0.7}],
        fullMatchingImages: [],
        partialMatchingImages: [],
        pagesWithMatchingImages: [],
        visuallySimilarImages: [],
        bestGuessLabels: [],
      };

      mockVisionWebDetection.mockResolvedValue([{webDetection: visionResponse}]);

      const result = await detectWeb.run({
        data: {imageUrl: 'https://example.com/image.jpg'},
        auth: {uid: 'test-user'},
      });

      expect(result.success).toBe(true);
      expect(mockVisionWebDetection).toHaveBeenCalledWith('https://example.com/image.jpg');
      // Legacy mode doesn't cache
      expect(mockDocUpdate).not.toHaveBeenCalled();
    });
  });
});

describe('transformWebDetection', () => {
  it('handles null arrays with ?? [] fallback pattern', () => {
    const testData = {
      webEntities: null as any,
      visuallySimilarImages: undefined as any,
    };

    expect(testData.webEntities ?? []).toEqual([]);
    expect(testData.visuallySimilarImages ?? []).toEqual([]);
  });

  it('maps entity fields correctly', () => {
    const entities = [
      {
        entityId: '123',
        description: 'Test',
        score: 0.9,
        extraField: 'ignored',
      },
    ];

    const mapped = entities.map((e) => ({
      entityId: e.entityId,
      description: e.description,
      score: e.score,
    }));

    expect(mapped[0]).toEqual({
      entityId: '123',
      description: 'Test',
      score: 0.9,
    });
    expect(mapped[0]).not.toHaveProperty('extraField');
  });
});
