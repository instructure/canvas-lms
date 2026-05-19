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
import React from 'react'
import {render, rerender} from '@canvas/react'
import I18n from '@canvas/i18n'
import round from '@canvas/round'
import Backbone from '@canvas/backbone'
import AssignmentGroupWeightsTemplate from '../../jst/AssignmentGroupWeights.handlebars'
import numberHelper from '@canvas/i18n/numberHelper'
import GroupWeightInput from '../../react/GroupWeightInput'

class AssignmentGroupWeightsView extends Backbone.View {
  initialize() {
    this.weightInputRoot = null
    super.initialize(...arguments)
  }

  findWeight() {
    const input = document.getElementById(`ag_${this.model.get('id')}_weight_input`)
    return round(
      numberHelper.parse(document.getElementById(`ag_${this.model.get('id')}_weight_input`).value),
      2,
    )
  }

  toJSON() {
    const data = super.toJSON(...arguments)
    data.canChangeWeights = this.canChangeWeights
    return data
  }

  afterRender() {
    setTimeout(() => {
      const groupId = this.model.get('id')
      const mount = document.getElementById(`assignment_group_${groupId}_weight_input`)
      const element = (
        <GroupWeightInput
          groupId={groupId}
          name={this.model.attributes.name}
          canChangeWeights={this.canChangeWeights}
          initialValue={this.model.attributes.group_weight}
        />
      )
      if (!this.weightInputRoot) {
        this.weightInputRoot = render(element, mount)
      } else {
        rerender(this.weightInputRoot, element)
      }
    }, 0)
  }
}

AssignmentGroupWeightsView.prototype.template = AssignmentGroupWeightsTemplate
AssignmentGroupWeightsView.prototype.tagName = 'tr'
AssignmentGroupWeightsView.prototype.className = 'ag-weights-tr'
AssignmentGroupWeightsView.optionProperty('canChangeWeights')

export default AssignmentGroupWeightsView
