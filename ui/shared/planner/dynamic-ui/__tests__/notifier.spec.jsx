/*
 * Copyright (C) 2017 - present Instructure, Inc.
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
import {mount} from 'enzyme'
import {notifier} from '../notifier'
import {DynamicUiProvider} from '../provider'

// eslint-disable-next-line react/prefer-stateless-function
class MockComponent extends React.Component {
  render() {
    return <div />
  }
}

MockComponent.displayName = 'MockComponent'

it('passes trigger property functions and forwards the calls to the dynamic ui manager', () => {
  const Wrapped = notifier(MockComponent)
  const mockManager = {
    handleAction: jest.fn(),
    registerAnimatable: jest.fn(),
    deregisterAnimatable: jest.fn(),
    preTriggerUpdates: jest.fn(),
    triggerUpdates: jest.fn(),
  }

  const wrapper = mount(
    <DynamicUiProvider manager={mockManager}>
      <Wrapped />
    </DynamicUiProvider>
  )
  expect(wrapper).toMatchSnapshot()

  const mockComponentProps = wrapper.find('MockComponent').props()
  mockComponentProps.preTriggerDynamicUiUpdates('args')
  expect(mockManager.preTriggerUpdates).toHaveBeenCalledWith('args')
  mockComponentProps.triggerDynamicUiUpdates('args')
  expect(mockManager.triggerUpdates).toHaveBeenCalledWith('args')
})
