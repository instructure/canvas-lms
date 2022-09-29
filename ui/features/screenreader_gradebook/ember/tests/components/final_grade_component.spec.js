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

QUnit.module('FinalGradeComponent', hooks => {
  let App
  let component

  hooks.beforeEach(() => {
    App = startApp()
    component = App.FinalGradeComponent.create({})
  })

  test('bubbles up an onEditFinalGradeOverride action with the grade', () => {
    const targetObject = {
      onEditFinalGradeOverride(grade) {
        strictEqual(grade, '93%')
      },
    }

    component.set('onEditFinalGradeOverride', 'onEditFinalGradeOverride')
    component.set('targetObject', targetObject)
    component.send('onEditFinalGradeOverride', '93%')
  })
})
