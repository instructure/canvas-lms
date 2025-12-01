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

import {debounce} from 'es-toolkit/compat'
import React from 'react'
import {AppsSearchBar} from './AppsSearchBar'

import GenericErrorPage from '@canvas/generic-error-page/react'
import {useScope as createI18nScope} from '@canvas/i18n'
import errorShipUrl from '@canvas/images/ErrorShip.svg'
import {Flex} from '@instructure/ui-flex'
import {Spinner} from '@instructure/ui-spinner'
import {formatSearchParamErrorMessages} from '../../../common/lib/useZodParams/ParamsParseResult'
import type {AccountId} from '../../model/AccountId'
import {AppsTable} from './AppsTable'
import {type ManageSearchParams, useManageSearchParams} from './ManageSearchParams'
import {useApps} from '../../api/registrations'
import {getAccountId} from '../../../common/lib/getAccountId'

const SEARCH_DEBOUNCE_MS = 250

const I18n = createI18nScope('lti_registrations')

export const ManagePage = () => {
  const accountId = getAccountId()
  const [searchParams] = useManageSearchParams()

  return searchParams.success ? (
    <ManagePageInner searchParams={searchParams.value} accountId={accountId} />
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
  accountId: AccountId
  searchParams: ManageSearchParams
}

export const ManagePageInner = (props: ManagePageInnerProps) => {
  const {sort, dir, page} = props.searchParams

  const [, setManageSearchParams] = useManageSearchParams()

  /**
   * Holds the state of the search input field
   */
  const [query, setQuery] = React.useState(props.searchParams.q ?? '')

  const result = useApps({
    query: props.searchParams.q ?? '',
    accountId: props.accountId,
    ...props.searchParams,
  })

  /**
   * Updates the query parameter in the URL,
   * which will trigger a reload of the data
   */
  const updateSearchParams = React.useCallback(
    (params: Partial<Record<keyof ManageSearchParams, string | undefined>>) => {
      setManageSearchParams(params)
    },
    [setManageSearchParams],
  )

  /**
   * A debounced version of {@link updateSearchParam}
   */
  const updateQueryParamDebounced = React.useCallback(
    debounce((q: string) => {
      updateSearchParams({q: q === '' ? undefined : q, page: undefined})
    }, SEARCH_DEBOUNCE_MS),
    [updateSearchParams],
  )

  const handleChange = React.useCallback(
    (event: React.ChangeEvent<HTMLInputElement>) => {
      const value = event.target.value
      setQuery(value)
      updateQueryParamDebounced(value)
    },
    [updateQueryParamDebounced],
  )

  const handleClear = React.useCallback(() => {
    setQuery('')
    updateSearchParams({q: undefined, page: undefined})
  }, [updateSearchParams])

  return (
    <div>
      <AppsSearchBar value={query} handleChange={handleChange} handleClear={handleClear} />
      {(() => {
        if (result.isError) {
          return (
            <GenericErrorPage
              imageUrl={errorShipUrl}
              errorSubject={I18n.t('LTI Registrations listing error')}
              errorMessage={result.error.message}
            />
          )
        } else if (result.isSuccess) {
          return (
            <>
              <AppsTable
                stale={result.isRefetching || query !== (props.searchParams.q || '')}
                apps={result.data.json}
                sort={sort}
                dir={dir}
                updateSearchParams={updateSearchParams}
                page={page}
                accountId={props.accountId}
              />
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
