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
import {func, bool, string} from 'prop-types'

import {Heading} from '@instructure/ui-heading'
import {Link} from '@instructure/ui-link'

import {InlineList} from '@instructure/ui-list'
import {useScope as createI18nScope} from '@canvas/i18n'
import DesertSvg from './EmptyDesert' // Currently uses react-svg-loader
import BalloonsSvg from './Balloons'
import buildStyle from './style'

const I18n = createI18nScope('planner')

export default class PlannerEmptyState extends Component {
  static propTypes = {
    changeDashboardView: func,
    onAddToDo: func.isRequired,
    isCompletelyEmpty: bool,
    responsiveSize: string,
    isWeekly: bool,
  }

  static defaultProps = {
    responsiveSize: 'large',
  }

  // @ts-expect-error TS7006 (typescriptify)
  constructor(props) {
    super(props)
    // @ts-expect-error TS2339 (typescriptify)
    this.style = buildStyle()
  }

  handleDashboardCardLinkClick = () => {
    // @ts-expect-error TS2339 (typescriptify)
    if (this.props.changeDashboardView) {
      // @ts-expect-error TS2339 (typescriptify)
      this.props.changeDashboardView('cards')
    }
  }

  renderAddToDoButton = () => {
    return (
      <Link
        as="button"
        isWithinText={false}
        id="PlannerEmptyState_AddToDo"
        // @ts-expect-error TS2339 (typescriptify)
        onClick={this.props.onAddToDo}
      >
        {I18n.t('Add To-Do')}
      </Link>
    )
  }

  renderNothingAtAll = () => {
    return (
      <div
        className={classnames(
          // @ts-expect-error TS2339 (typescriptify)
          this.style.classNames.root,
          'planner-empty-state',
          // @ts-expect-error TS2339 (typescriptify)
          this.style.classNames[this.props.responsiveSize],
        )}
      >
        <DesertSvg
          // @ts-expect-error TS2339 (typescriptify)
          className={classnames(this.style.classNames.desert, 'desert')}
          aria-hidden="true"
        />
        {/* @ts-expect-error TS2339 (typescriptify) */}
        <div className={this.style.classNames.title}>
          <Heading>{I18n.t('No Due Dates Assigned')}</Heading>
        </div>
        {/* @ts-expect-error TS2339 (typescriptify) */}
        <div className={this.style.classNames.subtitlebox}>
          {/* @ts-expect-error TS2339 (typescriptify) */}
          <div className={this.style.classNames.subtitle}>
            {I18n.t("Looks like there isn't anything here")}
          </div>
          {/* @ts-expect-error TS2339 (typescriptify) */}
          {!this.props.isWeekly && (
            <InlineList delimiter="pipe">
              {/* @ts-expect-error TS2339 (typescriptify) */}
              {this.props.changeDashboardView && (
                <InlineList.Item>
                  <Link
                    as="button"
                    isWithinText={false}
                    id="PlannerEmptyState_CardView"
                    onClick={this.handleDashboardCardLinkClick}
                  >
                    {I18n.t('Go to Card View Dashboard')}
                  </Link>
                </InlineList.Item>
              )}
              <InlineList.Item>{this.renderAddToDoButton()}</InlineList.Item>
            </InlineList>
          )}
        </div>
      </div>
    )
  }

  renderNothingLeft = () => {
    // @ts-expect-error TS2339 (typescriptify)
    const msg = this.props.isWeekly ? I18n.t('Nothing Due This Week') : I18n.t('Nothing More To Do')
    return (
      <div
        className={classnames(
          // @ts-expect-error TS2339 (typescriptify)
          this.style.classNames.root,
          'planner-empty-state',
          // @ts-expect-error TS2339 (typescriptify)
          this.style.classNames[this.props.responsiveSize],
        )}
      >
        <BalloonsSvg
          // @ts-expect-error TS2339 (typescriptify)
          className={classnames(this.style.classNames.balloons, 'balloons')}
          aria-hidden="true"
        />
        {/* @ts-expect-error TS2339 (typescriptify) */}
        <div className={this.style.classNames.title}>
          <Heading>{msg}</Heading>
        </div>
        {/* @ts-expect-error TS2339 (typescriptify) */}
        {!this.props.isWeekly && (
          // @ts-expect-error TS2339 (typescriptify)
          <div className={this.style.classNames.subtitlebox}>
            {/* @ts-expect-error TS2339 (typescriptify) */}
            <div className={this.style.classNames.subtitle}>
              {I18n.t('Scroll up to see your history!')}
            </div>
            {this.renderAddToDoButton()}
          </div>
        )}
      </div>
    )
  }

  render() {
    return (
      <>
        {/* @ts-expect-error TS2339 (typescriptify) */}
        <style>{this.style.css}</style>
        {/* @ts-expect-error TS2339 (typescriptify) */}
        {this.props.isCompletelyEmpty ? this.renderNothingAtAll() : this.renderNothingLeft()}
      </>
    )
  }
}
