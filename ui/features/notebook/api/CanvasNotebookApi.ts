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

import doFetchApi from '@canvas/do-fetch-api-effect'
import {request} from 'graphql-request'
import type {
  CreateNoteInputType,
  GetNotesParams,
  NotebookApi,
  NoteType,
  PaginatedNotes,
  UpdateNoteInputType,
} from '@instructure/platform-notebook'
import {
  CREATE_NOTE_MUTATION,
  DELETE_NOTE_MUTATION,
  EXECUTE_REDWOOD_QUERY,
  GET_NOTES_QUERY,
  UPDATE_NOTE_MUTATION,
} from './queries'

interface ExecuteRedwoodQueryResponse {
  executeRedwoodQuery: {
    data?: unknown
    errors?: Array<{message: string}>
  }
}

interface NotesQueryData {
  notes: {
    nodes: NoteType[]
    pageInfo: {
      hasNextPage?: boolean | null
      hasPreviousPage?: boolean | null
      startCursor?: string | null
      endCursor?: string | null
    }
  }
}

interface CreateNoteData {
  createNote: NoteType
}

interface UpdateNoteData {
  updateNote: NoteType
}

export class CanvasNotebookApi implements NotebookApi {
  private journeyUrl: string
  private jwtPromise: Promise<string> | null = null

  constructor(journeyUrl: string) {
    this.journeyUrl = journeyUrl
  }

  private getJwt(): Promise<string> {
    if (!this.jwtPromise) {
      this.jwtPromise = doFetchApi<{token: string}>({
        path: '/api/v1/jwts?canvas_audience=false&workflows[]=journey',
        method: 'POST',
      })
        .then(({json}) => atob(json!.token))
        .catch(err => {
          this.jwtPromise = null
          throw err
        })
    }
    return this.jwtPromise
  }

  private async executeRedwoodQuery<TData>(
    query: string,
    variables?: Record<string, unknown>,
    operationName?: string,
  ): Promise<TData> {
    const jwt = await this.getJwt()

    const response = await request<ExecuteRedwoodQueryResponse>(
      `${this.journeyUrl}/graphql`,
      EXECUTE_REDWOOD_QUERY,
      {
        input: {
          query,
          variables,
          operationName,
        },
      },
      {Authorization: `Bearer ${jwt}`},
    )

    const redwoodResponse = response.executeRedwoodQuery

    if (redwoodResponse.errors && redwoodResponse.errors.length > 0) {
      const combinedMessage = redwoodResponse.errors
        .map(error => error.message)
        .filter((message): message is string => Boolean(message))
        .join('; ')

      throw new Error(combinedMessage || 'Unknown error from Redwood')
    }

    if (!redwoodResponse.data) {
      throw new Error('No data returned from Redwood')
    }

    return redwoodResponse.data as TData
  }

  async getNotes(params: GetNotesParams): Promise<PaginatedNotes> {
    const variables = {
      filter: params.filter,
      first: params.direction === 'prev' ? null : (params.pageSize ?? 10),
      last: params.direction === 'prev' ? (params.pageSize ?? 10) : null,
      after: params.direction === 'next' ? params.cursor : null,
      before: params.direction === 'prev' ? params.cursor : null,
    }

    const data = await this.executeRedwoodQuery<NotesQueryData>(
      GET_NOTES_QUERY,
      variables,
      'GetNotes',
    )

    return {
      notes: data.notes.nodes,
      pageInfo: {
        hasNextPage: data.notes.pageInfo.hasNextPage ?? undefined,
        hasPreviousPage: data.notes.pageInfo.hasPreviousPage ?? undefined,
        startCursor: data.notes.pageInfo.startCursor ?? undefined,
        endCursor: data.notes.pageInfo.endCursor ?? undefined,
      },
    }
  }

  async createNote(input: CreateNoteInputType): Promise<NoteType> {
    const data = await this.executeRedwoodQuery<CreateNoteData>(
      CREATE_NOTE_MUTATION,
      input as unknown as Record<string, unknown>,
      'CreateNote',
    )
    return data.createNote
  }

  async updateNote(id: string, input: UpdateNoteInputType): Promise<NoteType> {
    const data = await this.executeRedwoodQuery<UpdateNoteData>(
      UPDATE_NOTE_MUTATION,
      {...(input as unknown as Record<string, unknown>), id},
      'UpdateNote',
    )
    return data.updateNote
  }

  async deleteNote(id: string): Promise<void> {
    await this.executeRedwoodQuery(DELETE_NOTE_MUTATION, {id}, 'DeleteNote')
  }
}
