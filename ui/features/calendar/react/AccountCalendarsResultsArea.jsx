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

import React, {useEffect} from 'react'
import {arrayOf, bool, func, number, shape, string} from 'prop-types'
import {IconButton} from '@instructure/ui-buttons'
import {Link} from '@instructure/ui-link'
import {View} from '@instructure/ui-view'
import {Text} from '@instructure/ui-text'
import {List} from '@instructure/ui-list'
import {Spinner} from '@instructure/ui-spinner'
import {Tooltip} from '@instructure/ui-tooltip'
import {IconCalendarMonthLine, IconQuestionLine} from '@instructure/ui-icons'
import {Flex} from '@instructure/ui-flex'
import {Checkbox} from '@instructure/ui-checkbox'
import SVGWrapper from '@canvas/svg-wrapper'
import {useScope as useI18nScope} from '@canvas/i18n'
import {alertForMatchingAccounts} from '@canvas/calendar/AccountCalendarsUtils'

const I18n = useI18nScope('account_calendars_results_area')

const accountCalendarsType = arrayOf(
  shape({
    id: string.isRequired,
    name: string.isRequired,
    asset_string: string.isRequired,
    type: string.isRequired,
  })
)

const AccountCalendarResultsArea = ({
  searchTerm,
  results,
  totalAccounts,
  isLoading,
  loadNextPage,
  selectedCalendars,
  setSelectedCalendars,
}) => {
  useEffect(() => {
    if (!isLoading && results?.length >= 0) {
      alertForMatchingAccounts(results?.length, searchTerm === '')
    }
  }, [isLoading, searchTerm, results])

  if (isLoading) {
    return (
      <View as="div" textAlign="center">
        <Spinner
          size="large"
          renderTitle={I18n.t('Waiting for results to load')}
          margin="large small"
        />
      </View>
    )
  }
  if (typeof results === 'undefined') return null
  if (results.length === 0)
    return (
      <View as="div" data-testid="account-calendars-empty-state">
        <View as="div" textAlign="center" margin="medium none">
          <SVGWrapper url="/images/account_calendars_empty_state.svg" />
        </View>
        <View as="div" textAlign="center">
          <Text as="div" size="large">
            {I18n.t('Hmm, we can’t find any matching calendars.')}
          </Text>
          <View as="div" margin="x-small none x-large none">
            <Text as="div">{I18n.t('Check your spelling or try fewer letters.')}</Text>
          </View>
        </View>
      </View>
    )

  const onCalendarSelected = accountCalendarId => {
    const isSelected = !!selectedCalendars.find(sC => sC.id === accountCalendarId)
    const selectedCalendar = results.find(r => r.id === accountCalendarId)

    if (!isSelected) {
      setSelectedCalendars([...selectedCalendars, selectedCalendar])
    } else {
      setSelectedCalendars(selectedCalendars.filter(calendar => calendar.id !== accountCalendarId))
    }
  }

  return (
    <View as="div">
      {!searchTerm ? (
        <View as="div" margin="medium none none">
          <Text weight="bold">{I18n.t('Calendars')}</Text>
        </View>
      ) : (
        <View as="div" margin="medium none none">
          {`${totalAccounts} ${
            totalAccounts === 1 ? I18n.t('result for ') : I18n.t('results for ')
          }`}
          <Text weight="bold">{searchTerm}</Text>
        </View>
      )}
      <List data-testid="account-calendars-list" isUnstyled={true} margin="small none">
        {results.map(r => (
          <List.Item key={r.id}>
            <View
              as="div"
              borderWidth="none none small"
              themeOverride={{borderColorPrimary: '#e6e6e6'}}
            >
              <Flex margin="small 0">
                <Flex.Item margin="0 small">
                  <Checkbox
                    data-testid={`account-${r.id}-checkbox`}
                    checked={!!selectedCalendars.find(sC => sC.id === r.id)}
                    disabled={r.auto_subscribe}
                    label=""
                    title={`${r.name} ${I18n.t('account')}`}
                    value={r.id}
                    onChange={e => onCalendarSelected(e.target.value)}
                  />
                </Flex.Item>
                <Flex.Item margin="0 xx-small xx-small 0">
                  <IconCalendarMonthLine />
                </Flex.Item>
                <Flex.Item shouldGrow={true}>
                  <Text>{r.name}</Text>{' '}
                </Flex.Item>
                {r.auto_subscribe && (
                  <Flex.Item textAlign="end">
                    <Tooltip
                      renderTip={I18n.t('Calendars added by the admin cannot be removed')}
                      on={['click', 'focus', 'hover']}
                    >
                      <IconButton
                        renderIcon={IconQuestionLine}
                        screenReaderLabel={I18n.t('help')}
                        size="small"
                        withBackground={false}
                        withBorder={false}
                      />
                    </Tooltip>
                  </Flex.Item>
                )}
              </Flex>
            </View>
          </List.Item>
        ))}
      </List>
      {results.length < totalAccounts && (
        <View as="div" textAlign="center" padding="small none none">
          <Link isWithinText={false} onClick={loadNextPage}>
            {I18n.t('Show more')}
          </Link>
        </View>
      )}
    </View>
  )
}

AccountCalendarResultsArea.propTypes = {
  results: accountCalendarsType,
  searchTerm: string,
  totalAccounts: number,
  isLoading: bool.isRequired,
  loadNextPage: func.isRequired,
  selectedCalendars: accountCalendarsType,
  setSelectedCalendars: func.isRequired,
}

export default AccountCalendarResultsArea
