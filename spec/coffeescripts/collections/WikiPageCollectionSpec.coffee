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

  module 'WikiPageCollection:sorting',
    setup: ->
      @collection = new WikiPageCollection

  test 'default sort is title', ->
    equal @collection.currentSortField, 'title', 'default sort set correctly'

  test 'default sort orders', ->
    equal @collection.sortOrders['title'], 'asc', 'default title sort order'
    equal @collection.sortOrders['created_at'], 'desc', 'default created_at sort order'
    equal @collection.sortOrders['updated_at'], 'desc', 'default updated_at sort order'

  test 'sort order toggles (sort on same field)', ->
    @collection.currentSortField = 'created_at'
    @collection.sortOrders['created_at'] = 'desc'
    @collection.setSortField('created_at')
    equal @collection.sortOrders['created_at'], 'asc', 'sort order toggled'

  test 'sort order does not toggle (sort on different field)', ->
    @collection.currentSortField = 'title'
    @collection.sortOrders['created_at'] = 'desc'
    @collection.setSortField('created_at')
    equal @collection.sortOrders['created_at'], 'desc', 'sort order remains'

  test 'sort order can be forced', ->
    @collection.currentSortField = 'title'
    @collection.setSortField('created_at', 'asc')
    equal @collection.currentSortField, 'created_at', 'sort field set'
    equal @collection.sortOrders['created_at'], 'asc', 'sort order forced'
    @collection.setSortField('created_at', 'asc')
    equal @collection.currentSortField, 'created_at', 'sort field remains'
    equal @collection.sortOrders['created_at'], 'asc', 'sort order remains'

  test 'setting sort triggers a sortChanged event', ->
    sortChangedSpy = @spy()
    @collection.on 'sortChanged', sortChangedSpy
    @collection.setSortField 'created_at'
    ok sortChangedSpy.calledOnce, 'sortChanged event triggered once'
    ok sortChangedSpy.calledWith(@collection.currentSortField, @collection.sortOrders), 'sortChanged triggered with parameters'

  test 'setting sort sets fetch parameters', ->
    @collection.setSortField('created_at', 'desc')
    ok @collection.options, 'options exists'
    ok @collection.options.params, 'params exists'
    equal @collection.options.params.sort, 'created_at', 'sort param set'
    equal @collection.options.params.order, 'desc', 'order param set'

  test 'sortByField delegates to setSortField', ->
    setSortFieldStub = @stub(@collection, 'setSortField')
    fetchStub = @stub(@collection, 'fetch')

    @collection.sortByField('created_at', 'desc')
    ok setSortFieldStub.calledOnce, 'setSortField called once'
    ok setSortFieldStub.calledWith('created_at', 'desc'), 'setSortField called with correct arguments'

  test 'sortByField triggers a fetch', ->
    fetchStub = @stub(@collection, 'fetch')

    @collection.sortByField('created_at', 'desc')
    ok fetchStub.calledOnce, 'fetch called once'
