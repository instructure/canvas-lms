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
import StepItem from '../index'

it('should render', () => {
  const {getByTestId} = render(<StepItem label="Foo" />)
  expect(getByTestId('step-item-step')).toBeInTheDocument()
})

it('should render complete status', () => {
  const {container, getByTestId} = render(<StepItem status="complete" label="Test label" />)
  const stepRender = getByTestId('step-item-step')

  expect(stepRender).toContainElement(container.querySelector(`svg[name="IconCheckMark"]`))
})

it('should render unavailable status', () => {
  const {container, getByTestId} = render(<StepItem status="unavailable" label="Test label" />)
  const stepRender = getByTestId('step-item-step')

  expect(stepRender).toContainElement(container.querySelector(`svg[name="IconLock"]`))
})

it('should render label correctly', () => {
  const {getByText} = render(<StepItem status="complete" label="progress 2" />)
  // aria-hidden label
  expect(getByText('progress 2')).toBeVisible()
  // screenreader text for status
  expect(getByText('progress 2 complete')).toBeInTheDocument()
})
