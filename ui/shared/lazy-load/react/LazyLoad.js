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

export function retry(fn, retriesLeft = 3, interval = 1000) {
  return new Promise((resolve, reject) => {
    fn()
      .then(resolve)
      .catch(error => {
        setTimeout(() => {
          if (retriesLeft === 1) {
            reject(error)
            return
          }

          return retry(fn, retriesLeft - 1, interval).then(resolve, reject)
        }, interval)
      })
  })
}

export function lazy(fn) {
  return React.lazy(() => retry(fn))
}

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
