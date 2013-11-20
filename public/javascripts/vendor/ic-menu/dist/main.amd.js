define(['ember'], function(Ember) {
window.ic = window.ic || {};

ic.MenuItemComponent = Ember.Component.extend({

  tagName: 'ic-menu-item',

  // classNames: 'ic-menu-item',

  role: 'menuitem',

  attributeBindings: ['tabindex'],

  tabindex: -1,

  focused: false,

  click: function() {
    this.get('parentView').close();
    Ember.run.next(this, function() {
      this.get('parentView').focusTrigger();
      this.sendAction('on-select', this);
    });
  },

  keyDown: function(event) {
    if (event.keyCode == 13 || event.keyCode == 32) {
      this.click();
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


// See http://www.w3.org/WAI/GL/wiki/Using_ARIA_menus

window.ic = window.ic || {};

ic.MenuListComponent = Ember.Component.extend({

  tagName: 'ul',

  role: 'menu',

  classNames: ['ic-menu-list'],

  attributeBindings: [
    'ariaExpanded:aria-expanded',
    'tabindex'
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
    // TODO: refactor this, every time I use switch I regret it, and now the
    // preventDefaults are making me sad
    switch (event.keyCode) {
      case /*down*/   40: event.preventDefault(); this.focusNext(); break;
      case /*up*/     38: event.preventDefault(); this.focusPrevious(); break;
      case /*escape*/ 27: event.preventDefault(); this.focusTrigger(); break;
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

  registerItem: function(item) {
    this.get('items').addObject(item);
  },

  deregisterItem: function(item) {
    this.get('items').removeObject(item);
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
    Ember.run.next(this, function() {
      if (!this.$().has(document.activeElement).length) {
        this.close();
      }
    });
  }

});


window.ic = window.ic || {};

ic.MenuTriggerComponent = Ember.Component.extend({

  tagName: 'button',

  classNames: 'ic-menu-trigger',

  attributeBindings: [
    'ariaOwns:aria-owns',
    'ariaHaspopup:aria-haspopup'
  ],

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

  keyDown: function(event) {
    switch (event.keyCode) {
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


window.ic = window.ic || {};

ic.MenuComponent = Ember.Component.extend({

  tagName: 'ic-menu',

  classNames: 'ic-menu',

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


Ember.Application.initializer({

  name: 'ic-menu',

  initialize: function(container, application) {
    application.IcMenuItemComponent = ic.MenuItemComponent;
    application.IcMenuListComponent = ic.MenuListComponent;
    application.IcMenuTriggerComponent = ic.MenuTriggerComponent;
    application.IcMenuComponent = ic.MenuComponent;
  }

});


Ember.TEMPLATES["components/ic-menu-css"] = Ember.Handlebars.template(function anonymous(Handlebars,depth0,helpers,partials,data) {
this.compilerInfo = [4,'>= 1.0.0'];
helpers = this.merge(helpers, Ember.Handlebars.helpers); data = data || {};
  


  data.buffer.push("<style>\n.ic-menu-list {\n  position: absolute;\n  display: none;\n}\n\n.ic-menu-list[aria-expanded=\"true\"] {\n  display: block;\n}\n\n.ic-menu-list {\n  outline: none;\n  background: #fff;\n  border: 1px solid #aaa;\n  border-radius: 3px;\n  box-shadow: 2px 2px 20px rgba(0, 0, 0, 0.25);\n  list-style-type: none;\n  padding: 2px 0px;\n  font-family: \"Lucida Grande\", \"Arial\", sans-serif;\n  font-size: 12px;\n}\n\n.ic-menu-item {\n  padding: 4px 20px;\n  cursor: default;\n  white-space: nowrap;\n}\n\n.ic-menu-item:focus {\n  background: #3879D9;\n  color: #fff;\n  outline: none;\n}\n</style>\n\n");
  
});

Ember.TEMPLATES["components/ic-menu-item"] = Ember.Handlebars.template(function anonymous(Handlebars,depth0,helpers,partials,data) {
this.compilerInfo = [4,'>= 1.0.0'];
helpers = this.merge(helpers, Ember.Handlebars.helpers); data = data || {};
  var buffer = '', hashTypes, hashContexts, escapeExpression=this.escapeExpression;


  hashTypes = {};
  hashContexts = {};
  data.buffer.push(escapeExpression(helpers._triageMustache.call(depth0, "yield", {hash:{},contexts:[depth0],types:["ID"],hashContexts:hashContexts,hashTypes:hashTypes,data:data})));
  data.buffer.push("\n");
  return buffer;
  
});

Ember.TEMPLATES["components/ic-menu-list"] = Ember.Handlebars.template(function anonymous(Handlebars,depth0,helpers,partials,data) {
this.compilerInfo = [4,'>= 1.0.0'];
helpers = this.merge(helpers, Ember.Handlebars.helpers); data = data || {};
  var buffer = '', hashTypes, hashContexts, escapeExpression=this.escapeExpression;


  hashTypes = {};
  hashContexts = {};
  data.buffer.push(escapeExpression(helpers._triageMustache.call(depth0, "yield", {hash:{},contexts:[depth0],types:["ID"],hashContexts:hashContexts,hashTypes:hashTypes,data:data})));
  data.buffer.push("\n");
  return buffer;
  
});

Ember.TEMPLATES["components/ic-menu-trigger"] = Ember.Handlebars.template(function anonymous(Handlebars,depth0,helpers,partials,data) {
this.compilerInfo = [4,'>= 1.0.0'];
helpers = this.merge(helpers, Ember.Handlebars.helpers); data = data || {};
  var buffer = '', hashTypes, hashContexts, escapeExpression=this.escapeExpression;


  hashTypes = {};
  hashContexts = {};
  data.buffer.push(escapeExpression(helpers._triageMustache.call(depth0, "yield", {hash:{},contexts:[depth0],types:["ID"],hashContexts:hashContexts,hashTypes:hashTypes,data:data})));
  data.buffer.push("\n\n");
  return buffer;
  
});

Ember.TEMPLATES["components/ic-menu"] = Ember.Handlebars.template(function anonymous(Handlebars,depth0,helpers,partials,data) {
this.compilerInfo = [4,'>= 1.0.0'];
helpers = this.merge(helpers, Ember.Handlebars.helpers); data = data || {};
  var buffer = '', hashTypes, hashContexts, escapeExpression=this.escapeExpression;


  hashTypes = {};
  hashContexts = {};
  data.buffer.push(escapeExpression(helpers._triageMustache.call(depth0, "yield", {hash:{},contexts:[depth0],types:["ID"],hashContexts:hashContexts,hashTypes:hashTypes,data:data})));
  data.buffer.push("\n");
  return buffer;
  
});
  return ic;
});

