//
// Copyright (C) 2023 - present Instructure, Inc.
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

const userSettings = {
  get: get('current_user_id'),
  contextGet: get('current_user_id', 'context_asset_string'),
  set: set('current_user_id'),
  contextSet: set('current_user_id', 'context_asset_string'),
  remove: remove('current_user_id'),
  contextRemove: remove('current_user_id', 'context_asset_string'),
}

function get(...tokens: string[]) {
  return function <T>(key: string): T | undefined {
    const joinedTokens = tokens.map(token => (window.ENV as Record<string, any>)[token]).join('_')
    try {
      const res = localStorage.getItem(`_${joinedTokens}_${key}`)
      if (res === 'undefined') return undefined
      if (res) return JSON.parse(res) as undefined
    } catch (_ex) {
      return undefined
    }
  }
}

function set(...tokens: string[]) {
  return function <T>(key: string, value: T) {
    const stringifiedValue = JSON.stringify(value)
    const joinedTokens = tokens.map(token => (window.ENV as Record<string, any>)[token]).join('_')
    try {
      localStorage.setItem(`_${joinedTokens}_${key}`, stringifiedValue)
    } catch (_ex) {
      // ignore
    }
  }
}

function remove(...tokens: string[]) {
  return function (key: string) {
    const joinedTokens = tokens.map(token => (window.ENV as Record<string, any>)[token]).join('_')
    try {
      localStorage.removeItem(`_${joinedTokens}_${key}`)
    } catch (_ex) {
      // ignore
    }
  }
}

export default userSettings
