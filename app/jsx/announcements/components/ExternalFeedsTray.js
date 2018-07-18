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
import React, { Component } from 'react'
import { string } from 'prop-types'

import Tray from '@instructure/ui-overlays/lib/components/Tray'
import Link from '@instructure/ui-elements/lib/components/Link'
import Button from '@instructure/ui-buttons/lib/components/Button'
import Heading from '@instructure/ui-elements/lib/components/Heading'
import View from '@instructure/ui-layout/lib/components/View'
import IconRssLine from '@instructure/ui-icons/lib/Line/IconRss'
import Text from '@instructure/ui-elements/lib/components/Text'

import { ConnectedAddExternalFeed } from './AddExternalFeed'
import propTypes from '../propTypes'

export default class ExternalFeedsTray extends Component {
  static propTypes = {
    atomFeedUrl: string,
    permissions: propTypes.permissions.isRequired
  }

  static defaultProps = {
    atomFeedUrl: null,
  }

  state = {
    open: false,
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
      <View
        margin="0 0 0 large"
        as="div"
        textAlign="start"
      >
        <Heading margin="small 0 0 small" level="h3" as="h2">{I18n.t('External feeds')}</Heading>
      </View>
    )
  }

  renderRssFeedLink() {
    if (this.props.atomFeedUrl) {
      return (
        <View
          margin="medium"
          as="div"
          textAlign="start"
        >
          <Link
            id="rss-feed-link"
            linkRef={(link) => {this.rssFeedLink = link}}
            href={this.props.atomFeedUrl}>
            <IconRssLine />
            <View margin="0 0 0 x-small">{I18n.t('RSS Feed')}</View>
          </Link>
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
        <Text size="medium" as="h2" weight="bold">{I18n.t("Feeds")}</Text>
        <div className="announcements-tray-row">
          <View
            margin="small 0 0"
            display="block"
            textAlign="start"
          >
            <ConnectedAddExternalFeed defaultOpen={false}/>
          </View>
        </div>
      </View>
    )
  }

  render () {
    return (
      <View display="block" textAlign="end">
        <Button
          id="external_feed"
          buttonRef={(link) => {this.externalFeedRef = link}}
          onClick={() => { this.setState({ open: !this.state.open }) }}
          variant="link">
          {I18n.t('External feeds')}
        </Button>
        <Tray
          label={I18n.t('External feeds')}
          closeButtonLabel={I18n.t('Close')}
          open={this.state.open}
          size="small"
          onDismiss={() => {
            this.setState({ open: false })
          }}
          placement="end"
        >
          {this.renderTrayContent()}
        </Tray>
      </View>
    )
  }
}
