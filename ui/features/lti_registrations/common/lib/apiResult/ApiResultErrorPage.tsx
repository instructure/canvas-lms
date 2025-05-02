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

import * as React from 'react'
import {formatApiResultError, UnsuccessfulApiResult} from './ApiResult'
import GenericErrorPage from '@canvas/generic-error-page/react'
import errorShipUrl from '@canvas/images/ErrorShip.svg'

type ApiResultErrorPageProps = {
  error: UnsuccessfulApiResult
  errorSubject?: string
}

/**
 * A helper component to display an error page for an API result.
 * @returns
 */
export const ApiResultErrorPage = ({error, errorSubject}: ApiResultErrorPageProps) => {
  return (
    <GenericErrorPage
      imageUrl={errorShipUrl}
      errorSubject={errorSubject}
      errorMessage={formatApiResultError(error)}
    />
  )
}
