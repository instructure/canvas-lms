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
import merge from 'lodash/merge'
import ConfirmDeleteModal from '../ConfirmDeleteModal'

const container = document.createElement('div')
container.setAttribute('id', 'fixtures')
document.body.appendChild(container)

const equal = (x, y) => expect(x).toBe(y)

const makeProps = (props = {}) =>
  merge(
    {
      onConfirm() {},
      onCancel() {},
      onHide() {},
      modalRef() {},
      selectedCount: 1,
      applicationElement: () => document.getElementById('fixtures'),
    },
    props,
  )

describe('ConfirmDeleteModal component', () => {
  test('should call onConfirm prop after confirming delete', done => {
    const confirmSpy = jest.fn()
    const tree = shallow(<ConfirmDeleteModal {...makeProps({onConfirm: confirmSpy})} />)
    tree.find('#confirm_delete_announcements').simulate('click')
    setTimeout(() => {
      expect(confirmSpy).toHaveBeenCalledTimes(1)
      done()
    })
  })

  test('should call onHide prop after confirming delete', done => {
    const hideSpy = jest.fn()
    const tree = shallow(<ConfirmDeleteModal {...makeProps({onHide: hideSpy})} />)
    tree.find('#confirm_delete_announcements').simulate('click')
    setTimeout(() => {
      expect(hideSpy).toHaveBeenCalledTimes(1)
      done()
    })
  })

  test('should call onCancel prop after cancelling', done => {
    const cancelSpy = jest.fn()
    const tree = shallow(<ConfirmDeleteModal {...makeProps({onCancel: cancelSpy})} />)
    tree.find('#cancel_delete_announcements').simulate('click')
    setTimeout(() => {
      expect(cancelSpy).toHaveBeenCalledTimes(1)
      done()
    })
  })

  test('should call onHide prop after cancelling', done => {
    const hideSpy = jest.fn()
    const tree = shallow(<ConfirmDeleteModal {...makeProps({onHide: hideSpy})} />)
    tree.find('#confirm_delete_announcements').simulate('click')
    setTimeout(() => {
      expect(hideSpy).toHaveBeenCalledTimes(1)
      done()
    })
  })
})
