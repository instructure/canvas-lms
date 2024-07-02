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

import {useScope as useI18nScope} from '@canvas/i18n'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
import {CloseButton} from '@instructure/ui-buttons'

import {LtiToolIcon} from '../../../shared/lti/react/LtiToolIcon'

const I18n = useI18nScope('assignment_editview_external_tool')

export type CardProps = {
  resourceTitle?: string
  onCloseButton: () => void
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

export function AssignmentSubmissionTypeSelectionResourceLinkCard(props: CardProps) {
  const {resourceTitle, onCloseButton, tool} = props
  return (
    <View
      id="assignment-submission-type-selection-resource-link-card"
      data-testid="assignment-submission-type-selection-resource-link-card"
      display="flex"
      position="relative"
      padding="small 0"
      margin="small 0"
      borderColor="primary"
      borderRadius="medium"
      borderWidth="small"
      background="primary"
    >
      <CloseButton
        placement="end"
        offset="small"
        screenReaderLabel="Close"
        onClick={onCloseButton}
        data-testid="close-button"
      />
      <div style={{display: 'flex', alignItems: 'center'}}>
        <LtiToolIcon tool={tool} />
        <View>
          <Text weight="bold" id="resource_title">
            {resourceTitle || I18n.t('Unnamed Document')}
          </Text>
          <Text as="div" color="secondary" size="small" id="tool_title">
            {tool.title}
          </Text>
        </View>
      </div>
    </View>
  )
}
