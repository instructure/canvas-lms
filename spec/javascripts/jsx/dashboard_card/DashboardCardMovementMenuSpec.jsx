/*
 * Copyright (C) 2016 - present Instructure, Inc.
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

import DashboardCardMovementMenu from '@canvas/dashboard-card/react/DashboardCardMovementMenu'

QUnit.module('DashboardCardMovementMenu', suiteHooks => {
  let $container
  let component
  let props

  suiteHooks.beforeEach(() => {
    $container = document.createElement('div')
    document.body.appendChild($container)

    props = {
      assetString: 'course_1',
      cardTitle: 'Strategery 101',
      handleMove: sinon.spy(),
      onUnfavorite: sinon.spy(),
      isFavorited: true,
      menuOptions: {
        canMoveLeft: true,
        canMoveRight: true,
        canMoveToBeginning: true,
        canMoveToEnd: true,
      },
    }
  })

  suiteHooks.afterEach(async () => {
    ReactDOM.unmountComponentAtNode($container)
    $container.remove()
  })

  function mountComponent() {
    const bindRef = ref => {
      component = ref
    }
    ReactDOM.render(<DashboardCardMovementMenu ref={bindRef} {...props} />, $container)
  }

  function getMenuElement() {
    return document.querySelector('[aria-label="Dashboard Card Movement Menu"]')
  }

  QUnit.module('#handleMoveCard()', () => {
    test('calls handleMove prop once when #handleMoveCard is called', () => {
      mountComponent()
      component.handleMoveCard(2)()

      strictEqual(props.handleMove.callCount, 1)
    })

    test('calls handleMove prop with assetString parameter', () => {
      mountComponent()
      component.handleMoveCard(2)()

      strictEqual(props.handleMove.getCall(0).args[0], 'course_1')
    })

    test('calls handleMove prop with atIndex parameter', () => {
      mountComponent()
      component.handleMoveCard(2)()

      strictEqual(props.handleMove.getCall(0).args[1], 2)
    })
  })

  QUnit.module('#onUnfavorite()', () => {
    test('calls onUnfavorite when Unfavorite option is clicked', () => {
      mountComponent()
      const $button = getMenuElement().querySelector('#unfavorite')
      $button.click()
      strictEqual(props.onUnfavorite.callCount, 1)
    })
  })

  QUnit.module('isFavorited', () => {
    test('renders Unfavorite option when isFavorited is true', () => {
      mountComponent()
      const unfavorite = getMenuElement().querySelector('#unfavorite')
      ok(unfavorite)
    })

    test('does not render Unfavorite option when isFavorited is false', () => {
      props.isFavorited = false
      mountComponent()
      const unfavorite = getMenuElement().querySelector('#unfavorite')
      notOk(unfavorite)
    })
  })
})
