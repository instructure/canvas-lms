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

/* eslint-disable react/no-array-index-key */

import React, {Component} from 'react'
import {arrayOf, bool, func, shape, string} from 'prop-types'
import ScreenReaderContent from '@instructure/ui-a11y/lib/components/ScreenReaderContent'
import Text from '@instructure/ui-elements/lib/components/Text'
import I18n from 'i18n!assignment_grade_summary'

import GridRow from './GridRow'

export default class Grid extends Component {
  static propTypes = {
    disabledCustomGrade: bool.isRequired,
    finalGrader: shape({
      graderId: string.isRequired
    }),
    graders: arrayOf(
      shape({
        graderName: string,
        graderId: string.isRequired
      })
    ).isRequired,
    grades: shape({}).isRequired,
    horizontalScrollRef: func.isRequired,
    onGradeSelect: func,
    rows: arrayOf(
      shape({
        studentId: string.isRequired,
        studentName: string.isRequired
      }).isRequired
    ).isRequired,
    selectProvisionalGradeStatuses: shape({}).isRequired
  }

  static defaultProps = {
    finalGrader: null,
    onGradeSelect: null
  }

  shouldComponentUpdate(nextProps) {
    return Object.keys(nextProps).some(key => this.props[key] !== nextProps[key])
  }

  render() {
    return (
      <div className="GradesGrid" ref={this.props.horizontalScrollRef}>
        <table role="table">
          <caption>
            {<ScreenReaderContent>{I18n.t('Grade Selection Table')}</ScreenReaderContent>}
          </caption>

          <thead>
            <tr className="GradesGrid__HeaderRow" role="row">
              <th className="GradesGrid__StudentColumnHeader" role="columnheader" scope="col">
                <Text>{I18n.t('Student')}</Text>
              </th>

              {this.props.graders.map(grader => (
                <th
                  className="GradesGrid__GraderHeader"
                  key={grader.graderId}
                  role="columnheader"
                  scope="col"
                >
                  <Text>{grader.graderName}</Text>
                </th>
              ))}

              <th className="GradesGrid__FinalGradeHeader" role="columnheader" scope="col">
                <Text>{I18n.t('Final Grade')}</Text>
              </th>
            </tr>
          </thead>

          <tbody>
            {this.props.rows.map((row, index) => (
              <GridRow
                disabledCustomGrade={this.props.disabledCustomGrade}
                finalGrader={this.props.finalGrader}
                graders={this.props.graders}
                grades={this.props.grades[row.studentId]}
                key={index /* index used for performance reasons */}
                onGradeSelect={this.props.onGradeSelect}
                row={row}
                selectProvisionalGradeStatus={
                  this.props.selectProvisionalGradeStatuses[row.studentId]
                }
              />
            ))}
          </tbody>
        </table>
      </div>
    )
  }
}
