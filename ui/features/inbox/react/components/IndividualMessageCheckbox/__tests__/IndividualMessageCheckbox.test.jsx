/*
 * Copyright (C) 2020 - present Instructure, Inc.
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

import {render, fireEvent} from '@testing-library/react'
import React from 'react'
import {IndividualMessageCheckbox} from '../IndividualMessageCheckbox'
import {responsiveQuerySizes} from '../../../../util/utils'

jest.mock('../../../../util/utils', () => ({
  ...jest.requireActual('../../../../util/utils'),
  responsiveQuerySizes: jest.fn(() => ({
    mobile: {maxWidth: '67px'},
    desktop: {minWidth: '768px'},
  })),
}))

const setup = props => {
  const utils = render(<IndividualMessageCheckbox onChange={() => {}} {...props} />)
  const individualCheckbox = utils.container.querySelector('input')
  return {individualCheckbox, utils}
}

describe('Button', () => {
  beforeAll(() => {
    // Add appropriate mocks for responsive
    window.matchMedia = jest.fn().mockImplementation(query => ({
      matches: query.includes('max-width'),
      media: query,
      onchange: null,
      addListener: jest.fn(),
      removeListener: jest.fn(),
    }))

    // Responsive Query Mock Default
    responsiveQuerySizes.mockImplementation(() => ({
      mobile: {maxWidth: '767px'},
      desktop: {minWidth: '768px'},
    }))
  })

  it('renders', () => {
    const {individualCheckbox} = setup()
    expect(individualCheckbox).toBeTruthy()
  })

  it('should call onChange when typing occurs', () => {
    const onChangeMock = jest.fn()
    const {individualCheckbox} = setup({
      onChange: onChangeMock,
    })
    fireEvent.click(individualCheckbox)
    expect(onChangeMock.mock.calls).toHaveLength(1)
  })

  it('should show checkbox as checked when prop is present', () => {
    const {individualCheckbox} = setup({
      checked: true,
    })
    expect(individualCheckbox.checked).toBe(true)
  })

  it('should not show checkbox as checked when prop is missing', () => {
    const {individualCheckbox} = setup()
    expect(individualCheckbox.checked).toBe(false)
  })

  describe('checkedAndDisabled prop', () => {
    beforeEach(() => {
      // Ensure mobile view for these tests
      window.matchMedia = jest.fn().mockImplementation(query => ({
        matches: query.includes('max-width'),
        media: query,
        onchange: null,
        addListener: jest.fn(),
        removeListener: jest.fn(),
      }))

      responsiveQuerySizes.mockImplementation(() => ({
        mobile: {maxWidth: '767px'},
        desktop: {minWidth: '768px'},
      }))
    })

    it('should render checked and disabled checkbox when true', () => {
      const props = {
        checkedAndDisabled: true,
        onChange: jest.fn(),
        title: 'Test Item',
      }

      const {getByTestId} = render(<IndividualMessageCheckbox {...props} />)

      const checkbox = getByTestId('individual-message-checkbox-mobile')
      expect(checkbox).toBeChecked()
      expect(checkbox).toBeDisabled()
    })

    it('should render unchecked and enabled checkbox when false', () => {
      const props = {
        checkedAndDisabled: false,
        onChange: jest.fn(),
        title: 'Test Item',
      }

      const {getByTestId} = render(<IndividualMessageCheckbox {...props} />)

      const checkbox = getByTestId('individual-message-checkbox-mobile')
      expect(checkbox).not.toBeChecked()
      expect(checkbox).not.toBeDisabled()
    })
  })

  describe('Responsive', () => {
    describe('Mobile', () => {
      beforeEach(() => {
        responsiveQuerySizes.mockImplementation(() => ({
          mobile: {maxWidth: '767px'},
        }))
      })

      it('Changes to Toggle vairent when mobile', () => {
        const {utils} = setup()
        const checkbox = utils.findByTestId('individual-message-checkbox-mobile')
        expect(checkbox).toBeTruthy()
      })
    })

    describe('Desktop', () => {
      beforeEach(() => {
        responsiveQuerySizes.mockImplementation(() => ({
          desktop: {minWidth: '768px'},
        }))
      })

      it('Changes to Toggle vairent when mobile', () => {
        const {utils} = setup()
        const checkbox = utils.findByTestId('individual-message-checkbox')
        expect(checkbox).toBeTruthy()
      })
    })
  })
})
