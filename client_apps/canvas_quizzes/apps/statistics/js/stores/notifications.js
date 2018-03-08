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
  var Store = require('canvas_quizzes/core/store')
  var Dispatcher = require('../core/dispatcher')
  var _ = require('lodash')
  var throttle = _.throttle

  /**
   * @class Stores.Notifications
   *
   * Display "stateful" and "one-time" alerts and notices.
   */
  var store = new Store(
    'notifications',
    {
      _state: {
        notifiers: [],
        notifications: [],
        dismissed: [],
        watchedTargets: []
      },

      initialize: function() {
        this.run = throttle(this.run.bind(this), 100, {
          leading: false,
          trailing: true
        })
      },

      registerWatcher: function(notifier) {
        var watchTargets = notifier.watchTargets || []
        var watchedTargets = this._state.watchedTargets
        var run = this.run.bind(this)

        watchTargets
          .filter(function(target) {
            return watchedTargets.indexOf(target) === -1
          })
          .forEach(function(target) {
            target.addChangeListener(run)
          })

        this._state.notifiers.push(notifier)
      },

      /**
       * @return {Models.Notification[]}
       *         All available notifications. Notifications that were dismissed
       *         by the user will not be returned.
       */
      getAll: function() {
        var dismissed = this._state.dismissed

        return this._state.notifications
          .filter(function(notification) {
            return dismissed.indexOf(notification.id) === -1
          })
          .map(function(notification) {
            return notification.toJSON()
          })
      },

      run: function() {
        this._state.notifications = this._state.notifiers.reduce(function(notifications, notifier) {
          return notifications.concat(notifier())
        }, [])

        this.emitChange()
      },

      actions: {
        /**
         * Dismiss a notification during the current session. Dismissals do not
         * currently persist through page refreshes.
         *
         * @param  {String} id
         *         The unique notification id.
         */
        dismiss: function(id, onChange /*, onError*/) {
          var dismissed = this._state.dismissed

          if (dismissed.indexOf(id) === -1) {
            dismissed.push(id)
            onChange()
          }
        }
      }
    },
    Dispatcher
  )

  return store
})
