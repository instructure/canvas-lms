
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
import { mount, ReactWrapper } from 'enzyme'
import merge from 'lodash/merge'

import ConfirmDeleteModal from 'jsx/announcements/components/ConfirmDeleteModal'

const makeProps = (props = {}) => merge({
  onConfirm () {},
  onCancel () {},
  onHide () {},
  modalRef () {},
  selectedCount: 1,
  applicationElement: () => document.getElementById('fixtures'),
}, props)

QUnit.module('ConfirmDeleteModal component')

test('should call onConfirm prop after confirming delete', (assert) => {
  const done = assert.async()
  const confirmSpy = sinon.spy()
  const tree = mount(
    <ConfirmDeleteModal {...makeProps({ onConfirm: confirmSpy })} />
  )
  const instance = tree.instance()
  instance.show()

  setTimeout(() => {
    const confirmWrapper = new ReactWrapper(instance.confirmBtn, instance.confirmBtn)
    confirmWrapper.simulate('click')

    // the nested setTimeout is necessary because if we do unmount in the same tick as clicking on confirm
    // then the focus unmount logic will run before the focus re-direction logic, which will blow up
    // using an additional setTimeout pushes the unmount execution in the next tick, after the focus logic
    setTimeout(() => {
      equal(confirmSpy.callCount, 1)
      tree.unmount()
      done()
    })
  })
})

test('should call onHide prop after confirming delete', (assert) => {
  const done = assert.async()
  const hideSpy = sinon.spy()
  const tree = mount(
    <ConfirmDeleteModal {...makeProps({ onHide: hideSpy })} />
  )
  const instance = tree.instance()
  instance.show()

  setTimeout(() => {
    const confirmWrapper = new ReactWrapper(instance.confirmBtn, instance.confirmBtn)
    confirmWrapper.simulate('click')

    // the nested setTimeout is necessary because if we do unmount in the same tick as clicking on confirm
    // then the focus unmount logic will run before the focus re-direction logic, which will blow up
    // using an additional setTimeout pushes the unmount execution in the next tick, after the focus logic
    setTimeout(() => {
      equal(hideSpy.callCount, 1)
      tree.unmount()
      done()
    })
  })
})

test('should call onCancel prop after cancelling', (assert) => {
  const done = assert.async()
  const cancelSpy = sinon.spy()
  const tree = mount(
    <ConfirmDeleteModal {...makeProps({ onCancel: cancelSpy })} />
  )
  const instance = tree.instance()
  instance.show()

  setTimeout(() => {
    const cancelWrapper = new ReactWrapper(instance.cancelBtn, instance.cancelBtn)
    cancelWrapper.simulate('click')

    // the nested setTimeout is necessary because if we do unmount in the same tick as clicking on confirm
    // then the focus unmount logic will run before the focus re-direction logic, which will blow up
    // using an additional setTimeout pushes the unmount execution in the next tick, after the focus logic
    setTimeout(() => {
      equal(cancelSpy.callCount, 1)
      tree.unmount()
      done()
    })
  })
})

test('should call onHide prop after cancelling', (assert) => {
  const done = assert.async()
  const hideSpy = sinon.spy()
  const tree = mount(
    <ConfirmDeleteModal {...makeProps({ onHide: hideSpy })} />
  )
  const instance = tree.instance()
  instance.show()

  setTimeout(() => {
    const cancelWrapper = new ReactWrapper(instance.cancelBtn, instance.cancelBtn)
    cancelWrapper.simulate('click')

    // the nested setTimeout is necessary because if we do unmount in the same tick as clicking on confirm
    // then the focus unmount logic will run before the focus re-direction logic, which will blow up
    // using an additional setTimeout pushes the unmount execution in the next tick, after the focus logic
    setTimeout(() => {
      equal(hideSpy.callCount, 1)
      tree.unmount()
      done()
    })
  })
})
