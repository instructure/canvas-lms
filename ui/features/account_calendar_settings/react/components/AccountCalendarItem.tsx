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

import type {Spacing} from '@instructure/emotion'
import {Checkbox} from '@instructure/ui-checkbox'
import {Flex} from '@instructure/ui-flex'
import {IconCalendarMonthLine} from '@instructure/ui-icons'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'

import {useScope as useI18nScope} from '@canvas/i18n'

import type {Account, SubscriptionChange, VisibilityChange} from '../types'
import SubscriptionsDropDown from './SubscriptionDropDown'

const I18n = useI18nScope('account_calendar_settings_account_calendar_item')

const CALENDAR_ICON_SIZE = '1.25rem'

type ComponentProps = {
  readonly item: Account
  readonly visibilityChanges: VisibilityChange[]
  readonly subscriptionChanges: SubscriptionChange[]
  readonly onAccountToggled: (id: number, visible: boolean) => void
  readonly onAccountSubscriptionToggled: (id: number, autoSubscription: boolean) => void
  readonly padding: Spacing
  readonly showTopSeparator?: boolean
}

export const AccountCalendarItem = ({
  item,
  visibilityChanges,
  subscriptionChanges,
  onAccountToggled,
  onAccountSubscriptionToggled,
  padding,
  showTopSeparator = false,
}: ComponentProps) => {
  const [isVisible, setIsVisible] = useState(item.visible)
  const [isAutoSubscription, setIsAutoSubscription] = useState<boolean>(
    item.auto_subscribe ?? false
  )

  useEffect(() => {
    const accountVisibility =
      visibilityChanges?.find(change => change.id === item.id)?.visible ?? item.visible
    setIsVisible(accountVisibility)
  }, [item.id, item.visible, visibilityChanges])

  useEffect(() => {
    const autoSubscription =
      subscriptionChanges?.find(change => change.id === item.id)?.auto_subscribe ??
      item.auto_subscribe ??
      false
    setIsAutoSubscription(autoSubscription)
  }, [item.id, item.auto_subscribe, subscriptionChanges])

  return (
    <View as="div" padding={padding} borderWidth={`${showTopSeparator ? 'small' : '0'} 0 0 0`}>
      <Flex data-testid="flex-calendar-item" as="div" alignItems="center">
        <Flex.Item>
          <Checkbox
            label={
              <ScreenReaderContent>
                {I18n.t('Show account calendar for %{name}', {name: item.name})}
              </ScreenReaderContent>
            }
            data-testid={`account-calendar-checkbox-${item.name}`}
            inline={true}
            checked={isVisible}
            onChange={e => onAccountToggled(item.id, e.target.checked)}
          />
        </Flex.Item>
        <Flex.Item margin="0 small">
          <IconCalendarMonthLine width={CALENDAR_ICON_SIZE} height={CALENDAR_ICON_SIZE} />
        </Flex.Item>
        <Flex.Item>
          <Text data-testid="account-calendar-name">{item.name}</Text>
        </Flex.Item>
        <Flex.Item margin="0 0 0 auto">
          <SubscriptionsDropDown
            accountId={item.id}
            autoSubscription={isAutoSubscription}
            disabled={!isVisible}
            onChange={onAccountSubscriptionToggled}
            accountName={item.name}
          />
        </Flex.Item>
      </Flex>
    </View>
  )
}
