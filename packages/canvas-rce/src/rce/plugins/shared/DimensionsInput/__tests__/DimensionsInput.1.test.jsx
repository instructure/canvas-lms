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
import {render, within} from '@testing-library/react'

import DimensionsInput, {useDimensionsState} from '..'
import DimensionsInputDriver from './DimensionsInputDriver'

describe('RCE > Plugins > Shared > DimensionsInput', () => {
  let $container
  let component
  let dimensions
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
    dimensions = new DimensionsInputDriver($container)
  }

  function buildMinDimensionsError() {
    return `Pixels must be at least ${props.minWidth} x ${props.minHeight}px`
  }

  function buildMinPercentageError() {
    return `Percentage must be at least ${props.minPercentage}%`
  }

  function currentMessageText() {
    const message = component.getByTestId('message')
    return within(message).getAllByText(/.*/)[0]?.textContent
  }

  describe('"Pixels" radio button', () => {
    beforeEach(() => {
      initialState.usePercentageUnits = false
      renderComponent()
    })

    it('is selected', () => {
      expect(dimensions.pixelsRadioButton.checked).toEqual(true)
    })

    it('is not selected', () => {
      expect(dimensions.percentageRadioButton.checked).toEqual(false)
    })
  })

  describe('"Percentage" radio button', () => {
    beforeEach(() => {
      initialState.usePercentageUnits = true
      renderComponent()
    })

    it('is selected', () => {
      expect(dimensions.percentageRadioButton.checked).toEqual(true)
    })

    it('is not selected', () => {
      expect(dimensions.pixelsRadioButton.checked).toEqual(false)
    })
  })
})
