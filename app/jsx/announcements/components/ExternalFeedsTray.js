/*
 * Copyright (C) 2017 - present Instructure, Inc.
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

import I18n from 'i18n!announcements_v2'
import React, {Component} from 'react'
import {string} from 'prop-types'

import {Tray} from '@instructure/ui-overlays'
import {Button, CloseButton} from '@instructure/ui-buttons'
import {Heading, Text} from '@instructure/ui-elements'
import {View} from '@instructure/ui-layout'
import {IconRssLine} from '@instructure/ui-icons'

import {ConnectedAddExternalFeed} from './AddExternalFeed'
import propTypes from '../propTypes'

export default class ExternalFeedsTray extends Component {
  static propTypes = {
    atomFeedUrl: string,
    permissions: propTypes.permissions.isRequired
  }

  static defaultProps = {
    atomFeedUrl: null
  }

  state = {
    open: false
  }

  renderTrayContent() {
    return (
      <View>
        {this.renderHeader()}
        {this.renderRssFeedLink()}
        {this.props.permissions.create && this.renderAddExternalFeed()}
      </View>
    )
  }

  renderHeader() {
    return (
      <View margin="0 0 0 medium" as="div" textAlign="start">
        <Heading margin="small 0 0 0" level="h3" as="h3">
          {I18n.t('External Feeds')}
        </Heading>
      </View>
    )
  }

  renderRssFeedLink() {
    if (this.props.atomFeedUrl) {
      return (
        <View margin="medium" as="div" textAlign="start">
          <Button
            variant="link"
            id="rss-feed-link"
            linkRef={link => {
              this.rssFeedLink = link
            }}
            href={this.props.atomFeedUrl}
            icon={IconRssLine}
            theme={{mediumPadding: '0', mediumHeight: '1.5rem'}}
          >
            {I18n.t('RSS Feed')}
          </Button>
        </View>
      )
    }
    return null
  }

  renderAddExternalFeed() {
    return (
      <View
        id="announcements-tray__add-rss-root"
        margin="medium medium small"
        display="block"
        textAlign="start"
        className="announcements-tray__add-rss-root"
      >
        <Text size="medium" as="h3" weight="bold">
          {I18n.t('Feeds')}
        </Text>
        <div className="announcements-tray-row">
          <View margin="small 0 0" display="block" textAlign="start">
            <ConnectedAddExternalFeed defaultOpen={false} />
          </View>
        </div>
      </View>
    )
  }

  render() {
    return (
      <View display="block" textAlign="end">
        <Button
          id="external_feed"
          aria-haspopup="dialog"
          buttonRef={link => (this.externalFeedRef = link)}
          onClick={() => this.setState({open: !this.state.open})}
          variant="link"
        >
          {I18n.t('External Feeds')}
        </Button>
        <Tray
          label={I18n.t('External Feeds')}
          open={this.state.open}
          size="small"
          onDismiss={() => this.setState({open: false})}
          placement="end"
        >
          <CloseButton placement="end" onClick={() => this.setState({open: false})}>
            {I18n.t('Close')}
          </CloseButton>
          {this.renderTrayContent()}
        </Tray>
      </View>
    )
  }
}
