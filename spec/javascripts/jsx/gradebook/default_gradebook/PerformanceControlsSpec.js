/*
 * Copyright (C) 2020 - present Instructure, Inc.
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

import PerformanceControls from 'ui/features/gradebook/react/default_gradebook/PerformanceControls'

QUnit.module('Gradebook > PerformanceControls', () => {
  QUnit.module('#activeRequestLimit', () => {
    const defaultValue = 12
    const maxValue = 100
    const minValue = 1

    test('is set to the given value', () => {
      const controls = new PerformanceControls({activeRequestLimit: 15})
      strictEqual(controls.activeRequestLimit, 15)
    })

    test(`defaults to ${defaultValue}`, () => {
      const controls = new PerformanceControls({})
      strictEqual(controls.activeRequestLimit, defaultValue)
    })

    test(`clips values higher than ${maxValue}`, () => {
      const controls = new PerformanceControls({activeRequestLimit: maxValue + 1})
      strictEqual(controls.activeRequestLimit, maxValue)
    })

    test(`clips values lower than ${minValue}`, () => {
      const controls = new PerformanceControls({activeRequestLimit: minValue - 1})
      strictEqual(controls.activeRequestLimit, minValue)
    })

    test('converts valid string numbers', () => {
      const controls = new PerformanceControls({activeRequestLimit: '24'})
      strictEqual(controls.activeRequestLimit, 24)
    })

    test('rejects invalid strings', () => {
      const controls = new PerformanceControls({activeRequestLimit: 'invalid'})
      strictEqual(controls.activeRequestLimit, defaultValue)
    })

    test('rejects null', () => {
      const controls = new PerformanceControls({activeRequestLimit: null})
      strictEqual(controls.activeRequestLimit, defaultValue)
    })

    test('rejects undefined', () => {
      const controls = new PerformanceControls({activeRequestLimit: undefined})
      strictEqual(controls.activeRequestLimit, defaultValue)
    })
  })

  QUnit.module('#apiMaxPerPage', () => {
    const defaultValue = 100
    const maxValue = 500
    const minValue = 1

    test('is set to the given value', () => {
      const controls = new PerformanceControls({apiMaxPerPage: 15})
      strictEqual(controls.apiMaxPerPage, 15)
    })

    test(`defaults to ${defaultValue}`, () => {
      const controls = new PerformanceControls({})
      strictEqual(controls.apiMaxPerPage, defaultValue)
    })

    test(`clips values higher than ${maxValue}`, () => {
      const controls = new PerformanceControls({apiMaxPerPage: maxValue + 1})
      strictEqual(controls.apiMaxPerPage, maxValue)
    })

    test(`clips values lower than ${minValue}`, () => {
      const controls = new PerformanceControls({apiMaxPerPage: minValue - 1})
      strictEqual(controls.apiMaxPerPage, minValue)
    })

    test('converts valid string numbers', () => {
      const controls = new PerformanceControls({apiMaxPerPage: '24'})
      strictEqual(controls.apiMaxPerPage, 24)
    })

    test('rejects invalid strings', () => {
      const controls = new PerformanceControls({apiMaxPerPage: 'invalid'})
      strictEqual(controls.apiMaxPerPage, defaultValue)
    })

    test('rejects null', () => {
      const controls = new PerformanceControls({apiMaxPerPage: null})
      strictEqual(controls.apiMaxPerPage, defaultValue)
    })

    test('rejects undefined', () => {
      const controls = new PerformanceControls({apiMaxPerPage: undefined})
      strictEqual(controls.apiMaxPerPage, defaultValue)
    })
  })

  QUnit.module('#assignmentGroupsPerPage', () => {
    const defaultValue = 100
    const minValue = 1

    test('is set to the given value', () => {
      const controls = new PerformanceControls({assignmentGroupsPerPage: 15})
      strictEqual(controls.assignmentGroupsPerPage, 15)
    })

    test(`defaults to ${defaultValue}`, () => {
      const controls = new PerformanceControls({})
      strictEqual(controls.assignmentGroupsPerPage, defaultValue)
    })

    test(`clips values higher than the apiMaxPerPage`, () => {
      const {apiMaxPerPage} = new PerformanceControls({})
      const controls = new PerformanceControls({assignmentGroupsPerPage: apiMaxPerPage + 1})
      strictEqual(controls.assignmentGroupsPerPage, apiMaxPerPage)
    })

    test(`clips values lower than ${minValue}`, () => {
      const controls = new PerformanceControls({assignmentGroupsPerPage: minValue - 1})
      strictEqual(controls.assignmentGroupsPerPage, minValue)
    })

    test('converts valid string numbers', () => {
      const controls = new PerformanceControls({assignmentGroupsPerPage: '24'})
      strictEqual(controls.assignmentGroupsPerPage, 24)
    })

    test('rejects invalid strings', () => {
      const controls = new PerformanceControls({assignmentGroupsPerPage: 'invalid'})
      strictEqual(controls.assignmentGroupsPerPage, defaultValue)
    })

    test('rejects null', () => {
      const controls = new PerformanceControls({assignmentGroupsPerPage: null})
      strictEqual(controls.assignmentGroupsPerPage, defaultValue)
    })

    test('rejects undefined', () => {
      const controls = new PerformanceControls({assignmentGroupsPerPage: undefined})
      strictEqual(controls.assignmentGroupsPerPage, defaultValue)
    })
  })

  QUnit.module('#contextModulesPerPage', () => {
    const defaultValue = 100
    const minValue = 1

    test('is set to the given value', () => {
      const controls = new PerformanceControls({contextModulesPerPage: 15})
      strictEqual(controls.contextModulesPerPage, 15)
    })

    test(`defaults to ${defaultValue}`, () => {
      const controls = new PerformanceControls({})
      strictEqual(controls.contextModulesPerPage, defaultValue)
    })

    test(`clips values higher than the apiMaxPerPage`, () => {
      const {apiMaxPerPage} = new PerformanceControls({})
      const controls = new PerformanceControls({contextModulesPerPage: apiMaxPerPage + 1})
      strictEqual(controls.contextModulesPerPage, apiMaxPerPage)
    })

    test(`clips values lower than ${minValue}`, () => {
      const controls = new PerformanceControls({contextModulesPerPage: minValue - 1})
      strictEqual(controls.contextModulesPerPage, minValue)
    })

    test('converts valid string numbers', () => {
      const controls = new PerformanceControls({contextModulesPerPage: '24'})
      strictEqual(controls.contextModulesPerPage, 24)
    })

    test('rejects invalid strings', () => {
      const controls = new PerformanceControls({contextModulesPerPage: 'invalid'})
      strictEqual(controls.contextModulesPerPage, defaultValue)
    })

    test('rejects null', () => {
      const controls = new PerformanceControls({contextModulesPerPage: null})
      strictEqual(controls.contextModulesPerPage, defaultValue)
    })

    test('rejects undefined', () => {
      const controls = new PerformanceControls({contextModulesPerPage: undefined})
      strictEqual(controls.contextModulesPerPage, defaultValue)
    })
  })

  QUnit.module('#customColumnDataPerPage', () => {
    const defaultValue = 100
    const minValue = 1

    test('is set to the given value', () => {
      const controls = new PerformanceControls({customColumnDataPerPage: 15})
      strictEqual(controls.customColumnDataPerPage, 15)
    })

    test(`defaults to ${defaultValue}`, () => {
      const controls = new PerformanceControls({})
      strictEqual(controls.customColumnDataPerPage, defaultValue)
    })

    test(`clips values higher than the apiMaxPerPage`, () => {
      const {apiMaxPerPage} = new PerformanceControls({})
      const controls = new PerformanceControls({customColumnDataPerPage: apiMaxPerPage + 1})
      strictEqual(controls.customColumnDataPerPage, apiMaxPerPage)
    })

    test(`clips values lower than ${minValue}`, () => {
      const controls = new PerformanceControls({customColumnDataPerPage: minValue - 1})
      strictEqual(controls.customColumnDataPerPage, minValue)
    })

    test('converts valid string numbers', () => {
      const controls = new PerformanceControls({customColumnDataPerPage: '24'})
      strictEqual(controls.customColumnDataPerPage, 24)
    })

    test('rejects invalid strings', () => {
      const controls = new PerformanceControls({customColumnDataPerPage: 'invalid'})
      strictEqual(controls.customColumnDataPerPage, defaultValue)
    })

    test('rejects null', () => {
      const controls = new PerformanceControls({customColumnDataPerPage: null})
      strictEqual(controls.customColumnDataPerPage, defaultValue)
    })

    test('rejects undefined', () => {
      const controls = new PerformanceControls({customColumnDataPerPage: undefined})
      strictEqual(controls.customColumnDataPerPage, defaultValue)
    })
  })

  QUnit.module('#customColumnsPerPage', () => {
    const defaultValue = 100
    const minValue = 1

    test('is set to the given value', () => {
      const controls = new PerformanceControls({customColumnsPerPage: 15})
      strictEqual(controls.customColumnsPerPage, 15)
    })

    test(`defaults to ${defaultValue}`, () => {
      const controls = new PerformanceControls({})
      strictEqual(controls.customColumnsPerPage, defaultValue)
    })

    test(`clips values higher than the apiMaxPerPage`, () => {
      const {apiMaxPerPage} = new PerformanceControls({})
      const controls = new PerformanceControls({customColumnsPerPage: apiMaxPerPage + 1})
      strictEqual(controls.customColumnDataPerPage, apiMaxPerPage)
    })

    test(`clips values lower than ${minValue}`, () => {
      const controls = new PerformanceControls({customColumnsPerPage: minValue - 1})
      strictEqual(controls.customColumnsPerPage, minValue)
    })

    test('converts valid string numbers', () => {
      const controls = new PerformanceControls({customColumnsPerPage: '24'})
      strictEqual(controls.customColumnsPerPage, 24)
    })

    test('rejects invalid strings', () => {
      const controls = new PerformanceControls({customColumnsPerPage: 'invalid'})
      strictEqual(controls.customColumnsPerPage, defaultValue)
    })

    test('rejects null', () => {
      const controls = new PerformanceControls({customColumnsPerPage: null})
      strictEqual(controls.customColumnsPerPage, defaultValue)
    })

    test('rejects undefined', () => {
      const controls = new PerformanceControls({customColumnsPerPage: undefined})
      strictEqual(controls.customColumnsPerPage, defaultValue)
    })
  })

  QUnit.module('#studentsChunkSize', () => {
    const defaultValue = 100
    const minValue = 1

    test('is set to the given value', () => {
      const controls = new PerformanceControls({studentsChunkSize: 15})
      strictEqual(controls.studentsChunkSize, 15)
    })

    test(`defaults to ${defaultValue}`, () => {
      const controls = new PerformanceControls({})
      strictEqual(controls.studentsChunkSize, defaultValue)
    })

    test(`clips values higher than the apiMaxPerPage`, () => {
      const {apiMaxPerPage} = new PerformanceControls({})
      const controls = new PerformanceControls({studentsChunkSize: apiMaxPerPage + 1})
      strictEqual(controls.customColumnDataPerPage, apiMaxPerPage)
    })

    test(`clips values lower than ${minValue}`, () => {
      const controls = new PerformanceControls({studentsChunkSize: minValue - 1})
      strictEqual(controls.studentsChunkSize, minValue)
    })

    test('converts valid string numbers', () => {
      const controls = new PerformanceControls({studentsChunkSize: '24'})
      strictEqual(controls.studentsChunkSize, 24)
    })

    test('rejects invalid strings', () => {
      const controls = new PerformanceControls({studentsChunkSize: 'invalid'})
      strictEqual(controls.studentsChunkSize, defaultValue)
    })

    test('rejects null', () => {
      const controls = new PerformanceControls({studentsChunkSize: null})
      strictEqual(controls.studentsChunkSize, defaultValue)
    })

    test('rejects undefined', () => {
      const controls = new PerformanceControls({studentsChunkSize: undefined})
      strictEqual(controls.studentsChunkSize, defaultValue)
    })
  })

  QUnit.module('#submissionsChunkSize', () => {
    const defaultValue = 10
    const minValue = 1

    test('is set to the given value', () => {
      const controls = new PerformanceControls({submissionsChunkSize: 15})
      strictEqual(controls.submissionsChunkSize, 15)
    })

    test(`defaults to ${defaultValue}`, () => {
      const controls = new PerformanceControls({})
      strictEqual(controls.submissionsChunkSize, defaultValue)
    })

    test(`clips values higher than the apiMaxPerPage`, () => {
      const {apiMaxPerPage} = new PerformanceControls({})
      const controls = new PerformanceControls({submissionsChunkSize: apiMaxPerPage + 1})
      strictEqual(controls.customColumnDataPerPage, apiMaxPerPage)
    })

    test(`clips values lower than ${minValue}`, () => {
      const controls = new PerformanceControls({submissionsChunkSize: minValue - 1})
      strictEqual(controls.submissionsChunkSize, minValue)
    })

    test('converts valid string numbers', () => {
      const controls = new PerformanceControls({submissionsChunkSize: '24'})
      strictEqual(controls.submissionsChunkSize, 24)
    })

    test('rejects invalid strings', () => {
      const controls = new PerformanceControls({submissionsChunkSize: 'invalid'})
      strictEqual(controls.submissionsChunkSize, defaultValue)
    })

    test('rejects null', () => {
      const controls = new PerformanceControls({submissionsChunkSize: null})
      strictEqual(controls.submissionsChunkSize, defaultValue)
    })

    test('rejects undefined', () => {
      const controls = new PerformanceControls({submissionsChunkSize: undefined})
      strictEqual(controls.submissionsChunkSize, defaultValue)
    })
  })

  QUnit.module('#submissionsPerPage', () => {
    const defaultValue = new PerformanceControls().apiMaxPerPage
    const minValue = 1

    test('is set to the given value', () => {
      const controls = new PerformanceControls({submissionsPerPage: 15})
      strictEqual(controls.submissionsPerPage, 15)
    })

    test(`defaults to ${defaultValue}`, () => {
      const controls = new PerformanceControls({})
      strictEqual(controls.submissionsPerPage, defaultValue)
    })

    test(`clips values higher than the apiMaxPerPage`, () => {
      const {apiMaxPerPage} = new PerformanceControls({})
      const controls = new PerformanceControls({submissionsPerPage: apiMaxPerPage + 1})
      strictEqual(controls.customColumnDataPerPage, apiMaxPerPage)
    })

    test(`clips values lower than ${minValue}`, () => {
      const controls = new PerformanceControls({submissionsPerPage: minValue - 1})
      strictEqual(controls.submissionsPerPage, minValue)
    })

    test('converts valid string numbers', () => {
      const controls = new PerformanceControls({submissionsPerPage: '24'})
      strictEqual(controls.submissionsPerPage, 24)
    })

    test('rejects invalid strings', () => {
      const controls = new PerformanceControls({submissionsPerPage: 'invalid'})
      strictEqual(controls.submissionsPerPage, defaultValue)
    })

    test('rejects null', () => {
      const controls = new PerformanceControls({submissionsPerPage: null})
      strictEqual(controls.submissionsPerPage, defaultValue)
    })

    test('rejects undefined', () => {
      const controls = new PerformanceControls({submissionsPerPage: undefined})
      strictEqual(controls.submissionsPerPage, defaultValue)
    })
  })
})
