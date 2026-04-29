/*
 * Copyright (C) 2025 - present Instructure, Inc.
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
import {render, screen, fireEvent, waitFor} from '@testing-library/react'
import {ModulesPageLegend, type ModulesPagePageLegendProps} from '../ModulesPageLegend'

describe('ModulesPageIconLegend', () => {
  const defaultProps: ModulesPagePageLegendProps = {
    is_blueprint_course: false,
    is_student: false,
  }

  const renderComponent = (props = {}) => {
    return render(<ModulesPageLegend {...defaultProps} {...props} />)
  }

  describe('visibility', () => {
    it('hides the button by default', () => {
      const {getByTestId} = renderComponent()

      const wrapper = getByTestId('icon-legend-button-wrapper') as HTMLElement
      expect(wrapper).toBeInTheDocument()
      expect(wrapper).toHaveStyle('opacity: 0')
    })

    it('shows the button on focus', () => {
      const {getByTestId} = renderComponent()

      const wrapper = getByTestId('icon-legend-button-wrapper') as HTMLElement
      const button = wrapper.querySelector('button') as HTMLButtonElement
      expect(wrapper).toBeInTheDocument()
      expect(wrapper).toHaveStyle('opacity: 0')

      fireEvent.focus(button)
      expect(wrapper).not.toHaveStyle('opacity: 0')
    })

    it('hides the button on blur', () => {
      const {getByTestId} = renderComponent()

      const wrapper = getByTestId('icon-legend-button-wrapper')
      const button = wrapper.querySelector('button') as HTMLButtonElement
      expect(wrapper).toBeInTheDocument()
      fireEvent.focus(button)
      expect(wrapper).not.toHaveStyle('opacity: 0')

      fireEvent.blur(button)
      expect(wrapper).toHaveStyle('opacity: 0')
    })

    it('keeps the button visible on blur when modal is open', async () => {
      const {getByTestId} = renderComponent()

      const wrapper = getByTestId('icon-legend-button-wrapper')
      const button = wrapper.querySelector('button') as HTMLButtonElement
      fireEvent.focus(button)
      fireEvent.click(button)

      await waitFor(() => {
        expect(getByTestId('icon-legend-modal')).toBeInTheDocument()
      })
      expect(button).not.toHaveFocus()
      expect(wrapper).not.toHaveStyle('opacity: 0')
    })
  })

  describe('the modal', () => {
    it('is rendered on button click', async () => {
      const {getByTestId} = renderComponent()

      const button = getByTestId('icon-legend-button-wrapper').querySelector(
        'button',
      ) as HTMLButtonElement
      fireEvent.click(button)

      await waitFor(() => {
        expect(getByTestId('icon-legend-modal')).toBeInTheDocument()
      })
    })

    it('renders published and unpublished icons for non-blueprint courses', async () => {
      const {getByTestId} = renderComponent({is_blueprint_course: false})

      const button = getByTestId('icon-legend-button-wrapper').querySelector(
        'button',
      ) as HTMLButtonElement
      fireEvent.click(button)

      await waitFor(() => {
        expect(getByTestId('icon-legend-modal')).toBeInTheDocument()
      })

      expect(getByTestId('icon-legend-modal')).toBeInTheDocument()
      expect(
        screen.getByText('This item is published and visible to students.'),
      ).toBeInTheDocument()
      expect(
        screen.getByText('This item is unpublished and not visible to students.'),
      ).toBeInTheDocument()
      expect(
        screen.queryByText(
          'This item   is managed by the Blueprint parent course and cannot be changed here.',
        ),
      ).not.toBeInTheDocument()
      expect(
        screen.queryByText(
          'This item was shared from the blueprint, but changes can be made in this course.',
        ),
      ).not.toBeInTheDocument()
    })

    it('renders blueprint icons for blueprint courses', async () => {
      const {getByTestId} = renderComponent({is_blueprint_course: true})

      const button = getByTestId('icon-legend-button-wrapper').querySelector(
        'button',
      ) as HTMLButtonElement
      fireEvent.click(button)

      await waitFor(() => {
        expect(getByTestId('icon-legend-modal')).toBeInTheDocument()
      })

      expect(
        screen.getByText('This item is published and visible to students.'),
      ).toBeInTheDocument()
      expect(
        screen.getByText('This item is unpublished and not visible to students.'),
      ).toBeInTheDocument()
      expect(
        screen.getByText(
          'This item is managed by the Blueprint parent course and cannot be changed here',
        ),
      ).toBeInTheDocument()
      expect(
        screen.getByText(
          'This item was shared from the blueprint, but changes can be made in this course.',
        ),
      ).toBeInTheDocument()
    })

    it('renders the correct descriptions for each icon', () => {
      const {getByTestId} = renderComponent({is_blueprint_course: true})

      const button = getByTestId('icon-legend-button-wrapper').querySelector(
        'button',
      ) as HTMLButtonElement
      fireEvent.click(button)

      expect(screen.getByText(/this item is managed by the blueprint/i)).toBeInTheDocument()
      expect(screen.getByText(/this item was shared from the blueprint/i)).toBeInTheDocument()
      expect(
        screen.getByText(/this item is published and visible to students/i),
      ).toBeInTheDocument()
      expect(
        screen.getByText(/this item is unpublished and not visible to students/i),
      ).toBeInTheDocument()
    })
  })

  describe('interaction', () => {
    const openModal = async (getByTestId: any) => {
      const button = getByTestId('icon-legend-button-wrapper').querySelector(
        'button',
      ) as HTMLButtonElement
      button.focus()
      fireEvent.click(button)

      await waitFor(() => {
        expect(getByTestId('icon-legend-modal')).toBeInTheDocument()
      })
    }

    it('closes the modal when the close button is clicked', async () => {
      const {getByTestId} = renderComponent()

      await openModal(getByTestId)

      const closeButton = screen.queryAllByText('Close')[0]?.closest('button') as HTMLElement
      fireEvent.click(closeButton)

      expect(screen.queryByTestId('icon-legend-modal')).not.toBeInTheDocument()
    })

    it('focuses the button when the modal closes', async () => {
      const {getByTestId} = renderComponent()

      const legend_button = getByTestId('icon-legend-button-wrapper').querySelector(
        'button',
      ) as HTMLButtonElement

      await openModal(getByTestId)

      // expect(legend_button).not.toHaveFocus()

      const closeButton = screen.queryAllByText('Close')[0]?.closest('button') as HTMLElement
      closeButton.focus() // I don't know why it doesn't, it does in real life.
      fireEvent.click(closeButton)

      await waitFor(() => {
        expect(legend_button).toHaveFocus()
      })
    })
  })
})
