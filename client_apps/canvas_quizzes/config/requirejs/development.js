requirejs.config({
  map: {
    '*': {
      'underscore': 'lodash',
      'canvas_packages': '../../../vendor/packages',
    },

    'qtip': {
      'jquery': '../../../vendor/packages/jquery'
    }
  },

  paths: {
    'text': '../../../vendor/js/require/text',
    'i18n': '../../../vendor/js/require/i18n',
    'jsx': '../../../vendor/js/require/jsx',
    'JSXTransformer': '../../../vendor/js/require/JSXTransformer-0.11.0.min',

    // ========================================================================
    // CQS dependencies
    'rsvp': '../../../vendor/js/rsvp.min',
    'qtip': '../../../vendor/js/jquery.qtip',
    'old_version_of_react_used_by_canvas_quizzes_client_apps': '../../../vendor/js/old_version_of_react_used_by_canvas_quizzes_client_apps',
    'old_version_of_react-router_used_by_canvas_quizzes_client_apps': '../../../vendor/js/old_version_of_react-router_used_by_canvas_quizzes_client_apps',
    // ========================================================================

    // ========================================================================
    // Aliases to frequently-used Canvas packages
    'lodash': '../../../vendor/packages/lodash',
    'd3': '../../../vendor/canvas_public/javascripts/symlink_to_node_modules/d3/d3',
    // ========================================================================

    // ========================================================================
    // Internal, for package providers only:
    'canvas': '../../../vendor/canvas_public/javascripts',
    'canvas_app': '../../../vendor/canvas_app'
  },

  shim: {
    qtip: [ 'jquery' ]
  },

  jsx: {
    fileExtension: '.jsx'
  },
});
