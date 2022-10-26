//
// Copyright (C) 2013 - present Instructure, Inc.
//
// This file is part of Canvas.
//
// Canvas is free software: you can redistribute it and/or modify it under
// the terms of the GNU Affero General Public License as published by the Free
// Software Foundation, version 3 of the License.
//
// Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
// A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
// details.
//
// You should have received a copy of the GNU Affero General Public License along
// with this program. If not, see <http://www.gnu.org/licenses/>.

import Application from '../index'
import Ember from 'ember'

export default function startApp() {
  let App = null

  // supresses this from logging during tests:
  // DEBUG LOG: 'DEBUG: -------------------------------'
  // DEBUG LOG: 'DEBUG: Ember      : 1.4.0'
  // DEBUG LOG: 'DEBUG: Handlebars : 1.3.0'
  // DEBUG LOG: 'DEBUG: jQuery     : 1.7.2'
  // DEBUG LOG: 'DEBUG: -------------------------------'
  Ember.LOG_VERSION = false

  // since we don't plan on upgrading any of our ember code to new versions
  // and we consider it "done" we don't care about deprecation warnings
  Ember.TESTING_DEPRECATION = true

  Ember.run.join(() => {
    App = Application.create({
      rootElement: '#fixtures',
    })
    App.Router.reopen({history: 'none'})
    App.setupForTesting()
    return App.injectTestHelpers()
  })
  window.App = App
  return App
}
