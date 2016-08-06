define [
  'i18n!groups'
  'jquery'
  'underscore'
  'compiled/views/groups/manage/GroupUsersView'
  'compiled/views/groups/manage/AssignToGroupMenu'
  'compiled/views/groups/manage/Scrollable'
  'compiled/views/groups/manage/GroupCategoryCloneView'
  'jst/groups/manage/groupUsers'
], (I18n, $, _, GroupUsersView, AssignToGroupMenu, Scrollable, GroupCategoryCloneView, template) ->

  class UnassignedUsersView extends GroupUsersView

    @optionProperty 'groupsCollection'
    @optionProperty 'category'

    defaults: _.extend {},
      GroupUsersView::defaults,
      autoFetch: true # load until below the viewport, don't wait for the user to scroll
      itemViewOptions:
        canAssignToGroup: true
        canEditGroupAssignment: false

    els: _.extend {},
      GroupUsersView::els,
      '.no-results-wrapper': '$noResultsWrapper'
      '.no-results': '$noResults'
      '.invalid-filter': '$invalidFilter'

    @mixin Scrollable

    elementIndex: -1
    fromAddButton: false

    dropOptions:
      accept: '.group-user'
      activeClass: 'droppable'
      hoverClass: 'droppable-hover'
      tolerance: 'pointer'

    attach: ->
      @collection.on 'reset', @render
      @collection.on 'remove', @render
      @collection.on 'moved', @highlightUser
      @on 'renderedItems', @realAfterRender

      @collection.once 'fetch', => @$noResultsWrapper.hide()
      @collection.on 'fetched:last', => @$noResultsWrapper.show()

    afterRender: ->
      super
      @collection.load('first')
      @$el.parent().droppable(_.extend({}, @dropOptions)).unbind('drop')
                   .on('drop', @_onDrop)
      @scrollContainer = @heightContainer = @$el
      @$scrollableElement = @$el.find("ul")

    realAfterRender: =>
      listElements = $("ul.collectionViewItems li.group-user", @$el)
      if @elementIndex > -1 and listElements.length > 0
        focusElement = $(listElements[@elementIndex] || listElements[listElements.length - 1])
        focusElement.find("a.assign-to-group").focus()

    toJSON: ->
      loading: !@collection.loadedAll
      count: @collection.length
      ENV: ENV

    remove: ->
      @assignToGroupMenu?.remove()
      super

    events:
      'click .assign-to-group': 'focusAssignToGroup'
      'focus .assign-to-group': 'showAssignToGroup'
      'blur .assign-to-group':  'hideAssignToGroup'
      'scroll':                 'hideAssignToGroup'

    focusAssignToGroup: (e) ->
      e.preventDefault()
      e.stopPropagation()
      $target = $(e.currentTarget)
      @fromAddButton = true
      assignToGroupMenu = @_getAssignToGroup()
      assignToGroupMenu.model = @collection.get($target.data('user-id'))
      assignToGroupMenu.showBy($target, true)

    showAssignToGroup: (e) ->
      if @elementIndex == -1
        e.preventDefault()
        e.stopPropagation()
      $target = $(e.currentTarget)

      assignToGroupMenu = @_getAssignToGroup()
      assignToGroupMenu.model = @collection.get($target.data('user-id'))
      assignToGroupMenu.showBy($target)


    _getAssignToGroup: ->
      if(!@assignToGroupMenu)
        @assignToGroupMenu = new AssignToGroupMenu collection: @groupsCollection
        @assignToGroupMenu.on("open", (options) =>
          @elementIndex = Array.prototype.indexOf.apply($("ul.collectionViewItems li.group-user", @$el), $(options.target).parent("li"))
        )
        @assignToGroupMenu.on("close", (options) =>
          studentElements = $("li.group-user a.assign-to-group", @$el)
          if @elementIndex != -1
            if studentElements.length == 0
              $('.filterable-unassigned-users').focus()
            else if options.escapePressed
              $(studentElements[@elementIndex] || studentElements[studentElements.length - 1]).focus()
            else if options.userMoved
              if @elementIndex == 0
                $('.filterable-unassigned-users').focus()
              else
                $(studentElements[@elementIndex - 1] || studentElements[studentElements.length - 1]).focus()
            @elementIndex = -1
        )
      return @assignToGroupMenu

    hideAssignToGroup: (e) ->
      if !@fromAddButton
        @assignToGroupMenu?.hide()
        setTimeout => # Element with next focus will not get focus until _after_ 'focusout' and 'blur' have been called.
          @elementIndex = -1 if !@$el.find("a.assign-to-group").is(":focus")
        , 100
      @fromAddButton = false

    setFilter: (search_term, options) ->
      searchDefer = @collection.search(search_term, options)
      searchDefer.always(=>
        if search_term.length < 3
          shouldShow = search_term.length > 0
          @$invalidFilter.toggleClass("hidden", !shouldShow)
          @$noResultsWrapper.toggle(shouldShow)
      ) if searchDefer

    canAssignToGroup: ->
      @options.canAssignToGroup and @groupsCollection.length

    ##
    # handle drop events on '.unassigned-students'
    # ui.draggable: the user being dragged
    _onDrop: (e, ui) =>
      user = ui.draggable.data('model')

      if user.has('group') and user.get('group').get("has_submission")
        @cloneCategoryView = new GroupCategoryCloneView
          model: @collection.category
          openedFromCaution: true
        @cloneCategoryView.open()
        @cloneCategoryView.on "close", =>
            if @cloneCategoryView.cloneSuccess
              window.location.reload()
            else if @cloneCategoryView.changeGroups
              @moveUser(user)
      else
        @moveUser(user)

    moveUser: (user) ->
      setTimeout =>
        @category.reassignUser(user, null)

    _initDrag: (view) ->
      super
      view.$el.on 'dragstart', (event, ui) =>
        @elementIndex = -1
