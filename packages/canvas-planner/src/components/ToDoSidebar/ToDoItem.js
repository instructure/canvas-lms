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

import React from 'react'
import {Button, CloseButton} from '@instructure/ui-buttons'
import {Text} from '@instructure/ui-text'
import {List} from '@instructure/ui-list'

import {
  IconAssignmentLine,
  IconQuizLine,
  IconAnnouncementLine,
  IconDiscussionLine,
  IconNoteLine,
  IconCalendarMonthLine,
  IconDocumentLine,
  IconPeerReviewLine
} from '@instructure/ui-icons'

import {func, shape, object, arrayOf, number, string, bool} from 'prop-types'
import {dateTimeString} from '../../utilities/dateUtils'
import formatMessage from '../../format-message'

const getIconComponent = itemType => {
  switch (itemType) {
    case 'Assignment':
      return (
        <IconAssignmentLine label={formatMessage('Assignment')} className="ToDoSidebarItem__Icon" />
      )
    case 'Quiz':
      return <IconQuizLine label={formatMessage('Quiz')} className="ToDoSidebarItem__Icon" />
    case 'Discussion':
      return (
        <IconDiscussionLine label={formatMessage('Discussion')} className="ToDoSidebarItem__Icon" />
      )
    case 'Announcement':
      return (
        <IconAnnouncementLine
          label={formatMessage('Announcement')}
          className="ToDoSidebarItem__Icon"
        />
      )
    case 'Calendar Event':
      return (
        <IconCalendarMonthLine
          label={formatMessage('Calendar Event')}
          className="ToDoSidebarItem__Icon"
        />
      )
    case 'Page':
      return <IconDocumentLine label={formatMessage('Page')} className="ToDoSidebarItem__Icon" />
    case 'Peer Review':
      return (
        <IconPeerReviewLine
          label={formatMessage('Peer Review')}
          className="ToDoSidebarItem__Icon"
        />
      )
    default:
      return <IconNoteLine label={formatMessage('To Do')} className="ToDoSidebarItem__Icon" />
  }
}

const getContextShortName = (courses, courseId) => {
  const course = courses.find(x => x.id === courseId)
  return course ? course.shortName : ''
}

export default class ToDoItem extends React.Component {
  focus() {
    const focusable = this.linkRef || this.buttonRef
    if (focusable) focusable.focus()
  }

  handleClick = () => {
    this.props.handleDismissClick(this.props.item)
  }

  getInformationRow = (dueAt, points) => {
    const toDisplay = []
    if (points) {
      toDisplay.push(
        <List.Item key="points">
          {formatMessage('{numPoints} points', {numPoints: points})}
        </List.Item>
      )
    }

    toDisplay.push(<List.Item key="date">{dateTimeString(dueAt, this.props.timeZone)}</List.Item>)
    return toDisplay
  }

  itemTitle() {
    if (this.props.item.type === 'Peer Review') {
      return formatMessage('Peer Review for {itemTitle}', {itemTitle: this.props.item.title})
    }
    return this.props.item.title
  }

  render() {
    const title = (
      <Text size="small" lineHeight="fit">
        {this.itemTitle()}
      </Text>
    )
    const titleComponent = this.props.item.html_url ? (
      <Button
        variant="link"
        theme={{mediumPaddingHorizontal: '0', mediumHeight: 'normal'}}
        buttonRef={elt => {
          this.linkRef = elt
        }}
        href={this.props.item.html_url}
      >
        {title}
      </Button>
    ) : (
      <Text>{title}</Text>
    )

    return (
      <div className="ToDoSidebarItem">
        {getIconComponent(this.props.item.type)}
        <div className="ToDoSidebarItem__Info">
          <div className="ToDoSidebarItem__Title">{titleComponent}</div>
          <Text color="secondary" size="small" weight="bold" lineHeight="fit">
            {getContextShortName(this.props.courses, this.props.item.course_id)}
          </Text>
          <List variant="inline" delimiter="pipe" size="small">
            {this.getInformationRow(this.props.item.date, this.props.item.points)}
          </List>
        </div>
        {!this.props.isObserving && (
          <div className="ToDoSidebarItem__Close">
            <CloseButton
              variant="icon"
              size="small"
              onClick={this.handleClick}
              buttonRef={elt => {
                this.buttonRef = elt
              }}
            >
              {formatMessage('Dismiss {itemTitle}', {itemTitle: this.props.item.title})}
            </CloseButton>
          </div>
        )}
      </div>
    )
  }
}

ToDoItem.propTypes = {
  item: shape({
    title: string,
    html_url: string,
    type: string,
    course_id: string,
    date: object, // moment
    points: number
  }),
  courses: arrayOf(object).isRequired,
  handleDismissClick: func.isRequired,
  timeZone: string,
  isObserving: bool
}
