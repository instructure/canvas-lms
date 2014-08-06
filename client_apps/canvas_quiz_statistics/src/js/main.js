requirejs.config({
  baseUrl: '/src/js',

  map: {
    '*': {
      'underscore': 'lodash',
      'canvas_packages': '../../vendor/packages',
    }
  },

  paths: {
    'text': '../../vendor/js/require/text',
    'i18n': '../../vendor/js/require/i18n',
    'jsx': '../../vendor/js/require/jsx',
    'JSXTransformer': '../../vendor/js/require/JSXTransformer-0.11.0.min',

    // ========================================================================
    // CQS dependencies
    'rsvp': '../../vendor/js/rsvp.min',
    // ========================================================================

    // ========================================================================
    // Aliases to frequently-used Canvas packages
    'react': '../../vendor/packages/react',
    'lodash': '../../vendor/packages/lodash',
    'd3': '../../vendor/packages/d3',
    // ========================================================================

    // ========================================================================
    // Internal, for package providers only:
    'canvas': '../../vendor/canvas/public/javascripts',
  },

  shim: {
  },

  jsx: {
    fileExtension: '.jsx'
  },
});

require([ 'boot' ]);