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
import {useScope as useI18nScope} from '@canvas/i18n'
import PropTypes from 'prop-types'
import React, {useState} from 'react'
import {Text} from '@instructure/ui-text'
import {Flex} from '@instructure/ui-flex'
import {View} from '@instructure/ui-view'

import {PARTICIPANT_EXPANSION_THRESHOLD} from '../../../util/constants'

const I18n = useI18nScope('conversations_2')

export const MessageDetailParticipants = ({...props}) => {
  const [participantsExpanded, setParticipantsExpanded] = useState(false)

  const uniqueMessageRecipients = props.conversationMessage?.recipients?.filter(
    p => p.shortName !== props.conversationMessage?.author?.shortName
  )

  const participantsToShow = participantsExpanded
    ? uniqueMessageRecipients
    : uniqueMessageRecipients.slice(0, PARTICIPANT_EXPANSION_THRESHOLD)

  const participantStr = `, ${participantsToShow
    .map(participant => participant.shortName)
    .join(', ')}`

  const participantCount = uniqueMessageRecipients.length - PARTICIPANT_EXPANSION_THRESHOLD
  const participantExpansionButtonText = participantsExpanded
    ? I18n.t('%{participantCount} less', {
        participantCount,
      })
    : I18n.t('%{participantCount} more', {
        participantCount,
      })

  return (
    <Flex width="100%">
      <Flex.Item shouldShrink={true} shouldGrow={true}>
        <View overflowX="hidden" overflowY="hidden" width="100%" display="block">
          <Text weight="bold" size={props.participantsSize}>
            {props.conversationMessage?.author?.shortName}
          </Text>
          {!participantsToShow.length ? null : (
            <Text size={props.participantsSize} data-testid="participant-list">
              {participantStr}
              {uniqueMessageRecipients.length > PARTICIPANT_EXPANSION_THRESHOLD && (
                <Link
                  margin="x-small"
                  data-testid="expand-participants-button"
                  onClick={() => {
                    setParticipantsExpanded(!participantsExpanded)
                  }}
                >
                  {participantExpansionButtonText}
                </Link>
              )}
            </Text>
          )}
        </View>
      </Flex.Item>
    </Flex>
  )
}

MessageDetailParticipants.propTypes = {
  conversationMessage: PropTypes.object,
  participantsSize: PropTypes.string,
}
