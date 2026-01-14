/*
 * Copyright (C) 2025 - present Instructure, Inc.
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

import {Flex} from '@instructure/ui-flex'
import {IconAssignmentLine, IconDocumentLine, IconMsWordLine} from '@instructure/ui-icons'
import {Text} from '@instructure/ui-text'

import {useScope as createI18nScope} from '@canvas/i18n'

import {AccessibilityResourceScan, ResourceType} from '../../../../../shared/react/types'

interface ContentTypeCellProps {
  item: AccessibilityResourceScan
}

const I18n = createI18nScope('accessibility_checker')

function getIconByContentType(contentType: ResourceType) {
  switch (contentType) {
    case ResourceType.WikiPage:
      return <IconDocumentLine aria-hidden="true" />
    case ResourceType.Assignment:
      return <IconAssignmentLine aria-hidden="true" />
    case ResourceType.Attachment:
      return <IconMsWordLine aria-hidden="true" />
  }
}

function getTextByContentType(contentType: ResourceType) {
  switch (contentType) {
    case ResourceType.WikiPage:
      return I18n.t('Page')
    case ResourceType.Assignment:
      return I18n.t('Assignment')
    case ResourceType.Attachment:
      return I18n.t('Attachment')
  }
}

export const ContentTypeCell: React.FC<ContentTypeCellProps> = ({item}: ContentTypeCellProps) => (
  <Flex gap="x-small">
    <Flex.Item>
      <Flex>{getIconByContentType(item.resourceType)}</Flex>
    </Flex.Item>
    <Flex.Item>
      <Text>{getTextByContentType(item.resourceType)}</Text>
    </Flex.Item>
  </Flex>
)
