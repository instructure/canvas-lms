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

    await t.expect(labeledBy('URL').visible).ok()
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
