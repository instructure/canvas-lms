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

import React from 'react';
import Button from '@instructure/ui-buttons/lib/components/Button';
import CloseButton from '@instructure/ui-buttons/lib/components/CloseButton';
import Link from '@instructure/ui-elements/lib/components/Link';
import Text from '@instructure/ui-elements/lib/components/Text';
import List from '@instructure/ui-elements/lib/components/List';
import ListItem from '@instructure/ui-elements/lib/components/List/ListItem';

import AssignmentIcon from   '@instructure/ui-icons/lib/Line/IconAssignment';
import QuizIcon from         '@instructure/ui-icons/lib/Line/IconQuiz';
import AnnouncementIcon from '@instructure/ui-icons/lib/Line/IconAnnouncement';
import DiscussionIcon from   '@instructure/ui-icons/lib/Line/IconDiscussion';
import NoteIcon from         '@instructure/ui-icons/lib/Line/IconNote';
import CalendarIcon from     '@instructure/ui-icons/lib/Line/IconCalendarMonth';
import PageIcon from         '@instructure/ui-icons/lib/Line/IconMsWord';
import PeerReviewIcon from '@instructure/ui-icons/lib/Line/IconPeerReview';

import { formatDateAtTimeWithoutYear } from '../../utilities/dateUtils';
import formatMessage from '../../format-message';
import { func, shape, object, arrayOf, number, string } from 'prop-types';

const getIconComponent = (itemType) => {
  switch (itemType) {
    case 'Assignment':
      return <AssignmentIcon label={formatMessage('Assignment')} className="ToDoSidebarItem__Icon" />;
    case 'Quiz':
      return <QuizIcon label={formatMessage('Quiz')} className="ToDoSidebarItem__Icon" />;
    case 'Discussion':
      return <DiscussionIcon label={formatMessage('Discussion')} className="ToDoSidebarItem__Icon" />;
    case 'Announcement':
      return <AnnouncementIcon label={formatMessage('Announcement')} className="ToDoSidebarItem__Icon" />;
    case 'Calendar Event':
      return <CalendarIcon label={formatMessage('Calendar Event')} className="ToDoSidebarItem__Icon" />;
    case 'Page':
      return <PageIcon label={formatMessage('Page')} className="ToDoSidebarItem__Icon" />;
    case 'Peer Review':
      return <PeerReviewIcon label={formatMessage('Peer Review')} className="ToDoSidebarItem__Icon" />;
    default:
      return <NoteIcon label={formatMessage('To Do')} className="ToDoSidebarItem__Icon" />;
  }
};

const getContextShortName = (courses, courseId) => {
  const course = courses.find(x => x.id === courseId);
  return course ? course.shortName : '';
};

export default class ToDoItem extends React.Component {
  focus () {
    const focusable = this.linkRef || this.buttonRef;
    if (focusable) focusable.focus();
  }

  handleClick = () => {
    this.props.handleDismissClick(this.props.item);
  }

  getInformationRow = (dueAt, points) => {
    const toDisplay = [];
    if (points) {
      toDisplay.push(
        <ListItem key="points">
          {formatMessage('{numPoints} points', { numPoints: points })}
        </ListItem>
      );
    }

    toDisplay.push(
      <ListItem key="date">
        {formatDateAtTimeWithoutYear(dueAt, this.props.timeZone)}
      </ListItem>
    );
    return toDisplay;
  }

  render () {
    const title = <Text size="small" lineHeight="fit">{this.props.item.title}</Text>;
    const titleComponent = this.props.item.html_url ? (
      <Link linkRef={(elt) => {this.linkRef = elt;}} href={this.props.item.html_url}>{title}</Link>
    ) : (
      <Text>{title}</Text>
    );

    return (
      <div className="ToDoSidebarItem">
        {getIconComponent(this.props.item.type)}
        <div className="ToDoSidebarItem__Info">
          <div className="ToDoSidebarItem__Title">
            {titleComponent}
          </div>
          <Text color="secondary" size="small" weight="bold" lineHeight="fit">
            {getContextShortName(this.props.courses, this.props.item.course_id)}
          </Text>
          <List variant="inline" delimiter="pipe" size="small">
            {this.getInformationRow(this.props.item.date, this.props.item.points)}
          </List>
        </div>
        <div className="ToDoSidebarItem__Close">
          <CloseButton
            variant="icon"
            size="small"
            onClick={this.handleClick}
            buttonRef={(elt) => {this.buttonRef = elt;}}
          >
            {formatMessage('Dismiss {itemTitle}', {itemTitle: this.props.item.title})}
          </CloseButton>
        </div>
      </div>
    );
  }
}

ToDoItem.propTypes = {
  item: shape({
    title: string,
    html_url: string,
    type: string,
    course_id: string,
    date: object, // moment
    points: number,
  }),
  courses: arrayOf(object).isRequired,
  handleDismissClick: func.isRequired,
  timeZone: string,
  locale: string,
};
