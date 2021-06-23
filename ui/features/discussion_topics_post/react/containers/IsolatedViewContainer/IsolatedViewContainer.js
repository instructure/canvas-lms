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

import {CloseButton} from '@instructure/ui-buttons'
import {Discussion} from '../../../graphql/Discussion'
import {Heading} from '@instructure/ui-heading'
import PropTypes from 'prop-types'
import React, {useState} from 'react'
import {Tray} from '@instructure/ui-tray'
import {Flex} from '@instructure/ui-flex'

export const mockThreads = {
  IsolatedRootEntry: {
    id: '432',
    author: {
      name: 'Jeffrey Johnson',
      avatarUrl: 'someURL'
    },
    createdAt: '2021-02-08T13:36:05-07:00',
    message:
      '<p>This is the post that never ends. It goes on and on my friends. This is the post that never ends. It goes on and on my friends. This is the post that never ends. It goes on and on my friends. This is the post that never ends. It goes on and on my friends. This is the post that never ends. It goes on and on my friends. This is the post that never ends. It goes on and on my friends. This is the post that never ends. It goes on and on my friends. This is the post that never ends. It goes on and on my friends. This is the post that never ends. It goes on and on my friends. This is the post that never ends. It goes on and on my friends.</p>',
    read: true,
    lastReply: null,
    rootEntryParticipantCounts: {
      unreadCount: 0,
      repliesCount: 0
    },
    subentriesCount: 0,
    permissions: {
      attach: true,
      create: true,
      delete: true,
      rate: true,
      read: true,
      reply: true,
      update: true,
      viewRating: true
    }
  }
}

export const IsolatedViewContainer = props => {
  const [showTray, setShowTray] = useState(true)

  return (
    <Tray open={showTray} placement="end" size="large" offset="large" label="Isolated View">
      <Flex>
        <Flex.Item shouldGrow shouldShrink>
          <Heading margin="medium medium medium">Thread</Heading>
        </Flex.Item>
        <Flex.Item>
          <CloseButton
            placement="end"
            offset="small"
            screenReaderLabel="Close"
            onClick={() => {
              setShowTray(false)
            }}
          />
        </Flex.Item>
      </Flex>
    </Tray>
  )
}

IsolatedViewContainer.propTypes = {
  IsolatedRootEntry: PropTypes.object.isRequired,
  DiscussionTopic: Discussion.shape
}
IsolatedViewContainer.defaultProps = {}

export default IsolatedViewContainer
