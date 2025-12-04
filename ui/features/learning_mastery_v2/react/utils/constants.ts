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

export const MAX_GRID_WIDTH: number = 1440
export const COLUMN_WIDTH: number = 160
export const STUDENT_COLUMN_WIDTH: number = 220
export const STUDENT_COLUMN_RIGHT_PADDING: number = 15
export const COLUMN_PADDING: number = 2
export const CELL_HEIGHT: number = 48

export const DEFAULT_PAGE_NUMBER: number = 1
export const DEFAULT_STUDENTS_PER_PAGE: number = 15
export const STUDENTS_PER_PAGE_OPTIONS: number[] = [15, 30, 50, 100]

export enum SortOrder {
  ASC = 'asc',
  DESC = 'desc',
}

export enum SortBy {
  Name = 'student_name',
  SortableName = 'student',
  SisId = 'student_sis_id',
  IntegrationId = 'student_integration_id',
  LoginId = 'student_login_id',
  Outcome = 'outcome',
}

export enum SecondaryInfoDisplay {
  NONE = 'none',
  SIS_ID = 'sis_id',
  INTEGRATION_ID = 'integration_id',
  LOGIN_ID = 'login_id',
}

export enum DisplayFilter {
  SHOW_STUDENTS_WITH_NO_RESULTS = 'show_students_with_no_results',
  SHOW_OUTCOMES_WITH_NO_RESULTS = 'show_outcomes_with_no_results',
  SHOW_STUDENT_AVATARS = 'show_student_avatars',
}

export enum NameDisplayFormat {
  FIRST_LAST = 'first_last',
  LAST_FIRST = 'last_first',
}

export enum ScoreDisplayFormat {
  ICON_ONLY = 'icon_only',
  ICON_AND_POINTS = 'icon_and_points',
  ICON_AND_LABEL = 'icon_and_label',
}

export enum OutcomeArrangement {
  ALPHABETICAL = 'alphabetical',
  CUSTOM = 'custom',
  UPLOAD_ORDER = 'upload_order',
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
