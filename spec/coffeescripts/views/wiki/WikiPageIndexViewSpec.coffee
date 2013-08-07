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
