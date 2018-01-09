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
  K = require('./log_auditing/constants')
  EventManager = require('./log_auditing/event_manager')
  EventBuffer = require('./log_auditing/event_buffer')
  EventTracker = require('./log_auditing/event_tracker')
  hasLocalStorage = require('../util/hasLocalStorage')
  debugConsole = require('../util/debugConsole')

  # ---------------------------
  # Trackers.
  # ---------------------------
  trackers = []
  trackers.push require('./log_auditing/event_trackers/page_focused')
  trackers.push require('./log_auditing/event_trackers/page_blurred')
  trackers.push require('./log_auditing/event_trackers/question_viewed')
  trackers.push require('./log_auditing/event_trackers/question_flagged')
  trackers.push require('./log_auditing/event_trackers/session_started')

  eventManager = new EventManager()

  # Register all event trackers
  trackers.forEach (factory) ->
    eventManager.registerTracker(factory)

  # Configure the EventBuffer to use localStorage if it's available:
  if hasLocalStorage
    debugConsole.debug('QuizLogAuditing: will be using localStorage.')
    EventBuffer.setStorageAdapter(K.EVT_STORAGE_LOCAL_STORAGE)

  eventManager.options.deliveryUrl = ENV.QUIZ_SUBMISSION_EVENTS_URL

  eventManager