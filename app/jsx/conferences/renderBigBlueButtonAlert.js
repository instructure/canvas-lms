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
import {Link} from '@instructure/ui-elements'
import {ApplyTheme} from '@instructure/ui-themeable'
import I18n from 'i18n!conferences_renderBigBlueButton'

const theme = {
  [Alert.theme]: {
    boxShadow: 'none'
  }
}

function BigBlueButtonAlert() {
  return (
    <ApplyTheme theme={theme}>
      <Alert margin="none none medium none" variant="info">
        {I18n.t(
          'Conferences are powered by BigBlueButton, a free service to Canvas users. Extreme increases in usage could cause performance issues. In the event that BigBlueButton is unable to meet current or future demands, Canvas also partners with Zoom, Hangouts, Teams, and other video conferencing tools who are offering free or discounted services.'
        )}
        &nbsp;
        <Link href="https://www.instructure.com/canvas/blog/canvas-partners-and-distance-learning">
          {I18n.t('Learn More')}
        </Link>
      </Alert>
    </ApplyTheme>
  )
}

export default function renderBigBlueButtonAlert() {
  const $container = document.getElementById('big-blue-button-message-container')
  render(<BigBlueButtonAlert />, $container)
}
