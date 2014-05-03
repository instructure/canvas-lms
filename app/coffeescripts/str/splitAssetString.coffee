define ['str/pluralize'], (pluralize) ->
  (assetString) ->
    if match = assetString.match(/(.*)_(\d+)$/)
      [pluralize(match[1]), match[2]]
