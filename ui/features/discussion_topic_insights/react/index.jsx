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
import {ApolloProvider, createClient} from '@canvas/apollo-v3'
import AlertManager from '@canvas/alerts/react/AlertManager'
import {useScope as createI18nScope} from '@canvas/i18n'
import LoadingIndicator from '@canvas/loading-indicator'
import ErrorBoundary from '@canvas/error-boundary'
import errorShipUrl from '@canvas/images/ErrorShip.svg'
import GenericErrorPage from '@canvas/generic-error-page'
import DiscussionInsights from './components/DiscussionInsights/DiscussionInsights'
import {IconInfoLine} from '@instructure/ui-icons'

const I18n = createI18nScope('discussion_topics_insights')

const DiscussionInsightsPage = _props => {
  const [client, setClient] = useState(null)
  const [loading, setLoading] = useState(true)

  const headers = [
    {
      id: 'status',
      text: <IconInfoLine />,
      width: 'fit-content',
      sortAble: false,
    },
    {
      id: 'name',
      text: 'Student Name',
      width: 'fit-content',
      sortAble: true,
    },
    {
      id: 'notes',
      text: 'Evaluation Notes',
      width: 'fit-content',
      sortAble: true,
    },
    {
      id: 'review',
      text: (
        <>
          Review <IconInfoLine />
        </>
      ),
      width: 'fit-content',
      sortAble: false,
    },
    {
      id: 'date',
      text: 'Time Posted',
      width: 'fit-content',
      sortAble: true,
    },
    {
      id: 'actions',
      text: 'Actions',
      width: 'fit-content',
      sortAble: false,
    },
  ]

  const rows = [
    {
      status: <IconInfoLine />,
      name: 'Test Student1',
      notes: 'Some AI generated text',
      review: 'Like buttons',
      date: 'Date',
      actions: 'See Reply',
    },
    {
      status: <IconInfoLine />,
      name: 'Test Student2',
      notes: 'Some AI generated text',
      review: 'Like buttons',
      date: 'Date',
      actions: 'See Reply',
    },
    {
      status: <IconInfoLine />,
      name: 'Test Student3',
      notes: 'Some AI generated text',
      review: 'Like buttons',
      date: 'Date',
      actions: 'See Reply',
    },
  ]

  useEffect(() => {
    setClient(createClient())
    setLoading(false)
  }, [])

  if (loading) {
    return <LoadingIndicator />
  }

  return (
    <ApolloProvider client={client}>
      <ErrorBoundary
        errorComponent={
          <GenericErrorPage
            imageUrl={errorShipUrl}
            errorCategory={I18n.t('Discussion Insights Error Page')}
          />
        }
      >
        <AlertManager>
          <DiscussionInsights headers={headers} rows={rows} />
        </AlertManager>
      </ErrorBoundary>
    </ApolloProvider>
  )
}

export default DiscussionInsightsPage
