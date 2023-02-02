// @ts-nocheck
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
import {Text} from '@instructure/ui-text'

import {
  gradeInfo as gradeInfoPropType,
  gradeEntry as gradeEntryPropType,
} from '../GradeInput/PropTypes'
import CellEditorComponent from '../CellEditorComponent'

export default class ReadOnlyCell extends CellEditorComponent {
  static propTypes = {
    gradeEntry: gradeEntryPropType.isRequired,
    gradeInfo: gradeInfoPropType.isRequired,
    pendingGradeInfo: gradeInfoPropType,
  }

  static defaultProps = {
    pendingGradeInfo: null,
  }

  render() {
    const {gradeEntry, gradeInfo, pendingGradeInfo} = this.props
    const displayValue = gradeEntry.formatGradeInfoForDisplay(pendingGradeInfo || gradeInfo)

    return (
      <div className="Grid__GradeCell Grid__ReadOnlyCell">
        <div className="Grid__GradeCell__StartContainer" />

        <div className="Grid__GradeCell__Content">
          <Text size="small">{displayValue}</Text>
        </div>

        <div className="Grid__GradeCell__EndContainer" />
      </div>
    )
  }
}
