/*
 * Copyright (C) 2014 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

define(function(require) {
  var React = require('old_version_of_react_used_by_canvas_quizzes_client_apps')
  var _ = require('lodash')
  var config = require('../config')
  var initialize = require('../config/initializer')
  var Layout = require('jsx!../bundles/routes')
  var controller = require('./controller')
  var extend = _.extend
  var container
  var layout

  /**
   * @class Events.Core.Delegate
   *
   * The client app delegate. This is the main interface that embedding
   * applications use to interact with the client app.
   */
  var exports = {}

  /**
   * Configure the application. See Config for the supported options.
   *
   * @param  {Object} options
   *         A set of options to override.
   */
  var configure = function(options) {
    extend(config, options)
  }

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
    configure(options)
    container = node

    return initialize().then(function() {
      layout = React.renderComponent(Layout, container)
      controller.start(update)
    })
  }

  var isMounted = function() {
    return !!layout
  }

  var update = function(props) {
    layout.getActiveComponent().setState(props)
  }

  var reload = function() {
    controller.load()
  }

  var unmount = function() {
    if (isMounted()) {
      controller.stop()
      React.unmountComponentAtNode(container)
      container = undefined
    }
  }

  exports.configure = configure
  exports.mount = mount
  exports.isMounted = isMounted
  exports.update = update
  exports.reload = reload
  exports.unmount = unmount

  return exports
})
