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
import {render, screen} from '@testing-library/react'
import userEvent from '@testing-library/user-event'

import Services from '../Services'

const props = (overrides = {}) => {
  return {
    validScopes: {ascope: 'ascope', bscope: 'bscope'},
    scopes: ['ascope'],
    ...overrides,
  }
}

it('generates the toolConfiguration', () => {
  const ref = React.createRef()
  render(<Services {...props({ref})} />)
  const toolConfig = ref.current.generateToolConfigurationPart()
  expect(toolConfig.length).toEqual(1)
  expect(toolConfig[0]).toEqual('ascope')
})

it('changes the scopes on select', () => {
  const ref = React.createRef()
  render(<Services {...props({ref})} />)
  ref.current.handleScopesSelectionChange(['ascope', 'bscope'])
  const toolConfig = ref.current.generateToolConfigurationPart()
  expect(toolConfig.length).toEqual(2)
  expect(toolConfig[1]).toEqual('bscope')
})
