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
import {momentObj} from 'react-moment-proptypes'
import {ToggleDetails} from '@instructure/ui-toggle-details'
import {Pill} from '@instructure/ui-pill'
import {func, number, string, arrayOf, shape, oneOf, bool} from 'prop-types'
import BadgeList from '../BadgeList'
import buildStyle from './style'
import {NotificationBadge, MissingIndicator, NewActivityIndicator} from '../NotificationBadge'
import {badgeShape, sizeShape} from '../plannerPropTypes'
import {animatable} from '../../dynamic-ui'
import {useScope as useI18nScope} from '@canvas/i18n'

const I18n = useI18nScope('planner')

export class CompletedItemsFacade extends Component {
  constructor(props) {
    super(props)
    this.style = buildStyle()
    this.conditionalTheme = this.style.theme
      ? {
          textColor: this.style.theme.labelColor,
          iconColor: this.style.theme.labelColor,
          iconMargin: this.style.theme.gutterWidth,
        }
      : undefined
  }

  static propTypes = {
    onClick: func.isRequired,
    itemCount: number.isRequired,
    badges: arrayOf(shape(badgeShape)),
    animatableIndex: number,
    animatableItemIds: arrayOf(string),
    registerAnimatable: func,
    deregisterAnimatable: func,
    notificationBadge: oneOf(['none', 'newActivity', 'missing']),
    // eslint-disable-next-line react/no-unused-prop-types
    date: momentObj, // the scroll-to-today animation requires a date on each component in the planner
    responsiveSize: sizeShape,
    simplifiedControls: bool,
  }

  static defaultProps = {
    badges: [],
    registerAnimatable: () => {},
    deregisterAnimatable: () => {},
    notificationBadge: 'none',
    responsiveSize: 'large',
  }

  componentDidMount() {
    this.props.registerAnimatable(
      'item',
      this,
      this.props.animatableIndex,
      this.props.animatableItemIds
    )
  }

  UNSAFE_componentWillReceiveProps(newProps) {
    this.props.deregisterAnimatable('item', this, this.props.animatableItemIds)
    this.props.registerAnimatable(
      'item',
      this,
      newProps.animatableIndex,
      newProps.animatableItemIds
    )
  }

  componentWillUnmount() {
    this.props.deregisterAnimatable('item', this, this.props.animatableItemIds)
  }

  getFocusable = () => {
    return this.buttonRef
  }

  getScrollable() {
    return this.rootDiv
  }

  renderBadges() {
    if (this.props.badges.length) {
      return (
        <BadgeList>
          {this.props.badges.map(b => (
            <Pill key={b.id} color={b.variant}>
              {b.text}
            </Pill>
          ))}
        </BadgeList>
      )
    }
    return null
  }

  renderNotificationBadge() {
    if (this.props.notificationBadge === 'none')
      return <NotificationBadge responsiveSize={this.props.responsiveSize} />

    const isNewItem = this.props.notificationBadge === 'newActivity'
    const IndicatorComponent = isNewItem ? NewActivityIndicator : MissingIndicator
    const badgeMessage = I18n.t(
      {
        one: '1 completed item',
        other: '%{count} completed items',
      },
      {count: this.props.itemCount}
    )
    return (
      <NotificationBadge responsiveSize={this.props.responsiveSize}>
        <div className={this.style.classNames.activityIndicator}>
          <IndicatorComponent
            title={badgeMessage}
            itemIds={this.props.animatableItemIds}
            animatableIndex={this.props.animatableIndex}
            getFocusable={this.getFocusable}
          />
        </div>
      </NotificationBadge>
    )
  }

  render = () => (
    <>
      <style>{this.style.css}</style>
      <div
        className={classnames(
          this.style.classNames.root,
          this.style.classNames[this.props.responsiveSize],
          'planner-completed-items',
          this.props.simplifiedControls ? this.style.classNames.k5Layout : ''
        )}
        ref={elt => (this.rootDiv = elt)}
      >
        {this.renderNotificationBadge()}
        <div className={this.style.classNames.contentPrimary}>
          <ToggleDetails
            ref={ref => (this.buttonRef = ref)}
            onToggle={this.props.onClick}
            summary={I18n.t(
              {
                one: 'Show 1 completed item',
                other: 'Show %{count} completed items',
              },
              {count: this.props.itemCount}
            )}
            themeOverride={this.conditionalTheme}
          >
            ToggleDetails requires a child
          </ToggleDetails>
        </div>
        <div className={this.style.classNames.contentSecondary}>{this.renderBadges()}</div>
      </div>
    </>
  )
}

export default animatable(CompletedItemsFacade)
