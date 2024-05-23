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
import {render} from '@testing-library/react'
import {animatable} from '../animatable'
import {DynamicUiProvider} from '../provider'

// eslint-disable-next-line react/prefer-stateless-function
class MockComponent extends React.Component {
  render() {
    return <div data-testid="mock-component" />
  }
}

MockComponent.displayName = 'MockComponent'

it('passes trigger property functions and forwards the calls to the dynamic ui manager', () => {
  const Wrapped = animatable(MockComponent)
  const mockManager = {
    handleAction: jest.fn(),
    registerAnimatable: jest.fn(),
    deregisterAnimatable: jest.fn(),
    preTriggerUpdates: jest.fn(),
    triggerUpdates: jest.fn(),
  }

  const ref = React.createRef()
  const wrapper = render(
    <DynamicUiProvider manager={mockManager}>
      <Wrapped ref={ref} />
    </DynamicUiProvider>
  )
  expect(wrapper.getByTestId('mock-component')).toMatchSnapshot()

  ref.current.registerAnimatable('type', 'component', 42, ['item'])
  expect(mockManager.registerAnimatable).toHaveBeenCalledWith('type', 'component', 42, ['item'])
  ref.current.deregisterAnimatable('type', 'component', ['item'])
  expect(mockManager.deregisterAnimatable).toHaveBeenCalledWith('type', 'component', ['item'])
})
