/*
 * Copyright (C) 2023 - present Instructure, Inc.
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

import {getColumnOrder, isInvalidSort, listRowIndicesForStudentIds} from '../Grid.utils'
import type {ColumnOrderSettings} from '../../gradebook.d'

describe('isInvalidSort', () => {
  const modules = [{id: '2601', name: 'Algebra', position: 1}]

  it('returns false if sorting by any valid criterion', () => {
    expect(isInvalidSort(modules, {sortType: 'name', direction: 'ascending'})).toBe(false)
  })

  it('returns true if sorting by module position but there are no modules in the course any more', () => {
    expect(isInvalidSort([], {sortType: 'module_position', direction: 'ascending'})).toBe(true)
  })

  it('returns true if sorting by custom but there is no custom column order stored', () => {
    expect(
      isInvalidSort(modules, {
        sortType: 'module_position',
        direction: 'ascending',
      })
    ).toBe(false)
  })

  it('returns false if sorting by custom and there is a custom column order stored', () => {
    expect(
      isInvalidSort(modules, {
        sortType: 'custom',
      })
    ).toBe(true)
  })

  it('returns true if sorting by custom and there is a custom column order stored', () => {
    expect(
      isInvalidSort(modules, {
        sortType: 'custom',
        customOrder: ['1', '2', '3'],
      })
    ).toBe(false)
  })
})

describe('getColumnOrder', () => {
  const modules = [{id: '2601', name: 'Algebra', position: 1}]

  it('sets column sort direction to "ascending" when the settings are invalid', () => {
    expect(
      getColumnOrder([], {
        direction: 'descending',
        freezeTotalGrade: false,
        sortType: 'module_position',
      })
    ).toMatchObject({
      direction: 'ascending',
    })
  })

  it('sets column sort type to "assignment_group" when the settings are invalid', () => {
    expect(
      getColumnOrder([], {
        direction: 'descending',
        freezeTotalGrade: false,
        sortType: 'module_position',
      })
    ).toMatchObject({
      sortType: 'assignment_group',
    })
  })

  it('freezes the total grade column when the setting is true', () => {
    expect(
      getColumnOrder([], {
        direction: 'descending',
        freezeTotalGrade: true,
        sortType: 'due_date',
      })
    ).toMatchObject({
      freezeTotalGrade: true,
    })
  })

  it('does not freeze the total grade column when the setting is false', () => {
    expect(
      getColumnOrder([], {
        direction: 'descending',
        freezeTotalGrade: false,
        sortType: 'due_date',
      })
    ).toMatchObject({
      freezeTotalGrade: false,
    })
  })

  it('does not freeze the total grade column when the setting is not set', () => {
    expect(
      getColumnOrder([], {
        direction: 'descending',
        sortType: 'due_date',
      })
    ).not.toMatchObject({
      freezeTotalGrade: false,
    })
  })

  it('sets column sort direction to "ascending" when the settings are invalid (3)', () => {
    expect(getColumnOrder(modules, {sortType: 'custom'})).toEqual({
      direction: 'ascending',
      sortType: 'assignment_group',
      freezeTotalGrade: false,
    })
  })

  it('sets column sort type to "assignment_group" when the settings are invalid (2)', () => {
    expect(getColumnOrder(modules, {sortType: 'custom'})).toEqual({
      direction: 'ascending',
      sortType: 'assignment_group',
      freezeTotalGrade: false,
    })
  })

  it('does not freeze the total grade column when the settings are invalid', () => {
    expect(getColumnOrder(modules, {sortType: 'custom'})).toEqual({
      direction: 'ascending',
      sortType: 'assignment_group',
      freezeTotalGrade: false,
    })
  })

  it('sets column sort direction to "ascending" when the settings are not defined', () => {
    expect(getColumnOrder(modules, undefined)).toEqual({
      direction: 'ascending',
      sortType: 'assignment_group',
      freezeTotalGrade: false,
    })
  })

  it('sets column sort type to "assignment_group" when the settings are not defined', () => {
    expect(getColumnOrder(modules, undefined)).toEqual({
      direction: 'ascending',
      sortType: 'assignment_group',
      freezeTotalGrade: false,
    })
  })

  it('does not freeze the total grade column when the settings are not defined', () => {
    expect(getColumnOrder(modules, undefined)).toEqual({
      direction: 'ascending',
      sortType: 'assignment_group',
      freezeTotalGrade: false,
    })
  })

  describe('#getColumnOrder when sorting by module position', () => {
    const settings: ColumnOrderSettings = {
      sortType: 'module_position',
      direction: 'descending',
      freezeTotalGrade: false,
    }

    it('includes the stored column sort direction', () => {
      expect(getColumnOrder(modules, settings)).toEqual({
        direction: 'descending',
        sortType: 'module_position',
        freezeTotalGrade: false,
      })
    })

    it('includes "module_position" as the stored column sort type', () => {
      expect(getColumnOrder(modules, settings)).toMatchObject({
        sortType: 'module_position',
      })
    })

    it('does not freeze the total grade column', () => {
      expect(getColumnOrder(modules, settings)).toMatchObject({
        freezeTotalGrade: false,
      })
    })

    it('sets the column direction to "ascending" when the course has no modules', () => {
      expect(getColumnOrder([], settings)).toMatchObject({
        direction: 'ascending',
      })
    })

    it('sets the column sort type to "assignment_group" when the course has no modules', () => {
      expect(getColumnOrder([], settings)).toMatchObject({
        sortType: 'assignment_group',
      })
    })
  })
})

describe('listRowIndicesForStudentIds', () => {
  expect(
    listRowIndicesForStudentIds(
      [{id: '1101'}, {id: '1102'}, {id: '1103'}, {id: '1104'}],
      ['1102', '1104']
    )
  ).toStrictEqual([1, 3])
})
