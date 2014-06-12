+function(root, factory) {
  if (typeof define === 'function' && define.amd) {
    define([
      'ember',
      './lib/components/ic-lazy-list',
      './lib/templates'
    ], function(Ember, IcLazyListComponent) {
      return factory(Ember, IcLazyListComponent);
    });
  } else if (typeof exports === 'object') {
    module.exports = factory(
      require('ember'),
      require('./lib/components/ic-lazy-list'),
      require('./lib/templates')
    );
  } else {
    factory(Ember, ic.LazyListComponent);
  }
}(this, function(Ember, IcLazyListComponent) {

  Ember.Application.initializer({
    name: 'ic-lazy-list',
    initialize: function(container, application) {
      container.register('component:ic-lazy-list', IcLazyListComponent);
    }
  });

  return {
    IcLazyListComponent: IcLazyListComponent
  };

});

