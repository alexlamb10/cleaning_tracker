const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

const db = admin.firestore();

/**
 * Scheduled Function: runs every 30 minutes.
 */
exports.sendDuePush = functions.pubsub.schedule("every 30 minutes").onRun(async (context) => {
    const now = new Date().toISOString();

    // 1. Find tasks whose next_due_date has passed
    console.log("Checking for due tasks at", now);
    const tasksSnapshot = await db.collection("push_tasks")
        .where("next_due_date", "<=", now)
        .get();

    if (tasksSnapshot.empty) {
        console.log("No due tasks found.");
        return null;
    }

    const dueTasks = [];
    tasksSnapshot.forEach(doc => {
        dueTasks.push({ id: doc.id, ...doc.data() });
    });

    // 2. Get all FCM tokens
    const tokensSnapshot = await db.collection("fcm_tokens").get();

    if (tokensSnapshot.empty) {
        console.log("No FCM tokens found.");
        return null;
    }

    const tokens = [];
    tokensSnapshot.forEach(doc => {
        tokens.push(doc.id); // The token is the document ID
    });

    console.log(`Sending notifications for ${dueTasks.length} tasks to ${tokens.length} devices.`);

    // 3. Send notifications
    for (const task of dueTasks) {
        const message = {
            notification: {
                title: "CleanTrack Reminder",
                body: `Time to clean: ${task.task_name}`
            },
            data: {
                taskId: task.id,
                url: "/"
            },
            tokens: tokens
        };

        try {
            const response = await admin.messaging().sendEachForMulticast(message);
            console.log(`Successfully sent message for ${task.task_name}:`, response.successCount);

            if (response.failureCount > 0) {
                console.log(`Failed tokens for ${task.task_name}: ${response.failureCount}`);
            }

            // 4. Mark task as updated (optional: update next due date or last notified)
            // For now we just log success. 
        } catch (e) {
            console.error(`Error sending message for ${task.task_name}:`, e);
        }
    }

    return null;
});
