/*
 * Copyright (C) 2018 - present Instructure, Inc.
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
import {arrayOf, func, string, number} from 'prop-types'
import {useScope as createI18nScope} from '@canvas/i18n'

import {TeacherAssignmentShape, SubmissionShape} from '../../assignmentData'

import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {View} from '@instructure/ui-view'
import {Table} from '@instructure/ui-table'
import {IconButton} from '@instructure/ui-buttons'
import {IconExpandStartLine} from '@instructure/ui-icons'
import {Avatar} from '@instructure/ui-avatar'
import SubmissionStatusPill from '@canvas/assignments/react/SubmissionStatusPill'
import FriendlyDatetime from '@canvas/datetime/react/components/FriendlyDatetime'
import StudentTray from './StudentTray'

import {Link} from '@instructure/ui-link'

const I18n = createI18nScope('assignments_2')

const {Head, Body, ColHeader, Row, Cell} = Table

const HEADERS = [
  {id: 'username', label: I18n.t('Name')},
  {id: 'attempts', label: I18n.t('submission_attempts', 'Attempts')},
  {id: 'score', label: I18n.t('Score')},
  {id: 'submitted_at', label: I18n.t('Submission Date')},
  {id: 'status', label: I18n.t('Status')},
  {id: 'more', label: I18n.t('More')},
]

export default class StudentsTable extends React.Component {
  static propTypes = {
    assignment: TeacherAssignmentShape.isRequired,
    submissions: arrayOf(SubmissionShape).isRequired,
    onRequestSort: func,
    sortableColumns: arrayOf(string),
    sortId: string, // id of column above, or ''
    sortDirection: string, // 'ascending', 'descending', or 'none'
    assignToFilter: string,
    attemptFilter: number,
    statusFilter: string,
  }

  static defaultProps = {
    sortableColumns: [],
    sortId: '',
    sortDirection: 'none',
    onRequestSort: () => {},
  }

  // @ts-expect-error
  constructor(props) {
    super(props)
    this.state = {
      trayOpen: false,
      trayStudentIndex: null,
      studentData: StudentsTable.prepareStudentData(props),
    }
  }

  // @ts-expect-error
  static getDerivedStateFromProps(props) {
    return {studentData: StudentsTable.prepareStudentData(props)}
  }

  // @ts-expect-error
  static prepareStudentData(props) {
    let submissions = props.submissions

    if (props.attemptFilter) {
      // @ts-expect-error
      submissions = submissions.filter(sub => {
        return sub.attempt >= props.attemptFilter
      })
    }

    if (props.statusFilter === 'excused') {
      // @ts-expect-error
      submissions = submissions.filter(sub => {
        return sub.excused
      })
    } else if (props.statusFilter) {
      // @ts-expect-error
      submissions = submissions.filter(sub => {
        return sub.submissionStatus === props.statusFilter
      })
    }

    // @ts-expect-error
    return submissions.map(submission => ({
      ...submission.user,
      ...{submission},
    }))
  }

  // @ts-expect-error
  renderNameColumn(student) {
    const displayName = student.shortName || student.name || I18n.t('User')
    return (
      <>
        <Avatar
          name={student.name}
          src={student.avatarUrl}
          size="small"
          margin="0 small 0 0"
          data-fs-exclude={true}
        />
        {displayName}
      </>
    )
  }

  // @ts-expect-error
  renderAttemptsColumn(student) {
    // @ts-expect-error
    const assignmentLid = this.props.assignment.lid
    // @ts-expect-error
    const courseLid = this.props.assignment.course.lid
    // @ts-expect-error
    const attempts = student.submission.submissionHistories.nodes.map(attempt => {
      const viewLink = `/courses/${courseLid}/gradebook/speed_grader?assignment_id=${assignmentLid}&student_id=${student.lid}&attempt=${attempt.attempt}`
      return (
        <View as="div" margin="0 0 x-small" key={attempt.attempt}>
          <Link
            href={viewLink}
            isWithinText={false}
            target="_blank"
            // @ts-expect-error
            themeOverride={{mediumPaddingHorizontal: '0', mediumHeight: 'normal'}}
          >
            {I18n.t('Attempt %{number}', {number: attempt.attempt})}
          </Link>
        </View>
      )
    })
    if (attempts.length) {
      return attempts
    } else if (student.submission.submissionDraft) {
      return (
        <View as="div" margin="0 0 x-small" key="draft">
          {I18n.t('In Progress')}
        </View>
      )
    }
  }

  // @ts-expect-error
  renderScoreColumn(student) {
    // @ts-expect-error
    return student.submission.submissionHistories.nodes.map(attempt => {
      const validScore = attempt.score || attempt.score === 0
      return (
        <View as="div" margin="0 0 x-small" key={attempt.attempt}>
          {I18n.t('{{student_points}}/{{possible_points}}', {
            student_points: validScore ? attempt.score : '\u2013',
            // @ts-expect-error
            possible_points: this.props.assignment.pointsPossible,
          })}
        </View>
      )
    })
  }

  // @ts-expect-error
  renderSubmittedAtColumn(student) {
    // @ts-expect-error
    return student.submission.submissionHistories.nodes.map(attempt => {
      return (
        <View as="div" margin="0 0 x-small" key={attempt.attempt}>
          <FriendlyDatetime dateTime={attempt.submittedAt} format={I18n.t('#date.formats.full')} />
        </View>
      )
    })
  }

  // @ts-expect-error
  renderSubmissionStatusColumn(student) {
    return (
      <SubmissionStatusPill
        excused={student.submission.excused}
        submissionStatus={student.submission.submissionStatus}
      />
    )
  }

  // @ts-expect-error
  renderTrayButton(student) {
    return (
      <IconButton
        renderIcon={<IconExpandStartLine rotate="180" />}
        withBackground={false}
        withBorder={false}
        data-student-id={student.lid}
        // @ts-expect-error
        ref={b => (this.trayButton = b)}
        onClick={this.handleTrayOpen}
        screenReaderLabel={I18n.t('Open student context tray')}
      />
    )
  }

  // @ts-expect-error
  renderStudent(student) {
    return (
      <Row key={student.lid}>
        <Cell>{this.renderNameColumn(student)}</Cell>
        <Cell>{this.renderAttemptsColumn(student)}</Cell>
        <Cell>{this.renderScoreColumn(student)}</Cell>
        <Cell>{this.renderSubmittedAtColumn(student)}</Cell>
        <Cell>{this.renderSubmissionStatusColumn(student)}</Cell>
        <Cell>{this.renderTrayButton(student)}</Cell>
      </Row>
    )
  }

  renderStudents() {
    // @ts-expect-error
    return this.state.studentData.map(student => this.renderStudent(student))
  }

  hideTray = () => {
    this.setState({trayOpen: false})
  }

  // @ts-expect-error
  handleTrayOpen = event => {
    const button = event.target.closest('button')
    const chosenId = button.dataset.studentId
    this.setState(prevState => {
      // @ts-expect-error
      const selectedStudentIndex = prevState.studentData.findIndex(
        // @ts-expect-error
        aStudent => aStudent.lid === chosenId,
      )
      return {
        trayOpen: true,
        trayStudentIndex: selectedStudentIndex,
      }
    })
  }

  handleTrayPreviousStudent = () => {
    this.setState(prevState => ({
      trayStudentIndex:
        // @ts-expect-error
        prevState.trayStudentIndex > 0
          ? // @ts-expect-error
            prevState.trayStudentIndex - 1
          : // @ts-expect-error
            prevState.studentData.length - 1,
    }))
  }

  handleTrayNextStudent = () => {
    this.setState(prevState => ({
      trayStudentIndex:
        // @ts-expect-error
        prevState.trayStudentIndex === prevState.studentData.length - 1
          ? 0
          : // @ts-expect-error
            prevState.trayStudentIndex + 1,
    }))
  }

  renderTray() {
    const student =
      // @ts-expect-error
      this.state.trayStudentIndex === null
        ? null
        : // @ts-expect-error
          this.state.studentData[this.state.trayStudentIndex]
    return (
      student && (
        <StudentTray
          // @ts-expect-error
          assignment={this.props.assignment}
          student={student}
          // @ts-expect-error
          trayOpen={this.state.trayOpen}
          onHideTray={this.hideTray}
          onPreviousStudent={this.handleTrayPreviousStudent}
          onNextStudent={this.handleTrayNextStudent}
        />
      )
    )
  }

  // @ts-expect-error
  renderHeader = ({id, label}) => {
    const sortProps = {}
    // @ts-expect-error
    if (this.props.sortableColumns.includes(id)) {
      // @ts-expect-error
      sortProps.onRequestSort = this.props.onRequestSort
    }
    // @ts-expect-error
    if (this.props.sortId === id) {
      // @ts-expect-error
      sortProps.sortDirection = this.props.sortDirection
    }
    return (
      <ColHeader key={id} id={id} {...sortProps}>
        {label}
      </ColHeader>
    )
  }

  render() {
    return (
      <View as="div">
        {this.renderTray()}
        <Table
          caption={
            <ScreenReaderContent>{I18n.t('Overview of student status')}</ScreenReaderContent>
          }
        >
          <Head renderSortLabel={<ScreenReaderContent>{I18n.t('Sort by')}</ScreenReaderContent>}>
            <Row>{HEADERS.map(this.renderHeader)}</Row>
          </Head>
          <Body>{this.renderStudents()}</Body>
        </Table>
      </View>
    )
  }
}
