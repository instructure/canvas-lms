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

// This isn't everything in the redux state, just the things we need
export type ReduxState = {
  apiBusy: Array<{id: string; name: string}>
  nextFocus: {
    targetArea: 'tray' | 'table' | null
    permissionName: string | null
    roleId: string | null
  }
}

// NONE must have value 0 so it Boolean-casts to false, for backward
// compatibility with the older Boolean value of 'enabled'.
export enum EnabledState {
  NONE,
  PARTIAL,
  ALL,
}

export type RolePermission = {
  enabled: EnabledState
  explicit: boolean
  locked: boolean
  readonly: boolean
  applies_to_descendants?: boolean
  applies_to_self?: boolean
}

export interface PermissionModifyAction {
  name: string
  id: string
  inTray: boolean
  enabled?: boolean
  locked?: boolean
  explicit: boolean
}
