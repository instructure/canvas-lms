require [
  'jquery'
  'underscore'
  'compiled/util/deparam'
  'compiled/views/KollectionItems/KollectionItemSaveView'
  'compiled/models/KollectionItem'
], ($, _, deparam, KollectionItemSaveView, KollectionItem) ->

  # you can pass ?link_url=http://example.com&description=blahblahblah
  queryStringParams = _(deparam()).pick 'link_url', 'description'
  kollectionItem = new KollectionItem(queryStringParams)
  kollectionItemSaveView = new KollectionItemSaveView
    model: kollectionItem
    el: '#kollectionItemSaveViewContainer'

  kollectionItem.on 'create sync', ->
    kollectionItemSaveView.$el.hide()
    $('#savedSuccessfullyMessage').show()
    setTimeout(window.close, 2000) if window.opener