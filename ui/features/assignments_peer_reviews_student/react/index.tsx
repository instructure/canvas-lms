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

import React from 'react'
import {createRoot} from 'react-dom/client'
import {QueryClient, QueryClientProvider} from '@tanstack/react-query'
import ErrorBoundary from '@canvas/error-boundary'
import errorShipUrl from '@canvas/images/ErrorShip.svg'
import GenericErrorPage from '@canvas/generic-error-page'
import PeerReviewsStudentView from './components/PeerReviewsStudentView'

const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      retry: 1,
      staleTime: 5 * 60 * 1000, // 5 minutes
      refetchOnWindowFocus: false,
    },
  },
})

export default function renderStudentPeerReview(elt: HTMLElement | null) {
  if (!ENV.ASSIGNMENT_ID || !elt) {
    return
  }

  const root = createRoot(elt)
  root.render(
    <QueryClientProvider client={queryClient}>
      <ErrorBoundary
        errorComponent={({error}: {error: Error}) => (
          <GenericErrorPage
            imageUrl={errorShipUrl}
            errorSubject={error.message}
            errorCategory="Peer Reviews Student Error Page"
            errorMessage={error.message}
            stack={error.stack}
          />
        )}
      >
        <PeerReviewsStudentView assignmentId={ENV.ASSIGNMENT_ID.toString()} />
      </ErrorBoundary>
    </QueryClientProvider>,
  )
}
