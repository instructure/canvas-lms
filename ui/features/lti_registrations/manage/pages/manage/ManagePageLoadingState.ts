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
import type {PaginatedList} from '../../api/PaginatedList'
import type {LtiRegistration} from '../../model/LtiRegistration'
import type {ManageSearchParams} from './ManageSearchParams'
import type {FetchRegistrations, DeleteRegistration} from '../../api/registrations'
import {useScope as useI18nScope} from '@canvas/i18n'
import {error} from '../../api/ApiResult'

export const MANAGE_EXTENSIONS_PAGE_LIMIT = 15

const I18n = useI18nScope('lti_registrations')

export type ManagePageLoadingState =
  | {
      _type: 'not_requested'
    }
  | {
      /**
       * Indicates that filters may have been changed (which makes
       * the current data stale), but a request to get fresh data
       * has not been made yet.
       */
      _type: 'stale'
      items?: PaginatedList<LtiRegistration>
    }
  | {
      /**
       * Indicates that a request is in flight.
       */
      _type: 'reloading'
      /**
       * A timestamp of the last time the data was requested,
       * to avoid race conditions
       */
      requested: number
      items?: PaginatedList<LtiRegistration>
    }
  | {
      /**
       * Indicates that data has been loaded, and data is up to date
       */
      _type: 'loaded'
      items: PaginatedList<LtiRegistration>
    }
  | {
      /**
       * Indicates that an error occurred while loading data
       */
      _type: 'error'
      message: string
    }

const LIMIT = 15

/**
 * Given a function that fetches registrations,
 * constructs a hook to manage state of the
 * registrations list. This is generalized over
 * that function to make it easier to test.
 * @param fetchRegistrations
 * @returns
 */
export const mkUseManagePageState =
  (apiFetchRegistrations: FetchRegistrations, apiDeleteRegistration: DeleteRegistration) =>
  (params: ManageSearchParams) => {
    const {q, sort, dir, page} = params
    const [state, setState] = React.useState<ManagePageLoadingState>({
      _type: 'not_requested',
    })

    // Using a ref ensures that the refresh closure called by deleteRegistration()
    // will have up-to-date search params, even if the search params changed since
    // the delete started
    // returns a promise that resolves once load is complete
    const refreshRef = React.useRef<() => void>()
    refreshRef.current = React.useCallback(() => {
      const requested = Date.now()
      setState(prev => ({
        _type: 'reloading',
        requested,
        items: 'items' in prev ? prev.items : undefined,
      }))

      return apiFetchRegistrations({
        sort,
        dir,
        query: q || '',
        offset: (page - 1) * LIMIT,
        limit: LIMIT,
      })
        .then(result => {
          setState(prev => {
            // Only apply the result if the request is still relevant
            if (prev._type === 'reloading' && requested === prev.requested) {
              return result._type === 'success'
                ? {
                    items: result.data,
                    _type: 'loaded',
                    lastRequested: requested,
                  }
                : result
            } else {
              return prev
            }
          })
        })
        .catch(() => {
          setState({
            _type: 'error',
            message: I18n.t(`Error retrieving registrations`),
          })
        })
    }, [sort, dir, q, page])

    // Refresh whenever search params (and thus refreshRef.current) change
    React.useEffect(() => {
      refreshRef.current?.()
      // eslint-disable-next-line react-hooks/exhaustive-deps
    }, [refreshRef.current])

    const setStale = React.useCallback(() => {
      setState(prev => {
        if (prev._type === 'loaded' || prev._type === 'stale' || prev._type === 'reloading') {
          return {
            _type: 'stale',
            items: prev.items,
          }
        } else {
          return {
            _type: 'stale',
          }
        }
      })
    }, [])

    /**
     * Deletes a registration and refreshes the list
     * @param registrationId
     * @returns Promise On error, the promise will resolve to an error result.
     */
    const deleteRegistration = React.useCallback(
      (registration: LtiRegistration) => {
        setStale()

        return apiDeleteRegistration(registration.id)
          .catch(() =>
            error(
              // TODO: log more info about the error? send to Sentry?
              // we could also consider returning the Error object, which
              // FlashAlert.findDetailMessage() expounds upon
              I18n.t('Error deleting app “%{appName}”', {appName: registration.name})
            )
          )
          .finally(() => refreshRef.current?.())
      },
      [setStale]
    )

    return [state, {setStale, deleteRegistration}] as const
  }
