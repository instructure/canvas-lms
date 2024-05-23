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

import type {GlobalEnv} from '@canvas/global/env/GlobalEnv.d'

import {BaseButton} from '@instructure/ui-buttons'
import {Avatar} from '@instructure/ui-avatar'
import {Text} from '@instructure/ui-text'
import {TruncateText} from '@instructure/ui-truncate-text'
import {View} from '@instructure/ui-view'

export type ButtonProps = {
  tool: {
    developer_key?: {
      global_id?: string
    }
    id: string
    title: string
    description?: string
    icon_url?: string
  }
  onClick: () => void
}

export function AssignmentSubmissionTypeSelectionLaunchButton(props: ButtonProps) {
  const {tool, onClick} = props
  const {title, description, icon_url: iconUrl} = tool

  const RenderIcon = () => {
    return iconUrl ? (
      <Avatar src={iconUrl} name={title} shape="rectangle" width="28px" height="28px" />
    ) : undefined
  }

  return (
    <BaseButton
      id="assignment_submission_type_selection_launch_button"
      data-testid="assignment_submission_type_selection_launch_button"
      display="block"
      color="secondary"
      margin="small 0"
      withBackground={true}
      withBorder={true}
      onClick={onClick}
      renderIcon={RenderIcon}
    >
      <View>
        <Text as="div" id="title_text">
          {title}
        </Text>
        {description && (
          <Text id="desc_text" weight="light" size="small">
            <TruncateText maxLines={1}>{description}</TruncateText>
          </Text>
        )}
      </View>
    </BaseButton>
  )
}
