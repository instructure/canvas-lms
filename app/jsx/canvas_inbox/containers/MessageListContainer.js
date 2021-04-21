/*
 * Copyright (C) 2020 - present Instructure, Inc.
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

import {AlertManagerContext} from 'jsx/shared/components/AlertManager'
import {CONVERSATIONS_QUERY} from '../Queries'
import {MessageListHolder} from '../components/MessageListHolder/MessageListHolder'
import I18n from 'i18n!conversations_2'
import {Mask} from '@instructure/ui-overlays'
import PropTypes from 'prop-types'
import React, {useContext} from 'react'
import {Spinner} from '@instructure/ui-spinner'
import {useQuery} from 'react-apollo'
import {View} from '@instructure/ui-view'

const MessageListContainer = ({course, scope, onSelectMessage}) => {
  const {setOnFailure} = useContext(AlertManagerContext)
  const userID = ENV.current_user_id?.toString()

  const {loading, error, data} = useQuery(CONVERSATIONS_QUERY, {
    variables: {userID, scope, course}
  })

  if (loading) {
    return (
      <View as="div" style={{position: 'relative'}} height="100%">
        <Mask>
          <Spinner renderTitle={() => I18n.t('Loading Message List')} variant="inverse" />
        </Mask>
      </View>
    )
  }

  if (error) {
    setOnFailure(I18n.t('Unable to load messages. '))
  }

  return (
    <MessageListHolder
      conversations={data?.legacyNode?.conversationsConnection?.nodes}
      onOpen={() => {}}
      onSelect={onSelectMessage}
      onStar={() => {}}
    />
  )
}

export default MessageListContainer

MessageListContainer.propTypes = {
  course: PropTypes.string,
  scope: PropTypes.string,
  onSelectMessage: PropTypes.func
}

MessageListContainer.defaultProps = {
  scope: 'inbox',
  onSelectMessage: () => {}
}
