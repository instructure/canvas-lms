/*
 * Copyright (C) 2026 - present Instructure, Inc.
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
import SuppressNotifications, {type SuppressNotificationsProps} from '..'

const MAIN_CHECKBOX_LABEL = 'Suppress notifications from being created and sent out'

const defaultCategories = [
  {slug: 'announcement', displayName: 'Announcement'},
  {slug: 'due_date', displayName: 'Due Date'},
  {slug: 'grading', displayName: 'Grading'},
  {slug: 'submission_comment', displayName: 'Submission Comment'},
]

function renderComponent(overrideProps: Partial<SuppressNotificationsProps> = {}) {
  const props: SuppressNotificationsProps = {
    suppressNotifications: false,
    notificationCategories: defaultCategories,
    ...overrideProps,
  }
  let mountPoint = document.getElementById('suppress-notifications-mount')
  if (!mountPoint) {
    mountPoint = document.createElement('div')
    mountPoint.id = 'suppress-notifications-mount'
    document.body.appendChild(mountPoint)
  }
  return render(<SuppressNotifications {...props} />, {container: mountPoint})
}

function getHiddenInputs(container: HTMLElement) {
  return Array.from(container.querySelectorAll<HTMLInputElement>('input[type="hidden"]'))
}

describe('SuppressNotifications', () => {
  describe('initial rendering', () => {
    it('renders the main suppress checkbox unchecked by default', () => {
      renderComponent()
      expect(screen.getByLabelText(MAIN_CHECKBOX_LABEL)).not.toBeChecked()
    })

    it('does not show scope options when unchecked', () => {
      renderComponent()
      expect(screen.queryByLabelText('All notifications')).not.toBeInTheDocument()
    })

    it('checks the main checkbox when suppressNotifications is true', () => {
      renderComponent({suppressNotifications: true})
      expect(screen.getByLabelText(MAIN_CHECKBOX_LABEL)).toBeChecked()
    })

    it('selects "All notifications" radio when suppressNotifications is true', () => {
      renderComponent({suppressNotifications: true})
      expect(screen.getByLabelText('All notifications')).toBeChecked()
      expect(screen.getByLabelText('Specific categories only')).not.toBeChecked()
    })

    it('selects "Specific categories only" radio when suppressNotifications is an array', () => {
      renderComponent({suppressNotifications: ['grading', 'announcement']})
      expect(screen.getByLabelText('Specific categories only')).toBeChecked()
    })

    it('shows the category count in the button when initialized with an array', () => {
      renderComponent({suppressNotifications: ['grading', 'announcement']})
      expect(screen.getByTestId('edit-categories-button')).toHaveTextContent(
        'Edit categories (2 selected)',
      )
    })
  })

  describe('interactions', () => {
    it('shows scope radio buttons when main checkbox is checked', async () => {
      renderComponent()
      await userEvent.click(screen.getByLabelText(MAIN_CHECKBOX_LABEL))
      expect(screen.getByLabelText('All notifications')).toBeInTheDocument()
      expect(screen.getByLabelText('Specific categories only')).toBeInTheDocument()
    })

    it('hides scope options when main checkbox is unchecked', async () => {
      renderComponent({suppressNotifications: true})
      await userEvent.click(screen.getByLabelText(MAIN_CHECKBOX_LABEL))
      expect(screen.queryByLabelText('All notifications')).not.toBeInTheDocument()
    })

    it('shows "Choose categories" button when "Specific categories only" is selected', async () => {
      renderComponent({suppressNotifications: true})
      await userEvent.click(screen.getByLabelText('Specific categories only'))
      expect(screen.getByTestId('edit-categories-button')).toHaveTextContent(
        'Choose categories\u2026',
      )
    })

    it('opens the modal when the categories button is clicked', async () => {
      renderComponent({suppressNotifications: true})
      await userEvent.click(screen.getByLabelText('Specific categories only'))
      await userEvent.click(screen.getByTestId('edit-categories-button'))
      expect(screen.getByTestId('save-button')).toBeInTheDocument()
    })

    it('pre-checks the correct categories in the modal from the initial array', async () => {
      renderComponent({suppressNotifications: ['grading', 'announcement']})
      await userEvent.click(screen.getByTestId('edit-categories-button'))
      expect(screen.getByLabelText('Grading')).toBeChecked()
      expect(screen.getByLabelText('Announcement')).toBeChecked()
      expect(screen.getByLabelText('Due Date')).not.toBeChecked()
    })

    it('saves category selections when modal Save is clicked', async () => {
      renderComponent({suppressNotifications: true})
      await userEvent.click(screen.getByLabelText('Specific categories only'))
      await userEvent.click(screen.getByTestId('edit-categories-button'))
      await userEvent.click(screen.getByLabelText('Grading'))
      await userEvent.click(screen.getByTestId('save-button'))
      expect(screen.getByTestId('edit-categories-button')).toHaveTextContent(
        'Edit categories (1 selected)',
      )
    })

    it('discards pending changes when modal Cancel is clicked', async () => {
      renderComponent({suppressNotifications: ['grading']})
      await userEvent.click(screen.getByTestId('edit-categories-button'))
      await userEvent.click(screen.getByLabelText('Grading'))
      await userEvent.click(screen.getByTestId('cancel-button'))
      expect(screen.getByTestId('edit-categories-button')).toHaveTextContent(
        'Edit categories (1 selected)',
      )
    })

    it('resets to "All notifications" when main checkbox is unchecked and rechecked', async () => {
      renderComponent({suppressNotifications: ['grading']})
      expect(screen.getByLabelText('Specific categories only')).toBeChecked()
      await userEvent.click(screen.getByLabelText(MAIN_CHECKBOX_LABEL))
      await userEvent.click(screen.getByLabelText(MAIN_CHECKBOX_LABEL))
      expect(screen.getByLabelText('All notifications')).toBeChecked()
    })

    it('clears category selections when main checkbox is unchecked and rechecked', async () => {
      renderComponent({suppressNotifications: ['grading']})
      await userEvent.click(screen.getByLabelText(MAIN_CHECKBOX_LABEL))
      await userEvent.click(screen.getByLabelText(MAIN_CHECKBOX_LABEL))
      await userEvent.click(screen.getByLabelText('Specific categories only'))
      expect(screen.getByTestId('edit-categories-button')).toHaveTextContent(
        'Choose categories\u2026',
      )
    })
  })

  describe('hidden form fields', () => {
    it('writes "0" when suppression is disabled', () => {
      const {container} = renderComponent({suppressNotifications: false})
      const inputs = getHiddenInputs(container)
      expect(inputs).toHaveLength(1)
      expect(inputs[0].name).toBe('account[settings][suppress_notifications]')
      expect(inputs[0].value).toBe('0')
    })

    it('writes "1" when suppress-all is enabled', () => {
      const {container} = renderComponent({suppressNotifications: true})
      const inputs = getHiddenInputs(container)
      expect(inputs).toHaveLength(1)
      expect(inputs[0].name).toBe('account[settings][suppress_notifications]')
      expect(inputs[0].value).toBe('1')
    })

    it('writes array fields when specific categories are selected', () => {
      const {container} = renderComponent({
        suppressNotifications: ['grading', 'announcement'],
      })
      const inputs = getHiddenInputs(container)
      expect(inputs).toHaveLength(2)
      const values = inputs.map(i => i.value).sort()
      expect(values).toEqual(['announcement', 'grading'])
      expect(inputs[0].name).toBe('account[settings][suppress_notifications][]')
    })

    it('updates hidden fields to "1" when main checkbox is checked', async () => {
      const {container} = renderComponent({suppressNotifications: false})
      await userEvent.click(screen.getByLabelText(MAIN_CHECKBOX_LABEL))
      const inputs = getHiddenInputs(container)
      expect(inputs).toHaveLength(1)
      expect(inputs[0].value).toBe('1')
    })

    it('updates hidden fields when saving category selections in the modal', async () => {
      const {container} = renderComponent({suppressNotifications: ['grading']})
      await userEvent.click(screen.getByTestId('edit-categories-button'))
      await userEvent.click(screen.getByLabelText('Announcement'))
      await userEvent.click(screen.getByTestId('save-button'))
      const inputs = getHiddenInputs(container)
      expect(inputs).toHaveLength(2)
      const values = inputs.map(i => i.value).sort()
      expect(values).toEqual(['announcement', 'grading'])
    })

    it('writes "1" when specific mode is active but no categories are selected', async () => {
      const {container} = renderComponent({suppressNotifications: ['grading']})
      await userEvent.click(screen.getByTestId('edit-categories-button'))
      await userEvent.click(screen.getByLabelText('Grading'))
      await userEvent.click(screen.getByTestId('save-button'))
      const inputs = getHiddenInputs(container)
      expect(inputs).toHaveLength(1)
      expect(inputs[0].value).toBe('1')
    })
  })

  describe('form validation', () => {
    const originalConfirm = window.confirm

    beforeEach(() => {
      window.confirm = vi.fn(() => true)
    })

    afterEach(() => {
      window.confirm = originalConfirm
    })

    function getMountValidator() {
      return (
        document.getElementById('suppress-notifications-mount') as HTMLElement & {
          __performValidation: () => boolean
        }
      ).__performValidation
    }

    it('attaches __performValidation to the mount element', () => {
      renderComponent({suppressNotifications: true})
      expect(typeof getMountValidator()).toBe('function')
    })

    it('shows confirmation when user newly enables suppress-all', async () => {
      renderComponent({suppressNotifications: false})
      await userEvent.click(screen.getByLabelText(MAIN_CHECKBOX_LABEL))
      const result = getMountValidator()()
      expect(window.confirm).toHaveBeenCalledOnce()
      expect(result).toBe(true)
    })

    it('blocks submission when confirmation is declined', async () => {
      vi.mocked(window.confirm).mockReturnValue(false)
      renderComponent({suppressNotifications: false})
      await userEvent.click(screen.getByLabelText(MAIN_CHECKBOX_LABEL))
      const result = getMountValidator()()
      expect(result).toBe(false)
    })

    it('does not show confirmation when suppress-all was already saved', () => {
      renderComponent({suppressNotifications: true})
      const result = getMountValidator()()
      expect(window.confirm).not.toHaveBeenCalled()
      expect(result).toBe(true)
    })

    it('does not show confirmation when suppression is disabled', () => {
      renderComponent({suppressNotifications: false})
      const result = getMountValidator()()
      expect(window.confirm).not.toHaveBeenCalled()
      expect(result).toBe(true)
    })

    it('does not show confirmation when granular categories are selected', () => {
      renderComponent({suppressNotifications: ['grading']})
      const result = getMountValidator()()
      expect(window.confirm).not.toHaveBeenCalled()
      expect(result).toBe(true)
    })

    it('shows confirmation when switching from specific to all-notifications', async () => {
      renderComponent({suppressNotifications: ['grading']})
      await userEvent.click(screen.getByLabelText('All notifications'))
      const result = getMountValidator()()
      expect(window.confirm).toHaveBeenCalledOnce()
      expect(result).toBe(true)
    })
  })
})
