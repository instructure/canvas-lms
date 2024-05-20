/*
 * Copyright (C) 2023 - present Instructure, Inc.
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

import {GradingStandard} from '@instructure/grading-utils'

export type EnvGradingStandards = EnvGradingStandardsCommon & Partial<EnvGradingStandardsAccount>

export interface EnvGradingStandardsCommon {
  GRADING_STANDARDS_URL: string
  GRADING_PERIOD_SETS_URL: string
  ENROLLMENT_TERMS_URL: string
  HAS_GRADING_PERIODS: boolean
  DEFAULT_GRADING_STANDARD_DATA: GradingStandard
  CONTEXT_SETTINGS_URL: string
  COURSE_DEFAULT_GRADING_SCHEME_ID: string | undefined
  GRADING_SCHEME_UPDATES_ENABLED: boolean
  CUSTOM_GRADEBOOK_STATUSES_ENABLED: boolean
  ARCHIVED_GRADING_SCHEMES_ENABLED: boolean
  /**
   * NOTE: Only present if the context is not Account
   */
  GRADING_PERIODS_URL?: string

  /**
   * NOTE: Only present if the context is not Account
   */
  GRADING_PERIODS_WEIGHTED?: boolean
}

export interface EnvGradingStandardsAccount {
  GRADING_PERIODS_UPDATE_URL: string
  GRADING_PERIODS_READ_ONLY: boolean
  GRADING_PERIOD_SET_UPDATE_URL: string
  ENROLLMENT_TERMS_URL: string
  DELETE_GRADING_PERIOD_URL: string
}
