//
// Copyright (C) 2018 - present Instructure, Inc.
//
// This file is part of Canvas.
//
// Canvas is free software: you can redistribute it and/or modify it under
// the terms of the GNU Affero General Public License as published by the Free
// Software Foundation, version 3 of the License.
//
// Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
// A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
// details.
//
// You should have received a copy of the GNU Affero General Public License along
// with this program. If not, see <http://www.gnu.org/licenses/>.

import startApp from '../start_app'

QUnit.module('FinalGradeOverrideComponent', hooks => {
  let App
  let component
  let finalGradeOverrides

  hooks.beforeEach(() => {
    App = startApp()
    finalGradeOverrides = {
      percentage: 92.32
    }
    const gradingStandard = [['A', 0.90], ['B', 0.80], ['C', 0.0]]
    component = App.FinalGradeOverrideComponent.create({finalGradeOverrides, gradingStandard})
  })

  test('overrideGrade returns the override grade', () => {
    strictEqual(component.get('overrideGrade'), 'A')
  })

  test('overrideGrade returns the percentage when grading schemes are not enabled', () => {
    component.set('gradingStandard', undefined)
    strictEqual(component.get('overrideGrade'), '92.32%')
  })

  test('overridePercent returns a formatted percentage', () => {
    strictEqual(component.get('overridePercent'), '92.32%')
  })

  test('overridePercent returns null when grading schemes are not enabled', () => {
    component.set('gradingStandard', undefined)
    strictEqual(component.get('overridePercent'), null)
  })

  test('changing the override percentage changes the overrideGrade', () => {
    finalGradeOverrides.percentage = 86.7
    strictEqual(component.get('overrideGrade'), 'B')
  })

  test('changing the override percentage changes the overridePercent', () => {
    finalGradeOverrides.percentage = 86.7
    strictEqual(component.get('overridePercent'), '86.7%')
  })
})
