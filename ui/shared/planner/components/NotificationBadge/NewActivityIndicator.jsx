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

import React, {Component} from 'react'
import {arrayOf, string, number, func} from 'prop-types'
import {useScope as useI18nScope} from '@canvas/i18n'
import {animatable} from '../../dynamic-ui'
import Indicator from './Indicator'

const I18n = useI18nScope('planner')

export class NewActivityIndicator extends Component {
  static propTypes = {
    title: string.isRequired,
    itemIds: arrayOf(string).isRequired,
    registerAnimatable: func,
    deregisterAnimatable: func,
    animatableIndex: number,
    getFocusable: func,
  }

  static defaultProps = {
    registerAnimatable: () => {},
    deregisterAnimatable: () => {},
  }

  UNSAFE_componentWillMount() {
    this.props.registerAnimatable(
      'new-activity-indicator',
      this,
      this.props.animatableIndex,
      this.props.itemIds
    )
  }

  UNSAFE_componentWillReceiveProps(newProps) {
    this.props.deregisterAnimatable('new-activity-indicator', this, this.props.itemIds)
    this.props.registerAnimatable(
      'new-activity-indicator',
      this,
      newProps.animatableIndex,
      newProps.itemIds
    )
  }

  componentWillUnmount() {
    this.props.deregisterAnimatable('new-activity-indicator', this, this.props.itemIds)
  }

  getFocusable() {
    return this.props.getFocusable ? this.props.getFocusable() : undefined
  }

  getScrollable() {
    return this.indicatorElt
  }

  render() {
    const badgeMessage = I18n.t('New activity for %{title}', {title: this.props.title})
    return (
      <Indicator
        indicatorRef={ref => (this.indicatorElt = ref)}
        title={badgeMessage}
        variant="primary"
      />
    )
  }
}

NewActivityIndicator.displayName = 'NewActivityIndicator'

export default animatable(NewActivityIndicator)
