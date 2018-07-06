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
import { shallow } from 'enzyme'
import sinon from 'sinon'
import ImportOutcomesModal from '../ImportOutcomesModal'

const element = () => sinon.createStubInstance(Element)
it('renders the ConfirmOutcomeEditModal component', () => {
  const modal = shallow(<ImportOutcomesModal toolbar={element()} />)
  expect(modal.exists()).toBe(true)
})

it('renders the invalid file error message if a file is rejected', () => {
  const modal = shallow(<ImportOutcomesModal toolbar={element()} />)
  modal.instance().onSelection([],[{file: 'foo'}],{})
  expect(modal.instance().state.messages).toEqual([{text: 'Invalid file type', type: 'error'}])
})

it('triggers sync and hides if a file is accepted', () => {
  const trigger = jest.fn()
  const toolbar = element()
  const dummyFile = {file: 'foo'}
  toolbar.trigger = trigger
  const modal = shallow(<ImportOutcomesModal toolbar={toolbar}/>)
  modal.instance().onSelection([dummyFile],[],{})
  expect(trigger).toBeCalledWith('start_sync', dummyFile)
  expect(modal.instance().state.show).toEqual(false)
})
