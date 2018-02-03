#
# Copyright (C) 2013 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

define [
  '../../util/round'
  'i18n!assignments'
  'jquery'
  'underscore'
  'jsx/shared/helpers/numberHelper'
  '../../models/AssignmentGroup'
  '../../collections/NeverDropCollection'
  './NeverDropCollectionView'
  '../DialogFormView'
  'jst/assignments/CreateGroup'
  'jst/EmptyDialogFormWrapper'
  '../../jquery.rails_flash_notifications'
], (round, I18n, $, _, numberHelper, AssignmentGroup, NeverDropCollection, NeverDropCollectionView, DialogFormView, template, wrapper) ->

  SHORT_HEIGHT = 250

  class CreateGroupView extends DialogFormView
    defaults:
      width: 600
      height: 500

    events: _.extend({}, @::events,
      'click .dialog_closer': 'close'
      'blur .group_weight': 'roundWeight'
    )

    els:
      '.never_drop_rules_group': '$neverDropContainer'

    template: template
    wrapperTemplate: wrapper

    @optionProperty 'assignmentGroups'
    @optionProperty 'assignmentGroup'
    @optionProperty 'course'
    @optionProperty 'userIsAdmin'

    messages:
      non_number: I18n.t('You must use a number')
      positive_number: I18n.t('You must use a positive number')
      max_number: I18n.t('You cannot use a number greater than the number of assignments')
      no_name_error: I18n.t('A name is required')
      name_too_long_error: I18n.t('Name is too long')

    initialize: ->
      super
      #@assignmentGroup will be defined when editing
      @model = @assignmentGroup or new AssignmentGroup(assignments: [])

    onSaveSuccess: ->
      super
      # meaning we are editing
      if @assignmentGroup
        # trigger instead of calling render directly
        @model.collection.trigger 'render', @model.collection
      else
        @assignmentGroups.add(@model)
        @model = new AssignmentGroup(assignments: [])

        @render()

      # we do this here because the re-render above causes the default focus
      # from DialogFormView not to stick
      setTimeout((=>
        $.flashMessage(I18n.t("Assignment group was saved successfully"))
        @focusReturnsTo()?.focus()
      ), 0)

    getFormData: ->
      data = super
      if data.rules
        delete data.rules.drop_lowest if _.contains(["", "0"], data.rules.drop_lowest)
        delete data.rules.drop_highest if _.contains(["", "0"], data.rules.drop_highest)
        delete data.rules.never_drop if data.rules.never_drop?.length == 0
      data.group_weight = round(numberHelper.parse(data.group_weight), 2)
      data

    validateFormData: (data) ->
      max = 0
      if @assignmentGroup
        as = @assignmentGroup.get('assignments')
        max = as.size() if as?
      errors = {}
      if data.name.length > 255
        errors["name"] = [{type: 'name_too_long_error', message: @messages.name_too_long_error}]
      if data.name == ""
        errors["name"] = [{type: 'no_name_error', message: @messages.no_name_error}]
      if (data.group_weight && isNaN(numberHelper.parse(data.group_weight)))
        errors["group_weight"] = [{type: 'number', message: @messages.non_number}]
      _.each data.rules, (value, name) =>
        # don't want to validate the never_drop field
        return if name is 'never_drop'
        val = Math.floor(numberHelper.parse(value))
        field = "rules[#{name}]"
        if isNaN(val)
          errors[field] = [{type: 'number', message: @messages.non_number}]
        if val < 0
          errors[field] = [{type: 'positive_number', message: @messages.positive_number}]
        if val > max
          errors[field] = [{type: 'maximum', message: @messages.max_number}]
      errors

    showWeight: ->
      course = @course or @model.collection?.course
      course?.get('apply_assignment_group_weights')

    canChangeWeighting: ->
      @userIsAdmin or not @model.anyAssignmentInClosedGradingPeriod()

    checkGroupWeight: ->
      if @showWeight() and @canChangeWeighting()
        @$el.find('.group_weight').removeAttr("readonly", "aria-disabled")
      else
        @$el.find('.group_weight').attr("readonly", "readonly").attr("aria-disabled", true)

    getNeverDrops: ->
      @$neverDropContainer.empty()
      rules = @model.rules()
      @never_drops = new NeverDropCollection [],
        assignments: @model.get('assignments')
        ag_id: @model.get('id') or 'new'

      @ndCollectionView = new NeverDropCollectionView
        canChangeDropRules: @canChangeWeighting()
        collection: @never_drops

      @$neverDropContainer.append @ndCollectionView.render().el
      if rules && rules.never_drop
        @never_drops.reset rules.never_drop,
          parse: true

    roundWeight: (e) ->
      value = $(e.target).val()
      rounded_value = round(numberHelper.parse(value), 2)
      if isNaN(rounded_value)
        return
      else
        $(e.target).val(I18n.n(rounded_value))

    toJSON: ->
      data = @model.toJSON()
      _.extend(data, {
        show_weight: @showWeight()
        can_change_weighting: @canChangeWeighting()
        group_weight: if @showWeight() then data.group_weight else null
        label_id: @model.get('id') or 'new'
        drop_lowest: @model.rules()?.drop_lowest or 0
        drop_highest: @model.rules()?.drop_highest or 0
        editable_drop: @model.get('assignments').length > 0
        #Safari is not fully compatiable with html5 validation - needs to be set to text instead to ensure our validations work
        number_input: if !!navigator.userAgent.match(/Version\/[\d\.]+.*Safari/) then "text" else "number"
      })

    openAgain: ->
      if @model.get('assignments').length == 0
        @setDimensions(this.defaults.width, SHORT_HEIGHT)

      super
      @checkGroupWeight()
      @getNeverDrops()
