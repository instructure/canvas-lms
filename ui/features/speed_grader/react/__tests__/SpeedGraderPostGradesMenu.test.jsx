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

import React from 'react'
import {render, screen} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import SpeedGraderPostGradesMenu from '../SpeedGraderPostGradesMenu'

describe('SpeedGraderPostGradesMenu', () => {
  const defaultProps = {
    allowHidingGradesOrComments: true,
    allowPostingGradesOrComments: true,
    hasGradesOrPostableComments: true,
    onHideGrades: jest.fn(),
    onPostGrades: jest.fn(),
  }

  const renderMenu = async (customProps = {}) => {
    const props = {...defaultProps, ...customProps}
    render(<SpeedGraderPostGradesMenu {...props} />)
    const button = screen.getByTestId('post-or-hide-grades-button')
    await userEvent.click(button)
    return button
  }

  afterEach(() => {
    jest.clearAllMocks()
  })

  describe('menu trigger', () => {
    it('renders as an "off" icon when allowPostingGradesOrComments is true', async () => {
      const button = await renderMenu()
      expect(button.querySelector('svg[name="IconOff"]')).toBeInTheDocument()
    })

    it('renders as an "eye" icon when allowPostingGradesOrComments is false', async () => {
      const button = await renderMenu({allowPostingGradesOrComments: false})
      expect(button.querySelector('svg[name="IconEye"]')).toBeInTheDocument()
    })
  })

  describe('Post Grades menu item', () => {
    describe('when allowPostingGradesOrComments is true', () => {
      it('shows "Post Grades" text', async () => {
        await renderMenu()
        expect(screen.getByRole('menuitem', {name: 'Post Grades'})).toBeInTheDocument()
      })

      it('enables the menu item', async () => {
        await renderMenu()
        expect(screen.getByRole('menuitem', {name: 'Post Grades'})).not.toHaveAttribute(
          'aria-disabled',
        )
      })

      it('calls onPostGrades when clicked', async () => {
        await renderMenu()
        await userEvent.click(screen.getByRole('menuitem', {name: 'Post Grades'}))
        expect(defaultProps.onPostGrades).toHaveBeenCalledTimes(1)
      })
    })

    describe('when allowPostingGradesOrComments is false', () => {
      describe('when hasGradesOrPostableComments is false', () => {
        it('shows "No Grades to Post" text and disables the menu item', async () => {
          await renderMenu({
            allowPostingGradesOrComments: false,
            hasGradesOrPostableComments: false,
          })
          const menuItem = screen.getByRole('menuitem', {name: 'No Grades to Post'})
          expect(menuItem).toBeInTheDocument()
          expect(menuItem).toHaveAttribute('aria-disabled', 'true')
        })
      })

      describe('when hasGradesOrPostableComments is true', () => {
        it('shows "All Grades Posted" text and disables the menu item', async () => {
          await renderMenu({
            allowPostingGradesOrComments: false,
            hasGradesOrPostableComments: true,
          })
          const menuItem = screen.getByRole('menuitem', {name: 'All Grades Posted'})
          expect(menuItem).toBeInTheDocument()
          expect(menuItem).toHaveAttribute('aria-disabled', 'true')
        })
      })
    })
  })

  describe('Hide Grades menu item', () => {
    describe('when allowHidingGradesOrComments is true', () => {
      it('shows "Hide Grades" text', async () => {
        await renderMenu()
        expect(screen.getByRole('menuitem', {name: 'Hide Grades'})).toBeInTheDocument()
      })

      it('enables the menu item', async () => {
        await renderMenu()
        expect(screen.getByRole('menuitem', {name: 'Hide Grades'})).not.toHaveAttribute(
          'aria-disabled',
        )
      })

      it('calls onHideGrades when clicked', async () => {
        await renderMenu()
        await userEvent.click(screen.getByRole('menuitem', {name: 'Hide Grades'}))
        expect(defaultProps.onHideGrades).toHaveBeenCalledTimes(1)
      })
    })

    describe('when allowHidingGradesOrComments is false', () => {
      describe('when hasGradesOrPostableComments is false', () => {
        it('shows "No Grades to Hide" text and disables the menu item', async () => {
          await renderMenu({
            allowHidingGradesOrComments: false,
            hasGradesOrPostableComments: false,
          })
          const menuItem = screen.getByRole('menuitem', {name: 'No Grades to Hide'})
          expect(menuItem).toBeInTheDocument()
          expect(menuItem).toHaveAttribute('aria-disabled', 'true')
        })
      })

      describe('when hasGradesOrPostableComments is true', () => {
        it('shows "All Grades Hidden" text and disables the menu item', async () => {
          await renderMenu({
            allowHidingGradesOrComments: false,
            hasGradesOrPostableComments: true,
          })
          const menuItem = screen.getByRole('menuitem', {name: 'All Grades Hidden'})
          expect(menuItem).toBeInTheDocument()
          expect(menuItem).toHaveAttribute('aria-disabled', 'true')
        })
      })
    })
  })
})
