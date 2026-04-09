/*
 * Copyright (C) 2021 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import {
  ScoreDisplayFormat,
  OutcomeArrangement,
  NameDisplayFormat,
  SecondaryInfoDisplay,
  DisplayFilter,
} from '@instructure/outcomes-ui/lib/util/gradebook/constants'

export const MAX_GRID_WIDTH: number = 1440
export const STUDENT_COLUMN_WIDTH: number = 220
export const STUDENT_COLUMN_RIGHT_PADDING: number = 15
export const COLUMN_PADDING: number = 2

export const BAR_CHART_HEIGHT: number = 64

export const DEFAULT_PAGE_NUMBER: number = 1
export const DEFAULT_STUDENTS_PER_PAGE: number = 15
export const STUDENTS_PER_PAGE_OPTIONS: number[] = [15, 30, 50, 100]

export enum SortBy {
  Name = 'student_name',
  SortableName = 'student',
  SisId = 'student_sis_id',
  IntegrationId = 'student_integration_id',
  LoginId = 'student_login_id',
  Outcome = 'outcome',
  ContributingScore = 'contributing_score',
}

export interface GradebookSettings {
  secondaryInfoDisplay: SecondaryInfoDisplay
  displayFilters: DisplayFilter[]
  nameDisplayFormat: NameDisplayFormat
  studentsPerPage: number
  scoreDisplayFormat: ScoreDisplayFormat
  outcomeArrangement: OutcomeArrangement
}

export const DEFAULT_GRADEBOOK_SETTINGS: GradebookSettings = {
  secondaryInfoDisplay: SecondaryInfoDisplay.NONE,
  displayFilters: [
    DisplayFilter.SHOW_STUDENT_AVATARS,
    DisplayFilter.SHOW_STUDENTS_WITH_NO_RESULTS,
    DisplayFilter.SHOW_OUTCOMES_WITH_NO_RESULTS,
  ],
  nameDisplayFormat: NameDisplayFormat.FIRST_LAST,
  studentsPerPage: DEFAULT_STUDENTS_PER_PAGE,
  scoreDisplayFormat: ScoreDisplayFormat.ICON_ONLY,
  outcomeArrangement: OutcomeArrangement.UPLOAD_ORDER,
}
