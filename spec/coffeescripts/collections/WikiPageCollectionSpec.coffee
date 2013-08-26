define [
  'compiled/models/WikiPage'
  'compiled/collections/WikiPageCollection'
], (WikiPage, WikiPageCollection) ->

  module 'WikiPageCollection'

  checkFrontPage = (collection) ->
    total = collection.reduce ((i, model) -> i += if model.get('front_page') then 1 else 0), 0
    total <= 1

  test 'only a single front_page per collection', ->
    collection = new WikiPageCollection
    for i in [0..2]
      collection.add new WikiPage

    ok checkFrontPage(collection), 'initial state'

    collection.models[0].set('front_page', true)
    ok checkFrontPage(collection), 'set front_page once'

    collection.models[1].set('front_page', true)
    ok checkFrontPage(collection), 'set front_page twice'

    collection.models[2].set('front_page', true)
    ok checkFrontPage(collection), 'set front_page thrice'
