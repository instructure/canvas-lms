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

import {Selector, ClientFunction} from 'testcafe'

fixture`RCEWrapper`.page`./testcafe.html`

const tinyIframe = Selector('.tox-edit-area__iframe')
const textarea = Selector('#textarea')
const rceContainer = Selector('.tox-tinymce')
const toggleButton = Selector('button').withText('</>')
const linksButton = Selector('button.tox-tbtn[title="Links"]')
const externalLinksMenuItem = Selector('[role="menuitem"]').withText("External Links")
const courseLinksMenuItem = Selector('[role="menuitem"]').withText("Course Links")
const editLinkMenuItem = Selector('[role="menuitem"]').withText("Edit Link")
const removeLinkMenuItem = Selector('[role="menuitem"]').withText("Remove Link")
const linkDialog = Selector('.tox-dialog__title').withText('Insert/Edit Link')
const selectword = Selector('#selectword')
const linksTraySelector = '[role="dialog"][aria-label="Course Links"]'

// given a DOM with
// <label for="someid">some label text</label><input id="someid"/>
// labeledBy("some label text") returns a Selector will find the input
function labeledBy(text) {
  return Selector(new Function(
    `
    const targetid = document.evaluate('//label[text()="${text}"]', document, null, XPathResult.FIRST_ORDERED_NODE_TYPE, null).singleNodeValue.getAttribute('for')
    return document.getElementById(targetid)
    `
  ))
}

test('edits in the textarea are reflected in the editor', async (t) => {
  await t
    .click(toggleButton)
    .typeText(textarea, 'this is new content')
    .click(toggleButton)
    .switchToIframe(tinyIframe)
    .expect(Selector('body').withText('this is new content').visible).ok()
    .switchToMainWindow()

  await t
    .click(toggleButton)
    .typeText(textarea, 'this is more content')
    .click(toggleButton)
    .switchToIframe(tinyIframe)
    .expect(Selector('body').withText('this is new content').visible).ok()
    .expect(Selector('body').withText('this is more content').visible).ok()
    .switchToMainWindow()
})

test('shows the create links menu', async t => {
  await t
    .click(toggleButton)
    .typeText(textarea, '<div>this is <span id="selectword">selected</span> text</div>')
    .click(toggleButton)
    .expect(rceContainer.visible).ok()

  await t
    .switchToIframe(tinyIframe)
    .selectEditableContent(selectword, selectword)
    .switchToMainWindow()
    .click(linksButton)
    .expect(externalLinksMenuItem.visible).ok()
    .expect(courseLinksMenuItem.visible).ok()
})

test('shows the edit links menu', async t => {
  await t
    .click(toggleButton)
    .typeText(textarea, '<div>this is <a href="http://example.com"><span id="selectword">selected</span></a> text</div>')
    .click(toggleButton)
    .expect(rceContainer.visible).ok()

  await t
    .switchToIframe(tinyIframe)
    .selectEditableContent(selectword, selectword)
    .switchToMainWindow()
    .click(linksButton)
    .expect(editLinkMenuItem.visible).ok()
    .expect(removeLinkMenuItem.visible).ok()
})

test('can create a link', async t => {
  await t
    .click(toggleButton)
    .typeText(textarea, '<div>this is <span id="selectword">selected</span> text</div>')
    .click(toggleButton)
    .expect(rceContainer.visible).ok()

  await t
    .switchToIframe(tinyIframe)
    .selectEditableContent(selectword, selectword)
    .switchToMainWindow()
    .click(linksButton)
    .click(externalLinksMenuItem)
    .expect(linkDialog.visible).ok()
    .expect(labeledBy('URL').visible).ok()

  await t
    .typeText(labeledBy('URL'), 'https://instructure.com')
    .click(Selector('button').withText('Save'))
    .switchToIframe(tinyIframe)
    .expect(Selector('a').withAttribute('href', 'https://instructure.com').withAttribute('target', '_blank').exists).ok()
})

test('can edit a link', async t => {
  await t
    .click(toggleButton)
    .typeText(textarea, '<div>this is <a href="http://example.com"><span id="selectword">selected</span></a> text</div>')
    .click(toggleButton)
    .expect(rceContainer.visible).ok()

  await t
    .switchToIframe(tinyIframe)
    .selectEditableContent(selectword, selectword)
    .switchToMainWindow()

  // the link is selected, the toolbar button should be enabled
  await t.expect(linksButton.hasClass('tox-tbtn--enabled')).ok()

  await t
    .click(linksButton)
    .click(editLinkMenuItem)
    .expect(linkDialog.visible).ok()

    await t.expect(labeledBy('URL').value).eql('http://example.com')
    await t.expect(labeledBy('Text to display').value).eql('selected')
})

test('can remove a link', async t => {
  await t
    .click(toggleButton)
    .typeText(textarea, '<div>this is <a href="http://example.com"><span id="selectword">selected</span></a> text</div>')
    .click(toggleButton)
    .expect(rceContainer.visible).ok()

  await t
    .switchToIframe(tinyIframe)
    .selectEditableContent(selectword, selectword)
    .switchToMainWindow()
    .click(linksButton)
    .click(removeLinkMenuItem)

  await t
    .switchToIframe(tinyIframe)
    .expect(Selector('a').exists).notOk()
})

test('focus returns on dismissing tray', async t => {
  const tinymceSelection = ClientFunction(() => tinymce.get('textarea').selection.getContent()) // the textarea id is from testcafe.html
  const focusedId = ClientFunction(() => document.activeElement.id)
  const focusedTag = ClientFunction(() => document.activeElement.tagName)

  await t
    .click(toggleButton)
    .typeText(textarea, '<div>this is <span id="selectword">selected</span> text</div>')
    .click(toggleButton)
    .expect(rceContainer.visible).ok()

  await t
    .switchToIframe(tinyIframe)
    .selectEditableContent(selectword, selectword)
    .switchToMainWindow()
    .click(linksButton)
    .click(courseLinksMenuItem)
    .expect(Selector(linksTraySelector).visible).ok()
    .click(Selector(`${linksTraySelector} button`).withText('Close'))
    .expect(Selector(linksTraySelector).exist).notOk()

  await t
    .expect(tinymceSelection()).eql('selected')
    .expect(focusedId()).eql('textarea_ifr')

    .switchToIframe(tinyIframe)
    .expect(focusedTag()).eql('BODY')
})

test('show the kb shortcut modal various ways', async t => {
  const hiddenbutton = Selector('[data-testid="ShowOnFocusButton__sronly"]')
  const kbshortcutbutton = Selector('button[data-testid="ShowOnFocusButton__button"]')
  const shortcutmodal = Selector('[data-testid="RCE_KeyboardShortcutModal"]')
  const focusKBSCBtn = ClientFunction(
    () => kbshortcutbutton().focus(),
    {dependencies: {kbshortcutbutton}}
  )

  await t
    .expect(hiddenbutton.exists).ok()
    .expect(kbshortcutbutton.exists).ok()

  await focusKBSCBtn()

  // open keyboard shortcut modal from the show-on-focus button
  // close with escape
  await t
    .expect(hiddenbutton.exists).notOk()
    .expect(kbshortcutbutton.visible).ok()
    .click(kbshortcutbutton)
    .expect(shortcutmodal.visible).ok()
    .pressKey('esc')
    .expect(shortcutmodal.exists).notOk()

  // open modal using alt+0
  // close with the close button
  await t
    .pressKey('alt+0')
    .expect(shortcutmodal.visible).ok()
    .click(Selector('button').withText('Close'))
    .expect(shortcutmodal.exists).notOk()

  // open modal from button in status bar
  await t
    .click(Selector('[data-testid="RCEStatusBar"] button').withText('View keyboard shortcuts'))
    .expect(shortcutmodal.visible).ok()
})

test('editor auto-resizes as content is added', async t => {
  const paramargin = 12
  const fontSize = 16
  const height = await rceContainer.clientHeight
  const parasFitInRce = Math.floor(height / (fontSize + paramargin))
  let content = ''
  // add 1 too many
  for (let i = 0; i <= parasFitInRce; ++i) {
    content += '<p>para</p>'
  }

  await t
    .click(toggleButton)
    .typeText(textarea, content)
    .click(toggleButton)
    .switchToMainWindow()

  const newHeight = await rceContainer.clientHeight
  await t
    .expect(newHeight > height).ok()
})
