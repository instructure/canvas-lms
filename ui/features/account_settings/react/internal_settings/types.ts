/*
 * Copyright (C) 2022 - present Instructure, Inc.
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

export type InternalSetting = {
  id: string
  name: string
  value: string | null
  secret: boolean
}

export type InternalSettingsData = {
  internalSettings: InternalSetting[]
}

export type InternalSettingData = {
  internalSetting: InternalSetting
}

export type InternalSettingMutationData = {
  errors?: {message: string}
}

export type UpdateInternalSettingData = InternalSettingMutationData & {
  updateInternalSetting: InternalSettingData
}

export type DeleteInternalSettingData = InternalSettingMutationData & {
  deleteInternalSetting: {internalSettingId: string}
}

export type CreateInternalSettingData = InternalSettingMutationData & {
  createInternalSetting: InternalSettingData
}

export type InternalSettingMutationVariables = {
  internalSettingId: string
}

export type UpdateInternalSettingVariables = InternalSettingMutationVariables & {
  value: string
}

export type CreateInternalSettingVariables = {
  name: string
  value: string
}
