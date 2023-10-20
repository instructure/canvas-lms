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

import React, {useCallback, useEffect, useMemo, useState, useRef} from 'react'
import PropTypes from 'prop-types'
import {useScope as useI18nScope} from '@canvas/i18n'
import moment from 'moment-timezone'

import {View} from '@instructure/ui-view'
import {Flex} from '@instructure/ui-flex'
import {Heading} from '@instructure/ui-heading'
import {IconButton, CloseButton} from '@instructure/ui-buttons'
import {IconSettingsLine} from '@instructure/ui-icons'
import {PresentationContent} from '@instructure/ui-a11y-content'

import useFetchApi from '@canvas/use-fetch-api-hook'
import {showFlashError} from '@canvas/alerts/react/FlashAlert'
import LoadingSkeleton from '@canvas/k5/react/LoadingSkeleton'
import LoadingWrapper from '@canvas/k5/react/LoadingWrapper'
import FilterCalendarsModal, {ImportantDatesContextsShape} from './FilterCalendarsModal'
import ImportantDatesEmpty from './ImportantDatesEmpty'
import ImportantDateSection from './ImportantDateSection'
import {groupImportantDates} from '@canvas/k5/react/utils'
import _ from 'lodash'

const I18n = useI18nScope('important_dates')

const ImportantDates = ({
  contexts,
  handleClose,
  selectedContextCodes: initialSelectedContextCodes,
  selectedContextsLimit,
  timeZone,
  observedUserId,
}) => {
  const [calendarsModalOpen, setCalendarsModalOpen] = useState(false)
  const [loadingAssignments, setLoadingAssignments] = useState(true)
  const [loadingEvents, setLoadingEvents] = useState(true)
  const [assignments, setAssignments] = useState([])
  const [events, setEvents] = useState([])
  const [selectedContextCodes, setSelectedContextCodes] = useState(null)
  const previousContextsRef = useRef(null)
  const [fetchEventsPath, setFetchEventsPath] = useState('/api/v1/calendar_events')
  const observerMode = !!observedUserId
  const isObservingUser = observerMode && observedUserId !== ENV.current_user_id

  useEffect(() => {
    // Only run this effect the first time we load contexts or if the user
    // is in observer mode and the contexts have changed
    if (
      contexts &&
      (!previousContextsRef.current ||
        (observerMode && !_.isEqual(previousContextsRef.current, contexts)))
    ) {
      previousContextsRef.current = contexts
      // If the user has no selected contexts saved already, default them to the first X contexts
      // as defined by the `calendar_contexts_limit` setting once the cards have loaded
      const defaultSelected = contexts.slice(0, selectedContextsLimit).map(c => c.assetString)
      // Make sure that we only include K-5 subject courses from `contexts` in the
      // `selectedContextCodes` we pass to the FilterCalendarsModal
      const savedSelected = initialSelectedContextCodes?.filter(code =>
        contexts.some(c => c.assetString === code)
      )
      const contextCodes = savedSelected?.length ? savedSelected : defaultSelected
      setSelectedContextCodes(contextCodes)
      // Calendar events are requested every time that the observedUserId and selectedContextCodes
      // change, so let's use this effect to also calculate the events request path and avoid
      // duplicated requests
      const fetchPath = isObservingUser
        ? `/api/v1/users/${observedUserId}/calendar_events`
        : '/api/v1/calendar_events'
      setFetchEventsPath(fetchPath)
      if (contextCodes?.length === 0) {
        // useFetchApi does not execute the loading callback if the result is forced
        // so, we need to stop the loading effect manually when there are no contexts
        setLoadingAssignments(false)
        setLoadingEvents(false)
      }
    }
  }, [
    contexts,
    initialSelectedContextCodes,
    isObservingUser,
    observedUserId,
    observerMode,
    selectedContextsLimit,
  ])

  const contextsLoaded = !!contexts && !!selectedContextCodes
  const tooManyContexts =
    !isObservingUser && contextsLoaded && contexts.length > selectedContextsLimit

  const fetchParams = {
    important_dates: true,
    context_codes: [...(selectedContextCodes || [])], // need to clone this list so the fetchApi effect will trigger on change
    start_date: useCallback(() => moment().tz(timeZone).startOf('day').toISOString(), [timeZone]),
    end_date: useCallback(() => moment().tz(timeZone).add(2, 'years').toISOString(), [timeZone]),
    per_page: 100,
  }

  useFetchApi({
    path: fetchEventsPath,
    success: setAssignments,
    error: useCallback(
      showFlashError(I18n.t('Failed to load assignments in important dates.')),
      []
    ),
    loading: setLoadingAssignments,
    params: {
      type: 'assignment',
      ...fetchParams,
    },
    forceResult: selectedContextCodes?.length ? undefined : [],
  })

  useFetchApi({
    path: fetchEventsPath,
    success: setEvents,
    error: useCallback(showFlashError(I18n.t('Failed to load events in important dates.')), []),
    loading: setLoadingEvents,
    params: {
      type: 'event',
      ...fetchParams,
    },
    forceResult: selectedContextCodes?.length ? undefined : [],
  })

  const closeCalendarsModal = () => setCalendarsModalOpen(false)

  const datesSkeleton = props => (
    <div {...props}>
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
    <>
      <View as="div" padding="medium">
        <Flex margin="small 0" alignItems="center">
          <Flex.Item shouldGrow={true} shouldShrink={true}>
            <Heading as="h2" level="h4" margin="small 0">
              {I18n.t('Important Dates')}
            </Heading>
          </Flex.Item>
          {tooManyContexts && (
            <Flex.Item>
              <IconButton
                data-testid="filter-important-dates-button"
                screenReaderLabel={I18n.t('Select calendars to retrieve important dates from')}
                withBackground={false}
                withBorder={false}
                size="small"
                onClick={() => setCalendarsModalOpen(true)}
                interaction={contextsLoaded ? 'enabled' : 'disabled'}
              >
                <IconSettingsLine />
              </IconButton>
            </Flex.Item>
          )}
          {handleClose && (
            <Flex.Item margin="0 0 0 small">
              <CloseButton
                screenReaderLabel={I18n.t('Hide Important Dates')}
                onClick={handleClose}
              />
            </Flex.Item>
          )}
        </Flex>
        <PresentationContent>
          <hr
            style={{
              margin: 0,
            }}
          />
        </PresentationContent>
        <LoadingWrapper
          id="important-dates-skeleton"
          isLoading={!selectedContextCodes || loadingAssignments || loadingEvents}
          renderCustomSkeleton={datesSkeleton}
          skeletonsNum={dates?.length}
          defaultSkeletonsNum={3}
          allowZeroSkeletons={false}
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
      {contextsLoaded && tooManyContexts && (
        <FilterCalendarsModal
          contexts={contexts}
          selectedContextCodes={selectedContextCodes}
          selectedContextsLimit={selectedContextsLimit}
          isOpen={calendarsModalOpen}
          closeModal={closeCalendarsModal}
          updateSelectedContextCodes={setSelectedContextCodes}
        />
      )}
    </>
  )
}

ImportantDates.propTypes = {
  contexts: PropTypes.arrayOf(ImportantDatesContextsShape),
  handleClose: PropTypes.func,
  selectedContextCodes: PropTypes.arrayOf(PropTypes.string),
  selectedContextsLimit: PropTypes.number.isRequired,
  timeZone: PropTypes.string.isRequired,
  observedUserId: PropTypes.string,
}

export default ImportantDates
