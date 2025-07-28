/*
 * Copyright (C) 2024 - present Instructure, Inc.
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
import {Flex} from '@instructure/ui-flex'
import {Button} from '@instructure/ui-buttons'
import {useScope as createI18nScope} from '@canvas/i18n'

const I18n = createI18nScope('SpeedGraderDiscussionsNavigation')

export const SpeedGraderDiscussionsNavigation = () => {
  // @ts-expect-error
  function sendPostMessage(message) {
    const iframe = document.getElementById('speedgrader_iframe')
    // @ts-expect-error
    const iframeDoc = iframe.contentDocument || iframe.contentWindow.document
    const discussion_iframe = iframeDoc?.getElementById('discussion_preview_iframe')
    const contentWindow = discussion_iframe?.contentWindow
    if (contentWindow) {
      contentWindow.postMessage(message, '*')
    }
  }

  function previousStudentReply() {
    const message = {subject: 'DT.previousStudentReply'}
    sendPostMessage(message)
  }

  function nextStudentReply() {
    const message = {subject: 'DT.nextStudentReply'}
    sendPostMessage(message)
  }

  return (
    <Flex justifyItems="space-between" margin="small none small none">
      <Flex.Item>
        <Button data-testid="discussions-previous-reply-button" onClick={previousStudentReply}>
          {I18n.t('Previous Reply')}
        </Button>
      </Flex.Item>
      <Flex.Item>
        <Button data-testid="discussions-next-reply-button" onClick={nextStudentReply}>
          {I18n.t('Next Reply')}
        </Button>
      </Flex.Item>
    </Flex>
  )
}
