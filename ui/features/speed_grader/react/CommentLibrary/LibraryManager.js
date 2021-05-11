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

import React, {useEffect, useState, useRef, useCallback} from 'react'
import PropTypes from 'prop-types'
import {useQuery, useMutation, useLazyQuery} from 'react-apollo'
import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'
import {View} from '@instructure/ui-view'
import {Spinner} from '@instructure/ui-spinner'
import useDebouncedSearchTerm from '@canvas/direct-sharing/react/hooks/useDebouncedSearchTerm'
import {DELETE_COMMENT_MUTATION, CREATE_COMMENT_MUTATION} from './graphql/Mutations'
import {COMMENTS_QUERY} from './graphql/Queries'
import I18n from 'i18n!CommentLibrary'
import Library from './Library'

const LibraryManager = ({setComment, courseId, setFocusToTextArea, userId, commentAreaText}) => {
  const abortController = useRef()
  const [removedItemIndex, setRemovedItemIndex] = useState(null)
  const [showSuggestions, setShowSuggestions] = useState(false)
  const {searchTerm, setSearchTerm} = useDebouncedSearchTerm('')
  // Sometimes, even if we get a new comment, we don't want to update the search term.
  // An example of this would be if the user clicks on a suggested comment.
  // If so, after setting the comment in the text area we disable search so a
  // new request to find suggestions isn't made
  const [changeSearchTerm, setChangeSearchTerm] = useState(true)

  const {loading, error, data} = useQuery(COMMENTS_QUERY, {
    variables: {userId}
  })

  useEffect(() => {
    if (error) {
      showFlashAlert({
        message: I18n.t('Error loading comment library'),
        type: 'error'
      })
    }
  }, [error])

  useEffect(() => {
    if (!changeSearchTerm) {
      setChangeSearchTerm(true)
    } else {
      setSearchTerm(commentAreaText)
    }
  }, [commentAreaText]) // eslint-disable-line react-hooks/exhaustive-deps

  const [queryComments, {data: searchResults}] = useLazyQuery(COMMENTS_QUERY)

  useEffect(() => {
    if (searchTerm.length >= 3 && showSuggestions) {
      abortController.current?.abort()
      const controller = new window.AbortController()
      abortController.current = controller
      queryComments({
        variables: {
          userId,
          query: searchTerm,
          maxResults: 5
        },
        context: {fetchOptions: {signal: controller.signal}}
      })
    }
  }, [searchTerm]) // eslint-disable-line react-hooks/exhaustive-deps

  const handleSetComment = useCallback(
    comment => {
      setChangeSearchTerm(false)
      setComment(comment)
      setFocusToTextArea()
    },
    [setComment, setFocusToTextArea]
  )

  const getCachedComments = cache => {
    return JSON.parse(
      JSON.stringify(
        cache.readQuery({
          query: COMMENTS_QUERY,
          variables: {userId}
        })
      )
    )
  }

  const writeComments = (cache, comments) => {
    cache.writeQuery({
      query: COMMENTS_QUERY,
      variables: {userId},
      data: comments
    })
  }

  const removeDeletedCommentFromCache = (cache, result) => {
    const commentsFromCache = getCachedComments(cache)
    const resultId = result.data.deleteCommentBankItem.commentBankItemId
    const removedIndex = commentsFromCache.legacyNode.commentBankItemsConnection.nodes.findIndex(
      comment => comment._id === resultId
    )
    const updatedComments = commentsFromCache.legacyNode.commentBankItemsConnection.nodes.filter(
      (_comment, index) => index !== removedIndex
    )

    commentsFromCache.legacyNode.commentBankItemsConnection.nodes = updatedComments
    writeComments(cache, commentsFromCache)
    setRemovedItemIndex(removedIndex)
  }

  const addCommentToCache = (cache, result) => {
    const commentsFromCache = getCachedComments(cache)
    const newComment = result.data.createCommentBankItem.commentBankItem
    const updatedComments = [
      ...commentsFromCache.legacyNode.commentBankItemsConnection.nodes,
      newComment
    ]

    commentsFromCache.legacyNode.commentBankItemsConnection.nodes = updatedComments
    writeComments(cache, commentsFromCache)
  }

  const [deleteComment] = useMutation(DELETE_COMMENT_MUTATION, {
    update: removeDeletedCommentFromCache,
    onCompleted(_data) {
      showFlashAlert({
        message: I18n.t('Comment destroyed'),
        type: 'success'
      })
    },
    onError(_error) {
      showFlashAlert({
        message: I18n.t('Error deleting comment'),
        type: 'error'
      })
    }
  })

  const [addComment, {loading: isAddingComment}] = useMutation(CREATE_COMMENT_MUTATION, {
    update: addCommentToCache,
    onCompleted(_data) {
      showFlashAlert({
        message: I18n.t('Comment added'),
        type: 'success'
      })
    },
    onError(_error) {
      showFlashAlert({
        message: I18n.t('Error creating comment'),
        type: 'error'
      })
    }
  })

  const handleAddComment = comment => {
    addComment({variables: {comment, courseId}})
  }

  if (loading) {
    return (
      <View as="div" textAlign="end">
        <Spinner size="small" renderTitle={() => I18n.t('Loading comment library')} />
      </View>
    )
  }

  if (error) {
    return null
  }

  return (
    <Library
      comments={data?.legacyNode?.commentBankItemsConnection?.nodes || []}
      setComment={handleSetComment}
      onAddComment={handleAddComment}
      onDeleteComment={id => deleteComment({variables: {id}})}
      isAddingComment={isAddingComment}
      removedItemIndex={removedItemIndex}
      showSuggestions={showSuggestions}
      setShowSuggestions={setShowSuggestions}
      searchResults={
        searchTerm.length >= 3
          ? searchResults?.legacyNode?.commentBankItemsConnection?.nodes || []
          : []
      }
      setFocusToTextArea={setFocusToTextArea}
    />
  )
}

LibraryManager.propTypes = {
  setComment: PropTypes.func.isRequired,
  courseId: PropTypes.string.isRequired,
  setFocusToTextArea: PropTypes.func.isRequired,
  userId: PropTypes.string.isRequired,
  commentAreaText: PropTypes.string.isRequired
}

export default LibraryManager
