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
  var rawAjax = require('../util/xhr_request')
  var RSVP = require('rsvp')

  var Adapter = function(inputConfig) {
    this.config = inputConfig
  }

  Adapter.prototype.request = function(options) {
    var ajax = this.config.ajax || rawAjax

    options.headers = options.headers || {}
    options.headers['Content-Type'] = 'application/json'
    options.headers.Accept = 'application/vnd.api+json'

    if (this.config.apiToken) {
      options.headers.Authorization = 'Bearer ' + this.config.apiToken
    }

    if (options.type !== 'GET' && options.data) {
      options.data = JSON.stringify(options.data)
    }

    //>>excludeStart("production", pragmas.production);
    if (this.config.fakeXHRDelay) {
      var svc = RSVP.defer()

      setTimeout(function() {
        RSVP.Promise.cast(ajax(options)).then(svc.resolve, svc.reject)
      }, this.config.fakeXHRDelay)

      return svc.promise
    }
    //>>excludeEnd("production");

    return RSVP.Promise.cast(ajax(options))
  }

  return Adapter
})
