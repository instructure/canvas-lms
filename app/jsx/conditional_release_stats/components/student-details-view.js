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
import Spinner from '@instructure/ui-core/lib/components/Spinner'
import I18n from 'i18n!cyoe_assignment_sidebar'
import { i18nGrade } from '../../shared/conditional_release/score'
import StudentAssignmentItem from './student-assignment-item'
import { assignmentShape, studentShape } from '../shapes/index'

const { shape, string, number, arrayOf, func, bool } = PropTypes

export default class StudentDetailsView extends React.Component {
  static propTypes = {
    isLoading: bool,
    student: studentShape,
    triggerAssignment: shape({
      submission: shape({
        grade: string.isRequired,
        submitted_at: string.isRequired,
      }).isRequired,
      assignment: assignmentShape.isRequired,
    }),
    followOnAssignments: arrayOf(shape({
      score: number,
      trend: number,
      assignment: assignmentShape.isRequired,
    })),

    selectNextStudent: func.isRequired,
    selectPrevStudent: func.isRequired,
    unselectStudent: func.isRequired,
  }

  componentDidUpdate (prevProps) {
    if (this.props.student && !prevProps.student) {
      setTimeout(() => this.backButton.focus(), 100)
    }
  }

  renderHeader () {
    if (!this.props.student) { return null }
    return (
      <header className="crs-student-details__header">
        <button
          className="crs-breakdown__link crs-back-button"
          ref={(e) => { this.backButton = e }}
          onClick={this.props.unselectStudent}
        >
          <i aria-hidden className="icon-arrow-open-left" />
          {I18n.t('Back')}
        </button>
      </header>
    )
  }

  renderStudentProfile () {
    const { student, triggerAssignment } = this.props
    const { assignment } = triggerAssignment

    const studentAvatar = student.avatar_image_url || '/images/messages/avatar-50.png'
    const conversationUrl = `/conversations?context_id=course_${assignment.course_id}&user_id=${student.id}&user_name=${student.name}`

    return (
      <section className="crs-student-details__profile-content">
        <button
          className="Button Button--icon-action student-details__prev-student"
          aria-label={I18n.t('view previous student')}
          onClick={this.props.selectPrevStudent}
          type="button"
        >
          <i aria-hidden className="icon-arrow-open-left" />
        </button>
        <div className="crs-student-details__profile-inner-content">
          <img src={studentAvatar} aria-hidden className="crs-student-details__profile-image" />
          <h3 className="crs-student-details__name">{student.name}</h3>
          <a target="_blank" rel="noopener noreferrer" href={conversationUrl} className="crs-breakdown__link">
            <i aria-hidden className="icon-email crs-icon-email" />{I18n.t('Send Message')}
          </a>
        </div>
        <button
          className="Button Button--icon-action student-details__next-student"
          aria-label={I18n.t('view next student')}
          onClick={this.props.selectNextStudent}
          type="button"
        >
          <i aria-hidden className="icon-arrow-open-right" />
        </button>
      </section>
    )
  }

  renderTriggerAssignment () {
    const { student, triggerAssignment } = this.props
    const { assignment, submission } = triggerAssignment || {}

    const submissionUrl = `/courses/${assignment.course_id}/assignments/${assignment.id}/submissions/${student.id}`
    let submissionDate = null
    if (submission) {
      submissionDate = submission.submitted_at ? I18n.l('date.formats.long', new Date(submission.submitted_at)) : null
    } else {
      submissionDate = I18n.t('Not Submitted')
    }

    return (
      <section className="crs-student-details__score-content">
        <h3 className="crs-student-details__score-number">{i18nGrade(submission.grade, assignment)}</h3>
        <div className="crs-student-details__score-title">{assignment.name}</div>
        {
          submissionDate ? (
            <div className="crs-student-details__score-date">{I18n.t('Submitted: %{submitDate}', { submitDate: submissionDate })}</div>
          ) : null
        }
        <a target="_blank" rel="noopener noreferrer" href={submissionUrl} className="crs-breakdown__link">
          {I18n.t('View Submission')}
        </a>
      </section>
    )
  }

  renderFollowOnAssignments () {
    const followOnAssignments = this.props.followOnAssignments || []
    return (
      <section>
        {
          followOnAssignments.map((item, i) => (
            <StudentAssignmentItem
              key={i}
              assignment={item.assignment}
              score={item.score}
              trend={item.trend}
            />
          ))
        }
      </section>
    )
  }

  renderContent () {
    if (this.props.isLoading) {
      return (
        <div className="crs-student-details__loading">
          <Spinner title={I18n.t('Loading')} size="small" />
          <p>{I18n.t('Loading Data..')}</p>
        </div>
      )
    } else if (this.props.student) {
      return (
        <div>
          {this.renderStudentProfile()}
          {this.renderTriggerAssignment()}
          {this.renderFollowOnAssignments()}
        </div>
      )
    }
    return null
  }

  render () {
    const isHidden = !this.props.student

    const studentDetailsClasses = classNames({
      'crs-student-details': true,
      'crs-student-details__hidden': isHidden,
    })

    return (
      <div className={studentDetailsClasses}>
        {this.renderHeader()}
        {this.renderContent()}
      </div>
    )
  }
}
