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

export default {
  EVT_PAGE_FOCUSED: 'page_focused',
  EVT_PAGE_BLURRED: 'page_blurred',
  EVT_QUESTION_VIEWED: 'question_viewed',
  EVT_QUESTION_FLAGGED: 'question_flagged',
  EVT_SESSION_STARTED: 'session_started',

  EVT_PRIORITY_LOW: 0,
  EVT_PRIORITY_HIGH: 100,

  EVT_STATE_PENDING_DELIVERY: 'pending_delivery',
  EVT_STATE_IN_DELIVERY: 'in_delivery',
  EVT_STATE_DELIVERED: 'delivered',

  // localStorage key where we'll be saving events
  EVT_STORAGE_KEY: 'qla_events',

  EVT_STORAGE_MEMORY: 'memory',
  EVT_STORAGE_LOCAL_STORAGE: 'localStorage',
}
