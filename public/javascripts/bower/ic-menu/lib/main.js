// <look-the-other-way>
+function(root, factory) {
  if (typeof define === 'function' && define.amd) {
    define([
      'ember',
      './components/ic-menu-item',
      './components/ic-menu-list',
      './components/ic-menu-trigger',
      './components/ic-menu',
      'ic-styled'
    ], function(Ember, Item, List, Trigger) {
      return factory(Ember, Item, List, Trigger, Menu);
    });
  } else if (typeof exports === 'object') {
    module.exports = factory(
      require('ember'),
      require('./components/ic-menu-item'),
      require('./components/ic-menu-list'),
      require('./components/ic-menu-trigger'),
      require('./components/ic-menu'),
      require('ic-styled')
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
      //application.IcMenuItemComponent = Item;
      //application.IcMenuListComponent = List;
      //application.IcMenuTriggerComponent = Trigger;
      //application.IcMenuComponent = Menu;
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

