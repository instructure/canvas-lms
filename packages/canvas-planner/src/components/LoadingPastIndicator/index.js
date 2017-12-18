/*
 * Copyright (C) 2017 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that they will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */
import React, { Component } from 'react';
import PropTypes from 'prop-types';
import Container from '@instructure/ui-core/lib/components/Container';
import Spinner from '@instructure/ui-core/lib/components/Spinner';
import Text from '@instructure/ui-core/lib/components/Text';
import ErrorAlert from '../ErrorAlert';
import formatMessage from '../../format-message';
import {animateSlideDown} from '../../utilities/scrollUtils';
import TV from './tv.svg';

export default class LoadingPastIndicator extends Component {
  static propTypes = {
    loadingPast: PropTypes.bool,            // actively loading?
    allPastItemsLoaded: PropTypes.bool,     // there are no more?
    loadingError: PropTypes.string          // message if there was an error attempting to loaad items
  }
  static defaultProps = {
    loadingPast: false,
    allPastItemsLoaded: false,
    loadingError: undefined
  }

  shouldComponentUpdate (nextProps, nextState) {
    const should = this.props.allPastItemsLoaded !== nextProps.allPastItemsLoaded ||
           this.props.loadingPast !== nextProps.loadingPast ||
           this.props.loadingError !== nextProps.loadingError;
    return should;
  }

  componentDidUpdate (prevProps) {
    // only animate on the transition to loading error,
    // regardless of the other property state
    if (this.props.loadingError) {
      if (!prevProps.loadingError) {
        animateSlideDown(this.rootDiv);
      }
      return;
    }
    // if we just transitioned from not loadingPast to loadingPast or
    // from not allPastItemsLoaded to allItemsLoaded, then run the transition
    // that slides the component in
    if((this.props.allPastItemsLoaded && this.props.allPastItemsLoaded !== prevProps.allPastItemsLoaded) ||
        (this.props.loadingPast && this.props.loadingPast !== prevProps.loadingPast)) {
      animateSlideDown(this.rootDiv);
    }
  }

  renderError () {
    if (this.props.loadingError) {
      // Show an Alert for the user, while including the underlying root cause error
      // in a hidden div in case we need to know what it was
      return (
        <div style={{width: '50%', margin: '0 auto'}}>
          <ErrorAlert error={this.props.loadingError}>
            {formatMessage('Error loading past items')}
          </ErrorAlert>
        </div>
      );
    }
  }

  renderLoading () {
    if (this.props.loadingPast) {
      return (
        <Container as="div" padding="small" textAlign="center">
          <Container display="inline">
            <Spinner size="small" margin="0 x-small 0 0" title={formatMessage('Loading past items')}/>
          </Container>
          <Text size="small" color="secondary">
            {formatMessage('Loading past items')}
          </Text>
        </Container>
      );
    }
  }

  renderNoMore () {
    if (!this.props.loadingPast && this.props.allPastItemsLoaded) {
      return (
        <Container as="div" padding="small" textAlign="center">
          <Container display="block" margin="small">
            <TV role="img" aria-hidden="true" />
          </Container>
          <Text size="large" as="div">
            {formatMessage('Beginning of Your To-Do History')}
          </Text>
          <Text size="medium" as="div">
            {formatMessage('You\'ve scrolled back to your very first To-Do!')}
          </Text>
        </Container>
      );
    }
  }

  render () {
    return (
      <div ref={(elt) => { this.rootDiv = elt; }}>
        {this.renderError()}
        {this.renderLoading()}
        {this.renderNoMore()}
      </div>
    );
  }
}
