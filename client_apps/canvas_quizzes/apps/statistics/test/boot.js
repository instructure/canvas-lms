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
  var Dispatcher = require('core/dispatcher')
  var ReactSuite = require('jasmine_react')
  var _ = require('lodash')
  var config = require('config')
  var AppDelegate = require('core/delegate')

  var stockConfig = _.clone(config)
  var actionIndex = 0

  document.body.id = 'canvas-quiz-statistics'

  afterEach(function() {
    // Reset the app if it got mounted during a spec:
    if (AppDelegate.isMounted()) {
      AppDelegate.unmount()
    }

    // Restore any config parameters changed during tests:
    AppDelegate.configure(stockConfig)
  })

  // configure jasmine-react to work with our Dispatcher for testing sendAction
  // calls from components:
  ReactSuite.config.getSendActionSpy = function(subject) {
    var dispatch = Dispatcher.dispatch.bind(Dispatcher)

    return {
      original: dispatch,
      spy: spyOn(Dispatcher, 'dispatch')
    }
  }

  ReactSuite.config.decorateSendActionRc = function(promise) {
    return {
      index: ++actionIndex,
      promise: promise
    }
  }

  // return function(startTests) {
  //   require([ 'core/delegate' ], startTests);
  // };
})
