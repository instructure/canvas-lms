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

import {create} from 'zustand'
import {devtools} from 'zustand/middleware'

declare const ENV: {
  discussion_topic_id?: string
}

type Error = {
  type: string
  message: string
}

interface Translation {
  loading: boolean
  title?: string
  message?: string
  language?: string
  translatedTitle?: string
  translatedMessage?: string
  error?: Error
}

type State = {
  activeLanguage: string | null
  isActiveLanguageSet: boolean
  translateAll: boolean

  discussionTopicId: string | null
  modalOpen: boolean
  translationEntryId: string | null
  translationTitle: string | null
  translationMessage: string | null
  translations: Record<string, string>
  entries: Record<string, Translation>
}

type Actions = {
  setModalOpen: (entryId: string, message: string, title?: string) => void
  closeModal: () => void
  setTranslateContent: (entryId: string, message: string, title?: string) => void

  addEntry: (entryId: string, entry: Pick<Translation, 'title' | 'message'>) => void
  removeEntry: (entryId: string) => void

  setActiveLanguage: (language: string | null) => void
  setTranslateAll: (value: boolean) => void
  clearTranslateAll: () => void

  setTranslationStart: (entryId: string) => void
  setTranslationEnd: (
    entryId: string,
    language?: string,
    translatedMessage?: string | null,
    translatedTitle?: string | null,
  ) => void
  setTranslationError: (entryId: string, error: Error, language: string) => void
}

const useTranslationStore = create<State & Actions>()(
  devtools(
    set => ({
      activeLanguage: null,
      isActiveLanguageSet: false,

      translateAll: false,
      discussionTopicId: ENV?.discussion_topic_id || null,
      modalOpen: false,
      translationEntryId: null,
      translationTitle: null,
      translationMessage: null,
      translations: {},
      entries: {},
      setModalOpen: (entryId: string, message: string, title?: string) =>
        set({
          modalOpen: true,
          translationEntryId: entryId,
          translationMessage: message,
          translationTitle: title || null,
        }),
      setTranslateContent: (entryId: string, message: string, title?: string) =>
        set({
          translationEntryId: entryId,
          translationMessage: message,
          translationTitle: title || null,
        }),
      closeModal: () => set({modalOpen: false, translationEntryId: null}),

      addEntry: (entryId: string, entry: Pick<Translation, 'title' | 'message'>) =>
        set(state => ({entries: {...state.entries, [entryId]: {...entry, loading: false}}})),
      removeEntry: (entryId: string) =>
        set(state => {
          const newEntries = {...state.entries}
          delete newEntries[entryId]
          return {entries: newEntries}
        }),

      setActiveLanguage: (language: string | null) =>
        set({activeLanguage: language, isActiveLanguageSet: true}),
      setTranslateAll: (value: boolean) => set({translateAll: value}),
      clearTranslateAll: () =>
        set(state => {
          const newEntries: Record<string, Translation> = {}

          Object.keys(state.entries).forEach(entryId => {
            newEntries[entryId] = {
              ...state.entries[entryId],
              loading: false,
              language: undefined,
              translatedTitle: undefined,
              translatedMessage: undefined,
            }
          })

          return {translateAll: false, entries: newEntries}
        }),

      setTranslationStart: (entryId: string) =>
        set(state => ({
          entries: {
            ...state.entries,
            [entryId]: {
              ...state.entries[entryId],
              loading: true,
              translatedMessage: undefined,
              translatedTitle: undefined,
              error: undefined,
            },
          },
        })),
      setTranslationEnd: (
        entryId: string,
        language?: string,
        translatedMessage?: string | null,
        translatedTitle?: string | null,
      ) =>
        set(state => ({
          entries: {
            ...state.entries,
            [entryId]: {
              ...state.entries[entryId],
              loading: false,
              language: language !== undefined ? language : state.entries[entryId]?.language,
              translatedMessage: translatedMessage || undefined,
              translatedTitle: translatedTitle || undefined,
            },
          },
        })),

      setTranslationError: (entryId: string, error: Error, language: string) =>
        set(state => ({
          entries: {
            ...state.entries,
            [entryId]: {
              ...state.entries[entryId],
              loading: false,
              translatedMessage: undefined,
              translatedTitle: undefined,
              language,
              error,
            },
          },
        })),
    }),
    {
      name: 'TranslationStore',
      enabled: window.INST.environment === 'development',
    },
  ),
)

export {useTranslationStore}
