#
# Copyright (C) 2012 - present Instructure, Inc.
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

# Utility method to alter a migration form data to use less keys
# Puts the selected items into lists
# removes the individually selected items if the all_item option is chosen for it
# see the test for a simple example
define ->
  # matches copy[folders][I_00001_R] and puts "folder" in first capture and the id in second
  reAssetId = /copy\[([^\]]*)\]\[([^\]]*)\]/
  # matches copy[all_folders] and puts "folder" in the capture
  reAllSelection = /copy\[all_([^\]]*)\]/

  processMigrationItemSelections = (data) ->
    newData = {items_to_copy: {}}
    allSelections = []
    copyEverything = data['copy[everything]'] is "1"

    for own key, value of data
      if matchData = key.match(reAssetId)
        assetType = matchData[1]
        assetID = matchData[2]
        if assetType is "day_substitutions"
          newData[key] = value
          continue
        continue if copyEverything
        if value is "1"
          newData.items_to_copy[assetType] ||= []
          newData.items_to_copy[assetType].push assetID
      else
        if matchData = key.match(reAllSelection)
          continue if copyEverything
          allSelections.push matchData[1] if value is "1"
        newData[key] = value

    for allSelection in allSelections
      delete newData.items_to_copy[allSelection]

    newData
