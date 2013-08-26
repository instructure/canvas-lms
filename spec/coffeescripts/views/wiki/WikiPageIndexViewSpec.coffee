define [
  'compiled/collections/WikiPageCollection'
  'compiled/views/wiki/WikiPageIndexView'
  'jquery'
  'jquery.disableWhileLoading'
], (WikiPageCollection,WikiPageIndexView,$) ->
  module 'WikiPageIndexView:sort',
    setup: ->
      @collection = new WikiPageCollection null,
        contextAssetString: 'course_1'
      @view = new WikiPageIndexView
        collection: @collection

      @a = $('<a>')
      @a.data 'sort-field', 'created_at'
      @a.data 'sort-order', 'desc'
    
      @e = jQuery.Event "click"
      @e.currentTarget = @a.get(0)

  test 'sort param changes based on sort data field', ->
    @view.sort @e
    equal @collection.options.params?.sort, 'created_at'
    equal @collection.options.params?.order, 'desc'

  # overkill, but for instructional value
  test 'calls disableWhileLoading while sorting', ->
    dfd = $.Deferred()
    dfdStub = sinon.stub(@collection, 'fetch').returns(dfd)

    disableWhileLoadingStub = sinon.stub(@view.$el, 'disableWhileLoading')
    @view.sort @e
    ok disableWhileLoadingStub.calledWith(dfd), "Calls disableWhileLoading on el once"
    disableWhileLoadingStub.restore()
    dfdStub.restore()


  module 'WikiPageIndexView:JSON'

  test 'WIKI_RIGHTS', ->
    collection = new WikiPageCollection
    view = new WikiPageIndexView
      collection: collection
      WIKI_RIGHTS:
        good: true
    strictEqual view.toJSON().WIKI_RIGHTS.good, true, 'WIKI_RIGHTS represented in toJSON'

  test 'contextName', ->
    collection = new WikiPageCollection
    view = new WikiPageIndexView
      collection: collection
      contextAssetString: 'group_73'
    strictEqual view.toJSON().contextName, 'groups', 'contextName represented in toJSON'
