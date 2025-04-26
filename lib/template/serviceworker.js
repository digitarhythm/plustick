var CACHE_NAME = '[[[:name:]]]-caches-[[[:version:]]]';
var urlsToCache = [
  [[[:cache_contents:]]]
];

self.addEventListener('install', function(event) {
  console.log('Serviceworker event: install called');

  event.waitUntil(
    caches.open(CACHE_NAME).then(function(cache) {
      return cache.addAll(urlsToCache);
    })
  );
});

self.addEventListener("activate", function (event) {
  console.log('Serviceworker event: activate called');

  event.waitUntil(
    (function () {
      caches.keys().then(function (oldCacheKeys) {
        oldCacheKeys
          .filter(function (key) {
            return key !== CACHE_NAME;
          })
          .map(function (key) {
            return caches.delete(key);
          });
      });
      clients.claim();
    })()
  );
});


self.addEventListener('fetch', function(event) {
  console.log('Serviceworker event: fetch called');

  event.respondWith(
    caches.match(event.request).then(function(response) {
      return response ? response : fetch(event.request);
    })
  );
});

self.addEventListener('push', function(event){
  console.log('Serviceworker event: push called');

  var notificationDataObj = event.data.json();
  var content = {
    body: notificationDataObj.body,
  };
  event.waitUntil(
    self.registration.showNotification(notificationDataObj.title, content)
  );
});
