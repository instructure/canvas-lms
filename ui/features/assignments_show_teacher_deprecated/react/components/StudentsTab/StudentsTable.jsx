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
import {useScope as useI18nScope} from '@canvas/i18n'

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

const I18n = useI18nScope('assignments_2')

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

  constructor(props) {
    super(props)
    this.state = {
      trayOpen: false,
      trayStudentIndex: null,
      studentData: StudentsTable.prepareStudentData(props),
    }
  }

  static getDerivedStateFromProps(props) {
    return {studentData: StudentsTable.prepareStudentData(props)}
  }

  static prepareStudentData(props) {
    let submissions = props.submissions

    if (props.attemptFilter) {
      submissions = submissions.filter(sub => {
        return sub.attempt >= props.attemptFilter
      })
    }

    if (props.statusFilter === 'excused') {
      submissions = submissions.filter(sub => {
        return sub.excused
      })
    } else if (props.statusFilter) {
      submissions = submissions.filter(sub => {
        return sub.submissionStatus === props.statusFilter
      })
    }

    return submissions.map(submission => ({
      ...submission.user,
      ...{submission},
    }))
  }

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

  renderAttemptsColumn(student) {
    const assignmentLid = this.props.assignment.lid
    const courseLid = this.props.assignment.course.lid
    const attempts = student.submission.submissionHistories.nodes.map(attempt => {
      const viewLink = `/courses/${courseLid}/gradebook/speed_grader?assignment_id=${assignmentLid}&student_id=${student.lid}&attempt=${attempt.attempt}`
      return (
        <View as="div" margin="0 0 x-small" key={attempt.attempt}>
          <Link
            href={viewLink}
            isWithinText={false}
            target="_blank"
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

  renderScoreColumn(student) {
    return student.submission.submissionHistories.nodes.map(attempt => {
      const validScore = attempt.score || attempt.score === 0
      return (
        <View as="div" margin="0 0 x-small" key={attempt.attempt}>
          {I18n.t('{{student_points}}/{{possible_points}}', {
            student_points: validScore ? attempt.score : '\u2013',
            possible_points: this.props.assignment.pointsPossible,
          })}
        </View>
      )
    })
  }

  renderSubmittedAtColumn(student) {
    return student.submission.submissionHistories.nodes.map(attempt => {
      return (
        <View as="div" margin="0 0 x-small" key={attempt.attempt}>
          <FriendlyDatetime dateTime={attempt.submittedAt} format={I18n.t('#date.formats.full')} />
        </View>
      )
    })
  }

  renderSubmissionStatusColumn(student) {
    return (
      <SubmissionStatusPill
        excused={student.submission.excused}
        submissionStatus={student.submission.submissionStatus}
      />
    )
  }

  renderTrayButton(student) {
    return (
      <IconButton
        renderIcon={<IconExpandStartLine rotate="180" />}
        withBackground={false}
        withBorder={false}
        data-student-id={student.lid}
        ref={b => (this.trayButton = b)}
        onClick={this.handleTrayOpen}
        screenReaderLabel={I18n.t('Open student context tray')}
      />
    )
  }

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
    return this.state.studentData.map(student => this.renderStudent(student))
  }

  hideTray = () => {
    this.setState({trayOpen: false})
  }

  handleTrayOpen = event => {
    const button = event.target.closest('button')
    const chosenId = button.dataset.studentId
    this.setState(prevState => {
      const selectedStudentIndex = prevState.studentData.findIndex(
        aStudent => aStudent.lid === chosenId
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
        prevState.trayStudentIndex > 0
          ? prevState.trayStudentIndex - 1
          : prevState.studentData.length - 1,
    }))
  }

  handleTrayNextStudent = () => {
    this.setState(prevState => ({
      trayStudentIndex:
        prevState.trayStudentIndex === prevState.studentData.length - 1
          ? 0
          : prevState.trayStudentIndex + 1,
    }))
  }

  renderTray() {
    const student =
      this.state.trayStudentIndex === null
        ? null
        : this.state.studentData[this.state.trayStudentIndex]
    return (
      student && (
        <StudentTray
          assignment={this.props.assignment}
          student={student}
          trayOpen={this.state.trayOpen}
          onHideTray={this.hideTray}
          onPreviousStudent={this.handleTrayPreviousStudent}
          onNextStudent={this.handleTrayNextStudent}
        />
      )
    )
  }

  renderHeader = ({id, label}) => {
    const sortProps = {}
    if (this.props.sortableColumns.includes(id)) {
      sortProps.onRequestSort = this.props.onRequestSort
    }
    if (this.props.sortId === id) {
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
