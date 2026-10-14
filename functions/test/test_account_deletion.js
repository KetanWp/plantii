/**
 * Account Deletion & Privacy Consent Unit Tests
 *
 * Verifies:
 * 1. POST /consent records version and timestamp on users/{uid}
 * 2. DELETE /account deletes all user scans, feedback, and user document
 * 3. DELETE /account deletes the Firebase Auth user
 * 4. Other users' data remains completely unaffected
 * 5. Partial failure scenarios are safely handled
 * 6. Unauthenticated requests are rejected
 */

const assert = require('assert');
const admin = require('firebase-admin');

// Initialize dummy app if not already initialized
if (!admin.apps.length) {
  admin.initializeApp({
    projectId: 'plantii-test',
  });
}

const { handleConsent, handleDeleteAccount } = require('../routes/account');
const { deleteUserData, recordUserConsent } = require('../services/firestoreService');

function createMockReqRes(options = {}) {
  const req = {
    method: options.method || 'POST',
    url: options.url || '/consent',
    headers: options.headers || {},
    body: options.body || {},
    query: options.query || {},
    user: options.user || null,
  };

  const res = {
    statusCode: 200,
    body: null,
    status(code) {
      this.statusCode = code;
      return this;
    },
    json(data) {
      this.body = data;
      return this;
    },
  };

  return { req, res };
}

// In-memory Firestore Store Simulation for reliable unit testing
function createMockFirestore() {
  const store = {
    scans: new Map(),
    feedback: new Map(),
    users: new Map(),
  };

  const mockDb = {
    store,
    collection(name) {
      const colMap = store[name] || new Map();
      store[name] = colMap;

      return {
        doc(id) {
          const docId = id || `doc_${Date.now()}_${Math.random().toString(36).substring(2, 7)}`;
          return {
            id: docId,
            ref: { id: docId, collection: name },
            async get() {
              const data = colMap.get(docId);
              return {
                id: docId,
                exists: data !== undefined,
                data: () => data,
              };
            },
            async set(data, options = {}) {
              if (options.merge && colMap.has(docId)) {
                colMap.set(docId, { ...colMap.get(docId), ...data });
              } else {
                colMap.set(docId, data);
              }
            },
            async delete() {
              colMap.delete(docId);
            },
          };
        },
        where(field, op, val) {
          return {
            async get() {
              const matchingDocs = [];
              for (const [id, data] of colMap.entries()) {
                if (op === '==' && data[field] === val) {
                  matchingDocs.push({
                    id,
                    ref: { id, collection: name },
                    data: () => data,
                  });
                }
              }
              return {
                empty: matchingDocs.length === 0,
                size: matchingDocs.length,
                forEach(cb) {
                  matchingDocs.forEach(cb);
                },
              };
            },
          };
        },
      };
    },
    batch() {
      const operations = [];
      return {
        delete(docRef) {
          operations.push(() => {
            const col = store[docRef.collection];
            if (col) col.delete(docRef.id);
          });
          return this;
        },
        async commit() {
          for (const op of operations) op();
        },
      };
    },
  };

  return mockDb;
}

function mockAdminFirestore(mockDb) {
  const mockFn = () => mockDb;
  mockFn.FieldValue = {
    serverTimestamp: () => new Date(),
  };
  Object.defineProperty(admin, 'firestore', {
    value: mockFn,
    configurable: true,
    writable: true,
  });
  return () => {
    delete admin.firestore;
  };
}

function mockAdminAuth(mockAuth) {
  Object.defineProperty(admin, 'auth', {
    value: () => mockAuth,
    configurable: true,
    writable: true,
  });
  return () => {
    delete admin.auth;
  };
}

async function runTests() {
  console.log('Running Plantii Account Deletion & Consent Tests...\n');

  // ============================================================================
  // TEST 1: Unauthenticated Requests are Rejected
  // ============================================================================
  console.log('Test 1: Unauthenticated Requests are Rejected');
  {
    // Test Consent without user
    const { req: consentReq, res: consentRes } = createMockReqRes({ user: null });
    await handleConsent(consentReq, consentRes);
    assert.strictEqual(consentRes.statusCode, 401, 'Consent requires authentication');

    // Test Delete Account without user
    const { req: deleteReq, res: deleteRes } = createMockReqRes({ user: null });
    await handleDeleteAccount(deleteReq, deleteRes);
    assert.strictEqual(deleteRes.statusCode, 401, 'Delete account requires authentication');
    console.log('  Passed: Unauthenticated /consent and /account rejected with HTTP 401');
  }

  // ============================================================================
  // TEST 2: POST /consent records version and timestamp
  // ============================================================================
  console.log('Test 2: POST /consent Records Policy Version on User Document');
  {
    const testUid = 'farmer_consent_uid_101';
    const mockDb = createMockFirestore();
    const restoreFirestore = mockAdminFirestore(mockDb);

    try {
      await recordUserConsent({ userId: testUid, consentVersion: '1.0' });
      const userDoc = await mockDb.collection('users').doc(testUid).get();
      assert.strictEqual(userDoc.exists, true, 'User document should exist');
      assert.strictEqual(userDoc.data().consentVersion, '1.0', 'Consent version must be 1.0');
      assert(userDoc.data().consentedAt !== undefined, 'consentedAt timestamp must be recorded');
      console.log('  Passed: Consent recorded on users/{uid} with version 1.0 and timestamp');
    } finally {
      restoreFirestore();
    }
  }

  // ============================================================================
  // TEST 3: DELETE /account Deletes User Scans, Feedback, and Doc, leaving others intact
  // ============================================================================
  console.log('Test 3: DELETE /account Deletes All User Data and Preserves Other Users');
  {
    const targetUid = 'farmer_target_to_delete';
    const otherUid = 'farmer_innocent_bystander';
    const mockDb = createMockFirestore();

    // Populate sample data for target user
    mockDb.store.scans.set('scan_t1', { userId: targetUid, cropId: 'tomato', diseaseName: 'Blight' });
    mockDb.store.scans.set('scan_t2', { userId: targetUid, cropId: 'rice', diseaseName: 'Blast' });
    mockDb.store.feedback.set('fb_t1', { userId: targetUid, scanId: 'scan_t1', helpful: true });
    mockDb.store.feedback.set('fb_t2', { userId: targetUid, scanId: 'scan_t2', helpful: false });
    mockDb.store.users.set(targetUid, { scanCount: 5, consentVersion: '1.0' });

    // Populate sample data for other user
    mockDb.store.scans.set('scan_o1', { userId: otherUid, cropId: 'potato', diseaseName: 'Scab' });
    mockDb.store.feedback.set('fb_o1', { userId: otherUid, scanId: 'scan_o1', helpful: true });
    mockDb.store.users.set(otherUid, { scanCount: 2, consentVersion: '1.0' });

    let authUserDeleted = null;
    const restoreFirestore = mockAdminFirestore(mockDb);
    const restoreAuth = mockAdminAuth({
      async deleteUser(uid) {
        authUserDeleted = uid;
      },
    });

    const { req, res } = createMockReqRes({
      method: 'DELETE',
      url: '/account',
      user: { uid: targetUid },
    });

    try {
      await handleDeleteAccount(req, res);

      // 1. Verify response
      assert.strictEqual(res.statusCode, 200, 'Must return HTTP 200 on success');
      assert.strictEqual(res.body?.success, true, 'success field must be true');
      assert.strictEqual(res.body?.deleted?.deletedScans, 2, 'Should report 2 scans deleted');
      assert.strictEqual(res.body?.deleted?.deletedFeedback, 2, 'Should report 2 feedback deleted');
      assert.strictEqual(res.body?.deleted?.userDocDeleted, true, 'User doc must be reported deleted');

      // 2. Verify target user data is deleted from store
      assert.strictEqual(mockDb.store.scans.has('scan_t1'), false, 'Scan 1 must be deleted');
      assert.strictEqual(mockDb.store.scans.has('scan_t2'), false, 'Scan 2 must be deleted');
      assert.strictEqual(mockDb.store.feedback.has('fb_t1'), false, 'Feedback 1 must be deleted');
      assert.strictEqual(mockDb.store.feedback.has('fb_t2'), false, 'Feedback 2 must be deleted');
      assert.strictEqual(mockDb.store.users.has(targetUid), false, 'Target user doc must be deleted');

      // 3. Verify other user's data is 100% PRESERVED
      assert.strictEqual(mockDb.store.scans.has('scan_o1'), true, 'Other user scan must be preserved');
      assert.strictEqual(mockDb.store.feedback.has('fb_o1'), true, 'Other user feedback must be preserved');
      assert.strictEqual(mockDb.store.users.has(otherUid), true, 'Other user doc must be preserved');

      // 4. Verify Auth user was deleted
      assert.strictEqual(authUserDeleted, targetUid, 'Firebase Auth user must be deleted');

      console.log('  Passed: Target scans, feedback, user document, and Auth user deleted; other data intact.');
    } finally {
      restoreFirestore();
      restoreAuth();
    }
  }

  // ============================================================================
  // TEST 4: Partial Failure Handling (Auth delete fails after Firestore delete)
  // ============================================================================
  console.log('Test 4: Partial Failure Returns Clear Error Code');
  {
    const targetUid = 'farmer_partial_fail';
    const mockDb = createMockFirestore();
    mockDb.store.users.set(targetUid, { scanCount: 1 });

    const restoreFirestore = mockAdminFirestore(mockDb);
    const restoreAuth = mockAdminAuth({
      async deleteUser() {
        const err = new Error('Auth server error');
        err.code = 'auth/internal-error';
        throw err;
      },
    });

    const { req, res } = createMockReqRes({
      method: 'DELETE',
      url: '/account',
      user: { uid: targetUid },
    });

    try {
      await handleDeleteAccount(req, res);
      assert.strictEqual(res.statusCode, 500, 'Partial failure returns HTTP 500');
      assert.strictEqual(res.body?.error?.code, 'partial_failure', 'Code must be partial_failure');
      assert.strictEqual(res.body?.error?.details?.firestoreDeleted, true);
      assert.strictEqual(res.body?.error?.details?.authDeleted, false);
      console.log('  Passed: Partial failure returns HTTP 500 with code partial_failure and details');
    } finally {
      restoreFirestore();
      restoreAuth();
    }
  }

  console.log('\n======================================================');
  console.log('All Account Deletion & Consent Tests PASSED Successfully!');
  console.log('======================================================\n');
}

runTests().catch((err) => {
  console.error('Test suite failed:', err);
  process.exit(1);
});
