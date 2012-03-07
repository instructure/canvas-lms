define ->
  processItemSelections = (data) ->
    newData = {items_to_copy: []}
    reAssetString = /copy\[([^\]]*)\]$/
    for own key, value of data
      matchData = key.match(reAssetString)
      if matchData
        assetString = matchData[1]
        if value is "1"
          newData.items_to_copy.push assetString
        else if value != "0"
          newData[key] = value
      else
        newData[key] = value

    newData
