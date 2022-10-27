/*
 * Copyright (C) 2019 - present Instructure, Inc.
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

import {useState, useEffect} from 'react'

export default function usePostMessage(expectedMessageType) {
  const [messageData, setMessageData] = useState(null)

  useEffect(() => {
    function handlePostMessage(postMessage) {
      const {subject} = postMessage.data

      if (
        postMessage.origin === ENV.DEEP_LINKING_POST_MESSAGE_ORIGIN &&
        subject === expectedMessageType
      ) {
        setMessageData(postMessage.data)
      }
    }

    window.addEventListener('message', handlePostMessage, false)

    return () => {
      window.removeEventListener('message', handlePostMessage)
    }
  })

  return messageData
}
