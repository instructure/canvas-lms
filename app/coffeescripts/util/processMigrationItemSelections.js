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

const reAssetId = /copy\[([^\]]*)\]\[([^\]]*)\]/
// matches copy[all_folders] and puts "folder" in the capture
const reAllSelection = /copy\[all_([^\]]*)\]/

// Utility method to alter a migration form data to use less keys
// Puts the selected items into lists
// removes the individually selected items if the all_item option is chosen for it
// see the test for a simple example
// matches copy[folders][I_00001_R] and puts "folder" in first capture and the id in second
export default function processMigrationItemSelections(data) {
  const newData = {
    items_to_copy: {}
  }
  const allSelections = []
  const copyEverything = data['copy[everything]'] === '1'

  Object.keys(data || {}).forEach(key => {
    const value = data[key]
    let matchData = key.match(reAssetId)
    if (matchData) {
      const assetType = matchData[1]
      const assetID = matchData[2]
      if (assetType === 'day_substitutions') {
        newData[key] = value
        return
      }
      if (copyEverything) return
      if (value === '1') {
        ;(newData.items_to_copy[assetType] || (newData.items_to_copy[assetType] = [])).push(assetID)
      }
    } else {
      if ((matchData = key.match(reAllSelection))) {
        if (copyEverything) return
        if (value === '1') {
          allSelections.push(matchData[1])
        }
      }
      newData[key] = value
    }
  })

  allSelections.forEach(allSelection => delete newData.items_to_copy[allSelection])

  return newData
}
