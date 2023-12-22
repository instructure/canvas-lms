/*
 * Copyright (C) 2021 - present Instructure, Inc.
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
import GradebookMenu from '../GradebookMenu'
import {Link} from '@instructure/ui-link'
import type {GradiantVariantName} from '../GradebookMenu'
import {fireEvent, render} from '@testing-library/react'

describe('GradebookMenu', () => {
  // EVAL-3711 Remove ICE Evaluate feature flag
  beforeEach(() => {
    window.ENV.FEATURES.instui_nav = true
  })
  const defaultProps = (props = {}) => ({
    courseUrl: '/courseUrl',
    learningMasteryEnabled: true,
    enhancedIndividualGradebookEnabled: undefined,
    variant: 'DefaultGradebook' as GradiantVariantName,
    ...props,
  })

  it('renders custom trigger if provided', () => {
    const customTrigger = <Link as="button">Custom Trigger</Link>
    const {getByText} = render(<GradebookMenu {...defaultProps({customTrigger})} />)

    const item = getByText('Custom Trigger')
    expect(item).toBeInTheDocument()
  })

  describe('when variant is "DefaultGradebook"', () => {
    // EVAL-3711 Remove ICE Evaluate feature flag
    it('renders the gradebook title when ICE feature flag is OFF', () => {
      window.ENV.FEATURES.instui_nav = false
      const {getByRole} = render(<GradebookMenu {...defaultProps()} />)
      const menu = getByRole('button')
      expect(menu).toHaveTextContent('Gradebook')
    })

    // EVAL-3711 Remove ICE Evaluate feature flag
    it('renders the gradebook title when ICE feature flag is ON', () => {
      const {getByTestId} = render(<GradebookMenu {...defaultProps()} />)
      expect(getByTestId('gradebook-title')).toHaveTextContent('Gradebook')
    })

    it('renders the expected options', () => {
      const {getAllByRole, getByRole} = render(<GradebookMenu {...defaultProps()} />)

      const menu = getByRole('button')
      fireEvent.click(menu)

      const menuItems = getAllByRole('menuitemradio')
      expect(menuItems).toHaveLength(4)
      expect(menuItems[0]).toHaveTextContent('Traditional Gradebook')
      expect(menuItems[1]).toHaveTextContent('Learning Mastery')
      expect(menuItems[2]).toHaveTextContent('Individual Gradebook')
      expect(menuItems[3]).toHaveTextContent('Gradebook History')
    })

    it('omits "Learning Mastery" when learningMasteryEnabled is false (1)', () => {
      const {getByRole, queryByTestId} = render(
        <GradebookMenu {...defaultProps()} learningMasteryEnabled={false} />
      )
      const menu = getByRole('button')
      fireEvent.click(menu)

      expect(queryByTestId('learning-mastery-menu-item')).not.toBeInTheDocument()
    })
  })

  describe('when variant is "DefaultGradebookLearningMastery"', () => {
    // EVAL-3711 Remove ICE Evaluate feature flag
    it('renders the gradebook title when ICE feature flag is OFF', () => {
      window.ENV.FEATURES.instui_nav = false
      const {getByRole} = render(
        <GradebookMenu {...defaultProps()} variant="DefaultGradebookLearningMastery" />
      )
      const menu = getByRole('button')
      expect(menu).toHaveTextContent('Learning Mastery')
    })

    // EVAL-3711 Remove ICE Evaluate feature flag
    it('renders the gradebook title when ICE feature flag is ON', () => {
      const {getByTestId} = render(
        <GradebookMenu {...defaultProps()} variant="DefaultGradebookLearningMastery" />
      )
      expect(getByTestId('gradebook-title')).toHaveTextContent('Learning Mastery')
    })

    it('renders the expected options', () => {
      const {getAllByRole, getByRole} = render(
        <GradebookMenu {...defaultProps()} variant="DefaultGradebookLearningMastery" />
      )

      const menu = getByRole('button')
      fireEvent.click(menu)

      const menuItems = getAllByRole('menuitemradio')
      expect(menuItems).toHaveLength(4)

      expect(menuItems[0]).toHaveTextContent('Traditional Gradebook')
      expect(menuItems[1]).toHaveTextContent('Learning Mastery')
      expect(menuItems[2]).toHaveTextContent('Individual Gradebook')
      expect(menuItems[3]).toHaveTextContent('Gradebook History')

      expect(menuItems[1]).toHaveAttribute('aria-checked', 'true')

      expect(menuItems[0]).toHaveAttribute(
        'href',
        '/courseUrl/gradebook/change_gradebook_version?version=gradebook'
      )
      expect(menuItems[1]).toHaveAttribute('href', '/courseUrl/gradebook?view=learning_mastery')
      expect(menuItems[2]).toHaveAttribute(
        'href',
        '/courseUrl/gradebook/change_gradebook_version?version=individual'
      )
      expect(menuItems[3]).toHaveAttribute('href', '/courseUrl/gradebook/history')
    })
  })

  describe('when variant is "GradebookHistory"', () => {
    // EVAL-3711 Remove ICE Evaluate feature flag
    it('renders the gradebook title when ICE feature flag is OFF', () => {
      window.ENV.FEATURES.instui_nav = false
      const {getByRole} = render(<GradebookMenu {...defaultProps()} variant="GradebookHistory" />)
      const menu = getByRole('button')
      expect(menu).toHaveTextContent('Gradebook History')
    })

    // EVAL-3711 Remove ICE Evaluate feature flag
    it('renders the gradebook title when ICE feature flag is ON', () => {
      const {getByTestId} = render(<GradebookMenu {...defaultProps()} variant="GradebookHistory" />)
      expect(getByTestId('gradebook-title')).toHaveTextContent('Gradebook History')
    })

    it('renders the expected options', () => {
      const {getAllByRole, getByRole} = render(
        <GradebookMenu {...defaultProps()} variant="GradebookHistory" />
      )

      const menu = getByRole('button')

      fireEvent.click(menu)

      const menuItems = getAllByRole('menuitemradio')
      expect(menuItems).toHaveLength(4)

      expect(menuItems[0]).toHaveTextContent('Traditional Gradebook')
      expect(menuItems[1]).toHaveTextContent('Learning Mastery')
      expect(menuItems[2]).toHaveTextContent('Individual Gradebook')
      expect(menuItems[3]).toHaveTextContent('Gradebook History')

      expect(menuItems[3]).toHaveAttribute('aria-checked', 'true')

      expect(menuItems[0]).toHaveAttribute(
        'href',
        '/courseUrl/gradebook/change_gradebook_version?version=gradebook'
      )
      expect(menuItems[1]).toHaveAttribute('href', '/courseUrl/gradebook?view=learning_mastery')
      expect(menuItems[2]).toHaveAttribute(
        'href',
        '/courseUrl/gradebook/change_gradebook_version?version=individual'
      )
      expect(menuItems[3]).toHaveAttribute('href', '/courseUrl/gradebook/history')
    })

    it('omits "Learning Mastery" when learningMasteryEnabled is false (2)', () => {
      const {getAllByRole, getByRole} = render(
        <GradebookMenu
          {...defaultProps()}
          variant="GradebookHistory"
          learningMasteryEnabled={false}
        />
      )
      const menu = getByRole('button')
      fireEvent.click(menu)

      const menuItems = getAllByRole('menuitemradio')
      expect(menuItems).toHaveLength(3)

      expect(menuItems[0]).toHaveTextContent('Traditional Gradebook')
      expect(menuItems[1]).toHaveTextContent('Individual Gradebook')
      expect(menuItems[2]).toHaveTextContent('Gradebook History')

      expect(menuItems[2]).toHaveAttribute('aria-checked', 'true')

      expect(menuItems[0]).toHaveAttribute(
        'href',
        '/courseUrl/gradebook/change_gradebook_version?version=gradebook'
      )
      expect(menuItems[1]).toHaveAttribute(
        'href',
        '/courseUrl/gradebook/change_gradebook_version?version=individual'
      )
      expect(menuItems[2]).toHaveAttribute('href', '/courseUrl/gradebook/history')
    })
  })
})
