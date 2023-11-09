/*
 * Copyright (C) 2023 - present Instructure, Inc.
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
import {ApolloProvider, createClient} from '@canvas/apollo'
import AlertManager from '@canvas/alerts/react/AlertManager'
import {useScope as useI18nScope} from '@canvas/i18n'
import LoadingIndicator from '@canvas/loading-indicator'
import ErrorBoundary from '@canvas/error-boundary'
import errorShipUrl from '@canvas/images/ErrorShip.svg'
import GenericErrorPage from '@canvas/generic-error-page'
import DiscussionTopicFormContainer from './containers/DiscussionTopicFormContainer/DiscussionTopicFormContainer'

const I18n = useI18nScope('discussion_topics_edit')

export const DiscussionTopicEdit = _props => {
  const [client, setClient] = useState(null)
  const [loading, setLoading] = useState(true)

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
            errorCategory={I18n.t('Discussion Topic Edit Error Page')}
          />
        }
      >
        <AlertManager>
          <DiscussionTopicFormContainer apolloClient={client} />
        </AlertManager>
      </ErrorBoundary>
    </ApolloProvider>
  )
}
