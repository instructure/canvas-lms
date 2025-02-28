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

import type {Lti} from '../models/Product'

export type PreferredLtiIntegration = {
  id: number
  unified_tool_id: string
  description: string
  lti_placements: string[]
  lti_services: string[]
} & (
  | {
      integration_type: 'lti_13_dynamic_registration'
      url: string
    }
  | {
      integration_type: 'lti_13_global_inherited_key'
      global_inherited_key: string
    }
  | {
      integration_type: 'lti_13_configuration'
      configuration: string
    }
  | {
      integration_type: 'lti_13_url'
      url: string
    }
)

type IntegrationType<T extends PreferredLtiIntegration['integration_type']> = Extract<
  PreferredLtiIntegration,
  {integration_type: T}
>

export const isLti13DynamicRegistrationConfig = (
  lti: Lti,
): lti is IntegrationType<'lti_13_dynamic_registration'> => {
  return (
    lti.integration_type === 'lti_13_dynamic_registration' &&
    'url' in lti &&
    typeof lti.url === 'string'
  )
}

export const isLti13GlobalInheritedKeyConfig = (
  lti: Lti,
): lti is IntegrationType<'lti_13_global_inherited_key'> => {
  return (
    lti.integration_type === 'lti_13_global_inherited_key' &&
    'global_inherited_key' in lti &&
    typeof lti.global_inherited_key === 'string'
  )
}

export const isLti13JsonConfig = (lti: Lti): lti is IntegrationType<'lti_13_configuration'> => {
  if (
    lti.integration_type === 'lti_13_configuration' &&
    'configuration' in lti &&
    typeof lti.configuration === 'string'
  ) {
    let isValidJson = false
    try {
      JSON.parse(lti.configuration)
      isValidJson = true
    } catch (e) {
      isValidJson = false
    }
    return isValidJson
  } else {
    return false
  }
}

export const isLti13UrlConfig = (lti: Lti): lti is IntegrationType<'lti_13_url'> => {
  return lti.integration_type === 'lti_13_url' && 'url' in lti && typeof lti.url === 'string'
}

export const pickPreferredIntegration = (configs: Lti[]): PreferredLtiIntegration | undefined => {
  return (
    configs.find(isLti13DynamicRegistrationConfig) ||
    configs.find(isLti13GlobalInheritedKeyConfig) ||
    configs.find(isLti13JsonConfig) ||
    configs.find(isLti13UrlConfig)
  )
}
