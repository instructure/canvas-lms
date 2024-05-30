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
import {ZDynamicRegistrationTokenUUID} from './DynamicRegistrationTokenUUID'

export const ZDynamicRegistrationToken = z.object({
  token: z.string(),
  oidc_configuration_url: z.string(),
  uuid: ZDynamicRegistrationTokenUUID,
})

/**
 * A Canvas-specific token for dynamic registration
 * Requested after the user has entered the dynamic registration URL,
 * but before the user is redirected to the tool's registration UI.
 *
 * This token is sent to the tool, but also used by the FE to retrieve the
 * staged registration after the user returns from the tool.
 */
export type DynamicRegistrationToken = z.infer<typeof ZDynamicRegistrationToken>
