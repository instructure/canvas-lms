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
import * as z from 'zod'
import {ZLtiPrivacyLevel} from '../LtiPrivacyLevel'
import {ZPlatformSettings} from './PlatformSettings'

export interface Extension extends z.infer<typeof ZExtension> {}

export const ZExtension = z.object({
  domain: z.string().optional().nullable(),
  platform: z.string(),
  tool_id: z.string().optional().nullable(),
  privacy_level: ZLtiPrivacyLevel.optional().nullable(),
  settings: ZPlatformSettings,
})
