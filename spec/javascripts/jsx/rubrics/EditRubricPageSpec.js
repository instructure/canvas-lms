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

import EditRubricPage from 'compiled/views/rubrics/EditRubricPage'
import assertions from 'helpers/assertions'

QUnit.module('RubricEdit');

test('should be accessible', (assert) => {
  const view = new EditRubricPage()
  const done = assert.async()
  assertions.isAccessible(view, done, {'a11yReport': true})
});

test('does not immediately create the dialog', () => {
  const clickSpy = sinon.spy(EditRubricPage.prototype, 'attachInitialEvent')
  const dialogSpy = sinon.spy(EditRubricPage.prototype, 'createDialog')

  new EditRubricPage();

  ok(clickSpy.called, 'sets up the initial click event')
  ok(dialogSpy.notCalled, 'does not immediately create the dialog')
  clickSpy.restore()
  dialogSpy.restore()
});
