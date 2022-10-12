/*
 * Copyright (C) 2022 - present Instructure, Inc.
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

import {ApplyTheme} from '@instructure/ui-themeable'
import {Checkbox} from '@instructure/ui-checkbox'
import {Flex} from '@instructure/ui-flex'
import {IconCalendarMonthLine} from '@instructure/ui-icons'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'

import {useScope as useI18nScope} from '@canvas/i18n'

import {accountListTheme} from '../theme'
import {Account, VisibilityChange} from '../types'

const I18n = useI18nScope('account_calendar_settings_account_calendar_item')

const CALENDAR_ICON_SIZE = '1.25rem'

type ComponentProps = {
  readonly item: Account
  readonly visibilityChanges: VisibilityChange[]
  readonly onAccountToggled: (id: number, visible: boolean) => void
  readonly padding?: string
  readonly showTopSeparator?: boolean
}

// Doing this to avoid TS2339 errors-- remove once we're on InstUI 8
const {Item: FlexItem} = Flex as any

export const AccountCalendarItem: React.FC<ComponentProps> = ({
  item,
  visibilityChanges,
  onAccountToggled,
  padding,
  showTopSeparator = false
}) => (
  <ApplyTheme theme={accountListTheme}>
    <View as="div" padding={padding} borderWidth={`${showTopSeparator ? 'small' : '0'} 0 0 0`}>
      <Flex data-testid="flex-calendar-item" as="div" alignItems="center">
        <FlexItem>
          <Checkbox
            label={
              <ScreenReaderContent>
                {I18n.t('Show account calendar for %{name}', {name: item.name})}
              </ScreenReaderContent>
            }
            inline={true}
            checked={
              visibilityChanges.find(change => change.id === item.id)
                ? visibilityChanges.find(change => change.id === item.id)!.visible
                : item.visible
            }
            onChange={e => onAccountToggled(item.id, e.target.checked)}
          />
        </FlexItem>
        <FlexItem margin="0 small">
          <IconCalendarMonthLine width={CALENDAR_ICON_SIZE} height={CALENDAR_ICON_SIZE} />
        </FlexItem>
        <FlexItem>
          <Text data-testid="account-calendar-name">{item.name}</Text>
        </FlexItem>
      </Flex>
    </View>
  </ApplyTheme>
)
