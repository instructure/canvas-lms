//
// Copyright (C) 2011 - present Instructure, Inc.
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
import Backbone from 'Backbone'
import userSettings from '../userSettings'
import OutcomeSummaryCollection from '../collections/OutcomeSummaryCollection'
import OutcomeSummaryView from '../views/grade_summary/OutcomeSummaryView'
import IndividualStudentView from '../views/grade_summary/IndividualStudentView'
import GradeSummary from 'jsx/grading/GradeSummary'
import 'jqueryui/tabs'
import 'jquery.disableWhileLoading'

// Ensure the gradebook summary code has had a chance to setup all its handlers
GradeSummary.setup()

class GradebookSummaryRouter extends Backbone.Router {

  initialize() {
    if (!ENV.student_outcome_gradebook_enabled) return
    $('#content').tabs({activate: this.activate})

    const course_id = ENV.context_asset_string.replace('course_', '')
    const user_id = ENV.student_id

    if (ENV.gradebook_non_scoring_rubrics_enabled) {
      this.outcomeView = new IndividualStudentView({
        el: $('#outcomes'),
        course_id,
        student_id: user_id
      })
    } else {
      this.outcomes = new OutcomeSummaryCollection([], {course_id, user_id})
      this.outcomeView = new OutcomeSummaryView({
        el: $('#outcomes'),
        collection: this.outcomes,
        toggles: $('.outcome-toggles')
      })
    }
  }

  tab(tab, path) {
    if (tab !== 'outcomes' && tab !== 'assignments') {
      tab = userSettings.contextGet('grade_summary_tab') || 'assignments'
    }
    $(`a[href='#${tab}']`).click()
    if (tab === 'outcomes') {
      if (!this.outcomeView) return
      this.outcomeView.show(path)
      $('.outcome-toggles').show()
    } else {
      $('.outcome-toggles').hide()
    }
  }

  activate(event, ui) {
    const tab = ui.newPanel.attr('id')
    router.navigate(`#tab-${tab}`, {trigger: true})
    return userSettings.contextSet('grade_summary_tab', tab)
  }
}
GradebookSummaryRouter.prototype.routes = {
  '': 'tab',
  'tab-:route(/*path)': 'tab'
}

GradeSummary.renderSelectMenuGroup()

var router = new GradebookSummaryRouter()
Backbone.history.start()
