"use strict";
var Ember = require("ember")["default"] || require("ember");

exports["default"] = Ember.Component.extend({
  
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