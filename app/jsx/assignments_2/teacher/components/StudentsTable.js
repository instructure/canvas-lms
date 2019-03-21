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
import {arrayOf, func, string} from 'prop-types'
import I18n from 'i18n!assignments_2'

import ScreenReaderContent from '@instructure/ui-a11y/lib/components/ScreenReaderContent'

import {TeacherAssignmentShape, SubmissionShape} from '../assignmentData'

import View from '@instructure/ui-layout/lib/components/View'
import {Table} from '@instructure/ui-table'
import Button from '@instructure/ui-buttons/lib/components/Button'
import IconExpandStart from '@instructure/ui-icons/lib/Line/IconExpandStart'
import Avatar from '@instructure/ui-elements/lib/components/Avatar'
import SubmissionStatusPill from '../../shared/SubmissionStatusPill'
import FriendlyDatetime from '../../../shared/FriendlyDatetime'
import Link from '@instructure/ui-elements/lib/components/Link'
import StudentTray from './StudentTray'

const {Head, Body, ColHeader, Row, Cell} = Table

const HEADERS = [
  {id: 'username', label: I18n.t('Name')},
  {id: 'attempts', label: I18n.t('submission_attempts', 'Attempts')},
  {id: 'score', label: I18n.t('Score')},
  {id: 'submitted_at', label: I18n.t('Submission Date')},
  {id: 'status', label: I18n.t('Status')},
  {id: 'more', label: I18n.t('More')}
]

export default class StudentsTable extends React.Component {
  static propTypes = {
    assignment: TeacherAssignmentShape.isRequired,
    submissions: arrayOf(SubmissionShape).isRequired,
    sortableColumns: arrayOf(string),
    sortId: string, // id of column above, or ''
    sortDirection: string, // 'ascending', 'descending', or 'none'
    onRequestSort: func
  }

  static defaultProps = {
    sortableColumns: [],
    sortId: '',
    sortDirection: 'none',
    onRequestSort: () => {}
  }

  constructor(props) {
    super(props)
    this.state = {
      trayOpen: false,
      trayStudentIndex: null,
      studentData: StudentsTable.prepareStudentData(props)
    }
  }

  static getDerivedStateFromProps(props) {
    return {studentData: StudentsTable.prepareStudentData(props)}
  }

  static prepareStudentData(props) {
    return props.submissions.map(submission => ({
      ...submission.user,
      ...{submission}
    }))
  }

  renderNameColumn(student) {
    const displayName = student.shortName || student.name || I18n.t('User')
    return (
      <React.Fragment>
        <Avatar name={student.name} src={student.avatarUrl} size="small" margin="0 small 0 0" />
        {displayName}
      </React.Fragment>
    )
  }

  renderAttemptsColumn(student) {
    if (!student.submission.submittedAt) {
      return null
    }
    const assignmentLid = this.props.assignment.lid
    const courseLid = this.props.assignment.course.lid
    const viewLink = `/courses/${courseLid}/assignments/${assignmentLid}/submissions/${student.lid}`
    return (
      <Link href={viewLink} target="_blank">
        {I18n.t('View Submission')}
      </Link>
    )
  }

  renderScoreColumn(student) {
    const validScore = student.submission.score || student.submission.score === 0
    return I18n.t('{{student_points}}/{{possible_points}}', {
      student_points: validScore ? student.submission.score : '\u2013',
      possible_points: this.props.assignment.pointsPossible
    })
  }

  renderSubmittedAtColumn(student) {
    return (
      student.submission.submittedAt && (
        <FriendlyDatetime
          dateTime={student.submission.submittedAt}
          format={I18n.t('#date.formats.full')}
        />
      )
    )
  }

  renderSubmissionStatusColumn(student) {
    return <SubmissionStatusPill submissionStatus={student.submission.submissionStatus} />
  }

  renderTrayButton(student) {
    return (
      <Button
        variant="icon"
        icon={<IconExpandStart rotate="180" />}
        data-student-id={student.lid}
        ref={b => (this.trayButton = b)}
        onClick={this.handleTrayOpen}
      >
        <ScreenReaderContent>{I18n.t('Open student context tray')}</ScreenReaderContent>
      </Button>
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
    const chosenId = event.target.dataset.studentId
    this.setState(prevState => {
      const selectedStudentIndex = prevState.studentData.findIndex(
        aStudent => aStudent.lid === chosenId
      )
      return {
        trayOpen: true,
        trayStudentIndex: selectedStudentIndex
      }
    })
  }

  handleTrayPreviousStudent = () => {
    this.setState(prevState => ({
      trayStudentIndex:
        prevState.trayStudentIndex > 0
          ? prevState.trayStudentIndex - 1
          : prevState.studentData.length - 1
    }))
  }

  handleTrayNextStudent = () => {
    this.setState(prevState => ({
      trayStudentIndex:
        prevState.trayStudentIndex === prevState.studentData.length - 1
          ? 0
          : prevState.trayStudentIndex + 1
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
          <Head>
            <Row>{HEADERS.map(this.renderHeader)}</Row>
          </Head>
          <Body>{this.renderStudents()}</Body>
        </Table>
      </View>
    )
  }
}
