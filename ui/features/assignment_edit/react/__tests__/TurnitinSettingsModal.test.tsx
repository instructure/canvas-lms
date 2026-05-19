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
import {act, render, screen, waitFor} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import TurnitinSettingsModal from '../TurnitinSettingsModal'
import type {
  TurnitinSettingsModalProps,
  TurnitinSettingsModalHandle,
  DialogState,
} from '../TurnitinSettingsModal'

const defaultTurnitinSettings: DialogState = {
  type: 'turnitin',
  settings: {
    originality_report_visibility: 'immediate',
    s_paper_check: true,
    internet_check: true,
    journal_check: true,
    exclude_biblio: true,
    exclude_quoted: true,
    exclude_small_matches_type: null,
    exclude_small_matches_value: 0,
    submit_papers_to: true,
  },
}

const defaultVeriCiteSettings: DialogState = {
  type: 'vericite',
  settings: {
    originality_report_visibility: 'immediate',
    exclude_quoted: true,
    exclude_self_plag: false,
    store_in_index: true,
  },
}

function renderModal(onSettingsChange: TurnitinSettingsModalProps['onSettingsChange'] = () => {}) {
  const ref = React.createRef<TurnitinSettingsModalHandle>()
  render(<TurnitinSettingsModal ref={ref} onSettingsChange={onSettingsChange} />)
  return ref
}

function openModal(ref: React.RefObject<TurnitinSettingsModalHandle | null>, dialog: DialogState) {
  act(() => ref.current!.open(dialog))
}

function getWordsRadio() {
  return document.querySelector('input[type="radio"][value="words"]') as HTMLInputElement
}

function getPercentRadio() {
  return document.querySelector('input[type="radio"][value="percent"]') as HTMLInputElement
}

function clickButton(name: string) {
  const btn = screen.getByText(name).closest('button') as HTMLElement
  return userEvent.setup().click(btn)
}

describe('TurnitinSettingsModal', () => {
  describe('Scenario 1: Turnitin dialog — default settings', () => {
    it('renders the modal with Turnitin title', () => {
      const ref = renderModal()
      openModal(ref, defaultTurnitinSettings)
      expect(screen.getByText('Advanced Turnitin Settings')).toBeInTheDocument()
    })

    it('renders originality report visibility dropdown', () => {
      const ref = renderModal()
      openModal(ref, defaultTurnitinSettings)
      expect(screen.getByLabelText('Students Can See the Originality Report')).toBeInTheDocument()
    })

    it('renders "Compare Against" checkboxes', () => {
      const ref = renderModal()
      openModal(ref, defaultTurnitinSettings)
      expect(screen.getByLabelText('Other Student Papers')).toBeInTheDocument()
      expect(screen.getByLabelText('Internet Database')).toBeInTheDocument()
      expect(screen.getByLabelText('Journals, Periodicals, and Publications')).toBeInTheDocument()
    })

    it('renders "Do Not Consider" checkboxes', () => {
      const ref = renderModal()
      openModal(ref, defaultTurnitinSettings)
      expect(screen.getByLabelText('Bibliographic Material')).toBeInTheDocument()
      expect(screen.getByLabelText('Quoted Material')).toBeInTheDocument()
      expect(screen.getByLabelText('Small Matches')).toBeInTheDocument()
    })

    it('renders repository checkbox', () => {
      const ref = renderModal()
      openModal(ref, defaultTurnitinSettings)
      expect(screen.getByLabelText('Include in Repository')).toBeInTheDocument()
    })

    it('renders Update Settings and Cancel buttons', () => {
      const ref = renderModal()
      openModal(ref, defaultTurnitinSettings)
      expect(screen.getByText('Update Settings')).toBeInTheDocument()
      expect(screen.getByText('Cancel')).toBeInTheDocument()
    })
  })

  describe('Scenario 2: Turnitin dialog — existing settings', () => {
    it('pre-populates saved values', () => {
      const ref = renderModal()
      const dialog: DialogState = {
        type: 'turnitin',
        settings: {
          ...defaultTurnitinSettings.settings,
          originality_report_visibility: 'after_grading',
          s_paper_check: false,
          internet_check: true,
          exclude_biblio: false,
          submit_papers_to: false,
        },
      }
      openModal(ref, dialog)
      expect(screen.getByLabelText('Students Can See the Originality Report')).toHaveValue(
        'after_grading',
      )
      expect(screen.getByLabelText('Other Student Papers')).not.toBeChecked()
      expect(screen.getByLabelText('Internet Database')).toBeChecked()
      expect(screen.getByLabelText('Bibliographic Material')).not.toBeChecked()
      expect(screen.getByLabelText('Include in Repository')).not.toBeChecked()
    })
  })

  describe('Scenario 3: Exclude small matches by words', () => {
    it('shows word count input when "Small Matches" is checked and "Words" is selected', () => {
      const ref = renderModal()
      const dialog: DialogState = {
        type: 'turnitin',
        settings: {
          ...defaultTurnitinSettings.settings,
          exclude_small_matches_type: 'words',
          exclude_small_matches_value: 5,
        },
      }
      openModal(ref, dialog)
      expect(screen.getByLabelText('Small Matches')).toBeChecked()
      expect(getWordsRadio().checked).toBe(true)
      expect(screen.getByLabelText('Number of words')).toHaveValue(5)
    })

    it('defaults to "Words" radio when checking Small Matches with no prior type', async () => {
      const user = userEvent.setup()
      const ref = renderModal()
      openModal(ref, defaultTurnitinSettings)
      await user.click(screen.getByLabelText('Small Matches'))
      expect(getWordsRadio().checked).toBe(true)
    })
  })

  describe('Scenario 4: Exclude small matches by percent', () => {
    it('shows percent input when "Percent" radio is selected', () => {
      const ref = renderModal()
      const dialog: DialogState = {
        type: 'turnitin',
        settings: {
          ...defaultTurnitinSettings.settings,
          exclude_small_matches_type: 'percent',
          exclude_small_matches_value: 10,
        },
      }
      openModal(ref, dialog)
      expect(getPercentRadio().checked).toBe(true)
      expect(screen.getByLabelText('Percentage of document')).toHaveValue(10)
    })
  })

  describe('Scenario 5: Validation — empty value', () => {
    it('shows error when submitting with empty word count', async () => {
      const user = userEvent.setup()
      const ref = renderModal()
      const dialog: DialogState = {
        type: 'turnitin',
        settings: {
          ...defaultTurnitinSettings.settings,
          exclude_small_matches_type: 'words',
          exclude_small_matches_value: 0,
        },
      }
      openModal(ref, dialog)
      const input = screen.getByLabelText('Number of words')
      await user.clear(input)
      await clickButton('Update Settings')
      expect(screen.getByText('Value must not be empty')).toBeInTheDocument()
    })

    it('does not call onSettingsChange when validation fails', async () => {
      const user = userEvent.setup()
      const onSettingsChange = vi.fn()
      const ref = renderModal(onSettingsChange)
      const dialog: DialogState = {
        type: 'turnitin',
        settings: {
          ...defaultTurnitinSettings.settings,
          exclude_small_matches_type: 'words',
          exclude_small_matches_value: 0,
        },
      }
      openModal(ref, dialog)
      const input = screen.getByLabelText('Number of words')
      await user.clear(input)
      await clickButton('Update Settings')
      expect(onSettingsChange).not.toHaveBeenCalled()
    })
  })

  describe('Scenario 6: Validation — non-integer', () => {
    it('shows error for decimal value on blur', async () => {
      const user = userEvent.setup()
      const ref = renderModal()
      const dialog: DialogState = {
        type: 'turnitin',
        settings: {
          ...defaultTurnitinSettings.settings,
          exclude_small_matches_type: 'words',
          exclude_small_matches_value: 0,
        },
      }
      openModal(ref, dialog)
      const input = screen.getByLabelText('Number of words')
      await user.clear(input)
      await user.type(input, '3.5')
      await user.tab()
      expect(screen.getByText('Value must be a whole number')).toBeInTheDocument()
    })
  })

  describe('Scenario 7: Validation — zero/negative', () => {
    it('shows error for zero value on blur', async () => {
      const user = userEvent.setup()
      const ref = renderModal()
      const dialog: DialogState = {
        type: 'turnitin',
        settings: {
          ...defaultTurnitinSettings.settings,
          exclude_small_matches_type: 'words',
          exclude_small_matches_value: 0,
        },
      }
      openModal(ref, dialog)
      const input = screen.getByLabelText('Number of words')
      await user.clear(input)
      await user.type(input, '0')
      await user.tab()
      expect(screen.getByText('Value must be greater than 0')).toBeInTheDocument()
    })
  })

  describe('Scenario 8: VeriCite dialog — default settings', () => {
    it('renders VeriCite-specific options', () => {
      const ref = renderModal()
      openModal(ref, defaultVeriCiteSettings)
      expect(screen.getByLabelText('Students Can See the Originality Report')).toBeInTheDocument()
      expect(screen.getByLabelText('Exclude Quoted Material')).toBeInTheDocument()
      expect(screen.getByLabelText('Exclude Self Plagiarism')).toBeInTheDocument()
      expect(screen.getByLabelText('Store submissions in Institutional Index')).toBeInTheDocument()
    })

    it('does not render Turnitin-specific options', () => {
      const ref = renderModal()
      openModal(ref, defaultVeriCiteSettings)
      expect(screen.queryByLabelText('Other Student Papers')).not.toBeInTheDocument()
      expect(screen.queryByLabelText('Small Matches')).not.toBeInTheDocument()
      expect(screen.queryByLabelText('Include in Repository')).not.toBeInTheDocument()
    })

    it('pre-populates VeriCite settings', () => {
      const ref = renderModal()
      const dialog: DialogState = {
        type: 'vericite',
        settings: {
          ...defaultVeriCiteSettings,
          originality_report_visibility: 'never',
          exclude_quoted: false,
          exclude_self_plag: true,
          store_in_index: false,
        },
      }
      openModal(ref, dialog)
      expect(screen.getByLabelText('Students Can See the Originality Report')).toHaveValue('never')
      expect(screen.getByLabelText('Exclude Quoted Material')).not.toBeChecked()
      expect(screen.getByLabelText('Exclude Self Plagiarism')).toBeChecked()
      expect(screen.getByLabelText('Store submissions in Institutional Index')).not.toBeChecked()
    })
  })

  describe('Scenario 9: Successful submit', () => {
    it('calls onSettingsChange with Turnitin form values on submit', async () => {
      const onSettingsChange = vi.fn()
      const ref = renderModal(onSettingsChange)
      openModal(ref, defaultTurnitinSettings)
      await clickButton('Update Settings')
      expect(onSettingsChange).toHaveBeenCalledWith(
        expect.objectContaining({
          originality_report_visibility: 'immediate',
          s_paper_check: true,
          internet_check: true,
          journal_check: true,
          exclude_biblio: true,
          exclude_quoted: true,
          exclude_small_matches_type: null,
          exclude_small_matches_value: null,
          submit_papers_to: true,
        }),
      )
    })

    it('calls onSettingsChange with VeriCite form values on submit', async () => {
      const onSettingsChange = vi.fn()
      const ref = renderModal(onSettingsChange)
      openModal(ref, defaultVeriCiteSettings)
      await clickButton('Update Settings')
      expect(onSettingsChange).toHaveBeenCalledWith(
        expect.objectContaining({
          originality_report_visibility: 'immediate',
          exclude_quoted: true,
          exclude_self_plag: false,
          store_in_index: true,
        }),
      )
    })

    it('closes the modal after successful submit', async () => {
      const ref = renderModal()
      openModal(ref, defaultTurnitinSettings)
      await clickButton('Update Settings')
      await waitFor(() => {
        expect(screen.queryByText('Advanced Turnitin Settings')).not.toBeInTheDocument()
      })
    })

    it('closes the modal when Cancel is clicked', async () => {
      const ref = renderModal()
      openModal(ref, defaultTurnitinSettings)
      await clickButton('Cancel')
      await waitFor(() => {
        expect(screen.queryByText('Advanced Turnitin Settings')).not.toBeInTheDocument()
      })
    })

    it('includes exclude_small_matches values when enabled', async () => {
      const onSettingsChange = vi.fn()
      const ref = renderModal(onSettingsChange)
      const dialog: DialogState = {
        type: 'turnitin',
        settings: {
          ...defaultTurnitinSettings.settings,
          exclude_small_matches_type: 'words',
          exclude_small_matches_value: 5,
        },
      }
      openModal(ref, dialog)
      await clickButton('Update Settings')
      expect(onSettingsChange).toHaveBeenCalledWith(
        expect.objectContaining({
          exclude_small_matches_type: 'words',
          exclude_small_matches_value: '5',
        }),
      )
    })
  })
})
