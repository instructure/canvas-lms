/*
 * Copyright (C) 2017 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that they will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */
import React, { Component } from 'react';
import { connect } from 'react-redux';
import Container from '@instructure/ui-core/lib/components/Container';
import Spinner from '@instructure/ui-core/lib/components/Spinner';
import { arrayOf, oneOfType, bool, object, string, number, func } from 'prop-types';
import { momentObj } from 'react-moment-proptypes';
import Day from '../Day';
import ShowOnFocusButton from '../ShowOnFocusButton';
import StickyButton from '../StickyButton';
import LoadingFutureIndicator from '../LoadingFutureIndicator';
import LoadingPastIndicator from '../LoadingPastIndicator';
import PlannerEmptyState from '../PlannerEmptyState';
import formatMessage from '../../format-message';
import {loadFutureItems, scrollIntoPast, loadPastUntilNewActivity, scrollToNewActivity, togglePlannerItemCompletion, updateTodo} from '../../actions';
import {getFirstLoadedMoment} from '../../utilities/dateUtils';
import {notifier} from '../../dynamic-ui';

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
    firstNewActivityDate: momentObj,
    scrollIntoPast: func,
    loadPastUntilNewActivity: func,
    scrollToNewActivity: func,
    loadFutureItems: func,
    stickyOffset: number, // in pixels
    stickyZIndex: number,
    changeToDashboardCardView: func,
    togglePlannerItemCompletion: func,
    updateTodo: func,
    triggerDynamicUiUpdates: func,
    preTriggerDynamicUiUpdates: func,
    plannerActive: func,
  };

  static defaultProps = {
    isLoading: false,
    stickyOffset: 0,
    triggerDynamicUiUpdates: () => {},
    preTriggerDynamicUiUpdates: () => {},
    plannerActive: () => {return false}
  };

  componentWillUpdate () {
    this.props.preTriggerDynamicUiUpdates(this.fixedElement, 'app');
  }

  componentDidUpdate () {
    this.props.triggerDynamicUiUpdates(this.fixedElement);
  }

  fixedElementRef = (elt) => {
    this.fixedElement = elt;
  }

  handleNewActivityClick = () => {
    let additionalOffset = 0;
    if (this.newActivityButtonRef) additionalOffset = this.newActivityButtonRef.getBoundingClientRect().height;
    this.props.scrollToNewActivity({additionalOffset});
  }

  renderLoading () {
    return <Container
      display="block"
      padding="xx-large medium"
      textAlign="center"
    >
      <Spinner
        title={formatMessage('Loading planner items')}
        size="medium"
      />
    </Container>;
  }

  renderNewActivity () {
    if (this.props.isLoading) return;
    if (!this.props.firstNewActivityDate) return;

    const firstLoadedMoment = getFirstLoadedMoment(this.props.days, this.props.timeZone);
    if (firstLoadedMoment.isSame(this.props.firstNewActivityDate) || firstLoadedMoment.isBefore(this.props.firstNewActivityDate)) return;

    return (
      <StickyButton
        direction="up"
        onClick={this.handleNewActivityClick}
        offset={this.props.stickyOffset + 'px'}
        zIndex={this.props.stickyZIndex}
        buttonRef={ref => this.newActivityButtonRef = ref}
      >
        {formatMessage("New Activity")}
      </StickyButton>
    );
  }

  renderLoadingPast () {
    return <LoadingPastIndicator
      loadingPast={this.props.loadingPast}
      allPastItemsLoaded={this.props.allPastItemsLoaded}
      loadingError={this.props.loadingError} />;
  }

  renderLoadMore () {
    if (this.props.isLoading) return;
    return <LoadingFutureIndicator
      loadingFuture={this.props.loadingFuture}
      allFutureItemsLoaded={this.props.allFutureItemsLoaded}
      loadingError={this.props.loadingError}
      onLoadMore={this.props.loadFutureItems}
      plannerActive={this.props.plannerActive} />;
  }

  renderLoadPastButton () {
    return (
      <ShowOnFocusButton
        buttonProps={{
          onClick: this.props.scrollIntoPast
        }}
        >
          {formatMessage('Load prior dates')}
      </ShowOnFocusButton>
    );
  }

  renderNoAssignments() {
    return (
      <div>
        {this.renderLoadPastButton()}
        <PlannerEmptyState changeToDashboardCardView={this.props.changeToDashboardCardView}/>
      </div>
    );
  }

  renderBody (children) {

    if (children.length === 0) {
      return <div>
        {this.renderNewActivity()}
        {this.renderNoAssignments()}
      </div>;
    }

    return <div className="PlannerApp">
      {this.renderNewActivity()}
      {this.renderLoadPastButton()}
      {this.renderLoadingPast()}
      {children}
      {this.renderLoadMore()}
      <div id="planner-app-fixed-element" ref={this.fixedElementRef} />
    </div>;
  }

  render () {
    if (this.props.isLoading) {
      return this.renderBody(this.renderLoading());
    }

    const children = this.props.days.map(([dayKey, dayItems], dayIndex) => {
      return <Day
        timeZone={this.props.timeZone}
        day={dayKey}
        itemsForDay={dayItems}
        animatableIndex={dayIndex}
        key={dayKey}
        toggleCompletion={this.props.togglePlannerItemCompletion}
        updateTodo={this.props.updateTodo}
      />;
    });

    return this.renderBody(children);
  }
}

const mapStateToProps = (state) => {
  return {
    days: state.days,
    isLoading: state.loading.isLoading,
    loadingPast: state.loading.loadingPast,
    allPastItemsLoaded: state.loading.allPastItemsLoaded,
    loadingFuture: state.loading.loadingFuture,
    allFutureItemsLoaded: state.loading.allFutureItemsLoaded,
    loadingError: state.loading.loadingError,
    firstNewActivityDate: state.firstNewActivityDate,
    timeZone: state.timeZone,
  };
};

const mapDispatchToProps = {loadFutureItems, scrollIntoPast, loadPastUntilNewActivity, scrollToNewActivity, togglePlannerItemCompletion, updateTodo};
export default notifier(connect(mapStateToProps, mapDispatchToProps)(PlannerApp));
