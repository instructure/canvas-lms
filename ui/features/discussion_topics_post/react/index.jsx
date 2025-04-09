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

import AlertManager from '@canvas/alerts/react/AlertManager'
import {ApolloProvider, createClient, createPersistentCache} from '@canvas/apollo-v3'
import DiscussionTopicManager from './DiscussionTopicManager'
import ErrorBoundary from '@canvas/error-boundary'
import errorShipUrl from '@canvas/images/ErrorShip.svg'
import GenericErrorPage from '@canvas/generic-error-page'
import {useScope as createI18nScope} from '@canvas/i18n'
import PropTypes from 'prop-types'
import React, {useEffect, useState} from 'react'
import {LoadingSpinner} from './components/LoadingSpinner/LoadingSpinner'
import {useKeyboardShortcuts} from './KeyboardShortcuts/useKeyboardShortcut'
import {QueryClientProvider} from '@tanstack/react-query'
import {queryClient} from '@canvas/query'

const I18n = createI18nScope('discussion_topics_post')

export const DiscussionTopicsPost = props => {
  const [client, setClient] = useState(null)
  const [loading, setLoading] = useState(true)

  useKeyboardShortcuts()

  useEffect(() => {
    const setupApolloClient = async () => {
      if (ENV.apollo_caching) {
        const cache = await createPersistentCache(ENV.discussion_cache_key)
        setClient(createClient({cache}))
      } else {
        setClient(createClient())
      }
      setLoading(false)
    }
    setupApolloClient()
  }, [])

  if (loading) {
    return <LoadingSpinner />
  }

  return (
    <QueryClientProvider client={queryClient}>
      <ApolloProvider client={client}>
        <ErrorBoundary
          errorComponent={
            <GenericErrorPage
              imageUrl={errorShipUrl}
              errorCategory={I18n.t('Discussion Topic Post Error Page')}
            />
          }
        >
          <AlertManager>
            <DiscussionTopicManager discussionTopicId={props.discussionTopicId} />
          </AlertManager>
        </ErrorBoundary>
      </ApolloProvider>
    </QueryClientProvider>
  )
}

DiscussionTopicsPost.propTypes = {
  discussionTopicId: PropTypes.string,
}
