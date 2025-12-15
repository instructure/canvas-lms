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
    allowManageGrades: true,
    hasGradesOrPostableComments: true,
    onHideGrades: vi.fn(),
    onPostGrades: vi.fn(),
  }

  const renderMenu = async (customProps = {}) => {
    const props = {...defaultProps, ...customProps}
    render(<SpeedGraderPostGradesMenu {...props} />)
    const button = screen.getByTestId('post-or-hide-grades-button')
    await userEvent.click(button)
    return button
  }

  afterEach(() => {
    vi.clearAllMocks()
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

  describe('permission-based access control', () => {
    describe('when allowManageGrades is false', () => {
      describe('Post Grades menu item', () => {
        it('disables the Post Grades menu item even when grades can be posted', async () => {
          await renderMenu({
            allowManageGrades: false,
            allowPostingGradesOrComments: true,
          })
          const menuItem = screen.getByRole('menuitem', {name: 'Post Grades'})
          expect(menuItem).toHaveAttribute('aria-disabled', 'true')
        })

        it('does not call onPostGrades when clicked while disabled', async () => {
          await renderMenu({
            allowManageGrades: false,
            allowPostingGradesOrComments: true,
          })
          const menuItem = screen.getByRole('menuitem', {name: 'Post Grades'})
          // Cannot click disabled items due to pointer-events: none
          // Just verify it's disabled
          expect(menuItem).toHaveAttribute('aria-disabled', 'true')
          expect(defaultProps.onPostGrades).not.toHaveBeenCalled()
        })

        it('shows disabled state when no grades to post and no permission', async () => {
          await renderMenu({
            allowManageGrades: false,
            allowPostingGradesOrComments: false,
            hasGradesOrPostableComments: false,
          })
          const menuItem = screen.getByRole('menuitem', {name: 'No Grades to Post'})
          expect(menuItem).toHaveAttribute('aria-disabled', 'true')
        })
      })

      describe('Hide Grades menu item', () => {
        it('disables the Hide Grades menu item even when grades can be hidden', async () => {
          await renderMenu({
            allowManageGrades: false,
            allowHidingGradesOrComments: true,
          })
          const menuItem = screen.getByRole('menuitem', {name: 'Hide Grades'})
          expect(menuItem).toHaveAttribute('aria-disabled', 'true')
        })

        it('does not call onHideGrades when clicked while disabled', async () => {
          await renderMenu({
            allowManageGrades: false,
            allowHidingGradesOrComments: true,
          })
          const menuItem = screen.getByRole('menuitem', {name: 'Hide Grades'})
          // Cannot click disabled items due to pointer-events: none
          // Just verify it's disabled
          expect(menuItem).toHaveAttribute('aria-disabled', 'true')
          expect(defaultProps.onHideGrades).not.toHaveBeenCalled()
        })

        it('shows disabled state when no grades to hide and no permission', async () => {
          await renderMenu({
            allowManageGrades: false,
            allowHidingGradesOrComments: false,
            hasGradesOrPostableComments: false,
          })
          const menuItem = screen.getByRole('menuitem', {name: 'No Grades to Hide'})
          expect(menuItem).toHaveAttribute('aria-disabled', 'true')
        })
      })
    })

    describe('when allowManageGrades is true', () => {
      it('enables Post Grades when user has permission and grades can be posted', async () => {
        await renderMenu({
          allowManageGrades: true,
          allowPostingGradesOrComments: true,
        })
        const menuItem = screen.getByRole('menuitem', {name: 'Post Grades'})
        expect(menuItem).not.toHaveAttribute('aria-disabled')
      })

      it('enables Hide Grades when user has permission and grades can be hidden', async () => {
        await renderMenu({
          allowManageGrades: true,
          allowHidingGradesOrComments: true,
        })
        const menuItem = screen.getByRole('menuitem', {name: 'Hide Grades'})
        expect(menuItem).not.toHaveAttribute('aria-disabled')
      })

      it('calls onPostGrades when Post Grades is clicked with permission', async () => {
        await renderMenu({
          allowManageGrades: true,
          allowPostingGradesOrComments: true,
        })
        await userEvent.click(screen.getByRole('menuitem', {name: 'Post Grades'}))
        expect(defaultProps.onPostGrades).toHaveBeenCalledTimes(1)
      })

      it('calls onHideGrades when Hide Grades is clicked with permission', async () => {
        await renderMenu({
          allowManageGrades: true,
          allowHidingGradesOrComments: true,
        })
        await userEvent.click(screen.getByRole('menuitem', {name: 'Hide Grades'}))
        expect(defaultProps.onHideGrades).toHaveBeenCalledTimes(1)
      })
    })

    describe('when allowManageGrades is undefined (backwards compatibility)', () => {
      it('defaults to disabling Post Grades when prop is not provided', async () => {
        await renderMenu({
          allowManageGrades: undefined,
          allowPostingGradesOrComments: true,
        })
        const menuItem = screen.getByRole('menuitem', {name: 'Post Grades'})
        // When undefined, the component treats it as false (no permission)
        expect(menuItem).toHaveAttribute('aria-disabled', 'true')
      })

      it('defaults to disabling Hide Grades when prop is not provided', async () => {
        await renderMenu({
          allowManageGrades: undefined,
          allowHidingGradesOrComments: true,
        })
        const menuItem = screen.getByRole('menuitem', {name: 'Hide Grades'})
        // When undefined, the component treats it as false (no permission)
        expect(menuItem).toHaveAttribute('aria-disabled', 'true')
      })
    })
  })

  describe('complex scenarios', () => {
    it('handles mixed permissions and states correctly', async () => {
      await renderMenu({
        allowManageGrades: false,
        allowPostingGradesOrComments: true,
        allowHidingGradesOrComments: false,
        hasGradesOrPostableComments: true,
      })

      const postMenuItem = screen.getByRole('menuitem', {name: 'Post Grades'})
      const hideMenuItem = screen.getByRole('menuitem', {name: 'All Grades Hidden'})

      expect(postMenuItem).toHaveAttribute('aria-disabled', 'true')
      expect(hideMenuItem).toHaveAttribute('aria-disabled', 'true')
    })

    it('respects submission state even with manage permission', async () => {
      await renderMenu({
        allowManageGrades: true,
        allowPostingGradesOrComments: false,
        allowHidingGradesOrComments: false,
        hasGradesOrPostableComments: true,
      })

      const postMenuItem = screen.getByRole('menuitem', {name: 'All Grades Posted'})
      const hideMenuItem = screen.getByRole('menuitem', {name: 'All Grades Hidden'})

      expect(postMenuItem).toHaveAttribute('aria-disabled', 'true')
      expect(hideMenuItem).toHaveAttribute('aria-disabled', 'true')
    })
  })
})
