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

import React, {Component} from 'react'
import {arrayOf, shape, string} from 'prop-types'
import I18n from 'i18n!assignment_grade_summary'

import Grid from './Grid'

function studentToRow(student, index) {
  return {
    studentId: student.id,
    studentName:
      student.displayName || I18n.t('Student %{studentNumber}', {studentNumber: I18n.n(index + 1)})
  }
}

export default class GradesGrid extends Component {
  static propTypes = {
    graders: arrayOf(
      shape({
        graderName: string,
        graderId: string.isRequired
      })
    ).isRequired,
    grades: shape({}).isRequired,
    students: arrayOf(
      shape({
        displayName: string,
        id: string.isRequired
      }).isRequired
    ).isRequired
  }

  constructor(props) {
    super(props)

    this.state = {
      rows: this.props.students.map(studentToRow)
    }
  }

  componentWillReceiveProps(nextProps) {
    if (nextProps.students !== this.props.students) {
      this.setState({
        rows: nextProps.students.map(studentToRow)
      })
    }
  }

  render() {
    return (
      <div className="GradesGridContainer">
        <Grid graders={this.props.graders} grades={this.props.grades} rows={this.state.rows} />
      </div>
    )
  }
}
