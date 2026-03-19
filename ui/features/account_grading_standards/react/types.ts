/*
 * Copyright (C) 2016 - present Instructure, Inc.
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

import type {EnrollmentTerm as ApiEnrollmentTerm} from '../enrollmentTermsApi'

export interface Permissions {
  read: boolean
  create: boolean
  update: boolean
  delete: boolean
}

export interface GradingPeriodsUrls {
  batchUpdateURL: string
  gradingPeriodSetsURL: string
  deleteGradingPeriodURL: string
}

export interface CollectionUrls {
  gradingPeriodSetsURL: string
  gradingPeriodsUpdateURL: string
  enrollmentTermsURL: string
  deleteGradingPeriodURL: string
}

export interface GradingPeriod {
  id?: string
  title: string
  weight: number
  startDate: Date
  endDate: Date
  closeDate: Date
  isClosed?: boolean
  isLast?: boolean
}

export interface GradingPeriodDraft {
  id?: string
  title: string
  weight: number | null
  startDate: Date | null
  endDate: Date | null
  closeDate: Date | null
}

export interface GradingPeriodSet {
  id: string
  title: string
  weighted: boolean
  displayTotalsForAllGradingPeriods: boolean
  createdAt: Date
  gradingPeriods: GradingPeriod[]
  enrollmentTermIDs?: string[]
  permissions: Permissions
}

export interface GradingPeriodSetEditorData {
  id?: string
  title: string
  weighted: boolean
  displayTotalsForAllGradingPeriods: boolean
  enrollmentTermIDs: string[]
}

export interface EnrollmentTerm extends ApiEnrollmentTerm {
  displayName?: string
}
