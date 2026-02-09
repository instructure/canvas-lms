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
import moment from 'moment-timezone'
import {IconButton} from '@instructure/ui-buttons'
import {Pill} from '@instructure/ui-pill'
import {Link} from '@instructure/ui-link'
import {PresentationContent, ScreenReaderContent} from '@instructure/ui-a11y-content'
import {IconXLine} from '@instructure/ui-icons'
import {string, bool, number, func, object} from 'prop-types'
// @ts-expect-error TS2305 (typescriptify)
import {getFullDateAndTime} from '../../utilities/dateUtils'
import {useScope as createI18nScope} from '@canvas/i18n'
import {animatable} from '../../dynamic-ui'
import buildStyle from './style'

const I18n = createI18nScope('planner')

export class Opportunity extends Component {
  static propTypes = {
    id: string.isRequired,
    dueAt: string.isRequired,
    points: number,
    courseName: string.isRequired,
    opportunityTitle: string.isRequired,
    timeZone: string.isRequired,
    url: string.isRequired,
    dismiss: func,
    plannerOverride: object,
    registerAnimatable: func,
    deregisterAnimatable: func,
    animatableIndex: number,
    isObserving: bool,
  }

  // @ts-expect-error TS7006 (typescriptify)
  constructor(props) {
    super(props)

    const tzMomentizedDate = moment.tz(props.dueAt, props.timeZone)
    // @ts-expect-error TS2339 (typescriptify)
    this.fullDate = getFullDateAndTime(tzMomentizedDate)
    // @ts-expect-error TS2339 (typescriptify)
    this.style = buildStyle()
  }

  static defaultProps = {
    registerAnimatable: () => {},
    deregisterAnimatable: () => {},
    dismiss: () => {},
  }

  componentDidMount() {
    // @ts-expect-error TS2339 (typescriptify)
    this.props.registerAnimatable('opportunity', this, this.props.animatableIndex, [this.props.id])
  }

  // @ts-expect-error TS7006 (typescriptify)
  UNSAFE_componentWillReceiveProps(newProps) {
    // @ts-expect-error TS2339 (typescriptify)
    this.props.deregisterAnimatable('opportunity', this, [this.props.id])
    // @ts-expect-error TS2339 (typescriptify)
    this.props.registerAnimatable('opportunity', this, newProps.animatableIndex, [newProps.id])
  }

  componentWillUnmount() {
    // @ts-expect-error TS2339 (typescriptify)
    this.props.deregisterAnimatable('opportunity', this, [this.props.id])
  }

  // @ts-expect-error TS7006 (typescriptify)
  linkRef = ref => {
    // @ts-expect-error TS2339 (typescriptify)
    this.link = ref
  }

  getFocusable() {
    // @ts-expect-error TS2339 (typescriptify)
    return this.link
  }

  dismiss = () => {
    // @ts-expect-error TS2339 (typescriptify)
    if (this.props.dismiss) {
      // @ts-expect-error TS2339 (typescriptify)
      this.props.dismiss(this.props.id, this.props.plannerOverride)
    }
  }

  renderButton() {
    // @ts-expect-error TS2339 (typescriptify)
    const isDismissed = this.props.plannerOverride && this.props.plannerOverride.dismissed
    return (
      // @ts-expect-error TS2339 (typescriptify)
      <div className={this.style.classNames.close}>
        {/* @ts-expect-error TS2339 (typescriptify) */}
        {isDismissed || this.props.isObserving ? null : (
          <IconButton
            onClick={this.dismiss}
            renderIcon={IconXLine}
            withBorder={false}
            withBackground={false}
            size="small"
            screenReaderLabel={I18n.t('Dismiss %{opportunityName}', {
              // @ts-expect-error TS2339 (typescriptify)
              opportunityName: this.props.opportunityTitle,
            })}
          />
        )}
      </div>
    )
  }

  renderPoints() {
    // @ts-expect-error TS2339 (typescriptify)
    if (typeof this.props.points !== 'number') {
      return (
        <ScreenReaderContent>
          {I18n.t('There are no points associated with this item')}
        </ScreenReaderContent>
      )
    }
    return (
      // @ts-expect-error TS2339 (typescriptify)
      <div className={this.style.classNames.points}>
        <ScreenReaderContent>
          {/* @ts-expect-error TS2339 (typescriptify) */}
          {I18n.t('%{points} points', {points: this.props.points})}
        </ScreenReaderContent>
        <PresentationContent>
          {/* @ts-expect-error TS2339 (typescriptify) */}
          <span className={this.style.classNames.pointsNumber}>{this.props.points}</span>
          {I18n.t('points')}
        </PresentationContent>
      </div>
    )
  }

  render = () => {
    return (
      <>
        {/* @ts-expect-error TS2339 (typescriptify) */}
        <style>{this.style.css}</style>
        {/* @ts-expect-error TS2339 (typescriptify) */}
        <div className={this.style.classNames.root}>
          {/* @ts-expect-error TS2339 (typescriptify) */}
          <div className={this.style.classNames.oppNameAndTitle}>
            {/* @ts-expect-error TS2339 (typescriptify) */}
            <div className={this.style.classNames.oppName}>{this.props.courseName}</div>
            {/* @ts-expect-error TS2339 (typescriptify) */}
            <div className={this.style.classNames.title}>
              <Link
                isWithinText={false}
                // @ts-expect-error TS2769 (typescriptify)
                themeOverride={{mediumPaddingHorizontal: '0', mediumHeight: 'normal'}}
                // @ts-expect-error TS2339 (typescriptify)
                href={this.props.url}
                elementRef={this.linkRef}
              >
                {/* @ts-expect-error TS2339 (typescriptify) */}
                {this.props.opportunityTitle}
              </Link>
            </div>
          </div>
          {/* @ts-expect-error TS2339 (typescriptify) */}
          <div className={this.style.classNames.footer}>
            {/* @ts-expect-error TS2339 (typescriptify) */}
            <div className={this.style.classNames.status}>
              <Pill color="danger">{I18n.t('Missing')}</Pill>
              {/* @ts-expect-error TS2339 (typescriptify) */}
              <div className={this.style.classNames.due}>
                {/* @ts-expect-error TS2339 (typescriptify) */}
                <span className={this.style.classNames.dueText}>{I18n.t('Due:')}</span>{' '}
                {/* @ts-expect-error TS2339 (typescriptify) */}
                {this.fullDate}
              </div>
            </div>
            {this.renderPoints()}
          </div>
          {this.renderButton()}
        </div>
      </>
    )
  }
}

export default animatable(Opportunity)
