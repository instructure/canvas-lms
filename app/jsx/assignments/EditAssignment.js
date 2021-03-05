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

import React, {Suspense} from 'react'
import ErrorBoundary from 'jsx/shared/components/ErrorBoundary'
import errorShipUrl from 'jsx/shared/svg/ErrorShip.svg'
import GenericErrorPage from 'jsx/shared/components/GenericErrorPage/index'
import LoadingIndicator from 'jsx/shared/LoadingIndicator'

const FileBrowser = React.lazy(() => import('jsx/shared/rce/FileBrowser'))

export function FileBrowserWrapper(props) {
  return (
    <ErrorBoundary
      errorComponent={
        <GenericErrorPage
          imageUrl={errorShipUrl}
          errorCategory="FileBrowser on Create Assignment page"
        />
      }
    >
      <Suspense fallback={<LoadingIndicator />}>
        <FileBrowser {...props} />
      </Suspense>
    </ErrorBoundary>
  )
}
