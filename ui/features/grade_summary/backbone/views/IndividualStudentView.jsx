//
// Copyright (C) 2018 - present Instructure, Inc.
//
// This file is part of Canvas.
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
import Backbone from '@canvas/backbone'
import React from 'react'
import ReactDOM from 'react-dom'
import IndividualStudentMastery from '@canvas/grade-summary/react/IndividualStudentMastery/index'
import template from '../../jst/individual_student_view.handlebars'

export default class IndividualStudentView extends Backbone.View {
  static initClass() {
    this.optionProperty('course_id')
    this.optionProperty('student_id')

    this.prototype.template = template
  }

  initialize() {
    super.initialize(...arguments)
    return this.bindToggles()
  }

  show() {
    super.show(...arguments)
    this.render()
    const masteryElement = (
      <IndividualStudentMastery
        courseId={this.course_id}
        studentId={this.student_id}
        onExpansionChange={this.updateToggles}
        outcomeProficiency={ENV.outcome_proficiency}
      />
    )
    return (this.reactView = ReactDOM.render(masteryElement, $('.individualStudentView').get(0)))
  }

  updateToggles(anyExpanded, anyContracted) {
    const collapseToggle = $('div.outcome-toggles a.icon-collapse')
    const expandToggle = $('div.outcome-toggles a.icon-expand')

    if (anyExpanded) {
      collapseToggle.removeAttr('disabled')
      collapseToggle.attr('aria-disabled', 'false')
    } else {
      // disabled attribute on <a> is invalid per the HTML spec
      collapseToggle.attr('disabled', 'disabled')
      collapseToggle.attr('aria-disabled', 'true')
    }

    if (anyContracted) {
      expandToggle.removeAttr('disabled')
      return expandToggle.attr('aria-disabled', 'false')
    } else {
      // disabled attribute on <a> is invalid per the HTML spec
      expandToggle.attr('disabled', 'disabled')
      return expandToggle.attr('aria-disabled', 'true')
    }
  }

  bindToggles() {
    const collapseToggle = $('div.outcome-toggles a.icon-collapse')
    const expandToggle = $('div.outcome-toggles a.icon-expand')
    expandToggle.click(event => {
      event.preventDefault()
      return this.reactView.expand()
    })
    return collapseToggle.click(event => {
      event.preventDefault()
      return this.reactView.contract()
    })
  }
}
IndividualStudentView.initClass()
