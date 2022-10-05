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
import {shallow} from 'enzyme'
import ExternalToolPlacementButton from 'ui/features/external_apps/react/components/ExternalToolPlacementButton'

QUnit.module('ExternalToolPlacementButton')

test('normally renders with a menuitem role', () => {
  const wrapper = shallow(
    <ExternalToolPlacementButton
      tool={{
        app_type: 'ContextExternalTool',
        name: 'A Tool',
      }}
      returnFocus={() => {}}
      onSuccess={() => {}}
    />
  )
  equal(wrapper.find('a').props().role, 'menuitem')
})

test('renders as a button when specified', () => {
  const wrapper = shallow(
    <ExternalToolPlacementButton
      type="button"
      tool={{
        app_type: 'ContextExternalTool',
        name: 'A Tool',
      }}
      returnFocus={() => {}}
      onSuccess={() => {}}
    />
  )
  equal(wrapper.find('a').props().role, 'button')
})

test('does not attempt to open an opened modal', () => {
  const wrapper = shallow(
    <ExternalToolPlacementButton
      type="button"
      tool={{
        app_type: 'ContextExternalTool',
        name: 'A Tool',
      }}
      returnFocus={() => {}}
      onSuccess={() => {}}
    />
  )

  wrapper.setState({modalIsOpen: true})
  ok(wrapper.find('a').simulate('click', {preventDefault: () => {}}))
})
