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
  var Dispatcher = require('../../core/dispatcher');

  /**
   * @class Statistics.Mixins.Components.ActorMixin
   *
   * Extend a component with the ability to dispatch (and track) events to
   * stores directly using a `#sendAction()` helper.
   */
  var ActorMixin = {
    getInitialState: function() {
      return {
        actionIndex: null
      };
    },

    getDefaultProps: function() {
      return {
        storeError: null
      };
    },

    componentWillReceiveProps: function(nextProps) {
      var storeError = nextProps.storeError;

      if (storeError && storeError.actionIndex === this.state.actionIndex) {
        this.setState({ storeError: storeError });
      }
    },

    componentDidUpdate: function() {
      if (this.state.storeError) {
        if (this.onStoreError) {
          this.onStoreError(this.state.storeError);
        }

        // Consume it so that the handling code doesn't get called repeatedly.
        this.setState({ storeError: null });
      }
    },

    componentWillUnmount: function() {
      this.lastAction = undefined;
    },

    /**
     * Convenient method for consuming events.
     *
     * @param {Event} e
     *        Something that responds to #preventDefault().
     */
    consume: function(e) {
      if (e) {
        e.preventDefault();
      }
    },

    /**
     * Send an action via the Dispatcher, track the action promise, and any
     * error the handler raises.
     *
     * A reference to the action handler's promise will be kept in
     * `this.lastAction`. The index of the action is tracked in
     * this.state.actionIndex.
     *
     * If an error is raised, it will be accessible in `this.state.storeError`.
     *
     * @param {String} action (required)
     *        Unique action identifier. Must be scoped by the store key, e.g:
     *        "categories:save", or "users:changePassword".
     *
     * @param {Object} [params={}]
     *        Action payload.
     *
     * @param {Object} [options={}]
     * @param {Boolean} [options.track=true]
     *        Pass as false if you don't want the mixin to perform any tracking.
     *
     * @return {RSVP.Promise}
     *         The action promise which will fulfill if the action succeeds,
     *         or fail if the action doesn't. Failure will be presented by
     *         an error that adheres to the UIError interface.
     */
    sendAction: function(action, params, options) {
      var service;
      var setState;

      service = Dispatcher.dispatch(action, params);

      if (options && options.track === false) {
        return;
      }

      setState = this.setState.bind(this);
      this.lastAction = service.promise;

      setState({
        actionIndex: service.index
      });

      service.promise.then(null, function(error) {
        setState({
          storeError: {
            actionIndex: service.index,
            error: error
          }
        });
      });

      return service.promise;
    }
  };

  return ActorMixin;
});
