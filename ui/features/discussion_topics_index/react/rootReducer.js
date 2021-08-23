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

import {combineReducers} from 'redux'
import {handleAction} from 'redux-actions'
import {reduceNotifications} from '@canvas/notifications/redux/actions'
import {createPaginatedReducer} from '@canvas/pagination/redux/actions'
import {actionTypes} from './actions'
import allDiscussionsReducer from './reducers/allDiscussionsReducer'
import pinnedDiscussionReducer from './reducers/pinnedDiscussionReducer'
import unpinnedDiscussionReducer from './reducers/unpinnedDiscussionReducer'
import closedForCommentsDiscussionReducer from './reducers/closedForCommentsDiscussionReducer'
import deleteFocusReducer from './reducers/deleteFocusReducer'
import userSettingsReducer from './reducers/userSettingsReducer'
import courseSettingsReducer from './reducers/courseSettingsReducer'
import isSavingSettingsReducer from './reducers/isSavingSettingsReducer'
import isSettingsModalOpenReducer from './reducers/isSettingsModalOpenReducer'
import copyToReducer from './reducers/copyToReducer'
import sendToReducer from './reducers/sendToReducer'

const identity = (defaultState = null) => state => (state === undefined ? defaultState : state)

export default combineReducers({
  allDiscussions: allDiscussionsReducer,
  closedForCommentsDiscussionIds: closedForCommentsDiscussionReducer,
  contextCodes: identity([]),
  contextId: identity(null),
  contextType: identity(null),
  courseSettings: courseSettingsReducer,
  currentUserId: identity(null),
  deleteFocusPending: deleteFocusReducer,
  discussions: createPaginatedReducer('discussions'),
  discussionTopicMenuTools: identity([]),
  discussionTopicIndexMenuTools: identity([]),
  isSavingSettings: isSavingSettingsReducer,
  isSettingsModalOpen: isSettingsModalOpenReducer,
  masterCourseData: identity(null),
  notifications: reduceNotifications,
  permissions: identity({}),
  pinnedDiscussionIds: pinnedDiscussionReducer,
  roles: identity({}),
  unpinnedDiscussionIds: unpinnedDiscussionReducer,
  userSettings: userSettingsReducer,
  copyTo: copyToReducer,
  sendTo: sendToReducer,
  DIRECT_SHARE_ENABLED: identity(false),
  COURSE_ID: identity(null)
})
