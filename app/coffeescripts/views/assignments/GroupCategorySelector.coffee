define [
  'i18n!assignment'
  'Backbone'
  'underscore'
  'jquery'
  'jst/assignments/GroupCategorySelector'
  'compiled/jquery/toggleAccessibly'
], (I18n, Backbone, _, $, template, toggleAccessibly) ->

  class GroupCategorySelector extends Backbone.View

    template: template

    GROUP_CATEGORY_ID = '#assignment_group_category_id'
    HAS_GROUP_CATEGORY = '#assignment_has_group_category'
    GROUP_CATEGORY_OPTIONS = '#group_category_options'

    els: do ->
      els = {}
      els["#{GROUP_CATEGORY_ID}"] = '$groupCategoryID'
      els["#{HAS_GROUP_CATEGORY}"] = '$hasGroupCategory'
      els["#{GROUP_CATEGORY_OPTIONS}"] = '$groupCategoryOptions'
      els

    events: do ->
      events = {}
      events[ "change #{GROUP_CATEGORY_ID}" ] = 'showGroupCategoryCreateDialog'
      events[ "change #{HAS_GROUP_CATEGORY}" ] = 'toggleGroupCategoryOptions'
      events

    @optionProperty 'parentModel'
    @optionProperty 'groupCategories'
    @optionProperty 'nested'

    initialize: ->
      super

      # delete this after Ifa654f7d853fd167d5bfbaee6184657209d58272 hits prod
      gc.id = gc.id.toString() for gc in @groupCategories

    showGroupCategoryCreateDialog: =>
      if @$groupCategoryID.val() == 'new'
        # TODO: Yikes, we need to pull the javascript out of manage_groups.js
        # and get rid of this global thing 
        window.addGroupCategory (data) =>
          group = data[0].group_category
          $newCategory = $('<option>')
          $newCategory.val(group.id)
          $newCategory.text(group.name)
          @$groupCategoryID.prepend $newCategory
          @$groupCategoryID.val(group.id)
          @groupCategories.push(group)

    toggleGroupCategoryOptions: =>
      @$groupCategoryOptions.toggleAccessibly @$hasGroupCategory.prop('checked')

      if @$hasGroupCategory.prop('checked') and @groupCategories.length == 0
        @showGroupCategoryCreateDialog()

    toJSON: =>
      frozenAttributes = @parentModel.frozenAttributes()
      groupCategoryFrozen = _.include frozenAttributes, 'group_category_id'
      groupCategoryLocked = @parentModel.attributes.has_submitted_submissions

      groupCategoryId: @parentModel.groupCategoryId()
      groupCategories: @groupCategories
      gradeGroupStudentsIndividually: @parentModel.gradeGroupStudentsIndividually()
      groupCategoryLocked: groupCategoryLocked

      hasGroupCategoryDisabled:  groupCategoryFrozen || groupCategoryLocked
      gradeIndividuallyDisabled: groupCategoryFrozen
      groupCategoryIdDisabled:   groupCategoryFrozen || groupCategoryLocked

      nested: @nested
      prefix: 'assignment' if @nested

    filterFormData: (data) =>
      hasGroupCategory = data.has_group_category
      delete data.has_group_category
      if hasGroupCategory == '0'
        data.group_category_id = null
        data.grade_group_students_individually = false
      data

    fieldSelectors:
      groupCategorySelector: '#assignment_group_category_id'

    validateBeforeSave: (data, errors) =>
      errors = @_validateGroupCategoryID data, errors
      errors

    _validateGroupCategoryID: (data, errors) =>
      gcid = if @nested
        data.assignment.groupCategoryId()
      else
        data.group_category_id

      if gcid == 'new'
        errors["groupCategorySelector"] = [
          message: I18n.t 'group_assignment_must_have_group_set', 'Please select a group set for this assignment'
        ]
      errors
