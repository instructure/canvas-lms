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

import {
  type ItemType,
  type CheckboxTreeNode,
  type CheckboxState,
  type SwitchState,
  TreeSelector,
} from './react/TreeSelector/TreeSelector'

import {CommonMigratorControls} from './react/CommonMigratorControls/CommonMigratorControls'
import {
  type AdjustDates,
  type DaySub,
  type DateShifts,
  type DateShiftsCommon,
  type DateAdjustmentConfig,
  type MigrationCreateRequestBody,
  type onSubmitMigrationFormCallback,
} from './react/CommonMigratorControls/types'

export {TreeSelector}
export type {CheckboxTreeNode, CheckboxState, ItemType, SwitchState}
export {CommonMigratorControls}
export type {
  AdjustDates,
  DaySub,
  DateShifts,
  DateShiftsCommon,
  DateAdjustmentConfig,
  MigrationCreateRequestBody,
  onSubmitMigrationFormCallback,
}

export {parseDateToISOString} from './react/utils'

export {FormLabel, RequiredFormLabel} from './react/CommonMigratorControls/FormLabel'
export {ErrorFormMessage, noFileSelectedFormMessage} from './react/errorFormMessage'
export {convertFormDataToMigrationCreateRequest} from './react/CommonMigratorControls/converter/form_data_converter'
