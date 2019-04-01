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

import React from 'react'
import ReactDOM from 'react-dom'
import SpeedGraderPostGradesMenu from 'jsx/speed_grader/SpeedGraderPostGradesMenu'

QUnit.module('SpeedGraderPostGradesMenu', hooks => {
  let $container

  hooks.beforeEach(() => {
    $container = document.createElement('div')
    document.body.appendChild($container)
  })

  hooks.afterEach(() => {
    ReactDOM.unmountComponentAtNode($container)
    $container.remove()
  })

  function renderAndOpenMenu(customProps) {
    const props = {
      allowHidingGrades: true,
      allowPostingGrades: true,
      onHideGrades: () => {},
      onPostGrades: () => {},
      ...customProps
    }

    ReactDOM.render(<SpeedGraderPostGradesMenu {...props} />, $container)
    getMenuTrigger().click()
  }

  function getMenuTrigger() {
    return $container.querySelector('button')
  }

  function getMenuContent() {
    const $trigger = getMenuTrigger()
    return document.querySelector(`[aria-labelledby="${$trigger.id}"]`)
  }

  function getPostGradesMenuItem() {
    return getMenuContent().querySelector('[role="menuitem"][name="postGrades"]')
  }

  function getHideGradesMenuItem() {
    return getMenuContent().querySelector('[role="menuitem"][name="hideGrades"]')
  }

  QUnit.module('menu trigger', () => {
    test('is rendered as an "off" icon when allowPostingGrades is true', () => {
      renderAndOpenMenu({allowPostingGrades: true})
      ok(getMenuTrigger().querySelector('svg[name="IconOff"]'))
    })

    test('is rendered as an "eye" icon when allowPostingGrades is false', () => {
      renderAndOpenMenu({allowPostingGrades: false})
      ok(getMenuTrigger().querySelector('svg[name="IconEye"]'))
    })
  })

  QUnit.module('"Post Grades" menu item', () => {
    QUnit.module('when allowPostingGrades is true', itemHooks => {
      let postGradesSpy

      itemHooks.beforeEach(() => {
        postGradesSpy = sinon.spy()
        renderAndOpenMenu({allowPostingGrades: true, onPostGrades: postGradesSpy})
      })

      test('enables the "Post Grades" menu item', () => {
        notOk(getPostGradesMenuItem().getAttribute('aria-disabled'))
      })

      test('retains the text "Post Grades"', () => {
        strictEqual(getPostGradesMenuItem().textContent, 'Post Grades')
      })

      test('fires the onPostGrades event when clicked', () => {
        getPostGradesMenuItem().click()
        strictEqual(postGradesSpy.callCount, 1)
      })
    })

    QUnit.module('when allowPostingGrades is false', itemHooks => {
      itemHooks.beforeEach(() => {
        renderAndOpenMenu({allowPostingGrades: false})
      })

      test('disables the "Post Grades" menu item', () => {
        strictEqual(getPostGradesMenuItem().getAttribute('aria-disabled'), 'true')
      })

      test('sets the text to "All Grades Posted"', () => {
        strictEqual(getPostGradesMenuItem().textContent, 'All Grades Posted')
      })
    })
  })

  QUnit.module('"Hide Grades" menu item', () => {
    QUnit.module('when allowHidingGrades is true', itemHooks => {
      let hideGradesSpy

      itemHooks.beforeEach(() => {
        hideGradesSpy = sinon.spy()
        renderAndOpenMenu({allowHidingGrades: true, onHideGrades: hideGradesSpy})
      })

      test('enables the "Hide Grades" menu item', () => {
        notOk(getHideGradesMenuItem().getAttribute('aria-disabled'))
      })

      test('retains the text "Hide Grades"', () => {
        strictEqual(getHideGradesMenuItem().textContent, 'Hide Grades')
      })

      test('fires the onHideGrades event when clicked', () => {
        getHideGradesMenuItem().click()
        strictEqual(hideGradesSpy.callCount, 1)
      })
    })

    QUnit.module('when allowHidingGrades is false', itemHooks => {
      itemHooks.beforeEach(() => {
        renderAndOpenMenu({allowHidingGrades: false})
      })

      test('disables the "Hide Grades" menu item', () => {
        strictEqual(getHideGradesMenuItem().getAttribute('aria-disabled'), 'true')
      })

      test('sets the text to "All Grades Hidden"', () => {
        strictEqual(getHideGradesMenuItem().textContent, 'All Grades Hidden')
      })
    })
  })
})
