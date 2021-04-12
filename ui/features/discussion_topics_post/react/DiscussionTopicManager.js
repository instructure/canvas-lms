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

import {DISCUSSION_QUERY} from '../graphql/Queries'
import DiscussionThreadContainer from './containers/DiscussionThreadContainer/DiscussionThreadContainer'
import errorShipUrl from '@canvas/images/ErrorShip.svg'
import GenericErrorPage from '@canvas/generic-error-page'
import I18n from 'i18n!discussion_topics_post'
import LoadingIndicator from '@canvas/loading-indicator'
import PropTypes from 'prop-types'
import React from 'react'
import {useQuery} from 'react-apollo'

export const PER_PAGE = 20

const DiscussionTopicManager = props => {
  const discussionTopicQuery = useQuery(DISCUSSION_QUERY, {
    variables: {
      discussionID: props.discussionTopicId,
      perPage: PER_PAGE
    }
  })

  if (discussionTopicQuery.error) {
    return (
      <GenericErrorPage
        imageUrl={errorShipUrl}
        errorSubject={I18n.t('Discussion Topic initial query error')}
        errorCategory={I18n.t('Discussion Topic Post Error Page')}
      />
    )
  }

  if (discussionTopicQuery.loading) {
    return <LoadingIndicator />
  }

  return (
    <>
      <DiscussionThreadContainer
        threads={discussionTopicQuery.data.legacyNode.rootDiscussionEntriesConnection.nodes}
      />
    </>
  )
}

DiscussionTopicManager.propTypes = {
  discussionTopicId: PropTypes.string.isRequired
}

export default DiscussionTopicManager
