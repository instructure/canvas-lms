//
// Copyright (C) 2014 - present Instructure, Inc.
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

// A console interface you can use for logging that will be mute unless you
// explicitly tell it not to be by setting "debug_js=1" in the query string.
//
// @return {Object}
//   An object that has an API similar to `console` and responds to the methods:
//   "debug", "info", "log", "warn", "error"
if (`${location.search}`.match(/[?&]debug_js=1/)) {
  module.exports = console
} else {
  function sink() {}
  module.exports = ['debug', 'info', 'log', 'warn', 'error'].reduce((logger, logLevel) => {
    logger[logLevel] = sink
    return logger
  }, {})
}
