##
# Listens to clicks on elements that have `data-repin-item` attribute.
# the attribute should be set to the id of the item you want to repin.

# markup example:
#   <a data-repin-item='2' href="#">repin collectionItem 2</a>

define [
  'jquery'
  'compiled/fn/preventDefault'
  'vendor/jquery.ba-tinypubsub'
  'compiled/views/KollectionItems/KollectionItemSaveView'
  'compiled/models/KollectionItem'
  'jst/KollectionItems/modalSaveTemplate'

  # needed by modalSaveTemplate
  'jst/_avatar'
], ($, preventDefault, {publish}, KollectionItemSaveView, KollectionItem, modalSaveTemplate) ->

  $(document).delegate "[data-repin-item]", 'click', preventDefault ->
    itemId = $(this).data("repinItem")

    kollectionItem = new KollectionItem
      link_url: "/api/v1/collections/items/#{itemId}"

    $dialog = $(modalSaveTemplate(ENV.current_user)).dialog
      width: 700
      resizable: false
      modal: false
      title: 'Pin To Canvas Network'

    kollectionItemSaveView = new KollectionItemSaveView
      model: kollectionItem
      el: $dialog.find('#kollectionItemSaveViewContainer')

    kollectionItem.on 'create sync', ->
      # TODO publish some info about how I was re-pinned
      $dialog.dialog('close')
