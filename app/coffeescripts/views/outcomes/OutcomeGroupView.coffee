#
# Copyright (C) 2012 - present Instructure, Inc.
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
  'jquery'
  'underscore'
  './OutcomeContentBase'
  'jst/outcomes/outcomeGroup'
  'jst/outcomes/outcomeGroupForm'
], ($, _, OutcomeContentBase, outcomeGroupTemplate, outcomeGroupFormTemplate) ->

  # For outcome groups
  class OutcomeGroupView extends OutcomeContentBase

    render: ->
      data = @model.toJSON()
      switch @state
        when 'edit', 'add'
          @$el.html outcomeGroupFormTemplate data
          @readyForm()
        when 'loading'
          @$el.empty()
        else # show
          canManage = !@readOnly() && @model.get 'can_edit'
          @$el.html outcomeGroupTemplate _.extend data, canManage: canManage
      @$('input:first').focus()
      this