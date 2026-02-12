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
      }),
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

  // @ts-expect-error
  shouldComponentUpdate(nextProps) {
    // @ts-expect-error
    return Object.keys(nextProps).some(key => this.props[key] !== nextProps[key])
  }

  render() {
    return (
      // @ts-expect-error
      <tr className={`GradesGrid__BodyRow student_${this.props.row.studentId}`} role="row">
        <th className="GradesGrid__BodyRowHeader" role="rowheader" scope="row">
          <Link
            // @ts-expect-error
            themeOverride={{mediumPaddingHorizontal: '0', mediumHeight: '1.25rem'}}
            // @ts-expect-error
            href={this.props.row.speedGraderUrl}
            isWithinText={false}
          >
            {/* @ts-expect-error */}
            {this.props.row.studentName}
          </Link>
        </th>

        {/* @ts-expect-error */}
        {this.props.graders.map(grader => {
          const classNames = ['GradesGrid__ProvisionalGradeCell', `grader_${grader.graderId}`]

          return (
            <td className={classNames.join(' ')} key={grader.graderId} role="cell">
              {/* @ts-expect-error */}
              <GradeIndicator gradeInfo={this.props.grades[grader.graderId]} />
            </td>
          )
        })}

        <td className="GradesGrid__FinalGradeCell" role="cell">
          <GradeSelect
            // @ts-expect-error
            disabledCustomGrade={this.props.disabledCustomGrade}
            // @ts-expect-error
            finalGrader={this.props.finalGrader}
            // @ts-expect-error
            graders={this.props.graders}
            // @ts-expect-error
            grades={this.props.grades}
            // @ts-expect-error
            onSelect={this.props.onGradeSelect}
            // @ts-expect-error
            selectProvisionalGradeStatus={this.props.selectProvisionalGradeStatus}
            // @ts-expect-error
            studentId={this.props.row.studentId}
            // @ts-expect-error
            studentName={this.props.row.studentName}
          />
        </td>
      </tr>
    )
  }
}
