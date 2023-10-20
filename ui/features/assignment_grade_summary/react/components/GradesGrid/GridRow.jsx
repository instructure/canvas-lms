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
import {arrayOf, bool, func, oneOf, shape, string} from 'prop-types'

import {FAILURE, STARTED, SUCCESS} from '../../grades/GradeActions'
import GradeIndicator from './GradeIndicator'
import GradeSelect from './GradeSelect'

import {Link} from '@instructure/ui-link'

export default class GridRow extends Component {
  static propTypes = {
    disabledCustomGrade: bool.isRequired,
    finalGrader: shape({
      graderId: string.isRequired,
    }),
    graders: arrayOf(
      shape({
        graderName: string,
        graderId: string.isRequired,
      })
    ).isRequired,
    grades: shape({}),
    onGradeSelect: func,
    row: shape({
      speedGraderUrl: string.isRequired,
      studentId: string.isRequired,
      studentName: string.isRequired,
    }).isRequired,
    selectProvisionalGradeStatus: oneOf([FAILURE, STARTED, SUCCESS]),
  }

  static defaultProps = {
    finalGrader: null,
    grades: {},
    onGradeSelect: null,
    selectProvisionalGradeStatus: null,
  }

  shouldComponentUpdate(nextProps) {
    return Object.keys(nextProps).some(key => this.props[key] !== nextProps[key])
  }

  render() {
    return (
      <tr className={`GradesGrid__BodyRow student_${this.props.row.studentId}`} role="row">
        <th className="GradesGrid__BodyRowHeader" role="rowheader" scope="row">
          <Link
            themeOverride={{mediumPaddingHorizontal: '0', mediumHeight: '1.25rem'}}
            href={this.props.row.speedGraderUrl}
            isWithinText={false}
          >
            {this.props.row.studentName}
          </Link>
        </th>

        {this.props.graders.map(grader => {
          const classNames = ['GradesGrid__ProvisionalGradeCell', `grader_${grader.graderId}`]

          return (
            <td className={classNames.join(' ')} key={grader.graderId} role="cell">
              <GradeIndicator gradeInfo={this.props.grades[grader.graderId]} />
            </td>
          )
        })}

        <td className="GradesGrid__FinalGradeCell" role="cell">
          <GradeSelect
            disabledCustomGrade={this.props.disabledCustomGrade}
            finalGrader={this.props.finalGrader}
            graders={this.props.graders}
            grades={this.props.grades}
            onSelect={this.props.onGradeSelect}
            selectProvisionalGradeStatus={this.props.selectProvisionalGradeStatus}
            studentId={this.props.row.studentId}
            studentName={this.props.row.studentName}
          />
        </td>
      </tr>
    )
  }
}
