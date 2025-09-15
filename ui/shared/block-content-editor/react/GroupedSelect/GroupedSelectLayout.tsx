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
import {List} from '@instructure/ui-list'
import {ReactNode} from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'

const I18n = createI18nScope('block_content_editor')

export const GroupedSelectLayout = (props: {
  groups: ReactNode[]
  items: ReactNode[]
  selectedBlockGroup: string
  onKeyDown: (event: React.KeyboardEvent) => void
  onBlur?: (event: React.FocusEvent) => void
}) => {
  return (
    <Flex alignItems="start" gap="medium" onKeyDown={props.onKeyDown} onBlur={props.onBlur}>
      <List
        role="group"
        width="50%"
        itemSpacing="xx-small"
        isUnstyled
        margin="none"
        data-testid="grouped-select-groups"
        aria-label={I18n.t('Block groups')}
      >
        {props.groups?.map((group, index) => (
          <List.Item key={index}>{group}</List.Item>
        ))}
      </List>
      <List
        role="group"
        width="50%"
        itemSpacing="xx-small"
        isUnstyled
        margin="none"
        data-testid="grouped-select-items"
        aria-label={I18n.t('%{selectedBlockGroup} group items', {
          selectedBlockGroup: props.selectedBlockGroup,
        })}
      >
        {props.items?.map((item, index) => (
          <List.Item key={index}>{item}</List.Item>
        ))}
      </List>
    </Flex>
  )
}
