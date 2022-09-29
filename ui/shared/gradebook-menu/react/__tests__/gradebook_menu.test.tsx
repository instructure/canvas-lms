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
import GradebookMenu from '@canvas/gradebook-menu'
import {fireEvent, render} from '@testing-library/react'

function checkMenuItemContents(
  menuItems: HTMLElement[],
  expectedOptions: string[],
  expectedHrefs?: string[]
) {
  expect(menuItems).toHaveLength(expectedOptions.length)
  menuItems.forEach((item, index) => {
    expect(item).toHaveTextContent(expectedOptions[index])
  })

  if (expectedHrefs != null) {
    expect(menuItems).toHaveLength(expectedHrefs.length)
    menuItems.forEach((item, index) => {
      expect((item as HTMLAnchorElement).href).toContain(expectedHrefs[index])
    })
  }
}

describe('GradebookMenu', () => {
  const defaultProps = {
    courseUrl: '/courseUrl',
    learningMasteryEnabled: true,
    variant: 'DefaultGradebook',
  }

  describe('when variant is "DefaultGradebook"', () => {
    it('renders the expected options', () => {
      const {getAllByRole, getByRole} = render(<GradebookMenu {...defaultProps} />)
      const menu = getByRole('button')

      expect(menu).toHaveTextContent('Gradebook')
      fireEvent.click(menu)

      checkMenuItemContents(
        getAllByRole('menuitem'),
        ['Learning Mastery…', 'Individual Gradebook…', 'Gradebook History…'],
        [
          '/courseUrl/gradebook?view=learning_mastery',
          '/courseUrl/gradebook/change_gradebook_version?version=individual',
          '/courseUrl/gradebook/history',
        ]
      )
    })

    it('omits "Learning Mastery" when learningMasteryEnabled is false', () => {
      const {getAllByRole, getByRole} = render(
        <GradebookMenu {...defaultProps} learningMasteryEnabled={false} />
      )
      const menu = getByRole('button')
      fireEvent.click(menu)

      checkMenuItemContents(getAllByRole('menuitem'), [
        'Individual Gradebook…',
        'Gradebook History…',
      ])
    })
  })

  describe('when variant is "DefaultGradebookLearningMastery"', () => {
    it('renders the expected options', () => {
      const {getAllByRole, getByRole} = render(
        <GradebookMenu {...defaultProps} variant="DefaultGradebookLearningMastery" />
      )
      const menu = getByRole('button')
      expect(menu).toHaveTextContent('Learning Mastery')
      fireEvent.click(menu)

      checkMenuItemContents(
        getAllByRole('menuitem'),
        ['Gradebook…', 'Individual Gradebook…', 'Gradebook History…'],
        [
          '/courseUrl/gradebook?view=gradebook',
          '/courseUrl/gradebook/change_gradebook_version?version=individual',
          '/courseUrl/gradebook/history',
        ]
      )
    })
  })

  describe('when variant is "GradebookHistory"', () => {
    it('renders the expected options', () => {
      const {getAllByRole, getByRole} = render(
        <GradebookMenu {...defaultProps} variant="GradebookHistory" />
      )
      const menu = getByRole('button')

      expect(menu).toHaveTextContent('Gradebook History')
      fireEvent.click(menu)

      checkMenuItemContents(
        getAllByRole('menuitem'),
        ['Gradebook…', 'Individual Gradebook…', 'Learning Mastery…'],
        [
          '/courseUrl/gradebook?view=gradebook',
          '/courseUrl/gradebook/change_gradebook_version?version=individual',
          '/courseUrl/gradebook?view=learning_mastery',
        ]
      )
    })

    it('omits "Learning Mastery" when learningMasteryEnabled is false', () => {
      const {getAllByRole, getByRole} = render(
        <GradebookMenu
          {...defaultProps}
          variant="GradebookHistory"
          learningMasteryEnabled={false}
        />
      )
      const menu = getByRole('button')
      fireEvent.click(menu)

      checkMenuItemContents(getAllByRole('menuitem'), ['Gradebook…', 'Individual Gradebook…'])
    })
  })
})
