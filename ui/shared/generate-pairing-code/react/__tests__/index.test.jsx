// @vitest-environment jsdom
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
import {shallow} from 'enzyme'
import moxios from 'moxios'
import GeneratePairingCode from '../index'

const defaultProps = {
  userId: '1',
}

beforeAll(() => {
  moxios.install()
})

afterAll(() => {
  moxios.uninstall()
})

it('renders the button and modal', () => {
  const tree = shallow(<GeneratePairingCode {...defaultProps} />)

  const button = tree.find('div > Button')
  expect(button.exists()).toEqual(true)

  const modal = tree.find('Modal')
  expect(modal.exists()).toEqual(true)
  expect(modal.props().open).toEqual(false)

  const closeButton = tree.find('CloseButton')
  expect(closeButton.exists()).toEqual(true)

  const okButton = tree.find('ModalFooter > Button')
  expect(okButton.exists()).toEqual(true)
})

it('Shows the pairing code in the modal after clicking the button', () => {
  moxios.stubRequest('/api/v1/users/1/observer_pairing_codes', {
    status: 200,
    data: {
      code: '1234',
    },
  })

  const tree = shallow(<GeneratePairingCode {...defaultProps} />)

  const button = tree.find('div > Button')
  button.simulate('click')

  moxios.wait(() => {
    const modal = tree.find('Modal')
    expect(modal.props().open).toEqual(true)

    const pairingCode = tree.find('.pairing-code Text')
    expect(pairingCode.props().children).toEqual('1234')
  })
})

it('Show an error in the modal if the pairing code fails to generate', () => {
  moxios.stubRequest('/api/v1/users/1/observer_pairing_codes', {
    status: 401,
  })

  const tree = shallow(<GeneratePairingCode {...defaultProps} />)
  tree.setState({showModal: true})

  moxios.wait(() => {
    const errorMessage = tree.find('Text[color="error"]')
    expect(errorMessage.toExists()).toEqual(true)
  })
})

it('Shows the loading spinner while the pairing code is being generated', () => {
  const tree = shallow(<GeneratePairingCode {...defaultProps} />)
  tree.setState({gettingPairingCode: true})

  const spinner = tree.find('Spinner')
  expect(spinner.exists()).toEqual(true)
})

it('clicking the close button will close the modal', () => {
  const tree = shallow(<GeneratePairingCode {...defaultProps} />)
  tree.setState({showModal: true})

  const closeButton = tree.find('CloseButton')
  closeButton.simulate('click')
  expect(tree.find('Modal').props().open).toEqual(false)
})

it('clicking the ok button will close the modal', () => {
  const tree = shallow(<GeneratePairingCode {...defaultProps} />)
  tree.setState({showModal: true})

  const okButton = tree.find('ModalFooter Button')
  okButton.simulate('click')
  expect(tree.find('Modal').props().open).toEqual(false)
})

it('should use the name in the text when it is provided', () => {
  const tree = shallow(<GeneratePairingCode {...defaultProps} name="George" />)
  tree.setState({showModal: true})

  const text = tree.find('ModalBody > Text').props().children
  expect(text.includes('George')).toEqual(true)
})
