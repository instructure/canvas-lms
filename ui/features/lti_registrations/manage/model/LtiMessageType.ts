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

export const LtiResourceLinkRequest = 'LtiResourceLinkRequest' as const
export const LtiDeepLinkingRequest = 'LtiDeepLinkingRequest' as const
export const ZResourceLinkRequest = z.literal(LtiResourceLinkRequest)
export const ZDeepLinkingRequest = z.literal(LtiDeepLinkingRequest)

export const ZLtiMessageType = z.union([ZDeepLinkingRequest, ZResourceLinkRequest])

export type LtiMessageType = z.infer<typeof ZLtiMessageType>

export const isLtiMessageType = (s: string): s is LtiMessageType => {
  return ZLtiMessageType.safeParse(s).success
}
