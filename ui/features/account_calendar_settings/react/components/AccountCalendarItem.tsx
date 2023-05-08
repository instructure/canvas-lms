// @ts-nocheck
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

import React, {useEffect, useState} from 'react'

import {Checkbox} from '@instructure/ui-checkbox'
import {Flex} from '@instructure/ui-flex'
import {IconCalendarMonthLine} from '@instructure/ui-icons'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'

import {useScope as useI18nScope} from '@canvas/i18n'

import {Account, SubscriptionChange, VisibilityChange} from '../types'
import SubscriptionsDropDown from './SubscriptionDropDown'

const I18n = useI18nScope('account_calendar_settings_account_calendar_item')

const CALENDAR_ICON_SIZE = '1.25rem'

type ComponentProps = {
  readonly item: Account
  readonly visibilityChanges: VisibilityChange[]
  readonly subscriptionChanges: SubscriptionChange[]
  readonly onAccountToggled: (id: number, visible: boolean) => void
  readonly onAccountSubscriptionToggled: (id: number, autoSubscription: boolean) => void
  readonly padding?: string
  readonly showTopSeparator?: boolean
  readonly autoSubscriptionEnabled: boolean
}

// Doing this to avoid TS2339 errors-- remove once we're on InstUI 8
const {Item: FlexItem} = Flex as any

export const AccountCalendarItem = ({
  item,
  visibilityChanges,
  subscriptionChanges,
  onAccountToggled,
  onAccountSubscriptionToggled,
  padding,
  showTopSeparator = false,
  autoSubscriptionEnabled,
}: ComponentProps) => {
  const [isVisible, setIsVisible] = useState(item.visible)
  const [isAutoSubscription, setIsAutoSubscription] = useState(item.auto_subscribe)

  useEffect(() => {
    const accountVisibility =
      visibilityChanges?.find(change => change.id === item.id)?.visible ?? item.visible
    setIsVisible(accountVisibility)
  }, [item.id, item.visible, visibilityChanges])

  useEffect(() => {
    const autoSubscription =
      subscriptionChanges?.find(change => change.id === item.id)?.auto_subscribe ??
      item.auto_subscribe
    setIsAutoSubscription(autoSubscription)
  }, [item.id, item.auto_subscribe, subscriptionChanges])

  return (
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
            checked={isVisible}
            onChange={e => onAccountToggled(item.id, e.target.checked)}
          />
        </FlexItem>
        <FlexItem margin="0 small">
          <IconCalendarMonthLine width={CALENDAR_ICON_SIZE} height={CALENDAR_ICON_SIZE} />
        </FlexItem>
        <FlexItem>
          <Text data-testid="account-calendar-name">{item.name}</Text>
        </FlexItem>
        {autoSubscriptionEnabled && (
          <FlexItem margin="0 0 0 auto">
            <SubscriptionsDropDown
              accountId={item.id}
              autoSubscription={isAutoSubscription}
              disabled={!isVisible}
              onChange={onAccountSubscriptionToggled}
            />
          </FlexItem>
        )}
      </Flex>
    </View>
  )
}
