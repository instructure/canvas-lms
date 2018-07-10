/*
 * Copyright (C) 2018 - present Instructure, Inc.
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

import React from 'react'
import {mount, ReactWrapper} from 'enzyme'
import SpeedGraderSettingsMenu from 'jsx/speed_grader/SpeedGraderSettingsMenu'

QUnit.module('SpeedGraderSettingsMenu', hooks => {
  let $container
  let $menuContent
  let props
  let qunitTimeout
  let resolveOpen
  let wrapper

  hooks.beforeEach(() => {
    qunitTimeout = QUnit.config.testTimeout
    QUnit.config.testTimeout = 500 // protect against unresolved async mistakes
    props = {
      assignmentID: '71',
      courseID: '8',
      helpURL: 'example.com/support',
      menuContentRef(ref) {
        $menuContent = ref
      },
      onMenuShow() {
        resolveOpen()
      },
      openOptionsModal() {},
      openKeyboardShortcutsModal() {},
      showHelpMenuItem: false,
      showModerationMenuItem: false
    }

    $container = document.createElement('div')
    document.body.appendChild($container)
    sinon.stub(SpeedGraderSettingsMenu, 'setURL')
    sinon.stub(window, 'open')
  })

  hooks.afterEach(() => {
    window.open.restore()
    SpeedGraderSettingsMenu.setURL.restore()
    $container.remove()
    QUnit.config.testTimeout = qunitTimeout
  })

  function mountComponent() {
    wrapper = mount(<SpeedGraderSettingsMenu {...props} />, {appendTo: $container})
  }

  function clickToOpenMenu() {
    return new Promise(resolve => {
      resolveOpen = resolve
      wrapper.find('button').simulate('click')
    })
  }

  function getMenuItem(text) {
    const options = new ReactWrapper(
      [...$menuContent.querySelectorAll('[role="menuitem"]')],
      $menuContent
    )
    return options.filterWhere(option => option.text() === text).at(0)
  }

  test('includes an "Options" menu item', () => {
    mountComponent()
    return clickToOpenMenu().then(() => {
      const menuItem = getMenuItem('Options')
      strictEqual(menuItem.length, 1)
    })
  })

  test('calls the openOptionsModal prop when "Options" is clicked', () => {
    props.openOptionsModal = sinon.stub()
    mountComponent()
    return clickToOpenMenu().then(() => {
      const menuItem = getMenuItem('Options')
      menuItem.simulate('click')
      strictEqual(props.openOptionsModal.callCount, 1)
    })
  })

  test('includes a "Keyboard Shortcuts" menu item', () => {
    mountComponent()
    return clickToOpenMenu().then(() => {
      const menuItem = getMenuItem('Keyboard Shortcuts')
      strictEqual(menuItem.length, 1)
    })
  })

  test('calls the openKeyboardShortcutsModal prop when "Keyboard Shortcuts" is clicked', () => {
    props.openKeyboardShortcutsModal = sinon.stub()
    mountComponent()
    return clickToOpenMenu().then(() => {
      const menuItem = getMenuItem('Keyboard Shortcuts')
      menuItem.simulate('click')
      strictEqual(props.openKeyboardShortcutsModal.callCount, 1)
    })
  })

  test('does not include a "Moderation Page" menu item if passed showModerationMenuItem: false', () => {
    mountComponent()
    return clickToOpenMenu().then(() => {
      const menuItem = getMenuItem('Moderation Page')
      strictEqual(menuItem.length, 0)
    })
  })

  test('includes a "Moderation Page" menu item if passed showModerationMenuItem: true', () => {
    props.showModerationMenuItem = true
    mountComponent()
    return clickToOpenMenu().then(() => {
      const menuItem = getMenuItem('Moderation Page')
      strictEqual(menuItem.length, 1)
    })
  })

  test('calls window.open when the "Moderation Page" is clicked', () => {
    props.showModerationMenuItem = true
    mountComponent()
    return clickToOpenMenu().then(() => {
      const menuItem = getMenuItem('Moderation Page')
      menuItem.simulate('click')
      strictEqual(window.open.callCount, 1)
    })
  })

  test('opens the moderation page when the "Moderation Page" is clicked', () => {
    props.showModerationMenuItem = true
    mountComponent()
    return clickToOpenMenu().then(() => {
      const menuItem = getMenuItem('Moderation Page')
      menuItem.simulate('click')
      const expectedURL = `/courses/${props.courseID}/assignments/${props.assignmentID}/moderate`
      strictEqual(window.open.firstCall.args[0], expectedURL)
    })
  })

  test('opens the page in a new tab when the "Moderation Page" is clicked', () => {
    props.showModerationMenuItem = true
    mountComponent()
    return clickToOpenMenu().then(() => {
      const menuItem = getMenuItem('Moderation Page')
      menuItem.simulate('click')
      const openInNewTabArgument = '_blank'
      strictEqual(window.open.firstCall.args[1], openInNewTabArgument)
    })
  })

  test('does not include a "Help" menu item if passed showHelpMenuItem: false', () => {
    mountComponent()
    return clickToOpenMenu().then(() => {
      const menuItem = getMenuItem('Help')
      strictEqual(menuItem.length, 0)
    })
  })

  test('includes a "Help" menu item if passed showHelpMenuItem: true', () => {
    props.showHelpMenuItem = true
    mountComponent()
    return clickToOpenMenu().then(() => {
      const menuItem = getMenuItem('Help')
      strictEqual(menuItem.length, 1)
    })
  })

  test('sets the URL when "Help" is clicked', () => {
    props.showHelpMenuItem = true
    mountComponent()
    return clickToOpenMenu().then(() => {
      const menuItem = getMenuItem('Help')
      menuItem.simulate('click')
      strictEqual(SpeedGraderSettingsMenu.setURL.callCount, 1)
    })
  })

  test('navigates to the help URL when "Help" is clicked', () => {
    props.showHelpMenuItem = true
    mountComponent()
    return clickToOpenMenu().then(() => {
      const menuItem = getMenuItem('Help')
      menuItem.simulate('click')
      strictEqual(SpeedGraderSettingsMenu.setURL.firstCall.args[0], props.helpURL)
    })
  })
})
