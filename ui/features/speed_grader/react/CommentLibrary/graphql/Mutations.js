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

import {gql} from '@canvas/apollo'
import {COMMENTS_QUERY} from './Queries'

export const CREATE_COMMENT_MUTATION = gql`
  mutation CreateCommentBankItem($courseId: ID!, $comment: String!) {
    createCommentBankItem(input: {courseId: $courseId, comment: $comment}) {
      commentBankItem {
        _id
        comment
      }
      errors {
        attribute
        message
      }
    }
  }
`

export const DELETE_COMMENT_MUTATION = gql`
  mutation DeleteCommentBankItem($id: ID!) {
    deleteCommentBankItem(input: {id: $id}) {
      commentBankItemId
      errors {
        attribute
        message
      }
    }
  }
`

export const UPDATE_COMMENT_MUTATION = gql`
  mutation UpdateCommentBankItem($id: ID!, $comment: String!) {
    updateCommentBankItem(input: {id: $id, comment: $comment}) {
      commentBankItem {
        _id
        comment
      }
      errors {
        attribute
        message
      }
    }
  }
`

const getCache = (cache, userId) => {
  return JSON.parse(
    JSON.stringify(
      cache.readQuery({
        query: COMMENTS_QUERY,
        variables: {userId},
      })
    )
  )
}

const writeToCache = (cache, comments, userId) => {
  cache.writeQuery({
    query: COMMENTS_QUERY,
    variables: {userId},
    data: comments,
  })
}

export const removeDeletedCommentFromCache = (cache, result, userId) => {
  const comments = getCache(cache, userId)
  const resultId = result.data.deleteCommentBankItem.commentBankItemId
  const removedIndex = comments.legacyNode.commentBankItemsConnection.nodes.findIndex(
    comment => comment._id === resultId
  )
  const updatedComments = comments.legacyNode.commentBankItemsConnection.nodes.filter(
    (_comment, index) => index !== removedIndex
  )

  comments.legacyNode.commentBankItemsConnection.nodes = updatedComments
  writeToCache(cache, comments, userId)
  return removedIndex
}

export const addCommentToCache = (cache, result, userId) => {
  const comments = getCache(cache, userId)
  const newComment = result.data.createCommentBankItem.commentBankItem
  const updatedComments = [...comments.legacyNode.commentBankItemsConnection.nodes, newComment]

  comments.legacyNode.commentBankItemsConnection.nodes = updatedComments
  writeToCache(cache, comments, userId)
}
