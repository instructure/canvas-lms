const rewriteRulesSnippet = require('grunt-connect-rewrite/lib/utils').rewriteRequest;
const proxy = require('grunt-connect-proxy/lib/utils').proxyRequest;
const middleware = function (connect, options) {
  const middlewares = [];
  let directory;

  // ReverseProxy support
  middlewares.push(proxy);

  // RewriteRules support
  middlewares.push(rewriteRulesSnippet);

  if (!Array.isArray(options.base)) {
    options.base = [options.base];
  }

  // Serve static files.
  options.base.forEach((base) => {
    middlewares.push(connect.static(base));
  });

  // Make directory browse-able.
  directory = options.directory || options.base[options.base.length - 1];
  middlewares.push(connect.directory(directory));

  return middlewares;
};

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
      middleware
    }
  },

  tests: {
    options: {
      keepalive: false,
      port: 9443,
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
