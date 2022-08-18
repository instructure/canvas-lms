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

import {Selector} from 'testcafe'
// eslint-disable-next-line babel/no-unused-expressions
fixture`StatusBar`.page`./testcafe.html`

const tinyIframe = Selector('#textarea_ifr')
const application = Selector('.tox-tinymce[role="document"]')
const textArea = Selector('.RceHtmlEditor')
const statusPath = Selector('[data-testid="whole-status-bar-path"]')
const wordCount = Selector('[data-testid="status-bar-word-count"]')
const toggleButton = Selector('button').withText('</>')
const dragHandle = Selector('[name="IconDragHandle"]')

test.skip('toggles between rce and html views', async t => {
  const rceContainer = Selector('.tox-tinymce')
  const keyboardButton = Selector('button[title="View keyboard shortcuts"]')
  const a11yButton = Selector('button[title="Accessibility Checker"]')
  await t.expect(rceContainer.visible).ok('rce should be initially visible')
  // initially empty, so it's not visible, but we just care that it exists
  await t.expect(statusPath.exists).ok('rich content path should be visible')
  await t.expect(keyboardButton.visible).ok('keyboard button should be visible')
  await t.expect(a11yButton.visible).ok('a11yButton button should be visible')
  await t.expect(wordCount.visible).ok('word count should be visible')
  await t.expect(textArea.visible).notOk('textarea should be initially invisible')
  await t.click(toggleButton)
  await t.expect(rceContainer.visible).notOk('rce should be invisible after toggle')
  await t.expect(textArea.visible).ok('textarea should be visible after toggle')
  await t.expect(statusPath.count).eql(0)
  await t.expect(wordCount.count).eql(0)
  await t.expect(keyboardButton.count).eql(0)
  await t.expect(a11yButton.count).eql(0)
  await t.expect(dragHandle.visible).ok('drag handle should still be visible')
  await t.click(toggleButton)
  await t.expect(rceContainer.visible).ok('rce should be visible after toggling again')
  await t.expect(statusPath.visible).ok('rich content path should be visible again')
  await t.expect(keyboardButton.visible).ok('keyboard button should be visible again')
  await t.expect(a11yButton.visible).ok('a11yButton button should be visible again')
  await t.expect(wordCount.visible).ok('word count should be visible again')
  await t.expect(textArea.visible).notOk('textarea should be hidden after toggling again')
})

test.skip('counts words', async t => {
  // search for the exact text for the selector will wait for it to change to this text
  await t.expect(wordCount.withText('0 words').exists).ok()

  await t.switchToIframe(tinyIframe).typeText('body', 'foo')
  await t.switchToMainWindow().expect(wordCount.withText('1 word').exists).ok()

  await t.switchToIframe(tinyIframe).typeText('body', ' bar baz bing')
  await t.switchToMainWindow().expect(Selector('span').withText('4 words').exists).ok()
})

test.skip('displays the current html path', async t => {
  await t.switchToIframe(tinyIframe).typeText('body', 'foo ')
  await t.expect(Selector(statusPath).withText(/p.*strong.*em/).exists).notOk()
  await t.switchToMainWindow().click(Selector('button[title="Bold"]'))
  await t.switchToIframe(tinyIframe).typeText('body', 'bar ')
  await t.switchToMainWindow().click(Selector('button[title="Italic"]'))
  await t.switchToIframe(tinyIframe).typeText('body', 'baz ')
  await t
    .switchToMainWindow()
    .expect(statusPath.withText(/p.*strong.*em/).exists)
    .ok()
})
// these 2 tests fail in headless
test.skip('drag handle resizes the editor', async t => {
  const initialSize = await tinyIframe.boundingClientRect
  await t.drag(dragHandle, -100, 400)
  let finalSize = await tinyIframe.boundingClientRect
  await t.expect(finalSize.height).eql(initialSize.height + 400)
  await t.expect(finalSize.width).eql(initialSize.width)
  await t.drag(dragHandle, -100, -300)
  finalSize = await tinyIframe.boundingClientRect
  await t.expect(finalSize.height).eql(initialSize.height + 100)
  await t.expect(finalSize.width).eql(initialSize.width)
})

test.skip('drag handle in rce mode also resizes the textarea', async t => {
  await t.drag(dragHandle, 0, 400)
  const applicationHeight = await application.getStyleProperty('height')
  await t.click(toggleButton)
  const textareaHeight = await textArea.getStyleProperty('height')
  await t.expect(textareaHeight).eql(applicationHeight)
})

test.skip('drag handle in textarea mode also resizes the rce', async t => {
  await t.click(toggleButton).drag(dragHandle, 0, 400)
  const textareaHeight = await textArea.getStyleProperty('height')
  await t.click(toggleButton)
  const rceHeight = await application.getStyleProperty('height')
  await t.expect(rceHeight).eql(textareaHeight)
})
