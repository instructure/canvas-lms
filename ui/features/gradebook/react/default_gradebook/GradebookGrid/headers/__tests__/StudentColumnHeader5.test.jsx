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

import {render} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import React from 'react'
import studentRowHeaderConstants from '../../../constants/studentRowHeaderConstants'
import StudentColumnHeader from '../StudentColumnHeader'

describe('GradebookGrid StudentColumnHeader', () => {
  let props
  let gradebookElements

  const renderHeader = () => {
    return render(<StudentColumnHeader {...props} />)
  }

  beforeEach(() => {
    gradebookElements = []
    props = {
      addGradebookElement: $el => {
        gradebookElements.push($el)
      },
      disabled: false,
      onMenuDismiss: jest.fn(),
      onSelectPrimaryInfo: jest.fn(),
      onSelectSecondaryInfo: jest.fn(),
      onToggleEnrollmentFilter: jest.fn(),
      removeGradebookElement: $el => {
        gradebookElements.splice(gradebookElements.indexOf($el), 1)
      },
      sectionsEnabled: true,
      selectedEnrollmentFilters: [],
      selectedPrimaryInfo: studentRowHeaderConstants.defaultPrimaryInfo,
      selectedSecondaryInfo: studentRowHeaderConstants.defaultSecondaryInfo,
      sortBySetting: {
        direction: 'ascending',
        disabled: false,
        isSortColumn: true,
        onSortByIntegrationId: jest.fn(),
        onSortByLoginId: jest.fn(),
        onSortBySisId: jest.fn(),
        onSortBySortableName: jest.fn(),
        onSortInAscendingOrder: jest.fn(),
        onSortInDescendingOrder: jest.fn(),
        onSortBySortableNameAscending: jest.fn(),
        onSortBySortableNameDescending: jest.fn(),
        settingKey: 'sortable_name',
      },
      studentGroupsEnabled: true,
    }
  })

  describe('"Options" > "Show" setting', () => {
    describe('"Inactive enrollments" option', () => {
      it('is always present', async () => {
        const {getByRole} = renderHeader()
        await userEvent.click(getByRole('button', {name: 'Student Name Options'}))
        expect(getByRole('menuitemcheckbox', {name: 'Inactive enrollments'})).toBeInTheDocument()
      })

      it('is selected when showing inactive enrollments', async () => {
        props.selectedEnrollmentFilters = ['concluded', 'inactive']
        const {getByRole} = renderHeader()
        await userEvent.click(getByRole('button', {name: 'Student Name Options'}))
        expect(getByRole('menuitemcheckbox', {name: 'Inactive enrollments'})).toHaveAttribute(
          'aria-checked',
          'true',
        )
      })

      it('is not selected when not showing inactive enrollments', async () => {
        props.selectedEnrollmentFilters = ['concluded']
        const {getByRole} = renderHeader()
        await userEvent.click(getByRole('button', {name: 'Student Name Options'}))
        expect(getByRole('menuitemcheckbox', {name: 'Inactive enrollments'})).toHaveAttribute(
          'aria-checked',
          'false',
        )
      })

      it('is disabled when all options are disabled', async () => {
        props.disabled = true
        const {getByRole} = renderHeader()
        await userEvent.click(getByRole('button', {name: 'Student Name Options'}))
        expect(getByRole('menuitemcheckbox', {name: 'Inactive enrollments'})).toHaveAttribute(
          'aria-disabled',
          'true',
        )
      })

      describe('when clicked', () => {
        it('calls the onToggleEnrollmentFilter callback', async () => {
          const {getByRole} = renderHeader()
          await userEvent.click(getByRole('button', {name: 'Student Name Options'}))
          await userEvent.click(getByRole('menuitemcheckbox', {name: 'Inactive enrollments'}))
          expect(props.onToggleEnrollmentFilter).toHaveBeenCalledTimes(1)
        })

        it('includes "inactive" when calling the onToggleEnrollmentFilter callback', async () => {
          const {getByRole} = renderHeader()
          await userEvent.click(getByRole('button', {name: 'Student Name Options'}))
          await userEvent.click(getByRole('menuitemcheckbox', {name: 'Inactive enrollments'}))
          expect(props.onToggleEnrollmentFilter).toHaveBeenCalledWith('inactive')
        })

        it('returns focus to the "Options" menu trigger', async () => {
          const {getByRole} = renderHeader()
          const menuButton = getByRole('button', {name: 'Student Name Options'})
          await userEvent.click(menuButton)
          await userEvent.click(getByRole('menuitemcheckbox', {name: 'Inactive enrollments'}))
          expect(menuButton).toHaveFocus()
        })
      })
    })

    describe('"Concluded enrollments" option', () => {
      it('is always present', async () => {
        const {getByRole} = renderHeader()
        await userEvent.click(getByRole('button', {name: 'Student Name Options'}))
        expect(getByRole('menuitemcheckbox', {name: 'Concluded enrollments'})).toBeInTheDocument()
      })

      it('is selected when showing concluded enrollments', async () => {
        props.selectedEnrollmentFilters = ['concluded', 'inactive']
        const {getByRole} = renderHeader()
        await userEvent.click(getByRole('button', {name: 'Student Name Options'}))
        expect(getByRole('menuitemcheckbox', {name: 'Concluded enrollments'})).toHaveAttribute(
          'aria-checked',
          'true',
        )
      })

      it('is not selected when not showing concluded enrollments', async () => {
        props.selectedEnrollmentFilters = ['inactive']
        const {getByRole} = renderHeader()
        await userEvent.click(getByRole('button', {name: 'Student Name Options'}))
        expect(getByRole('menuitemcheckbox', {name: 'Concluded enrollments'})).toHaveAttribute(
          'aria-checked',
          'false',
        )
      })

      it('is disabled when all options are disabled', async () => {
        props.disabled = true
        const {getByRole} = renderHeader()
        await userEvent.click(getByRole('button', {name: 'Student Name Options'}))
        expect(getByRole('menuitemcheckbox', {name: 'Concluded enrollments'})).toHaveAttribute(
          'aria-disabled',
          'true',
        )
      })

      describe('when clicked', () => {
        it('calls the onToggleEnrollmentFilter callback', async () => {
          const {getByRole} = renderHeader()
          await userEvent.click(getByRole('button', {name: 'Student Name Options'}))
          await userEvent.click(getByRole('menuitemcheckbox', {name: 'Concluded enrollments'}))
          expect(props.onToggleEnrollmentFilter).toHaveBeenCalledTimes(1)
        })

        it('includes "concluded" when calling the onToggleEnrollmentFilter callback', async () => {
          const {getByRole} = renderHeader()
          await userEvent.click(getByRole('button', {name: 'Student Name Options'}))
          await userEvent.click(getByRole('menuitemcheckbox', {name: 'Concluded enrollments'}))
          expect(props.onToggleEnrollmentFilter).toHaveBeenCalledWith('concluded')
        })

        it('returns focus to the "Options" menu trigger', async () => {
          const {getByRole} = renderHeader()
          const menuButton = getByRole('button', {name: 'Student Name Options'})
          await userEvent.click(menuButton)
          await userEvent.click(getByRole('menuitemcheckbox', {name: 'Concluded enrollments'}))
          expect(menuButton).toHaveFocus()
        })
      })
    })
  })

  describe('keyboard navigation', () => {
    describe('when the "Options" menu trigger has focus', () => {
      it('does not handle Tab', async () => {
        const {getByRole} = renderHeader()
        const menuButton = getByRole('button', {name: 'Student Name Options'})
        menuButton.focus()
        await userEvent.tab()
        expect(menuButton).not.toHaveFocus()
      })

      it('does not handle Shift+Tab', async () => {
        const {getByRole} = renderHeader()
        const menuButton = getByRole('button', {name: 'Student Name Options'})
        menuButton.focus()
        await userEvent.tab({shift: true})
        expect(menuButton).not.toHaveFocus()
      })

      it('Enter opens the "Options" menu', async () => {
        const {getByRole} = renderHeader()
        const menuButton = getByRole('button', {name: 'Student Name Options'})
        menuButton.focus()
        await userEvent.keyboard('{Enter}')
        expect(getByRole('menuitemcheckbox', {name: 'Inactive enrollments'})).toBeInTheDocument()
      })
    })
  })

  describe('focus management', () => {
    it('sets focus on the "Options" menu trigger', () => {
      const {getByRole} = renderHeader()
      const menuButton = getByRole('button', {name: 'Student Name Options'})
      menuButton.focus()
      expect(menuButton).toHaveFocus()
    })

    it('adds the "focused" class to the header when the "Options" menu trigger receives focus', () => {
      const {getByRole, container} = renderHeader()
      const menuButton = getByRole('button', {name: 'Student Name Options'})
      menuButton.focus()
      expect(container.firstChild).toHaveClass('focused')
    })

    it('removes the "focused" class from the header when focus leaves', () => {
      const {getByRole, container} = renderHeader()
      const menuButton = getByRole('button', {name: 'Student Name Options'})
      menuButton.focus()
      menuButton.blur()
      expect(container.firstChild).not.toHaveClass('focused')
    })
  })
})
