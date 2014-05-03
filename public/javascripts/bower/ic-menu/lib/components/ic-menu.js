+function(root, factory) {
  if (typeof define === 'function' && define.amd) {
    define(['ember'], function(Ember) { return factory(Ember); });
  } else if (typeof exports === 'object') {
    module.exports = factory(require('ember'));
  } else {
    root.ic = root.ic || {};
    root.ic.MenuComponent = factory(Ember);
  }
}(this, function(Ember) {

  var MenuComponent = Ember.Component.extend({

    tagName: 'ic-menu',

    classNameBindings: ['isOpen:is-open:is-closed'],

    list: null,

    listTrigger: null,

    isOpen: function() {
      return this.get('list.isOpen');
    }.property('list.isOpen'),

    registerList: function(list) {
      this.set('list', list);
    },

    registerTrigger: function(trigger) {
      this.set('listTrigger', trigger);
    },

    openList: function() {
      this.get('list').open();
    }

  });

  return MenuComponent;

});

