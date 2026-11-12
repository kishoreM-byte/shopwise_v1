const fs = require('fs');
const path = require('path');
const {
  initializeTestEnvironment,
  assertSucceeds,
  assertFails,
} = require('@firebase/rules-unit-testing');
const {
  doc,
  setDoc,
  updateDoc,
  getDoc,
  deleteDoc,
  writeBatch,
  runTransaction,
  Timestamp,
} = require('firebase/firestore');

const PROJECT_ID = 'shopwise-160a3';

const CUSTOMER_UID = 'test-customer-001';
const OWNER_UID = 'test-owner-001';
const ATTACKER_UID = 'test-attacker-001';

const ENQUIRY_ID = 'enquiry-test-001';
const NOTIFICATION_ID = `${ENQUIRY_ID}_accepted`;
const ORDER_ID = ENQUIRY_ID;

const PRODUCT_ID = 'product-test-001';
const SHOP_ID = 'shop-test-001';

let testEnv;
let customerDb;
let ownerDb;
let attackerDb;

function enquiryData(overrides = {}) {
  return {
    id: ENQUIRY_ID,
    productId: PRODUCT_ID,
    shopId: SHOP_ID,
    ownerId: OWNER_UID,
    customerId: CUSTOMER_UID,
    customerName: 'Test Customer',
    customerEmail: 'customer@example.com',
    customerPhone: '9000000000',
    productName: 'Test Product',
    productPrice: 10000,
    quantity: 2,
    message: 'I would like to enquire about this product.',
    status: 'pending',
    createdAt: Timestamp.fromDate(new Date('2026-08-30T10:00:00Z')),
    updatedAt: Timestamp.fromDate(new Date('2026-08-30T10:00:00Z')),
    ...overrides,
  };
}

function orderData(overrides = {}) {
  return {
    id: ORDER_ID,
    enquiryId: ENQUIRY_ID,
    productId: PRODUCT_ID,
    shopId: SHOP_ID,
    ownerId: OWNER_UID,
    customerId: CUSTOMER_UID,
    productName: 'Test Product',
    quantity: 2,
    unitPrice: 10000,
    subtotal: 20000,
    deliveryCharge: 500,
    installationCharge: 500,
    totalAmount: 21000,
    inventoryAdjusted: true,
    purchaseMode: 'enquiry',
    fulfillmentType: 'delivery',
    status: 'placed',
    purchaseStatus: 'purchased',
    createdAt: Timestamp.fromDate(new Date('2026-08-30T10:05:00Z')),
    updatedAt: Timestamp.fromDate(new Date('2026-08-30T10:05:00Z')),
    ...overrides,
  };
}

function notificationData(overrides = {}) {
  return {
    id: NOTIFICATION_ID,
    userId: CUSTOMER_UID,
    type: 'enquiry_accepted',
    title: 'Enquiry accepted',
    message: 'Your enquiry for Test Product has been accepted by the shop.',
    productId: PRODUCT_ID,
    shopId: SHOP_ID,
    enquiryId: ENQUIRY_ID,
    isRead: false,
    createdAt: Timestamp.fromDate(new Date('2026-08-30T10:01:00Z')),
    ...overrides,
  };
}

async function seedDoc(collection, id, data) {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    await setDoc(doc(context.firestore(), collection, id), data);
  });
}

beforeAll(async () => {
  const rules = fs.readFileSync(
    path.join(__dirname, '..', 'firestore.rules'),
    'utf8',
  );

  testEnv = await initializeTestEnvironment({
    projectId: PROJECT_ID,
    firestore: {
      rules,
    },
  });

  customerDb = testEnv.authenticatedContext(CUSTOMER_UID).firestore();
  ownerDb = testEnv.authenticatedContext(OWNER_UID).firestore();
  attackerDb = testEnv.authenticatedContext(ATTACKER_UID).firestore();

  await testEnv.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();

    await setDoc(doc(db, 'shops', SHOP_ID), {
      id: SHOP_ID,
      ownerId: OWNER_UID,
      name: 'Test Shop',
      deliveryAvailable: true,
      deliveryCharge: 500,
    });

    await setDoc(doc(db, 'products', PRODUCT_ID), {
      id: PRODUCT_ID,
      shopId: SHOP_ID,
      ownerId: OWNER_UID,
      name: 'Test Product',
      price: 10000,
      stock: 5,
      isAvailable: true,
      imageUrls: [],
      deliveryAvailable: true,
    });

    await setDoc(
      doc(db, 'enquiries', ENQUIRY_ID),
      enquiryData(),
    );
  });
});

afterEach(async () => {
  if (testEnv) {
    await testEnv.clearFirestore();
  }
});

afterAll(async () => {
  if (testEnv) {
    await testEnv.cleanup();
  }
});

describe('ShopWise Firestore security rules', () => {

  test('customer can read their own enquiry', async () => {
    await setDoc(
      doc(customerDb, 'enquiries', ENQUIRY_ID),
      enquiryData(),
    ).catch(() => {});

    await assertSucceeds(
      getDoc(doc(customerDb, 'enquiries', ENQUIRY_ID)),
    );
  });

  test('owner can hide a product without deleting its record', async () => {
    await seedDoc('products', PRODUCT_ID, {
      id: PRODUCT_ID,
      shopId: SHOP_ID,
      ownerId: OWNER_UID,
      name: 'Test Product',
      price: 10000,
      stock: 5,
      isAvailable: true,
      imageUrls: [],
    });

    await assertSucceeds(
      updateDoc(doc(ownerDb, 'products', PRODUCT_ID), {
        isAvailable: false,
        updatedAt: Timestamp.fromDate(
          new Date('2026-10-22T10:00:00Z'),
        ),
      }),
    );

    const snapshot = await getDoc(doc(ownerDb, 'products', PRODUCT_ID));
    expect(snapshot.exists()).toBe(true);
    expect(snapshot.data().isAvailable).toBe(false);
  });

  test('owner cannot hard-delete a product record', async () => {
    await seedDoc('products', PRODUCT_ID, {
      id: PRODUCT_ID,
      shopId: SHOP_ID,
      ownerId: OWNER_UID,
      name: 'Test Product',
      price: 10000,
      stock: 5,
      isAvailable: true,
      imageUrls: [],
    });

    await assertFails(
      deleteDoc(doc(ownerDb, 'products', PRODUCT_ID)),
    );
  });


  test('owner cannot create a product with negative or fractional stock', async () => {
    await seedDoc('shops', SHOP_ID, {
      id: SHOP_ID,
      ownerId: OWNER_UID,
      name: 'Test Shop',
    });

    for (const stock of [-1, 1.5]) {
      await assertFails(
        setDoc(doc(ownerDb, 'products', PRODUCT_ID), {
          id: PRODUCT_ID,
          shopId: SHOP_ID,
          ownerId: OWNER_UID,
          name: 'Test Product',
          category: 'Furniture',
          description: '',
          price: 10000,
          stock,
          isAvailable: true,
          imageUrls: [],
          rating: 0,
          reviewCount: 0,
          hasOffer: false,
        }),
      );
    }
  });

  test('owner cannot update product stock to negative or fractional values', async () => {
    await seedDoc('products', PRODUCT_ID, {
      id: PRODUCT_ID,
      shopId: SHOP_ID,
      ownerId: OWNER_UID,
      name: 'Test Product',
      category: 'Furniture',
      description: '',
      price: 10000,
      stock: 5,
      isAvailable: true,
      imageUrls: [],
      rating: 0,
      reviewCount: 0,
      hasOffer: false,
    });

    for (const stock of [-1, 1.5]) {
      await assertFails(
        updateDoc(doc(ownerDb, 'products', PRODUCT_ID), { stock }),
      );
    }

    expect((await getDoc(doc(ownerDb, 'products', PRODUCT_ID))).data().stock)
      .toBe(5);
  });

  test('customer can delete their own pending enquiry', async () => {
    await seedDoc('enquiries', ENQUIRY_ID, enquiryData());

    await assertSucceeds(
      deleteDoc(doc(customerDb, 'enquiries', ENQUIRY_ID)),
    );
  });

  test('customer cannot delete an accepted enquiry', async () => {
    await seedDoc(
      'enquiries',
      ENQUIRY_ID,
      enquiryData({ status: 'accepted' }),
    );

    await assertFails(
      deleteDoc(doc(customerDb, 'enquiries', ENQUIRY_ID)),
    );
  });

  test('customer cannot delete a purchased or order-linked enquiry', async () => {
    for (const overrides of [
      { orderId: ORDER_ID },
      { purchaseStatus: 'purchased' },
    ]) {
      await testEnv.clearFirestore();
      await seedDoc(
        'enquiries',
        ENQUIRY_ID,
        enquiryData({ status: 'accepted', ...overrides }),
      );

      await assertFails(
        deleteDoc(doc(customerDb, 'enquiries', ENQUIRY_ID)),
      );
    }
  });

  test('attacker cannot read another customer enquiry', async () => {
    await seedDoc(
      'enquiries',
      ENQUIRY_ID,
      enquiryData(),
    );

    await assertFails(
      getDoc(doc(attackerDb, 'enquiries', ENQUIRY_ID)),
    );
  });

  test('owner can read enquiries belonging to the owner', async () => {
    await seedDoc(
      'enquiries',
      ENQUIRY_ID,
      enquiryData(),
    );

    await assertSucceeds(
      getDoc(doc(ownerDb, 'enquiries', ENQUIRY_ID)),
    );
  });

  test('attacker cannot read owner enquiries', async () => {
    await seedDoc(
      'enquiries',
      ENQUIRY_ID,
      enquiryData(),
    );

    await assertFails(
      getDoc(doc(attackerDb, 'enquiries', ENQUIRY_ID)),
    );
  });

  test('owner acceptance creates the customer notification atomically', async () => {
    await seedDoc(
      'enquiries',
      ENQUIRY_ID,
      enquiryData(),
    );

    const batch = writeBatch(ownerDb);

    batch.update(
      doc(ownerDb, 'enquiries', ENQUIRY_ID),
      {
        status: 'accepted',
        updatedAt: Timestamp.fromDate(new Date('2026-08-30T10:01:00Z')),
      },
    );

    batch.set(
      doc(ownerDb, 'notifications', NOTIFICATION_ID),
      notificationData(),
    );

    await assertSucceeds(batch.commit());

    const enquiry = await getDoc(
      doc(ownerDb, 'enquiries', ENQUIRY_ID),
    );

    const notification = await getDoc(
      doc(customerDb, 'notifications', NOTIFICATION_ID),
    );

    if (!enquiry.exists()) {
      throw new Error('Accepted enquiry was not created.');
    }

    if (enquiry.data().status !== 'accepted') {
      throw new Error('Enquiry was not accepted.');
    }

    if (!notification.exists()) {
      throw new Error('Customer notification was not created.');
    }

    if (notification.data().userId !== CUSTOMER_UID) {
      throw new Error('Notification userId is incorrect.');
    }
  });

  test('attacker cannot create a forged enquiry-accepted notification', async () => {
    await seedDoc(
      'enquiries',
      ENQUIRY_ID,
      enquiryData({
        status: 'accepted',
      }),
    );

    await assertFails(
      setDoc(
        doc(attackerDb, 'notifications', NOTIFICATION_ID),
        notificationData(),
      ),
    );
  });

  test('customer can read their own notification', async () => {
    await seedDoc(
      'notifications',
      NOTIFICATION_ID,
      notificationData(),
    );

    await assertSucceeds(
      getDoc(doc(customerDb, 'notifications', NOTIFICATION_ID)),
    );
  });

  test('attacker cannot read another customer notification', async () => {
    await seedDoc(
      'notifications',
      NOTIFICATION_ID,
      notificationData(),
    );

    await assertFails(
      getDoc(doc(attackerDb, 'notifications', NOTIFICATION_ID)),
    );
  });

  test('customer can mark their notification as read', async () => {
    await seedDoc(
      'notifications',
      NOTIFICATION_ID,
      notificationData(),
    );

    await assertSucceeds(
      updateDoc(
        doc(customerDb, 'notifications', NOTIFICATION_ID),
        {
          isRead: true,
        },
      ),
    );

    const notification = await getDoc(
      doc(customerDb, 'notifications', NOTIFICATION_ID),
    );

    if (notification.data().isRead !== true) {
      throw new Error('Notification was not marked as read.');
    }
  });

  test('customer cannot modify protected notification fields', async () => {
    await seedDoc(
      'notifications',
      NOTIFICATION_ID,
      notificationData(),
    );

    await assertFails(
      updateDoc(
        doc(customerDb, 'notifications', NOTIFICATION_ID),
        {
          title: 'Forged notification',
        },
      ),
    );
  });

  test('customer can create a valid order only from an accepted enquiry', async () => {
    await seedDoc(
      'shops',
      SHOP_ID,
      {
        id: SHOP_ID,
        ownerId: OWNER_UID,
        name: 'Test Shop',
        deliveryAvailable: true,
        deliveryCharge: 500,
        installationAvailable: true,
        installationCharge: 500,
      },
    );

    await seedDoc(
      'enquiries',
      ENQUIRY_ID,
      enquiryData({
        status: 'accepted',
      }),
    );

    await seedDoc('products', PRODUCT_ID, {
      id: PRODUCT_ID,
      shopId: SHOP_ID,
      ownerId: OWNER_UID,
      name: 'Test Product',
      price: 10000,
      stock: 5,
      isAvailable: true,
      imageUrls: [],
    });

    const batch = writeBatch(customerDb);
    batch.update(doc(customerDb, 'products', PRODUCT_ID), {
      stock: 3,
      lastStockOrderId: ORDER_ID,
    });
    batch.set(doc(customerDb, 'orders', ORDER_ID), orderData());
    batch.update(doc(customerDb, 'enquiries', ENQUIRY_ID), {
      orderId: ORDER_ID,
      purchaseStatus: 'purchased',
      purchasedAt: Timestamp.fromDate(new Date('2026-08-30T10:05:00Z')),
      updatedAt: Timestamp.fromDate(new Date('2026-08-30T10:05:00Z')),
    });
    await assertSucceeds(batch.commit());
  });

  test('accepted enquiry checkout cannot change unrelated or reused fields', async () => {
    await seedDoc('shops', SHOP_ID, {
      id: SHOP_ID,
      ownerId: OWNER_UID,
      name: 'Test Shop',
      deliveryAvailable: true,
      deliveryCharge: 500,
      installationAvailable: true,
      installationCharge: 500,
    });
    await seedDoc('products', PRODUCT_ID, {
      id: PRODUCT_ID,
      shopId: SHOP_ID,
      ownerId: OWNER_UID,
      name: 'Test Product',
      price: 10000,
      stock: 5,
      isAvailable: true,
      imageUrls: [],
    });

    await seedDoc('enquiries', ENQUIRY_ID, enquiryData({ status: 'accepted' }));
    const tamperingBatch = writeBatch(customerDb);
    tamperingBatch.update(doc(customerDb, 'products', PRODUCT_ID), {
      stock: 3,
      lastStockOrderId: ORDER_ID,
    });
    tamperingBatch.set(doc(customerDb, 'orders', ORDER_ID), orderData());
    tamperingBatch.update(doc(customerDb, 'enquiries', ENQUIRY_ID), {
      orderId: ORDER_ID,
      purchaseStatus: 'purchased',
      purchasedAt: Timestamp.fromDate(new Date('2026-08-30T10:05:00Z')),
      updatedAt: Timestamp.fromDate(new Date('2026-08-30T10:05:00Z')),
      customerEmail: 'forged@example.com',
    });
    await assertFails(tamperingBatch.commit());

    await seedDoc('enquiries', ENQUIRY_ID, enquiryData({
      status: 'accepted',
      orderId: 'preexisting-order-id',
    }));
    const reusedBatch = writeBatch(customerDb);
    reusedBatch.update(doc(customerDb, 'products', PRODUCT_ID), {
      stock: 3,
      lastStockOrderId: ORDER_ID,
    });
    reusedBatch.set(doc(customerDb, 'orders', ORDER_ID), orderData());
    reusedBatch.update(doc(customerDb, 'enquiries', ENQUIRY_ID), {
      orderId: ORDER_ID,
      purchaseStatus: 'purchased',
      purchasedAt: Timestamp.fromDate(new Date('2026-08-30T10:05:00Z')),
      updatedAt: Timestamp.fromDate(new Date('2026-08-30T10:05:00Z')),
    });
    await assertFails(reusedBatch.commit());

    await seedDoc('enquiries', ENQUIRY_ID, enquiryData({ status: 'accepted' }));
    const badPriceBatch = writeBatch(customerDb);
    badPriceBatch.update(doc(customerDb, 'products', PRODUCT_ID), {
      stock: 3,
      lastStockOrderId: ORDER_ID,
    });
    badPriceBatch.set(doc(customerDb, 'orders', ORDER_ID), orderData({
      installationCharge: 900,
      totalAmount: 21400,
    }));
    badPriceBatch.update(doc(customerDb, 'enquiries', ENQUIRY_ID), {
      orderId: ORDER_ID,
      purchaseStatus: 'purchased',
      purchasedAt: Timestamp.fromDate(new Date('2026-08-30T10:05:00Z')),
      updatedAt: Timestamp.fromDate(new Date('2026-08-30T10:05:00Z')),
    });
    await assertFails(badPriceBatch.commit());
  });

  test('customer cannot create an order from a pending enquiry', async () => {
    await seedDoc(
      'enquiries',
      ENQUIRY_ID,
      enquiryData({
        status: 'pending',
      }),
    );

    await assertFails(
      setDoc(
        doc(customerDb, 'orders', ORDER_ID),
        orderData(),
      ),
    );
  });

  test('accepted-enquiry order must preserve the enquiry quantity', async () => {
    await seedDoc('shops', SHOP_ID, {
      id: SHOP_ID,
      ownerId: OWNER_UID,
      name: 'Test Shop',
      deliveryAvailable: true,
      deliveryCharge: 500,
      installationAvailable: true,
      installationCharge: 500,
    });
    await seedDoc('enquiries', ENQUIRY_ID, enquiryData({ status: 'accepted' }));
    await seedDoc('products', PRODUCT_ID, {
      id: PRODUCT_ID,
      shopId: SHOP_ID,
      ownerId: OWNER_UID,
      name: 'Test Product',
      price: 10000,
      stock: 5,
      isAvailable: true,
      imageUrls: [],
    });

    const batch = writeBatch(customerDb);
    batch.update(doc(customerDb, 'products', PRODUCT_ID), {
      stock: 4,
      lastStockOrderId: ORDER_ID,
    });
    batch.set(doc(customerDb, 'orders', ORDER_ID), orderData({
      quantity: 1,
      subtotal: 10000,
      totalAmount: 11000,
    }));
    await assertFails(batch.commit());
  });

  test('direct order requires the matching atomic stock decrement', async () => {
    await seedDoc('shops', SHOP_ID, {
      id: SHOP_ID,
      ownerId: OWNER_UID,
      name: 'Test Shop',
      deliveryAvailable: false,
      deliveryCharge: 500,
    });
    await seedDoc('products', PRODUCT_ID, {
      id: PRODUCT_ID,
      shopId: SHOP_ID,
      ownerId: OWNER_UID,
      name: 'Test Product',
      price: 10000,
      stock: 5,
      isAvailable: true,
      imageUrls: [],
    });

    const directId = 'direct-order-1';
    const batch = writeBatch(customerDb);
    batch.update(doc(customerDb, 'products', PRODUCT_ID), {
      stock: 4,
      lastStockOrderId: directId,
    });
    batch.set(
      doc(customerDb, 'orders', directId),
      orderData({
        id: directId,
        enquiryId: '',
        purchaseMode: 'offline',
        fulfillmentType: 'pickup',
        quantity: 1,
        subtotal: 10000,
        deliveryCharge: 0,
        installationCharge: 0,
        totalAmount: 10000,
      }),
    );

    await assertSucceeds(batch.commit());
  });

  test('direct checkout cannot invent an installation charge', async () => {
    await seedDoc('shops', SHOP_ID, {
      id: SHOP_ID,
      ownerId: OWNER_UID,
      name: 'Test Shop',
      deliveryAvailable: false,
      deliveryCharge: 500,
    });
    await seedDoc('products', PRODUCT_ID, {
      id: PRODUCT_ID,
      shopId: SHOP_ID,
      ownerId: OWNER_UID,
      name: 'Test Product',
      price: 10000,
      stock: 5,
      isAvailable: true,
      imageUrls: [],
    });

    const directId = 'direct-installation-fee-1';
    const batch = writeBatch(customerDb);
    batch.update(doc(customerDb, 'products', PRODUCT_ID), {
      stock: 4,
      lastStockOrderId: directId,
    });
    batch.set(doc(customerDb, 'orders', directId), orderData({
      id: directId,
      enquiryId: '',
      purchaseMode: 'offline',
      fulfillmentType: 'pickup',
      quantity: 1,
      subtotal: 10000,
      deliveryCharge: 0,
      installationCharge: 250,
      totalAmount: 10250,
    }));

    await assertFails(batch.commit());
  });

  test('concurrent direct orders cannot reserve the final unit twice', async () => {
    await seedDoc('shops', SHOP_ID, {
      id: SHOP_ID,
      ownerId: OWNER_UID,
      name: 'Test Shop',
      deliveryAvailable: false,
      deliveryCharge: 500,
    });
    await seedDoc('products', PRODUCT_ID, {
      id: PRODUCT_ID,
      shopId: SHOP_ID,
      ownerId: OWNER_UID,
      name: 'Test Product',
      price: 10000,
      stock: 1,
      isAvailable: true,
      imageUrls: [],
    });

    const reserve = async (orderId) =>
      runTransaction(customerDb, async (transaction) => {
        const productRef = doc(customerDb, 'products', PRODUCT_ID);
        const product = await transaction.get(productRef);
        const stock = product.data().stock;
        if (stock < 1) throw new Error('Insufficient stock');
        const orderRef = doc(customerDb, 'orders', orderId);
        transaction.update(productRef, {
          stock: stock - 1,
          lastStockOrderId: orderId,
        });
        transaction.set(orderRef, orderData({
          id: orderId,
          enquiryId: '',
          purchaseMode: 'offline',
          fulfillmentType: 'pickup',
          quantity: 1,
          subtotal: 10000,
          deliveryCharge: 0,
          installationCharge: 0,
          totalAmount: 10000,
        }));
      });

    const outcomes = await Promise.allSettled([
      reserve('concurrent-order-a'),
      reserve('concurrent-order-b'),
    ]);
    expect(outcomes.filter((result) => result.status === 'fulfilled')).toHaveLength(1);
    expect((await getDoc(doc(customerDb, 'products', PRODUCT_ID))).data().stock).toBe(0);
    let createdOrders;
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      createdOrders = await Promise.all([
        getDoc(doc(db, 'orders', 'concurrent-order-a')),
        getDoc(doc(db, 'orders', 'concurrent-order-b')),
      ]);
    });
    expect(createdOrders.filter((order) => order.exists())).toHaveLength(1);
  });

  test('customer cannot decrement stock without a paired order', async () => {
    await seedDoc('products', PRODUCT_ID, {
      id: PRODUCT_ID,
      shopId: SHOP_ID,
      ownerId: OWNER_UID,
      name: 'Test Product',
      price: 10000,
      stock: 5,
      isAvailable: true,
      imageUrls: [],
    });

    await assertFails(
      updateDoc(doc(customerDb, 'products', PRODUCT_ID), {
        stock: 4,
        lastStockOrderId: 'missing-order',
      }),
    );
  });

  test('customer cannot increase stock or forge an existing order', async () => {
    await seedDoc('products', PRODUCT_ID, {
      id: PRODUCT_ID,
      shopId: SHOP_ID,
      ownerId: OWNER_UID,
      name: 'Test Product',
      price: 10000,
      stock: 3,
      isAvailable: true,
      imageUrls: [],
    });
    await seedDoc('orders', ORDER_ID, orderData());

    await assertFails(
      updateDoc(doc(customerDb, 'products', PRODUCT_ID), {
        stock: 4,
        lastStockOrderId: ORDER_ID,
      }),
    );
    await assertFails(
      setDoc(doc(customerDb, 'orders', ORDER_ID), orderData({
        inventoryAdjusted: false,
      })),
    );
  });

  test('order must match its document id and exact reserved quantity', async () => {
    await seedDoc('shops', SHOP_ID, {
      id: SHOP_ID,
      ownerId: OWNER_UID,
      name: 'Test Shop',
      deliveryAvailable: false,
      deliveryCharge: 500,
    });
    await seedDoc('products', PRODUCT_ID, {
      id: PRODUCT_ID,
      shopId: SHOP_ID,
      ownerId: OWNER_UID,
      name: 'Test Product',
      price: 10000,
      stock: 5,
      isAvailable: true,
      imageUrls: [],
    });

    const createReservationBatch = (
      orderId,
      dataId,
      reservedQuantity,
      orderQuantity,
    ) => {
      const batch = writeBatch(customerDb);
      batch.update(doc(customerDb, 'products', PRODUCT_ID), {
        stock: 5 - reservedQuantity,
        lastStockOrderId: orderId,
      });
      batch.set(
        doc(customerDb, 'orders', orderId),
        orderData({
          id: dataId,
          enquiryId: '',
          purchaseMode: 'offline',
          fulfillmentType: 'pickup',
          quantity: orderQuantity,
          subtotal: 10000 * orderQuantity,
          deliveryCharge: 0,
          installationCharge: 0,
          totalAmount: 10000 * orderQuantity,
        }),
      );
      return batch;
    };

    await assertFails(
      createReservationBatch('quantity-mismatch', 'quantity-mismatch', 1, 2).commit(),
    );
    await assertFails(
      createReservationBatch('forged-order-doc', 'different-order-id', 1, 1).commit(),
    );

    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      expect((await getDoc(doc(db, 'products', PRODUCT_ID))).data().stock).toBe(5);
      expect((await getDoc(doc(db, 'orders', 'quantity-mismatch'))).exists()).toBe(false);
      expect((await getDoc(doc(db, 'orders', 'forged-order-doc'))).exists()).toBe(false);
    });
  });

  test('owner cannot cancel a reserved order without restoring stock', async () => {
    await seedDoc('products', PRODUCT_ID, {
      id: PRODUCT_ID,
      shopId: SHOP_ID,
      ownerId: OWNER_UID,
      name: 'Test Product',
      price: 10000,
      stock: 3,
      isAvailable: true,
      imageUrls: [],
    });
    await seedDoc('orders', ORDER_ID, orderData());

    await assertFails(
      updateDoc(doc(ownerDb, 'orders', ORDER_ID), {
        status: 'cancelled',
        updatedAt: Timestamp.fromDate(new Date('2026-08-30T11:00:00Z')),
      }),
    );
  });

  test('owner cannot cancel a reserved order when its product is missing', async () => {
    // Deliberately seed the reserved order without its product document.
    await seedDoc('orders', ORDER_ID, orderData());

    await assertFails(
      updateDoc(doc(ownerDb, 'orders', ORDER_ID), {
        status: 'cancelled',
        inventoryAdjusted: false,
        updatedAt: Timestamp.fromDate(new Date('2026-08-30T11:00:00Z')),
      }),
    );

    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      const savedOrder = await getDoc(doc(db, 'orders', ORDER_ID));
      expect(savedOrder.data().status).toBe('placed');
      expect(savedOrder.data().inventoryAdjusted).toBe(true);
      expect((await getDoc(doc(db, 'products', PRODUCT_ID))).exists()).toBe(false);
    });
  });

  test('owner cannot cancel a reserved order when product stock is negative', async () => {
    // Deliberately seed invalid stock to ensure cancellation cannot legitimize it.
    await seedDoc('products', PRODUCT_ID, {
      id: PRODUCT_ID,
      shopId: SHOP_ID,
      ownerId: OWNER_UID,
      name: 'Test Product',
      price: 10000,
      stock: -1,
      isAvailable: true,
      imageUrls: [],
    });
    await seedDoc('orders', ORDER_ID, orderData());

    const batch = writeBatch(ownerDb);
    batch.update(doc(ownerDb, 'products', PRODUCT_ID), {
      stock: 1,
      lastStockOrderId: ORDER_ID,
    });
    batch.update(doc(ownerDb, 'orders', ORDER_ID), {
      status: 'cancelled',
      inventoryAdjusted: false,
      updatedAt: Timestamp.fromDate(new Date('2026-08-30T11:00:00Z')),
    });
    await assertFails(batch.commit());

    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      const savedOrder = await getDoc(doc(db, 'orders', ORDER_ID));
      const savedProduct = await getDoc(doc(db, 'products', PRODUCT_ID));
      expect(savedOrder.data().status).toBe('placed');
      expect(savedOrder.data().inventoryAdjusted).toBe(true);
      expect(savedProduct.data().stock).toBe(-1);
    });
  });

  test('owner order updates cannot mutate unrelated fields', async () => {
    await seedDoc('orders', ORDER_ID, orderData());

    await assertFails(
      updateDoc(doc(ownerDb, 'orders', ORDER_ID), {
        status: 'accepted',
        customerId: ATTACKER_UID,
        updatedAt: Timestamp.fromDate(new Date('2026-08-30T11:00:00Z')),
      }),
    );
  });

  test('owner cancellation restores stock once with order transition', async () => {
    await seedDoc('products', PRODUCT_ID, {
      id: PRODUCT_ID,
      shopId: SHOP_ID,
      ownerId: OWNER_UID,
      name: 'Test Product',
      price: 10000,
      stock: 3,
      isAvailable: true,
      imageUrls: [],
    });
    await seedDoc('orders', ORDER_ID, orderData());

    const batch = writeBatch(ownerDb);
    batch.update(doc(ownerDb, 'products', PRODUCT_ID), {
      stock: 5,
      lastStockOrderId: ORDER_ID,
    });
    batch.update(doc(ownerDb, 'orders', ORDER_ID), {
      status: 'cancelled',
      inventoryAdjusted: false,
      updatedAt: Timestamp.fromDate(new Date('2026-08-30T11:00:00Z')),
    });
    await assertSucceeds(batch.commit());

    await assertFails(
      updateDoc(doc(ownerDb, 'orders', ORDER_ID), {
        status: 'cancelled',
        inventoryAdjusted: false,
        updatedAt: Timestamp.fromDate(new Date('2026-08-30T11:01:00Z')),
      }),
    );
  });

  test('concurrent cancellation requests restore inventory once', async () => {
    await seedDoc('products', PRODUCT_ID, {
      id: PRODUCT_ID,
      shopId: SHOP_ID,
      ownerId: OWNER_UID,
      name: 'Test Product',
      price: 10000,
      stock: 3,
      isAvailable: true,
      imageUrls: [],
    });
    await seedDoc('orders', ORDER_ID, orderData());

    const cancel = () =>
      runTransaction(ownerDb, async (transaction) => {
        const orderRef = doc(ownerDb, 'orders', ORDER_ID);
        const order = await transaction.get(orderRef);
        if (!['placed', 'accepted'].includes(order.data().status)) {
          throw new Error('Order is no longer cancellable');
        }
        const productRef = doc(ownerDb, 'products', PRODUCT_ID);
        const product = await transaction.get(productRef);
        transaction.update(productRef, {
          stock: product.data().stock + order.data().quantity,
          lastStockOrderId: ORDER_ID,
        });
        transaction.update(orderRef, {
          status: 'cancelled',
          inventoryAdjusted: false,
          updatedAt: Timestamp.fromDate(new Date('2026-08-30T11:00:00Z')),
        });
      });

    const outcomes = await Promise.allSettled([cancel(), cancel()]);
    expect(outcomes.filter((result) => result.status === 'fulfilled')).toHaveLength(1);
    expect((await getDoc(doc(ownerDb, 'products', PRODUCT_ID))).data().stock).toBe(5);
    expect((await getDoc(doc(ownerDb, 'orders', ORDER_ID))).data().inventoryAdjusted).toBe(false);
  });

  test('completion racing cancellation has only one valid outcome', async () => {
    await seedDoc('products', PRODUCT_ID, {
      id: PRODUCT_ID,
      shopId: SHOP_ID,
      ownerId: OWNER_UID,
      name: 'Test Product',
      price: 10000,
      stock: 3,
      isAvailable: true,
      imageUrls: [],
    });
    await seedDoc('orders', ORDER_ID, orderData({ status: 'accepted' }));

    const cancel = () =>
      runTransaction(ownerDb, async (transaction) => {
        const orderRef = doc(ownerDb, 'orders', ORDER_ID);
        const order = await transaction.get(orderRef);
        if (order.data().status !== 'accepted') throw new Error('Not cancellable');
        const productRef = doc(ownerDb, 'products', PRODUCT_ID);
        const product = await transaction.get(productRef);
        transaction.update(productRef, {
          stock: product.data().stock + order.data().quantity,
          lastStockOrderId: ORDER_ID,
        });
        transaction.update(orderRef, {
          status: 'cancelled',
          inventoryAdjusted: false,
          updatedAt: Timestamp.fromDate(new Date('2026-08-30T11:00:00Z')),
        });
      });
    const complete = () =>
      runTransaction(ownerDb, async (transaction) => {
        const orderRef = doc(ownerDb, 'orders', ORDER_ID);
        const order = await transaction.get(orderRef);
        if (order.data().status !== 'accepted') throw new Error('Not completable');
        transaction.update(orderRef, {
          status: 'completed',
          updatedAt: Timestamp.fromDate(new Date('2026-08-30T11:00:00Z')),
        });
      });

    const outcomes = await Promise.allSettled([cancel(), complete()]);
    expect(outcomes.filter((result) => result.status === 'fulfilled')).toHaveLength(1);

    const finalOrder = (await getDoc(doc(ownerDb, 'orders', ORDER_ID))).data();
    const finalStock = (await getDoc(doc(ownerDb, 'products', PRODUCT_ID))).data().stock;
    if (finalOrder.status === 'cancelled') {
      expect(finalOrder.inventoryAdjusted).toBe(false);
      expect(finalStock).toBe(5);
    } else {
      expect(finalOrder.status).toBe('completed');
      expect(finalOrder.inventoryAdjusted).toBe(true);
      expect(finalStock).toBe(3);
    }
  });

  test('legacy orders without inventory markers can still transition', async () => {
    const legacyOrder = orderData({ status: 'placed' });
    delete legacyOrder.inventoryAdjusted;
    delete legacyOrder.purchaseMode;
    delete legacyOrder.fulfillmentType;
    await seedDoc('orders', ORDER_ID, legacyOrder);

    await assertSucceeds(
      updateDoc(doc(ownerDb, 'orders', ORDER_ID), {
        status: 'accepted',
        updatedAt: Timestamp.fromDate(new Date('2026-08-30T11:00:00Z')),
      }),
    );
    await assertSucceeds(
      updateDoc(doc(ownerDb, 'orders', ORDER_ID), {
        status: 'cancelled',
        updatedAt: Timestamp.fromDate(new Date('2026-08-30T11:01:00Z')),
      }),
    );
  });

  test('customer cannot forge another customer in an order', async () => {
    await seedDoc(
      'enquiries',
      ENQUIRY_ID,
      enquiryData({
        status: 'accepted',
      }),
    );

    await assertFails(
      setDoc(
        doc(customerDb, 'orders', ORDER_ID),
        orderData({
          customerId: ATTACKER_UID,
        }),
      ),
    );
  });

  test('customer cannot forge another owner in an order', async () => {
    await seedDoc(
      'enquiries',
      ENQUIRY_ID,
      enquiryData({
        status: 'accepted',
      }),
    );

    await assertFails(
      setDoc(
        doc(customerDb, 'orders', ORDER_ID),
        orderData({
          ownerId: ATTACKER_UID,
        }),
      ),
    );
  });

  test('customer cannot create an order with incorrect subtotal', async () => {
    await seedDoc(
      'enquiries',
      ENQUIRY_ID,
      enquiryData({
        status: 'accepted',
      }),
    );

    await assertFails(
      setDoc(
        doc(customerDb, 'orders', ORDER_ID),
        orderData({
          subtotal: 999,
        }),
      ),
    );
  });

  test('customer cannot create an order with incorrect total', async () => {
    await seedDoc(
      'enquiries',
      ENQUIRY_ID,
      enquiryData({
        status: 'accepted',
      }),
    );

    await assertFails(
      setDoc(
        doc(customerDb, 'orders', ORDER_ID),
        orderData({
          totalAmount: 999,
        }),
      ),
    );
  });

  test('owner can read an order belonging to their shop', async () => {
    await seedDoc(
      'orders',
      ORDER_ID,
      orderData(),
    );

    await assertSucceeds(
      getDoc(doc(ownerDb, 'orders', ORDER_ID)),
    );
  });

  test('attacker cannot read an order they do not own', async () => {
    await seedDoc(
      'orders',
      ORDER_ID,
      orderData(),
    );

    await assertFails(
      getDoc(doc(attackerDb, 'orders', ORDER_ID)),
    );
  });

  test('owner cannot make an invalid order lifecycle transition', async () => {
    await seedDoc(
      'orders',
      ORDER_ID,
      orderData({
        status: 'placed',
      }),
    );

    await assertFails(
      updateDoc(
        doc(ownerDb, 'orders', ORDER_ID),
        {
          status: 'completed',
          updatedAt: Timestamp.fromDate(new Date('2026-08-30T11:00:00Z')),
        },
      ),
    );
  });

  test('owner cannot modify protected order financial fields', async () => {
    await seedDoc(
      'orders',
      ORDER_ID,
      orderData({
        status: 'placed',
      }),
    );

    await assertFails(
      updateDoc(
        doc(ownerDb, 'orders', ORDER_ID),
        {
          status: 'accepted',
          totalAmount: 1,
          updatedAt: Timestamp.fromDate(new Date('2026-08-30T11:00:00Z')),
        },
      ),
    );
  });

  test('orders cannot be deleted', async () => {
    await seedDoc(
      'orders',
      ORDER_ID,
      orderData(),
    );

    await assertFails(
      deleteDoc(
        doc(ownerDb, 'orders', ORDER_ID),
      ),
    );

    await assertFails(
      deleteDoc(
        doc(customerDb, 'orders', ORDER_ID),
      ),
    );
  });
});
