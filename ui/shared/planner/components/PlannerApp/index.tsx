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
import {momentObj} from 'react-moment-proptypes'
import {connect} from 'react-redux'
import {View} from '@instructure/ui-view'
import {Spinner} from '@instructure/ui-spinner'
import {arrayOf, oneOfType, shape, bool, number, object, string, func} from 'prop-types'
import {userShape, sizeShape} from '../plannerPropTypes'
import AnimatableDay from '../Day'
import ThemedEmptyDays from '../EmptyDays'
import ShowOnFocusButton from '../ShowOnFocusButton'
import LoadingFutureIndicator from '../LoadingFutureIndicator'
import LoadingPastIndicator from '../LoadingPastIndicator'
import PlannerEmptyState from '../PlannerEmptyState'
import {useScope as createI18nScope} from '@canvas/i18n'
import {
  loadFutureItems,
  loadPastButtonClicked,
  togglePlannerItemCompletion,
  updateTodo,
  scrollToToday,
  reloadWithObservee,
} from '../../actions'
import {notifier} from '../../dynamic-ui'
import {daysToDaysHash} from '../../utilities/daysUtils'
// @ts-expect-error TS2305 (typescriptify)
import {formatDayKey, isThisWeek} from '../../utilities/dateUtils'
import {Animator} from '../../dynamic-ui/animator'
import responsiviser from '../responsiviser'
import {observedUserId, observedUserContextCodes} from '../../utilities/apiUtils'

const I18n = createI18nScope('planner')

export class PlannerApp extends Component {
  static propTypes = {
    days: arrayOf(arrayOf(oneOfType([/* date */ string, arrayOf(/* items */ object)]))),
    timeZone: string,
    isLoading: bool,
    loadingPast: bool,
    loadingError: string,
    allPastItemsLoaded: bool,
    loadingFuture: bool,
    allFutureItemsLoaded: bool,
    loadPastButtonClicked: func,
    loadFutureItems: func,
    changeDashboardView: func,
    togglePlannerItemCompletion: func,
    updateTodo: func,
    scrollToToday: func,
    triggerDynamicUiUpdates: func,
    preTriggerDynamicUiUpdates: func,
    plannerActive: func,
    currentUser: shape(userShape),
    responsiveSize: sizeShape,
    appRef: func,
    focusFallback: func,
    // today, the weekly planner is used only for k5 mode, but that's not
    // strictly necessary. And k5 mode renders different stuff, so it's unique.
    // Let's keep them both.
    k5Mode: bool,
    isWeekly: bool,
    isCompletelyEmpty: bool,
    loadingWeek: bool,
    thisWeek: shape({
      weekStart: momentObj,
      weekEnd: momentObj,
    }),
    weekLoaded: bool,
    loadingOpportunities: bool,
    opportunityCount: number,
    singleCourseView: bool,
    isObserving: bool,
    observedUserId: string,
    observedUserContextCodes: arrayOf(string),
  }

  static defaultProps = {
    isLoading: false,
    triggerDynamicUiUpdates: () => {},
    preTriggerDynamicUiUpdates: () => {},
    plannerActive: () => {
      return false
    },
    responsiveSize: 'large',
    appRef: () => {},
    focusFallback: () => {},
    isCompletelyEmpty: true,
    k5Mode: false,
    singleCourseView: false,
    isObserving: false,
  }

  // @ts-expect-error TS7006 (typescriptify)
  constructor(props) {
    super(props)
    // @ts-expect-error TS2339 (typescriptify)
    this.animator = null
    // @ts-expect-error TS2339 (typescriptify)
    this._plannerElem = null
    // @ts-expect-error TS2339 (typescriptify)
    this.fixedResponsiveMemo = null
  }

  UNSAFE_componentWillMount() {
    // @ts-expect-error TS2339 (typescriptify)
    this.props.appRef(this)
    window.addEventListener('resize', this.onResize, false)
  }

  // @ts-expect-error TS7006 (typescriptify)
  UNSAFE_componentWillUpdate(nextProps) {
    // @ts-expect-error TS2339 (typescriptify)
    if (this.props.allPastItemsLoaded === false && nextProps.allPastItemsLoaded === true) {
      // @ts-expect-error TS2339 (typescriptify)
      if (this.loadPriorButton === document.activeElement) {
        // @ts-expect-error TS2339 (typescriptify)
        this.props.focusFallback()
      }
    }
    // @ts-expect-error TS2339 (typescriptify)
    this.props.preTriggerDynamicUiUpdates()
  }

  // @ts-expect-error TS7006 (typescriptify)
  componentDidUpdate(prevProps) {
    // @ts-expect-error TS2339 (typescriptify)
    if (prevProps.observedUserId !== this.props.observedUserId) {
      // @ts-expect-error TS2339,TS2554 (typescriptify)
      reloadWithObservee(this.props.observedUserId, this.props.observedUserContextCodes)
      return
    }

    // @ts-expect-error TS2339 (typescriptify)
    this.props.triggerDynamicUiUpdates()
    // @ts-expect-error TS2339 (typescriptify)
    if (this.props.responsiveSize !== prevProps.responsiveSize) {
      this.afterLayoutChange()
    }
    // @ts-expect-error TS2339 (typescriptify)
    if (!this.props.isLoading && prevProps.isLoading) {
      // @ts-expect-error TS2339 (typescriptify)
      this.props.scrollToToday({isWeekly: this.props.isWeekly, autoFocus: false})
    }
  }

  componentWillUnmount() {
    // @ts-expect-error TS2339 (typescriptify)
    this.props.appRef(null)
    window.removeEventListener('resize', this.onResize, false)
  }

  fixedElementForItemScrolling() {
    // @ts-expect-error TS2551 (typescriptify)
    return this.fixedElement
  }

  // @ts-expect-error TS7006 (typescriptify)
  fixedElementRef = elt => {
    // @ts-expect-error TS2551 (typescriptify)
    this.fixedElement = elt
  }

  // when the planner changes layout, its contents move and the user gets lost.
  // let's help with that.

  // First, when the user starts to resize the window, call beforeLayoutChange
  resizeTimer = 0

  onResize = () => {
    if (this.resizeTimer === 0) {
      this.resizeTimer = window.setTimeout(() => {
        this.resizeTimer = 0
      }, 1000)
      this.beforeLayoutChange()
    }
  }

  // @ts-expect-error TS7006 (typescriptify)
  onAddToDo = event => {
    event.preventDefault()
    // @ts-expect-error TS2339 (typescriptify)
    this.props.updateTodo({updateTodoItem: {}})
  }

  // before we tell the responsive elements the size has changed, find the first
  // visible day or grouping and remember its position.
  beforeLayoutChange() {
    // @ts-expect-error TS7006 (typescriptify)
    function findFirstVisible(selector) {
      const list = plannerTop.querySelectorAll(selector)
      const elem = Array.prototype.find.call(list, el => el.getBoundingClientRect().top > 0)
      return elem
    }
    // @ts-expect-error TS2339 (typescriptify)
    const plannerTop = this._plannerElem || document
    const fixedResponsiveElem = findFirstVisible(
      '.planner-day, .planner-grouping, .planner-empty-days',
    )
    if (fixedResponsiveElem) {
      // @ts-expect-error TS2339 (typescriptify)
      if (!this.animator) this.animator = new Animator()
      // @ts-expect-error TS2339 (typescriptify)
      this.fixedResponsiveMemo = this.animator.elementPositionMemo(fixedResponsiveElem)
    }
  }

  // after the re-layout, put the cached element back to where it was
  afterLayoutChange = () => {
    // @ts-expect-error TS2339 (typescriptify)
    if (this.fixedResponsiveMemo) {
      // @ts-expect-error TS2339 (typescriptify)
      this.animator.maintainViewportPositionFromMemo(
        // @ts-expect-error TS2339 (typescriptify)
        this.fixedResponsiveMemo.element,
        // @ts-expect-error TS2339 (typescriptify)
        this.fixedResponsiveMemo,
      )
      // @ts-expect-error TS2339 (typescriptify)
      this.fixedResponsiveMemo = null
    }
  }

  renderLoading() {
    return (
      <View key="spinner" display="block" padding="xx-large medium" textAlign="center">
        <Spinner renderTitle={() => I18n.t('Loading planner items')} size="medium" />
      </View>
    )
  }

  renderLoadingPast() {
    // @ts-expect-error TS2339 (typescriptify)
    if (this.props.isLoading) return
    // @ts-expect-error TS2339 (typescriptify)
    if (this.props.isWeekly) return
    return (
      <LoadingPastIndicator
        // @ts-expect-error TS2339 (typescriptify)
        loadingPast={this.props.loadingPast}
        // @ts-expect-error TS2339 (typescriptify)
        allPastItemsLoaded={this.props.allPastItemsLoaded}
        // @ts-expect-error TS2339 (typescriptify)
        loadingError={this.props.loadingError}
      />
    )
  }

  renderLoadMore() {
    // @ts-expect-error TS2339 (typescriptify)
    if (this.props.isLoading || this.props.loadingPast) return
    // @ts-expect-error TS2339 (typescriptify)
    if (this.props.isWeekly) return
    return (
      <LoadingFutureIndicator
        // @ts-expect-error TS2339 (typescriptify)
        loadingFuture={this.props.loadingFuture}
        // @ts-expect-error TS2339 (typescriptify)
        allFutureItemsLoaded={this.props.allFutureItemsLoaded}
        // @ts-expect-error TS2339 (typescriptify)
        loadingError={this.props.loadingError}
        // @ts-expect-error TS2339 (typescriptify)
        onLoadMore={this.props.loadFutureItems}
        // @ts-expect-error TS2339,TS2769 (typescriptify)
        plannerActive={this.props.plannerActive}
      />
    )
  }

  renderLoadPastButton() {
    // @ts-expect-error TS2339 (typescriptify)
    if (this.props.allPastItemsLoaded) return
    // @ts-expect-error TS2339 (typescriptify)
    if (this.props.isWeekly) return
    return (
      <View as="div" textAlign="center" margin="x-small 0 0 0">
        <ShowOnFocusButton
          // @ts-expect-error TS2339 (typescriptify)
          elementRef={ref => (this.loadPriorButton = ref)}
          buttonProps={{
            // @ts-expect-error TS2339 (typescriptify)
            onClick: this.props.loadPastButtonClicked,
          }}
        >
          {I18n.t('Load prior dates')}
        </ShowOnFocusButton>
      </View>
    )
  }

  renderNoAssignments() {
    if (
      // @ts-expect-error TS2339 (typescriptify)
      this.props.isWeekly &&
      // @ts-expect-error TS2339 (typescriptify)
      (this.props.opportunityCount || this.props.loadingOpportunities) &&
      // @ts-expect-error TS2339 (typescriptify)
      isThisWeek(this.props.thisWeek.weekStart)
    ) {
      // @ts-expect-error TS2339 (typescriptify)
      const today = moment.tz(this.props.timeZone).startOf('day')
      return this.renderOneDay(today, formatDayKey(today), [], 0)
    }

    return (
      <PlannerEmptyState
        // @ts-expect-error TS2339 (typescriptify)
        changeDashboardView={this.props.changeDashboardView}
        // @ts-expect-error TS2339 (typescriptify)
        isCompletelyEmpty={this.props.isCompletelyEmpty}
        onAddToDo={this.onAddToDo}
        // @ts-expect-error TS2339 (typescriptify)
        responsiveSize={this.props.responsiveSize}
        // @ts-expect-error TS2339 (typescriptify)
        isWeekly={this.props.isWeekly}
      />
    )
  }

  // starting at firstEmptyDay, and ending on of before lastDay
  // return the number of days with no items
  // @ts-expect-error TS7006 (typescriptify)
  countEmptyDays(dayHash, firstEmptyDay, lastDay) {
    const trialDay = firstEmptyDay.clone()
    let trialDayKey = formatDayKey(trialDay)
    let numEmptyDays = 0
    while (
      (!dayHash[trialDayKey] || dayHash[trialDayKey].length === 0) &&
      (trialDay.isSame(lastDay) || trialDay.isBefore(lastDay))
    ) {
      ++numEmptyDays
      trialDay.add(1, 'days')
      trialDayKey = formatDayKey(trialDay)
    }
    return numEmptyDays
  }

  // return a sigle <Day> with items
  // advances workingDay to the next day
  // @ts-expect-error TS7006 (typescriptify)
  renderOneDay(workingDay, workingDayKey, dayItems, dayIndex) {
    const day = (
      <AnimatableDay
        // @ts-expect-error TS2339 (typescriptify)
        timeZone={this.props.timeZone}
        day={workingDayKey}
        itemsForDay={dayItems}
        animatableIndex={dayIndex}
        key={workingDayKey}
        // @ts-expect-error TS2339 (typescriptify)
        toggleCompletion={this.props.togglePlannerItemCompletion}
        // @ts-expect-error TS2339 (typescriptify)
        updateTodo={this.props.updateTodo}
        // @ts-expect-error TS2339 (typescriptify)
        currentUser={this.props.currentUser}
        // @ts-expect-error TS2339 (typescriptify)
        simplifiedControls={this.props.k5Mode}
        // @ts-expect-error TS2339 (typescriptify)
        singleCourseView={this.props.singleCourseView}
        // @ts-expect-error TS2339 (typescriptify)
        showMissingAssignments={this.props.k5Mode}
        // @ts-expect-error TS2339 (typescriptify)
        responsiveSize={this.props.responsiveSize}
        // @ts-expect-error TS2339 (typescriptify)
        isObserving={this.props.isObserving}
      />
    )
    workingDay.add(1, 'days')
    return day
  }

  // return an array of empty <Day> objects
  // advances workingDay to the day after the empty series of days
  // @ts-expect-error TS7006 (typescriptify)
  renderEmptyDays(numEmptyDays, workingDay, dayIndex) {
    const children = []
    for (let i = 0; i < numEmptyDays; ++i) {
      const workingDayKey = formatDayKey(workingDay)
      children.push(this.renderOneDay(workingDay, workingDayKey, [], dayIndex++))
    }
    return children
  }

  // return an <EmptyDays> for the given number of days, starting at workingDay
  // advances workingDay to the day after the empty series of days
  // @ts-expect-error TS7006 (typescriptify)
  renderEmptyDayStretch(numEmptyDays, workingDay, dayIndex) {
    const workingDayKey = formatDayKey(workingDay) // starting day key
    workingDay.add(numEmptyDays - 1, 'days') // ending day
    const endingDayKey = formatDayKey(workingDay) // ending day key
    const child = (
      <ThemedEmptyDays
        // @ts-expect-error TS2339 (typescriptify)
        timeZone={this.props.timeZone}
        day={workingDayKey}
        endday={endingDayKey}
        // @ts-expect-error TS2322 (typescriptify)
        animatableIndex={dayIndex++}
        key={workingDayKey}
        // @ts-expect-error TS2339 (typescriptify)
        updateTodo={this.props.updateTodo}
        // @ts-expect-error TS2339 (typescriptify)
        currentUser={this.props.currentUser}
        // @ts-expect-error TS2339 (typescriptify)
        responsiveSize={this.props.responsiveSize}
      />
    )
    workingDay.add(1, 'days') // step to the next day
    return child
  }

  // in the past, we only render Days that have items
  // the past starts on workingDay (presumably the first planner item we have),
  // and ends on lastDay.
  // advances workingDay to the day after lastDay
  // @ts-expect-error TS7006 (typescriptify)
  renderPast(workingDay, lastDay, dayHash, dayIndex) {
    const children = []
    while (workingDay.isSame(lastDay) || workingDay.isBefore(lastDay)) {
      const workingDayKey = formatDayKey(workingDay)
      const dayItems = dayHash[workingDayKey]
      if (dayItems && dayItems.length > 0) {
        children.push(this.renderOneDay(workingDay, workingDayKey, dayItems, dayIndex++))
      } else {
        workingDay.add(1, 'day')
      }
    }
    return children
  }

  // in the present, render every day, no matter what
  // the present starts at workingDay, ends on lastDay
  // advances workingDay to the day after lastDay
  // @ts-expect-error TS7006 (typescriptify)
  renderPresent(workingDay, lastDay, dayHash, dayIndex) {
    const children = []
    while (workingDay.isSame(lastDay) || workingDay.isBefore(lastDay)) {
      const workingDayKey = formatDayKey(workingDay)
      const dayItems = dayHash[workingDayKey] || []
      children.push(this.renderOneDay(workingDay, workingDayKey, dayItems, dayIndex++))
    }
    return children
  }

  // in the future, render stretches of 3 days together
  // the future starts at workindDay, ends on lastDay
  // advances workingDay to the day after lastDay
  // @ts-expect-error TS7006 (typescriptify)
  renderFuture(workingDay, lastDay, dayHash, dayIndex) {
    const children = []
    while (workingDay.isSame(lastDay) || workingDay.isBefore(lastDay)) {
      const workingDayKey = formatDayKey(workingDay)
      const dayItems = dayHash[workingDayKey]
      if (dayItems && dayItems.length > 0) {
        children.push(this.renderOneDay(workingDay, workingDayKey, dayItems, dayIndex++))
      } else {
        const numEmptyDays = this.countEmptyDays(dayHash, workingDay, lastDay)
        if (numEmptyDays < 3) {
          children.splice(
            children.length,
            0,
            ...this.renderEmptyDays(numEmptyDays, workingDay, dayIndex),
          )
          dayIndex += numEmptyDays
        } else {
          children.push(this.renderEmptyDayStretch(numEmptyDays, workingDay, dayIndex))
          ++dayIndex
        }
      }
    }
    return children
  }

  // starting at the date of the first props.days, and
  // ending at the last props.days (or today, whichever is later)
  // step a day at a time.
  // if the day is before yesterday, emit a <Day> only it if it has items
  // always render yesterday (if loaded), today, and tomorrow
  // starting with the day after tomorrow:
  //    if a day has items, emit a <Day>
  //    if we find a string of < 3 empty days, emit a <Day> for each
  //    if we find a string of 3 or more empty days, emit an <EmptyDays> for the interval
  renderDays() {
    // @ts-expect-error TS7034 (typescriptify)
    const children = []
    // @ts-expect-error TS2339 (typescriptify)
    const dayHash = daysToDaysHash(this.props.days)
    let dayIndex = 1

    // @ts-expect-error TS2339 (typescriptify)
    if (this.props.isWeekly) {
      return this.renderPresent(
        // @ts-expect-error TS2339 (typescriptify)
        this.props.thisWeek.weekStart.clone(),
        // @ts-expect-error TS2339 (typescriptify)
        this.props.thisWeek.weekEnd.clone(),
        dayHash,
        dayIndex,
      )
    }

    // @ts-expect-error TS2339 (typescriptify)
    const today = moment.tz(this.props.timeZone).startOf('day')
    // @ts-expect-error TS2339 (typescriptify)
    let workingDay = moment.tz(this.props.days[0][0], this.props.timeZone)
    if (workingDay.isAfter(today)) workingDay = today.clone()
    // @ts-expect-error TS2339 (typescriptify)
    let lastDay = moment.tz(this.props.days[this.props.days.length - 1][0], this.props.timeZone)
    let tomorrow = today.clone().add(1, 'day')
    const dayBeforeYesterday = today.clone().add(-2, 'day')
    if (lastDay.isBefore(today)) lastDay = today.clone()
    // We don't want to render an empty tomorrow if we don't know it's actually empty.
    // It might just not be loaded yet. If so, sneak it back to today so it isn't displayed.
    if (tomorrow.isAfter(lastDay)) tomorrow = today.clone()

    const pastChildren = this.renderPast(workingDay, dayBeforeYesterday, dayHash, dayIndex)
    dayIndex += pastChildren.length
    // @ts-expect-error TS7005 (typescriptify)
    children.splice(children.length, 0, ...pastChildren)

    const presentChildren = this.renderPresent(workingDay, tomorrow, dayHash, dayIndex)
    dayIndex += presentChildren.length
    // @ts-expect-error TS7005 (typescriptify)
    children.splice(children.length, 0, ...presentChildren)

    const futureChildren = this.renderFuture(workingDay, lastDay, dayHash, dayIndex)
    // @ts-expect-error TS7005 (typescriptify)
    children.splice(children.length, 0, ...futureChildren)

    // @ts-expect-error TS7005 (typescriptify)
    return children
  }

  // @ts-expect-error TS7006 (typescriptify)
  renderBody(children) {
    // @ts-expect-error TS2339 (typescriptify)
    if (this.props.isWeekly) return children

    const loading =
      // @ts-expect-error TS2339 (typescriptify)
      this.props.loadingPast ||
      // @ts-expect-error TS2339 (typescriptify)
      this.props.loadingFuture ||
      // @ts-expect-error TS2339 (typescriptify)
      this.props.loadingWeek ||
      // @ts-expect-error TS2339 (typescriptify)
      this.props.isLoading
    if (children.length === 0 && !loading) {
      return (
        <>
          {this.renderLoadPastButton()}
          {this.renderNoAssignments()}
        </>
      )
    }

    return (
      <>
        {this.renderLoadPastButton()}
        {this.renderLoadingPast()}
        {children}
        <div id="planner-app-fixed-element" ref={this.fixedElementRef} />
        {this.renderLoadMore()}
      </>
    )
  }

  render() {
    // @ts-expect-error TS2339 (typescriptify)
    const clazz = classnames('PlannerApp', this.props.responsiveSize)
    let children = []
    if (
      // @ts-expect-error TS2339 (typescriptify)
      (this.props.isWeekly && !this.props.weekLoaded) ||
      // @ts-expect-error TS2339 (typescriptify)
      (!this.props.isWeekly && this.props.isLoading)
    ) {
      children = [this.renderLoading()]
      // @ts-expect-error TS2339 (typescriptify)
    } else if (this.props.days.length > 0 || this.props.isWeekly) {
      children = this.renderDays()
    }
    children = this.renderBody(children)
    return (
      // @ts-expect-error TS2339 (typescriptify)
      <div className={clazz} ref={el => (this._plannerElem = el)} data-testid="PlannerApp">
        {children}
      </div>
    )
  }
}

// @ts-expect-error TS7006 (typescriptify)
export const mapStateToProps = state => {
  const weeks = state.weeklyDashboard?.weeks
  return {
    days: state.days,
    isLoading: state.loading.isLoading || state.loading.hasSomeItems === null,
    loadingPast: state.loading.loadingPast,
    allPastItemsLoaded: state.loading.allPastItemsLoaded,
    loadingFuture: state.loading.loadingFuture,
    allFutureItemsLoaded: state.loading.allFutureItemsLoaded,
    loadingWeek: state.loading.loadingWeek,
    loadingError: state.loading.loadingError,
    timeZone: state.timeZone,
    isCompletelyEmpty:
      state.loading.hasSomeItems === false &&
      state.days.length === 0 &&
      state.loading.partialPastDays.length === 0 &&
      state.loading.partialFutureDays.length === 0 &&
      state.loading.partialWeekDays.length === 0,
    thisWeek: state.weeklyDashboard && {
      weekStart: state.weeklyDashboard.weekStart,
      weekEnd: state.weeklyDashboard.weekEnd,
    },
    weekLoaded: weeks ? !!weeks[state.weeklyDashboard.weekStart.format()] : false,
    loadingOpportunities: !!state.loading.loadingOpportunities,
    opportunityCount: state.opportunities?.items?.length || 0,
    singleCourseView: state.singleCourse,
    isObserving: !!observedUserId(state),
    observeduserId: observedUserId(state),
    observedUserContextCodes: observedUserContextCodes(state),
  }
}

const ResponsivePlannerApp = responsiviser()(PlannerApp)
const mapDispatchToProps = {
  loadFutureItems,
  loadPastButtonClicked,
  togglePlannerItemCompletion,
  updateTodo,
  scrollToToday,
}
export default notifier(connect(mapStateToProps, mapDispatchToProps)(ResponsivePlannerApp))
