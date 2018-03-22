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

import React, { Component } from 'react';
import { arrayOf, string, number, func } from 'prop-types';
import formatMessage from '../../format-message';

import { animatable } from '../../dynamic-ui';

import Indicator from './Indicator';

export class NewActivityIndicator extends Component {
  static propTypes = {
    title: string.isRequired,
    itemIds: arrayOf(string).isRequired,
    registerAnimatable: func,
    deregisterAnimatable: func,
    animatableIndex: number,
  }

  static defaultProps = {
    registerAnimatable: () => {},
    deregisterAnimatable: () => {},
  }

  componentWillMount () {
    this.props.registerAnimatable('new-activity-indicator', this, this.props.animatableIndex, this.props.itemIds);
  }

  componentWillReceiveProps (newProps) {
    this.props.deregisterAnimatable('new-activity-indicator', this, this.props.itemIds);
    this.props.registerAnimatable('new-activity-indicator', this, newProps.animatableIndex, newProps.itemIds);
  }

  componentWillUnmount () {
    this.props.deregisterAnimatable('new-activity-indicator', this, this.props.itemIds);
  }

  getFocusable () { throw new Error('tried to call getFocusable on NewActivityIndicator'); }
  getScrollable () {
    return this.indicatorElt;
  }

  render () {
    const badgeMessage = formatMessage('New activity for {title}', {title: this.props.title});
    return <Indicator
      indicatorRef={ref => this.indicatorElt = ref}
      title={badgeMessage}
      variant="primary"
    />;
  }
}

export default animatable(NewActivityIndicator);
