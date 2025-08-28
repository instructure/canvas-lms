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

import React, {useMemo} from 'react'
import {Flex} from '@instructure/ui-flex'
import {Text} from '@instructure/ui-text'
import {Link} from '@instructure/ui-link'
import {IconExternalLinkLine} from '@instructure/ui-icons'
import {View} from '@instructure/ui-view'
import {ModuleItemContent} from '../utils/types'

interface ModuleItemTitleProps {
  moduleItemId: string
  content: ModuleItemContent
  url: string
  title: string
  onClick?: () => void
}

const ModuleItemTitle: React.FC<ModuleItemTitleProps> = ({
  moduleItemId,
  content,
  url,
  title,
  onClick,
}) => {
  const titleText = useMemo(() => {
    if (content?.type === 'ExternalUrl') {
      return (
        <Flex direction="row" gap="small" alignItems="center" wrap="no-wrap">
          <Flex.Item>
            <Link href={url} isWithinText={false} onClick={onClick}>
              <Text
                weight={content?.newTab ? 'normal' : 'bold'}
                color={content?.newTab ? 'brand' : 'primary'}
              >
                {title || 'Untitled Item'}
              </Text>
            </Link>
          </Flex.Item>
          <Flex.Item padding="0 0 xxx-small 0">
            {content?.newTab && (
              <IconExternalLinkLine size="x-small" color="brand" data-testid="external-link-icon" />
            )}
          </Flex.Item>
        </Flex>
      )
    } else if (content?.type === 'SubHeader') {
      return (
        <Text weight="bold" color="primary" data-testid="subheader-title-text">
          {title || 'Untitled Item'}
        </Text>
      )
    } else {
      return (
        <Link
          href={url}
          isWithinText={false}
          onClick={onClick}
          data-testid="module-item-title-link"
          data-module-item-id={moduleItemId}
        >
          <Text weight="bold" color="primary">
            {title || 'Untitled Item'}
          </Text>
        </Link>
      )
    }
  }, [content, url, onClick, title])

  return (
    <View as="div" padding="0 xx-small" className="module-title">
      {titleText}
    </View>
  )
}

export default ModuleItemTitle
