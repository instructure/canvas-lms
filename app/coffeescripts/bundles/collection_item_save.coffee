require [
  'underscore'
  'compiled/util/deparam'
  'compiled/views/KollectionItems/KollectionItemSaveView'
  'compiled/models/KollectionItem'
], (_, deparam, KollectionItemSaveView, KollectionItem) ->
  $ ->
    # you can pass ?link_url=http://example.com&description=blahblahblah
    queryStringParams = _(deparam()).pick 'link_url', 'description'
    queryStringParams.user_id = ENV.current_user_id
    window.kollectionItem = kollectionItem = new KollectionItem(queryStringParams)
    new KollectionItemSaveView(model: kollectionItem)

    if window.opener
      kollectionItem.on 'create sync', ->
        setTimeout window.close, 2000