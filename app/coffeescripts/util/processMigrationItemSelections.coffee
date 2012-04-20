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

    for own allSelection in allSelections
      delete newData.items_to_copy[allSelection]

    newData
