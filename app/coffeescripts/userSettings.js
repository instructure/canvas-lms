//
// Copyright (C) 2012 - present Instructure, Inc.
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

// uses the global ENV.current_user_id and ENV.context_asset_string varibles to store things in
// localStorage (safe, since we only support ie8+) keyed to the user (and current context)
//
// DO NOT PUT SENSITIVE DATA HERE
//
// usage:
//
// userSettings.set 'favoriteColor', 'red'
// userSettings.get 'favoriteColor' # => 'red'
//
// # when you are on /courses/1/x
// userSettings.contextSet 'specialIds', [1,2,3]
// userSettings.contextGet 'specialIds'  # => [1,2,3]
// # when you are on /groups/1/x
// userSettings.contextGet 'specialIds' # => undefined
// # back on /courses/1/x
// userSettings.contextRemove 'specialIds'

import $ from 'jquery'
import 'jquery.instructure_misc_helpers'

const userSettings = {
  globalEnv: window.ENV
}

function addTokens(method, ...tokens) {
  return function(key, value) {
    const stringifiedValue = JSON.stringify(value)
    const joinedTokens = tokens.map(token => userSettings.globalEnv[token]).join('_')
    const res = localStorage[`${method}Item`](`_${joinedTokens}_${key}`, stringifiedValue)
    if (res === 'undefined') return undefined
    if (res) return JSON.parse(res)
  }
}

;['get', 'set', 'remove'].forEach(method => {
  userSettings[method] = addTokens(method, 'current_user_id')
  userSettings[`context${$.capitalize(method)}`] = addTokens(
    method,
    'current_user_id',
    'context_asset_string'
  )
})

export default userSettings
