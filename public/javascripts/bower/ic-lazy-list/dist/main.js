+function(root, factory) {
  if (typeof define === 'function' && define.amd) {
    define(['ember', 'ic-ajax'], function(Ember, ajax) {
      return factory(Ember, ajax);
    });
  } else if (typeof exports === 'object') {
    module.exports = factory(require('ember'), require('ic-ajax'));
  } else {
    (root.ic || (root.ic = {})).LazyListComponent = factory(Ember, ic.ajax);
  }
}(this, function(Ember, ajax) {

  /*
   * taken from underscore, see license at
   * https://github.com/jashkenas/underscore/blob/master/LICENSE
   * will remove as soon as backburner run.throttle invokes on first call
   */

  var throttle = function(func, wait) {
    var context, args, timeout, result;
    var previous = 0;
    var later = function() {
      previous = new Date;
      timeout = null;
      result = func.apply(context, args);
    };
    return function() {
      var now = new Date;
      var remaining = wait - (now - previous);
      context = this;
      args = arguments;
      if (remaining <= 0) {
        clearTimeout(timeout);
        timeout = null;
        previous = now;
        result = func.apply(context, args);
      } else if (!timeout) {
        timeout = setTimeout(later, remaining);
      }
      return result;
    };
  };

  /*
   * Lazily loads records from a url.
   */

  var IcLazyList = Ember.Component.extend({

    tagName: 'ic-lazy-list',

    isLoading: false,

    'is-loading': Ember.computed.alias('isLoading'),

    registerWithConstructor: function() {
      if (this.get('meta.next')) this.constructor.register(this);
    }.observes('meta.next'),

    unregisterFromConstructor: function() {
      if (!this.get('meta.next')) this.constructor.unregister(this);
    }.observes('meta.next'),

    unregisterOnDestroy: function() {
      this.constructor.unregister(this);
    }.on('willDestroyElement'),

    reset: function() {
      this.loadRecords();
    }.on('didInsertElement'),

    setMeta: function() {
      this.set('meta', Ember.Object.create());
    }.on('init'),

    loadRecords: function(href) {
      href = href || this.get('href');
      this.set('isLoading', true);
      this.request(href).then(
        this.ajaxSuccess.bind(this),
        this.ajaxError.bind(this)
      );
    },

    request: function(href) {
      return ajax.raw(href);
    },

    loadNextRecords: function() {
      this.loadRecords(this.get('meta.next'));
    },

    ajaxSuccess: function(result) {
      this.get('data').pushObjects(this.normalize(result));
      this.set('meta', this.extractMeta(result));
      this.set('isLoading', false);
    },

    ajaxError: function(result) {
      this.sendAction('on-error', result);
    },

    /*
     * Override this to normalize the data differently
     */

    normalize: function(result) {
      var key = this.get('data-key');
      return key ? result.response[key] : result.response;
    },

    /*
     * Override this to extract the meta data from your request differently.
     * In most of canvas-lms we use the link header, so it is the default
     * for this component (see:
     * https://canvas.instructure.com/doc/api/file.pagination.html)
     *
     * For example, to use a "meta" key instead you could do this:
     *
     * ```js
     * IcLazyList.reopen({
     *   extractMeta: function(result) {
     *     return result.response.meta;
     *   }
     * });
     * ```
     */

    extractMeta: function(result) {
      var regex = /<(http.*?)>; rel="([a-z]*)",?/g;
      var links = {};
      var header = result.jqXHR.getResponseHeader('Link');
      if (!header) return links;
      var link;
      while (link = regex.exec(header)) {
        links[link[2]] = link[1];
      }
      return links;
    }

  });

  IcLazyList.reopenClass({

    views: [],

    scrollContainer: Ember.$(window),

    scrollBuffer: 500,

    register: function(view) {
      this.views.addObject(view);
      if (this.views.length) this.attachScroll();
      Ember.run.scheduleOnce('afterRender', this, 'checkViews');
    },

    attachScroll: function() {
      var handler = throttle(function() {
        Ember.run(this, 'checkViews');
      }.bind(this), 100);
      this.scrollContainer.on('scroll.ic-lazy-list', handler);
    },

    unregister: function(view) {
      this.views.removeObject(view);
      if (!this.views.length) {
        this.scrollContainer.off('.ic-lazy-list');
      }
    },

    checkViews: function() {
      var bottom, view;
      for (var i = 0, l = this.views.length; i < l; i++) {
        view = this.views[i];
        if (view.get('isLoading')) {
          continue;
        }
        bottom = view.get('element').getBoundingClientRect().bottom;
        if (bottom <= window.innerHeight + this.scrollBuffer) {
          view.loadNextRecords();
        }
      }
    }

  });

  return IcLazyList;

});


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

