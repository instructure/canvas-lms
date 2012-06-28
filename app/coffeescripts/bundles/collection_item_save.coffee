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

  # TODO: do something more useful once it's been created
  kollectionItem.on 'create sync', ->
    $('#savedSuccessfullyMessage').show()
    $('.popup-container .image-block').remove()
    setTimeout(window.close, 2000) if window.opener