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
import {render, screen, within} from '@testing-library/react'

import DimensionsInput, {useDimensionsState} from '..'
import DimensionsInputDriver from './DimensionsInputDriver'

describe('RCE > Plugins > Shared > DimensionsInput', () => {
  let $container
  let component
  let dimensionsState
  let initialState
  let props

  beforeEach(() => {
    $container = document.body.appendChild(document.createElement('div'))
    dimensionsState = null

    initialState = {
      appliedHeight: 300,
      appliedWidth: 150,
      appliedPercentage: 70,
      usePercentageUnits: false,
      naturalHeight: 200,
      naturalWidth: 100,
    }

    props = {
      minWidth: 30,
      minHeight: 60,
      minPercentage: 10,
      hidePercentage: false,
    }
  })

  afterEach(() => {
    component.unmount()
    $container.remove()
  })

  function SpecComponent() {
    const {minHeight, minWidth, minPercentage} = props
    dimensionsState = useDimensionsState(initialState, {minHeight, minWidth, minPercentage})

    return <DimensionsInput dimensionsState={dimensionsState} {...props} />
  }

  function renderComponent() {
    component = render(<SpecComponent />, {container: $container})
    new DimensionsInputDriver($container)
  }
  describe('When hidePercentage is false', () => {
    let percentageRadio
    let pixelsRadio

    beforeEach(() => {
      initialState.usePercentageUnits = true
      renderComponent()
      const container = screen.getByTestId('dimension-type')
      percentageRadio = within(container).getByLabelText('Percentage')
      pixelsRadio = within(container).getByLabelText('Pixels')
    })

    it('The radio input group for Percentage and Pixels is displayed', () => {
      const radioInputGroup = screen.getByRole('radiogroup', {name: /Dimension Type/i})

      expect(radioInputGroup).toBeVisible()
    })
    it('The "Percentage" radio input is checked', () => {
      expect(percentageRadio).toBeChecked()
      expect(pixelsRadio).not.toBeChecked()
    })
    it('The dimension input for width is not rendered', () => {
      const widthInput = screen.queryByLabelText('Width')
      expect(widthInput).not.toBeInTheDocument()
    })
    it('The dimension input for height is not rendered', () => {
      const heightInput = screen.queryByLabelText('Height')
      expect(heightInput).not.toBeInTheDocument()
    })
  })
  describe('When hidePercentage is true', () => {
    beforeEach(() => {
      props.hidePercentage = true
      renderComponent()
    })
    it('The radio input group for Percentage and Pixels is not displayed', () => {
      const radioInputGroup = screen.queryByRole('group', {name: /Dimension Type/i})
      expect(radioInputGroup).toBeNull()
    })
    it('The custom text description is displayed', () => {
      const label = screen.getByText('Custom width and height (Pixels)')
      expect(label).toBeVisible()
    })
  })
})
