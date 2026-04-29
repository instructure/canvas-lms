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

/**
 * Types of flash notifcations,
 * pulled from: app/controllers/application_controller.rb
 */
type FlashNotificationType = 'warning' | 'error' | 'info' | 'success'

/**
 * Types of icons for flash notifcations,
 * pulled from: app/controllers/application_controller.rb
 */
type FlashNotificationIcon = 'warning' | 'error' | 'info' | 'check'

/**
 * Type for flash notice message content
 */
export type FlashNotificationContent = string | {timeout?: number; html: string}

export type FlashNotice = {
  type: FlashNotificationType
  icon?: FlashNotificationIcon
  content: FlashNotificationContent
  classes?: string
}

export interface EnvNotices {
  notices: ReadonlyArray<FlashNotice>
}
