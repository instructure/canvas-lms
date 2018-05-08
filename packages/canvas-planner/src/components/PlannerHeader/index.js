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
import Button from '@instructure/ui-core/lib/components/Button';
import CloseButton from '@instructure/ui-buttons/lib/components/CloseButton';
import View from '@instructure/ui-layout/lib/components/View';
import IconPlusLine from 'instructure-icons/lib/Line/IconPlusLine';
import IconAlertsLine from 'instructure-icons/lib/Line/IconAlertsLine';
import IconGradebookLine from 'instructure-icons/lib/Line/IconGradebookLine';
import Popover, {PopoverTrigger, PopoverContent} from '@instructure/ui-core/lib/components/Popover';
import PropTypes from 'prop-types';
import UpdateItemTray from '../UpdateItemTray';
import Tray from '@instructure/ui-core/lib/components/Tray';
import Badge from '@instructure/ui-core/lib/components/Badge';
import Opportunities from '../Opportunities';
import GradesDisplay from '../GradesDisplay';
import {
  addDay, savePlannerItem, deletePlannerItem, cancelEditingPlannerItem, openEditingPlannerItem, getNextOpportunities,
  getInitialOpportunities, dismissOpportunity, clearUpdateTodo, startLoadingGradesSaga, scrollToToday
} from '../../actions';

import { courseShape, opportunityShape } from '../plannerPropTypes';
import styles from './styles.css';
import theme from './theme.js';
import formatMessage from '../../format-message';
import {notifier} from '../../dynamic-ui';

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
    locale: PropTypes.string.isRequired,
    timeZone: PropTypes.string.isRequired,
    opportunities: PropTypes.shape(opportunityShape).isRequired,
    getInitialOpportunities: PropTypes.func.isRequired,
    getNextOpportunities: PropTypes.func.isRequired,
    dismissOpportunity: PropTypes.func.isRequired,
    clearUpdateTodo: PropTypes.func.isRequired,
    startLoadingGradesSaga: PropTypes.func.isRequired,
    todo: PropTypes.shape({
      updateTodoItem: PropTypes.shape({
        title: PropTypes.string,
      }),
    }),
    loading: PropTypes.shape({
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
    ariaHideElement: PropTypes.instanceOf(Element).isRequired
  };

  static defaultProps = {
    triggerDynamicUiUpdates: () => {},
    preTriggerDynamicUiUpdates: () => {},
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

    if (!nextProps.loading.allOpportunitiesLoaded && !nextProps.loading.loadingOpportunities && opportunities.length < 10) {
      nextProps.getNextOpportunities();
    }

    opportunities = opportunities.slice(0, 10);
    this.setUpdateItemTray(!!nextProps.todo.updateTodoItem || this.state.trayOpen);
    this.setState({opportunities});
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
    this.toggleUpdateItemTray();
    this.props.savePlannerItem(plannerItem);
  }

  isOpportunityVisible = (opportunity) => {
    if(this.state.dismissedTabSelected) {
      return opportunity.planner_override ? opportunity.planner_override.dismissed : false;
    } else {
      return opportunity.planner_override ? !opportunity.planner_override.dismissed : true;
    }
  }

  handleDeletePlannerItem = (plannerItem) => {
    this.toggleUpdateItemTray();
    this.props.deletePlannerItem(plannerItem);
  }

  handleCancelPlannerItem = () => {
    this.toggleUpdateItemTray();
    // let the dynamic ui manager manage focus on cancel.
    if (this.props.cancelEditingPlannerItem) {
      this.props.cancelEditingPlannerItem();
    }
  }

  toggleAriaHiddenStuff = (hide) => {
    if (hide) {
      this.props.ariaHideElement.setAttribute('aria-hidden', 'true');
    } else {
      this.props.ariaHideElement.removeAttribute('aria-hidden');
    }
  }

  toggleUpdateItemTray = () => {
    this.setUpdateItemTray(!this.state.trayOpen);
  }

  toggleGradesTray = () => {
    if (!this.state.gradesTrayOpen &&
      !this.props.loading.loadingGrades &&
      !this.props.loading.gradesLoaded) {
      this.props.startLoadingGradesSaga();
    }
    this.setState({gradesTrayOpen: !this.state.gradesTrayOpen});
  }

  setUpdateItemTray (trayOpen) {
    if (trayOpen && this.props.openEditingPlannerItem) {
      this.props.openEditingPlannerItem();
    }
    this.setState({ trayOpen }, () => {
      this.toggleAriaHiddenStuff(this.state.trayOpen);
    });
  }

  handleTodayClick = () => {
    if (this.props.scrollToToday) {
      this.props.scrollToToday();
    }
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

  noteBtnOnClose = () => {
    this.props.clearUpdateTodo();
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
    if (this.props.todo.updateTodoItem) {
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

  render () {
    const verticalRoom = this.getPopupVerticalRoom();

    return (
      <div className={styles.root}>
        <Button
          variant="light"
          margin="0 medium 0 0"
          onClick={this.handleTodayClick}
        >
          {formatMessage("Today")}
        </Button>
        <Button
          variant="icon"
          margin="0 medium 0 0"
          onClick={this.toggleUpdateItemTray}
          ref={(b) => { this.addNoteBtn = b; }}
        >
          <IconPlusLine title={formatMessage("Add To Do")} />
        </Button>
        <Button
          variant="icon"
          margin="0 medium 0 0"
          onClick={this.toggleGradesTray}
        >
          <IconGradebookLine title={formatMessage("Show My Grades")} />
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
              <Badge {...this.state.opportunities.length ? {count :this.state.opportunities.length} : {}}>
                <IconAlertsLine title={this.opportunityTitle()} />
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
          closeButtonLabel={formatMessage("Close")}
          open={this.state.trayOpen}
          label={this.getTrayLabel()}
          placement="end"
          shouldContainFocus={true}
          shouldReturnFocus={false}
          applicationElement={() => document.getElementById('application') }
          onExited={this.noteBtnOnClose}
          onDismiss={this.handleCancelPlannerItem}
        >
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
          applicationElement={() => document.getElementById('application') }
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
      </div>
    );
  }
}

export const ThemedPlannerHeader = themeable(theme, styles)(PlannerHeader);
export const NotifierPlannerHeader = notifier(ThemedPlannerHeader);

const mapStateToProps = ({opportunities, loading, courses, todo}) => ({opportunities, loading, courses, todo});
const mapDispatchToProps = {
  addDay, savePlannerItem, deletePlannerItem, cancelEditingPlannerItem, openEditingPlannerItem,
  getInitialOpportunities, getNextOpportunities, dismissOpportunity, clearUpdateTodo, startLoadingGradesSaga, scrollToToday
};

export default connect(mapStateToProps, mapDispatchToProps)(NotifierPlannerHeader);
