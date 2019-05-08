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

import Backbone from 'Backbone'
import _ from 'underscore'
import I18n from 'i18n!assignmentsNeverDrop'
import neverDropTemplate from 'jst/assignments/NeverDrop'

export default class NeverDrop extends Backbone.View
  className: 'never_drop_rule'
  template: neverDropTemplate

  @optionProperty 'canChangeDropRules'

  events:
    'change select': 'setChosen'
    'click .remove_never_drop': 'removeNeverDrop'

  # change the `chosen_id` on a model
  # and mark it for focusing when we re-render
  # the collection
  setChosen: (e) ->
    if @canChangeDropRules
      $target = @$(e.currentTarget)
      @model.set
        'chosen_id': $target.val()
        'focus': true

  removeNeverDrop: (e) ->
    e.preventDefault()
    if @canChangeDropRules
      @model.collection.remove @model

  #after render we want to check and see if we should focus
  #this select
  afterRender: ->
    if @model.has('focus')
      _.defer(=>
        @$('select').focus()
        @model.unset 'focus'
      )

  toJSON: =>
    json = super
    json.canChangeDropRules = @canChangeDropRules
    json.buttonTitle = I18n.t('remove_unsaved_never_drop_rule', "Remove unsaved never drop rule")
    if @model.has('chosen_id')
      json.assignments = @model.collection.toAssignments(@model.get('chosen_id'))
    if json.chosen
      json.buttonTitle = I18n.t('remove_never_drop_rule', "Remove never drop rule") + " #{json.chosen}"
    json
