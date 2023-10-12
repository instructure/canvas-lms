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

import {LtiMessageHandler} from '../lti_message_handler'
import {SUBJECT_ALLOW_LIST, isPlatformStorageSubject} from '../messages'

const handler: LtiMessageHandler<unknown> = ({responseMessages}) => {
  const isPlatformStorageEnabled = ENV?.LTI_PLATFORM_STORAGE_ENABLED

  const supported_messages = SUBJECT_ALLOW_LIST.filter(subject => {
    if (isPlatformStorageSubject(subject) && !isPlatformStorageEnabled) {
      return false
    }

    if (subject.includes('org.imsglobal')) {
      return false
    }

    return true
  }).map(subject => ({subject}))

  responseMessages.sendResponse({supported_messages})
  return true
}

export default handler
