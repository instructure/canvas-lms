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
import {useScope as createI18nScope} from '@canvas/i18n'

const I18n = createI18nScope('planner')

// @ts-expect-error TS7006 (typescriptify)
const getAriaLabel = (itemType, itemTitle) => {
  switch (itemType) {
    case 'Assignment':
      return I18n.t('Assignment, %{itemTitle}', {itemTitle})
    case 'Quiz':
      return I18n.t('Quiz, %{itemTitle}', {itemTitle})
    case 'Discussion':
      return I18n.t('Discussion, %{itemTitle}', {itemTitle})
    case 'Announcement':
      return I18n.t('Announcment, %{itemTitle}', {itemTitle})
    case 'Calendar Event':
      return I18n.t('Calendar Event, %{itemTitle}', {itemTitle})
    case 'Page':
      return I18n.t('Page, %{itemTitle}', {itemTitle})
    case 'Peer Review':
      return I18n.t('Peer Review, %{itemTitle}', {itemTitle})
    case 'Discussion Checkpoint':
      return I18n.t('Discussion Checkpoint, %{itemTitle}', {itemTitle})
    default:
      return I18n.t('To Do, %{itemTitle}', {itemTitle})
  }
}

// @ts-expect-error TS7006 (typescriptify)
const getIconComponent = itemType => {
  switch (itemType) {
    case 'Assignment':
      // @ts-expect-error TS2769 (typescriptify)
      return <IconAssignmentLine label={I18n.t('Assignment')} className="ToDoSidebarItem__Icon" />
    case 'Quiz':
      // @ts-expect-error TS2769 (typescriptify)
      return <IconQuizLine label={I18n.t('Quiz')} className="ToDoSidebarItem__Icon" />
    case 'Discussion':
      // @ts-expect-error TS2769 (typescriptify)
      return <IconDiscussionLine label={I18n.t('Discussion')} className="ToDoSidebarItem__Icon" />
    case 'Discussion Checkpoint':
      return (
        <IconDiscussionLine
          // @ts-expect-error TS2769 (typescriptify)
          label={I18n.t('Discussion Checkpoint')}
          className="ToDoSidebarItem__Icon"
        />
      )
    case 'Announcement':
      return (
        // @ts-expect-error TS2769 (typescriptify)
        <IconAnnouncementLine label={I18n.t('Announcement')} className="ToDoSidebarItem__Icon" />
      )
    case 'Calendar Event':
      return (
        // @ts-expect-error TS2769 (typescriptify)
        <IconCalendarMonthLine label={I18n.t('Calendar Event')} className="ToDoSidebarItem__Icon" />
      )
    case 'Page':
      // @ts-expect-error TS2769 (typescriptify)
      return <IconDocumentLine label={I18n.t('Page')} className="ToDoSidebarItem__Icon" />
    case 'Peer Review':
      // @ts-expect-error TS2769 (typescriptify)
      return <IconPeerReviewLine label={I18n.t('Peer Review')} className="ToDoSidebarItem__Icon" />
    default:
      // @ts-expect-error TS2769 (typescriptify)
      return <IconNoteLine label={I18n.t('To Do')} className="ToDoSidebarItem__Icon" />
  }
}

// @ts-expect-error TS7006 (typescriptify)
const getContextShortName = (courses, courseId) => {
  // @ts-expect-error TS7006 (typescriptify)
  const course = courses.find(x => x.id === courseId)
  return course ? course.shortName : ''
}

export default class ToDoItem extends React.Component {
  // @ts-expect-error TS7006 (typescriptify)
  constructor(props) {
    super(props)
    // @ts-expect-error TS2339 (typescriptify)
    this.dismissed = false
  }

  focus() {
    // @ts-expect-error TS2339 (typescriptify)
    const focusable = this.linkRef || this.buttonRef
    if (focusable) focusable.focus()
  }

  handleClick = () => {
    // @ts-expect-error TS2339 (typescriptify)
    if (this.dismissed) return
    // @ts-expect-error TS2339 (typescriptify)
    this.dismissed = true
    // @ts-expect-error TS2339 (typescriptify)
    this.props.handleDismissClick(this.props.item)
  }

  // @ts-expect-error TS7006 (typescriptify)
  getInformationRow = (dueAt, points, restrictQuantitativeData) => {
    const toDisplay = []
    if (points && !restrictQuantitativeData) {
      toDisplay.push(
        <InlineList.Item key="points">
          {I18n.t('%{numPoints} points', {numPoints: points})}
        </InlineList.Item>,
      )
    }

    toDisplay.push(
      // @ts-expect-error TS2339 (typescriptify)
      <InlineList.Item key="date">{dateTimeString(dueAt, this.props.timeZone)}</InlineList.Item>,
    )
    return toDisplay
  }

  itemTitle() {
    // @ts-expect-error TS2339 (typescriptify)
    if (this.props.item.type === 'Peer Review') {
      // @ts-expect-error TS2339 (typescriptify)
      return I18n.t('Peer Review for %{itemTitle}', {itemTitle: this.props.item.title})
    }
    // @ts-expect-error TS2339 (typescriptify)
    return this.props.item.title
  }

  render() {
    const title = (
      <Text size="small" lineHeight="fit">
        {this.itemTitle()}
      </Text>
    )
    // @ts-expect-error TS2339 (typescriptify)
    const titleComponent = this.props.item.html_url ? (
      <Link
        elementRef={elt => {
          // @ts-expect-error TS2339 (typescriptify)
          this.linkRef = elt
        }}
        // @ts-expect-error TS2339 (typescriptify)
        aria-label={getAriaLabel(this.props.item.type, this.props.item.title)}
        // @ts-expect-error TS2339 (typescriptify)
        href={this.props.item.html_url}
      >
        {title}
      </Link>
    ) : (
      // @ts-expect-error TS2339 (typescriptify)
      <Text aria-label={getAriaLabel(this.props.item.type, this.props.item.title)}>{title}</Text>
    )

    return (
      <div className="ToDoSidebarItem">
        {/* @ts-expect-error TS2339 (typescriptify) */}
        {getIconComponent(this.props.item.type)}
        <div className="ToDoSidebarItem__Info" data-testid="todo-sidebar-item-info">
          <div className="ToDoSidebarItem__Title" data-testid="todo-sidebar-item-title">
            {titleComponent}
          </div>
          <Text color="secondary" size="small" weight="bold" lineHeight="fit">
            {/* @ts-expect-error TS2339 (typescriptify) */}
            {getContextShortName(this.props.courses, this.props.item.course_id)}
          </Text>
          <InlineList delimiter="pipe" size="small" data-testid="ToDoSidebarItem__InformationRow">
            {this.getInformationRow(
              // @ts-expect-error TS2339 (typescriptify)
              this.props.item.date,
              // @ts-expect-error TS2339 (typescriptify)
              this.props.item.points,
              // @ts-expect-error TS2339 (typescriptify)
              this.props.item?.restrict_quantitative_data,
            )}
          </InlineList>
        </div>
        {/* @ts-expect-error TS2339 (typescriptify) */}
        {!this.props.isObserving && (
          <div className="ToDoSidebarItem__Close" data-testid="todo-sidebar-item-close">
            <CloseButton
              data-testid="todo-sidebar-item-close-button"
              size="small"
              onClick={this.handleClick}
              screenReaderLabel={I18n.t('Dismiss %{itemTitle}', {
                // @ts-expect-error TS2339 (typescriptify)
                itemTitle: this.props.item.title,
              })}
              elementRef={elt => {
                // @ts-expect-error TS2339 (typescriptify)
                this.buttonRef = elt
              }}
            />
          </div>
        )}
      </div>
    )
  }
}

// @ts-expect-error TS2339 (typescriptify)
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
