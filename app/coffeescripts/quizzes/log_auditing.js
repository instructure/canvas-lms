/*
 * Copyright (C) 2018 - present Instructure, Inc.
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

import K from './log_auditing/constants'
import EventManager from './log_auditing/event_manager'
import EventBuffer from './log_auditing/event_buffer'
import './log_auditing/event_tracker'
import hasLocalStorage from '../util/hasLocalStorage'
import debugConsole from '../util/debugConsole'
import page_focused from './log_auditing/event_trackers/page_focused'
import page_blurred from './log_auditing/event_trackers/page_blurred'
import question_viewed from './log_auditing/event_trackers/question_viewed'
import question_flagged from './log_auditing/event_trackers/question_flagged'
import session_started from './log_auditing/event_trackers/session_started'

// ---------------------------
// Trackers.
// ---------------------------
const trackers = [page_focused, page_blurred, question_viewed, question_flagged, session_started]

const eventManager = new EventManager()

// Register all event trackers
trackers.forEach(factory => eventManager.registerTracker(factory))

// Configure the EventBuffer to use localStorage if it's available:
if (hasLocalStorage) {
  debugConsole.debug('QuizLogAuditing: will be using localStorage.')
  EventBuffer.setStorageAdapter(K.EVT_STORAGE_LOCAL_STORAGE)
}

eventManager.options.deliveryUrl = ENV.QUIZ_SUBMISSION_EVENTS_URL

export default eventManager
