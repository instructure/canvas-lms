requirejs.config({
  map: {
    'canvas/Backbone': {
      'compiled/behaviors/authenticity_token': 'canvas/compiled/behaviors/authenticity_token',
      'node_modules-version-of-backbone': 'canvas/symlink_to_node_modules/backbone/backbone',
      'compiled/backbone-ext/Backbone.syncWithMultipart': 'canvas/compiled/backbone-ext/Backbone.syncWithMultipart',
      'compiled/backbone-ext/View': 'canvas/compiled/backbone-ext/View',
      'compiled/backbone-ext/Model': 'canvas/compiled/backbone-ext/Model',
      'compiled/backbone-ext/Collection': 'canvas/compiled/backbone-ext/Collection',
      'jquery': '../../../vendor/packages/jquery',
    },

    'canvas/symlink_to_node_modules/backbone/backbone': {
      'jquery': '../../../vendor/packages/jquery',
    },

    'canvas/compiled/backbone-ext/Backbone.syncWithMultipart': {
      'vendor/backbone': 'canvas/vendor/backbone',
      'jquery': '../../../vendor/packages/jquery',
      'compiled/behaviors/authenticity_token': 'canvas/compiled/behaviors/authenticity_token',
      'str/htmlEscape': 'canvas/str/htmlEscape',
    },

    'canvas/compiled/behaviors/authenticity_token': {
      'jquery': '../../../vendor/packages/jquery',
      'vendor/jquery.cookie': 'canvas/vendor/jquery.cookie',
    },

    'canvas/vendor/jquery.cookie': {
      'jquery': '../../../vendor/packages/jquery'
    },

    'canvas/compiled/backbone-ext/View': {
      'jquery': '../../../vendor/packages/jquery',
      'vendor/backbone': 'canvas/vendor/backbone',
      'str/htmlEscape': 'canvas/str/htmlEscape',
      'compiled/util/mixin': 'canvas/compiled/util/mixin',
    },

    // Needed by View
    'canvas/str/htmlEscape': {
      'INST': 'canvas/INST',
      'jquery': '../../../vendor/packages/jquery'
    },

    // Needed by str/htmlEscape
    'canvas/INST': {
      'jquery': '../../../vendor/packages/jquery'
    },

    'canvas/compiled/backbone-ext/Model': {
      'vendor/backbone': 'canvas/vendor/backbone',
      'compiled/util/mixin': 'canvas/compiled/util/mixin',
      'compiled/backbone-ext/Model/computedAttributes': 'canvas/compiled/backbone-ext/Model/computedAttributes',
      'compiled/backbone-ext/Model/dateAttributes': 'canvas/compiled/backbone-ext/Model/dateAttributes',
      'compiled/backbone-ext/Model/errors': 'canvas/compiled/backbone-ext/Model/errors',
    },

    'canvas/compiled/backbone-ext/Collection': {
      'vendor/backbone': 'canvas/vendor/backbone',
      'compiled/util/mixin': 'canvas/compiled/util/mixin',
      'compiled/backbone-ext/DefaultUrlMixin': 'canvas/compiled/backbone-ext/DefaultUrlMixin',
    },

    'canvas/compiled/backbone-ext/DefaultUrlMixin': {
      'compiled/str/splitAssetString': 'canvas/compiled/str/splitAssetString'
    },

    'canvas/compiled/str/splitAssetString': {
      'str/pluralize': 'canvas/str/pluralize'
    },

    'canvas/str/pluralize': {
      'jquery': '../../../vendor/packages/jquery'
    }
  }
});

define([ 'canvas/Backbone' ], function(Backbone) {
  return Backbone;
});