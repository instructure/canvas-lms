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
import PropTypes from 'prop-types'
import {useQuery} from 'react-apollo'
import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'
import {View} from '@instructure/ui-view'
import {Spinner} from '@instructure/ui-spinner'
import {COMMENTS_QUERY} from './graphql/Queries'
import I18n from 'i18n!CommentLibrary'
import Library from './Library'

const LibraryManager = ({setComment}) => {
  const courseId = ENV.context_asset_string.split('_')[1]

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
      comments={data?.course?.commentBankItemsConnection?.nodes || []}
      setComment={setComment}
    />
  )
}

LibraryManager.propTypes = {
  setComment: PropTypes.func.isRequired
}

export default LibraryManager
