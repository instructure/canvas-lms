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

import React, { Component } from 'react';
import classnames from 'classnames';
import moment from 'moment-timezone';
import { connect } from 'react-redux';
import View from '@instructure/ui-layout/lib/components/View';
import Spinner from '@instructure/ui-elements/lib/components/Spinner';
import { arrayOf, oneOfType, shape, bool, object, string, number, func } from 'prop-types';
import { userShape, sizeShape } from '../plannerPropTypes';
import Day from '../Day';
import EmptyDays from '../EmptyDays';
import ShowOnFocusButton from '../ShowOnFocusButton';
import LoadingFutureIndicator from '../LoadingFutureIndicator';
import LoadingPastIndicator from '../LoadingPastIndicator';
import PlannerEmptyState from '../PlannerEmptyState';
import formatMessage from '../../format-message';
import {loadFutureItems, loadPastButtonClicked, loadPastUntilNewActivity, togglePlannerItemCompletion, updateTodo} from '../../actions';
import {notifier} from '../../dynamic-ui';
import {daysToDaysHash} from '../../utilities/daysUtils';
import {formatDayKey} from '../../utilities/dateUtils';
import {Animator} from '../../dynamic-ui/animator';
import responsiviser from '../responsiviser';

export class PlannerApp extends Component {
  static propTypes = {
    days: arrayOf(
      arrayOf(
        oneOfType([/* date */ string, arrayOf(/* items */ object)])
      )
    ),
    timeZone: string,
    isLoading: bool,
    loadingPast: bool,
    loadingError: string,
    allPastItemsLoaded: bool,
    loadingFuture: bool,
    allFutureItemsLoaded: bool,
    loadPastButtonClicked: func,
    loadPastUntilNewActivity: func,
    loadFutureItems: func,
    stickyOffset: number, // in pixels
    changeDashboardView: func,
    togglePlannerItemCompletion: func,
    updateTodo: func,
    triggerDynamicUiUpdates: func,
    preTriggerDynamicUiUpdates: func,
    plannerActive: func,
    currentUser: shape(userShape),
    responsiveSize: sizeShape,
    appRef: func,
    focusFallback: func,
  };
  static defaultProps = {
    isLoading: false,
    stickyOffset: 0,
    triggerDynamicUiUpdates: () => {},
    preTriggerDynamicUiUpdates: () => {},
    plannerActive: () => {return false;},
    responsiveSize: 'large',
    appRef: () => {},
    focusFallback: () => {},
    isCompletelyEmpty: bool,
  };

  constructor (props) {
    super(props);
    this.animator = null;
    this._plannerElem = null;
    this.fixedResponsiveMemo = null;
  }

  componentWillMount () {
    this.props.appRef(this);
    window.addEventListener('resize', this.onResize, false);
  }

  componentWillUpdate (nextProps) {
    if (this.props.allPastItemsLoaded === false && nextProps.allPastItemsLoaded === true) {
      if (this.loadPriorButton === document.activeElement) {
        this.props.focusFallback();
      }
    }
    this.props.preTriggerDynamicUiUpdates();
  }

  componentDidUpdate (prevProps) {
    const additionalOffset = this.newActivityButtonRef ?
      this.newActivityButtonRef.getBoundingClientRect().height :
      0;
    this.props.triggerDynamicUiUpdates(additionalOffset);
    if (this.props.responsiveSize !== prevProps.responsiveSize) {
      this.afterLayoutChange();
    }
  }

  componentWillUnmount () {
    this.props.appRef(null);
    window.removeEventListenet('resize', this.onResize, false);
  }

  fixedElementForItemScrolling () { return this.fixedElement; }

  fixedElementRef = (elt) => {
    this.fixedElement = elt;
  }

  // when the planner changes layout, its contents move and the user gets lost.
  // let's help with that.

  // First, when the user starts to resize the window, call beforeLayoutChange
    resizeTimer = 0;
  onResize = (event) => {
    if (this.resizeTimer === 0) {
      this.resizeTimer = window.setTimeout(() => {this.resizeTimer = 0;}, 1000);
      this.beforeLayoutChange();
    }
  }

  onAddToDo = (event) => {
    event.preventDefault();
    this.props.updateTodo({updateTodoItem: {}});
  }

  // before we tell the responsive elements the size has changed, find the first
  // visible day or grouping and remember its position.
  beforeLayoutChange () {
    function findFirstVisible(selector) {
      const list = plannerTop.querySelectorAll(selector);
      const elem = Array.prototype.find.call(list, el => el.getBoundingClientRect().top > 0);
      return elem;
    }
    const plannerTop = this._plannerElem || document;
    const fixedResponsiveElem = findFirstVisible('.planner-day, .planner-grouping, .planner-empty-days');
    if (fixedResponsiveElem) {
      if (!this.animator) this.animator = new Animator();
      this.fixedResponsiveMemo = this.animator.elementPositionMemo(fixedResponsiveElem);
    }
  }
  // after the re-layout, put the cached element back to where it was
  afterLayoutChange = () => {
    if (this.fixedResponsiveMemo) {
      this.animator.maintainViewportPositionFromMemo(this.fixedResponsiveMemo.element, this.fixedResponsiveMemo);
      this.fixedResponsiveMemo = null;
    }
  }

  renderLoading () {
    return <View
      display="block"
      padding="xx-large medium"
      textAlign="center"
    >
      <Spinner
        title={formatMessage('Loading planner items')}
        size="medium"
      />
    </View>;
  }

  renderLoadingPast () {
    if (this.props.isLoading) return;
    return <LoadingPastIndicator
      loadingPast={this.props.loadingPast}
      allPastItemsLoaded={this.props.allPastItemsLoaded}
      loadingError={this.props.loadingError} />;
  }

  renderLoadMore () {
    if (this.props.isLoading || this.props.loadingPast) return;
    return <LoadingFutureIndicator
      loadingFuture={this.props.loadingFuture}
      allFutureItemsLoaded={this.props.allFutureItemsLoaded}
      loadingError={this.props.loadingError}
      onLoadMore={this.props.loadFutureItems}
      plannerActive={this.props.plannerActive} />;
  }

  renderLoadPastButton () {
    if (this.props.allPastItemsLoaded) return;
    return <View as="div" textAlign="center">
      <ShowOnFocusButton
        buttonRef={ref => this.loadPriorButton = ref}
        buttonProps={{
          onClick: this.props.loadPastButtonClicked
        }}
        >
          {formatMessage('Load prior dates')}
      </ShowOnFocusButton>
    </View>;
  }

  renderNoAssignments() {
    return (
      <PlannerEmptyState
        changeDashboardView={this.props.changeDashboardView}
        isCompletelyEmpty={this.props.isCompletelyEmpty}
        onAddToDo={this.onAddToDo}
      />
    );
  }

  // starting at firstEmptyDay, and ending on of before lastDay
  // return the number of days with no items
  countEmptyDays (dayHash, firstEmptyDay, lastDay) {
    let trialDay = firstEmptyDay.clone();
    let trialDayKey = formatDayKey(trialDay);
    let numEmptyDays = 0;
    while( (!dayHash[trialDayKey] || dayHash[trialDayKey].length === 0) && (trialDay.isSame(lastDay) || trialDay.isBefore(lastDay)) ) {
      ++numEmptyDays;
      trialDay.add(1, 'days');
      trialDayKey = formatDayKey(trialDay);
    }
    return numEmptyDays;
  }

  // return a sigle <Day> with items
  // advances workingDay to the next day
  renderOneDay (workingDay, workingDayKey, dayItems, dayIndex) {
    const day = <Day
      timeZone={this.props.timeZone}
      day={workingDayKey}
      itemsForDay={dayItems}
      animatableIndex={dayIndex}
      key={workingDayKey}
      toggleCompletion={this.props.togglePlannerItemCompletion}
      updateTodo={this.props.updateTodo}
      currentUser={this.props.currentUser}
    />;
    workingDay.add(1, 'days');
    return day;
  }

  // return an array of empty <Day> objects
  // advances workingDay to the day after the empty series of days
  renderEmptyDays (numEmptyDays, workingDay, dayIndex) {
    let children = [];
    for (let i = 0; i < numEmptyDays; ++i) {
      const workingDayKey = formatDayKey(workingDay);
      children.push(this.renderOneDay(workingDay, workingDayKey, [], dayIndex++));
    }
    return children;
  }

  // return an <EmptyDays> for the given number of days, starting at workingDay
  // advances workingDay to the day after the empty series of days
  renderEmptyDayStretch (numEmptyDays, workingDay, dayIndex) {
    const workingDayKey = formatDayKey(workingDay); // starting day key
    workingDay.add(numEmptyDays-1, 'days');         // ending day
    const endingDayKey = formatDayKey(workingDay);  // ending day key
    const child = (
      <EmptyDays
        timeZone={this.props.timeZone}
        day={workingDayKey}
        endday={endingDayKey}
        animatableIndex={dayIndex++}
        key={workingDayKey}
        updateTodo={this.props.updateTodo}
        currentUser={this.props.currentUser}
      />
    );
    workingDay.add(1, 'days');  // step to the next day
    return child;
  }

  // in the past, we only render Days that have items
  // the past starts on workingDay (presumably the first planner item we have),
  // and ends on lastDay.
  // advances workingDay to the day after lastDay
  renderPast (workingDay, lastDay, dayHash, dayIndex) {
    const children = [];
    while (workingDay.isSame(lastDay) || workingDay.isBefore(lastDay)) {
      const workingDayKey = formatDayKey(workingDay);
      const dayItems = dayHash[workingDayKey];
      if (dayItems && dayItems.length > 0) {
        children.push(this.renderOneDay(workingDay, workingDayKey, dayItems, dayIndex++));
      } else {
        workingDay.add(1, 'day');
      }
    }
    return children;
  }

  // in the present, render every day, no matter what
  // the present starts at workingDay, ends on lastDay
  // advances workingDay to the day after lastDay
  renderPresent (workingDay, lastDay, dayHash, dayIndex) {
    const children = [];
    while (workingDay.isSame(lastDay) || workingDay.isBefore(lastDay)) {
      const workingDayKey = formatDayKey(workingDay);
      const dayItems = dayHash[workingDayKey] || [];
      children.push(this.renderOneDay(workingDay, workingDayKey, dayItems, dayIndex++));
    }
    return children;
  }

  // in the future, render stretches of 3 days together
  // the future starts at workindDay, ends on lastDay
  // advances workingDay to the day after lastDay
  renderFuture (workingDay, lastDay, dayHash, dayIndex) {
    const children = [];
    while (workingDay.isSame(lastDay) || workingDay.isBefore(lastDay)) {
      let workingDayKey = formatDayKey(workingDay);
      const dayItems = dayHash[workingDayKey];
      if (dayItems && dayItems.length > 0) {
        children.push(this.renderOneDay(workingDay, workingDayKey, dayItems, dayIndex++));
      } else {
        const numEmptyDays = this.countEmptyDays(dayHash, workingDay, lastDay);
        if (numEmptyDays < 3) {
          children.splice(children.length, 0, ...this.renderEmptyDays(numEmptyDays, workingDay, dayIndex));
          dayIndex += numEmptyDays;
        } else {
          children.push(this.renderEmptyDayStretch(numEmptyDays, workingDay, dayIndex));
          ++dayIndex;
        }
      }
    }
    return children;
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
  renderDays () {
    const children = [];
    const today = moment.tz(this.props.timeZone).startOf('day');
    let workingDay = moment.tz(this.props.days[0][0], this.props.timeZone);
    if (workingDay.isAfter(today)) workingDay = today.clone();
    let lastDay = moment.tz(this.props.days[this.props.days.length-1][0], this.props.timeZone);
    let tomorrow = today.clone().add(1, 'day');
    const dayBeforeYesterday = today.clone().add(-2, 'day');
    if (lastDay.isBefore(today)) lastDay = today.clone();
    // We don't want to render an empty tomorrow if we don't know it's actually empty.
    // It might just not be loaded yet. If so, sneak it back to today so it isn't displayed.
    if (tomorrow.isAfter(lastDay)) tomorrow = today.clone();
    const dayHash = daysToDaysHash(this.props.days);
    let dayIndex = 1;

    const pastChildren = this.renderPast(workingDay, dayBeforeYesterday, dayHash, dayIndex);
    dayIndex += pastChildren.length;
    children.splice(children.length, 0, ...pastChildren);

    const presentChildren = this.renderPresent(workingDay, tomorrow, dayHash, dayIndex);
    dayIndex += presentChildren.length;
    children.splice(children.length, 0, ...presentChildren);

    const futureChildren = this.renderFuture(workingDay, lastDay, dayHash, dayIndex);
    children.splice(children.length, 0, ...futureChildren);
    return children;
  }

  renderBody (children, classes) {
    const loading = this.props.loadingPast || this.props.loadingFuture || this.props.isLoading;
    if (children.length === 0 && !loading) {
      return <div className={classes}>
        {this.renderLoadPastButton()}
        {this.renderNoAssignments()}
      </div>;
    }

    return <div className={classes} ref={el => this._plannerElem = el}>
      {this.renderLoadPastButton()}
      {this.renderLoadingPast()}
      {children}
      <div id="planner-app-fixed-element" ref={this.fixedElementRef} />
      {this.renderLoadMore()}
    </div>;
  }

  render () {
    const clazz = classnames('PlannerApp', this.props.responsiveSize);
    let children = [];
    if (this.props.isLoading) {
      children = this.renderLoading();
    } else if (this.props.days.length > 0 ) {
      children = this.renderDays();
    }
    return this.renderBody(children, clazz);
  }
}

export const mapStateToProps = (state) => {
  return {
    days: state.days,
    isLoading: state.loading.isLoading || state.loading.hasSomeItems === null,
    loadingPast: state.loading.loadingPast,
    allPastItemsLoaded: state.loading.allPastItemsLoaded,
    loadingFuture: state.loading.loadingFuture,
    allFutureItemsLoaded: state.loading.allFutureItemsLoaded,
    loadingError: state.loading.loadingError,
    timeZone: state.timeZone,
    isCompletelyEmpty:  state.loading.hasSomeItems === false &&
                        state.days.length === 0 &&
                        state.loading.partialPastDays.length === 0 &&
                        state.loading.partialFutureDays.length === 0,
  };
};

const ResponsivePlannerApp = responsiviser()(PlannerApp);
const mapDispatchToProps = {loadFutureItems, loadPastButtonClicked, loadPastUntilNewActivity, togglePlannerItemCompletion, updateTodo};
export default notifier(connect(mapStateToProps, mapDispatchToProps)(ResponsivePlannerApp));
