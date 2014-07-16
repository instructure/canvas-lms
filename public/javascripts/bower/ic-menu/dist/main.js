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
      'role',
      'aria-disabled'
    ],

    role: 'menuitem',

    enabled: true,

    tabindex: -1,

    focused: false,

    'aria-disabled': function() {
      return !this.get('enabled') + ''; // coerce to ensure true || false
    }.property('enabled'),

    click: function(event) {
      var wasKeyboard = !event.clientX && !event.clientY;
      this.get('parentView').close();
      Ember.run.next(this, function() {
        if (wasKeyboard) { this.get('parentView').focusTrigger(); }
        if (this.get('enabled')) {
          this.sendAction('on-select', this);
        } else {
          this.sendAction('on-disabled-select', this);
        }
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


+function(root, factory) {
  if (typeof define === 'function' && define.amd) {
    define(['ember'], function(Ember) { return factory(Ember); });
  } else if (typeof exports === 'object') {
    module.exports = factory(require('ember'));
  } else {
    root.ic = root.ic || {};
    root.ic.MenuTriggerComponent = factory(Ember);
  }
}(this, function(Ember) {

  var MenuTriggerComponent = Ember.Component.extend({

    tagName: 'ic-menu-trigger',

    role: 'button',

    attributeBindings: [
      'ariaOwns:aria-owns',
      'ariaHaspopup:aria-haspopup',
      'role',
      'tabindex',
      'title'
    ],

    tabindex: 0,

    ariaHaspopup: 'true',

    ariaOwns: function() {
      return this.get('parentView.list.elementId');
    }.property('parentView.list'),

    mouseDown: function() {
      if (!this.get('parentView.list.isOpen')) return;
      // MenuList::focusOut handles outerclick/outerfocus, mousedown on the
      // trigger will close an already open list, then the click finishes after
      // and would reopen the list, so we have this temporary property to deal
      // with it.
      this.closingClickStarted = true;
    },

    click: Ember.aliasMethod('openList'),

    keyDown: function(event) {
      switch (event.keyCode) {
        case 13 /*enter*/:
        case 32 /*space*/:
        case 40 /*down*/:
        case 38 /*up*/: this.openList(event); break;
      }
    },

    openList: function(event) {
      event.preventDefault();
      // I have no idea how reliable this is, but it seems good enough
      this.set('lastClickEventWasMouse', event.clientX > 0 && event.clientY > 0);
      if (this.closingClickStarted) {
        return this.closingClickStarted = false;
      }
      this.get('parentView').openList();
    },

    click: Ember.aliasMethod('openList'),

    registerWithParent: function() {
      this.get('parentView').registerTrigger(this);
    }.on('didInsertElement'),

    focus: function() {
      this.$().focus();
    }

  });

  return MenuTriggerComponent;

});


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


+function(root, factory) {
  if (typeof define === 'function' && define.amd) {
    define(['ember'], function(Ember) { return factory(Ember); });
  } else if (typeof exports === 'object') {
    factory(require('ember'));
  } else {
    factory(Ember);
  }
}(this, function(Ember) {

Ember.TEMPLATES["components/ic-menu-css"] = Ember.Handlebars.template(function anonymous(Handlebars,depth0,helpers,partials,data) {
this.compilerInfo = [4,'>= 1.0.0'];
helpers = this.merge(helpers, Ember.Handlebars.helpers); data = data || {};
  


  data.buffer.push("<style>\nic-menu {\n  display: inline-block;\n}\n\nic-menu-list {\n  position: absolute;\n  display: none;\n}\n\nic-menu-list[aria-expanded=\"true\"] {\n  display: block;\n}\n\nic-menu-list {\n  outline: none;\n  background: #fff;\n  border: 1px solid #aaa;\n  border-radius: 3px;\n  box-shadow: 2px 2px 20px rgba(0, 0, 0, 0.25);\n  list-style-type: none;\n  padding: 2px 0px;\n  font-family: \"Lucida Grande\", \"Arial\", sans-serif;\n  font-size: 12px;\n}\n\nic-menu-item {\n  display: block;\n  padding: 4px 20px;\n  cursor: default;\n  white-space: nowrap;\n}\n\n\nic-menu-item:focus {\n  background: #3879D9;\n  color: #fff;\n  outline: none;\n}\n\nic-menu-item[aria-disabled=\"true\"] {\n  color: #999;\n}\n\nic-menu-item[aria-disabled=\"true\"]:focus {\n  background: #ccc;\n  color: #000;\n}\n\nic-menu-item a {\n  color: inherit;\n  text-decoration: none;\n}\n</style>\n\n");
  
});

Ember.TEMPLATES["components/ic-menu-list"] = Ember.Handlebars.template(function anonymous(Handlebars,depth0,helpers,partials,data) {
this.compilerInfo = [4,'>= 1.0.0'];
helpers = this.merge(helpers, Ember.Handlebars.helpers); data = data || {};
  var buffer = '', stack1;


  stack1 = helpers._triageMustache.call(depth0, "yield", {hash:{},hashTypes:{},hashContexts:{},contexts:[depth0],types:["ID"],data:data});
  if(stack1 || stack1 === 0) { data.buffer.push(stack1); }
  data.buffer.push("\n");
  return buffer;
  
});

Ember.TEMPLATES["components/ic-menu"] = Ember.Handlebars.template(function anonymous(Handlebars,depth0,helpers,partials,data) {
this.compilerInfo = [4,'>= 1.0.0'];
helpers = this.merge(helpers, Ember.Handlebars.helpers); data = data || {};
  var buffer = '', stack1;


  stack1 = helpers._triageMustache.call(depth0, "yield", {hash:{},hashTypes:{},hashContexts:{},contexts:[depth0],types:["ID"],data:data});
  if(stack1 || stack1 === 0) { data.buffer.push(stack1); }
  data.buffer.push("\n");
  return buffer;
  
});

});
// <look-the-other-way>
+function(root, factory) {
  if (typeof define === 'function' && define.amd) {
    define([
      'ember',
      './lib/components/ic-menu-item',
      './lib/components/ic-menu-list',
      './lib/components/ic-menu-trigger',
      './lib/components/ic-menu',
      'ic-styled',
      './lib/templates'
    ], function(Ember, Item, List, Trigger, Menu) {
      return factory(Ember, Item, List, Trigger, Menu);
    });
  } else if (typeof exports === 'object') {
    module.exports = factory(
      require('ember'),
      require('./lib/components/ic-menu-item'),
      require('./lib/components/ic-menu-list'),
      require('./lib/components/ic-menu-trigger'),
      require('./lib/components/ic-menu'),
      require('ic-styled'),
      require('./lib/templates')
    );
  } else {
    factory(
      Ember,
      root.ic.MenuItemComponent,
      root.ic.MenuListComponent,
      root.ic.MenuTriggerComponent,
      root.ic.MenuComponent
    );
  }
}(this, function(Ember, Item, List, Trigger, Menu) {
// </look-the-other-way>

  Ember.Application.initializer({

    name: 'ic-menu',

    initialize: function(container, application) {
      container.register('component:ic-menu-item', Item);
      container.register('component:ic-menu-list', List);
      container.register('component:ic-menu-trigger', Trigger);
      container.register('component:ic-menu', Menu);
    }

  });

  return {
    MenuItemComponent: Item,
    MenuListComponent: List,
    MenuTriggerComponent: Trigger,
    MenuComponent: Menu
  }

});

