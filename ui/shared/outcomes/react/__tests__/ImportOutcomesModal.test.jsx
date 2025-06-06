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
import {render} from '@testing-library/react'
import ImportOutcomesModal from '../ImportOutcomesModal'

const element = () => {
  const el = document.createElement('div')
  el.trigger = jest.fn()
  return el
}

it('renders the ImportOutcomesModal component', () => {
  let modalRef
  render(
    <ImportOutcomesModal
      toolbar={element()}
      ref={ref => {
        modalRef = ref
      }}
    />,
  )
  modalRef.show()
  expect(modalRef).toBeTruthy()
})

it('renders the ImportOutcomesModal component without toolbar', () => {
  let modalRef
  render(
    <ImportOutcomesModal
      ref={ref => {
        modalRef = ref
      }}
    />,
  )
  modalRef.show()
  expect(modalRef).toBeTruthy()
})

it('renders the invalid file error message if a file is rejected', () => {
  let modalRef
  const {rerender} = render(
    <ImportOutcomesModal
      toolbar={element()}
      ref={ref => {
        modalRef = ref
      }}
    />,
  )
  modalRef.onSelection([], [{file: 'foo'}], {})
  rerender(
    <ImportOutcomesModal
      toolbar={element()}
      ref={ref => {
        modalRef = ref
      }}
    />,
  )
  expect(modalRef.state.messages).toEqual([{text: 'Invalid file type', type: 'error'}])
})

it('triggers sync and hides if a file is accepted', () => {
  const trigger = jest.fn()
  const toolbar = element()
  const dummyFile = {file: 'foo'}
  toolbar.trigger = trigger
  let modalRef
  render(
    <ImportOutcomesModal
      toolbar={toolbar}
      ref={ref => {
        modalRef = ref
      }}
    />,
  )
  modalRef.onSelection([dummyFile], [], {})
  expect(trigger).toHaveBeenCalledWith('start_sync', dummyFile)
  expect(modalRef.state.show).toEqual(false)
})

it('calls onFileDrop and hides if a file is accepted', () => {
  const onFileDrop = jest.fn()
  const dummyFile = {file: 'foo'}
  let modalRef
  render(
    <ImportOutcomesModal
      onFileDrop={onFileDrop}
      ref={ref => {
        modalRef = ref
      }}
    />,
  )
  modalRef.onSelection([dummyFile], [], {})
  expect(onFileDrop).toHaveBeenCalledWith(dummyFile, undefined, undefined)
  expect(modalRef.state.show).toEqual(false)
})
