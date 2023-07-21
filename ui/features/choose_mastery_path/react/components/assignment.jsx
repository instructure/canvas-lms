/*
 * Copyright (C) 2016 - present Instructure, Inc.
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
import PropTypes from 'prop-types'
import classNames from 'classnames'
import {useScope as useI18nScope} from '@canvas/i18n'
import apiUserContent from '@canvas/util/jquery/apiUserContent'
import assignmentShape from '../shapes/assignment-shape'

const I18n = useI18nScope('choose_mastery_path')

const {bool} = PropTypes

export default class Assignment extends React.Component {
  static propTypes = {
    assignment: assignmentShape.isRequired,
    isSelected: bool,
  }

  renderTitle() {
    if (this.props.isSelected) {
      return (
        <a
          href={`/courses/${this.props.assignment.course_id}/assignments/${this.props.assignment.assignmentId}`}
          title={this.props.assignment.name}
          className="item_name cmp-assignment__title-link"
        >
          {this.props.assignment.name}
        </a>
      )
    } else {
      return <span className="item_name">{this.props.assignment.name}</span>
    }
  }

  render() {
    const dueAt = this.props.assignment.due_at
    const points = this.props.assignment.points_possible
    const date = dueAt && I18n.l('date.formats.short', dueAt)

    const assgClasses = classNames(
      'cmp-assignment',
      'context_module_item',
      this.props.assignment.category.contentTypeClass
    )

    return (
      <li className={assgClasses}>
        <div className="ig-row">
          <div className="ig-header">
            <span className="type_icon" title={this.props.assignment.category.label}>
              <span className="ig-type-icon">
                <i className={`icon-${this.props.assignment.category.id}`} />
              </span>
            </span>
            <div className="ig-info">
              <div className="module-item-title">{this.renderTitle()}</div>
              <div className="ig-details">
                {!!dueAt && (
                  <div className="due_date_display ig-details__item">
                    <strong>{I18n.t('Due')}</strong>
                    <span>{date}</span>
                  </div>
                )}
                {points != null && (
                  <div key="points" className="points_possible_display ig-details__item">
                    {I18n.t('%{points} pts', {points})}
                  </div>
                )}
              </div>
            </div>
          </div>
          <div
            className="ig-description"
            dangerouslySetInnerHTML={{
              __html: apiUserContent.convert(this.props.assignment.description),
            }}
          />
        </div>
      </li>
    )
  }
}
