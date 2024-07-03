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

import {debounce} from 'lodash'
import React from 'react'
import {AppsSearchBar} from './AppsSearchBar'

import GenericErrorPage from '@canvas/generic-error-page/react'
import {useScope as useI18nScope} from '@canvas/i18n'
import {confirmDanger} from '@canvas/instui-bindings/react/Confirm'
import errorShipUrl from '@canvas/images/ErrorShip.svg'
import {Flex} from '@instructure/ui-flex'
import {Pagination} from '@instructure/ui-pagination'
import {Spinner} from '@instructure/ui-spinner'
import {
  fetchRegistrations as apiFetchRegistrations,
  deleteRegistration as apiDeleteRegistration,
} from '../../api/registrations'
import {AppsTable} from './AppsTable'
import {MANAGE_APPS_PAGE_LIMIT, mkUseManagePageState} from './ManagePageLoadingState'
import {type ManageSearchParams, useManageSearchParams} from './ManageSearchParams'
import {formatSearchParamErrorMessages} from '../../../common/lib/useZodParams/ParamsParseResult'
import type {LtiRegistration} from '../../model/LtiRegistration'
import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'

const SEARCH_DEBOUNCE_MS = 250

const I18n = useI18nScope('lti_registrations')

export const ManagePage = () => {
  const [searchParams] = useManageSearchParams()
  return searchParams.success ? (
    <ManagePageInner searchParams={searchParams.value} />
  ) : (
    <GenericErrorPage
      imageUrl={errorShipUrl}
      errorMessage="Error parsing query"
      stack={`error parsing query:\n${formatSearchParamErrorMessages(searchParams.errors)}`}
      errorCategory="Dynamic Registration"
    />
  )
}

type ManagePageInnerProps = {
  searchParams: ManageSearchParams
}

const confirmDeletion = (registration: LtiRegistration): Promise<boolean> =>
  confirmDanger({
    title: I18n.t('Delete App'),
    confirmButtonLabel: I18n.t('Delete'),
    heading: I18n.t('You are about to delete “%{appName}”.', {appName: registration.name}),
    message: I18n.t(
      'You are removing the app from the entire account. It will be removed from its placements and any resource links to it will stop working. To reestablish placements and links, you will need to reinstall the app.'
    ),
  })

const useManagePageState = mkUseManagePageState(apiFetchRegistrations, apiDeleteRegistration)

export const ManagePageInner = (props: ManagePageInnerProps) => {
  const {sort, dir, page} = props.searchParams

  const [, setManageSearchParams] = useManageSearchParams()

  const [apps, {setStale, deleteRegistration}] = useManagePageState(props.searchParams)

  /**
   * Holds the state of the search input field
   */
  const [query, setQuery] = React.useState(props.searchParams.q ?? '')

  /**
   * Updates the query parameter in the URL,
   * which will trigger a reload of the data
   */
  const updateSearchParams = React.useCallback(
    (params: Partial<Record<keyof ManageSearchParams, string | undefined>>) => {
      setStale()
      setManageSearchParams(params)
    },
    [setStale, setManageSearchParams]
  )

  const deleteApp = React.useCallback(
    async (app: LtiRegistration) => {
      if (await confirmDeletion(app)) {
        const deleteResult = await deleteRegistration(app)
        const type = deleteResult._type === 'success' ? 'success' : 'error'
        showFlashAlert({
          type,
          message:
            deleteResult._type === 'success'
              ? I18n.t('There was an error deleting “%{appName}”', {appName: app.name})
              : I18n.t('App “%{appName}” successfully deleted', {appName: app.name}),
        })
      }
    },
    [deleteRegistration]
  )

  /**
   * A debounced version of {@link updateSearchParam}
   */
  const updateQueryParamDebounced = React.useCallback(
    debounce((q: string) => {
      updateSearchParams({q: q === '' ? undefined : q, page: undefined})
    }, SEARCH_DEBOUNCE_MS),
    [updateSearchParams]
  )

  const handleChange = React.useCallback(
    (event: React.ChangeEvent<HTMLInputElement>) => {
      setStale()
      const value = event.target.value
      setQuery(value)
      updateQueryParamDebounced(value)
    },
    [setStale, updateQueryParamDebounced]
  )

  const handleClear = React.useCallback(() => {
    setStale()
    setQuery('')
    updateSearchParams({q: undefined, page: undefined})
  }, [setStale, updateSearchParams])

  return (
    <div>
      <AppsSearchBar value={query} handleChange={handleChange} handleClear={handleClear} />
      {(() => {
        if (apps._type === 'error') {
          return (
            <GenericErrorPage
              imageUrl={errorShipUrl}
              errorSubject={I18n.t('LTI Registrations listing error')}
              error={apps.message}
            />
          )
        } else if ('items' in apps && typeof apps.items !== 'undefined') {
          return (
            <>
              <AppsTable
                stale={apps._type === 'reloading' || apps._type === 'stale'}
                apps={apps.items}
                sort={sort}
                dir={dir}
                updateSearchParams={updateSearchParams}
                deleteApp={deleteApp}
              />
              <Pagination
                as="nav"
                margin="small"
                variant="compact"
                labelNext={I18n.t('Next Page')}
                labelPrev={I18n.t('Previous Page')}
              >
                {Array.from(Array(Math.ceil(apps.items.total / MANAGE_APPS_PAGE_LIMIT))).map(
                  (_, i) => (
                    <Pagination.Page
                      // eslint-disable-next-line react/no-array-index-key
                      key={i}
                      current={i === page - 1}
                      onClick={() => {
                        setManageSearchParams({page: (i + 1).toString()})
                      }}
                    >
                      {i + 1}
                    </Pagination.Page>
                  )
                )}
              </Pagination>
            </>
          )
        } else {
          return (
            <Flex direction="column" alignItems="center" padding="large 0">
              <Spinner renderTitle="Loading" />
            </Flex>
          )
        }
      })()}
    </div>
  )
}
