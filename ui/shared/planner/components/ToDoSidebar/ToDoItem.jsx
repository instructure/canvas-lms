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
import {CloseButton} from '@instructure/ui-buttons'
import {Link} from '@instructure/ui-link'
import {Text} from '@instructure/ui-text'
import {InlineList} from '@instructure/ui-list'

import {
  IconAssignmentLine,
  IconQuizLine,
  IconAnnouncementLine,
  IconDiscussionLine,
  IconNoteLine,
  IconCalendarMonthLine,
  IconDocumentLine,
  IconPeerReviewLine,
} from '@instructure/ui-icons'

import {func, shape, object, arrayOf, number, string, bool} from 'prop-types'
import {dateTimeString} from '../../utilities/dateUtils'
import {useScope as useI18nScope} from '@canvas/i18n'

const I18n = useI18nScope('planner')

const getAriaLabel = (itemType, itemTitle) => {
  switch (itemType) {
    case 'Assignment':
      return I18n.t('Assignment, %{itemTitle}', {itemTitle: itemTitle})
    case 'Quiz':
      return I18n.t('Quiz, %{itemTitle}', {itemTitle: itemTitle})
    case 'Discussion':
      return I18n.t('Discussion, %{itemTitle}', {itemTitle: itemTitle})
    case 'Announcement':
      return I18n.t('Announcment, %{itemTitle}', {itemTitle: itemTitle})
    case 'Calendar Event':
      return I18n.t('Calendar Event, %{itemTitle}', {itemTitle: itemTitle})
    case 'Page':
      return I18n.t('Page, %{itemTitle}', {itemTitle: itemTitle})
    case 'Peer Review':
      return I18n.t('Peer Review, %{itemTitle}', {itemTitle: itemTitle})
    default:
      return I18n.t('To Do, %{itemTitle}', {itemTitle: itemTitle})
  }
}

const getIconComponent = itemType => {
  switch (itemType) {
    case 'Assignment':
      return <IconAssignmentLine label={I18n.t('Assignment')} className="ToDoSidebarItem__Icon" />
    case 'Quiz':
      return <IconQuizLine label={I18n.t('Quiz')} className="ToDoSidebarItem__Icon" />
    case 'Discussion':
      return <IconDiscussionLine label={I18n.t('Discussion')} className="ToDoSidebarItem__Icon" />
    case 'Announcement':
      return (
        <IconAnnouncementLine label={I18n.t('Announcement')} className="ToDoSidebarItem__Icon" />
      )
    case 'Calendar Event':
      return (
        <IconCalendarMonthLine label={I18n.t('Calendar Event')} className="ToDoSidebarItem__Icon" />
      )
    case 'Page':
      return <IconDocumentLine label={I18n.t('Page')} className="ToDoSidebarItem__Icon" />
    case 'Peer Review':
      return <IconPeerReviewLine label={I18n.t('Peer Review')} className="ToDoSidebarItem__Icon" />
    default:
      return <IconNoteLine label={I18n.t('To Do')} className="ToDoSidebarItem__Icon" />
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

  getInformationRow = (dueAt, points, restrictQuantitativeData) => {
    const toDisplay = []
    if (points && !restrictQuantitativeData) {
      toDisplay.push(
        <InlineList.Item key="points">
          {I18n.t('%{numPoints} points', {numPoints: points})}
        </InlineList.Item>
      )
    }

    toDisplay.push(
      <InlineList.Item key="date">{dateTimeString(dueAt, this.props.timeZone)}</InlineList.Item>
    )
    return toDisplay
  }

  itemTitle() {
    if (this.props.item.type === 'Peer Review') {
      return I18n.t('Peer Review for %{itemTitle}', {itemTitle: this.props.item.title})
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
      <Link
        elementRef={elt => {
          this.linkRef = elt
        }}
        aria-label={getAriaLabel(this.props.item.type, this.props.item.title)}
        href={this.props.item.html_url}
      >
        {title}
      </Link>
    ) : (
      <Text aria-label={getAriaLabel(this.props.item.type, this.props.item.title)}>{title}</Text>
    )

    return (
      <div className="ToDoSidebarItem">
        {getIconComponent(this.props.item.type)}
        <div className="ToDoSidebarItem__Info">
          <div className="ToDoSidebarItem__Title">{titleComponent}</div>
          <Text color="secondary" size="small" weight="bold" lineHeight="fit">
            {getContextShortName(this.props.courses, this.props.item.course_id)}
          </Text>
          <InlineList delimiter="pipe" size="small" data-testid="ToDoSidebarItem__InformationRow">
            {this.getInformationRow(
              this.props.item.date,
              this.props.item.points,
              this.props.item?.restrict_quantitative_data
            )}
          </InlineList>
        </div>
        {!this.props.isObserving && (
          <div className="ToDoSidebarItem__Close">
            <CloseButton
              size="small"
              onClick={this.handleClick}
              screenReaderLabel={I18n.t('Dismiss %{itemTitle}', {
                itemTitle: this.props.item.title,
              })}
              elementRef={elt => {
                this.buttonRef = elt
              }}
            />
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
    points: number,
    restrict_quantitative_data: bool,
  }),
  courses: arrayOf(object).isRequired,
  handleDismissClick: func.isRequired,
  timeZone: string,
  isObserving: bool,
}
