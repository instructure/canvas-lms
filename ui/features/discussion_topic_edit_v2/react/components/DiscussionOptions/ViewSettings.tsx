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

import React from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'

import {Checkbox} from '@instructure/ui-checkbox'
import {FormFieldGroup} from '@instructure/ui-form-field'
import {Heading} from '@instructure/ui-heading'
import {RadioInput, RadioInputGroup} from '@instructure/ui-radio-input'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
import {IconInfoLine} from '@instructure/ui-icons'
import {Tooltip} from '@instructure/ui-tooltip'
import {IconButton} from '@instructure/ui-buttons'

const I18n = createI18nScope('discussion_create')

type Props = {
  expanded: boolean
  expandedLocked: boolean
  sortOrder: string
  sortOrderLocked: boolean
  setExpanded: (value: boolean) => void
  setExpandedLocked: (value: boolean) => void
  setSortOrder: (value: string) => void
  setSortOrderLocked: (value: boolean) => void
}

export const ViewSettings = ({
  expanded,
  expandedLocked,
  sortOrder,
  sortOrderLocked,
  setExpanded,
  setExpandedLocked,
  setSortOrder,
  setSortOrderLocked,
}: Props) => {
  const infoToolTipSortOrder = I18n.t(
    "This setting defines the initial sort order. Students can set their preference. After they change it, future default updates won't alter their settings unless locked.",
  )
  const infoToolTipExpand = I18n.t(
    "This setting defines the initial thread state. Students can set their preference. After they change it, future default updates won't alter their settings unless locked.",
  )

  return (
    <View display="block" margin="medium 0" data-testid="discussion-view-settings">
      <Text size="large" as="h2">
        {I18n.t('View')}
      </Text>
      {ENV.DISCUSSION_DEFAULT_EXPAND_ENABLED && (
        <View display="block" margin="small 0 medium">
          <RadioInputGroup
            name="expanded"
            description={
              <>
                <View display="inline-block">
                  <Heading level="h4">{I18n.t('Default Thread State')}</Heading>
                </View>
                <Tooltip renderTip={infoToolTipExpand} on={['hover', 'focus']} color="primary">
                  <IconButton
                    renderIcon={IconInfoLine}
                    withBackground={false}
                    withBorder={false}
                    color="primary"
                    size="small"
                    cursor="default"
                    screenReaderLabel={infoToolTipExpand}
                  />
                </Tooltip>
              </>
            }
            value={expanded + ''}
            onChange={(_event, value) => {
              setExpanded(value === 'true')
              if (value !== 'true') {
                setExpandedLocked(false)
              }
            }}
            data-testid="view-default-thread-state"
          >
            <RadioInput
              key="expanded"
              value="true"
              label={I18n.t('Expanded')}
              data-testid="view-default-thread-state-expanded"
            />
            <RadioInput
              key="collapsed"
              value="false"
              label={I18n.t('Collapsed')}
              data-testid="view-default-thread-state-collapsed"
            />
          </RadioInputGroup>
          <FormFieldGroup description="" rowSpacing="small">
            <View display="block" margin="small 0 0 0">
              <Checkbox
                label={I18n.t('Lock thread state for students')}
                value="expandedLocked"
                inline={true}
                checked={expandedLocked}
                onChange={() => {
                  setExpandedLocked(!expandedLocked)
                }}
                disabled={!expanded}
                data-testid="view-expanded-locked"
                data-action-state={expandedLocked ? 'unlockExpandedState' : 'lockExpandedState'}
              />
            </View>
          </FormFieldGroup>
        </View>
      )}
      {ENV.DISCUSSION_DEFAULT_SORT_ENABLED && (
        <View display="block" margin="medium 0">
          <RadioInputGroup
            name="sortOrder"
            description={
              <>
                <View display="inline-block">
                  <Heading level="h4">{I18n.t('Default Sort Order')}</Heading>
                </View>
                <Tooltip renderTip={infoToolTipSortOrder} on={['hover', 'focus']} color="primary">
                  <IconButton
                    renderIcon={IconInfoLine}
                    withBackground={false}
                    withBorder={false}
                    color="primary"
                    size="small"
                    cursor="default"
                    screenReaderLabel={infoToolTipSortOrder}
                  />
                </Tooltip>
              </>
            }
            value={sortOrder}
            onChange={(_event, value) => {
              setSortOrder(value)
            }}
            data-testid="view-default-sort-order"
          >
            <RadioInput key="asc" value="asc" label={I18n.t('Oldest First')} />
            <RadioInput key="desc" value="desc" label={I18n.t('Newest First')} />
          </RadioInputGroup>
          <FormFieldGroup description="" rowSpacing="small">
            <View display="block" margin="small 0 0 0">
              <Checkbox
                label={I18n.t('Lock sort order for students')}
                value="sortOrderLocked"
                inline={true}
                checked={sortOrderLocked}
                onChange={() => {
                  setSortOrderLocked(!sortOrderLocked)
                }}
                disabled={
                  false // Could be disabled, if the Discussion Topic author is Student
                }
                data-testid="view-sort-order-locked"
                data-action-state={sortOrderLocked ? 'unlockSortOrder' : 'lockSortOrder'}
              />
            </View>
          </FormFieldGroup>
        </View>
      )}
    </View>
  )
}
