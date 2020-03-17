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
import {View} from '@instructure/ui-view'
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
        <View>{I18n.t('Canvas Conferences is a free service provided by BigBlueButton.')}</View>
        <View as="div" padding="small 0">
          {I18n.t(`If your institution is likely to need more than 10 concurrent Conferences powered by
          BigBlueButton, we recommend upgrading to Premium BigBlueButton or exploring alternative
          conferencing solutions Canvas partners with, such as Zoom, Hangouts, Teams, and other
          video conferencing tools who are offering free or discounted services.`)}
          &nbsp;
          <Link href="https://www.instructure.com/canvas/blog/canvas-partners-and-distance-learning">
            {I18n.t('Learn More')}
          </Link>
        </View>
        <View as="div">
          {I18n.t(`Not all of these services may be supported by your institution. Please contact your
          local support for more information.`)}
        </View>
      </Alert>
    </ApplyTheme>
  )
}

export default function renderBigBlueButtonAlert() {
  const $container = document.getElementById('big-blue-button-message-container')
  render(<BigBlueButtonAlert />, $container)
}
