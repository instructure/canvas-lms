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
import React from 'react'
import ReactDOM from 'react-dom'
import {Spinner, Text} from '@instructure/ui-elements'
import {Flex} from '@instructure/ui-layout'

export class RetrievingContent extends React.Component {
  static messageType = 'LtiDeepLinkingResponse'

  componentDidMount() {
    const parentWindow = this.parentWindow()
    parentWindow.postMessage(
      {
        messageType: RetrievingContent.messageType,
        content_items: ENV.content_items,
        msg: ENV.message,
        log: ENV.log,
        errormsg: ENV.error_message,
        errorlog: ENV.error_log,
        ltiEndpoint: ENV.lti_endpoint,
        reloadpage: ENV.reload_page
      },
      ENV.DEEP_LINKING_POST_MESSAGE_ORIGIN
    )
  }

  render() {
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

  parentWindow() {
    let parentWindow = window.parent
    while (parentWindow && parentWindow.parent !== window.parent) {
      parentWindow = parentWindow.parent
    }
    return parentWindow
  }
}

export default class DeepLinkingResponse {
  static mount() {
    ReactDOM.render(<RetrievingContent />, document.getElementById('deepLinkingContent'))
  }
}
