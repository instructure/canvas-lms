//
// Copyright (C) 2017 - present Instructure, Inc.
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

import App from './config/app'
import routes from './config/routes'
import AssignmentSubtotalGradesComponent from './components/assignment_subtotal_grades_component'
import AssignmentMuterComponent from './components/assignment_muter_component'
import CustomColumnCellComponent from './components/custom_column_cell_component'
import FastSelectComponent from './components/fast_select_component'
import FinalGradeComponent from './components/final_grade_component'
import FinalGradeOverrideComponent from './components/final_grade_override_component'
import GradingCellComponent from './components/grading_cell_component'
import ScreenreaderGradebookController from './controllers/screenreader_gradebook_controller'
import ScreenreaderGradebookRoute from './routes/screenreader_gradebook_route'
import AssignmentsView from './views/assignments_view'
import LearningMasteryView from './views/learning_mastery_view'
import ScreenreaderGradebookView from './views/screenreader_gradebook_view'
import SelectionButtonsView from './views/selection_buttons_view'
import '../jst/aria_announcer.hbs'
import '../jst/assignment_information/actions.hbs'
import '../jst/assignment_information/details.hbs'
import '../jst/assignment_information/index.hbs'
import '../jst/assignments.hbs'
import '../jst/components/assignment-subtotal-grades.hbs'
import '../jst/components/custom-column-cell.hbs'
import '../jst/components/final-grade.hbs'
import '../jst/components/final-grade-override.hbs'
import '../jst/components/grading-cell.hbs'
import '../jst/content_selection/assignment.hbs'
import '../jst/content_selection/header.hbs'
import '../jst/content_selection/outcome.hbs'
import '../jst/content_selection/selection_buttons.hbs'
import '../jst/content_selection/student.hbs'
import '../jst/gradebookHeader.hbs'
import '../jst/grading.hbs'
import '../jst/learning_mastery.hbs'
import '../jst/outcome_information.hbs'
import '../jst/screenreader_gradebook.hbs'
import '../jst/settings/assignment_toggles_and_actions.hbs'
import '../jst/settings/grading_period_select.hbs'
import '../jst/settings/header.hbs'
import '../jst/settings/mastery_toggles_and_actions.hbs'
import '../jst/settings/section_select.hbs'
import '../jst/settings/sort_select.hbs'
import '../jst/student_information/assignment_subtotals.hbs'
import '../jst/student_information/details.hbs'
import '../jst/student_information/index.hbs'

App.initializer({
  name: 'routes',
  initialize(container, application) {
    return application.Router.map(routes)
  },
})

export default App.reopen({
  AssignmentSubtotalGradesComponent,
  AssignmentMuterComponent,
  CustomColumnCellComponent,
  FastSelectComponent,
  FinalGradeComponent,
  FinalGradeOverrideComponent,
  GradingCellComponent,
  ScreenreaderGradebookController,
  ScreenreaderGradebookRoute,
  AssignmentsView,
  LearningMasteryView,
  ScreenreaderGradebookView,
  SelectionButtonsView,
})
