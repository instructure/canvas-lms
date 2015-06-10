#
# Handles navigation through a collection.
#
define [], ->

  CollectionHandler =

    isBackboneCollection: (collection) ->
      return collection instanceof Backbone.Collection

    # Get the previous item in a collection.
    getPreviousInRelationTo : (collection, collectionItem) ->

      isBackbone = @isBackboneCollection(collection)

      itemIndex = collection.indexOf(collectionItem)

      # Return null if the item wasn't found.
      return null unless itemIndex >= 0

      nextIndex = itemIndex - 1

      # Return the last item if we were at the first.
      if nextIndex < 0
        if isBackbone
          return collection.at(collection.length - 1)
        else
          return collection[collection.length - 1]

      # Otherwise let's just return the previous item.
      if isBackbone then collection.at(nextIndex) else collection[nextIndex]

    # Get the next item in a collection.
    getNextInRelationTo : (collection, collectionItem) ->

      isBackbone = @isBackboneCollection(collection)

      itemIndex = collection.indexOf(collectionItem)

      # Return null if the item wasn't found.
      return null unless itemIndex >= 0

      nextIndex = itemIndex + 1

      # Return the first item if we were at the last.
      if nextIndex > collection.length - 1
        if isBackbone
          return collection.at(0)
        else
          return collection[0]
      # Otherwise let's just return the next item.
      if isBackbone then collection.at(nextIndex) else collection[nextIndex]