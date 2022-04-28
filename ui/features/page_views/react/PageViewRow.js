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
import {TruncateText} from '@instructure/ui-truncate-text'
import {Text} from '@instructure/ui-text'
import {useScope as useI18nScope} from '@canvas/i18n'
import FriendlyDatetime from '@canvas/datetime/react/components/FriendlyDatetime'
import {IconCheckMarkSolid} from '@instructure/ui-icons'
import {Table} from '@instructure/ui-table'
import UAParser from 'ua-parser-js'

const I18n = useI18nScope('PageViews')

export default class PageViewRow extends React.Component {
  static displayName = 'Row'

  parseUserAgentString(userAgent) {
    const SPEEDGRADER = 'SpeedGrader for iPad'
    const parser = new UAParser(userAgent)

    let browser = parser.getBrowser() ? parser.getBrowser().name : ''

    if (userAgent.toLowerCase().indexOf('speedgrader') >= 0) {
      browser = SPEEDGRADER
    }

    if (!browser) {
      browser = I18n.t('browsers.unrecognized', 'Unrecognized Browser')
    } else if (browser !== SPEEDGRADER) {
      const version = parser.getBrowser().version ? parser.getBrowser().version.split('.')[0] : '0'
      browser = `${browser} ${version}`
    }
    return browser
  }

  summarizedUserAgent(data) {
    return data.app_name || this.parseUserAgentString(data.user_agent)
  }

  readableInteractionTime(data) {
    const seconds = data.interaction_seconds
    if (seconds > 5) {
      return Math.round(seconds)
    } else {
      return '--'
    }
  }

  urlAsLink(data) {
    const method = data.http_method
    const url = data.url || ''

    if (!method || method !== 'get') return <>{url}</>
    else
      return (
        <>
          <a href={url}>{url}</a>
        </>
      )
  }

  particpatedIcon(data) {
    if (data.participated) return <IconCheckMarkSolid />
    else return <></>
  }

  renderRow() {
    return (
      <>
        <Table.Row key={this.props.rowData.session_id}>
          <Table.Cell key="url">
            <Text key="url_text">
              <TruncateText position="end">{this.urlAsLink(this.props.rowData)}</TruncateText>
            </Text>
          </Table.Cell>
          <Table.Cell key="created_at">
            <FriendlyDatetime
              key="datetime"
              dateTime={this.props.rowData.created_at}
              showTime
              format="%-d %b %Y %-l:%M%P"
            />
          </Table.Cell>
          <Table.Cell key="participated" textAlign="center">
            <Text>{this.particpatedIcon(this.props.rowData)}</Text>
          </Table.Cell>
          <Table.Cell key="interaction_seconds" textAlign="center">
            <Text>{this.readableInteractionTime(this.props.rowData)}</Text>
          </Table.Cell>
          <Table.Cell key="user_agent">
            <Text>{this.summarizedUserAgent(this.props.rowData)}</Text>
          </Table.Cell>
        </Table.Row>
      </>
    )
  }

  render() {
    if (this.props.rowData) return this.renderRow()
    else return <></>
  }
}
