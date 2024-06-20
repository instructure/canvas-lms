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
import Modal from '@canvas/react-modal'
import ManageAppListButton from '../ManageAppListButton'

const ok = value => expect(value).toBeTruthy()
const equal = (value, expected) => expect(value).toEqual(expected)

const wrapper = document.createElement('div')
wrapper.setAttribute('id', 'fixtures')
document.body.appendChild(wrapper)

Modal.setAppElement(wrapper)
const onUpdateAccessToken = function () {}
const createElement = () => <ManageAppListButton onUpdateAccessToken={onUpdateAccessToken} />
const renderComponent = () => ReactDOM.render(createElement(), wrapper)

describe('ExternalApps.ManageAppListButton', () => {
  afterEach(() => {
    ReactDOM.unmountComponentAtNode(wrapper)
  })

  test('open and close modal', () => {
    const component = renderComponent({})
    component.openModal()
    ok(component.state.modalIsOpen, 'modal is open')

    component.closeModal()

    ok(!component.state.modalIsOpen, 'modal is not open')
  })

  test('maskedAccessToken', () => {
    const component = renderComponent({})
    equal(component.maskedAccessToken(undefined), undefined)
    equal(component.maskedAccessToken('token'), 'token...')
  })
})
