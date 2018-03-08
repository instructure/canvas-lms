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

export default function processItemSelections(data) {
  const newData = {items_to_copy: []}
  const reAssetString = /copy\[([^\]]*)\]$/
  Object.keys(data || {}).forEach(key => {
    const value = data[key]
    const matchData = key.match(reAssetString)
    if (matchData) {
      const assetString = matchData[1]
      if (value === '1') {
        newData.items_to_copy.push(assetString)
      } else if (value !== '0') {
        newData[key] = value
      }
    } else {
      newData[key] = value
    }
  })

  return newData
}
