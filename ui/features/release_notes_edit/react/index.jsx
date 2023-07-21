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
import doFetchApi from '@canvas/do-fetch-api-effect'
import useFetchApi from '@canvas/use-fetch-api-hook'
import {useScope as useI18nScope} from '@canvas/i18n'

import NotesTable from './NotesTable'
import CreateEditModal from './CreateEditModal'

const I18n = useI18nScope('release_notes')

function notesReducer(prevState, action) {
  if (action.type === 'FETCH_LOADING') {
    return {...prevState, loading: action.payload}
  } else if (action.type === 'FETCH_META') {
    return {...prevState, nextPage: action.payload.next}
  } else if (action.type === 'FETCH_SUCCESS') {
    const newNotes = [...prevState.notes]
    action.payload.forEach(row => {
      if (!prevState.notes.some(n => n.id === row.id)) {
        newNotes.push(row)
      }
    })
    return {...prevState, notes: newNotes}
  } else if (action.type === 'PUBLISHED_STATE') {
    const newNotes = cloneDeep(prevState.notes)
    const relevantNote = newNotes.find(n => n.id === action.payload.id)
    relevantNote.published = action.payload.state
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
  }
  return prevState
}

export default function ReleaseNotesEdit({envs, langs}) {
  const [state, dispatch] = useReducer(notesReducer, {
    notes: [],
    nextPage: null,
    loading: true,
  })
  const [page, setPage] = useState(null)
  const [showDialog, setShowDialog] = useState(false)
  const [currentNote, setCurrentNote] = useState(null)

  const editNote = useCallback(note => {
    setCurrentNote(note)
    setShowDialog(true)
  }, [])

  const createNote = useCallback(() => {
    setCurrentNote(null)
    setShowDialog(true)
  }, [])

  useFetchApi({
    path: '/api/v1/release_notes',
    success: useCallback(response => {
      dispatch({type: 'FETCH_SUCCESS', payload: response})
    }, []),
    meta: useCallback(({link}) => {
      dispatch({type: 'FETCH_META', payload: link})
    }, []),
    error: useCallback(error => dispatch({type: 'FETCH_ERROR', payload: error}), []),
    loading: useCallback(loading => dispatch({type: 'FETCH_LOADING', payload: loading}), []),
    params: {
      includes: ['langs'],
      per_page: 20,
      page,
    },
  })

  const setPublished = useCallback(async (id, publishedState) => {
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
  }, [])

  const upsertNote = useCallback(async newNote => {
    const note = await doFetchApi({
      path: `/api/v1/release_notes${newNote.id ? `/${newNote.id}` : ''}`,
      method: newNote.id ? 'PUT' : 'POST',
      body: newNote,
    })
    dispatch({type: 'UPSERT_NOTE', payload: note.json})
    setShowDialog(false)
  }, [])

  const deleteNote = useCallback(async id => {
    await doFetchApi({
      path: `/api/v1/release_notes/${id}`,
      method: 'DELETE',
    })
    dispatch({type: 'REMOVE_NOTE', payload: {id}})
  }, [])

  if (state.loading) {
    return <Spinner renderTitle={I18n.t('Loading')} />
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
