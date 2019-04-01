/*
 * Copyright (C) 2019 - present Instructure, Inc.
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
import {render, fireEvent} from 'react-testing-library'
import EditableHeading from '../EditableHeading'

it('renders the value in view mode', () => {
  const {getByText} = render(
    <EditableHeading
      mode="view"
      onChange={() => {}}
      onChangeMode={() => {}}
      label="Book title"
      value="Another Roadside Attraction"
      level="h3"
    />
  )

  expect(getByText('Another Roadside Attraction')).toBeInTheDocument()
  expect(document.querySelector('h3')).toBeInTheDocument()
})

it('renders the value in edit mode', () => {
  const {getByDisplayValue} = render(
    <EditableHeading
      mode="edit"
      onChange={() => {}}
      onChangeMode={() => {}}
      label="Book title"
      value="Still Life with Woodpecker"
      level="h3"
    />
  )

  expect(getByDisplayValue('Still Life with Woodpecker')).toBeInTheDocument()
})

it('does not render edit button when readOnly', () => {
  const {queryByText} = render(
    <EditableHeading
      mode="view"
      onChange={() => {}}
      onChangeMode={() => {}}
      label="Edit title"
      value="Still Life with Woodpecker"
      level="h3"
      readOnly
    />
  )
  expect(queryByText('Edit title')).toBeNull()
})

it('exits edit mode on <Enter>', () => {
  const onChangeMode = jest.fn()
  const {getByDisplayValue} = render(
    <EditableHeading
      mode="edit"
      onChange={() => {}}
      onChangeMode={onChangeMode}
      label="Book title"
      value="Jitterbug Perfume"
      level="h3"
    />
  )
  const input = getByDisplayValue('Jitterbug Perfume')
  fireEvent.keyDown(input, {key: 'Enter', code: 13})
  expect(onChangeMode).toHaveBeenCalledWith('view')
})
