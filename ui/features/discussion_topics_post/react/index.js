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
import {ApolloProvider, createClient} from '@canvas/apollo'
import DiscussionTopicManager from './DiscussionTopicManager'
import ErrorBoundary from '@canvas/error-boundary'
import errorShipUrl from '@canvas/images/ErrorShip.svg'
import GenericErrorPage from '@canvas/generic-error-page'
import I18n from 'i18n!discussion_topics_post'
import React from 'react'
import ReactDOM from 'react-dom'

const client = createClient()

export default function renderDiscussionPosts(env, elt) {
  ReactDOM.render(
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
          <DiscussionTopicManager discussionTopicId={env.discussion_topic_id} />
        </AlertManager>
      </ErrorBoundary>
    </ApolloProvider>,
    elt
  )
}
