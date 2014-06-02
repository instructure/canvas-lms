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

