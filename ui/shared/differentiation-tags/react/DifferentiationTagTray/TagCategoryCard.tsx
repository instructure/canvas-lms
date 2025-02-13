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
import {View} from '@instructure/ui-view'
import {IconButton} from '@instructure/ui-buttons'
import {IconEditLine, IconTrashLine} from '@instructure/ui-icons'
import {TruncateText} from '@instructure/ui-truncate-text'
import {useScope as createI18nScope} from '@canvas/i18n'
import TagInfo from './TagInfo'
import {DifferentiationTagCategory} from '../types'

const I18n = createI18nScope('differentiation_tags')

export interface TagCategoryCardProps {
  category: DifferentiationTagCategory
  onEditCategory: (id: number) => void
}

function TagCategoryCard({category, onEditCategory}: TagCategoryCardProps) {
  const {name, groups = []} = category

  const handleEdit = (event: React.KeyboardEvent<any> | React.MouseEvent<any, MouseEvent>) => {
    event.preventDefault()
    onEditCategory(category.id)
  }

  const handleDelete = () => {
    // TODO: Add delete functionality
    console.log('delete')
  }

  return (
    <View padding="small medium" margin="small 0" display="block" borderWidth="small">
      <Flex justifyItems="space-between" width="100%">
        <Flex.Item shouldGrow shouldShrink>
          <Flex direction="column">
            <Flex.Item>
              <TruncateText>{name}</TruncateText>
            </Flex.Item>
            <Flex.Item>
              {groups.length < 2 && (
                <View margin="0 0 small 0" as="div">
                  <Text size="small" color="secondary">
                    {groups.length === 0 ? I18n.t('No tags in tag set') : I18n.t('Single tag')}
                  </Text>
                </View>
              )}
            </Flex.Item>
          </Flex>
        </Flex.Item>

        <Flex.Item align="start" margin="0 0 0 small" shouldShrink={false}>
          <Flex>
            <Flex.Item margin="0 x-small 0 0">
              <IconButton
                color="primary"
                size="small"
                withBackground={false}
                withBorder={false}
                screenReaderLabel={I18n.t('Edit')}
                onClick={handleEdit}
              >
                <IconEditLine />
              </IconButton>
            </Flex.Item>
            <Flex.Item>
              <IconButton
                color="primary"
                size="small"
                withBackground={false}
                withBorder={false}
                screenReaderLabel={I18n.t('Delete')}
                onClick={handleDelete}
              >
                <IconTrashLine />
              </IconButton>
            </Flex.Item>
          </Flex>
        </Flex.Item>
      </Flex>
      <TagInfo tags={groups} onEdit={handleEdit} />
    </View>
  )
}

export default React.memo(TagCategoryCard)
