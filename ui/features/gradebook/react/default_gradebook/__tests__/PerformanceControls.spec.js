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

import PerformanceControls from '../PerformanceControls'

describe('Gradebook > PerformanceControls', () => {
  describe('#activeRequestLimit', () => {
    const defaultValue = 12
    const maxValue = 100
    const minValue = 1

    test('is set to the given value', () => {
      const controls = new PerformanceControls({activeRequestLimit: 15})
      expect(controls.activeRequestLimit).toBe(15)
    })

    test(`defaults to ${defaultValue}`, () => {
      const controls = new PerformanceControls({})
      expect(controls.activeRequestLimit).toBe(defaultValue)
    })

    test(`clips values higher than ${maxValue}`, () => {
      const controls = new PerformanceControls({activeRequestLimit: maxValue + 1})
      expect(controls.activeRequestLimit).toBe(maxValue)
    })

    test(`clips values lower than ${minValue}`, () => {
      const controls = new PerformanceControls({activeRequestLimit: minValue - 1})
      expect(controls.activeRequestLimit).toBe(minValue)
    })

    test('converts valid string numbers', () => {
      const controls = new PerformanceControls({activeRequestLimit: '24'})
      expect(controls.activeRequestLimit).toBe(24)
    })

    test('rejects invalid strings', () => {
      const controls = new PerformanceControls({activeRequestLimit: 'invalid'})
      expect(controls.activeRequestLimit).toBe(defaultValue)
    })

    test('rejects null', () => {
      const controls = new PerformanceControls({activeRequestLimit: null})
      expect(controls.activeRequestLimit).toBe(defaultValue)
    })

    test('rejects undefined', () => {
      const controls = new PerformanceControls({activeRequestLimit: undefined})
      expect(controls.activeRequestLimit).toBe(defaultValue)
    })
  })

  describe('#apiMaxPerPage', () => {
    const defaultValue = 100
    const maxValue = 500
    const minValue = 1

    test('is set to the given value', () => {
      const controls = new PerformanceControls({apiMaxPerPage: 15})
      expect(controls.apiMaxPerPage).toBe(15)
    })

    test(`defaults to ${defaultValue}`, () => {
      const controls = new PerformanceControls({})
      expect(controls.apiMaxPerPage).toBe(defaultValue)
    })

    test(`clips values higher than ${maxValue}`, () => {
      const controls = new PerformanceControls({apiMaxPerPage: maxValue + 1})
      expect(controls.apiMaxPerPage).toBe(maxValue)
    })

    test(`clips values lower than ${minValue}`, () => {
      const controls = new PerformanceControls({apiMaxPerPage: minValue - 1})
      expect(controls.apiMaxPerPage).toBe(minValue)
    })

    test('converts valid string numbers', () => {
      const controls = new PerformanceControls({apiMaxPerPage: '24'})
      expect(controls.apiMaxPerPage).toBe(24)
    })

    test('rejects invalid strings', () => {
      const controls = new PerformanceControls({apiMaxPerPage: 'invalid'})
      expect(controls.apiMaxPerPage).toBe(defaultValue)
    })

    test('rejects null', () => {
      const controls = new PerformanceControls({apiMaxPerPage: null})
      expect(controls.apiMaxPerPage).toBe(defaultValue)
    })

    test('rejects undefined', () => {
      const controls = new PerformanceControls({apiMaxPerPage: undefined})
      expect(controls.apiMaxPerPage).toBe(defaultValue)
    })
  })

  describe('#assignmentGroupsPerPage', () => {
    const defaultValue = 100
    const minValue = 1

    test('is set to the given value', () => {
      const controls = new PerformanceControls({assignmentGroupsPerPage: 15})
      expect(controls.assignmentGroupsPerPage).toBe(15)
    })

    test(`defaults to ${defaultValue}`, () => {
      const controls = new PerformanceControls({})
      expect(controls.assignmentGroupsPerPage).toBe(defaultValue)
    })

    test(`clips values higher than the apiMaxPerPage`, () => {
      const {apiMaxPerPage} = new PerformanceControls({})
      const controls = new PerformanceControls({assignmentGroupsPerPage: apiMaxPerPage + 1})
      expect(controls.assignmentGroupsPerPage).toBe(apiMaxPerPage)
    })

    test(`clips values lower than ${minValue}`, () => {
      const controls = new PerformanceControls({assignmentGroupsPerPage: minValue - 1})
      expect(controls.assignmentGroupsPerPage).toBe(minValue)
    })

    test('converts valid string numbers', () => {
      const controls = new PerformanceControls({assignmentGroupsPerPage: '24'})
      expect(controls.assignmentGroupsPerPage).toBe(24)
    })

    test('rejects invalid strings', () => {
      const controls = new PerformanceControls({assignmentGroupsPerPage: 'invalid'})
      expect(controls.assignmentGroupsPerPage).toBe(defaultValue)
    })

    test('rejects null', () => {
      const controls = new PerformanceControls({assignmentGroupsPerPage: null})
      expect(controls.assignmentGroupsPerPage).toBe(defaultValue)
    })

    test('rejects undefined', () => {
      const controls = new PerformanceControls({assignmentGroupsPerPage: undefined})
      expect(controls.assignmentGroupsPerPage).toBe(defaultValue)
    })
  })

  describe('#contextModulesPerPage', () => {
    const defaultValue = 100
    const minValue = 1

    test('is set to the given value', () => {
      const controls = new PerformanceControls({contextModulesPerPage: 15})
      expect(controls.contextModulesPerPage).toBe(15)
    })

    test(`defaults to ${defaultValue}`, () => {
      const controls = new PerformanceControls({})
      expect(controls.contextModulesPerPage).toBe(defaultValue)
    })

    test(`clips values higher than the apiMaxPerPage`, () => {
      const {apiMaxPerPage} = new PerformanceControls({})
      const controls = new PerformanceControls({contextModulesPerPage: apiMaxPerPage + 1})
      expect(controls.contextModulesPerPage).toBe(apiMaxPerPage)
    })

    test(`clips values lower than ${minValue}`, () => {
      const controls = new PerformanceControls({contextModulesPerPage: minValue - 1})
      expect(controls.contextModulesPerPage).toBe(minValue)
    })

    test('converts valid string numbers', () => {
      const controls = new PerformanceControls({contextModulesPerPage: '24'})
      expect(controls.contextModulesPerPage).toBe(24)
    })

    test('rejects invalid strings', () => {
      const controls = new PerformanceControls({contextModulesPerPage: 'invalid'})
      expect(controls.contextModulesPerPage).toBe(defaultValue)
    })

    test('rejects null', () => {
      const controls = new PerformanceControls({contextModulesPerPage: null})
      expect(controls.contextModulesPerPage).toBe(defaultValue)
    })

    test('rejects undefined', () => {
      const controls = new PerformanceControls({contextModulesPerPage: undefined})
      expect(controls.contextModulesPerPage).toBe(defaultValue)
    })
  })

  describe('#customColumnDataPerPage', () => {
    const defaultValue = 100
    const minValue = 1

    test('is set to the given value', () => {
      const controls = new PerformanceControls({customColumnDataPerPage: 15})
      expect(controls.customColumnDataPerPage).toBe(15)
    })

    test(`defaults to ${defaultValue}`, () => {
      const controls = new PerformanceControls({})
      expect(controls.customColumnDataPerPage).toBe(defaultValue)
    })

    test(`clips values higher than the apiMaxPerPage`, () => {
      const {apiMaxPerPage} = new PerformanceControls({})
      const controls = new PerformanceControls({customColumnDataPerPage: apiMaxPerPage + 1})
      expect(controls.customColumnDataPerPage).toBe(apiMaxPerPage)
    })

    test(`clips values lower than ${minValue}`, () => {
      const controls = new PerformanceControls({customColumnDataPerPage: minValue - 1})
      expect(controls.customColumnDataPerPage).toBe(minValue)
    })

    test('converts valid string numbers', () => {
      const controls = new PerformanceControls({customColumnDataPerPage: '24'})
      expect(controls.customColumnDataPerPage).toBe(24)
    })

    test('rejects invalid strings', () => {
      const controls = new PerformanceControls({customColumnDataPerPage: 'invalid'})
      expect(controls.customColumnDataPerPage).toBe(defaultValue)
    })

    test('rejects null', () => {
      const controls = new PerformanceControls({customColumnDataPerPage: null})
      expect(controls.customColumnDataPerPage).toBe(defaultValue)
    })

    test('rejects undefined', () => {
      const controls = new PerformanceControls({customColumnDataPerPage: undefined})
      expect(controls.customColumnDataPerPage).toBe(defaultValue)
    })
  })

  describe('#customColumnsPerPage', () => {
    const defaultValue = 100
    const minValue = 1

    test('is set to the given value', () => {
      const controls = new PerformanceControls({customColumnsPerPage: 15})
      expect(controls.customColumnsPerPage).toBe(15)
    })

    test(`defaults to ${defaultValue}`, () => {
      const controls = new PerformanceControls({})
      expect(controls.customColumnsPerPage).toBe(defaultValue)
    })

    test(`clips values higher than the apiMaxPerPage`, () => {
      const {apiMaxPerPage} = new PerformanceControls({})
      const controls = new PerformanceControls({customColumnsPerPage: apiMaxPerPage + 1})
      expect(controls.customColumnsPerPage).toBe(apiMaxPerPage)
    })

    test(`clips values lower than ${minValue}`, () => {
      const controls = new PerformanceControls({customColumnsPerPage: minValue - 1})
      expect(controls.customColumnsPerPage).toBe(minValue)
    })

    test('converts valid string numbers', () => {
      const controls = new PerformanceControls({customColumnsPerPage: '24'})
      expect(controls.customColumnsPerPage).toBe(24)
    })

    test('rejects invalid strings', () => {
      const controls = new PerformanceControls({customColumnsPerPage: 'invalid'})
      expect(controls.customColumnsPerPage).toBe(defaultValue)
    })

    test('rejects null', () => {
      const controls = new PerformanceControls({customColumnsPerPage: null})
      expect(controls.customColumnsPerPage).toBe(defaultValue)
    })

    test('rejects undefined', () => {
      const controls = new PerformanceControls({customColumnsPerPage: undefined})
      expect(controls.customColumnsPerPage).toBe(defaultValue)
    })
  })

  describe('#studentsChunkSize', () => {
    const defaultValue = 100
    const minValue = 1

    test('is set to the given value', () => {
      const controls = new PerformanceControls({studentsChunkSize: 15})
      expect(controls.studentsChunkSize).toBe(15)
    })

    test(`defaults to ${defaultValue}`, () => {
      const controls = new PerformanceControls({})
      expect(controls.studentsChunkSize).toBe(defaultValue)
    })

    test(`clips values higher than the apiMaxPerPage`, () => {
      const {apiMaxPerPage} = new PerformanceControls({})
      const controls = new PerformanceControls({studentsChunkSize: apiMaxPerPage + 1})
      expect(controls.customColumnDataPerPage).toBe(apiMaxPerPage)
    })

    test(`clips values lower than ${minValue}`, () => {
      const controls = new PerformanceControls({studentsChunkSize: minValue - 1})
      expect(controls.studentsChunkSize).toBe(minValue)
    })

    test('converts valid string numbers', () => {
      const controls = new PerformanceControls({studentsChunkSize: '24'})
      expect(controls.studentsChunkSize).toBe(24)
    })

    test('rejects invalid strings', () => {
      const controls = new PerformanceControls({studentsChunkSize: 'invalid'})
      expect(controls.studentsChunkSize).toBe(defaultValue)
    })

    test('rejects null', () => {
      const controls = new PerformanceControls({studentsChunkSize: null})
      expect(controls.studentsChunkSize).toBe(defaultValue)
    })

    test('rejects undefined', () => {
      const controls = new PerformanceControls({studentsChunkSize: undefined})
      expect(controls.studentsChunkSize).toBe(defaultValue)
    })
  })

  describe('#submissionsChunkSize', () => {
    const defaultValue = 10
    const minValue = 1

    test('is set to the given value', () => {
      const controls = new PerformanceControls({submissionsChunkSize: 15})
      expect(controls.submissionsChunkSize).toBe(15)
    })

    test(`defaults to ${defaultValue}`, () => {
      const controls = new PerformanceControls({})
      expect(controls.submissionsChunkSize).toBe(defaultValue)
    })

    test(`clips values higher than the apiMaxPerPage`, () => {
      const {apiMaxPerPage} = new PerformanceControls({})
      const controls = new PerformanceControls({submissionsChunkSize: apiMaxPerPage + 1})
      expect(controls.customColumnDataPerPage).toBe(apiMaxPerPage)
    })

    test(`clips values lower than ${minValue}`, () => {
      const controls = new PerformanceControls({submissionsChunkSize: minValue - 1})
      expect(controls.submissionsChunkSize).toBe(minValue)
    })

    test('converts valid string numbers', () => {
      const controls = new PerformanceControls({submissionsChunkSize: '24'})
      expect(controls.submissionsChunkSize).toBe(24)
    })

    test('rejects invalid strings', () => {
      const controls = new PerformanceControls({submissionsChunkSize: 'invalid'})
      expect(controls.submissionsChunkSize).toBe(defaultValue)
    })

    test('rejects null', () => {
      const controls = new PerformanceControls({submissionsChunkSize: null})
      expect(controls.submissionsChunkSize).toBe(defaultValue)
    })

    test('rejects undefined', () => {
      const controls = new PerformanceControls({submissionsChunkSize: undefined})
      expect(controls.submissionsChunkSize).toBe(defaultValue)
    })
  })

  describe('#submissionsPerPage', () => {
    const defaultValue = new PerformanceControls().apiMaxPerPage
    const minValue = 1

    test('is set to the given value', () => {
      const controls = new PerformanceControls({submissionsPerPage: 15})
      expect(controls.submissionsPerPage).toBe(15)
    })

    test(`defaults to ${defaultValue}`, () => {
      const controls = new PerformanceControls({})
      expect(controls.submissionsPerPage).toBe(defaultValue)
    })

    test(`clips values higher than the apiMaxPerPage`, () => {
      const {apiMaxPerPage} = new PerformanceControls({})
      const controls = new PerformanceControls({submissionsPerPage: apiMaxPerPage + 1})
      expect(controls.customColumnDataPerPage).toBe(apiMaxPerPage)
    })

    test(`clips values lower than ${minValue}`, () => {
      const controls = new PerformanceControls({submissionsPerPage: minValue - 1})
      expect(controls.submissionsPerPage).toBe(minValue)
    })

    test('converts valid string numbers', () => {
      const controls = new PerformanceControls({submissionsPerPage: '24'})
      expect(controls.submissionsPerPage).toBe(24)
    })

    test('rejects invalid strings', () => {
      const controls = new PerformanceControls({submissionsPerPage: 'invalid'})
      expect(controls.submissionsPerPage).toBe(defaultValue)
    })

    test('rejects null', () => {
      const controls = new PerformanceControls({submissionsPerPage: null})
      expect(controls.submissionsPerPage).toBe(defaultValue)
    })

    test('rejects undefined', () => {
      const controls = new PerformanceControls({submissionsPerPage: undefined})
      expect(controls.submissionsPerPage).toBe(defaultValue)
    })
  })
})
