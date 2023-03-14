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

import {Selector, ClientFunction} from 'testcafe'
// eslint-disable-next-line babel/no-unused-expressions
fixture`RCEWrapper`.page`./testcafe.html`
const tinyIframe = Selector('#textarea_ifr')
const textArea = Selector('.RceHtmlEditor')
const rceContainer = Selector('.tox-tinymce')
const toggleButton = Selector('button').withText('</>')
const linksButton = Selector('[role="button"][aria-label="Links"] .tox-split-button__chevron')
const externalLinksMenuItem = Selector('[role^="menuitem"][title="External Links"]')
const courseLinksMenuItem = Selector('[role^="menuitem"][title="Course Links"]')
const editLinkMenuItem = Selector('[role^="menuitem"][title="Edit Link"]')
const removeLinkMenuItem = Selector('[role^="menuitem"][title="Remove Link"]')
const linkDialog = Selector('[data-testid="RCELinkOptionsDialog"]')
const linkTray = Selector('[data-testid="RCELinkOptionsTray"]')
const selectword = Selector('#selectword')
const linksTraySelector = '[role="dialog"][aria-label="Course Links"]'
const rceBody = Selector('#tinymce')
const linksPanelSelector = Selector('[data-testid="instructure_links-LinksPanel"]')

function named(name) {
  return Selector(`[name="${name}"]`)
}

function specificValue(value) {
  return Selector(`[value="${value}"]`)
}

test.skip('edits in the textarea are reflected in the editor', async t => {
  // const myText = ClientFunction(() => document.querySelector('#tinymce').innerText)
  await t
    .click(toggleButton)
    .typeText(textArea, 'this is new content')
    .click(toggleButton)
    .switchToIframe(tinyIframe)

  await t.expect(rceBody.withExactText('this is new content').visible).ok().switchToMainWindow()

  await t
    .click(toggleButton)
    .pressKey('end')
    .typeText(textArea, 'this is more content')
    .click(toggleButton)
    .switchToIframe(tinyIframe)
    .expect(Selector('body').find('p').withExactText('this is new content').visible)
    .ok()
    .expect(Selector('body').find('p').withExactText('this is more content').visible)
    .ok()
    .switchToMainWindow()
})

test.skip('shows the create links menu', async t => {
  await t
    .click(toggleButton)
    .typeText(textArea, '<div>this is <span id="selectword">selected</span> text</div>')
    .click(toggleButton)
    .expect(rceContainer.visible)
    .ok()

  await t
    .switchToIframe(tinyIframe)
    .selectEditableContent(selectword, selectword)
    .switchToMainWindow()
    .click(linksButton)
    .expect(externalLinksMenuItem.visible)
    .ok()
    .expect(courseLinksMenuItem.visible)
    .ok()
})

test.skip('shows the edit links menu', async t => {
  await t
    .click(toggleButton)
    .typeText(
      textArea,
      '<div>this is <a href="http://example.com"><span id="selectword">selected</span></a> text</div>'
    )
    .click(toggleButton)
    .expect(rceContainer.visible)
    .ok()

  await t
    .switchToIframe(tinyIframe)
    .selectEditableContent(selectword, selectword)
    .switchToMainWindow()
    .click(linksButton)
    .expect(editLinkMenuItem.visible)
    .ok()
    .expect(removeLinkMenuItem.visible)
    .ok()
})

test.skip('can create an external link', async t => {
  await t
    .click(toggleButton)
    .typeText(textArea, '<div>this is <span id="selectword">selected</span> text</div>')
    .click(toggleButton)
    .expect(rceContainer.visible)
    .ok()

  await t
    .switchToIframe(tinyIframe)
    .selectEditableContent(selectword, selectword)
    .switchToMainWindow()
    .click(linksButton)
    .click(externalLinksMenuItem)
    .expect(linkDialog.visible)
    .ok()
    .expect(named('linklink').visible)
    .ok()

  await t
    .typeText(named('linklink'), 'https://instructure.com')
    .click(Selector('button').withText('Done'))
    .switchToIframe(tinyIframe)
    .expect(
      Selector('a')
        .withAttribute('href', 'https://instructure.com')
        .withAttribute('target', '_blank').exists
    )
    .ok()
})

test.skip('can edit an external link', async t => {
  await t
    .click(toggleButton)
    .typeText(
      textArea,
      '<div>this is <a href="http://example.com"><span id="selectword">selected</span></a> text</div>'
    )
    .click(toggleButton)
    .expect(rceContainer.visible)
    .ok()

  await t
    .switchToIframe(tinyIframe)
    .selectEditableContent(selectword, selectword)
    .switchToMainWindow()

  // the link is selected, the toolbar button should be enabled
  // await t.expect(linksButton.hasClass('tox-tbtn--enabled')).ok()

  await t.click(linksButton).click(editLinkMenuItem).expect(linkTray.visible).ok()

  await t.expect(specificValue('http://example.com').exists).ok()
  await t.expect(specificValue('selected').exists).ok()
})

test.skip('expands selection to edit external link', async t => {
  await t
    .click(toggleButton)
    .typeText(
      textArea,
      '<div>this is <a href="http://example.com"><span id="selectword">selected</span></a> text</div>'
    )
    .click(toggleButton)
    .expect(rceContainer.visible)
    .ok()

  await t.switchToIframe(tinyIframe).click(selectword, {caretPos: 1}).switchToMainWindow()

  await t.click(linksButton).click(editLinkMenuItem).expect(linkTray.visible).ok()

  await t.expect(specificValue('http://example.com').exists).ok()
  await t.expect(specificValue('selected').exists).ok()
})

test.skip('can remove a link', async t => {
  await t
    .click(toggleButton)
    .typeText(
      textArea,
      '<div>this is <a href="http://example.com"><span id="selectword">selected</span></a> text</div>'
    )
    .click(toggleButton)
    .expect(rceContainer.visible)
    .ok()

  await t
    .switchToIframe(tinyIframe)
    .selectEditableContent(selectword, selectword)
    .switchToMainWindow()
    .click(linksButton)
    .click(removeLinkMenuItem)

  await t.switchToIframe(tinyIframe).expect(Selector('a').exists).notOk()
})

// fails at the React.lazy call to load the tray's panel
test.skip('focus returns on dismissing tray', async t => {
  const tinymceSelection = ClientFunction(() => tinymce.get('textarea').selection.getContent()) // the textarea id is from testcafe.html
  const focusedId = ClientFunction(() => document.activeElement.id)
  const focusedTag = ClientFunction(() => document.activeElement.tagName)
  const ltSelector = Selector(linksTraySelector)

  await t
    .click(toggleButton)
    .typeText(textArea, '<div>this is <span id="selectword">selected</span> text</div>')
    .click(toggleButton)
    .expect(rceContainer.visible)
    .ok()

  await t
    .switchToIframe(tinyIframe)
    .selectEditableContent(selectword, selectword)
    .switchToMainWindow()
    .click(linksButton)
    .click(courseLinksMenuItem)

  await linksPanelSelector()

  await t
    .expect(ltSelector.visible)
    .ok()
    .click(Selector(`${linksTraySelector} button`).withText('Close'))
    .expect(ltSelector.exist)
    .notOk()

  await t
    .expect(tinymceSelection())
    .eql('selected')
    .expect(focusedId())
    .eql('textarea_ifr')

    .switchToIframe(tinyIframe)
    .expect(focusedTag())
    .eql('BODY')
})

test.skip('show the kb shortcut modal various ways', async t => {
  const kbshortcutbutton = Selector('button[data-testid="ShowOnFocusButton__button"]')
  const sbKbshortcutbutton = Selector('button[title="View keyboard shortcuts"]')
  const shortcutmodal = Selector('[data-testid="RCE_KeyboardShortcutModal"]')
  const focusKBSCBtn = ClientFunction(() => kbshortcutbutton().focus(), {
    dependencies: {kbshortcutbutton},
  })
  const focusSBKBSCBtn = ClientFunction(() => sbKbshortcutbutton().focus(), {
    dependencies: {sbKbshortcutbutton},
  })

  await t.expect(kbshortcutbutton.exists).ok()

  await focusKBSCBtn()

  // open keyboard shortcut modal from the show-on-focus button
  // close with escape
  await t
    .expect(kbshortcutbutton.visible)
    .ok()
    .click(kbshortcutbutton)
    .expect(shortcutmodal.visible)
    .ok()
    .pressKey('esc')
    .expect(shortcutmodal.exists)
    .notOk()

  // open modal using alt+0
  // close with the close button
  // await t
  //   .switchToIframe(tinyIframe)
  //   .click(Selector('body'))
  //   .pressKey('alt+0')
  //   .expect(shortcutmodal.visible)
  //   .ok()
  //   .click(Selector('button').withText('Close'))
  //   .expect(shortcutmodal.exists)
  //   .notOk()

  // open modal from button in status bar
  // debugger;
  // close with the close button
  await focusSBKBSCBtn()

  await t
    .expect(sbKbshortcutbutton.exists)
    .ok()
    .click(sbKbshortcutbutton)
    .expect(shortcutmodal.visible)
    .ok()
    .click(Selector('button').withText('Close'))
    .expect(shortcutmodal.exists)
    .notOk()
})

// test.skip('can bring up the images dialog', async t => {
//   await t
//     .switchToMainWindow()
//     .click(imagesButton())
//     .click(uploadImageMenuItem())
//     .expect(uploadImageDialog().visible)
//     .ok()

// await t
//   .typeText(named('linklink'), 'https://instructure.com')
//   .click(Selector('button').withText('Done'))
//   .switchToIframe(tinyIframe)
//   .expect(
//     Selector('a')
//       .withAttribute('href', 'https://instructure.com')
//       .withAttribute('target', '_blank').exists
//   )
//   .ok()
// })
