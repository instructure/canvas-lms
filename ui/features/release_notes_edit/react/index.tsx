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

import React, {useReducer, useState, useCallback} from 'react'
import {cloneDeep} from 'lodash'
import {Button} from '@instructure/ui-buttons'
import {Spinner} from '@instructure/ui-spinner'
import {Alert} from '@instructure/ui-alerts'
import doFetchApi, {FetchApiError} from '@canvas/do-fetch-api-effect'
import useFetchApi from '@canvas/use-fetch-api-hook'
import {useScope as createI18nScope} from '@canvas/i18n'

import NotesTable from './NotesTable'
import CreateEditModal from './CreateEditModal'
import type {Links} from '@canvas/parse-link-header/parseLinkHeader'
import type {ReleaseNote} from './types'

const I18n = createI18nScope('release_notes')

type Notes = {
  notes: ReleaseNote[]
  nextPage: string | null
  loading: boolean
  error?: Error
}
type NotesReducerTransition = {
  type:
    | 'FETCH_LOADING'
    | 'FETCH_META'
    | 'FETCH_SUCCESS'
    | 'FETCH_ERROR'
    | 'PUBLISHED_STATE'
    | 'UPSERT_NOTE'
    | 'REMOVE_NOTE'
  payload: any
}

function isFetchApiError(error: Error): error is FetchApiError {
  return error instanceof FetchApiError
}

function notesReducer(prevState: Notes, action: NotesReducerTransition) {
  if (action.type === 'FETCH_LOADING') {
    return {...prevState, loading: action.payload}
  } else if (action.type === 'FETCH_META') {
    if (!action.payload) return prevState // if no link header, do nothing
    return {...prevState, nextPage: action.payload.next}
  } else if (action.type === 'FETCH_SUCCESS') {
    const newNotes = [...prevState.notes]
    const fetchedNotes = action.payload as ReleaseNote[]
    fetchedNotes.forEach(row => {
      if (!prevState.notes.some(n => n.id === row.id)) {
        newNotes.push(row)
      }
    })
    return {...prevState, notes: newNotes}
  } else if (action.type === 'PUBLISHED_STATE') {
    const newNotes = cloneDeep(prevState.notes)
    const relevantNote = newNotes.find(n => n.id === action.payload.id)
    if (relevantNote) relevantNote.published = action.payload.state
    return {...prevState, notes: newNotes}
  } else if (action.type === 'UPSERT_NOTE') {
    const newNotes = [...prevState.notes]
    const relevantNote = newNotes.findIndex(n => n.id === action.payload.id)
    if (relevantNote >= 0) {
      newNotes[relevantNote] = action.payload
    } else {
      newNotes.unshift(action.payload)
    }

    return {...prevState, notes: newNotes}
  } else if (action.type === 'REMOVE_NOTE') {
    const newNotes = prevState.notes.filter(note => note.id !== action.payload.id)
    return {...prevState, notes: newNotes}
  } else if (action.type === 'FETCH_ERROR') {
    return {...prevState, error: action.payload as Error}
  }
  return prevState
}

interface ReleaseNotesEditProps {
  envs: string[]
  langs: string[]
}

export default function ReleaseNotesEdit({envs, langs}: ReleaseNotesEditProps): JSX.Element {
  const [state, dispatch] = useReducer(notesReducer, {
    notes: [],
    nextPage: null,
    loading: true,
  })
  const [page, setPage] = useState(null)
  const [showDialog, setShowDialog] = useState(false)
  const [currentNote, setCurrentNote] = useState<ReleaseNote | null>(null)

  const editNote = useCallback((note: ReleaseNote) => {
    setCurrentNote(note)
    setShowDialog(true)
  }, [])

  const createNote = useCallback(() => {
    setCurrentNote(null)
    setShowDialog(true)
  }, [])

  useFetchApi({
    path: '/api/v1/release_notes',
    success: useCallback((response: ReleaseNote[]) => {
      dispatch({type: 'FETCH_SUCCESS', payload: response})
    }, []),
    meta: useCallback(({link}: {link?: Links; response: any}) => {
      dispatch({type: 'FETCH_META', payload: link})
    }, []),
    error: useCallback((error: Error) => dispatch({type: 'FETCH_ERROR', payload: error}), []),
    loading: useCallback(
      (loading: boolean) => dispatch({type: 'FETCH_LOADING', payload: loading}),
      [],
    ),
    params: {
      includes: ['langs'],
      per_page: 20,
      page,
    },
  })

  const setPublished = useCallback(
    async (id: Required<ReleaseNote>['id'], publishedState: boolean): Promise<void> => {
      await doFetchApi({
        path: `/api/v1/release_notes/${id}/published`,
        method: publishedState ? 'PUT' : 'DELETE',
      })
      dispatch({
        type: 'PUBLISHED_STATE',
        payload: {
          id,
          state: publishedState,
        },
      })
    },
    [],
  )

  const upsertNote = useCallback(async (newNote: ReleaseNote) => {
    const note = await doFetchApi({
      path: `/api/v1/release_notes${newNote.id ? `/${newNote.id}` : ''}`,
      method: newNote.id ? 'PUT' : 'POST',
      body: newNote,
    })
    dispatch({type: 'UPSERT_NOTE', payload: note.json})
    setShowDialog(false)
  }, [])

  const deleteNote = useCallback(async (id: Required<ReleaseNote>['id']): Promise<void> => {
    await doFetchApi({
      path: `/api/v1/release_notes/${id}`,
      method: 'DELETE',
    })
    dispatch({type: 'REMOVE_NOTE', payload: {id}})
  }, [])

  if (state.loading) {
    return <Spinner renderTitle={I18n.t('Loading')} />
  }

  if (state.error) {
    let errorText: string
    if (isFetchApiError(state.error)) {
      const {status, statusText, url} = state.error.response
      errorText = I18n.t('API %{status} %{statusText} fetching %{url}', {
        status,
        statusText,
        url,
      })
    } else {
      const {name, message} = state.error
      errorText = I18n.t('non-API error, type %{name}, %{message}', {name, message})
    }
    return (
      <Alert variant="error" margin="small">
        <p>
          <strong>{I18n.t('An error occurred while loading the release notes')}</strong>
          <br />
          {errorText}
        </p>
      </Alert>
    )
  }

  return (
    <>
      <Button onClick={createNote} color="primary">
        {I18n.t('New Note')}
      </Button>
      <NotesTable
        notes={state.notes}
        setPublished={setPublished}
        editNote={editNote}
        deleteNote={deleteNote}
      />
      {state.nextPage ? (
        <Button onClick={() => setPage(state.nextPage.page)}>{I18n.t('Load more')}</Button>
      ) : null}
      <CreateEditModal
        open={showDialog}
        onClose={() => setShowDialog(false)}
        currentNote={currentNote}
        onSubmit={upsertNote}
        envs={envs}
        langs={langs}
      />
    </>
  )
}
