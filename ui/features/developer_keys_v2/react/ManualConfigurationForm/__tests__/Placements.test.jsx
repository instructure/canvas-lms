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

import Placements from '../Placements'

const props = (overrides = {}, placementOverrides = {}) => {
  return {
    validPlacements: ['account_navigation', 'course_navigation'],
    placements: [
      {
        placement: 'account_navigation',
        target_link_uri: 'http://example.com',
        message_type: 'LtiResourceLinkRequest',
        icon_url: 'http://example.com/icon',
        text: 'asdf',
        selection_height: 10,
        selection_width: 10,
        ...placementOverrides,
      },
    ],
    ...overrides,
  }
}

it('allows empty placements', () => {
  const propsNoPlacements = {...props(), placements: []}
  const ref = React.createRef()
  render(<Placements {...props({placements: [], ref})} />)
  expect(ref.current.valid()).toEqual(true)
})

it('generates the toolConfiguration', () => {
  const ref = React.createRef()
  render(<Placements {...props({ref})} />)
  const toolConfig = ref.current.generateToolConfigurationPart()
  expect(toolConfig.length).toEqual(1)
  expect(toolConfig[0].icon_url).toEqual('http://example.com/icon')
})

it('generates the displayNames correctly', () => {
  render(<Placements {...props()} />)
  expect(screen.getByRole('combobox', {name: /Account Navigation/i})).toBeInTheDocument()
  expect(screen.queryByRole('combobox', {name: /Course Navigation/i})).not.toBeInTheDocument()
})

it('adds placements', async () => {
  const ref = React.createRef()
  render(<Placements {...props({ref})} />)
  ref.current.handlePlacementSelect(['account_navigation', 'course_navigation'])
  expect(screen.getByRole('combobox', {name: /Account Navigation/i})).toBeInTheDocument()
  expect(screen.queryByRole('combobox', {name: /Course Navigation/i})).toBeInTheDocument()
})

it('adds new placements to output', () => {
  const ref = React.createRef()
  render(<Placements {...props({ref})} />)
  ref.current.handlePlacementSelect(['account_navigation', 'course_navigation'])
  const toolConfig = ref.current.generateToolConfigurationPart()
  expect(toolConfig.length).toEqual(2)
  expect(toolConfig[1].placement).toEqual('course_navigation')
})
