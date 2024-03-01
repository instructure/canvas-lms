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

import {BaseButton} from '@instructure/ui-buttons'
import {Text} from '@instructure/ui-text'
import {TruncateText} from '@instructure/ui-truncate-text'
import {View} from '@instructure/ui-view'

export default function AssignmentSubmissionTypeSelectionLaunchButton(props) {
  const {tool, onClick} = props
  const {title, description, icon_url: iconUrl} = tool

  return (
    window.ENV.UPDATE_ASSIGNMENT_SUBMISSION_TYPE_LAUNCH_BUTTON_ENABLED ? (
      <BaseButton
      id="assignment_submission_type_selection_launch_button"
      display="block"
      color="secondary"
      margin="small 0"
      withBackground={true}
      withBorder={true}
      onClick={onClick}
      renderIcon={iconUrl ? <img src={iconUrl} width="28px" height="28px" /> : undefined}
      >
        <View>
          <Text as="div" id="title_text">
            {title}
          </Text>
          {description && (
            <Text weight="light" size="small">
              <TruncateText as="div" id="desc_text" maxLines={1}>
                {description}
              </TruncateText>
            </Text>
          )}
        </View>
      </BaseButton>
      ) : (
        <div class="pad-box">
          <div class="ic-Form-control">
            <button class="Button btn-primary" type="button" id="assignment_submission_type_selection_launch_button" onClick={onClick}>
              <i class="icon-link sr-hide" />
              <span style={{marginLeft: "8px"}}>{title}</span>
            </button>
          </div>
        </div>
      )
  )
}
