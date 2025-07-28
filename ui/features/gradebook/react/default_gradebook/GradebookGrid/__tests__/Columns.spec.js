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

import GradebookGrid from '../index'

describe('GradebookGrid Columns', () => {
  let gradebookGridOptions
  let gradebookGrid

  beforeEach(() => {
    gradebookGridOptions = {
      data: {
        columns: {
          definitions: {},
          frozen: ['student', 'custom_col_2401'],
          scrollable: ['assignment_2301', 'total_grade', 'total_grade_override'],
        },
        rows: [],
      },
    }
  })

  function createGradebookGrid() {
    gradebookGrid = new GradebookGrid(gradebookGridOptions)
  }

  describe('#getIndexOfColumn()', () => {
    test('returns the index of frozen columns', () => {
      createGradebookGrid()
      expect(gradebookGrid.columns.getIndexOfColumn('custom_col_2401')).toBe(1)
    })

    test('returns the offset index of scrollable columns', () => {
      createGradebookGrid()
      expect(gradebookGrid.columns.getIndexOfColumn('total_grade')).toBe(3)
    })
  })
})
