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
import themeable from '@instructure/ui-themeable/lib';
import Text from '@instructure/ui-core/lib/components/Text';
import Checkbox from '@instructure/ui-core/lib/components/Checkbox';
import Link from '@instructure/ui-core/lib/components/Link';
import ScreenReaderContent from '@instructure/ui-core/lib/components/ScreenReaderContent';
import Pill from '@instructure/ui-core/lib/components/Pill';
import Avatar from '@instructure/ui-core/lib/components/Avatar';
import Assignment from 'instructure-icons/lib/Line/IconAssignmentLine';
import Quiz from 'instructure-icons/lib/Line/IconQuizLine';
import Announcement from 'instructure-icons/lib/Line/IconAnnouncementLine';
import Discussion from 'instructure-icons/lib/Line/IconDiscussionLine';
import Calendar from 'instructure-icons/lib/Line/IconCalendarMonthLine';
import Page from 'instructure-icons/lib/Line/IconMsWordLine';
import NotificationBadge, { MissingIndicator, NewActivityIndicator } from '../NotificationBadge';
import BadgeList from '../BadgeList';
import responsiviser from '../responsiviser';
import styles from './styles.css';
import theme from './theme.js';
import { arrayOf, bool, number, string, func, shape, object } from 'prop-types';
import { badgeShape, userShape, statusShape, sizeShape } from '../plannerPropTypes';
import { showPillForOverdueStatus } from '../../utilities/statusUtils';
import { momentObj } from 'react-moment-proptypes';
import formatMessage from '../../format-message';
import {animatable} from '../../dynamic-ui';

export class PlannerItem extends Component {
  static propTypes = {
    color: string,
    id: string.isRequired,
    uniqueId: string.isRequired,
    animatableIndex: number,
    title: string.isRequired,
    points: number,
    date: momentObj,
    details: string,
    courseName: string,
    completed: bool,
    overrideId: string,
    associated_item: string,
    context: object,
    html_url: string,
    toggleCompletion: func,
    updateTodo: func.isRequired,
    badges: arrayOf(shape(badgeShape)),
    registerAnimatable: func,
    deregisterAnimatable: func,
    toggleAPIPending: bool,
    status: statusShape,
    newActivity: bool,
    showNotificationBadge: bool,
    currentUser: shape(userShape),
    responsiveSize: sizeShape,
    allDay: bool,
  };

  static defaultProps = {
    badges: [],
    responsiveSize: 'large',
    allDay: false,
  };

  constructor (props) {
    super(props);
    this.state = {
      completed: props.completed,
    };
  }

  componentDidMount () {
    this.props.registerAnimatable('item', this, this.props.animatableIndex, [this.props.uniqueId]);
  }

  componentWillReceiveProps (nextProps) {
    this.props.deregisterAnimatable('item', this, [this.props.uniqueId]);
    this.props.registerAnimatable('item', this, nextProps.animatableIndex, [nextProps.uniqueId]);
    this.setState({
      completed: nextProps.completed,
    });
  }

  componentWillUnmount () {
    this.props.deregisterAnimatable('item', this, [this.props.uniqueId]);
  }

  toDoLinkClick = (e) => {
    e.preventDefault();
    this.props.updateTodo({updateTodoItem: {...this.props}});
  }

  registerRootDivRef = (elt) => {
    this.rootDivRef = elt;
  }

  registerFocusElementRef = (elt) => {
    this.checkboxRef = elt;
  }

  getFocusable (which) {
    return (which === 'update' || which === 'delete') ? this.itemLink : this.checkboxRef;
  }

  getScrollable () {
    return this.rootDivRef;
  }

  getLayout() {
    return this.props.responsiveSize;
  }

  renderDateField = () => {
    if (this.props.date) {

      if (this.props.associated_item === "Announcement" || this.props.associated_item === "Calendar Event") {
        return this.props.allDay === true ? formatMessage('All Day') : this.props.date.format("LT");
      }
      return formatMessage(`DUE: {date}`, {date: this.props.date.format("LT")});
    }
    return null;
  }

  renderIcon = () => {
    const currentUser = this.props.currentUser || {};

    switch(this.props.associated_item) {
        case "Assignment":
          return <Assignment />;
        case "Quiz":
          return <Quiz />;
        case "Discussion":
          return <Discussion />;
        case "Announcement":
          return <Announcement />;
        case "Calendar Event":
          return <Calendar />;
        case "Page":
          return <Page />;
        default:
          return <Avatar name={currentUser.displayName || '?'} src={currentUser.avatarUrl} size="small" />;
    }
  }

  renderBadges = () => {
    if (this.props.badges.length) {
      return (
        <BadgeList>
          {this.props.badges.map((b) => (
            <Pill
              key={b.id}
              text={b.text}
              variant={b.variant}
            />
          ))}
        </BadgeList>
      );
    }
    return null;
  }

  renderItemMetrics = () => {
    return (
      <div className={styles.secondary}>
        <div className={styles.badges}>
          {this.renderBadges()}
        </div>
        <div className={styles.metrics}>
          {(this.props.points) ?
            <div className={styles.score}>
              <Text color="secondary">
                <Text size="large">{this.props.points}</Text>
                <Text size="x-small">&nbsp;
                  { this.props.points
                      ? formatMessage('pts')
                      : null
                  }
                </Text>
              </Text>
            </div> : null
          }
          <div className={styles.due}>
            <Text color="secondary" size="x-small">
              {this.renderDateField()}
            </Text>
          </div>
        </div>
      </div>
    );
  }

  renderType = () => {
    if (!this.props.associated_item) {
      return formatMessage('{course} TO DO', { course: this.props.courseName || '' });
    } else {
      return `${this.props.courseName || ''} ${this.props.associated_item}`;
    }
  }

  renderItemDetails = () => {
    return (
      <div className={styles.details}>
        <div className={styles.type}>
          <Text size="x-small" color="secondary">
            {this.renderType()}
          </Text>
        </div>
        <div className={styles.title}>
          <Link
            linkRef={(link) => {this.itemLink = link;}}
            {...this.props.associated_item === "To Do" ? {onClick: this.toDoLinkClick} : {}}
            href={this.props.html_url || "#" }>
            {this.props.title}
          </Link>
        </div>
      </div>
    );
  }

  renderNotificationBadge () {
    if (!this.props.showNotificationBadge) {
      return null;
    }

    const newItem = this.props.newActivity;
    let missing = false;
    if (showPillForOverdueStatus('missing', {status: this.props.status, context: this.props.context})) {
      missing = true;
    }

    if (newItem || missing) {
      const IndicatorComponent = newItem ? NewActivityIndicator : MissingIndicator;
      return (
        <NotificationBadge>
          <div className={styles.activityIndicator}>
            <IndicatorComponent
            title={this.props.title}
            itemIds={[this.props.uniqueId]}
            animatableIndex={this.props.animatableIndex} />
          </div>
        </NotificationBadge>
      );
    } else {
      return <NotificationBadge/>;
    }
  }

  render () {
    const assignmentType = this.props.associated_item ?
      this.props.associated_item : formatMessage('Task');
    const checkboxLabel = this.state.completed ?
      formatMessage('{assignmentType} {title} is complete',
        { assignmentType: assignmentType, title: this.props.title }) :
      formatMessage('{assignmentType} {title} is incomplete',
        { assignmentType: assignmentType, title: this.props.title });
    return (
      <div className={classnames(styles.root, styles[this.getLayout()], 'planner-item')} ref={this.registerRootDivRef}>
        {this.renderNotificationBadge()}
        <div className={styles.completed}>
          <Checkbox
            ref={this.registerFocusElementRef}
            label={<ScreenReaderContent>{checkboxLabel}</ScreenReaderContent>}
            checked={this.props.toggleAPIPending ? !this.state.completed : this.state.completed}
            onChange={this.props.toggleCompletion}
            disabled={this.props.toggleAPIPending}
          />
        </div>
        <div
          className={assignmentType === 'To Do' ? styles.avatar : styles.icon}
          style={{ color: this.props.color }}
          aria-hidden="true"
        >
          {this.renderIcon()}
        </div>
        <div className={styles.layout}>
          {this.renderItemDetails()}
          {this.renderItemMetrics()}
        </div>
      </div>
    );
  }
}

const ResponsivePlannerItem = responsiviser()(PlannerItem);
export default animatable(themeable(theme, styles)(ResponsivePlannerItem));
