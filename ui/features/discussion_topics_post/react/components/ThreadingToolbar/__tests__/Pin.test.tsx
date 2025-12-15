/*
 * Copyright (C) 2024 - present Instructure, Inc.
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

import {render, fireEvent, screen} from '@testing-library/react'
import React from 'react'
import {Pin} from '../Pin'
import {responsiveQuerySizes} from '../../../utils'

vi.mock('../../../utils')
vi.mock('@instructure/ui-icons', () => ({
  IconPinSolid: (props: any) => <svg {...props} data-testid="icon-pin-solid" />,
  IconPinLine: (props: any) => <svg {...props} data-testid="icon-pin-line" />,
}))

const mockResponsiveQuerySizes = responsiveQuerySizes as ReturnType<typeof vi.fn>

beforeAll(() => {
  window.matchMedia = vi.fn().mockImplementation(() => {
    return {
      matches: true,
      media: '',
      onchange: null,
      addListener: vi.fn(),
      removeListener: vi.fn(),
    }
  })
})

beforeEach(() => {
  mockResponsiveQuerySizes.mockImplementation(
    () =>
      ({
        desktop: {maxWidth: '1000px'},
      }) as any,
  )
})

const setup = (props = {}) => {
  const defaultProps = {
    onClick: vi.fn(),
    isPinned: false,
  }

  return render(<Pin {...defaultProps} {...props} />)
}

describe('Pin', () => {
  describe('Render desktop', () => {
    it('renders correct elements when status is not pinned', () => {
      const {getAllByText, queryByTestId} = setup()
      const linePinIcon = screen.getByTestId('icon-pin-line')

      expect(getAllByText('Pin')).toBeTruthy()
      expect(linePinIcon).toBeInTheDocument()
      expect(queryByTestId('threading-toolbar-pin')).toHaveAttribute(
        'data-action-state',
        'pinButton',
      )
    })

    it('renders correct elements when status is pinned', () => {
      const {getAllByText, queryByTestId} = setup({isPinned: true})
      const solidPinIcon = screen.getByTestId('icon-pin-solid')

      expect(getAllByText('Unpin')).toBeTruthy()
      expect(solidPinIcon).toBeInTheDocument()
      expect(queryByTestId('threading-toolbar-pin')).toHaveAttribute(
        'data-action-state',
        'unpinButton',
      )
    })
  })

  describe('Render mobile', () => {
    beforeEach(() => {
      mockResponsiveQuerySizes.mockImplementation(
        () =>
          ({
            mobile: {maxWidth: '1024px'},
          }) as any,
      )
    })

    it('does not render text when status is not pinned', () => {
      const {queryByText, queryByTestId} = setup()
      const linePinIcon = screen.getByTestId('icon-pin-line')

      expect(queryByText('Pin')).toBeFalsy()
      expect(linePinIcon).toBeInTheDocument()
      expect(queryByTestId('threading-toolbar-pin')).toHaveAttribute(
        'data-action-state',
        'pinButton',
      )
    })

    it('does not render text when status is pinned', () => {
      const {queryByText, queryByTestId} = setup({isPinned: true})
      const solidPinIcon = screen.getByTestId('icon-pin-solid')

      expect(queryByText('Unpin')).toBeFalsy()
      expect(solidPinIcon).toBeInTheDocument()
      expect(queryByTestId('threading-toolbar-pin')).toHaveAttribute(
        'data-action-state',
        'unpinButton',
      )
    })
  })

  describe('onClick', () => {
    it('calls provided callback when clicked', () => {
      const onClickMock = vi.fn()
      const {getAllByText} = setup({onClick: onClickMock})

      expect(onClickMock.mock.calls).toHaveLength(0)
      fireEvent.click(getAllByText('Pin')[0])
      expect(onClickMock.mock.calls).toHaveLength(1)
    })
  })
})
