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
import {Heading} from '@instructure/ui-heading'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
import {arrayOf, bool, func, number, shape, string} from 'prop-types'
import {itemShape, sizeShape, userShape} from '../plannerPropTypes'
// @ts-expect-error TS2305 (typescriptify)
import {getDynamicFullDate, getFriendlyDate, isToday} from '../../utilities/dateUtils'
import buildStyle from './style'

import MissingAssignments from '../MissingAssignments'

import Grouping from '../Grouping'
import {useScope as createI18nScope} from '@canvas/i18n'
import {animatable} from '../../dynamic-ui'

const I18n = createI18nScope('planner')

export class Day extends Component {
  static componentId = 'Day'

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
    responsiveSize: sizeShape,
    isObserving: bool,
  }

  static defaultProps = {
    animatableIndex: 0,
    simplifiedControls: false,
    singleCourseView: false,
    showMissingAssignments: false,
    responsiveSize: 'large',
    isObserving: false,
  }

  // @ts-expect-error TS7006 (typescriptify)
  constructor(props) {
    super(props)
    // @ts-expect-error TS2339 (typescriptify)
    this.style = buildStyle()

    const tzMomentizedDate = moment.tz(props.day, props.timeZone)
    // @ts-expect-error TS2339 (typescriptify)
    this.friendlyName = getFriendlyDate(tzMomentizedDate, moment().tz(props.timeZone))
    // @ts-expect-error TS2339 (typescriptify)
    this.date = getDynamicFullDate(tzMomentizedDate, props.timeZone)
    // @ts-expect-error TS2339 (typescriptify)
    this.thisIsToday = isToday(this.props.day)
  }

  componentDidMount() {
    // @ts-expect-error TS2339,TS2554 (typescriptify)
    this.props.registerAnimatable('day', this, this.props.animatableIndex, this.itemUniqueIds())
  }

  // @ts-expect-error TS7006 (typescriptify)
  UNSAFE_componentWillReceiveProps(nextProps) {
    // @ts-expect-error TS2339,TS2554 (typescriptify)
    this.props.deregisterAnimatable('day', this, this.itemUniqueIds())
    // @ts-expect-error TS2339 (typescriptify)
    this.props.registerAnimatable(
      'day',
      this,
      nextProps.animatableIndex,
      this.itemUniqueIds(nextProps),
    )
  }

  componentWillUnmount() {
    // @ts-expect-error TS2339,TS2554 (typescriptify)
    this.props.deregisterAnimatable('day', this, this.itemUniqueIds())
  }

  // @ts-expect-error TS7006 (typescriptify)
  itemUniqueIds(props) {
    props = props || this.props
    // @ts-expect-error TS7006 (typescriptify)
    return (props.itemsForDay || []).map(item => item.uniqueId)
  }

  hasItems() {
    // @ts-expect-error TS2339 (typescriptify)
    return this.props.itemsForDay && this.props.itemsForDay.length > 0
  }

  // @ts-expect-error TS7006 (typescriptify)
  renderGrouping(groupKey, groupItems, index) {
    const courseInfo = groupItems[0].context || {}
    // @ts-expect-error TS2339 (typescriptify)
    const groupColor = (courseInfo.color ? courseInfo.color : this.props.currentUser.color) || null
    return (
      <Grouping
        key={groupKey}
        title={courseInfo.title}
        image_url={courseInfo.image_url}
        color={groupColor}
        // @ts-expect-error TS2339 (typescriptify)
        timeZone={this.props.timeZone}
        // @ts-expect-error TS2339 (typescriptify)
        updateTodo={this.props.updateTodo}
        items={groupItems}
        // @ts-expect-error TS2339 (typescriptify)
        animatableIndex={this.props.animatableIndex * 100 + index + 1}
        url={courseInfo.url}
        themeOverride={{
          titleColor: groupColor,
        }}
        // @ts-expect-error TS2339 (typescriptify)
        toggleCompletion={this.props.toggleCompletion}
        // @ts-expect-error TS2339 (typescriptify)
        currentUser={this.props.currentUser}
        // @ts-expect-error TS2339 (typescriptify)
        simplifiedControls={this.props.simplifiedControls}
        // @ts-expect-error TS2339 (typescriptify)
        singleCourseView={this.props.singleCourseView}
        // @ts-expect-error TS2339 (typescriptify)
        responsiveSize={this.props.responsiveSize}
        // @ts-expect-error TS2339 (typescriptify)
        isObserving={this.props.isObserving}
      />
    )
  }

  renderGroupings() {
    const groupings = []
    let currGroupItems
    let currGroupKey
    // @ts-expect-error TS2339 (typescriptify)
    const nItems = this.props.itemsForDay.length

    for (let i = 0; i < nItems; ++i) {
      // @ts-expect-error TS2339 (typescriptify)
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
        // @ts-expect-error TS2454 (typescriptify)
        currGroupItems.push(item)
      }
    }
    // the last groupings// emit the grouping we've been working
    groupings.push(this.renderGrouping(currGroupKey, currGroupItems, groupings.length))
    return groupings
  }

  render = () => (
    <>
      {/* @ts-expect-error TS2339 (typescriptify) */}
      <style>{this.style.css}</style>
      <div
        data-testid="day"
        // @ts-expect-error TS2339 (typescriptify)
        className={classnames(this.style.classNames.root, 'planner-day', {
          // @ts-expect-error TS2339 (typescriptify)
          'planner-today': this.thisIsToday,
        })}
      >
        <Heading border={this.hasItems() ? 'none' : 'bottom'}>
          {/* @ts-expect-error TS2339 (typescriptify) */}
          {this.thisIsToday ? (
            <>
              <Text data-testid="today-text" as="div" size="large" weight="bold">
                {/* @ts-expect-error TS2339 (typescriptify) */}
                {this.friendlyName}
              </Text>
              {/* @ts-expect-error TS2339 (typescriptify) */}
              <div data-testid="today-date" className={this.style.classNames.secondary}>
                {/* @ts-expect-error TS2339 (typescriptify) */}
                {this.date}
              </div>
            </>
          ) : (
            // @ts-expect-error TS2339 (typescriptify)
            <div data-testid="not-today" className={this.style.classNames.secondary}>
              {/* @ts-expect-error TS2339 (typescriptify) */}
              {this.friendlyName}, {this.date}
            </div>
          )}
        </Heading>

        <div>
          {this.hasItems() ? (
            this.renderGroupings()
          ) : (
            <View data-testid="no-items" textAlign="center" display="block" margin="small 0 0 0">
              {I18n.t('Nothing Planned Yet')}
            </View>
          )}
        </div>
        {/* @ts-expect-error TS2339 (typescriptify) */}
        {this.thisIsToday && this.props.showMissingAssignments && (
          <div data-testid="missing-assignments">
            <MissingAssignments
              // @ts-expect-error TS2339 (typescriptify)
              timeZone={this.props.timeZone}
              // @ts-expect-error TS2339 (typescriptify)
              responsiveSize={this.props.responsiveSize}
            />
          </div>
        )}
      </div>
    </>
  )
}

const AnimatableDay = animatable(Day)
// @ts-expect-error TS2339 (typescriptify)
AnimatableDay.theme = Day.theme
export default AnimatableDay
