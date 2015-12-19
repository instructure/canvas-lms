define ['str/pluralize'], (pluralize) ->
  (assetString, toPlural = true) ->
    if match = assetString.match(/(.*)_(\d+)$/)
      contextType = if toPlural then pluralize(match[1]) else match[1]
      [contextType, match[2]]
