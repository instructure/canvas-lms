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

import {Link} from '@instructure/ui-link'
import I18n from 'i18n!conversations_2'
import PropTypes from 'prop-types'
import React, {useState} from 'react'
import {Text} from '@instructure/ui-text'
import {Flex} from '@instructure/ui-flex'

import {PARTICIPANT_EXPANSION_THRESHOLD} from '../../../util/constants'

export const MessageDetailParticipants = ({...props}) => {
  const [participantsExpanded, setParticipantsExpanded] = useState(false)

  const uniqueMessageRecipients = props.conversationMessage.recipients.filter(
    p => p.name !== props.conversationMessage.author.name
  )

  const participantsToShow = participantsExpanded
    ? uniqueMessageRecipients
    : uniqueMessageRecipients.slice(0, PARTICIPANT_EXPANSION_THRESHOLD)

  const participantStr = `, ${participantsToShow.map(participant => participant.name).join(', ')}`

  const participantCount = uniqueMessageRecipients.length - PARTICIPANT_EXPANSION_THRESHOLD
  const participantExpansionButtonText = participantsExpanded
    ? I18n.t('%{participantCount} less', {
        participantCount
      })
    : I18n.t('%{participantCount} more', {
        participantCount
      })

  return (
    <Flex>
      <Flex.Item shouldShrink>
        <Text weight="bold">{props.conversationMessage.author.name}</Text>
        <Text>
          {participantStr}
          {uniqueMessageRecipients.length > PARTICIPANT_EXPANSION_THRESHOLD && (
            <Link
              margin="0 0 0 x-small"
              data-testid="expand-participants-button"
              onClick={() => {
                setParticipantsExpanded(!participantsExpanded)
              }}
            >
              {participantExpansionButtonText}
            </Link>
          )}
        </Text>
      </Flex.Item>
    </Flex>
  )
}

MessageDetailParticipants.propTypes = {
  conversationMessage: PropTypes.object
}
