/*
 * Copyright (C) 2019 - present Instructure, Inc.
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

import React, {useReducer, useCallback} from 'react'
import {useScope as useI18nScope} from '@canvas/i18n'
import {Heading} from '@instructure/ui-heading'
import {Spinner} from '@instructure/ui-spinner'
import {Alert} from '@instructure/ui-alerts'
import {CloseButton} from '@instructure/ui-buttons'
import {View} from '@instructure/ui-view'
import useFetchApi from '@canvas/use-fetch-api-hook'
import ViolationTable from './ViolationTable'

const I18n = useI18nScope('csp_violation_tray')

const violationsReducer = (state, action) => {
  switch (action.type) {
    case 'FETCH_INIT':
      return {...state, isLoading: action.payload}
    case 'FETCH_SUCCESS':
      return {...state, isLoading: false, violations: action.payload, isError: false}
    case 'FETCH_ERROR':
      return {...state, isLoading: false, error: action.payload, isError: true}
    default:
      throw new Error('Reducer was called with an invalid action')
  }
}

export default function ViolationTray({handleClose, accountId, addDomain, whitelistedDomains}) {
  const [state, dispatch] = useReducer(violationsReducer, {
    isLoading: true,
    isError: false,
    violations: [],
    error: null,
  })

  useFetchApi({
    path: `/api/v1/accounts/${accountId}/csp_log`,
    success: useCallback(response => {
      dispatch({type: 'FETCH_SUCCESS', payload: response})
    }, []),
    error: useCallback(error => dispatch({type: 'FETCH_ERROR', payload: error}), []),
    loading: useCallback(loading => dispatch({type: 'FETCH_INIT', payload: loading}), []),
  })

  return (
    <>
      <CloseButton
        placement="start"
        offset="none"
        onClick={handleClose}
        screenReaderLabel={I18n.t('Close')}
      />
      <View as="div" padding="large x-small">
        <Heading level="h3" as="h2">
          {I18n.t('Violation Log')}
        </Heading>
        <View as="div" padding="large x-small">
          {state.isLoading && <Spinner renderTitle={() => I18n.t('Loading')} />}
          {state.isError && (
            <Alert variant="error" margin="small">
              {I18n.t('Something went wrong loading the violations. Try reloading the page.')}
            </Alert>
          )}
          {!state.isLoading && !state.isError && state.violations.length === 0 && (
            <Alert variant="info" margin="small">
              {I18n.t('No violations have been reported.')}
            </Alert>
          )}
          {!state.isLoading && !state.isError && state.violations.length > 0 && (
            <ViolationTable
              violations={state.violations}
              whitelistedDomains={whitelistedDomains}
              addDomain={addDomain}
              accountId={accountId}
            />
          )}
        </View>
      </View>
    </>
  )
}
