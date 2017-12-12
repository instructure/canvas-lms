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
import Button from '@instructure/ui-core/lib/components/Button';
import Link from '@instructure/ui-core/lib/components/Link';
import Text from '@instructure/ui-core/lib/components/Text';
import List from '@instructure/ui-core/lib/components/List';
import ListItem from '@instructure/ui-core/lib/components/List/ListItem';
import AssignmentIcon from 'instructure-icons/lib/Line/IconAssignmentLine';
import QuizIcon from 'instructure-icons/lib/Line/IconQuizLine';
import AnnouncementIcon from 'instructure-icons/lib/Line/IconAnnouncementLine';
import DiscussionIcon from 'instructure-icons/lib/Line/IconDiscussionLine';
import NoteIcon from 'instructure-icons/lib/Line/IconNoteLightLine';
import CalendarIcon from 'instructure-icons/lib/Line/IconCalendarMonthLine';
import PageIcon from 'instructure-icons/lib/Line/IconMsWordLine';
import XIcon from 'instructure-icons/lib/Line/IconDiscussionXLine';
import I18n from 'i18n!todo_sidebar';
import { func, object, arrayOf, number, string } from 'prop-types';

const getIconComponent = (itemType) => {
  switch (itemType) {
    case 'assignment':
      return <AssignmentIcon label={I18n.t('Assignment')} className="ToDoSidebarItem__Icon" />;
    case 'quiz':
      return <QuizIcon label={I18n.t('Quiz')} className="ToDoSidebarItem__Icon" />;
    case 'discussion_topic':
      return <DiscussionIcon label={I18n.t('Discussion')} className="ToDoSidebarItem__Icon" />;
    case 'announcement':
      return <AnnouncementIcon label={I18n.t('Announcement')} className="ToDoSidebarItem__Icon" />;
    case 'calendar':
      return <CalendarIcon label={I18n.t('Calendar Event')} className="ToDoSidebarItem__Icon" />;
    case 'page':
      return <PageIcon label={I18n.t('Page')} className="ToDoSidebarItem__Icon" />;
    default:
      return <NoteIcon label={I18n.t('To Do')} className="ToDoSidebarItem__Icon" />;
  }
};

const getContextShortName = (courses, courseId) => {
  const course = courses.find(x => x.id === courseId);
  return course ? course.shortName : '';
}

const getInformationRow = (dueAt, points) => {
  const toDisplay = [];
  if (points) {
    toDisplay.push(
      <ListItem key="points">
        {I18n.t('%{numPoints} points', { numPoints: points })}
      </ListItem>
    );
  }
  toDisplay.push(
    <ListItem key="date">
      {
        I18n.t('%{date} at %{time}', {
          date: I18n.l('#date.formats.short', dueAt),
          time: I18n.l('#time.formats.tiny', dueAt)
        })
      }
    </ListItem>
  );
  return toDisplay;
}

export default function ToDoItem (props) {
  const title = <Text size="small" lineHeight="fit">{props.title}</Text>
  const titleComponent = props.href ? (
    <Link href={props.href}>{title}</Link>
  ) : (
    <Text>{title}</Text>
  );

  const handleClick = () => {
    props.handleDismissClick(props.itemType, props.itemId);
  }

  return (
    <div className="ToDoSidebarItem">
      {getIconComponent(props.itemType)}
      <div className="ToDoSidebarItem__Info">
        <div className="ToDoSidebarItem__Title">
          {titleComponent}
        </div>
        <Text color="secondary" size="small" weight="bold" lineHeight="fit">
          {getContextShortName(props.courses, props.courseId)}
        </Text>
        <List variant="pipe">
          {getInformationRow(props.dueAt, props.points)}
        </List>
      </div>
      <div className="ToDoSidebarItem__Close">
        <Button
          variant="icon"
          size="small"
          onClick={handleClick}
        >
          <XIcon title={I18n.t('Dismiss This')} className="ToDoSidebarItem__CloseIcon" />
        </Button>
      </div>
    </div>
  )
}

ToDoItem.propTypes = {
  itemId: string.isRequired,
  title: string.isRequired,
  href: string,
  itemType: string.isRequired,
  courses: arrayOf(object).isRequired,
  courseId: string,
  dueAt: string.isRequired,
  points: number,
  handleDismissClick: func.isRequired
};

ToDoItem.defaultProps = {
  href: null,
  courseId: null,
  points: null
};
