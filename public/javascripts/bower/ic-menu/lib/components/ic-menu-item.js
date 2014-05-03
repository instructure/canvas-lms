+function(root, factory) {
  if (typeof define === 'function' && define.amd) {
    define(['ember'], function(Ember) { return factory(Ember); });
  } else if (typeof exports === 'object') {
    module.exports = factory(require('ember'));
  } else {
    root.ic = root.ic || {};
    root.ic.MenuItemComponent = factory(Ember);
  }
}(this, function(Ember) {

  var MenuItemComponent = Ember.Component.extend({

    tagName: 'ic-menu-item',

    attributeBindings: [
      'tabindex',
      'role'
    ],

    role: 'menuitem',

    tabindex: -1,

    focused: false,

    click: function(event) {
      var wasKeyboard = !event.clientX && !event.clientY;
      this.get('parentView').close();
      Ember.run.next(this, function() {
        if (wasKeyboard) { this.get('parentView').focusTrigger(); }
        this.sendAction('on-select', this);
      });
    },

    keyDown: function(event) {
      if (event.keyCode == 13 || event.keyCode == 32) {
        this.click(event);
      }
    },

    register: function() {
      this.get('parentView').registerItem(this);
    }.on('didInsertElement'),

    deregister: function() {
      this.get('parentView').deregisterItem(this);
    }.on('willDestroyElement'),

    focus: function() {
      this.set('focused', true);
      this.$().focus();
    },

    mouseEnter: function() {
      this.get('parentView').focusItem(this);
    },

    blur: function() {
      this.set('focused', false);
    }

  });

  return MenuItemComponent;

});
