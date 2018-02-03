#
# Copyright (C) 2014 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

define (require) ->
  EventTracker = require('../event_tracker')
  K = require('../constants')
  debugConsole = require('../../../util/debugConsole')

  class SessionStarted extends EventTracker
    eventType: K.EVT_SESSION_STARTED
    options: {
    }

    install: (deliver) ->
      userAgent = navigator.userAgent
      debugConsole.log """
        I've been loaded by #{userAgent}.
        """
      if location.href.indexOf("question") == -1 && location.href.indexOf("take") > 0
        deliver({
            'user_agent': userAgent
          })