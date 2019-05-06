/*
 * Copyright (C) 2019 - present Instructure, Inc.
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

/* eslint-disable mocha/no-global-tests, mocha/handle-done-callback */

import {Selector} from 'testcafe'

fixture`StatusBar`.page`./testcafe.html` //.beforeEach(addTestcafeTestingLibrary).page`./testcafe.html`

test('toggles between rce and html views', async t => {
  const textarea = Selector('#textarea')
  const rce = Selector('.tox-tinymce')
  const toggleButton = Selector('button').withText('</>')
  await t.expect(rce.visible).ok('rce should be initially visible')
  await t.expect(textarea.visible).notOk('textarea should be initially invisible')
  await t.click(toggleButton)
  await t.expect(rce.visible).notOk('rce should be invisible after toggle')
  await t.expect(textarea.visible).ok('textarea should be visible after toggle')
  await t.click(toggleButton)
  await t.expect(rce.visible).ok('rce should be visible after toggling again')
  await t.expect(textarea.visible).notOk('textarea should be hidden after toggling again')
})
