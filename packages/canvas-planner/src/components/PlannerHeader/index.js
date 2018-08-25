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
import themeable from '@instructure/ui-themeable/lib';
import Button from '@instructure/ui-buttons/lib/components/Button';
import CloseButton from '@instructure/ui-buttons/lib/components/CloseButton';
import ScreenReaderContent from '@instructure/ui-a11y/lib/components/ScreenReaderContent';
import View from '@instructure/ui-layout/lib/components/View';
import Portal from '@instructure/ui-portal/lib/components/Portal';
import IconPlusLine from '@instructure/ui-icons/lib/Line/IconPlus';
import IconAlertsLine from '@instructure/ui-icons/lib/Line/IconAlerts';
import IconGradebookLine from '@instructure/ui-icons/lib/Line/IconGradebook';
import Popover, {PopoverTrigger, PopoverContent} from '@instructure/ui-overlays/lib/components/Popover';
import PropTypes from 'prop-types';
import UpdateItemTray from '../UpdateItemTray';
import Tray from '@instructure/ui-overlays/lib/components/Tray';
import Badge from '@instructure/ui-elements/lib/components/Badge';
import Opportunities from '../Opportunities';
import GradesDisplay from '../GradesDisplay';
import StickyButton from '../StickyButton';
import { isFutureEmpty } from '../../utilities/statusUtils';

import {
  addDay, savePlannerItem, deletePlannerItem, cancelEditingPlannerItem, openEditingPlannerItem, getNextOpportunities,
  getInitialOpportunities, dismissOpportunity, clearUpdateTodo, startLoadingGradesSaga, scrollToToday,
  scrollToNewActivity
} from '../../actions';

import { courseShape, opportunityShape } from '../plannerPropTypes';
import styles from './styles.css';
import theme from './theme.js';
import formatMessage from '../../format-message';
import {notifier} from '../../dynamic-ui';
import {getFirstLoadedMoment} from "../../utilities/dateUtils";
import {momentObj} from "react-moment-proptypes";

export class PlannerHeader extends Component {

  static propTypes = {
    courses: PropTypes.arrayOf(PropTypes.shape(courseShape)).isRequired,
    addDay: PropTypes.func,
    savePlannerItem: PropTypes.func.isRequired,
    deletePlannerItem: PropTypes.func.isRequired,
    cancelEditingPlannerItem: PropTypes.func,
    openEditingPlannerItem: PropTypes.func,
    triggerDynamicUiUpdates: PropTypes.func,
    preTriggerDynamicUiUpdates: PropTypes.func,
    scrollToToday: PropTypes.func,
    scrollToNewActivity: PropTypes.func,
    locale: PropTypes.string.isRequired,
    timeZone: PropTypes.string.isRequired,
    opportunities: PropTypes.shape(opportunityShape).isRequired,
    getInitialOpportunities: PropTypes.func.isRequired,
    getNextOpportunities: PropTypes.func.isRequired,
    dismissOpportunity: PropTypes.func.isRequired,
    clearUpdateTodo: PropTypes.func.isRequired,
    startLoadingGradesSaga: PropTypes.func.isRequired,
    firstNewActivityDate: momentObj,
    days: PropTypes.arrayOf(
      PropTypes.arrayOf(
        PropTypes.oneOfType([/* date */ PropTypes.string, PropTypes.arrayOf(/* items */ PropTypes.object)])
      )
    ),
    ui: PropTypes.shape({
      naiAboveScreen: PropTypes.bool,
    }),
    todo: PropTypes.shape({
      updateTodoItem: PropTypes.shape({
        title: PropTypes.string,
      }),
    }),
    stickyZIndex: PropTypes.number,
    loading: PropTypes.shape({
      isLoading: PropTypes.bool,
      allPastItemsLoaded: PropTypes.bool,
      allFutureItemsLoaded: PropTypes.bool,
      allOpportunitiesLoaded: PropTypes.bool,
      loadingOpportunities:  PropTypes.bool,
      setFocusAfterLoad: PropTypes.bool,
      firstNewDayKey: PropTypes.object,
      futureNextUrl: PropTypes.string,
      pastNextUrl: PropTypes.string,
      seekingNewActivity: PropTypes.bool,
      loadingGrades: PropTypes.bool,
      gradesLoaded: PropTypes.bool,
      gradesLoadingError: PropTypes.string,
    }).isRequired,
    ariaHideElement: PropTypes.instanceOf(Element).isRequired,
    auxElement: PropTypes.instanceOf(Element).isRequired
  };

  static defaultProps = {
    triggerDynamicUiUpdates: () => {},
    preTriggerDynamicUiUpdates: () => {},
    stickyZIndex: 0
  }

  constructor (props) {
    super(props);

    this.state = {
      opportunities: props.opportunities.items,
      trayOpen: false,
      gradesTrayOpen: false,
      opportunitiesOpen: false,
      dismissedTabSelected: false
    };
  }

  componentDidMount() {
    this.props.getInitialOpportunities();
  }

  componentWillReceiveProps(nextProps) {
    let opportunities = nextProps.opportunities.items.filter((opportunity) => this.isOpportunityVisible(opportunity));

    if (!nextProps.loading.allOpportunitiesLoaded &&
        !nextProps.loading.loadingOpportunities) {
      nextProps.getNextOpportunities();
    }

    if (this.props.todo.updateTodoItem !== nextProps.todo.updateTodoItem) {
      this.setUpdateItemTray(!!nextProps.todo.updateTodoItem);
    }
    if (this.props.opportunities !== opportunities) {
      this.setState({opportunities});
    }
  }

  componentWillUpdate () {
    this.props.preTriggerDynamicUiUpdates();
  }

  componentDidUpdate () {
    if (this.props.todo.updateTodoItem) {
      this.toggleAriaHiddenStuff(this.state.trayOpen);
    }
    this.props.triggerDynamicUiUpdates();
  }

  handleSavePlannerItem = (plannerItem) => {
    this.handleCloseTray();
    this.props.savePlannerItem(plannerItem);
  }

  handleDeletePlannerItem = (plannerItem) => {
    this.handleCloseTray();
    this.props.deletePlannerItem(plannerItem);
  }

  handleCloseTray = () => {
    this.setUpdateItemTray(false);
  }

  handleToggleTray = () => {
    if(this.state.trayOpen) {
      this.handleCloseTray();
    } else {
      this.setUpdateItemTray(true);
    }
  }

  // sets the tray open state and tells dynamic-ui what just happened
  // via open/cancelEditingPlannerItem
  setUpdateItemTray (trayOpen) {
    if (trayOpen) {
      if (this.props.openEditingPlannerItem) {
        this.props.openEditingPlannerItem();  // tell dynamic-ui we've started editing
      }
    } else {
      if (this.props.cancelEditingPlannerItem) {
        this.props.cancelEditingPlannerItem();
      }
    }

    this.setState({ trayOpen }, () => {
      this.toggleAriaHiddenStuff(this.state.trayOpen);
    });
  }

  toggleAriaHiddenStuff = (hide) => {
    if (hide) {
      this.props.ariaHideElement.setAttribute('aria-hidden', 'true');
    } else {
      this.props.ariaHideElement.removeAttribute('aria-hidden');
    }
  }

  isOpportunityVisible = (opportunity) => {
    if(this.state.dismissedTabSelected) {
      return opportunity.planner_override ? opportunity.planner_override.dismissed : false;
    } else {
      return opportunity.planner_override ? !opportunity.planner_override.dismissed : true;
    }
  }

  toggleGradesTray = () => {
    if (!this.state.gradesTrayOpen &&
      !this.props.loading.loadingGrades &&
      !this.props.loading.gradesLoaded) {
      this.props.startLoadingGradesSaga();
    }
    this.setState({gradesTrayOpen: !this.state.gradesTrayOpen});
  }

  handleTodayClick = () => {
    if (this.props.scrollToToday) {
      this.props.scrollToToday();
    }
  }

  handleNewActivityClick = () => {
    this.props.scrollToNewActivity();
  }

  _doToggleOpportunitiesDropdown (openOrClosed) {
    this.setState({opportunitiesOpen: !!openOrClosed}, () => {
      this.toggleAriaHiddenStuff(this.state.opportunitiesOpen);
      this.opportunitiesButton.focus();
    });
  }

  closeOpportunitiesDropdown = () => {
    this._doToggleOpportunitiesDropdown(false);
  }

  openOpportunitiesDropdown = () => {
    this._doToggleOpportunitiesDropdown(true);
  }

  toggleOpportunitiesDropdown = () => {
    this._doToggleOpportunitiesDropdown(!this.state.opportunitiesOpen);
  }

  opportunityTitle = () => {
    return (
      formatMessage(`{
        count, plural,
        =0 {# opportunities}
        one {# opportunity}
        other {# opportunities}
      }`, { count: this.state.opportunities.length })
    );
  }

  getTrayLabel = () => {
    if (this.props.todo.updateTodoItem && this.props.todo.updateTodoItem.title) {
      return formatMessage('Edit {title}', { title: this.props.todo.updateTodoItem.title });
    }
    return formatMessage("Add To Do");
  }

  // Size the opportunities popover so that it fits on the screen under the trigger button
  getPopupVerticalRoom () {
    const trigger = this.opportunitiesHtmlButton;
    if (trigger) {
      const buffer = 30;
      const minRoom = 250;
      const rect = trigger.getBoundingClientRect();
      const offset = rect.top + rect.height;
      return Math.max(window.innerHeight - offset - buffer, minRoom);
    }
    return 'none';
  }

  newActivityAboveView () {
    if (this.props.loading.isLoading) return false;
    if (!this.props.firstNewActivityDate) return false;

    const firstLoadedMoment = getFirstLoadedMoment(this.props.days, this.props.timeZone);
    const firstNewActivityLoaded = firstLoadedMoment.isSame(this.props.firstNewActivityDate) || firstLoadedMoment.isBefore(this.props.firstNewActivityDate);
    return (!(firstNewActivityLoaded && !this.props.ui.naiAboveScreen));
  }

  renderNewActivity () {
    return (
      <Portal mountNode={this.props.auxElement} open={this.newActivityAboveView()}>
        <StickyButton
          id="new_activity_button"
          direction="up"
          onClick={this.handleNewActivityClick}
          zIndex={this.props.stickyZIndex}
          buttonRef={ref => this.newActivityButtonRef = ref}
          className="StickyButton-styles__newActivityButton"
          description={formatMessage("Scrolls up to the previous item with new activity.")}
        >
          {formatMessage("New Activity")}
        </StickyButton>
      </Portal>
    );
  }

  renderToday () {
    // if we're not displaying any items, don't show the today button
    // this is true if the planner is completely empty, or showing the balloons
    // because everything is in the past when first loaded
    if (this.props.days.length > 0) {
      return (
        <Button
          id="planner-today-btn"
          variant="light"
          margin="0 medium 0 0"
          onClick={this.handleTodayClick}
        >
          {formatMessage("Today")}
        </Button>
      );
    }
    return null;
  }

  render () {
    const verticalRoom = this.getPopupVerticalRoom();

    return (
      <div className={styles.root}>
        {this.renderToday()}
        <Button
          variant="icon"
          icon={IconPlusLine}
          margin="0 medium 0 0"
          onClick={this.handleToggleTray}
          ref={(b) => { this.addNoteBtn = b; }}
        >
          <ScreenReaderContent>{formatMessage("Add To Do")}</ScreenReaderContent>
        </Button>
        <Button
          variant="icon"
          icon={IconGradebookLine}
          margin="0 medium 0 0"
          onClick={this.toggleGradesTray}
        >
          <ScreenReaderContent>{formatMessage("Show My Grades")}</ScreenReaderContent>
        </Button>
        <Popover
          onDismiss={this.closeOpportunitiesDropdown}
          show={this.state.opportunitiesOpen}
          on="click"
          constrain="none"
          placement="bottom end"
        >
          <PopoverTrigger>
            <Button
              onClick={this.toggleOpportunitiesDropdown}
              variant="icon"
              margin="0 medium 0 0"
              ref={(b) => { this.opportunitiesButton = b; }}
              buttonRef={(b) => { this.opportunitiesHtmlButton = b; }}
            >
              <Badge {...this.props.loading.allOpportunitiesLoaded && this.state.opportunities.length ? {count :this.state.opportunities.length} : {}}>
                <View>
                  <IconAlertsLine/>
                  <ScreenReaderContent>{this.opportunityTitle()}</ScreenReaderContent>
                </View>
              </Badge>
            </Button>
          </PopoverTrigger>
          <PopoverContent>
            <Opportunities
              togglePopover={this.closeOpportunitiesDropdown}
              opportunities={this.state.opportunities}
              courses={this.props.courses}
              timeZone={this.props.timeZone}
              dismiss={this.props.dismissOpportunity}
              maxHeight={verticalRoom}
            />
          </PopoverContent>
        </Popover>
        <Tray
          open={this.state.trayOpen}
          label={this.getTrayLabel()}
          placement="end"
          shouldContainFocus={true}
          shouldReturnFocus={false}
          onDismiss={this.handleCloseTray}
        >
          <CloseButton placement="start" variant="icon" onClick={this.handleCloseTray}>
            {formatMessage("Close")}
          </CloseButton>
          <UpdateItemTray
            locale={this.props.locale}
            timeZone={this.props.timeZone}
            noteItem={this.props.todo.updateTodoItem}
            onSavePlannerItem={this.handleSavePlannerItem}
            onDeletePlannerItem={this.handleDeletePlannerItem}
            courses={this.props.courses}
          />
        </Tray>
        <Tray
          label={formatMessage('My Grades')}
          open={this.state.gradesTrayOpen}
          placement="end"
          shouldContainFocus
          shouldReturnFocus
          onDismiss={this.toggleGradesTray}
        >
          <View as="div" padding="large large medium">
            <CloseButton placement="start" variant="icon" onClick={this.toggleGradesTray}>
              {formatMessage("Close")}
            </CloseButton>
            <GradesDisplay
              courses={this.props.courses}
              loading={this.props.loading.loadingGrades}
              loadingError={this.props.loading.gradesLoadingError}
            />
          </View>
        </Tray>
        {this.renderNewActivity()}
      </div>
    );
  }
}

export const ThemedPlannerHeader = themeable(theme, styles)(PlannerHeader);
export const NotifierPlannerHeader = notifier(ThemedPlannerHeader);

const mapStateToProps = ({opportunities, loading, courses, todo, days, timeZone, ui, firstNewActivityDate}) =>
  ({opportunities, loading, courses, todo, days, timeZone, ui, firstNewActivityDate});
const mapDispatchToProps = {
  addDay, savePlannerItem, deletePlannerItem, cancelEditingPlannerItem, openEditingPlannerItem,
  getInitialOpportunities, getNextOpportunities, dismissOpportunity, clearUpdateTodo,
  startLoadingGradesSaga, scrollToToday, scrollToNewActivity
};

export default connect(mapStateToProps, mapDispatchToProps)(NotifierPlannerHeader);
