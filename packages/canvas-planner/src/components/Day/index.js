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
import classnames from 'classnames'
import moment from 'moment-timezone'
import {themeable} from '@instructure/ui-themeable'
import {Heading} from '@instructure/ui-heading'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
import {bool, shape, string, number, arrayOf, func} from 'prop-types'
import {userShape, itemShape, sizeShape} from '../plannerPropTypes'
import styles from './styles.css'
import theme from './theme'
import {getFriendlyDate, getDynamicFullDate, isToday} from '../../utilities/dateUtils'
import MissingAssignments from '../MissingAssignments'
import Grouping from '../Grouping'
import formatMessage from '../../format-message'
import {animatable} from '../../dynamic-ui'

export class Day extends Component {
  static propTypes = {
    day: string.isRequired,
    itemsForDay: arrayOf(shape(itemShape)),
    animatableIndex: number,
    timeZone: string.isRequired,
    toggleCompletion: func,
    updateTodo: func,
    registerAnimatable: func.isRequired,
    deregisterAnimatable: func.isRequired,
    currentUser: shape(userShape),
    simplifiedControls: bool,
    singleCourseView: bool,
    showMissingAssignments: bool,
    responsiveSize: sizeShape
  }

  static defaultProps = {
    animatableIndex: 0,
    simplifiedControls: false,
    singleCourseView: false,
    showMissingAssignments: false,
    responsiveSize: 'large'
  }

  constructor(props) {
    super(props)

    const tzMomentizedDate = moment.tz(props.day, props.timeZone)
    this.friendlyName = getFriendlyDate(tzMomentizedDate)
    this.date = getDynamicFullDate(tzMomentizedDate, props.timeZone)
  }

  componentDidMount() {
    this.props.registerAnimatable('day', this, this.props.animatableIndex, this.itemUniqueIds())
  }

  UNSAFE_componentWillReceiveProps(nextProps) {
    this.props.deregisterAnimatable('day', this, this.itemUniqueIds())
    this.props.registerAnimatable(
      'day',
      this,
      nextProps.animatableIndex,
      this.itemUniqueIds(nextProps)
    )
  }

  componentWillUnmount() {
    this.props.deregisterAnimatable('day', this, this.itemUniqueIds())
  }

  itemUniqueIds(props) {
    props = props || this.props
    return (props.itemsForDay || []).map(item => item.uniqueId)
  }

  hasItems() {
    return this.props.itemsForDay && this.props.itemsForDay.length > 0
  }

  renderGrouping(groupKey, groupItems, index) {
    const courseInfo = groupItems[0].context || {}
    const groupColor = (courseInfo.color ? courseInfo.color : this.props.currentUser.color) || null
    return (
      <Grouping
        title={courseInfo.title}
        image_url={courseInfo.image_url}
        color={groupColor}
        timeZone={this.props.timeZone}
        updateTodo={this.props.updateTodo}
        items={groupItems}
        animatableIndex={this.props.animatableIndex * 100 + index + 1}
        url={courseInfo.url}
        key={groupKey}
        theme={{
          titleColor: groupColor
        }}
        toggleCompletion={this.props.toggleCompletion}
        currentUser={this.props.currentUser}
        simplifiedControls={this.props.simplifiedControls}
        singleCourseView={this.props.singleCourseView}
        responsiveSize={this.props.responsiveSize}
      />
    )
  }

  renderGroupings() {
    const groupings = []
    let currGroupItems
    let currGroupKey
    const nItems = this.props.itemsForDay.length

    for (let i = 0; i < nItems; ++i) {
      const item = this.props.itemsForDay[i]
      const groupKey =
        item.context && item.context.id ? `${item.context.type}${item.context.id}` : 'Notes'
      if (groupKey !== currGroupKey) {
        if (currGroupKey) {
          // emit the grouping we've been working
          groupings.push(this.renderGrouping(currGroupKey, currGroupItems, groupings.length))
        }
        // start new grouping
        currGroupKey = groupKey
        currGroupItems = [item]
      } else {
        currGroupItems.push(item)
      }
    }
    // the last groupings// emit the grouping we've been working
    groupings.push(this.renderGrouping(currGroupKey, currGroupItems, groupings.length))
    return groupings
  }

  render() {
    const thisIsToday = isToday(this.props.day)

    return (
      <div className={classnames(styles.root, 'planner-day', {'planner-today': thisIsToday})}>
        <Heading border={this.hasItems() ? 'none' : 'bottom'}>
          {thisIsToday ? (
            <>
              <Text as="div" size="large" weight="bold">
                {this.friendlyName}
              </Text>
              <div className={styles.secondary}>{this.date}</div>
            </>
          ) : (
            <div className={styles.secondary}>
              {this.friendlyName}, {this.date}
            </div>
          )}
        </Heading>

        <div>
          {this.hasItems() ? (
            this.renderGroupings()
          ) : (
            <View textAlign="center" display="block" margin="small 0 0 0">
              {formatMessage('Nothing Planned Yet')}
            </View>
          )}
        </div>
        {thisIsToday && this.props.showMissingAssignments && (
          <MissingAssignments
            timeZone={this.props.timeZone}
            responsiveSize={this.props.responsiveSize}
          />
        )}
      </div>
    )
  }
}

const ThemeableDay = themeable(theme, styles)(Day)
const AnimatableDay = animatable(ThemeableDay)
AnimatableDay.theme = ThemeableDay.theme
export default AnimatableDay
