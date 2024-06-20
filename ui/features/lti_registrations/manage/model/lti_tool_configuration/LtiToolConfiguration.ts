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
import * as z from 'zod'
import {ZLtiPrivacyLevel} from '../LtiPrivacyLevel'
import {ZLtiPlacement} from '../LtiPlacement'
import {ZLtiConfiguration} from './LtiConfiguration'

/**
 * Represents the configuration of an LTI tool associated with a developer key.
 *
 * @see lib/schemas/lti/tool_configuration.rb
 */
export const ZLtiToolConfiguration = z.object({
  id: z.string(),
  privacy_level: ZLtiPrivacyLevel,
  developer_key_id: z.string(),
  disabled_placements: z.array(ZLtiPlacement),
  settings: ZLtiConfiguration,
  created_at: z.string(),
  updated_at: z.string(),
})

export interface LtiToolConfiguration extends z.infer<typeof ZLtiToolConfiguration> {}
