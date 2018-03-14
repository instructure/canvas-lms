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
  let wrapper

  hooks.beforeEach(() => {
    qunitTimeout = QUnit.config.testTimeout
    QUnit.config.testTimeout = 500 // protect against unresolved async mistakes
    props = {
      menuContentRef(ref) {
        $menuContent = ref
      },
      showHelpMenuItem: false,
      showModerationMenuItem: false
    }

    $container = document.createElement('div')
    document.body.appendChild($container)
  })

  hooks.afterEach(() => {
    $container.remove()
    QUnit.config.testTimeout = qunitTimeout
  })

  function mountComponent() {
    wrapper = mount(<SpeedGraderSettingsMenu {...props} />, {appendTo: $container})
  }

  function clickToOpenMenu() {
    return new Promise(resolve => {
      const waitForMenuReady = () => {
        setTimeout(() => {
          if ($menuContent && $menuContent.contains(document.activeElement)) {
            resolve()
          } else {
            waitForMenuReady()
          }
        })
      }
      wrapper.find('button').simulate('click')
      waitForMenuReady()
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

  test('includes a "Keyboard Shortcuts" menu item', () => {
    mountComponent()
    return clickToOpenMenu().then(() => {
      const menuItem = getMenuItem('Keyboard Shortcuts')
      strictEqual(menuItem.length, 1)
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
})
