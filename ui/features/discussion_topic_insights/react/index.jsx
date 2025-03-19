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
import DiscussionInsightsPage from './DiscussionInsightsPage'
import {QueryClient, QueryClientProvider} from '@tanstack/react-query'
import ErrorBoundary from '@canvas/error-boundary'
import AlertManager from '@canvas/alerts/react/AlertManager'
import GenericErrorPage from '@canvas/generic-error-page'
import errorShipUrl from '@canvas/images/ErrorShip.svg'
import {useScope as createI18nScope} from '@canvas/i18n'

const I18n = createI18nScope('discussion_insights')

const DiscussionInsightsApp = () => {
  const queryClient = new QueryClient()
  const context = ENV.context_type === 'Course' ? 'courses' : 'groups'
  return (
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
          <DiscussionInsightsPage
            context={context}
            contextId={ENV.context_id}
            discussionId={ENV.discussion_topic_id}
          />
        </AlertManager>
      </ErrorBoundary>
    </QueryClientProvider>
  )
}

export default DiscussionInsightsApp
