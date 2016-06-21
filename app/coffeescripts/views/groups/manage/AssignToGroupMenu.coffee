define [
  'compiled/views/groups/manage/PopoverMenuView'
  'compiled/views/groups/manage/GroupCategoryCloneView'
  'compiled/models/GroupUser'
  'jst/groups/manage/assignToGroupMenu'
  'jquery'
  'underscore'
  'compiled/jquery/outerclick'
], (PopoverMenuView, GroupCategoryCloneView, GroupUser, template, $, _) ->

  class AssignToGroupMenu extends PopoverMenuView

    defaults: _.extend {},
      PopoverMenuView::defaults,
      zIndex: 10

    events: _.extend {},
      PopoverMenuView::events,
      'click .set-group': 'setGroup'
      'focusin .focus-bound': "boundFocused"

    attach: ->
      @collection.on 'change add remove reset', @render

    tagName: 'div'

    className: 'assign-to-group-menu ui-tooltip popover content-top horizontal'

    template: template

    setGroup: (e) ->
      e.preventDefault()
      e.stopPropagation()
      newGroupId = $(e.currentTarget).data('group-id')
      userId = @model.id

      if @collection.get(newGroupId).get("has_submission")
        @cloneCategoryView = new GroupCategoryCloneView
            model: @model.collection.category
            openedFromCaution: true
        @cloneCategoryView.open()
        @cloneCategoryView.on "close", =>
            if @cloneCategoryView.cloneSuccess
              window.location.reload()
            else if @cloneCategoryView.changeGroups
              @moveUser(newGroupId)
            else
              $("[data-user-id='#{userId}']").focus()
              @hide()
      else
        @moveUser(newGroupId)

    moveUser: (newGroupId) ->
      @collection.category.reassignUser(@model, @collection.get(newGroupId))
      @$el.detach()
      @trigger("close", {"userMoved": true })

    toJSON: ->
      hasGroups = @collection.length > 0
      {
        groups: @collection.toJSON()
        noGroups: !hasGroups
        allFull: hasGroups and @collection.models.every (g) -> g.isFull()
      }

    attachElement: ->
      $('body').append(@$el)

    focus: ->
      noGroupsToJoin = @collection.length <= 0 or @collection.models.every (g) -> g.isFull()
      toFocus = if noGroupsToJoin then ".popover-content p" else "li a" #focus text if no groups, focus first group if groups
      @$el.find(toFocus).first().focus()

    boundFocused: ->
      #force hide and pretend we pressed escape
      @$el.detach()
      @trigger("close", {"escapePressed": true })
