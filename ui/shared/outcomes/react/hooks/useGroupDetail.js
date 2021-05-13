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

import {useState, useEffect, useRef} from 'react'
import {useApolloClient} from 'react-apollo'
import {ACCOUNT_FOLDER_ID} from '../treeBrowser'
import useCanvasContext from './useCanvasContext'
import I18n from 'i18n!OutcomeManagement'
import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'
import {SEARCH_GROUP_OUTCOMES} from '@canvas/outcomes/graphql/Management'

const useGroupDetail = ({
  query = SEARCH_GROUP_OUTCOMES,
  loadOutcomesIsImported = false,
  searchString = '',
  id
}) => {
  const {contextType, contextId} = useCanvasContext()
  const client = useApolloClient()
  const [group, setGroup] = useState(null)
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState(null)
  const abortController = useRef(null)
  const abortLatest = () => abortController.current && abortController.current.abort()
  const queryVars = {outcomesContextType: contextType, outcomesContextId: contextId}

  const load = currentGroup => {
    if (
      id &&
      String(id) !== String(ACCOUNT_FOLDER_ID) &&
      ((searchString || '').length === 0 || searchString.length > 2)
    ) {
      setLoading(true)

      if (searchString) queryVars.searchQuery = searchString

      abortLatest()
      const controller = new window.AbortController()
      abortController.current = controller

      client
        .query({
          query,
          variables: {
            id,
            outcomeIsImported: loadOutcomesIsImported,
            outcomesCursor: currentGroup?.outcomes?.pageInfo?.endCursor,
            ...queryVars
          },
          context: {
            fetchOptions: {signal: controller.signal}
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
                edges: [...currentGroup.outcomes.edges, ...data.group.outcomes.edges]
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
  }, [id])

  useEffect(() => {
    setError(null)
    setLoading(true)
    load(null)
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [id, searchString])

  useEffect(() => {
    if (error) {
      showFlashAlert({
        message: I18n.t('An error occurred while loading selected group.'),
        type: 'error'
      })
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
    setGroup,
    loadMore
  }
}

export default useGroupDetail
