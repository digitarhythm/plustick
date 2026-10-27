var CACHE_NAME = [[[:cache_name:]]];
var CACHE_PREFIX = [[[:cache_prefix:]]];
var PAGE_URL = [[[:page_url:]]];
var API_PATH = [[[:api_path:]]];
var DEVELOP = [[[:develop:]]];
var urlsToCache = [[[:cache_contents:]]];

//--------------------------------------------------------------------------
// install: cache each file individually (one failure must not abort install)
//--------------------------------------------------------------------------
self.addEventListener('install', function(event) {
  event.waitUntil(
    caches.open(CACHE_NAME).then(function(cache) {
      return Promise.all(urlsToCache.map(function(url) {
        return cache.add(url).catch(function(err) {
          console.warn('Serviceworker: failed to cache', url, err);
        });
      }));
    }).then(function() {
      return self.skipWaiting();
    })
  );
});

//--------------------------------------------------------------------------
// activate: delete old caches of this application only
//--------------------------------------------------------------------------
self.addEventListener('activate', function(event) {
  event.waitUntil(
    caches.keys().then(function(keys) {
      return Promise.all(keys.filter(function(key) {
        return key.indexOf(CACHE_PREFIX) === 0 && key !== CACHE_NAME;
      }).map(function(key) {
        return caches.delete(key);
      }));
    }).then(function() {
      return self.clients.claim();
    })
  );
});

//--------------------------------------------------------------------------
// fetch
//   page (navigation) / develop mode : network first, cache as fallback
//   cached files                     : cache first, refreshed in background
//   API / non-GET / others           : not handled (network)
//--------------------------------------------------------------------------
function networkFirst(request, fallbackUrl) {
  return fetch(request).then(function(response) {
    if (response.ok) {
      var copy = response.clone();
      caches.open(CACHE_NAME).then(function(cache) {
        cache.put(fallbackUrl || request, copy);
      });
    }
    return response;
  }).catch(function(err) {
    return caches.match(fallbackUrl || request, { ignoreSearch: !!fallbackUrl }).then(function(cached) {
      if (cached) {
        return cached;
      }
      throw err;
    });
  });
}

self.addEventListener('fetch', function(event) {
  var request = event.request;
  if (request.method !== 'GET') {
    return;
  }
  var url = new URL(request.url);
  if (url.origin === self.location.origin && url.pathname.indexOf(API_PATH) === 0) {
    return;
  }

  if (request.mode === 'navigate') {
    var isPage = (url.origin === self.location.origin && url.pathname === PAGE_URL);
    event.respondWith(networkFirst(request, isPage ? PAGE_URL : undefined));
    return;
  }

  event.respondWith(
    caches.open(CACHE_NAME).then(function(cache) {
      return cache.match(request).then(function(cached) {
        if (!cached) {
          return fetch(request);
        }
        if (DEVELOP) {
          return networkFirst(request);
        }
        event.waitUntil(fetch(request).then(function(response) {
          if (response.ok) {
            return cache.put(request, response);
          }
        }).catch(function() {}));
        return cached;
      });
    })
  );
});

//--------------------------------------------------------------------------
// push notification
//--------------------------------------------------------------------------
self.addEventListener('push', function(event) {
  var data = {};
  if (event.data) {
    try {
      data = event.data.json();
    } catch (e) {
      data = { body: event.data.text() };
    }
  }
  event.waitUntil(
    self.registration.showNotification(data.title || '', { body: data.body || '', data: { url: data.url || PAGE_URL } })
  );
});

self.addEventListener('notificationclick', function(event) {
  event.notification.close();
  var target = new URL((event.notification.data && event.notification.data.url) || PAGE_URL, self.location.origin);
  if (target.origin !== self.location.origin) {
    target = new URL(PAGE_URL, self.location.origin);
  }
  target = target.href;
  event.waitUntil(
    self.clients.matchAll({ type: 'window', includeUncontrolled: true }).then(function(list) {
      for (var i = 0; i < list.length; i++) {
        if (list[i].url === target && 'focus' in list[i]) {
          return list[i].focus();
        }
      }
      return self.clients.openWindow(target);
    })
  );
});
