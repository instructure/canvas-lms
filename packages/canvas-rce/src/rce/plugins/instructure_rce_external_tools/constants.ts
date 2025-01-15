/*
 * Copyright (C) 2024 - present Instructure, Inc.
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
 * Name of the parameter used to indicate to Canvas that it is being loaded in an iframe inside of an
 * LTI tool. It should be set to the global id of the containing tool.
 */
export const parentFrameContextParam = 'parent_frame_context'

/**
 * Fallback iframe allowances used when they aren't provided to the editor.
 */
export const fallbackIframeAllowances = [
  'geolocation *',
  'microphone *',
  'camera *',
  'midi *',
  'encrypted-media *',
  'autoplay *',
  'clipboard-write *',
  'display-capture *',
]
