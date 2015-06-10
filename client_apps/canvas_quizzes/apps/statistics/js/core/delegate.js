define(function(require) {
  var React = require('react');
  var _ = require('lodash');
  var config = require('../config');
  var initialize = require('../config/initializer');
  var controller = require('./controller');
  var Layout = require('jsx!../views/app');
  var extend = _.extend;
  var container;
  var layout;

  /**
   * @class Statistics.Core.Delegate
   *
   * The client app delegate. This is the main interface that embedding
   * applications use to interact with the client app.
   */
  var exports = {};

  /**
   * Configure the application. See Config for the supported options.
   *
   * @param  {Object} options
   *         A set of options to override.
   */
  var configure = function(options) {
    extend(config, options);
  };

  /**
   * Start the app and perform any necessary data loading.
   *
   * @param  {HTMLElement} node
   *         The node to mount the app in.
   *
   * @param  {Object} [options={}]
   *         Options to configure the app with. See config.js
   *
   * @return {RSVP.Promise}
   *         Fulfilled when the app has been started and rendered.
   */
  var mount = function(node, options) {
    configure(options);
    container = node;

    return initialize().then(function() {
      layout = React.renderComponent(Layout(), container);
      controller.start(update);
    });
  };

  var isMounted = function() {
    return !!layout;
  };

  var update = function(props) {
    layout.setProps(props);
  };

  var reload = function() {
    controller.load();
  };

  var unmount = function() {
    if (isMounted()) {
      controller.stop();
      React.unmountComponentAtNode(container);
      container = undefined;
    }
  };

  exports.configure = configure;
  exports.mount = mount;
  exports.isMounted = isMounted;
  exports.update = update;
  exports.reload = reload;
  exports.unmount = unmount;

  //>>excludeStart("production", pragmas.production);
  // You can use this in development to read the props of the app layout
  // directly in console.
  //
  //     require([ 'core/delegate' ], function(Delegate) {
  //       Delegate.__getLayout__().props; // {}
  //     });
  exports.__getLayout__ = function() { return layout; }
  //>>excludeEnd("production");

  return exports;
});