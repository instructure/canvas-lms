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

import Ember from 'ember'
import App from './config/app'
import routes from './config/routes'
import AssignmentSubtotalGradesComponent from './components/assignment_subtotal_grades_component'
import AssignmentMuterComponent from './components/assignment_muter_component'
import CustomColumnCellComponent from './components/custom_column_cell_component'
import FastSelectComponent from './components/fast_select_component'
import FinalGradeComponent from './components/final_grade_component'
import GradingCellComponent from './components/grading_cell_component'
import ScreenreaderGradebookController from './controllers/screenreader_gradebook_controller'
import ScreenreaderGradebookRoute from './routes/screenreader_gradebook_route'
import AssignmentsView from './views/assignments_view'
import LearningMasteryView from './views/learning_mastery_view'
import ScreenreaderGradebookView from './views/screenreader_gradebook_view'
import SelectionButtonsView from './views/selection_buttons_view'
import './templates/aria_announcer'
import './templates/assignment_information/actions'
import './templates/assignment_information/details'
import './templates/assignment_information/index'
import './templates/assignments'
import './templates/components/assignment-subtotal-grades'
import './templates/components/custom-column-cell'
import './templates/components/final-grade'
import './templates/components/grading-cell'
import './templates/content_selection/assignment'
import './templates/content_selection/header'
import './templates/content_selection/outcome'
import './templates/content_selection/selection_buttons'
import './templates/content_selection/student'
import './templates/gradezillaHeader'
import './templates/grading'
import './templates/header'
import './templates/learning_mastery'
import './templates/outcome_information'
import './templates/screenreader_gradebook'
import './templates/settings/assignment_toggles_and_actions'
import './templates/settings/grading_period_select'
import './templates/settings/header'
import './templates/settings/mastery_toggles_and_actions'
import './templates/settings/section_select'
import './templates/settings/sort_select'
import './templates/student_information/assignment_subtotals'
import './templates/student_information/details'
import './templates/student_information/index'

App.initializer({
  name: 'routes',
  initialize(container, application) {
    return application.Router.map(routes)
  }
})

export default App.reopen({
  AssignmentSubtotalGradesComponent,
  AssignmentMuterComponent,
  CustomColumnCellComponent,
  FastSelectComponent,
  FinalGradeComponent,
  GradingCellComponent,
  ScreenreaderGradebookController,
  ScreenreaderGradebookRoute,
  AssignmentsView,
  LearningMasteryView,
  ScreenreaderGradebookView,
  SelectionButtonsView
})
