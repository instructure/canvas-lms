define((require) => {
  const React = require('old_version_of_react_used_by_canvas_quizzes_client_apps');
  const _ = require('lodash');
  const config = require('../config');
  const initialize = require('../config/initializer');
  const Layout = require('jsx!../bundles/routes');
  const controller = require('./controller');
  const extend = _.extend;
  let container;
  let layout;

  /**
   * @class Events.Core.Delegate
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
      layout = React.renderComponent(Layout, container);
      controller.start(update);
    });
  };

  const isMounted = function () {
    return !!layout;
  };

  var update = function (props) {
    layout.getActiveComponent().setState(props);
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

  return exports;
});
