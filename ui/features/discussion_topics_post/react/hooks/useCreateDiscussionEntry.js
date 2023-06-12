/*
 * Copyright (C) 2023 - present Instructure, Inc.
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

import {useContext} from 'react'
import {CREATE_DISCUSSION_ENTRY} from '../../graphql/Mutations'
import {useMutation} from 'react-apollo'
import {AlertManagerContext} from '@canvas/alerts/react/AlertManager'
import {useScope as useI18nScope} from '@canvas/i18n'

const I18n = useI18nScope('discussion_topics_post')

export default function useCreateDiscussionEntry(onCompleteCallback, updateCacheCallback) {
  const {setOnFailure, setOnSuccess} = useContext(AlertManagerContext)

  const [createDiscussionEntry, {data, loading}] = useMutation(CREATE_DISCUSSION_ENTRY, {
    onCompleted: completionData => {
      // Common onCompletion handling logic here.
      setOnSuccess(I18n.t('The discussion entry was successfully created.'))

      if (onCompleteCallback) {
        // Additional, component-specific completion handling logic here.
        onCompleteCallback(completionData)
      }
    },
    onError: () => {
      // Common error handling logic here.
      setOnFailure(I18n.t('There was an unexpected error creating the discussion entry.'))
    },
    // Pass in caching update logic
    update: updateCacheCallback,
  })

  return {
    createDiscussionEntry,
    data,
    loading,
  }
}
