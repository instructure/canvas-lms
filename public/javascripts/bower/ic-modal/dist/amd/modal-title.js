define(
  ["ember","exports"],
  function(__dependency1__, __exports__) {
    "use strict";
    var Ember = __dependency1__["default"] || __dependency1__;

    __exports__["default"] = Ember.Component.extend({
      
      tagName: 'ic-modal-title',

      attributeBindings: ['aria-hidden'],

      /**
       * Tells the screenreader not to read this element. The modal has its
       * 'aria-labelledby' set to the id of this element so it would be redundant.
       *
       * @property aria-hidden
       */

      'aria-hidden': 'true',

      /**
       * @method registerTitle
       * @private
       */

      registerWithModal: function() {
        this.get('parentView').registerTitle(this);
      }.on('willInsertElement')
        
    });
  });