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
import {arrayOf, shape, string} from 'prop-types'
import Text from '@instructure/ui-elements/lib/components/Text'
import I18n from 'i18n!assignment_grade_summary'

import GridRow from './GridRow'

export default class Grid extends Component {
  static propTypes = {
    graders: arrayOf(
      shape({
        graderName: string,
        graderId: string.isRequired
      })
    ).isRequired,
    grades: shape({}).isRequired,
    rows: arrayOf(
      shape({
        studentId: string.isRequired,
        studentName: string.isRequired
      }).isRequired
    ).isRequired
  }

  shouldComponentUpdate(nextProps) {
    return Object.keys(nextProps).some(key => this.props[key] !== nextProps[key])
  }

  render() {
    return (
      <div className="GradesGrid">
        <table>
          <thead className="GradesGrid__Header">
            <tr className="GradesGrid__HeaderRow">
              <th className="GradesGrid__StudentColumnHeader" scope="col">
                <Text>{I18n.t('Student')}</Text>
              </th>

              {this.props.graders.map((grader, index) => (
                <th className="GradesGrid__GraderHeader" key={grader.graderId} scope="col">
                  <Text>
                    {grader.graderName ||
                      I18n.t('Grader %{graderNumber}', {graderNumber: I18n.n(index + 1)})}
                  </Text>
                </th>
              ))}
            </tr>
          </thead>

          <tbody className="GradesGrid__Body">
            {this.props.rows.map((row, index) => (
              <GridRow
                graders={this.props.graders}
                grades={this.props.grades[row.studentId]}
                key={index /* index used for performance reasons */}
                row={row}
              />
            ))}
          </tbody>
        </table>
      </div>
    )
  }
}
