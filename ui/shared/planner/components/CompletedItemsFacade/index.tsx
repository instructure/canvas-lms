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
import {useScope as createI18nScope} from '@canvas/i18n'

const I18n = createI18nScope('planner')

export class CompletedItemsFacade extends Component {
  // @ts-expect-error TS7006 (typescriptify)
  constructor(props) {
    super(props)
    // @ts-expect-error TS2339 (typescriptify)
    this.style = buildStyle()
    // @ts-expect-error TS2339 (typescriptify)
    this.conditionalTheme = this.style.theme
      ? {
          // @ts-expect-error TS2339 (typescriptify)
          textColor: this.style.theme.labelColor,
          // @ts-expect-error TS2339 (typescriptify)
          iconColor: this.style.theme.labelColor,
          // @ts-expect-error TS2339 (typescriptify)
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
    // @ts-expect-error TS2339 (typescriptify)
    this.props.registerAnimatable(
      'item',
      this,
      // @ts-expect-error TS2339 (typescriptify)
      this.props.animatableIndex,
      // @ts-expect-error TS2339 (typescriptify)
      this.props.animatableItemIds,
    )
  }

  // @ts-expect-error TS7006 (typescriptify)
  UNSAFE_componentWillReceiveProps(newProps) {
    // @ts-expect-error TS2339 (typescriptify)
    this.props.deregisterAnimatable('item', this, this.props.animatableItemIds)
    // @ts-expect-error TS2339 (typescriptify)
    this.props.registerAnimatable(
      'item',
      this,
      newProps.animatableIndex,
      newProps.animatableItemIds,
    )
  }

  componentWillUnmount() {
    // @ts-expect-error TS2339 (typescriptify)
    this.props.deregisterAnimatable('item', this, this.props.animatableItemIds)
  }

  getFocusable = () => {
    // @ts-expect-error TS2339 (typescriptify)
    return this.buttonRef
  }

  getScrollable() {
    // @ts-expect-error TS2339 (typescriptify)
    return this.rootDiv
  }

  renderBadges() {
    // @ts-expect-error TS2339 (typescriptify)
    if (this.props.badges.length) {
      return (
        <BadgeList>
          {/* @ts-expect-error TS2339,TS7006 (typescriptify) */}
          {this.props.badges.map(b => (
            <Pill key={b.id} color={b.variant} data-testid="badgepill">
              {b.text}
            </Pill>
          ))}
        </BadgeList>
      )
    }
    return null
  }

  renderNotificationBadge() {
    // @ts-expect-error TS2339 (typescriptify)
    if (this.props.notificationBadge === 'none')
      // @ts-expect-error TS2339 (typescriptify)
      return <NotificationBadge responsiveSize={this.props.responsiveSize} />

    // @ts-expect-error TS2339 (typescriptify)
    const isNewItem = this.props.notificationBadge === 'newActivity'
    const IndicatorComponent = isNewItem ? NewActivityIndicator : MissingIndicator
    const badgeMessage = I18n.t(
      {
        one: '1 completed item',
        other: '%{count} completed items',
      },
      // @ts-expect-error TS2339 (typescriptify)
      {count: this.props.itemCount},
    )
    return (
      // @ts-expect-error TS2339 (typescriptify)
      <NotificationBadge responsiveSize={this.props.responsiveSize}>
        {/* @ts-expect-error TS2339 (typescriptify) */}
        <div className={this.style.classNames.activityIndicator}>
          <IndicatorComponent
            title={badgeMessage}
            // @ts-expect-error TS2339 (typescriptify)
            itemIds={this.props.animatableItemIds}
            // @ts-expect-error TS2339 (typescriptify)
            animatableIndex={this.props.animatableIndex}
            getFocusable={this.getFocusable}
          />
        </div>
      </NotificationBadge>
    )
  }

  render = () => (
    <>
      {/* @ts-expect-error TS2339 (typescriptify) */}
      <style>{this.style.css}</style>
      <div
        className={classnames(
          // @ts-expect-error TS2339 (typescriptify)
          this.style.classNames.root,
          // @ts-expect-error TS2339 (typescriptify)
          this.style.classNames[this.props.responsiveSize],
          'planner-completed-items',
          // @ts-expect-error TS2339 (typescriptify)
          this.props.simplifiedControls ? this.style.classNames.k5Layout : '',
        )}
        // @ts-expect-error TS2339 (typescriptify)
        ref={elt => (this.rootDiv = elt)}
      >
        {this.renderNotificationBadge()}
        {/* @ts-expect-error TS2339 (typescriptify) */}
        <div className={this.style.classNames.contentPrimary}>
          <ToggleDetails
            data-testid="completed-items-toggle"
            // @ts-expect-error TS2339 (typescriptify)
            ref={ref => (this.buttonRef = ref)}
            // @ts-expect-error TS2339 (typescriptify)
            onToggle={this.props.onClick}
            summary={I18n.t(
              {
                one: 'Show 1 completed item',
                other: 'Show %{count} completed items',
              },
              // @ts-expect-error TS2339 (typescriptify)
              {count: this.props.itemCount},
            )}
            // @ts-expect-error TS2339 (typescriptify)
            themeOverride={this.conditionalTheme}
          >
            ToggleDetails requires a child
          </ToggleDetails>
        </div>
        {/* @ts-expect-error TS2339 (typescriptify) */}
        <div className={this.style.classNames.contentSecondary}>{this.renderBadges()}</div>
      </div>
    </>
  )
}

export default animatable(CompletedItemsFacade)
