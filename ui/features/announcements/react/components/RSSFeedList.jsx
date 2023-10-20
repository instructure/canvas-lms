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

import {useScope as useI18nScope} from '@canvas/i18n'
import React from 'react'
import {func, arrayOf, bool} from 'prop-types'
import {connect} from 'react-redux'
import {bindActionCreators} from 'redux'

import {Button} from '@instructure/ui-buttons'
import {Grid} from '@instructure/ui-grid'
import {View} from '@instructure/ui-view'
import {Text} from '@instructure/ui-text'
import {Spinner} from '@instructure/ui-spinner'
import {IconXLine} from '@instructure/ui-icons'

import actions from '../actions'
import propTypes from '../propTypes'
import select from '@canvas/obj-select'

import {Link} from '@instructure/ui-link'

const I18n = useI18nScope('announcements_v2')

export default class RSSFeedList extends React.Component {
  static propTypes = {
    feeds: arrayOf(propTypes.rssFeed),
    hasLoadedFeed: bool,
    getExternalFeeds: func.isRequired,
    deleteExternalFeed: func.isRequired,
    focusLastElement: func.isRequired,
  }

  static defaultProps = {
    feeds: [],
    hasLoadedFeed: false,
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
        other: '%{count} posts added',
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
            <Grid.Row>
              <Grid.Col>
                <Link
                  margin="0 small"
                  size="small"
                  href={url}
                  isWithinText={false}
                  themeOverride={{smallPadding: '0', smallHeight: '1rem'}}
                >
                  {display_name}
                </Link>
                <Text size="small" margin="0 small" color="secondary">
                  {this.renderPostAddedText(external_feed_entries_count)}
                </Text>
              </Grid.Col>
              <Grid.Col width="auto">
                <Button
                  id={`feed-row-${index}`}
                  className="external-rss-feed__delete-button"
                  renderIcon={
                    <IconXLine title={I18n.t('Delete %{feedName}', {feedName: display_name})} />
                  }
                  onClick={() => this.deleteExternalFeed(id, index)}
                  offset="none"
                  size="small"
                  placement="end"
                />
              </Grid.Col>
            </Grid.Row>
          </Grid>
        </View>
      </div>
    )
  }

  render() {
    if (!this.props.hasLoadedFeed) {
      return (
        <div style={{textAlign: 'center'}}>
          <Spinner size="small" renderTitle={I18n.t('Adding RSS Feed')} />
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

const connectState = state => ({
  feeds: state.externalRssFeed.feeds,
  hasLoadedFeed: state.externalRssFeed.hasLoadedFeed,
})
const connectActions = dispatch =>
  bindActionCreators(
    Object.assign(select(actions, ['getExternalFeeds', 'deleteExternalFeed'])),
    dispatch
  )
export const ConnectedRSSFeedList = connect(connectState, connectActions)(RSSFeedList)
