// See http://www.w3.org/WAI/GL/wiki/Using_ARIA_menus

+function(root, factory) {
  if (typeof define === 'function' && define.amd) {
    define(['ember'], function(Ember) { return factory(Ember); });
  } else if (typeof exports === 'object') {
    module.exports = factory(require('ember'));
  } else {
    root.ic = root.ic || {};
    root.ic.MenuListComponent = factory(Ember);
  }
}(this, function(Ember) {

  var MenuListComponent = Ember.Component.extend({

    role: 'menu',

    tagName: 'ic-menu-list',

    attributeBindings: [
      'ariaExpanded:aria-expanded',
      'tabindex',
      'role'
    ],

    // so we can focus the menu manually and get "focusOut" to trigger without
    // putting the menu in the tab-o-sphere
    tabindex: -1,

    isOpen: false,

    ariaExpanded: function() {
      return this.get('isOpen')+''; // aria wants "true" and "false" as strings
    }.property('isOpen'),

    focusedItem: null,

    createItems: function() {
      this.set('items', Ember.ArrayProxy.create({content: []}));
    }.on('init'),


    keyDown: function(event) {
      keysDict = {
        40: this.focusNext,       /*down*/
        38: this.focusPrevious,   /*up*/
        27: this.focusTrigger     /*escape*/
      };
      if (keysDict.hasOwnProperty(event.keyCode)) {
        event.preventDefault();
        keysDict[event.keyCode].call(this)
      }
    },

    focusTrigger: function() {
      this.get('parentView.listTrigger').focus();
    },

    focusNext: function() {
      var index = 0;
      var items = this.get('items');
      var focusedItem = this.get('focusedItem');
      if (focusedItem) {
        index = items.indexOf(focusedItem) + 1;
      }
      if (index === items.get('length')) {
        index = 0; // loop it
      }
      this.focusItemAtIndex(index);
    },

    focusPrevious: function() {
      var items = this.get('items');
      var index = items.get('length') - 1;
      var focusedItem = this.get('focusedItem');
      if (focusedItem) {
        index = items.indexOf(focusedItem) - 1;
      }
      if (index == -1) {
        index = items.get('length') - 1; // loop it
      }
      this.focusItemAtIndex(index);
    },

    focusItemAtIndex: function(index) {
      var item = this.get('items').objectAt(index);
      this.focusItem(item);
    },

    focusItem: function(item) {
      var focusedItem = this.get('focusedItem');
      if (focusedItem) focusedItem.blur();
      this.set('focusedItem', item);
      item.focus();
    },

    itemsAsHash: function() {
      var items = this.get('items');
      var itemsHash = {};
      items.forEach(function(item){
        var id = item.$().attr('id');
        itemsHash[id] = item;
      });
      return itemsHash;
    },

    syncItemsWithChildViews: function() {
      // this.get('childViews') doesn't seem to update as menu-items
      // are added / removed. so resorting to pulling directly from DOM :/
      if (!this.$()) {
        return; // not in DOM
      }
      var cv = this.$().find('ic-menu-item').get();
      var itemsHash = this.itemsAsHash();
      if (!cv) {
        return;
      }
      var items = [];
      cv.forEach(function(child) {
        var id = this.$(child).attr('id');
        if (itemsHash[id]) {
          items.push(itemsHash[id]);
        }
      });
      this.set('items', items);
    },

    registerItem: function(item) {
      this.get('items').addObject(item);
      Ember.run.debounce(this, this.syncItemsWithChildViews, 1)
    },

    deregisterItem: function(item) {
      this.get('items').removeObject(item);
      Ember.run.debounce(this, this.syncItemsWithChildViews, 1)
    },

    open: function() {
      this.set('isOpen', true);
    },

    close: function() {
      this.set('isOpen', false);
      this.set('focusedItem', null);
    },

    focusFirstItemOnOpen: function() {
      if (!this.get('isOpen')) return;
      // wait for dom repaint so we can actually focus items
      Ember.run.next(this, function() {
        if (this.get('parentView.listTrigger.lastClickEventWasMouse')) {
          // focus the list then keyboard navigation still works, but the first
          // item isn't strangely selected
          this.$().focus();
        } else {
          // select first item for keyboard navigation
          this.focusItemAtIndex(0);
        }
      });
    }.observes('isOpen'),

    registerWithParent: function() {
      this.get('parentView').registerList(this);
    }.on('didInsertElement'),

    focusOut: function(event) {
      // wait for activeElement to get set (I think?)
      Ember.run.next(this, function(){
        // gaurd against case where this.$() is undefinded.
        // otherwise get random failures
        if (this.$()) {
          if (!this.$().has(document.activeElement).length) {
            this.close();
          }
        }
      });
    }

  });

  return MenuListComponent;

});

