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

import {useScope as createI18nScope} from '@canvas/i18n'
import type {NotebookTranslations} from '@instructure/platform-notebook'

const I18n = createI18nScope('notebook')

type TranslationThunk = (opts?: Record<string, unknown>) => string

const TRANSLATION_THUNKS: Record<string, TranslationThunk> = {
  notebook: () => I18n.t('Notebook'),
  notes: () => I18n.t('Notes'),
  important: () => I18n.t('Important'),
  unclear: () => I18n.t('Unclear'),
  back: () => I18n.t('Back'),
  editNote: () => I18n.t('Edit note'),
  save: () => I18n.t('Save'),
  cancel: () => I18n.t('Cancel'),
  deleteNote: () => I18n.t('Delete note'),
  note: () => I18n.t('note'),
  addNotePrompt: () => I18n.t('Add note (optional)'),
  removeFromNotebook: () => I18n.t('Remove from Notebook'),
  addNoteOptional: () => I18n.t('Add a note (optional).'),
  markImportant: () => I18n.t('Mark important'),
  markUnclear: () => I18n.t('Mark unclear'),
  savedToNotebook: () => I18n.t('Saved to Notebook.'),
  noteUpdated: () => I18n.t('Note updated'),
  noteDeleted: () => I18n.t('Note deleted'),
  errorSavingNote: () => I18n.t('Error saving to Notebook.'),
  errorUpdatingNote: () => I18n.t('Error updating note'),
  noteDeletionFailed: () => I18n.t('Note deletion failed'),
  loadingNotes: () => I18n.t('Loading notes'),
  failedToLoadNotes: () => I18n.t('Failed to load notes'),
  emptyStateHeading: () => I18n.t('Start capturing your notes'),
  emptyStateDescription: () =>
    I18n.t(
      "Your notes from learning materials will appear here. Highlight key ideas, reflections, or questions as you learn—they'll all be saved in your Notebook for easy review later.",
    ),
  nothingHereYet: () => I18n.t('Nothing here yet'),
  adjustFiltersOrCreate: () => I18n.t('Adjust your filters or create a new note to get started.'),
  noNotesForFilter: () => I18n.t('You have no notes for the selected filter'),
  previousPage: () => I18n.t('Previous page'),
  nextPage: () => I18n.t('Next page'),
  allCourses: () => I18n.t('All courses'),
  allNotes: () => I18n.t('All notes'),
  closeNotebookPanel: () => I18n.t('Close Notebook panel'),
  featureDescription: () =>
    I18n.t(
      "To use the Notebook feature, highlight an excerpt from your learning material to flag it as 'confusing' or 'important' and leave an optional note.",
    ),
  highlightUnavailable: () => I18n.t('The content you highlighted is no longer available.'),
}

export const notebookTranslations = new Proxy({} as NotebookTranslations, {
  get(_target, prop: string) {
    return TRANSLATION_THUNKS[prop]?.() ?? prop
  },
})

export function notebookTranslate(key: string, options?: Record<string, unknown>): string {
  const thunk = TRANSLATION_THUNKS[key]
  return thunk ? thunk(options) : key
}
