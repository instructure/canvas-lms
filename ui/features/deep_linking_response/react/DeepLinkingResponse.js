/*
 * Copyright (C) 2018 - present Instructure, Inc.
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

import I18n from 'i18n!external_content.success'
import React, {useEffect, useCallback} from 'react'
import ReactDOM from 'react-dom'
import {Text} from '@instructure/ui-text'
import {Spinner} from '@instructure/ui-spinner'
import {Flex} from '@instructure/ui-flex'

export const RetrievingContent = ({environment, parentWindow}) => {
  const messageType = 'LtiDeepLinkingResponse'

  const sendMessage = useCallback(() => {
    parentWindow.postMessage(
      {
        messageType,
        ...environment.deep_link_response
      },
      environment.DEEP_LINKING_POST_MESSAGE_ORIGIN
    )
  }, [environment, parentWindow])

  useEffect(() => {
    sendMessage()
  }, [sendMessage])

  const message = I18n.t('Retrieving Content')
  return (
    <div>
      <Flex justifyItems="center" margin="x-large 0 large 0">
        <Flex.Item>
          <Spinner renderTitle={message} size="large" />
        </Flex.Item>
      </Flex>
      <Flex justifyItems="center" margin="0 0 large">
        <Flex.Item>
          <Text size="x-large" fontStyle="italic">
            {message}
          </Text>
        </Flex.Item>
      </Flex>
    </div>
  )
}

export default class DeepLinkingResponse {
  static mount() {
    const parentWindow = window.opener || window.top
    ReactDOM.render(
      <RetrievingContent environment={window.ENV} parentWindow={parentWindow} />,
      document.getElementById('deepLinkingContent')
    )
  }
}
