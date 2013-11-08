define [
  'compiled/collections/WikiPageCollection'
  'compiled/views/wiki/WikiPageIndexView'
  'jquery'
  'jquery.disableWhileLoading'
], (WikiPageCollection,WikiPageIndexView,$) ->

  module 'WikiPageIndexView:sort',
    setup: ->
      @collection = new WikiPageCollection
      @view = new WikiPageIndexView
        collection: @collection

      @$a = $('<a/>')
      @$a.data 'sort-field', 'created_at'

      @ev = $.Event('click')
      @ev.currentTarget = @$a.get(0)

  test 'sort delegates to the collection sortByField', ->
    sortByFieldStub = sinon.stub(@collection, 'sortByField')

    @view.sort(@ev)
    ok sortByFieldStub.calledOnce, 'collection sortByField called once'

  test 'view disabled while sorting', ->
    dfd = $.Deferred()
    fetchStub = sinon.stub(@collection, 'fetch').returns(dfd)
    disableWhileLoadingStub = sinon.stub(@view.$el, 'disableWhileLoading')

    @view.sort(@ev)
    ok disableWhileLoadingStub.calledOnce, 'disableWhileLoading called once'
    ok disableWhileLoadingStub.calledWith(dfd), 'disableWhileLoading called with correct deferred object'

  test 'view disabled while sorting again', ->
    dfd = $.Deferred()
    fetchStub = sinon.stub(@collection, 'fetch').returns(dfd)
    disableWhileLoadingStub = sinon.stub(@view.$el, 'disableWhileLoading')

    @view.sort(@ev)
    ok disableWhileLoadingStub.calledOnce, 'disableWhileLoading called once'
    ok disableWhileLoadingStub.calledWith(dfd), 'disableWhileLoading called with correct deferred object'

  test 'renderSortHeaders called when sorting changes', ->
    renderSortHeadersStub = sinon.stub(@view, 'renderSortHeaders')

    @collection.trigger('sortChanged', 'created_at')
    ok renderSortHeadersStub.calledOnce, 'renderSortHeaders called once'
    equal @view.currentSortField, 'created_at', 'currentSortField set correctly'


  module 'WikiPageIndexView:JSON'

  testRights = (subject, options) ->
    test "#{subject}", ->
      collection = new WikiPageCollection
      view = new WikiPageIndexView
        collection: collection
        contextAssetString: options.contextAssetString
        WIKI_RIGHTS: options.WIKI_RIGHTS
      json = view.toJSON()
      for key of options.CAN
        strictEqual json.CAN[key], options.CAN[key], "CAN.#{key}"

  testRights 'CAN (manage course)',
    contextAssetString: 'course_73'
    WIKI_RIGHTS:
      read: true
      create_page: true
      manage: true
    CAN:
      CREATE: true
      MANAGE: true
      PUBLISH: true

  testRights 'CAN (manage group)',
    contextAssetString: 'group_73'
    WIKI_RIGHTS:
      read: true
      create_page: true
      manage: true
    CAN:
      CREATE: true
      MANAGE: true
      PUBLISH: false

  testRights 'CAN (read)',
    contextAssetString: 'course_73'
    WIKI_RIGHTS:
      read: true
    CAN:
      CREATE: false
      MANAGE: false
      PUBLISH: false

  testRights 'CAN (null)',
    CAN:
      CREATE: false
      MANAGE: false
      PUBLISH: false
