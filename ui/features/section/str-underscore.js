//
// Copyright (C) 2011 - present Instructure, Inc.
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
//

// given a string, convert it from camelcase, title case, etc.
// to underscores.
//
// ex.
//
// str = 'SpyHunterIsMyFavoriteVideoGame'
// underscore str # returns 'spy_hunter_is_my_favorite_video_game'
//
// @param {String} string - the string to convert to underscores
//
// @return String
export default function underscore(string) {
  if (typeof string !== 'string' || string === '') return string
  return string
    .replace(/([A-Z])/g, '_$1')
    .replace(/^_/, '')
    .toLowerCase()
}
