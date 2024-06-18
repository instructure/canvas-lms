/*
 * Copyright (C) 2017 - present Instructure, Inc.
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

import CellEditorFactory from '../../editors/CellEditorFactory'
import AssignmentCellEditor from '../../editors/AssignmentCellEditor/index'
import TotalGradeOverrideCellEditor from '../../editors/TotalGradeOverrideCellEditor/index'

describe('GradebookGrid CellEditorFactory', () => {
  describe('#getEditor()', () => {
    test('returns AssignmentCellEditor for columns of type "assignment"', () => {
      const factory = new CellEditorFactory()
      expect(factory.getEditor({type: 'assignment'})).toBe(AssignmentCellEditor)
    })

    test('returns TotalGradeOverrideCellEditor for columns of type "total_grade_override"', () => {
      const factory = new CellEditorFactory()
      expect(factory.getEditor({type: 'total_grade_override'})).toBe(TotalGradeOverrideCellEditor)
    })

    test('returns undefined for unhandled column types', () => {
      const factory = new CellEditorFactory()
      expect(factory.getEditor({type: 'unknown'})).toBeUndefined()
    })
  })
})
