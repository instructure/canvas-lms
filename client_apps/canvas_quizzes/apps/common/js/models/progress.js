define((require) => {
  const Backbone = require('canvas_packages/backbone');
  const pickAndNormalize = require('./common/pick_and_normalize');
  const K = require('../constants');

  return Backbone.Model.extend({
    url () {
      return this.get('url');
    },

    parse (payload) {
      return pickAndNormalize(payload, K.PROGRESS_ATTRS);
    },
  });
});
