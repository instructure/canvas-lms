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
  let finalGradeOverride

  hooks.beforeEach(() => {
    App = startApp()
    finalGradeOverride = {
      percentage: 92.32,
    }
    const gradingStandard = [
      ['A', 0.9],
      ['B', 0.8],
      ['C', 0.0],
    ]
    component = App.FinalGradeOverrideComponent.create({finalGradeOverride, gradingStandard})
  })

  test('inputValue returns the override grade', () => {
    strictEqual(component.get('inputValue'), 'A')
  })

  test('inputValue returns the percentage when grading schemes are not enabled', () => {
    component.set('gradingStandard', undefined)
    strictEqual(component.get('inputValue'), '92.32%')
  })

  test('inputDescription returns a formatted percentage', () => {
    strictEqual(component.get('inputDescription'), '92.32%')
  })

  test('inputDescription returns null when grading schemes are not enabled', () => {
    component.set('gradingStandard', undefined)
    strictEqual(component.get('inputDescription'), null)
  })

  test('changing the override percentage changes the inputValue', () => {
    finalGradeOverride.percentage = 86.7
    component.set('finalGradeOverride', {...finalGradeOverride})
    strictEqual(component.get('inputValue'), 'B')
  })

  test('changing the override percentage changes the inputDescription', () => {
    finalGradeOverride.percentage = 86.7
    strictEqual(component.get('inputDescription'), '86.7%')
  })

  test('changing the grading standard changes the inputValue', () => {
    const gradingStandard = [
      ['A', 0.99],
      ['F', 0.0],
    ]
    component.set('gradingStandard', gradingStandard)
    strictEqual(component.get('inputValue'), 'F')
  })

  test('focusOut sends onEditFinalGradeOverride with the inputValue', () => {
    const targetObject = {
      onEditFinalGradeOverride(grade) {
        strictEqual(grade, 92.1)
      },
    }

    component.set('onEditFinalGradeOverride', 'onEditFinalGradeOverride')
    component.set('targetObject', targetObject)
    component.set('inputValue', 92.1)
    component.focusOut()
  })

  test('focusOut sets the inputValue to the internalInputValue', () => {
    component.set('internalInputValue', 'C')
    component.focusOut()
    strictEqual(component.get('inputValue'), 'C')
  })
})
