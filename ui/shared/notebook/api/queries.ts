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

// Journey proxy mutation that wraps Redwood GraphQL operations
export const EXECUTE_REDWOOD_QUERY = `
  mutation ExecuteRedwoodQuery($input: RedwoodQueryInput!) {
    executeRedwoodQuery(input: $input) {
      data
      errors
    }
  }
`

const NOTE_FIELDS_FRAGMENT = `
  fragment NoteFields on Note {
    id
    userId
    courseId
    objectId
    objectType
    userText
    reaction
    highlightData
    rootAccountUuid
    createdAt
    updatedAt
  }
`

const NOTE_CONNECTION_FRAGMENT = `
  fragment NoteConnection on NoteConnection {
    edges {
      cursor
      node {
        ...NoteFields
      }
    }
    pageInfo {
      hasNextPage
      hasPreviousPage
      startCursor
      endCursor
    }
    nodes {
      ...NoteFields
    }
  }
  ${NOTE_FIELDS_FRAGMENT}
`

export const GET_NOTES_QUERY = `
  query GetNotes($first: Float, $after: String, $before: String, $last: Float, $filter: NoteFilterInput) {
    notes(first: $first, after: $after, before: $before, last: $last, filter: $filter) {
      ...NoteConnection
    }
  }
  ${NOTE_CONNECTION_FRAGMENT}
`

export const CREATE_NOTE_MUTATION = `
  mutation CreateNote(
    $courseId: String!
    $objectId: String!
    $objectType: String!
    $userText: String
    $reaction: [String!]
    $highlightData: JSON
  ) {
    createNote(
      input: {
        courseId: $courseId
        objectId: $objectId
        objectType: $objectType
        userText: $userText
        reaction: $reaction
        highlightData: $highlightData
      }
    ) {
      id
      rootAccountUuid
      userId
      courseId
      objectId
      objectType
      userText
      reaction
      highlightData
      createdAt
      updatedAt
    }
  }
`

export const UPDATE_NOTE_MUTATION = `
  mutation UpdateNote(
    $id: String!
    $userText: String
    $reaction: [String!]
    $highlightData: JSON
  ) {
    updateNote(
      id: $id
      input: {
        userText: $userText
        reaction: $reaction
        highlightData: $highlightData
      }
    ) {
      id
      rootAccountUuid
      userId
      courseId
      objectId
      objectType
      userText
      reaction
      highlightData
      createdAt
      updatedAt
    }
  }
`

export const DELETE_NOTE_MUTATION = `
  mutation DeleteNote($id: String!) {
    deleteNote(id: $id)
  }
`
