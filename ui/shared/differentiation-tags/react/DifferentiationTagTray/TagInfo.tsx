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
import {useScope as createI18nScope} from '@canvas/i18n'

const I18n = createI18nScope('differentiation_tags')

export interface TagData {
  id: number
  name: string
  members_count: number
}

export interface TagInfoProps {
  tags: TagData[]
  multiMode?: boolean
}

const TagInfo: React.FC<TagInfoProps> = ({tags, multiMode = false}) => {
  if (tags.length === 1 && !multiMode) {
    return (
      <Text size="small" aria-hidden="true" data-testid="tag-member-count">
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
                <Tag
                  text={tagData.name}
                  size="small"
                  aria-label={I18n.t(
                    {one: '%{name} - 1 student', other: '%{name} - %{count} students'},
                    {name: tagData.name, count: tagData.members_count},
                  )}
                  data-testid={`tag-${tagData.name}`}
                />
              </Flex.Item>
              <Flex.Item shouldShrink={false}>
                <Text size="small" aria-hidden="true">
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
      </Flex>
    )
  }
}

export default TagInfo
