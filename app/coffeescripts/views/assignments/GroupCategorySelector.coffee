define [
  'i18n!assignment'
  'Backbone'
  'underscore'
  'jquery'
  'jst/assignments/GroupCategorySelector'
  'compiled/jquery/toggleAccessibly',
  'jsx/due_dates/StudentGroupStore'
], (I18n, Backbone, _, $, template, toggleAccessibly, StudentGroupStore) ->

  class GroupCategorySelector extends Backbone.View

    template: template

    GROUP_CATEGORY_ID = '#assignment_group_category_id'
    CREATE_GROUP_CATEGORY_ID = '#create_group_category_id'
    HAS_GROUP_CATEGORY = '#has_group_category'
    GROUP_CATEGORY_OPTIONS = '#group_category_options'

    els: do ->
      els = {}
      els["#{GROUP_CATEGORY_ID}"] = '$groupCategoryID'
      els["#{HAS_GROUP_CATEGORY}"] = '$hasGroupCategory'
      els["#{GROUP_CATEGORY_OPTIONS}"] = '$groupCategoryOptions'
      els

    events: do ->
      events = {}
      events[ "change #{GROUP_CATEGORY_ID}" ] = 'groupCategorySelected'
      events[ "click #{CREATE_GROUP_CATEGORY_ID}" ] = 'showGroupCategoryCreateDialog'
      events[ "change #{HAS_GROUP_CATEGORY}" ] = 'toggleGroupCategoryOptions'
      events

    @optionProperty 'parentModel'
    @optionProperty 'groupCategories'
    @optionProperty 'nested'
    @optionProperty 'hideGradeIndividually'
    @optionProperty 'sectionLabel'
    @optionProperty 'fieldLabel'
    @optionProperty 'lockedMessage'
    @optionProperty 'inClosedGradingPeriod'

    render: =>
      selectedID = @parentModel.groupCategoryId()
      if !@parentModel.canGroup() or _.isEmpty(@groupCategories)
        StudentGroupStore.setSelectedGroupSet(null)
      else if !selectedID? or !_.findWhere(@groupCategories, {id: selectedID.toString()})?
        StudentGroupStore.setSelectedGroupSet('blank')
      else
        StudentGroupStore.setSelectedGroupSet(selectedID)
      super
      @$groupCategoryID.toggleAccessibly !_.isEmpty(@groupCategories)

    groupCategorySelected: =>
      newSelectedId = @$groupCategoryID.val()
      StudentGroupStore.setSelectedGroupSet(newSelectedId)

    showGroupCategoryCreateDialog: =>
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
        @$groupCategoryID.toggleAccessibly true

    toggleGroupCategoryOptions: =>
      isGrouped = @$hasGroupCategory.prop('checked')
      @$groupCategoryOptions.toggleAccessibly isGrouped

      selectedGroupSetId = if isGrouped then @$groupCategoryID.val() else null
      StudentGroupStore.setSelectedGroupSet(selectedGroupSetId)
      if isGrouped and _.isEmpty(@groupCategories)
        @showGroupCategoryCreateDialog()

    toJSON: =>
      frozenAttributes = @parentModel.frozenAttributes?() || []
      groupCategoryFrozen = _.include frozenAttributes, 'group_category_id'
      groupCategoryLocked = !@parentModel.canGroup()

      groupCategoryId: @parentModel.groupCategoryId()
      groupCategories: @groupCategories
      originalGroupRemoved: !_.chain(@groupCategories)
                              .pluck('id')
                              .contains(@parentModel.groupCategoryId())
                              .value() && !_.isEmpty(@groupCategories)
      hideGradeIndividually: @hideGradeIndividually
      gradeGroupStudentsIndividually: !@hideGradeIndividually && @parentModel.gradeGroupStudentsIndividually()
      groupCategoryLocked: groupCategoryLocked

      hasGroupCategoryDisabled:  groupCategoryFrozen || groupCategoryLocked
      gradeIndividuallyDisabled: groupCategoryFrozen
      groupCategoryIdDisabled:   groupCategoryFrozen || groupCategoryLocked

      sectionLabel: @sectionLabel
      fieldLabel: @fieldLabel
      lockedMessage: @lockedMessage
      ariaChecked: if @parentModel.groupCategoryId() then 'true' else 'false'

      nested: @nested
      prefix: 'assignment' if @nested
      inClosedGradingPeriod: @inClosedGradingPeriod

    filterFormData: (data) =>
      hasGroupCategory = data.has_group_category
      delete data.has_group_category
      if hasGroupCategory == '0'
        data.group_category_id = null
        data.grade_group_students_individually = false
      data

    fieldSelectors: do ->
      s = {}
      s['groupCategorySelector'] = '#assignment_group_category_id'
      s['newGroupCategory'] = '#create_group_category_id'
      s

    validateBeforeSave: (data, errors) =>
      errors = @_validateGroupCategoryID data, errors
      errors

    _validateGroupCategoryID: (data, errors) =>
      gcid = if @nested
        data.assignment.groupCategoryId()
      else
        data.group_category_id
      if gcid == 'blank'
        if _.isEmpty(@groupCategories)
          errors["newGroupCategory"] = [
            message: I18n.t 'Please create a group set'
          ]
        else
          errors["groupCategorySelector"] = [
            message: I18n.t 'Please select a group set for this assignment'
          ]
      errors
