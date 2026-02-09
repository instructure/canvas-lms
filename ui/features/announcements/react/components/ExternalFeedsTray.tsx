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

import {useScope as createI18nScope} from '@canvas/i18n'
import React, {Component} from 'react'
import {bool, string} from 'prop-types'

import {Tray} from '@instructure/ui-tray'
import {Link} from '@instructure/ui-link'
import {CloseButton} from '@instructure/ui-buttons'
import {Text} from '@instructure/ui-text'
import {Heading} from '@instructure/ui-heading'
import {View} from '@instructure/ui-view'
import {IconRssLine} from '@instructure/ui-icons'

import {ConnectedAddExternalFeed} from './AddExternalFeed'
import propTypes from '../propTypes'

const I18n = createI18nScope('announcements_v2')

export default class ExternalFeedsTray extends Component {
  static propTypes = {
    atomFeedUrl: string,
    permissions: propTypes.permissions.isRequired,
    defaultOpen: bool, // facilitates testing
  }

  static defaultProps = {
    atomFeedUrl: null,
    defaultOpen: false,
  }

  state = {
    // @ts-expect-error TS2339 (typescriptify)
    open: this.props.defaultOpen,
  }

  renderTrayContent() {
    return (
      <View data-testid="announcements-tray__content">
        {this.renderHeader()}
        {this.renderRssFeedLink()}
        {/* @ts-expect-error TS2339 (typescriptify) */}
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
    // @ts-expect-error TS2339 (typescriptify)
    if (this.props.atomFeedUrl) {
      return (
        <View margin="medium" as="div" textAlign="start">
          <Link
            id="rss-feed-link"
            data-testid="rss-feed-link"
            elementRef={link => {
              // @ts-expect-error TS2339 (typescriptify)
              this.rssFeedLink = link
            }}
            // @ts-expect-error TS2339 (typescriptify)
            href={this.props.atomFeedUrl}
            isWithinText={false}
            renderIcon={IconRssLine}
            // @ts-expect-error TS2769 (typescriptify)
            themeOverride={{mediumPaddingHorizontal: '0', mediumHeight: '1.5rem'}}
          >
            {I18n.t('RSS Feed')}
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
        data-testid="announcements-tray__add-rss-root"
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
        <Link
          as="button"
          id="external_feed"
          data-testid="external-feed-link"
          isWithinText={false}
          aria-haspopup="dialog"
          // @ts-expect-error TS2339 (typescriptify)
          elementRef={link => (this.externalFeedRef = link)}
          onClick={() => {
            // @ts-expect-error TS2339 (typescriptify)
            this.setState(oldState => ({open: !oldState.open}))
          }}
        >
          {I18n.t('External Feeds')}
        </Link>
        <Tray
          label={I18n.t('External Feeds')}
          open={this.state.open}
          size="small"
          onDismiss={() => this.setState({open: false})}
          placement="end"
        >
          <CloseButton
            placement="end"
            onClick={() => this.setState({open: false})}
            screenReaderLabel={I18n.t('Close')}
          />
          {this.renderTrayContent()}
        </Tray>
      </View>
    )
  }
}
