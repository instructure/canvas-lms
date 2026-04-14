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

import React, {useCallback, useMemo, useRef, useEffect, useState} from 'react'
import {QueryClient, QueryClientProvider} from '@tanstack/react-query'
import {
  ContentWithNoteWrapper,
  NotebookProvider,
  NotebookTray,
  NotesListView,
  useNotebook,
  useGetNotes,
  useUpdateNote,
  useDeleteNote,
  REACTION_TYPE,
  type HighlightTheme,
  type NoteCardTheme,
} from '@instructure/platform-notebook'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Button} from '@instructure/ui-buttons'
import {IconNoteLine} from '@instructure/ui-icons'
import {canvas} from '@instructure/ui-themes'
import {CanvasNotebookApi} from '../api/CanvasNotebookApi'

const I18n = createI18nScope('notebook')

const HIGHLIGHT_THEME: HighlightTheme = {
  colors: {
    importantBackground: canvas.colors.contrasts.blue1212,
    confusingBackground: canvas.colors.contrasts.red1212,
    importantUnderline: canvas.colors.contrasts.blue4570,
    confusingUnderline: canvas.colors.contrasts.red4570,
  },
  borderWidthSmall: '0.0625rem',
  underlineOffset: '0.125rem',
}

const CARD_THEME: NoteCardTheme = {
  importantBorderColor: canvas.colors.contrasts.blue4570,
  confusingBorderColor: canvas.colors.contrasts.red4570,
}

const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      staleTime: 1000 * 60 * 5,
      refetchOnWindowFocus: false,
    },
  },
})

function NotebookButton() {
  const {isTrayOpen, openTray, closeTray} = useNotebook()

  return (
    <Button
      renderIcon={<IconNoteLine />}
      color="secondary"
      onClick={isTrayOpen ? closeTray : openTray}
      data-testid="notebook-button"
    >
      {I18n.t('Notebook')}
    </Button>
  )
}

function NotebookTrayContent() {
  const {api, objectId, objectType, courseId, selectedNoteId, selectNote, clearSelectedNote} =
    useNotebook()

  const {data, isLoading, isError} = useGetNotes({
    api,
    filter: {learningObject: {type: objectType, id: objectId}},
    courseId,
    pageSize: 100,
  })

  const {mutate: updateNote} = useUpdateNote(api)
  const {mutate: deleteNote} = useDeleteNote(api)

  const notes = useMemo(() => data?.notes ?? [], [data?.notes])

  const handleDelete = useCallback(
    (noteId: string) => {
      deleteNote(noteId)
    },
    [deleteNote],
  )

  const handleSave = useCallback(
    (noteId: string, text: string) => {
      const note = notes.find(n => n.id === noteId)
      if (!note) return
      updateNote({
        id: noteId,
        input: {
          id: noteId,
          userText: text,
          reaction: note.reaction,
          highlightData: note.highlightData,
        },
      })
    },
    [notes, updateNote],
  )

  const handleTypeChange = useCallback(
    (noteId: string, type: REACTION_TYPE) => {
      const note = notes.find(n => n.id === noteId)
      if (!note) return
      updateNote({
        id: noteId,
        input: {
          id: noteId,
          userText: note.userText,
          reaction: [type],
          highlightData: note.highlightData,
        },
      })
    },
    [notes, updateNote],
  )

  return (
    <NotesListView
      notes={notes}
      isLoading={isLoading}
      isError={isError}
      pageInfo={data?.pageInfo}
      onPreviousPage={() => {}}
      onNextPage={() => {}}
      selectedNoteId={selectedNoteId ?? undefined}
      onNoteSelect={id => (id === selectedNoteId ? clearSelectedNote() : selectNote(id))}
      onNoteDelete={handleDelete}
      onNoteSave={handleSave}
      onNoteTypeChange={handleTypeChange}
      columnCount={1}
      highlightTheme={HIGHLIGHT_THEME}
      cardTheme={CARD_THEME}
    />
  )
}

function NotebookContent() {
  const containerRef = useRef<HTMLElement | null>(null)
  const [containerReady, setContainerReady] = useState(false)

  useEffect(() => {
    const trySetContainer = (): boolean => {
      const el = document.querySelector<HTMLElement>('.show-content.user_content')
      if (el) {
        containerRef.current = el
        setContainerReady(true)
        return true
      }
      return false
    }

    if (trySetContainer()) return

    // wiki_page_show renders .show-content.user_content via a separate async
    // bundle. If that bundle hasn't run yet when this effect fires, observe the
    // DOM until the element appears.
    const root = document.getElementById('content') ?? document.body
    const observer = new MutationObserver(() => {
      if (trySetContainer()) observer.disconnect()
    })
    observer.observe(root, {subtree: true, childList: true})

    const timeoutId = window.setTimeout(() => {
      observer.disconnect()
    }, 10_000)

    return () => {
      observer.disconnect()
      window.clearTimeout(timeoutId)
    }
  }, [])

  return (
    <>
      <NotebookButton />
      <NotebookTray>
        <NotebookTrayContent />
      </NotebookTray>
      {containerReady && (
        <ContentWithNoteWrapper containerRef={containerRef} highlightTheme={HIGHLIGHT_THEME} />
      )}
    </>
  )
}

export default function NotebookApp() {
  const journeyUrl = window.ENV.JOURNEY_URL
  const api = useMemo(() => (journeyUrl ? new CanvasNotebookApi(journeyUrl) : null), [journeyUrl])

  if (!api) return null

  return (
    <QueryClientProvider client={queryClient}>
      <NotebookProvider
        api={api}
        currentUserId={window.ENV.current_user_id ?? ''}
        objectId={window.ENV.WIKI_PAGE_ID ?? ''}
        objectType="Page"
        courseId={String(window.ENV.COURSE_ID ?? '')}
        pageLastModifiedAt={window.ENV.WIKI_PAGE_UPDATED_AT}
      >
        <NotebookContent />
      </NotebookProvider>
    </QueryClientProvider>
  )
}
