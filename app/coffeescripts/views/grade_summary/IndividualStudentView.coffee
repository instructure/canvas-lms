#
# Copyright (C) 2018 - present Instructure, Inc.
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
  'Backbone'
  'react'
  'react-dom'
  'jsx/outcomes/IndividualStudentMastery'
  'jst/grade_summary/individual_student_view'
], ($, _, Backbone, React, ReactDOM, IndividualStudentMastery, template) ->

  class IndividualStudentView extends Backbone.View
    @optionProperty 'course_id'
    @optionProperty 'student_id'

    template: template

    initialize: () ->
      super
      @bindToggles()

    show: () ->
      super
      @render()
      masteryElement = React.createElement(IndividualStudentMastery, {
        courseId: @course_id,
        studentId: @student_id,
        onExpansionChange: @updateToggles,
        outcomeProficiency: ENV.outcome_proficiency
      })
      @reactView = ReactDOM.render(masteryElement, $('.individualStudentView').get(0))

    updateToggles: (anyExpanded, anyContracted) ->
      collapseToggle = $('div.outcome-toggles a.icon-collapse')
      expandToggle = $('div.outcome-toggles a.icon-expand')

      if (anyExpanded)
        collapseToggle.removeAttr('disabled')
        collapseToggle.attr('aria-disabled', 'false')
      else
        collapseToggle.attr('disabled', 'disabled')
        collapseToggle.attr('aria-disabled', 'true')

      if (anyContracted)
        expandToggle.removeAttr('disabled')
        expandToggle.attr('aria-disabled', 'false')
      else
        expandToggle.attr('disabled', 'disabled')
        expandToggle.attr('aria-disabled', 'true')

    bindToggles: () ->
      collapseToggle = $('div.outcome-toggles a.icon-collapse')
      expandToggle = $('div.outcome-toggles a.icon-expand')
      expandToggle.click((event) =>
        event.preventDefault()
        @reactView.expand()
      )
      collapseToggle.click((event) =>
        event.preventDefault()
        @reactView.contract()
      )
