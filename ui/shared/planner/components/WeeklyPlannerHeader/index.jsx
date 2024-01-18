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
import {momentObj} from 'react-moment-proptypes'
import {connect} from 'react-redux'
import keycode from 'keycode'
import qs from 'qs'
import {AccessibleContent} from '@instructure/ui-a11y-content'
import {Button, IconButton} from '@instructure/ui-buttons'
import {IconArrowOpenEndLine, IconArrowOpenStartLine} from '@instructure/ui-icons'
import {View} from '@instructure/ui-view'
import {
  loadNextWeekItems,
  loadPastWeekItems,
  loadThisWeekItems,
  scrollToToday,
  savePlannerItem,
  deletePlannerItem,
  cancelEditingPlannerItem,
  openEditingPlannerItem,
  toggleMissingItems,
} from '../../actions'
import ErrorAlert from '../ErrorAlert'
import {useScope as useI18nScope} from '@canvas/i18n'
import {isInMomentRange} from '../../utilities/dateUtils'
import TodoEditorModal from '../TodoEditorModal'

import buildStyle from './style'

const I18n = useI18nScope('planner')

export const WEEKLY_PLANNER_ACTIVE_BTN_ID = 'weekly-header-active-button'

// Breaking our encapsulation by reaching outside our dom sub-tree
// I suppose we could wire up the event handlers in K5Dashboard.js
// and pass the height as a prop to all the pages. Maybe it will be
// worth the complexity when another page needs the info.
function findStickyOffset() {
  const dashboardTabs = document.querySelector('.ic-Dashboard-tabs')
  return dashboardTabs?.getBoundingClientRect().bottom || 0
}

export const processFocusTarget = () => {
  const {protocol, host, pathname, search, hash} = window.location
  const queryParams = qs.parse(search.substring(1))
  const focusTarget = queryParams.focusTarget
  queryParams.focusTarget = undefined
  let query = qs.stringify(queryParams)
  query = query ? `?${query}` : ''
  const newUrl = `${protocol}//${host}${pathname}${query}${hash}`
  window.history.replaceState({}, null, newUrl)
  return focusTarget
}

// Theming a functional component blew up because there was no super.prototpye
export class WeeklyPlannerHeader extends Component {
  static propTypes = {
    loadNextWeekItems: PropTypes.func.isRequired,
    loadPastWeekItems: PropTypes.func.isRequired,
    loadThisWeekItems: PropTypes.func.isRequired,
    scrollToToday: PropTypes.func.isRequired,
    toggleMissing: PropTypes.func.isRequired,
    loading: PropTypes.shape({
      isLoading: PropTypes.bool,
      loadingWeek: PropTypes.bool,
      loadingError: PropTypes.string,
    }).isRequired,
    visible: PropTypes.bool,
    todayMoment: momentObj,
    weekStartMoment: momentObj,
    weekEndMoment: momentObj,
    wayPastItemDate: PropTypes.string,
    wayFutureItemDate: PropTypes.string,
    weekLoaded: PropTypes.bool,
    locale: PropTypes.string.isRequired,
    timeZone: PropTypes.string.isRequired,
    todo: PropTypes.shape({
      updateTodoItem: PropTypes.shape({
        title: PropTypes.string,
      }),
    }),
    savePlannerItem: PropTypes.func.isRequired,
    deletePlannerItem: PropTypes.func.isRequired,
    cancelEditingPlannerItem: PropTypes.func.isRequired,
    openEditingPlannerItem: PropTypes.func.isRequired,
    courses: PropTypes.arrayOf(PropTypes.object).isRequired,
  }

  constructor(props) {
    super(props)
    this.style = buildStyle()
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
  }

  handleStickyOffset = () => {
    this.setState({stickyOffset: findStickyOffset()})
  }

  handlePrev = () => {
    this.prevButtonRef.current.focus()
    this.props.loadPastWeekItems()
    this.setState({focusedButtonIndex: 0})
  }

  handleToday = () => {
    this.todayButtonRef.current.focus()
    this.props.loadThisWeekItems()
    this.setState((state, _props) => {
      return {focusedButtonIndex: state.prevEnabled ? 1 : 0}
    })
  }

  handleNext = () => {
    this.nextButtonRef.current.focus()
    this.props.loadNextWeekItems({loadMoreButtonClicked: true})
    this.setState((state, _props) => {
      return {focusedButtonIndex: state.prevEnabled ? 2 : 1}
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

  updateButtons() {
    const buttons = []

    this.setState((state, props) => {
      const prevEnabled =
        props.wayPastItemDate < props.weekStartMoment.format() ||
        props.weekStartMoment.isAfter(props.todayMoment)
      const nextEnabled =
        props.wayFutureItemDate > props.weekEndMoment.format() ||
        props.weekEndMoment.isBefore(props.todayMoment)
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

  handleFocusTarget() {
    const focusTarget = processFocusTarget()
    // Only scroll / focus if we're on the current week
    if (
      isInMomentRange(this.props.todayMoment, this.props.weekStartMoment, this.props.weekEndMoment)
    ) {
      window.setTimeout(() => {
        if (focusTarget === 'missing-items') {
          this.props.toggleMissing({forceExpanded: true})
        }
        this.props.scrollToToday({focusTarget, isWeekly: true})
      }, 0) // need to wait until the k5Dashboard tab is active
    }
  }

  componentChangedVisibility(finishedLoading) {
    if (this.props.visible) {
      this.handleStickyOffset()
      document.addEventListener('scroll', this.handleStickyOffset)
      window.addEventListener('resize', this.handleStickyOffset)
      if (finishedLoading) {
        this.handleFocusTarget()
      }
    } else {
      document.removeEventListener('scroll', this.handleStickyOffset)
      window.removeEventListener('resize', this.handleStickyOffset)
    }
  }

  componentDidMount() {
    if (this.props.visible) {
      this.componentChangedVisibility(this.props.weekLoaded)
    }
    this.updateButtons()
  }

  componentDidUpdate(prevProps, prevState) {
    // the tabs panel above the weekly planner changes size when
    // 1. the user scrolls up and the heading shrinks, or
    // 2. the window becomes narrow enough for the tabs to wrap.
    // We need to relocate the WeeklyPlannerHeader so it sticks
    // to the bottom of the tabs panel.
    if (this.props.visible !== prevProps.visible) {
      this.componentChangedVisibility(this.props.weekLoaded)
    }
    if (!prevProps.weekLoaded && this.props.weekLoaded && this.props.visible) {
      this.handleFocusTarget()
    }
    if (
      this.props.wayPastItemDate !== prevProps.wayPastItemDate ||
      !this.props.weekStartMoment.isSame(prevProps.weekStartMoment) ||
      this.props.wayFutureItemDate !== prevProps.wayFutureItemDate ||
      !this.props.weekEndMoment.isSame(prevProps.weekEndMoment)
    ) {
      const buttons = this.updateButtons()

      if (prevState.buttons.length === 3 && buttons.length === 2) {
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

  getButtonId(which) {
    return this.getButtonTabIndex(which) === 0 ? WEEKLY_PLANNER_ACTIVE_BTN_ID : undefined
  }

  render() {
    return (
      <>
        <style>{this.style.css}</style>
        <div
          id="weekly_planner_header"
          data-testid="WeeklyPlannerHeader"
          className={`${this.style.classNames.root} WeeklyPlannerHeader`}
          style={{top: `${this.state.stickyOffset}px`}}
          role="toolbar"
          aria-label={I18n.t('Weekly schedule navigation')}
        >
          {this.props.loading.loadingError && (
            <div className={this.style.classNames.errorbox}>
              <ErrorAlert error={this.props.loading.loadingError} margin="xx-small">
                {I18n.t('Error loading items')}
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
              data-testid="view-previous-week-button"
              id={this.getButtonId('prev')}
              onClick={this.handlePrev}
              screenReaderLabel={I18n.t('View previous week')}
              interaction={this.state.prevEnabled ? 'enabled' : 'disabled'}
              ref={this.prevButtonRef}
              tabIndex={this.getButtonTabIndex('prev')}
            >
              <IconArrowOpenStartLine />
            </IconButton>
            <Button
              data-testid="jump-to-today-button"
              id={this.getButtonId('today')}
              margin="0 xx-small"
              onClick={this.handleToday}
              ref={this.todayButtonRef}
              tabIndex={this.getButtonTabIndex('today')}
            >
              <AccessibleContent alt={I18n.t('Jump to Today')}>{I18n.t('Today')}</AccessibleContent>
            </Button>
            <IconButton
              data-testid="view-next-week-button"
              id={this.getButtonId('next')}
              onClick={this.handleNext}
              screenReaderLabel={I18n.t('View next week')}
              interaction={this.state.nextEnabled ? 'enabled' : 'disabled'}
              ref={this.nextButtonRef}
              tabIndex={this.getButtonTabIndex('next')}
            >
              <IconArrowOpenEndLine />
            </IconButton>
            <TodoEditorModal
              locale={this.props.locale}
              timeZone={this.props.timeZone}
              todoItem={this.props.todo?.updateTodoItem}
              courses={this.props.courses}
              onEdit={this.props.openEditingPlannerItem}
              onClose={this.props.cancelEditingPlannerItem}
              savePlannerItem={this.props.savePlannerItem}
              deletePlannerItem={this.props.deletePlannerItem}
            />
          </View>
        </div>
      </>
    )
  }
}

const mapStateToProps = state => {
  const weeks = state.weeklyDashboard?.weeks
  return {
    loading: state.loading,
    locale: state.locale,
    todayMoment: state.today,
    weekStartMoment: state.weeklyDashboard.weekStart,
    weekEndMoment: state.weeklyDashboard.weekEnd,
    wayPastItemDate: state.weeklyDashboard.wayPastItemDate,
    wayFutureItemDate: state.weeklyDashboard.wayFutureItemDate,
    weekLoaded: weeks ? !!weeks[state.weeklyDashboard.weekStart.format()] : false,
    timeZone: state.timeZone,
    todo: state.todo,
    courses: state.courses,
  }
}

const mapDispatchToProps = {
  loadNextWeekItems,
  loadPastWeekItems,
  loadThisWeekItems,
  scrollToToday,
  savePlannerItem,
  deletePlannerItem,
  cancelEditingPlannerItem,
  openEditingPlannerItem,
  toggleMissing: toggleMissingItems,
}

export default connect(mapStateToProps, mapDispatchToProps)(WeeklyPlannerHeader)
