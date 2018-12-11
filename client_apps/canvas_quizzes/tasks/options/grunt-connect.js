/*
 * Copyright (C) 2014 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

var rewriteRulesSnippet = require('grunt-connect-rewrite/lib/utils').rewriteRequest;
var proxy = require('grunt-connect-proxy/lib/utils').proxyRequest;
var middleware = function (connect, options) {
  var middlewares = [];
  var directory;

  // ReverseProxy support
  middlewares.push( proxy );

  // RewriteRules support
  middlewares.push(rewriteRulesSnippet);

  if (!Array.isArray(options.base)) {
    options.base = [options.base];
  }

  // Serve static files.
  options.base.forEach(function (base) {
    middlewares.push(connect.static(base));
  });

  // Make directory browse-able.
  directory = options.directory || options.base[options.base.length - 1];
  middlewares.push(connect.directory(directory));

  return middlewares;
};;

module.exports = {
  rules: [
    {
      from: '^/app/',
      to: "/apps/<%= grunt.config.get('currentApp') %>/js/",
    },

    {
      from: '^/fixtures/',
      to: "/apps/<%= grunt.config.get('currentApp') %>/test/fixtures/"
    },

    {
      from: "^/apps/<%= grunt.config.get('currentApp') %>/js/<%= grunt.config.get('pkg.name') %>/",
      to: '/apps/common/js/'
    }
  ],

  www: {
    proxies: [{
      context: '/api/v1',
      host: 'canvas.docker',
      https: false,
      changeOrigin: false,
      xforward: false
    }, {
      context: '/files',
      host: 'canvas.docker',
      https: false,
      changeOrigin: true, // needed for <iframe src="" /> not to blow up
      xforward: false
    }],

    options: {
      keepalive: false,
      port: 9442,
      base: 'www',
      middleware: middleware
    }
  },

  tests: {
    options: {
      keepalive: false,
      port: 9219,
      hostname: '*'
    }
  },

  docs: {
    options: {
      keepalive: false,
      port: 9444,
      base: 'www',
      hostname: '*'
    }
  },
};
