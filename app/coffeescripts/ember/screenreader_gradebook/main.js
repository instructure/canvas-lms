#
# Copyright (C) 2017 - present Instructure, Inc.
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
  "ember",
  "./config/app",
  "./config/routes",
  "./components/assignment_subtotal_grades_component",
  "./components/assignment_muter_component",
  "./components/custom_column_cell_component",
  "./components/fast_select_component",
  "./components/final_grade_component",
  "./components/grading_cell_component",
  "./controllers/screenreader_gradebook_controller",
  "./routes/screenreader_gradebook_route",
  "./views/assignments_view",
  "./views/learning_mastery_view",
  "./views/screenreader_gradebook_view",
  "./views/selection_buttons_view",
  "./templates/aria_announcer",
  "./templates/assignment_information/actions",
  "./templates/assignment_information/details",
  "./templates/assignment_information/index",
  "./templates/assignments",
  "./templates/components/assignment-subtotal-grades",
  "./templates/components/custom-column-cell",
  "./templates/components/final-grade",
  "./templates/components/grading-cell",
  "./templates/content_selection/assignment",
  "./templates/content_selection/header",
  "./templates/content_selection/outcome",
  "./templates/content_selection/selection_buttons",
  "./templates/content_selection/student",
  "./templates/gradezillaHeader",
  "./templates/grading",
  "./templates/header",
  "./templates/learning_mastery",
  "./templates/outcome_information",
  "./templates/screenreader_gradebook",
  "./templates/settings/assignment_toggles_and_actions",
  "./templates/settings/grading_period_select",
  "./templates/settings/header",
  "./templates/settings/mastery_toggles_and_actions",
  "./templates/settings/section_select",
  "./templates/settings/sort_select",
  "./templates/student_information/assignment_subtotals",
  "./templates/student_information/details",
  "./templates/student_information/index"
], (
  Ember,
  App,
  routes,
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
) ->

  App.initializer
    name: 'routes'
    initialize: (container, application) ->
      application.Router.map(routes)

  App.reopen({
    AssignmentSubtotalGradesComponent: AssignmentSubtotalGradesComponent
    AssignmentMuterComponent: AssignmentMuterComponent
    CustomColumnCellComponent: CustomColumnCellComponent
    FastSelectComponent: FastSelectComponent
    FinalGradeComponent: FinalGradeComponent
    GradingCellComponent: GradingCellComponent
    ScreenreaderGradebookController: ScreenreaderGradebookController
    ScreenreaderGradebookRoute: ScreenreaderGradebookRoute
    AssignmentsView: AssignmentsView
    LearningMasteryView: LearningMasteryView
    ScreenreaderGradebookView: ScreenreaderGradebookView
    SelectionButtonsView: SelectionButtonsView
  })
