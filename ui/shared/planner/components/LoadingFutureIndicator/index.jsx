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
import React, {Component} from 'react'
import {bool, func, string} from 'prop-types'
import {Link} from '@instructure/ui-link'
import {View} from '@instructure/ui-view'
import {Text} from '@instructure/ui-text'
import {Spinner} from '@instructure/ui-spinner'
import ErrorAlert from '../ErrorAlert'
import {useScope as useI18nScope} from '@canvas/i18n'

const I18n = useI18nScope('planner')

export default class LoadingFutureIndicator extends Component {
  static propTypes = {
    loadingFuture: bool,
    allFutureItemsLoaded: bool,
    onLoadMore: func,
    loadingError: string,
  }

  static defaultProps = {
    loadingFuture: false,
    allFutureItemsLoaded: false,
    onLoadMore: () => {},
    loadingError: undefined,
  }

  handleLoadMoreButton = () => {
    this.props.onLoadMore({loadMoreButtonClicked: true})
  }

  renderLoadMore() {
    if (!this.props.loadingFuture && !this.props.allFutureItemsLoaded) {
      return (
        <Link isWithinText={false} as="button" onClick={this.handleLoadMoreButton}>
          {I18n.t('Load more')}
        </Link>
      )
    }
  }

  renderError() {
    if (this.props.loadingError) {
      // Show an Alert for the user, while including the underlying root cause error
      // in a hidden div in case we need to know what it was
      return (
        <div style={{width: '50%', margin: '0 auto'}}>
          <ErrorAlert error={this.props.loadingError}>
            {I18n.t('Error loading more items')}
          </ErrorAlert>
        </div>
      )
    }
  }

  renderLoading() {
    if (this.props.loadingFuture && !this.props.allFutureItemsLoaded) {
      return (
        <View>
          <Spinner size="small" margin="0 x-small 0 0" renderTitle={() => I18n.t('Loading...')} />
          <Text size="small" color="secondary">
            {I18n.t('Loading...')}
          </Text>
        </View>
      )
    }
  }

  renderEverythingLoaded() {
    if (this.props.allFutureItemsLoaded) {
      return (
        <Text color="secondary" size="small">
          {I18n.t('No more items to show')}
        </Text>
      )
    }
  }

  render() {
    return (
      <div>
        <View as="div" padding="x-large" textAlign="center">
          {this.renderError()}
          {this.renderLoadMore()}
          {this.renderLoading()}
          {this.renderEverythingLoaded()}
        </View>
      </div>
    )
  }
}
