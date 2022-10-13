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
import {waitFor} from '@testing-library/react'

import ConfirmUnfavoriteCourseModal from '@canvas/dashboard-card/react/ConfirmUnfavoriteCourseModal'

QUnit.module('ConfirmUnfavoriteCourseModal', suiteHooks => {
  let $container
  let component
  let props

  suiteHooks.beforeEach(() => {
    $container = document.createElement('div')
    document.body.appendChild($container)

    props = {
      courseName: 'defense against the dark arts',
      onConfirm: sinon.spy(),
      onClose: sinon.spy(),
      onEntered: sinon.spy(),
    }
  })

  suiteHooks.afterEach(async () => {
    await ensureModalIsClosed()
    ReactDOM.unmountComponentAtNode($container)
    $container.remove()
  })

  function mountComponent() {
    const bindRef = ref => {
      component = ref
    }
    ReactDOM.render(<ConfirmUnfavoriteCourseModal ref={bindRef} {...props} />, $container)
  }

  function getModalElement() {
    return document.querySelector('[role="dialog"][aria-label="Confirm unfavorite course"]')
  }

  async function showModal() {
    component.show()
    await waitFor(() => {
      if (props.onEntered.callCount > 0) {
        return
      }
      throw new Error('Modal is not open yet')
    })
  }

  async function mountAndOpen() {
    mountComponent()
    await showModal()
  }

  async function waitForModalClosed() {
    await waitFor(() => {
      if (props.onClose.callCount > 0) {
        return
      }
      throw new Error('Modal is still open')
    })
  }

  async function ensureModalIsClosed() {
    if (getModalElement()) {
      component.hide()
      await waitForModalClosed()
    }
  }

  function getSubmitButton() {
    return [...getModalElement().querySelectorAll('Button')].find($button =>
      $button.textContent.includes('Submit')
    )
  }

  function getCloseButton() {
    return [...getModalElement().querySelectorAll('Button')].find($button =>
      $button.textContent.includes('Close')
    )
  }

  QUnit.module('#show()', () => {
    test('opens the modal', async () => {
      mountComponent()
      await showModal()
      ok(getModalElement())
    })
  })

  QUnit.module('#hide()', () => {
    test('closes the modal', async () => {
      mountComponent()
      await showModal()
      component.hide()
      await waitForModalClosed()
      strictEqual(props.onClose.callCount, 1)
    })
  })

  QUnit.module('#handleSubmitUnfavorite()', () => {
    test('calls onConfirm prop', async () => {
      await mountAndOpen()
      const $button = getSubmitButton()
      $button.click()
      strictEqual(props.onConfirm.callCount, 1)
    })

    test('hides the modal', async () => {
      await mountAndOpen()
      const $button = getSubmitButton()
      $button.click()
      await waitForModalClosed()
      strictEqual(props.onClose.callCount, 1)
    })
  })

  QUnit.module('once modal is open', () => {
    test('closes modal when Close button selected', async () => {
      await mountAndOpen()
      const $button = getCloseButton()
      $button.click()
      strictEqual(props.onClose.callCount, 1)
    })
  })
})
