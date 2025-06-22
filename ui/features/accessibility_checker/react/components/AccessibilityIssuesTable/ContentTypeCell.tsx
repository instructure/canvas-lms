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
import {PresentationContent} from '@instructure/ui-a11y-content'
import {Text} from '@instructure/ui-text'

import {useScope as createI18nScope} from '@canvas/i18n'

import {ContentItem, ContentItemType} from '../../types'

interface ContentTypeCellProps {
  item: ContentItem
}

const I18n = createI18nScope('accessibility_checker')

function getIconByContentType(contentType: ContentItemType) {
  switch (contentType) {
    case ContentItemType.WikiPage:
      return <IconDocumentLine />
    case ContentItemType.Assignment:
      return <IconAssignmentLine />
    case ContentItemType.Attachment:
      return <IconMsWordLine />
  }
}

function getTextByContentType(contentType: ContentItemType) {
  switch (contentType) {
    case ContentItemType.WikiPage:
      return I18n.t('Page')
    case ContentItemType.Assignment:
      return I18n.t('Assignment')
    case ContentItemType.Attachment:
      return I18n.t('Attachment')
  }
}

export const ContentTypeCell: React.FC<ContentTypeCellProps> = ({item}: ContentTypeCellProps) => (
  <Flex gap="x-small">
    <Flex.Item>
      <PresentationContent>{getIconByContentType(item.type)}</PresentationContent>
    </Flex.Item>
    <Flex.Item>
      <Text>{getTextByContentType(item.type)}</Text>
    </Flex.Item>
  </Flex>
)
