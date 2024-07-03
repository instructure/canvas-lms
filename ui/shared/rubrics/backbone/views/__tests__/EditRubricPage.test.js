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

import EditRubricPage from '../EditRubricPage'
import {isAccessible} from '@canvas/test-utils/jestAssertions'
import sinon from 'sinon'

describe('RubricEdit', () => {
  test('should be accessible', done => {
    const view = new EditRubricPage()
    isAccessible(view, done, {a11yReport: true})
  })

  test('does not immediately create the dialog', () => {
    const clickSpy = sinon.spy(EditRubricPage.prototype, 'attachInitialEvent')
    const dialogSpy = sinon.spy(EditRubricPage.prototype, 'createDialog')

    new EditRubricPage()

    // 'sets up the initial click event'
    expect(clickSpy.called).toBeTruthy()

    // 'does not immediately create the dialog'
    expect(dialogSpy.notCalled).toBeTruthy()
    clickSpy.restore()
    dialogSpy.restore()
  })
})
