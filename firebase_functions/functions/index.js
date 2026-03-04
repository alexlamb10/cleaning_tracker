const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

const db = admin.firestore();

/**
 * Scheduled Function: runs every 30 minutes.
 */
exports.sendDuePush = functions.pubsub.schedule("every 30 minutes").onRun(async (context) => {
    const now = admin.firestore.Timestamp.now();

    // 1. Find tasks whose nextNotification is due
    console.log("Checking for due tasks at", now.toDate().toISOString());
    const tasksSnapshot = await db.collection("push_tasks")
        .where("nextNotification", "<=", now)
        .get();

    if (tasksSnapshot.empty) {
        console.log("No due tasks found.");
        return null;
    }

    const dueTasks = [];
    tasksSnapshot.forEach(doc => {
        dueTasks.push({ id: doc.id, ...doc.data() });
    });

    console.log(`Sending notifications for ${dueTasks.length} tasks.`);

    // 2. Iterate through tasks and send targeted notifications
    for (const task of dueTasks) {
        if (!task.creatorUid) {
            console.log(`Task ${task.name} (${task.id}) has no creatorUid. Skipping.`);
            continue;
        }

        // Find tokens for this specific user
        const tokensSnapshot = await db.collection("fcm_tokens")
            .where("userId", "==", task.creatorUid)
            .get();

        if (tokensSnapshot.empty) {
            console.log(`No tokens found for user ${task.creatorUid} (Task: ${task.name}).`);
            continue;
        }

        const tokens = [];
        tokensSnapshot.forEach(doc => {
            tokens.push(doc.id); // The token is the document ID
        });

        const message = {
            notification: {
                title: "CleanTrack Reminder",
                body: `Time to clean: ${task.name}`
            },
            data: {
                taskId: task.id,
                url: "/"
            },
            tokens: tokens
        };

        try {
            const response = await admin.messaging().sendEachForMulticast(message);
            console.log(`Successfully sent message for ${task.name} to user ${task.creatorUid}:`, response.successCount);

            if (response.failureCount > 0) {
                console.log(`Failed tokens for ${task.name}: ${response.failureCount}`);
            }
        } catch (e) {
            console.error(`Error sending message for ${task.name}:`, e);
        }
    }

    return null;
});
