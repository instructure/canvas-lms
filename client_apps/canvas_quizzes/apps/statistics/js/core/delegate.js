define((require) => {
  const React = require('old_version_of_react_used_by_canvas_quizzes_client_apps');
  const _ = require('lodash');
  const config = require('../config');
  const initialize = require('../config/initializer');
  const controller = require('./controller');
  const Layout = require('jsx!../views/app');
  const extend = _.extend;
  let container;
  let layout;

  /**
   * @class Statistics.Core.Delegate
   *
   * The client app delegate. This is the main interface that embedding
   * applications use to interact with the client app.
   */
  const exports = {};

  /**
   * Configure the application. See Config for the supported options.
   *
   * @param  {Object} options
   *         A set of options to override.
   */
  const configure = function (options) {
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
  const mount = function (node, options) {
    configure(options);
    container = node;

    return initialize().then(() => {
      layout = React.renderComponent(Layout(), container);
      controller.start(update);
    });
  };

  const isMounted = function () {
    return !!layout;
  };

  var update = function (props) {
    layout.setProps(props);
  };

  const reload = function () {
    controller.load();
  };

  const unmount = function () {
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

  // >>excludeStart("production", pragmas.production);
  // You can use this in development to read the props of the app layout
  // directly in console.
  //
  //     require([ 'core/delegate' ], function(Delegate) {
  //       Delegate.__getLayout__().props; // {}
  //     });
  exports.__getLayout__ = function () { return layout; }
  // >>excludeEnd("production");

  return exports;
});
