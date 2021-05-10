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

import React, {useEffect} from 'react'
import PropTypes, {shape, instanceOf} from 'prop-types'
import {useQuery, useMutation} from 'react-apollo'
import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'
import {View} from '@instructure/ui-view'
import {Spinner} from '@instructure/ui-spinner'
import {DELETE_COMMENT_MUTATION, CREATE_COMMENT_MUTATION} from './graphql/Mutations'
import {COMMENTS_QUERY} from './graphql/Queries'
import I18n from 'i18n!CommentLibrary'
import Library from './Library'

const LibraryManager = ({setComment, courseId, textAreaRef}) => {
  const {loading, error, data} = useQuery(COMMENTS_QUERY, {
    variables: {courseId}
  })

  useEffect(() => {
    if (!error) {
      return
    }
    showFlashAlert({
      message: I18n.t('Error loading comment library'),
      type: 'error'
    })
  }, [error])

  const getCachedComments = cache => {
    return JSON.parse(
      JSON.stringify(
        cache.readQuery({
          query: COMMENTS_QUERY,
          variables: {courseId}
        })
      )
    )
  }

  const writeComments = (cache, comments) => {
    cache.writeQuery({
      query: COMMENTS_QUERY,
      variables: {courseId},
      data: comments
    })
  }

  const removeDeletedCommentFromCache = (cache, result) => {
    const commentsFromCache = getCachedComments(cache)
    const resultId = result.data.deleteCommentBankItem.commentBankItemId
    const updatedComments = commentsFromCache.course.commentBankItemsConnection.nodes.filter(
      comment => comment._id !== resultId
    )

    commentsFromCache.course.commentBankItemsConnection.nodes = updatedComments
    writeComments(cache, commentsFromCache)
  }

  const addCommentToCache = (cache, result) => {
    const commentsFromCache = getCachedComments(cache)
    const newComment = result.data.createCommentBankItem.commentBankItem
    const updatedComments = [
      ...commentsFromCache.course.commentBankItemsConnection.nodes,
      newComment
    ]

    commentsFromCache.course.commentBankItemsConnection.nodes = updatedComments
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

  const handleSetComment = comment => {
    setComment(comment)
    textAreaRef.current.focus()
  }

  return (
    <Library
      comments={data?.course?.commentBankItemsConnection?.nodes || []}
      setComment={handleSetComment}
      onAddComment={handleAddComment}
      onDeleteComment={id => deleteComment({variables: {id}})}
      isAddingComment={isAddingComment}
      courseId={courseId}
    />
  )
}

LibraryManager.propTypes = {
  setComment: PropTypes.func.isRequired,
  courseId: PropTypes.string.isRequired,
  textAreaRef: shape({
    current: instanceOf(Element)
  }).isRequired
}

export default LibraryManager
