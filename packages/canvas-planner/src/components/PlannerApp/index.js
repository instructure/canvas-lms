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
import classnames from 'classnames';
import { connect } from 'react-redux';
import Container from '@instructure/ui-core/lib/components/Container';
import Spinner from '@instructure/ui-core/lib/components/Spinner';
import { arrayOf, oneOfType, shape, bool, object, string, number, func } from 'prop-types';
import { momentObj } from 'react-moment-proptypes';
import { userShape, sizeShape } from '../plannerPropTypes';
import Day from '../Day';
import ShowOnFocusButton from '../ShowOnFocusButton';
import StickyButton from '../StickyButton';
import LoadingFutureIndicator from '../LoadingFutureIndicator';
import LoadingPastIndicator from '../LoadingPastIndicator';
import PlannerEmptyState from '../PlannerEmptyState';
import formatMessage from '../../format-message';
import {loadFutureItems, loadPastButtonClicked, loadPastUntilNewActivity, scrollToNewActivity, togglePlannerItemCompletion, updateTodo} from '../../actions';
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
    loadPastButtonClicked: func,
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
    ui: shape({
      naiAboveScreen: bool,
    }),
    currentUser: shape(userShape),
    size: sizeShape,
  };
  static defaultProps = {
    isLoading: false,
    stickyOffset: 0,
    triggerDynamicUiUpdates: () => {},
    preTriggerDynamicUiUpdates: () => {},
    plannerActive: () => {return false;},
    size: 'large',
  };

  componentWillUpdate () {
    this.props.preTriggerDynamicUiUpdates(this.fixedElement, 'app');
  }

  componentDidUpdate () {
    const additionalOffset = this.newActivityButtonRef ?
      this.newActivityButtonRef.getBoundingClientRect().height :
      0;
    this.props.triggerDynamicUiUpdates(additionalOffset);
  }

  fixedElementRef = (elt) => {
    this.fixedElement = elt;
  }

  handleNewActivityClick = () => {
    this.props.scrollToNewActivity();
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
    const firstNewActivityLoaded = firstLoadedMoment.isSame(this.props.firstNewActivityDate) || firstLoadedMoment.isBefore(this.props.firstNewActivityDate);
    if (firstNewActivityLoaded && !this.props.ui.naiAboveScreen) return;

    return (
      <StickyButton
        direction="up"
        hidden={true}
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
    return (
      <ShowOnFocusButton
        buttonProps={{
          onClick: this.props.loadPastButtonClicked
        }}
        >
          {formatMessage('Load prior dates')}
      </ShowOnFocusButton>
    );
  }

  renderNoAssignments() {
    return (
      <PlannerEmptyState changeToDashboardCardView={this.props.changeToDashboardCardView}/>
    );
  }

  renderBody (children, classes) {

    const loading = this.props.loadingPast || this.props.loadingFuture || this.props.isLoading;
    if (children.length === 0 && !loading) {
      return <div className={classes}>
        {this.renderNewActivity()}
        {this.renderLoadPastButton()}
        {this.renderNoAssignments()}
      </div>;
    }

    return <div className={classes}>
      {this.renderNewActivity()}
      {this.renderLoadPastButton()}
      {this.renderLoadingPast()}
      {children}
      {this.renderLoadMore()}
      <div id="planner-app-fixed-element" ref={this.fixedElementRef} />
    </div>;
  }

  render () {
    const clazz = classnames('PlannerApp', this.props.size);
    let children;
    if (this.props.isLoading) {
      children = this.renderLoading();
    } else {
      children = this.props.days.map(([dayKey, dayItems], dayIndex) => {
        return <Day
          timeZone={this.props.timeZone}
          day={dayKey}
          itemsForDay={dayItems}
          animatableIndex={dayIndex}
          key={dayKey}
          toggleCompletion={this.props.togglePlannerItemCompletion}
          updateTodo={this.props.updateTodo}
          currentUser={this.props.currentUser}
        />;
      });
    }
    return this.renderBody(children, clazz);
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
    ui: state.ui,
  };
};

const mapDispatchToProps = {loadFutureItems, loadPastButtonClicked, loadPastUntilNewActivity, scrollToNewActivity, togglePlannerItemCompletion, updateTodo};
export default notifier(connect(mapStateToProps, mapDispatchToProps)(PlannerApp));
