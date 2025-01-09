/*
 * Copyright (C) 2024 - present Instructure, Inc.
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

import React, {useCallback} from 'react'
import {Button} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {Menu, type MenuItemProps} from '@instructure/ui-menu'
import {IconArrowOpenDownLine, IconFilterLine} from '@instructure/ui-icons'
import {useScope as createI18nScope} from '@canvas/i18n'
import type {Record} from 'immutable'

const I18n = createI18nScope('block-editor')

export const AvailableTags: Record<string, string> = {
  home: I18n.t('Home'),
  resource: I18n.t('Resource'),
  moduleoverview: I18n.t('Module Overview'),
  intro: I18n.t('Introduction'),
  generalcontent: I18n.t('General Content'),
}

type TagSelectProps = {
  onChange: (tags: string[]) => void
  selectedTags: string[]
  interaction: 'enabled' | 'disabled'
}

const TagSelect = ({onChange, selectedTags, interaction}: TagSelectProps) => {
  const handleTagSelect = useCallback(
    (_e: any, value: MenuItemProps['value'], selected: MenuItemProps['selected']) => {
      const tag = value as string
      if (selected) {
        if (!selectedTags.includes(tag)) {
          onChange([...selectedTags, tag])
        }
      } else {
        onChange(selectedTags.filter(t => t !== tag))
      }
    },
    [onChange, selectedTags],
  )

  return (
    <Menu
      trigger={
        <Button renderIcon={<IconFilterLine />} interaction={interaction}>
          <Flex gap="x-small">
            {I18n.t('Apply Filters')}
            <IconArrowOpenDownLine size="x-small" />
          </Flex>
        </Button>
      }
    >
      {Object.keys(AvailableTags)
        .sort()
        .map(key => (
          <Menu.Item
            key={key}
            type="checkbox"
            value={key}
            selected={selectedTags.includes(key)}
            onSelect={handleTagSelect}
          >
            {AvailableTags[key]}
          </Menu.Item>
        ))}
    </Menu>
  )
}

export {TagSelect}
