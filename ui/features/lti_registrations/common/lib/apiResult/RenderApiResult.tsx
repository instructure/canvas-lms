/*
 * Copyright (C) 2025 - present Instructure, Inc.
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

import {UseQueryResult} from '@tanstack/react-query'
import {ApiResult, exception, isUnsuccessful, UnsuccessfulApiResult} from './ApiResult'
import {ReactElement} from 'react'
import {ApiResultErrorPage} from './ApiResultErrorPage'
import {Flex} from '@instructure/ui-flex'
import {Spinner} from '@instructure/ui-spinner'

import {useScope as createI18nScope} from '@canvas/i18n'
const I18n = createI18nScope('lti_registrations')

export type RenderApiResultProps<A> = {
  query: UseQueryResult<ApiResult<A>>
  onError?: (error: UnsuccessfulApiResult) => JSX.Element
  onInitialLoading?: () => JSX.Element
  onSuccess: (params: {data: A; refetching: boolean}) => JSX.Element
}

const renderError = (
  error: UnsuccessfulApiResult,
  onError?: (error: UnsuccessfulApiResult) => ReactElement,
) => {
  if (onError) {
    return onError(error)
  } else {
    return <ApiResultErrorPage error={error} />
  }
}

export const RenderApiResult = <A,>(props: RenderApiResultProps<A>) => {
  if (props.query.isError) {
    // This was an exception not caught by the ApiResult function
    return renderError(exception(props.query.error), props.onError)
  } else if (props.query.data) {
    return isUnsuccessful(props.query.data)
      ? renderError(props.query.data, props.onError)
      : props.onSuccess({
          data: props.query.data.data,
          refetching: props.query.isRefetching,
        })
  } else {
    return props.onInitialLoading ? (
      props.onInitialLoading()
    ) : (
      <Flex direction="column" alignItems="center" padding="large 0">
        <Spinner renderTitle={I18n.t('Loading')} />{' '}
      </Flex>
    )
  }
}
