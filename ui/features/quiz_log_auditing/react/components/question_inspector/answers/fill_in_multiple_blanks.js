/*
 * Copyright (C) 2021 - present Instructure, Inc.
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
import K from '../../../../constants'
import NO_ANSWER from './no_answer'

const FIMB = ({answer}) => (
  <table>
    <tbody>
      {Object.keys(answer).map(function (blank) {
        return (
          <tr key={'blank' + blank}>
            <th scope="row">{blank}</th>
            <td>{answer[blank] || NO_ANSWER}</td>
          </tr>
        )
      })}
    </tbody>
  </table>
)

FIMB.questionTypes = [K.Q_FILL_IN_MULTIPLE_BLANKS]

export default FIMB
