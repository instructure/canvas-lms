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
import React from 'react'

export const PARTICIPANT_EXPANSION_THRESHOLD = 2

const conversationContextDefaultValues = {
  multiselect: false,
  setMultiselect: () => {},
  messageOpenEvent: false,
  setMessageOpenEvent: () => {},
  isSubmissionCommentsType: false,
  setIsSubmissionCommentsType: () => {},
}
export const ConversationContext = React.createContext(conversationContextDefaultValues)

export const CONVERSATION_ID_WHERE_CAN_REPLY_IS_FALSE = '129'
