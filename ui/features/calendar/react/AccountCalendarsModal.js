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

import React, {useState, useEffect, useMemo} from 'react'
import {func, number} from 'prop-types'
import {Link} from '@instructure/ui-link'
import {View} from '@instructure/ui-view'
import {Button, CloseButton} from '@instructure/ui-buttons'
import {IconSearchLine, IconPlusLine} from '@instructure/ui-icons'
import {Modal} from '@instructure/ui-modal'
import {Heading} from '@instructure/ui-heading'
import {TextInput} from '@instructure/ui-text-input'
import doFetchApi from '@canvas/do-fetch-api-effect'
import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'
import {debounce} from 'lodash'

import AccountCalendarResultsArea from './AccountCalendarsResultsArea'
import {useScope as useI18nScope} from '@canvas/i18n'

const I18n = useI18nScope('account_calendars_modal')

const TYPING_DEBOUNCE = 500
const MIN_SEARCH_LENGTH = 3
export const SEARCH_ENDPOINT = '/api/v1/account_calendars'
export const SAVE_PREFERENCES_ENDPOINT = '/api/v1/calendar_events/save_enabled_account_calendars'

const getLiveRegion = () => document.getElementById('flash_screenreader_holder')

const AccountCalendarsModal = ({getSelectedOtherCalendars, onSave, calendarsPerRequest = 100}) => {
  const [searchTerm, setSearchTerm] = useState('')
  const [isOpen, setIsOpen] = useState(false)
  const [isLoading, setIsLoading] = useState(false)
  const [results, setResults] = useState(undefined)
  const [nextPage, setNextPage] = useState(null)
  const [totalAccounts, setTotalAccounts] = useState(null)
  const [selectedCalendars, setSelectedCalendars] = useState(getSelectedOtherCalendars())
  const loadNextPage = () => fetchAccounts({next: true})
  const resultsProps = {
    searchTerm,
    results,
    totalAccounts,
    isLoading,
    loadNextPage,
    selectedCalendars,
    setSelectedCalendars
  }
  let messages = null
  const modalHeight = '500px'

  const updateSearchTerm = useMemo(
    () =>
      debounce(v => {
        setSearchTerm(v)
      }, TYPING_DEBOUNCE),
    []
  )

  if (searchTerm.length < MIN_SEARCH_LENGTH) {
    messages = [
      {
        type: 'hint',
        text: I18n.t('Type at least %{number} characters to search', {
          number: MIN_SEARCH_LENGTH
        })
      }
    ]
  }

  useEffect(() => {
    if (isOpen) setSelectedCalendars(getSelectedOtherCalendars())
  }, [getSelectedOtherCalendars, isOpen])

  useEffect(() => {
    fetchAccounts({next: false})
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [searchTerm])

  const closeModal = () => {
    setSearchTerm('')
    setIsOpen(false)
  }

  const fetchAccounts = async ({next}) => {
    try {
      setIsLoading(true)
      const apiParams = {per_page: calendarsPerRequest}
      if (searchTerm) {
        apiParams.search_term = searchTerm
      }
      if (next && nextPage) {
        apiParams.page = nextPage
      }
      const {json, link} = await doFetchApi({
        path: SEARCH_ENDPOINT,
        params: apiParams
      })
      const newResults = next ? [...results, ...json.account_calendars] : json.account_calendars

      setResults(newResults)
      setNextPage(link?.next?.page)
      setTotalAccounts(json.total_results)
    } catch (err) {
      showFlashAlert({
        message: I18n.t('An error occurred while searching accounts calendars'),
        err
      })
    } finally {
      setIsLoading(false)
    }
  }

  const updateSearch = e => {
    if (e.target.value.length < MIN_SEARCH_LENGTH) {
      updateSearchTerm.cancel()
      setSearchTerm('')
      return
    }
    updateSearchTerm(e.target.value)
  }

  const onSubmit = async () => {
    const payload = {
      enabled_account_calendars:
        selectedCalendars.length > 0 ? selectedCalendars.map(sC => sC.id) : ''
    }
    try {
      const {json} = await doFetchApi({
        path: SAVE_PREFERENCES_ENDPOINT,
        params: payload,
        method: 'POST'
      })
      if (json.status === 'ok') {
        showFlashAlert({
          type: 'success',
          message: I18n.t('Calendars added successfully')
        })
      }
      onSave(selectedCalendars)
      closeModal()
    } catch (err) {
      showFlashAlert({
        err,
        message: I18n.t('An error occurred while saving changes')
      })
    }
  }

  return (
    <>
      <View as="div" padding="small x-small 0 x-small">
        <Link
          data-testid="add-other-calendars-button"
          onClick={() => setIsOpen(true)}
          theme={{color: 'black', hoverColor: 'black'}}
        >
          <IconPlusLine title={I18n.t('Add other calendar')} />
        </Link>
      </View>
      <Modal
        liveRegion={getLiveRegion}
        size="small"
        onDismiss={closeModal}
        open={isOpen}
        label={I18n.t('Add Calendar')}
        theme={{smallMaxWidth: '34rem'}}
      >
        <Modal.Header>
          <CloseButton
            data-testid="header-close-button"
            placement="end"
            offset="medium"
            onClick={closeModal}
            screenReaderLabel={I18n.t('Close')}
          />
          <Heading>{I18n.t('Add Calendar')}</Heading>
        </Modal.Header>
        <Modal.Body padding="none">
          <View as="div" margin="small medium">
            {I18n.t('Choose additional calendars to add to your Canvas calendar.')}
          </View>
          <View as="div" margin="small medium medium" maxHeight={modalHeight}>
            <TextInput
              data-testid="search-input"
              type="search"
              theme={{borderRadius: '2rem'}}
              placeholder={I18n.t('Search %{totalAccounts} calendars', {
                totalAccounts
              })}
              onChange={updateSearch}
              messages={messages}
              renderBeforeInput={<IconSearchLine inline={false} />}
            />
            <AccountCalendarResultsArea {...resultsProps} />
          </View>
        </Modal.Body>
        <Modal.Footer>
          <Button data-testid="footer-close-button" onClick={closeModal}>
            {I18n.t('Cancel')}
          </Button>
          <Button
            data-testid="save-calendars-button"
            variant="primary"
            margin="none none none small"
            onClick={onSubmit}
          >
            {I18n.t('Add Calendars')}
          </Button>
        </Modal.Footer>
      </Modal>
    </>
  )
}

AccountCalendarsModal.propTypes = {
  getSelectedOtherCalendars: func.isRequired,
  onSave: func.isRequired,
  calendarsPerRequest: number
}

export default AccountCalendarsModal
