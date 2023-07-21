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

import AlertManager from '@canvas/alerts/react/AlertManager'
import {ApolloProvider, createClient, createPersistentCache} from '@canvas/apollo'
import ErrorBoundary from '@canvas/error-boundary'
import errorShipUrl from '@canvas/images/ErrorShip.svg'
import GenericErrorPage from '@canvas/generic-error-page'
import LoadingIndicator from '@canvas/loading-indicator'
import React, {useEffect, useState} from 'react'
import CoursePeople from './containers/CoursePeople'

export const CoursePeopleApp = () => {
  const [client, setClient] = useState(null)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    const setupApolloClient = async () => {
      if (ENV.apollo_caching) {
        const cache = await createPersistentCache(ENV.conversation_cache_key)
        setClient(createClient({cache}))
      } else {
        setClient(createClient())
      }
      setLoading(false)
    }
    setupApolloClient()
  }, [])

  if (loading) {
    return <LoadingIndicator />
  }

  return (
    <ApolloProvider client={client}>
      <ErrorBoundary
        errorComponent={
          <GenericErrorPage imageUrl={errorShipUrl} errorCategory="Canvas People Error Page" />
        }
      >
        <AlertManager>
          <CoursePeople />
        </AlertManager>
      </ErrorBoundary>
    </ApolloProvider>
  )
}
