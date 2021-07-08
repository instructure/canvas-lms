/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

import React, {useState, useCallback, useMemo} from 'react'
import PropTypes from 'prop-types'
import I18n from 'i18n!important_dates'
import moment from 'moment-timezone'

import {View} from '@instructure/ui-view'
import {Heading} from '@instructure/ui-heading'
import {PresentationContent} from '@instructure/ui-a11y-content'
import {Flex} from '@instructure/ui-flex'
import {CloseButton} from '@instructure/ui-buttons'

import useFetchApi from '@canvas/use-fetch-api-hook'
import {showFlashError} from '@canvas/alerts/react/FlashAlert'
import LoadingSkeleton from '@canvas/k5/react/LoadingSkeleton'
import LoadingWrapper from '@canvas/k5/react/LoadingWrapper'
import ImportantDatesEmpty from './ImportantDatesEmpty'
import ImportantDateSection from './ImportantDateSection'
import {groupImportantDates} from '@canvas/k5/react/utils'

const ImportantDates = ({timeZone, contextCodes, handleClose}) => {
  const [loadingAssignments, setLoadingAssignments] = useState(true)
  const [loadingEvents, setLoadingEvents] = useState(true)
  const [assignments, setAssignments] = useState([])
  const [events, setEvents] = useState([])

  const fetchPath = '/api/v1/calendar_events'
  const fetchParams = {
    important_dates: true,
    context_codes: contextCodes,
    start_date: useCallback(() => moment().tz(timeZone).startOf('day').toISOString(), [timeZone]),
    end_date: useCallback(() => moment().tz(timeZone).add(2, 'years').toISOString(), [timeZone])
  }

  useFetchApi({
    path: fetchPath,
    success: setAssignments,
    error: useCallback(
      showFlashError(I18n.t('Failed to load assignments in important dates.')),
      []
    ),
    loading: setLoadingAssignments,
    params: {
      type: 'assignment',
      ...fetchParams
    },
    forceResult: contextCodes?.length ? undefined : []
  })

  useFetchApi({
    path: fetchPath,
    success: setEvents,
    error: useCallback(showFlashError(I18n.t('Failed to load events in important dates.')), []),
    loading: setLoadingEvents,
    params: {
      type: 'event',
      ...fetchParams
    },
    forceResult: contextCodes?.length ? undefined : []
  })

  const datesSkeleton = () => (
    <div>
      <LoadingSkeleton
        id="skeleton-date"
        screenReaderLabel={I18n.t('Loading Important Date')}
        height="1rem"
        width="75%"
        margin="medium 0 x-small"
      />
      <LoadingSkeleton
        id="skeleton-details"
        screenReaderLabel={I18n.t('Loading Important Date Details')}
        height="4rem"
        width="100%"
        margin="x-small 0"
      />
    </div>
  )

  const dates = useMemo(
    () => groupImportantDates(assignments, events, timeZone),
    [assignments, events, timeZone]
  )

  return (
    <View as="div" padding="medium">
      <Flex margin="small 0" alignItems="center" justifyItems="space-between">
        <Flex.Item>
          <Heading as="h3" level="h4">
            {I18n.t('Important Dates')}
          </Heading>
        </Flex.Item>
        {handleClose && (
          <Flex.Item>
            <CloseButton screenReaderLabel={I18n.t('Hide Important Dates')} onClick={handleClose} />
          </Flex.Item>
        )}
      </Flex>
      <PresentationContent>
        <hr
          style={{
            margin: 0
          }}
        />
      </PresentationContent>
      <LoadingWrapper
        id="important-dates-skeleton"
        isLoading={contextCodes == null || loadingAssignments || loadingEvents}
        renderCustomSkeleton={datesSkeleton}
        skeletonsCount={3}
      >
        {dates?.length ? (
          dates.map(date => (
            <ImportantDateSection
              key={`important-date-${date.date}`}
              timeZone={timeZone}
              {...date}
            />
          ))
        ) : (
          <ImportantDatesEmpty />
        )}
      </LoadingWrapper>
    </View>
  )
}

ImportantDates.propTypes = {
  timeZone: PropTypes.string.isRequired,
  contextCodes: PropTypes.arrayOf(PropTypes.string),
  handleClose: PropTypes.func
}

export default ImportantDates
