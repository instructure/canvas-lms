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
  'jquery'
  '../../util/round'
  'Backbone'
  'jst/assignments/AssignmentGroupWeights'
  'jsx/shared/helpers/numberHelper'
], ($, round, Backbone, AssignmentGroupWeightsTemplate, numberHelper) ->

  class AssignmentGroupWeightsView extends Backbone.View
    template: AssignmentGroupWeightsTemplate
    tagName: 'tr'
    className: 'ag-weights-tr'

    @optionProperty 'canChangeWeights'

    events:
      'blur .group_weight_value' : 'roundWeight'

    roundWeight: (e) ->
      value = $(e.target).val()
      rounded_value = round(numberHelper.parse(value), 2)
      if isNaN(rounded_value)
        return
      else
        $(e.target).val(I18n.n(rounded_value))

    findWeight: ->
      round(numberHelper.parse(@$el.find('.group_weight_value').val()), 2)

    toJSON: ->
      data = super
      data.canChangeWeights = @canChangeWeights
      data
