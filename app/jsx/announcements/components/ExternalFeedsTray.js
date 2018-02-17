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

import Tray from '@instructure/ui-core/lib/components/Tray'
import Link from '@instructure/ui-core/lib/components/Link'
import Heading from '@instructure/ui-core/lib/components/Heading'
import Container from '@instructure/ui-core/lib/components/Container'
import IconRssLine from 'instructure-icons/lib/Line/IconRssLine'
import Text from '@instructure/ui-core/lib/components/Text'

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
      <Container>
        {this.renderHeader()}
        {this.renderRssFeedLink()}
        {this.props.permissions.create && this.renderAddExternalFeed()}
      </Container>
    )
  }

  renderHeader() {
    return (
      <Container
        margin="0 0 0 large"
        as="div"
        textAlign="start"
      >
        <Heading margin="small 0 0 small" level="h3" as="h2">{I18n.t('External feeds')}</Heading>
      </Container>
    )
  }

  renderRssFeedLink() {
    if (this.props.atomFeedUrl) {
      return (
        <Container
          margin="medium"
          as="div"
          textAlign="start"
        >
          <Link
            id="rss-feed-link"
            linkRef={(link) => {this.rssFeedLink = link}}
            href={this.props.atomFeedUrl}>
            <IconRssLine />
            <Container margin="0 0 0 x-small">{I18n.t('RSS Feed')}</Container>
          </Link>
        </Container>
      )
    }
    return null
  }

  renderAddExternalFeed() {
    return (
      <Container
        id="announcements-tray__add-rss-root"
        margin="medium medium small"
        display="block"
        textAlign="start"
        className="announcements-tray__add-rss-root"
      >
        <Text size="medium" as="h2" weight="bold">{I18n.t("Feeds")}</Text>
        <div className="announcements-tray-row">
          <Container
            margin="small 0 0"
            display="block"
            textAlign="start"
          >
            <ConnectedAddExternalFeed defaultOpen={false}/>
          </Container>
        </div>
      </Container>
    )
  }

  render () {
    return (
      <Container display="block" textAlign="end">
        <Link
          id="external_feed"
          linkRef={(link) => {this.externalFeedRef = link}}
          onClick={() => { this.setState({ open: !this.state.open }) }}>
          {I18n.t('External feeds')}
        </Link>
        <Tray
          label={I18n.t('External feeds')}
          closeButtonLabel={I18n.t('Close')}
          open={this.state.open}
          onExit={() => this.externalFeedRef.focus()}
          size="small"
          onDismiss={() => { this.setState({ open: false }) }}
          placement="end"
          applicationElement={() => document.getElementById('application') }
        >
          {this.renderTrayContent()}
        </Tray>
      </Container>
    )
  }
}
