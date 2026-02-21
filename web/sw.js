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
        clients.matchAll({ type: 'window', includeUncontrolled: true }).then(function (clientList) {
            // If a window is already open, focus it
            for (var i = 0; i < clientList.length; i++) {
                var client = clientList[i];
                if ('focus' in client) {
                    return client.focus();
                }
            }
            // Otherwise open a new one
            if (clients.openWindow) {
                return clients.openWindow('/');
            }
        })
    );
});
/**
 * Service Worker push handler — add this to your existing flutter_service_worker.js
 * or a custom service worker registered in web/index.html.
 *
 * IMPORTANT for iOS PWA: this file must be registered BEFORE the Flutter SW.
 * In web/index.html add before </body>:
 *
 *   <script>
 *     if ('serviceWorker' in navigator) {
 *       navigator.serviceWorker.register('/flutter_service_worker.js');
 *     }
 *   </script>
 *
 * The push and notificationclick listeners below should live in flutter_service_worker.js
 * (or a custom SW that importScripts() the Flutter SW).
 */

// ── Push received (fires even when the app is closed) ────────────────────────
self.addEventListener('push', (event) => {
  let data = { title: 'CleanTrack', body: 'You have a cleaning task due.' };
  try {
    data = event.data?.json() ?? data;
  } catch (_) {}

  event.waitUntil(
    self.registration.showNotification(data.title, {
      body: data.body,
      icon: '/icons/Icon-192.png',
      badge: '/icons/Icon-192.png',
      tag: data.tag ?? 'cleantrack',   // prevents duplicate banners
      renotify: true,
    })
  );
});

// ── Notification tapped ───────────────────────────────────────────────────────
// Required on iOS PWA — without this, tapping the banner does nothing.
self.addEventListener('notificationclick', (event) => {
  event.notification.close();
  event.waitUntil(
    clients.matchAll({ type: 'window', includeUncontrolled: true }).then((clientList) => {
      // If app is already open, focus it
      for (const client of clientList) {
        if (client.url.startsWith(self.location.origin) && 'focus' in client) {
          return client.focus();
        }
      }
      // Otherwise open a new window
      return clients.openWindow('/');
    })
  );
});
