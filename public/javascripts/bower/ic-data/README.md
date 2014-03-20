ic-data
=======

Ember Data models, adapters, and serializers to work with the
[instructure canvas][1] [api][2].

Proxy Server
------------

This repository includes a proxy server to the canvas API for testing
and development, it sets the access token for you automatically so
requests don't need to contain the query parameter.

No API stubbing here, we want to know it really works.

1. Log into canvas, and create an API token from the user settings page,
   then paste it into `proxy-config.json`.
2. Fire up the server with `node proxy.js`

  [1]:http://instructure.com
  [2]:http://canvas.instructure.com/doc/api/index.html

