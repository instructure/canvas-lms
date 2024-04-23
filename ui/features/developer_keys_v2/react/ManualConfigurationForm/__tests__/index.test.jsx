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

import ManualConfiguration from '../index'
import userEvent from '@testing-library/user-event'

const props = (overrides = {}) => {
  return {
    toolConfiguration: {},
    validScopes: {
      test: 'valid_scope',
    },
    validPlacements: ['aplacement'],
    ...overrides,
  }
}

it('renders form', () => {
  render(<ManualConfiguration {...props()} />)
  expect(screen.getByLabelText('* Title')).toBeInTheDocument()
  expect(screen.getByLabelText('* Title')).toBeInTheDocument()
  expect(screen.getByLabelText('* Description')).toBeInTheDocument()
  expect(screen.getByLabelText('* Target Link URI')).toBeInTheDocument()
  expect(screen.getByLabelText('* OpenID Connect Initiation Url')).toBeInTheDocument()
  expect(screen.getByLabelText('* JWK Method')).toBeInTheDocument()
})

it('generates the toolConfiguration', () => {
  const ref = React.createRef()
  render(<ManualConfiguration {...props()} ref={ref} />)
  const toolConfig = ref.current.generateToolConfiguration()
  expect(toolConfig.scopes).toBeDefined()
  expect(toolConfig.extensions.length).toEqual(1)
})
