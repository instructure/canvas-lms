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

import React from 'react'
import {render} from 'react-dom'
import {Alert} from '@instructure/ui-alerts'
import {View} from '@instructure/ui-view'
import {ApplyTheme} from '@instructure/ui-themeable'
import I18n from 'i18n!conferences_renderBigBlueButton'

const theme = {
  [Alert.theme]: {
    boxShadow: 'none'
  }
}

/* 
[Account name] is using a free version of BigBlueButton that provides 10 concurrent video conferences, each with 1 host and up to 24 attendees. Recordings are stored for 7 days.

Dramatic increases in usage of free BigBlueButton may cause performance issues.

A premium version of BigBlueButton is available that offers concurrent conferences based on purchased amount (each with 1 host and up to 99 attendees), no recorded storage limitations, and dedicated infrastructure for better performance.

In the event that BigBlueButton is unable to meet your current or future needs, Canvas also partners with Zoom, Google Meet, Microsoft Teams, as well as other video conferencing tools.

Please contact your LMS Administrator for more details.
*/

function BigBlueButtonAlert() {
  return (
    <ApplyTheme theme={theme}>
      <Alert margin="none none medium none" renderCloseButtonLabel={I18n.t('Close')} variant="info">
        <View as="div">
          {ENV.current_account_name +
            I18n.t(
              ' is using a free version of BigBlueButton that provides 10 concurrent video conferences, each with 1 host and up to 24 attendees. Recordings are stored for 7 days.'
            )}
        </View>
        <View as="div" padding="small none none none">
          {I18n.t(
            'Dramatic increases in usage of free BigBlueButton may cause performance issues.'
          )}
        </View>
        <View as="div" padding="small none none none">
          {I18n.t(
            'A premium version of BigBlueButton is available that offers concurrent conferences based on purchased amount (each with 1 host and up to 99 attendees), no recorded storage limitations, and dedicated infrastructure for better performance.'
          )}
        </View>
        <View as="div" padding="small none none none">
          {I18n.t(
            'In the event that BigBlueButton is unable to meet your current or future needs, Canvas also partners with Zoom, Google Meet, Microsoft Teams, as well as other video conferencing tools.'
          )}
        </View>
        <View as="div" padding="small none none none">
          {I18n.t('Please contact your LMS Administrator for more details.')}
        </View>
      </Alert>
    </ApplyTheme>
  )
}

export default function renderBigBlueButtonAlert() {
  const $container = document.getElementById('big-blue-button-message-container')
  render(<BigBlueButtonAlert />, $container)
}
