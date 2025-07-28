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

const PERCENTAGE_NAN_ERROR = 'Percentage must be a number'
const ASPECT_MESSAGE = 'Aspect ratio will be preserved'

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

  function buildMinPercentageError() {
    return `Percentage must be at least ${props.minPercentage}%`
  }

  function currentMessageText() {
    const message = component.getByTestId('message')
    return within(message).getAllByText(/.*/)[0]?.textContent
  }

  describe('"Percentage" field', () => {
    beforeEach(() => {
      initialState.usePercentageUnits = true
    })

    it('is present', () => {
      renderComponent()
      expect(dimensions.percentage).not.toBeNull()
    })

    it('is not present', () => {
      initialState.usePercentageUnits = false
      renderComponent()
      expect(dimensions.percentage).toBeNull()
    })

    describe('when the value changes', () => {
      beforeEach(renderComponent)

      it('updates the value in the field', () => {
        dimensions.percentage.setValue('95')
        expect(dimensions.percentage.value).toEqual('95')
      })

      describe('when the value includes whitespace', () => {
        it('preserves the whitespace in the field', () => {
          dimensions.percentage.setValue('  120  ')
          expect(dimensions.percentage.value).toEqual('  120  ')
        })

        it('ignores whitespace in the dimensions state height', () => {
          dimensions.percentage.setValue('  50  ')
          expect(dimensionsState.percentage).toEqual(50)
        })
      })

      describe('when the value is a decimal number', () => {
        it('preserves the decimal value in the field', () => {
          dimensions.percentage.setValue('19.51')
          expect(dimensions.percentage.value).toEqual('19.51')
        })

        it('sets the dimensions state height with the rounded integer', () => {
          dimensions.percentage.setValue('19.51')
          expect(dimensionsState.percentage).toEqual(20)
        })
      })

      describe('when the value is cleared', () => {
        beforeEach(() => {
          dimensions.percentage.setValue('')
        })

        it('sets the dimensions state percentage to null', () => {
          expect(dimensionsState.percentage).toBeNull()
        })

        it('sets the dimensions state as invalid', () => {
          expect(dimensionsState.isValid).toEqual(false)
        })
      })

      describe('when the value is not a number', () => {
        beforeEach(() => {
          dimensions.percentage.setValue('twelve')
        })

        it('preserves the invalid value in the field', () => {
          expect(dimensions.percentage.value).toEqual('twelve')
        })

        it('sets the dimensions state percentage to NaN', () => {
          expect(dimensionsState.percentage).toBeNaN()
        })
      })

      describe('when the value is not a finite number', () => {
        beforeEach(() => {
          dimensions.percentage.setValue('Infinity')
        })

        it('preserves the value in the field', () => {
          expect(dimensions.percentage.value).toEqual('Infinity')
        })

        it('sets the dimensions state height to NaN', () => {
          expect(dimensionsState.percentage).toBeNaN()
        })

        it('sets the dimensions state as invalid', () => {
          expect(dimensionsState.isValid).toEqual(false)
        })

        it('displays a validation error with the field', () => {
          expect(currentMessageText()).toEqual(PERCENTAGE_NAN_ERROR)
        })
      })

      describe('when the value is less than the minimum', () => {
        beforeEach(() => {
          dimensions.percentage.setValue(props.minPercentage)
          dimensions.percentage.setValue(props.minPercentage - 1)
        })

        it('displays a validation error with the field', () => {
          expect(currentMessageText()).toEqual(buildMinPercentageError())
        })

        it('sets the dimensions state as invalid', () => {
          expect(dimensionsState.isValid).toEqual(false)
        })
      })

      describe('when the value becomes valid', () => {
        beforeEach(() => {
          dimensions.percentage.setValue(props.minPercentage - 1)
          dimensions.percentage.setValue(props.minPercentage)
        })

        it('removes the validation error from the field', () => {
          expect(currentMessageText()).toEqual(ASPECT_MESSAGE)
        })

        it('sets the dimensions state as valid', () => {
          expect(dimensionsState.isValid).toEqual(true)
        })
      })

      describe('when the value remains invalid', () => {
        beforeEach(() => {
          dimensions.percentage.setValue('')
          dimensions.percentage.setValue(1)
        })

        it('displays a validation error with the field', () => {
          expect(currentMessageText()).toEqual(buildMinPercentageError())
        })

        it('sets the dimensions state as invalid', () => {
          expect(dimensionsState.isValid).toEqual(false)
        })
      })
    })

    describe('when decremented', () => {
      describe('when a percentage has been applied to the element', () => {
        beforeEach(() => {
          renderComponent()
          dimensions.percentage.decrement()
        })

        it('decrements the applied percentage for the field value', () => {
          expect(dimensions.percentage.value).toEqual(`${initialState.appliedPercentage - 1}`)
        })

        it('decrements the applied percentage for the dimensions state percentage', () => {
          expect(dimensionsState.percentage).toEqual(initialState.appliedPercentage - 1)
        })
      })

      describe('when no percentage has been applied to the element', () => {
        beforeEach(() => {
          initialState.appliedPercentage = null
          renderComponent()
          dimensions.percentage.decrement()
        })

        it('decrements the full percentage for the field value', () => {
          expect(dimensions.percentage.value).toEqual('99')
        })

        it('decrements the full percentage for the dimensions state percentage', () => {
          expect(dimensionsState.percentage).toEqual(99)
        })
      })

      describe('when the applied percentage is less than the minimum percentage', () => {
        beforeEach(() => {
          initialState.appliedPercentage = props.minPercentage - 1
          renderComponent()
          dimensions.percentage.decrement()
        })

        it('uses the minimum percentage for the field value', () => {
          expect(dimensions.percentage.value).toEqual(`${props.minPercentage}`)
        })

        it('uses the minimum percentage for the dimensions state percentage', () => {
          expect(dimensionsState.percentage).toEqual(props.minPercentage)
        })

        it('removes the validation error from the field', () => {
          expect(currentMessageText()).toEqual(ASPECT_MESSAGE)
        })

        it('sets the dimensions state as valid', () => {
          expect(dimensionsState.isValid).toEqual(true)
        })
      })

      describe('when the value had been cleared', () => {
        beforeEach(() => {
          renderComponent()
          dimensions.percentage.setValue('')
          dimensions.percentage.decrement()
        })

        it('decrements the initial percentage for the field value', () => {
          expect(dimensions.percentage.value).toEqual(`${initialState.appliedPercentage - 1}`)
        })

        it('decrements the initial percentage for the dimensions state percentage', () => {
          expect(dimensionsState.percentage).toEqual(initialState.appliedPercentage - 1)
        })

        it('removes the validation error from the field', () => {
          expect(currentMessageText()).toEqual(ASPECT_MESSAGE)
        })

        it('sets the dimensions state as valid', () => {
          expect(dimensionsState.isValid).toEqual(true)
        })
      })

      describe('when the value is not a number', () => {
        beforeEach(() => {
          renderComponent()
          dimensions.percentage.setValue('twelve')
          dimensions.percentage.decrement()
        })

        it('preserves the invalid value in the field', () => {
          expect(dimensions.percentage.value).toEqual('twelve')
        })

        it('sets the dimensions state percentage to NaN', () => {
          expect(dimensionsState.percentage).toBeNaN()
        })
      })
    })

    describe('when incremented', () => {
      describe('when a percentage has been applied to the element', () => {
        beforeEach(() => {
          renderComponent()
          dimensions.percentage.increment()
        })

        it('increments the applied height for the field value', () => {
          expect(dimensions.percentage.value).toEqual(`${initialState.appliedPercentage + 1}`)
        })

        it('increments the applied height for the dimensions state height', () => {
          expect(dimensionsState.percentage).toEqual(initialState.appliedPercentage + 1)
        })
      })

      describe('when no percentage has been applied to the element', () => {
        beforeEach(() => {
          initialState.appliedPercentage = null
          renderComponent()
          dimensions.percentage.increment()
        })

        it('increments the full percentage for the field value', () => {
          expect(dimensions.percentage.value).toEqual('101')
        })

        it('increments the full percentage for the dimensions state percentage', () => {
          expect(dimensionsState.percentage).toEqual(101)
        })
      })

      describe('when the applied percentage is less than the minimum percentage', () => {
        beforeEach(() => {
          initialState.appliedPercentage = props.minPercentage - 2
          renderComponent()
          dimensions.percentage.increment()
        })

        it('uses the minimum percentage for the field value', () => {
          expect(dimensions.percentage.value).toEqual(`${props.minPercentage}`)
        })

        it('uses the minimum percentage for the dimensions state percentage', () => {
          expect(dimensionsState.percentage).toEqual(props.minPercentage)
        })

        it('removes the validation error from the field', () => {
          expect(currentMessageText()).toEqual(ASPECT_MESSAGE)
        })

        it('sets the dimensions state as valid', () => {
          expect(dimensionsState.isValid).toEqual(true)
        })
      })

      describe('when the value had been cleared', () => {
        beforeEach(() => {
          renderComponent()
          dimensions.percentage.setValue('')
          dimensions.percentage.increment()
        })

        it('increments the initial percentage for the field value', () => {
          expect(dimensions.percentage.value).toEqual(`${initialState.appliedPercentage + 1}`)
        })

        it('increments the initial percentage for the dimensions state height', () => {
          expect(dimensionsState.percentage).toEqual(initialState.appliedPercentage + 1)
        })

        it('removes the validation error from the field', () => {
          expect(currentMessageText()).toEqual(ASPECT_MESSAGE)
        })

        it('sets the dimensions state as valid', () => {
          expect(dimensionsState.isValid).toEqual(true)
        })
      })

      describe('when the value is not a number', () => {
        beforeEach(() => {
          renderComponent()
          dimensions.percentage.setValue('twelve')
          dimensions.percentage.increment()
        })

        it('preserves the invalid value in the field', () => {
          expect(dimensions.percentage.value).toEqual('twelve')
        })

        it('sets the dimensions state percentage to NaN', () => {
          expect(dimensionsState.percentage).toBeNaN()
        })
      })
    })
  })
})
