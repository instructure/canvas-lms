// Copyright (C) 2013 - present Instructure, Inc.
//
// AssignmentGroupWeightsView file is part of Canvas.
//
// Canvas is free software: you can redistribute it and/or modify it under
// the terms of the GNU Affero General Public License as published by the Free
// Software Foundation, version 3 of the License.
//
// Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
// A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
// details.
//
// You should have received a copy of the GNU Affero General Public License along
// with this program. If not, see <http://www.gnu.org/licenses/>.

import $ from 'jquery'
import I18n from '@canvas/i18n'
import round from '@canvas/round'
import Backbone from '@canvas/backbone'
import AssignmentGroupWeightsTemplate from '../../jst/AssignmentGroupWeights.handlebars'
import numberHelper from '@canvas/i18n/numberHelper'

class AssignmentGroupWeightsView extends Backbone.View {
  roundWeight(e) {
    const value = $(e.target).val()
    const rounded_value = round(numberHelper.parse(value), 2)
    if (!Number.isNaN(Number(rounded_value))) {
      return $(e.target).val(I18n.n(rounded_value))
    }
  }

  findWeight() {
    return round(numberHelper.parse(this.$el.find('.group_weight_value').val()), 2)
  }

  toJSON() {
    const data = super.toJSON(...arguments)
    data.canChangeWeights = this.canChangeWeights
    return data
  }
}

AssignmentGroupWeightsView.prototype.template = AssignmentGroupWeightsTemplate
AssignmentGroupWeightsView.prototype.tagName = 'tr'
AssignmentGroupWeightsView.prototype.className = 'ag-weights-tr'
AssignmentGroupWeightsView.optionProperty('canChangeWeights')
AssignmentGroupWeightsView.prototype.events = {'blur .group_weight_value': 'roundWeight'}

export default AssignmentGroupWeightsView
