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
import PropTypes from 'prop-types'
import {View} from '@instructure/ui-view'
import {Text} from '@instructure/ui-text'
import {Spinner} from '@instructure/ui-spinner'

import ErrorAlert from '../ErrorAlert'
import {useScope as useI18nScope} from '@canvas/i18n'
import TV from './TV'

const I18n = useI18nScope('planner')

export default class LoadingPastIndicator extends Component {
  static propTypes = {
    loadingPast: PropTypes.bool, // actively loading?
    allPastItemsLoaded: PropTypes.bool, // there are no more?
    loadingError: PropTypes.string, // message if there was an error attempting to loaad items
  }

  static defaultProps = {
    loadingPast: false,
    allPastItemsLoaded: false,
    loadingError: undefined,
  }

  // Don't try to animate this component here. If we want this to animate, it should be coordinated
  // with other animations in the dynamic ui manager.

  renderError() {
    if (this.props.loadingError) {
      // Show an Alert for the user, while including the underlying root cause error
      // in a hidden div in case we need to know what it was
      return (
        <div style={{width: '50%', margin: '0 auto'}}>
          <ErrorAlert error={this.props.loadingError}>
            {I18n.t('Error loading past items')}
          </ErrorAlert>
        </div>
      )
    }
  }

  renderNoMore() {
    if (this.props.allPastItemsLoaded) {
      return (
        <View as="div" padding="small" textAlign="center">
          <View display="block" margin="small">
            <TV role="img" aria-hidden="true" />
          </View>
          <Text size="large" as="div">
            {I18n.t('Beginning of Your To-Do History')}
          </Text>
          <Text size="medium" as="div">
            {I18n.t("You've scrolled back to your very first To-Do!")}
          </Text>
        </View>
      )
    }
  }

  renderLoading() {
    if (this.props.loadingPast && !this.props.allPastItemsLoaded) {
      return (
        <View as="div" padding="medium small small small" textAlign="center">
          <Spinner
            size="small"
            margin="0 x-small 0 0"
            renderTitle={() => I18n.t('Loading past items')}
          />
          <Text size="small" color="secondary">
            {I18n.t('Loading past items')}
          </Text>
        </View>
      )
    }
  }

  render() {
    return (
      <div
        ref={elt => {
          this.rootDiv = elt
        }}
      >
        {this.renderError()}
        {this.renderNoMore()}
        {this.renderLoading()}
      </div>
    )
  }
}
