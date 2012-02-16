# Utility methods for arrays of objects
#
# Returns an array with extra methods.  It uses direct property injection so our
# prototypes are still clean, but we get a nice OO syntax for these kinds
# of arrays.
define ->
  (array) ->

    array.indexOf = (needle) ->
      for item, index in array
        return index if item is needle
    -1

    # Can find a specific element by a property ie:
    #   arr = arrayOfObjects([{id: 1}, {id: 2}])
    #   arr.findBy('id', 1) //> {id: 1}
    array.findBy = (prop, value) ->
      for item, index in array
        return item if (item[prop] is value)
      false

    array.eraseBy = (prop, value) ->
      item = array.findBy(prop, value)
      array.erase(item)

    # Inserts an item into an array at a specific index
    array.insert = (item, index = 0) ->
      array.splice(index, 0, item)

    # erases an item from an array, if it exists
    array.erase = (victim) ->
      for prospect, index in array
        array.splice(index, 1) if prospect is victim

    # Sort an array of of objects by object property, Supports sorting by strings
    # and numbers
    array.sortBy = do ->
      sorters =
        string: (a, b) ->
          if a < b
            -1
          else if a > b
            1
          else
            0

        number: (a, b) ->
          a - b

      (prop) ->
        return array if array.length is 0
        type = typeof array[0][prop] or 'string'
        array.sort (a, b) ->
          return sorters[type](a[prop], b[prop])

    return array

