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
import {arrayOf, bool, func, shape, string} from 'prop-types'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {Text} from '@instructure/ui-text'
import {useScope as createI18nScope} from '@canvas/i18n'

import GridRow from './GridRow'

const I18n = createI18nScope('assignment_grade_summary')

export default class Grid extends Component {
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
    grades: shape({}).isRequired,
    horizontalScrollRef: func.isRequired,
    onGradeSelect: func,
    rows: arrayOf(
      shape({
        speedGraderUrl: string.isRequired,
        studentId: string.isRequired,
        studentName: string.isRequired,
      }).isRequired,
    ).isRequired,
    selectProvisionalGradeStatuses: shape({}).isRequired,
  }

  static defaultProps = {
    finalGrader: null,
    onGradeSelect: null,
  }

  // @ts-expect-error
  shouldComponentUpdate(nextProps) {
    // @ts-expect-error
    return Object.keys(nextProps).some(key => this.props[key] !== nextProps[key])
  }

  render() {
    return (
      // @ts-expect-error
      <div className="GradesGrid" ref={this.props.horizontalScrollRef}>
        <table role="table">
          <caption>
            <ScreenReaderContent>{I18n.t('Grade Selection Table')}</ScreenReaderContent>
          </caption>

          <thead>
            <tr className="GradesGrid__HeaderRow" role="row">
              <th className="GradesGrid__StudentColumnHeader" role="columnheader" scope="col">
                <Text>{I18n.t('Student')}</Text>
              </th>

              {/* @ts-expect-error */}
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
            {/* @ts-expect-error */}
            {this.props.rows.map(row => (
              <GridRow
                // @ts-expect-error
                disabledCustomGrade={this.props.disabledCustomGrade}
                // @ts-expect-error
                finalGrader={this.props.finalGrader}
                // @ts-expect-error
                graders={this.props.graders}
                // @ts-expect-error
                grades={this.props.grades[row.studentId]}
                key={row.studentId}
                // @ts-expect-error
                onGradeSelect={this.props.onGradeSelect}
                row={row}
                selectProvisionalGradeStatus={
                  // @ts-expect-error
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
