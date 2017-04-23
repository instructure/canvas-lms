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
  "compiled/ember/screenreader_gradebook/config/app",
  "compiled/ember/screenreader_gradebook/config/routes",
  "compiled/ember/screenreader_gradebook/components/assignment_subtotal_grades_component",
  "compiled/ember/screenreader_gradebook/components/assignment_muter_component",
  "compiled/ember/screenreader_gradebook/components/custom_column_cell_component",
  "compiled/ember/screenreader_gradebook/components/fast_select_component",
  "compiled/ember/screenreader_gradebook/components/final_grade_component",
  "compiled/ember/screenreader_gradebook/components/grading_cell_component",
  "compiled/ember/screenreader_gradebook/controllers/screenreader_gradebook_controller",
  "compiled/ember/screenreader_gradebook/routes/screenreader_gradebook_route",
  "compiled/ember/screenreader_gradebook/views/assignments_view",
  "compiled/ember/screenreader_gradebook/views/learning_mastery_view",
  "compiled/ember/screenreader_gradebook/views/screenreader_gradebook_view",
  "compiled/ember/screenreader_gradebook/views/selection_buttons_view",
  "compiled/ember/screenreader_gradebook/templates/aria_announcer",
  "compiled/ember/screenreader_gradebook/templates/assignment_information/actions",
  "compiled/ember/screenreader_gradebook/templates/assignment_information/details",
  "compiled/ember/screenreader_gradebook/templates/assignment_information/index",
  "compiled/ember/screenreader_gradebook/templates/assignments",
  "compiled/ember/screenreader_gradebook/templates/components/assignment-subtotal-grades",
  "compiled/ember/screenreader_gradebook/templates/components/custom-column-cell",
  "compiled/ember/screenreader_gradebook/templates/components/final-grade",
  "compiled/ember/screenreader_gradebook/templates/components/grading-cell",
  "compiled/ember/screenreader_gradebook/templates/content_selection/assignment",
  "compiled/ember/screenreader_gradebook/templates/content_selection/header",
  "compiled/ember/screenreader_gradebook/templates/content_selection/outcome",
  "compiled/ember/screenreader_gradebook/templates/content_selection/selection_buttons",
  "compiled/ember/screenreader_gradebook/templates/content_selection/student",
  "compiled/ember/screenreader_gradebook/templates/gradezillaHeader",
  "compiled/ember/screenreader_gradebook/templates/grading",
  "compiled/ember/screenreader_gradebook/templates/header",
  "compiled/ember/screenreader_gradebook/templates/learning_mastery",
  "compiled/ember/screenreader_gradebook/templates/outcome_information",
  "compiled/ember/screenreader_gradebook/templates/screenreader_gradebook",
  "compiled/ember/screenreader_gradebook/templates/settings/assignment_toggles_and_actions",
  "compiled/ember/screenreader_gradebook/templates/settings/grading_period_select",
  "compiled/ember/screenreader_gradebook/templates/settings/header",
  "compiled/ember/screenreader_gradebook/templates/settings/mastery_toggles_and_actions",
  "compiled/ember/screenreader_gradebook/templates/settings/section_select",
  "compiled/ember/screenreader_gradebook/templates/settings/sort_select",
  "compiled/ember/screenreader_gradebook/templates/student_information/assignment_subtotals",
  "compiled/ember/screenreader_gradebook/templates/student_information/details",
  "compiled/ember/screenreader_gradebook/templates/student_information/index"
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
