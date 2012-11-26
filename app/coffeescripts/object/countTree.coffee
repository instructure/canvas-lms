define ['compiled/arr/walk'], (walk) ->

  ##
  # Counts the number of items in a nested object tree
  # ex:
  #   obj = {a:[{a:[{a:[{}]}]}]}
  #   countTree(object, 'a') is 3

  countTree = (obj, prop) ->
    count = 0
    return count unless obj[prop]
    walk obj[prop], prop, -> count++
    count

