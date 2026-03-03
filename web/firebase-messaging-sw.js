// firebase-messaging-sw.js
importScripts('https://www.gstatic.com/firebasejs/9.0.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/9.0.0/firebase-messaging-compat.js');

// Initialize Firebase in the Service Worker
firebase.initializeApp({
    apiKey: "AIzaSyAKTuQc_mPQqym6UesK4u7KV0OR7oQ4nV8",
    authDomain: "cleaning-tracker-5408d.firebaseapp.com",
    projectId: "cleaning-tracker-5408d",
    storageBucket: "cleaning-tracker-5408d.firebasestorage.app",
    messagingSenderId: "621678496436",
    appId: "1:621678496436:web:63d1b0c900ab8965cee5e1"
});

const messaging = firebase.messaging();

// Background handling logic
messaging.onBackgroundMessage((payload) => {
    console.log('[firebase-messaging-sw.js] Received background message ', payload);

    const notificationTitle = payload.notification?.title || 'Cleaning Reminder';
    const notificationOptions = {
        body: payload.notification?.body || 'Time for your scheduled task!',
        icon: '/icons/Icon-192.png',
        badge: '/icons/Icon-192.png',
        tag: 'cleantrack-reminder',
        data: { url: payload.data?.url || '/' }
    };

    return self.registration.showNotification(notificationTitle, notificationOptions);
});
