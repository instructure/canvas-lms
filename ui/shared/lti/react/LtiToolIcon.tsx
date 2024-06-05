/*
 * Copyright (C) 2019 - present Instructure, Inc.
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

import React from 'react'

import {View} from '@instructure/ui-view'
import {Avatar} from '@instructure/ui-avatar'

export type LtiToolIconProps = {
  tool: {
    developer_key?: {
      global_id?: string
    }
    id: string
    title: string
    description?: string
    icon_url?: string
  }
}

export function LtiToolIcon({tool}: LtiToolIconProps) {
  const toolId = tool?.developer_key?.global_id || tool.id
  const fallbackUrl = `/lti/tool_default_icon?id=${toolId}&name="${tool.title}"`

  return (
    <View>
      <Avatar
        name={tool.title}
        src={tool.icon_url || fallbackUrl}
        shape="rectangle"
        margin="0 small"
        data-testid="lti-tool-icon"
      />
    </View>
  )
}
