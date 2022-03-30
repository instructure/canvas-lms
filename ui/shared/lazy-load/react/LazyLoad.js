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

import React, {Suspense} from 'react'
import ErrorBoundary from '@canvas/error-boundary'
import errorShipUrl from '@canvas/images/ErrorShip.svg'
import GenericErrorPage from '@canvas/generic-error-page'
import LoadingIndicator from '@canvas/loading-indicator'

export default function LazyLoad({children, errorCategory}) {
  return (
    <ErrorBoundary
      errorComponent={({error}) => {
        return (
          <GenericErrorPage
            imageUrl={errorShipUrl}
            errorSubject={error.message}
            errorCategory={errorCategory}
            stack={error.stack}
          />
        )
      }}
    >
      <Suspense fallback={<LoadingIndicator />}>{children}</Suspense>
    </ErrorBoundary>
  )
}
