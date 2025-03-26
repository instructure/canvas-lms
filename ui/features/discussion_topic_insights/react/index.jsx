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
import React, {useState, useEffect} from 'react'
import DiscussionInsightsPage from './DiscussionInsightsPage'
import {ApolloProvider, createClient} from '@canvas/apollo-v3'
import {QueryClient, QueryClientProvider} from '@tanstack/react-query'
import ErrorBoundary from '@canvas/error-boundary'
import AlertManager from '@canvas/alerts/react/AlertManager'
import GenericErrorPage from '@canvas/generic-error-page'
import errorShipUrl from '@canvas/images/ErrorShip.svg'
import {useScope as createI18nScope} from '@canvas/i18n'
import LoadingIndicator from '@canvas/loading-indicator/react'

const I18n = createI18nScope('discussion_insights')

const DiscussionInsightsApp = () => {
  const [client, setClient] = useState(null)

  const queryClient = new QueryClient()

  useEffect(() => {
    if (!client) {
      setClient(createClient())
    }
  }, [client, setClient])

  if (!client) {
    return <LoadingIndicator />
  }

  return (
    <ApolloProvider client={client}>
      <QueryClientProvider client={queryClient}>
        <ErrorBoundary
          errorComponent={
            <GenericErrorPage
              imageUrl={errorShipUrl}
              errorCategory={I18n.t('Discussion Insights Error Page')}
            />
          }
        >
          <AlertManager>
            <DiscussionInsightsPage />
          </AlertManager>
        </ErrorBoundary>
      </QueryClientProvider>
    </ApolloProvider>
  )
}

export default DiscussionInsightsApp
