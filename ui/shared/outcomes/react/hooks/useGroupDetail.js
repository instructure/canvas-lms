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

import '@canvas/rails-flash-notifications'
import I18n from 'i18n!OutcomeManagement'
import $ from 'jquery'
import {useState, useEffect} from 'react'
import {useApolloClient} from 'react-apollo'
import {
  GROUP_DETAIL_QUERY,
  GROUP_DETAIL_QUERY_WITH_IMPORTED_OUTCOMES
} from '../../graphql/Management'
import {ACCOUNT_FOLDER_ID} from '../treeBrowser'
import useCanvasContext from './useCanvasContext'

const useGroupDetail = (id, loadOutcomesIsImported = false) => {
  const {contextType, contextId} = useCanvasContext()
  const client = useApolloClient()
  const [group, setGroup] = useState(null)
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState(null)
  const outcomeIsImportedVariables = loadOutcomesIsImported
    ? {outcomeIsImportedContextType: contextType, outcomeIsImportedContextId: contextId}
    : {}

  const load = currentGroup => {
    if (id && String(id) !== String(ACCOUNT_FOLDER_ID)) {
      setLoading(true)
      client
        .query({
          query: loadOutcomesIsImported
            ? GROUP_DETAIL_QUERY_WITH_IMPORTED_OUTCOMES
            : GROUP_DETAIL_QUERY,
          variables: {
            id,
            outcomesCursor: currentGroup?.outcomes?.pageInfo?.endCursor,
            ...outcomeIsImportedVariables
          }
        })
        .then(({data}) => {
          if (!currentGroup) {
            setGroup(data.group)
          } else {
            setGroup({
              ...data.group,
              outcomes: {
                pageInfo: data.group.outcomes.pageInfo,
                nodes: [...currentGroup.outcomes.nodes, ...data.group.outcomes.nodes]
              }
            })
          }
        })
        .finally(() => {
          setLoading(false)
        })
        .catch(err => {
          setError(err)
        })
    }
  }

  useEffect(() => {
    setGroup(null)
    setError(null)
    setLoading(true)
    load(null)
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [id])

  useEffect(() => {
    if (error) {
      $.flashError(I18n.t('An error occurred while loading selected group.'))
    }
  }, [error])

  const loadMore = () => {
    if (!loading) {
      load(group)
    }
  }

  return {
    loading,
    group,
    error,
    loadMore
  }
}

export default useGroupDetail
