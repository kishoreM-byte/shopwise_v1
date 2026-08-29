import {setGlobalOptions} from "firebase-functions";
import {onDocumentUpdated} from "firebase-functions/v2/firestore";
import * as admin from "firebase-admin";
import {FieldValue} from "firebase-admin/firestore";

admin.initializeApp();

setGlobalOptions({
  maxInstances: 10,
});

export const onEnquiryStatusChanged = onDocumentUpdated(
  "enquiries/{enquiryId}",
  async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();

    if (!before || !after) {
      return;
    }

    const previousStatus = before.status;
    const currentStatus = after.status;

    if (
      previousStatus === currentStatus ||
      (currentStatus !== "accepted" && currentStatus !== "rejected")
    ) {
      return;
    }

    const customerId = after.customerId;

    if (typeof customerId !== "string" || customerId.trim().length === 0) {
      console.error(
        "Cannot create notification: invalid customerId",
        event.params.enquiryId,
      );
      return;
    }

    const notificationId =
      `${event.params.enquiryId}_${currentStatus}`;

    const notificationRef = admin
      .firestore()
      .collection("notifications")
      .doc(notificationId);

    const productName =
      typeof after.productName === "string" && after.productName.trim() ?
        after.productName.trim() :
        "your product enquiry";

    const isAccepted = currentStatus === "accepted";

    await notificationRef.set({
      id: notificationRef.id,
      userId: customerId,
      type: isAccepted ? "enquiry_accepted" : "enquiry_rejected",
      title: isAccepted ? "Enquiry accepted" : "Enquiry rejected",
      message: isAccepted ?
        `The shop has accepted your enquiry for ${productName}.` :
        `The shop has rejected your enquiry for ${productName}.`,
      productId: after.productId ?? null,
      shopId: after.shopId ?? null,
      enquiryId: event.params.enquiryId,
      isRead: false,
      createdAt: FieldValue.serverTimestamp(),
    });

    console.log(
      `Created ${currentStatus} notification for customer ${customerId}`,
    );
  },
);
