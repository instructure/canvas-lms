/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

import React, {Component, createRef} from 'react'
import PropTypes from 'prop-types'
import {connect} from 'react-redux'
import keycode from 'keycode'
import {themeable} from '@instructure/ui-themeable'
import {Button, IconButton} from '@instructure/ui-buttons'
import {IconArrowOpenEndLine, IconArrowOpenStartLine} from '@instructure/ui-icons'
import {View} from '@instructure/ui-view'
import {loadNextWeekItems, loadPastWeekItems, loadThisWeekItems, scrollToToday} from '../../actions'
import ErrorAlert from '../ErrorAlert'
import formatMessage from '../../format-message'
import {isThisWeek} from '../../utilities/dateUtils'

import theme from './theme'
import styles from './styles.css'

// Breaking our encapsulation by reaching outside our dom sub-tree
// I suppose we could wire up the event handlers in K5Dashboard.js
// and pass the height as a prop to all the pages. Maybe it will be
// worth the complexity when another page needs the info.
function findStickyOffset() {
  const dashboardTabs = document.querySelector('.ic-Dashboard-tabs')
  const so = dashboardTabs?.getBoundingClientRect().bottom || 122
  return so
}

// Theming a functional component blew up because there was no super.prototpye
export class WeeklyPlannerHeader extends Component {
  static propTypes = {
    loadNextWeekItems: PropTypes.func.isRequired,
    loadPastWeekItems: PropTypes.func.isRequired,
    loadThisWeekItems: PropTypes.func.isRequired,
    scrollToToday: PropTypes.func.isRequired,
    loading: PropTypes.shape({
      isLoading: PropTypes.bool,
      loadingWeek: PropTypes.bool,
      loadingError: PropTypes.string
    }).isRequired,
    visible: PropTypes.bool,
    isFooter: PropTypes.bool,
    today: PropTypes.string,
    focusMissingItems: PropTypes.bool,
    weekStartDate: PropTypes.string,
    weekEndDate: PropTypes.string,
    wayPastItemDate: PropTypes.string,
    wayFutureItemDate: PropTypes.string
  }

  prevButtonRef = createRef()

  todayButtonRef = createRef()

  nextButtonRef = createRef()

  state = {
    stickyOffset: findStickyOffset(),
    prevEnabled: true,
    nextEnabled: true,
    focusedButtonIndex: 1, // start with the today button
    buttons: [this.prevButtonRef, this.todayButtonRef, this.nextButtonRef],
    focused: false,
    activeButton: 0 // -1 for prev, 0 for today, 1 for next
  }

  handleStickyOffset = () => {
    this.setState({stickyOffset: findStickyOffset()})
  }

  handlePrev = () => {
    this.prevButtonRef.current.focus()
    this.props.loadPastWeekItems()
    this.setState({focusedButtonIndex: 0, activeButton: -1})
  }

  handleToday = () => {
    this.todayButtonRef.current.focus()
    this.props.loadThisWeekItems()
    this.setState((state, _props) => {
      return {focusedButtonIndex: state.prevEnabled ? 1 : 0, activeButton: 0}
    })
  }

  handleNext = () => {
    this.nextButtonRef.current.focus()
    this.props.loadNextWeekItems({loadMoreButtonClicked: true})
    this.setState((state, _props) => {
      return {focusedButtonIndex: state.prevEnabled ? 2 : 1, activeButton: 1}
    })
  }

  handleKey = event => {
    let newFocusedIndex
    if (event.keyCode === keycode.codes.right) {
      newFocusedIndex = (this.state.focusedButtonIndex + 1) % this.state.buttons.length
    } else if (event.keyCode === keycode.codes.left) {
      newFocusedIndex =
        (this.state.focusedButtonIndex + this.state.buttons.length - 1) % this.state.buttons.length
    } else {
      return
    }
    this.state.buttons[newFocusedIndex].current?.focus()
    this.setState({focusedButtonIndex: newFocusedIndex})
  }

  handleFocus = () => {
    this.setState({focused: true})
  }

  handleBlur = () => {
    this.setState({focused: false})
  }

  updateButtons() {
    const buttons = []

    this.setState((state, props) => {
      const prevEnabled =
        props.wayPastItemDate < props.weekStartDate || props.weekStartDate > props.today
      const nextEnabled =
        props.wayFutureItemDate > props.weekEndDate || props.weekEndDate < props.today
      let focusedButtonIndex = state.focusedButtonIndex
      if (prevEnabled) buttons.push(this.prevButtonRef)
      buttons.push(this.todayButtonRef)
      if (nextEnabled) buttons.push(this.nextButtonRef)
      if (!nextEnabled && state.focusedButtonIndex === state.buttons.length - 1) {
        // prev button just taken out of play. move focus index 1 to the left
        focusedButtonIndex = buttons.length - 1
      }
      if (prevEnabled && !state.prevEnabled && state.focusedButtonIndex === 0) {
        // focus was on the Today button. Now that the prev button is in play, shift focus to Today
        focusedButtonIndex = 1
      } else if (!prevEnabled && state.prevEnabled && state.focusedButtonIndex > 0) {
        // focus was on a button when prev is taken out, shift focus to the left
        focusedButtonIndex -= 1
      }

      return {prevEnabled, nextEnabled, buttons, focusedButtonIndex}
    })
    return buttons
  }

  componentDidMount() {
    if (this.props.visible) {
      this.handleStickyOffset()
      document.addEventListener('scroll', this.handleStickyOffset)
      window.addEventListener('resize', this.handleStickyOffset)
    }
    this.updateButtons()
  }

  componentDidUpdate(prevProps, prevState) {
    // the tabs panel above the weekly planner changes size when
    // 1. the user scrolls up and the heading shrinks, or
    // 2. the window becomes narrow enough for the tabs to wrap.
    // We need to relocate the WeeklyPlannerHeader so it sticks
    // to the bottom of the tabs panel.
    if (!this.props.isFooter && this.props.visible !== prevProps.visible) {
      if (this.props.visible) {
        this.handleStickyOffset()
        document.addEventListener('scroll', this.handleStickyOffset)
        window.addEventListener('resize', this.handleStickyOffset)
        if (isThisWeek(this.props.weekStartDate)) {
          const focusMissingItems = this.props.focusMissingItems || false
          window.setTimeout(() => this.props.scrollToToday({focusMissingItems, isWeekly: true}), 0) // need to wait until the k5Dashboard tab is active
        }
      } else {
        document.removeEventListener('scroll', this.handleStickyOffset)
        window.removeEventListener('resize', this.handleStickyOffset)
      }
    }
    if (
      this.props.wayPastItemDate !== prevProps.wayPastItemDate ||
      this.props.weekStartDate !== prevProps.weekStartDate ||
      this.props.wayFutureItemDate !== prevProps.wayFutureItemDate ||
      this.props.weekEndDate !== prevProps.weekEndDate
    ) {
      const buttons = this.updateButtons()

      if (!this.props.isFooter && prevState.buttons.length === 3 && buttons.length === 2) {
        // when prev or next buttons go away, move focus to Today
        this.todayButtonRef.current.focus()
      }
    }
  }

  getButtonTabIndex(which) {
    switch (which) {
      case 'prev':
        return this.state.prevEnabled && this.state.focusedButtonIndex === 0 ? 0 : -1
      case 'today': {
        const todayIndex = this.state.prevEnabled ? 1 : 0
        return this.state.focusedButtonIndex === todayIndex ? 0 : -1
      }
      case 'next': {
        const nextIndex = this.state.prevEnabled ? 2 : 1
        return this.state.nextEnabled && this.state.focusedButtonIndex === nextIndex ? 0 : -1
      }
    }
  }

  render() {
    let prevButtonId, todayButtonId, nextButtonId
    if (!this.props.isFooter) {
      prevButtonId = this.state.activeButton === -1 ? 'weekly-header-active-button' : undefined
      todayButtonId = this.state.activeButton === 0 ? 'weekly-header-active-button' : undefined
      nextButtonId = this.state.activeButton === 1 ? 'weekly-header-active-button' : undefined
    }
    return (
      <div
        id={this.props.isFooter ? 'weekly_planner_footer' : 'weekly_planner_header'}
        data-testid={this.props.isFooter ? 'WeeklyPlannerFooter' : 'WeeklyPlannerHeader'}
        className={`${styles.root} ${
          this.props.isFooter ? 'WeeklyPlannerFooter' : 'WeeklyPlannerHeader'
        }`}
        style={{
          top: `${this.state.stickyOffset}px`,
          opacity: `${this.props.isFooter && !this.state.focused ? 0 : 1}`
        }}
        role="toolbar"
        onFocus={this.handleFocus}
        onBlur={this.handleBlur}
      >
        {this.props.loading.loadingError && !this.props.isFooter && (
          <div className={styles.errorbox}>
            <ErrorAlert error={this.props.loading.loadingError} margin="xx-small">
              {formatMessage('Error loading items')}
            </ErrorAlert>
          </div>
        )}
        <View
          as="div"
          textAlign="end"
          padding="xx-small 0 xx-small xx-small"
          background="primary"
          onKeyDown={this.handleKey}
        >
          <IconButton
            id={prevButtonId}
            onClick={this.handlePrev}
            screenReaderLabel={formatMessage('View previous week')}
            interaction={this.state.prevEnabled ? 'enabled' : 'disabled'}
            ref={this.prevButtonRef}
            tabIndex={this.getButtonTabIndex('prev')}
          >
            <IconArrowOpenStartLine />
          </IconButton>
          <Button
            id={todayButtonId}
            margin="0 xx-small"
            onClick={this.handleToday}
            ref={this.todayButtonRef}
            tabIndex={this.getButtonTabIndex('today')}
          >
            {formatMessage('Today')}
          </Button>
          <IconButton
            id={nextButtonId}
            onClick={this.handleNext}
            screenReaderLabel={formatMessage('View next week')}
            interaction={this.state.nextEnabled ? 'enabled' : 'disabled'}
            ref={this.nextButtonRef}
            tabIndex={this.getButtonTabIndex('next')}
          >
            <IconArrowOpenEndLine />
          </IconButton>
        </View>
      </div>
    )
  }
}

export const ThemedWeeklyPlannerHeader = themeable(theme, styles)(WeeklyPlannerHeader)

const mapStateToProps = state => {
  return {
    loading: state.loading,
    today: state.today.format(),
    weekStartDate: state.weeklyDashboard.weekStart.format(),
    weekEndDate: state.weeklyDashboard.weekEnd.format(),
    wayPastItemDate: state.weeklyDashboard.wayPastItemDate,
    wayFutureItemDate: state.weeklyDashboard.wayFutureItemDate
  }
}

const mapDispatchToProps = {
  loadNextWeekItems,
  loadPastWeekItems,
  loadThisWeekItems,
  scrollToToday
}

export default connect(mapStateToProps, mapDispatchToProps)(ThemedWeeklyPlannerHeader)
