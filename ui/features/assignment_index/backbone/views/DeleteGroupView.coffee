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

import I18n from 'i18n!DeleteGroupView'
import $ from 'jquery'
import _ from 'underscore'
import DialogFormView from '@canvas/forms/backbone/views/DialogFormView.coffee'
import template from '../../jst/DeleteGroup.handlebars'
import wrapper from '@canvas/forms/jst/EmptyDialogFormWrapper.handlebars'
import '@canvas/jquery/jquery.disableWhileLoading'
import {shimGetterShorthand} from '@canvas/util/legacyCoffeesScriptHelpers'

export default class DeleteGroupView extends DialogFormView
  defaults: shimGetterShorthand
    width: 500
    height: 350
  ,
    title: -> I18n.t('Delete Assignment Group')

  els:
    '.assignment_count': '$assignmentCount'
    '.group_select': '$groupSelect'

  events: _.extend({}, @::events,
    'click .dialog_closer': 'close'
    'change .group_select': 'selectMove'
  )

  template: template
  wrapperTemplate: wrapper

  initialize: ->
    super
    @model.get('assignments').on 'add remove', @updateAssignmentCount
    @model.collection.on 'add', @addToGroupOptions
    @model.collection.on 'remove', @removeFromGroupOptions

  toJSON: ->
    data = super
    groups = @model.collection.reject (model) =>
      model.get('id') == @model.get('id')
    groups_json = groups.map (model) ->
      model.toJSON()

    _.extend(data, {
      assignment_count: @model.get('assignments').length
      groups: groups_json
      label_id: data.id
    })

  updateAssignmentCount: =>
    @$assignmentCount.text(@model.get('assignments').length)

  addToGroupOptions: (model) =>
    id = model.get('id')
    $opt = $('<option>')
    $opt.val(id)
    $opt.addClass("ag_#{id}")
    $opt.text(model.get('name'))
    @$groupSelect.append $opt

  removeFromGroupOptions: (model) =>
    id = model.get('id')
    @$groupSelect.find("move_to_ag_#{id}").remove()

  validateFormData: (data) ->
    errors = {}
    if data.action == "move" && !data.move_assignments_to
      errors.move_assignments_to = [
        type: 'required'
        message: I18n.t('You must select an assignment group.')
      ]
    errors

  saveFormData: (data) ->
    if data.action == "move" && data.move_assignments_to
      @destroyModel(data.move_assignments_to)
    else if data.action == "delete"
      @destroyModel()

  destroyModel: (moveTo=null) ->
    @collection = @model.collection
    data = if moveTo then "move_assignments_to=#{moveTo}" else ''
    destroyDfd = @model.destroy(data: data, wait: true)
    destroyDfd.then =>
      @collection.fetch(reset: true) if moveTo
    @$el.disableWhileLoading destroyDfd
    destroyDfd

  selectMove: ->
    if !@$el.find(".group_select :selected").hasClass("blank")
      @$el.find('.assignment_group_move').prop('checked', true)

  openAgain: ->
    # make sure there is more than one assignment group
    if @model.collection.models.length > 1
      # check if it has assignments
      if @model.get('assignments').length > 0
        super
      else
        # no assignments, so just confirm
        if confirm I18n.t('confirm_delete_group', "Are you sure you want to delete this Assignment Group?")
          @destroyModel()
    else
      # last assignment group, so alert, but don't destroy
      alert I18n.t('cannot_delete_group', "You must have at least one Assignment Group")
