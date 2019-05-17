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

fixture`StatusBar`.page`./testcafe.html`

const tinyIframe = Selector('.tox-edit-area__iframe')

test('toggles between rce and html views', async t => {
  const textarea = Selector('#textarea')
  const rceContainer = Selector('.tox-tinymce')
  const toggleButton = Selector('button').withText('</>')
  const wordCount = Selector('span').withText('0 words').nth(-1)
  await t.expect(rceContainer.visible).ok('rce should be initially visible')
  await t.expect(wordCount.count).eql(1)
  await t.expect(textarea.visible).notOk('textarea should be initially invisible')
  await t.click(toggleButton)
  await t.expect(rceContainer.visible).notOk('rce should be invisible after toggle')
  await t.expect(wordCount.count).eql(0)
  await t.expect(textarea.visible).ok('textarea should be visible after toggle')
  await t.click(toggleButton)
  await t.expect(rceContainer.visible).ok('rce should be visible after toggling again')
  await t.expect(wordCount.count).eql(1)
  await t.expect(textarea.visible).notOk('textarea should be hidden after toggling again')
})

test('counts words', async t => {
  // search for the exact text for the selector will wait for it to change to this text
  await t.expect(Selector('span').withText('0 words')).exists

  await t.switchToIframe(tinyIframe).typeText('body', 'foo')
  await t
    .switchToMainWindow()
    .expect(Selector('span').withText('1 word').exists)
    .ok()

  await t.switchToIframe(tinyIframe).typeText('body', ' bar baz bing')
  await t
    .switchToMainWindow()
    .expect(Selector('span').withText('4 words').exists)
    .ok()
})

test('displays the current html path', async t => {
  await t.switchToIframe(tinyIframe).typeText('body', 'foo ')
  await t.expect(Selector('span').withText(/p.*strong.*em/).exists).notOk()
  await t.switchToMainWindow().click(Selector('button[title="Bold"]'))
  await t.switchToIframe(tinyIframe).typeText('body', 'bar ')
  await t.switchToMainWindow().click(Selector('button[title="Italic"]'))
  await t.switchToIframe(tinyIframe).typeText('body', 'baz ')
  await t
    .switchToMainWindow()
    .expect(Selector('span').withText(/p.*strong.*em/).exists)
    .ok()
})
