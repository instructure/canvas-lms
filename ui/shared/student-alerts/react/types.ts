/*
 * Copyright (C) 2025 - present Instructure, Inc.
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

export enum CriterionType {
  Interaction = 'Interaction',
  UngradedCount = 'UngradedCount',
  UngradedTimespan = 'UngradedTimespan',
}

export interface AlertCriterion {
  criterion_type: CriterionType
  threshold: number
}

export type AlertRecipient = ':student' | ':teachers' | string

export interface Alert {
  id?: number | string
  criteria: AlertCriterion[]
  recipients: AlertRecipient[]
  repetition?: number | null
}

export interface PossibleCriteria {
  label: (count: number) => string
  option: string
  default_threshold: number
}

export interface AlertUIMetadata {
  POSSIBLE_RECIPIENTS: Record<AlertRecipient, string>
  POSSIBLE_CRITERIA: Record<CriterionType, PossibleCriteria>
}

export interface AccountRole {
  id: string
  label: string
}

export interface SaveAlertPayload {
  alert: Alert
}
