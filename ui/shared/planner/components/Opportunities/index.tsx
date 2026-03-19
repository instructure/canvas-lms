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
import {scopeTab} from '@instructure/ui-a11y-utils'
import {AccessibleContent} from '@instructure/ui-a11y-content'
import keycode from 'keycode'

import {Tabs} from '@instructure/ui-tabs'
import {CloseButton} from '@instructure/ui-buttons'
import {array, bool, string, func, number, oneOfType} from 'prop-types'

import Opportunity from '../Opportunity'
import {specialFallbackFocusId} from '../../dynamic-ui/util'
import {animatable} from '../../dynamic-ui'
import {useScope as createI18nScope} from '@canvas/i18n'
import buildStyle from './style'

const I18n = createI18nScope('planner')

export const OPPORTUNITY_SPECIAL_FALLBACK_FOCUS_ID = specialFallbackFocusId('opportunity')

export class Opportunities_ extends Component {
  static propTypes = {
    newOpportunities: array.isRequired,
    dismissedOpportunities: array.isRequired,
    timeZone: string.isRequired,
    courses: array.isRequired,
    dismiss: func.isRequired,
    togglePopover: func.isRequired,
    maxHeight: oneOfType([number, string]),
    registerAnimatable: func,
    deregisterAnimatable: func,
    isObserving: bool,
  }

  static defaultProps = {
    maxHeight: 'none',
    registerAnimatable: () => {},
    deregisterAnimatable: () => {},
  }

  // @ts-expect-error TS7006 (typescriptify)
  constructor(props) {
    super(props)

    this.state = {
      innerMaxHeight: 'auto',
      selectedIndex: 0,
    }
    // @ts-expect-error TS2339 (typescriptify)
    this.closeButtonRef = null
    // @ts-expect-error TS2339 (typescriptify)
    this.tabPanelContentDiv = null
    // @ts-expect-error TS2339 (typescriptify)
    this.style = buildStyle()
  }

  // @ts-expect-error TS7006,TS7031 (typescriptify)
  handleTabChange = (event, {index, _id}) => {
    this.setState({
      selectedIndex: index,
    })
  }

  componentDidMount() {
    // @ts-expect-error TS2339 (typescriptify)
    this.props.registerAnimatable('opportunity', this, -1, [OPPORTUNITY_SPECIAL_FALLBACK_FOCUS_ID])
    this.setMaxHeight(this.props)
    // @ts-expect-error TS2339 (typescriptify)
    this.closeButtonRef?.focus()
  }

  // @ts-expect-error TS7006 (typescriptify)
  UNSAFE_componentWillReceiveProps(nextProps) {
    this.setMaxHeight(nextProps)
  }

  componentWillUnmount() {
    // @ts-expect-error TS2339 (typescriptify)
    this.props.deregisterAnimatable('opportunity', this, [OPPORTUNITY_SPECIAL_FALLBACK_FOCUS_ID])
  }

  getFocusable() {
    // @ts-expect-error TS2339 (typescriptify)
    return this.closeButtonRef
  }

  // @ts-expect-error TS7006 (typescriptify)
  handleKeyDown = event => {
    if (event.keyCode === keycode.codes.tab) {
      // @ts-expect-error TS2551 (typescriptify)
      scopeTab(this._content, event)
    }

    // @ts-expect-error TS2339 (typescriptify)
    if (event.keyCode === keycode.codes.escape) {
      event.preventDefault()
      // @ts-expect-error TS2339 (typescriptify)
      this.props.togglePopover()
    }
  }

  // @ts-expect-error TS7006 (typescriptify)
  courseAttr = (id, attr) => {
    // @ts-expect-error TS2339,TS7006 (typescriptify)
    const course = this.props.courses.find(c => c.id === id) || {}
    return course[attr]
  }

  // the only place on the <Tabs> hierarchy where we can set a maxHeight is on
  // TabPanel, which puts the style on it's child content-holding div.
  // To keep the scrolling area w/in the TabPanel's content so that
  // the <Tabs> doesn't outgrow its parent and the user winds up scrolling the tabs
  // out of view, we need to subtract out how much space the <Tabs>'s boilerplate takes
  // up to set the TabPanel's maxHeight appropriately.
  // Unfortunately TabPanel's tabRef returns a ref to the Tab, and TabPanel's ref returns
  // a ref to the TabPanel component. Even if we get it's div, it doesn't have it's padding
  // at the time when the component mounts and our calculation is off.
  // @ts-expect-error TS7006 (typescriptify)
  setMaxHeight(props) {
    let mxht = 'auto'
    // @ts-expect-error TS2339 (typescriptify)
    if (this.tabPanelContentDiv) {
      // @ts-expect-error TS2339 (typescriptify)
      const style = window.getComputedStyle(this.tabPanelContentDiv)
      // @ts-expect-error TS7015 (typescriptify)
      const padding = parseInt(style['padding-top'], 10) + parseInt(style['padding-bottom'], 10)
      const border =
        // @ts-expect-error TS7015 (typescriptify)
        parseInt(style['border-top-width'], 10) + parseInt(style['border-bottom-width'], 10)
      // @ts-expect-error TS2339 (typescriptify)
      mxht = `${props.maxHeight - this.tabPanelContentDiv.offsetTop - padding - border}px`
    }
    this.setState({innerMaxHeight: mxht})
  }

  // the parent of the <ol> holding the opportunities is the div TabPanel will assign
  // TabPanel's maxHeight prop to.
  // @ts-expect-error TS7006 (typescriptify)
  getTabPanelContentDivRefFromList = ol => {
    // @ts-expect-error TS2339 (typescriptify)
    this.tabPanelContentDiv = ol && ol.parentElement
  }

  // @ts-expect-error TS7006 (typescriptify)
  renderOpportunities(opportunities, dismissed) {
    return (
      // @ts-expect-error TS2339 (typescriptify)
      <ol className={this.style.classNames.list} ref={this.getTabPanelContentDivRefFromList}>
        {/* @ts-expect-error TS7006 (typescriptify) */}
        {opportunities.map((opportunity, oppIndex) => (
          // @ts-expect-error TS2339 (typescriptify)
          <li key={opportunity.id} className={this.style.classNames.item}>
            <Opportunity
              id={opportunity.id}
              dueAt={opportunity.due_at}
              points={opportunity.restrict_quantitative_data ? null : opportunity.points_possible}
              courseName={this.courseAttr(opportunity.course_id, 'shortName')}
              opportunityTitle={opportunity.name}
              // @ts-expect-error TS2339 (typescriptify)
              timeZone={this.props.timeZone}
              // @ts-expect-error TS2339 (typescriptify)
              dismiss={dismissed ? null : this.props.dismiss}
              plannerOverride={opportunity.planner_override}
              url={opportunity.html_url}
              animatableIndex={oppIndex}
              // @ts-expect-error TS2339 (typescriptify)
              isObserving={this.props.isObserving}
            />
          </li>
        ))}
      </ol>
    )
  }

  renderNewOpportunities() {
    // @ts-expect-error TS2339 (typescriptify)
    return this.props.newOpportunities.length ? (
      // @ts-expect-error TS2339 (typescriptify)
      this.renderOpportunities(this.props.newOpportunities, false)
    ) : (
      <div>{I18n.t('Nothing new needs attention.')}</div>
    )
  }

  renderDismissedOpportunities() {
    // @ts-expect-error TS2339 (typescriptify)
    return this.props.dismissedOpportunities.length ? (
      // @ts-expect-error TS2339 (typescriptify)
      this.renderOpportunities(this.props.dismissedOpportunities, true)
    ) : (
      <div>{I18n.t('Nothing here needs attention.')}</div>
    )
  }

  // @ts-expect-error TS7006 (typescriptify)
  renderTitle(which) {
    const srtitle =
      which === 'new' ? I18n.t('New Opportunities') : I18n.t('Dismissed Opportunities')
    const title = which === 'new' ? I18n.t('New') : I18n.t('Dismissed')
    return <AccessibleContent alt={srtitle}>{title}</AccessibleContent>
  }

  renderCloseButton() {
    return (
      <CloseButton
        placement="end"
        offset="x-small"
        // @ts-expect-error TS2339 (typescriptify)
        onClick={this.props.togglePopover}
        screenReaderLabel={I18n.t('Close Opportunity Center popup')}
        elementRef={el => {
          // @ts-expect-error TS2339 (typescriptify)
          this.closeButtonRef = el
        }}
      />
    )
  }

  render() {
    // @ts-expect-error TS2339 (typescriptify)
    const {selectedIndex} = this.state
    return (
      <>
        {/* @ts-expect-error TS2339 (typescriptify) */}
        <style>{this.style.css}</style>
        {/* eslint-disable-next-line jsx-a11y/no-static-element-interactions */}
        <div
          id="opportunities_parent"
          // @ts-expect-error TS2339 (typescriptify)
          className={this.style.classNames.root}
          onKeyDown={this.handleKeyDown}
          ref={c => {
            // @ts-expect-error TS2551 (typescriptify)
            this._content = c
          }}
          // @ts-expect-error TS2339 (typescriptify)
          style={{maxHeight: this.props.maxHeight}}
        >
          {this.renderCloseButton()}
          {/* @ts-expect-error TS2322,TS2339 (typescriptify) */}
          <Tabs id={this.style.classNames.tabs_container} onRequestTabChange={this.handleTabChange}>
            <Tabs.Panel
              renderTitle={this.renderTitle('new')}
              // @ts-expect-error TS2339 (typescriptify)
              maxHeight={this.state.innerMaxHeight}
              isSelected={selectedIndex === 0}
            >
              {this.renderNewOpportunities()}
            </Tabs.Panel>
            <Tabs.Panel
              renderTitle={this.renderTitle('dismissed')}
              // @ts-expect-error TS2339 (typescriptify)
              maxHeight={this.state.innerMaxHeight}
              isSelected={selectedIndex === 1}
            >
              {this.renderDismissedOpportunities()}
            </Tabs.Panel>
          </Tabs>
        </div>
      </>
    )
  }
}

// @ts-expect-error TS2339 (typescriptify)
Opportunities_.displayName = 'Opportunities_'

export default animatable(Opportunities_)
