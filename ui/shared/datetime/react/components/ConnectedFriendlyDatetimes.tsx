/*
 * Copyright (C) 2023 - present Instructure, Inc.
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
import * as tz from '../../index'
import _ from 'lodash'
import $ from 'jquery'
import '../../jquery/index'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'

type Props = {
  firstDateTime: string | Date
  secondDateTime: string | Date
  format?: string
  prefix?: string
  prefixMobile?: string
  connector?: string
  connectorMobile?: string
  showTime?: boolean
}

function timeFormatting(dateTime: string | Date, format: string | undefined, showTime: boolean) {
  if (!_.isDate(dateTime)) {
    // @ts-expect-error
    dateTime = tz.parse(dateTime)
  }

  // @ts-expect-error
  const fudged = $.fudgeDateForProfileTimezone(dateTime)
  let friendly
  if (format) {
    friendly = tz.format(dateTime, format)
  } else if (showTime) {
    friendly = $.datetimeString(dateTime)
  } else {
    // @ts-expect-error
    friendly = $.friendlyDatetime(fudged)
  }
  return {friendly, fudged}
}

export default function ConnectedFriendlyDatetimes({
  format,
  prefix,
  prefixMobile,
  connector,
  connectorMobile,
  showTime = false,
  firstDateTime,
  secondDateTime,
}: Props) {
  if (!(firstDateTime && secondDateTime)) {
    return <span />
  }

  const firstTime = timeFormatting(firstDateTime, format, showTime)
  const secondTime = timeFormatting(secondDateTime, format, showTime)

  const fixedPrefix = prefix ? `${prefix.trim()} ` : ''
  const fixedPrefixMobile = prefixMobile ? `${prefixMobile?.trim()} ` : ''
  const fixedConnector = connector ? ` ${connector.trim()} ` : ' '
  const fixedConnectorMobile = connectorMobile ? ` ${connectorMobile.trim()} ` : ' '

  return (
    <span data-testid="connected-friendly-date-time">
      <ScreenReaderContent>
        {fixedPrefix + firstTime.friendly + fixedConnector + secondTime.friendly}
      </ScreenReaderContent>

      <span aria-hidden="true">
        <span className="visible-desktop">
          {fixedPrefix + firstTime.friendly + fixedConnector + secondTime.friendly}
        </span>
        <span className="hidden-desktop">
          {fixedPrefixMobile +
            firstTime.fudged.toLocaleDateString() +
            fixedConnectorMobile +
            secondTime.fudged.toLocaleDateString()}
        </span>
      </span>
    </span>
  )
}
