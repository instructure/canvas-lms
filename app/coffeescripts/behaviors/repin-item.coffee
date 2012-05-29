##
# Listens to clicks on elements that have `data-repin-item` attribute.
# the attribute should be set to the id of the item you want to repin.

# markup example:
#   <a data-repin-item='2' href="#">repin collectionItem 2</a>

define [
  'jquery'
  'compiled/fn/preventDefault'
  'vendor/jquery.ba-tinypubsub'
], ($, preventDefault, {publish}) ->

  $(document).delegate "[data-repin-item]", 'click', preventDefault ->
    itemId = $(this).data("repinItem")
    alert "TODO: create a new RepinItem dialog for collection item: #{itemId}}"