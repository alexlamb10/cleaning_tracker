self.addEventListener('push', function (event) {
    console.log('[Service Worker] Push Received.');
    console.log(`[Service Worker] Push had this data: "${event.data.text()}"`);

    let data = {};
    try {
        data = event.data.json();
    } catch (e) {
        data = { title: 'CleanTrack Reward', body: event.data.text() };
    }

    const title = data.title || 'CleanTrack Reminder';
    const options = {
        body: data.body || 'A task needs your attention!',
        icon: '/icons/Icon-192.png',
        badge: '/icons/Icon-192.png',
        vibrate: [100, 50, 100],
        data: {
            dateOfArrival: Date.now(),
            primaryKey: '1'
        }
    };

    event.waitUntil(self.registration.showNotification(title, options));
});

self.addEventListener('notificationclick', function (event) {
    console.log('[Service Worker] Notification click Received.');
    event.notification.close();
    event.waitUntil(
        clients.openWindow('/')
    );
});
