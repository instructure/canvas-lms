define ->
  processMigrationItemSelections = (data) ->
    newData = {items_to_copy: {}}
    # matches copy[folders][I_00001_R] and puts "folder" in first capture and the id in second
    reAssetId = /copy\[([^\]]*)\]\[([^\]]*)\]/
    for own key, value of data
      matchData = key.match(reAssetId)
      if matchData
        assetType = matchData[1]
        assetID = matchData[2]
        if value is "1"
          newData.items_to_copy[assetType] ||= []
          newData.items_to_copy[assetType].push assetID
      else
        newData[key] = value
    
    newData
