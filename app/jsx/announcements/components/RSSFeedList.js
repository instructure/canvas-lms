/*
 * Copyright (C) 2018 - present Instructure, Inc.
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
import React from 'react'
import {func, arrayOf, bool} from 'prop-types'
import {connect} from 'react-redux'
import {bindActionCreators} from 'redux'

import Button from '@instructure/ui-buttons/lib/components/Button'
import View from '@instructure/ui-layout/lib/components/View'
import Grid, {GridRow, GridCol} from '@instructure/ui-layout/lib/components/Grid'
import Link from '@instructure/ui-elements/lib/components/Link'
import Spinner from '@instructure/ui-elements/lib/components/Spinner'
import Text from '@instructure/ui-elements/lib/components/Text'
import IconXLine from '@instructure/ui-icons/lib/Line/IconX'

import actions from '../actions'
import propTypes from '../propTypes'
import select from '../../shared/select'

export default class RSSFeedList extends React.Component {
  static propTypes = {
    feeds: arrayOf(propTypes.rssFeed),
    hasLoadedFeed: bool,
    getExternalFeeds: func.isRequired,
    deleteExternalFeed: func.isRequired,
    focusLastElement: func.isRequired
  }

  static defaultProps = {
    feeds: [],
    hasLoadedFeed: false
  }

  componentDidMount() {
    if (!this.props.hasLoadedFeed) {
      this.props.getExternalFeeds()
    }
  }

  deleteExternalFeed = (id, index) => {
    this.props.deleteExternalFeed({feedId: id})
    const previousIndex = index - 1
    const elFocus = index
      ? () => {
          document.getElementById(`feed-row-${previousIndex}`).focus()
        }
      : this.props.focusLastElement

    setTimeout(() => {
      elFocus()
    }, 200)
  }

  renderPostAddedText(numberOfPosts) {
    return I18n.t(
      {
        zero: '%{count} posts added',
        one: '%{count} post added',
        other: '%{count} posts added'
      },
      {count: numberOfPosts}
    )
  }

  renderFeedRow({display_name, id, external_feed_entries_count = 0, url}, index) {
    return (
      <div key={id} className="announcements-tray-feed-row">
        <View margin="small 0" display="block">
          <Grid
            startAt="medium"
            vAlign="middle"
            colSpacing="small"
            hAlign="space-around"
            rowSpacing="small"
          >
            <GridRow>
              <GridCol>
                <Link margin="0 small" href={url}>
                  <Text size="small" margin="0 small 0">
                    {display_name}
                  </Text>
                </Link>
                <Text size="small" margin="0 small" color="secondary">
                  {this.renderPostAddedText(external_feed_entries_count)}
                </Text>
              </GridCol>
              <GridCol width="auto">
                <Button
                  id={`feed-row-${index}`}
                  className="external-rss-feed__delete-button"
                  variant="icon"
                  onClick={() => this.deleteExternalFeed(id, index)}
                  offset="none"
                  size="small"
                  placement="end"
                >
                  <IconXLine title={I18n.t('Delete %{feedName}', {feedName: display_name})} />
                </Button>
              </GridCol>
            </GridRow>
          </Grid>
        </View>
      </div>
    )
  }

  render() {
    if (!this.props.hasLoadedFeed) {
      return (
        <div style={{textAlign: 'center'}}>
          <Spinner size="small" title={I18n.t('Adding RSS Feed')} />
        </div>
      )
    } else {
      return (
        <View id="external_rss_feed__rss-list" display="block" textAlign="start">
          {this.props.feeds.map((feed, index) => this.renderFeedRow(feed, index))}
          <div className="announcements-tray-row" />
        </View>
      )
    }
  }
}

const connectState = state =>
  Object.assign({
    feeds: state.externalRssFeed.feeds,
    hasLoadedFeed: state.externalRssFeed.hasLoadedFeed
  })
const connectActions = dispatch =>
  bindActionCreators(
    Object.assign(select(actions, ['getExternalFeeds', 'deleteExternalFeed'])),
    dispatch
  )
export const ConnectedRSSFeedList = connect(
  connectState,
  connectActions
)(RSSFeedList)
