/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

import {createContext} from 'react'
import {pick} from 'lodash'

export const GroupContext = createContext({
  name: '',
})

export function formatMessages(text) {
  if (text) return [{text, type: 'error'}]
  return []
}

const CONTEXT_KEYS = Object.freeze([
  'name',
  'selfSignup',
  'groupLimit',
  'bySection',
  'enableAutoLeader',
  'autoLeaderType',
  'splitGroups',
  'createGroupCount',
  'createGroupMemberCount',
])

export const stateToContext = state => pick(state, CONTEXT_KEYS)

export const SPLIT = Object.freeze({
  off: '0',
  byGroupCount: '1',
  byMemberCount: '2',
})

export const API_STATE = Object.freeze({
  inactive: 0, // nothing pending from the back end
  submitting: 1, // API call to create group set is pending
  assigning: 2, // Polling for assigning to groups is in progress
})
