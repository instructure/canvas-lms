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

import React from 'react'
import {Flex} from '@instructure/ui-flex'
import {Text} from '@instructure/ui-text'
import {Tag} from '@instructure/ui-tag'
import {Link} from '@instructure/ui-link'
import {useScope as createI18nScope} from '@canvas/i18n'

const I18n = createI18nScope('differentiation_tags')

export interface TagData {
  id: number
  name: string
  members_count: number
}

export interface TagInfoProps {
  tags: TagData[]
  onEdit: React.MouseEventHandler<any>
  multiMode?: boolean
}

const TagInfo: React.FC<TagInfoProps> = ({tags, onEdit, multiMode = false}) => {
  if (tags.length === 0) {
    return (
      <Flex direction="column" margin="small 0 0 0">
        <Flex.Item overflowX="visible" overflowY="visible">
          <Text size="small">
            <Link
              href="#"
              margin="small 0 0 0"
              as="button"
              onClick={onEdit}
              aria-label={I18n.t('Add a variant to the tag')}
            >
              {I18n.t('+ Add a variant')}
            </Link>
          </Text>
        </Flex.Item>
      </Flex>
    )
  } else if (tags.length === 1 && !multiMode) {
    return (
      <Text>
        {I18n.t(
          {
            one: '1 student',
            other: '%{count} students',
          },
          {
            count: tags[0].members_count,
          },
        )}{' '}
      </Text>
    )
  } else {
    return (
      <Flex direction="column" margin="small 0 0 0">
        <Flex.Item>
          {tags.map(tagData => (
            <Flex
              key={tagData.id}
              direction="row"
              alignItems="center"
              gap="x-small"
              margin="0 0 x-small 0"
              data-testid="tag-info"
            >
              <Flex.Item shouldGrow shouldShrink>
                <Tag text={tagData.name} size="small" />
              </Flex.Item>
              <Flex.Item shouldShrink={false}>
                <Text size="small">
                  {I18n.t(
                    {
                      one: '1 student',
                      other: '%{count} students',
                    },
                    {
                      count: tagData.members_count,
                    },
                  )}
                </Text>
              </Flex.Item>
            </Flex>
          ))}
        </Flex.Item>
        <Flex.Item overflowX="visible" overflowY="visible">
          <Text size="small">
            <Link
              href="#"
              margin="small 0 0 0"
              as="button"
              onClick={onEdit}
              aria-label={I18n.t('Add a variant to the tag')}
            >
              {I18n.t('+ Add a variant')}
            </Link>
          </Text>
        </Flex.Item>
      </Flex>
    )
  }
}

export default TagInfo
