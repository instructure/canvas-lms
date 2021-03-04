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

import 'compiled/jquery.rails_flash_notifications'
import I18n from 'i18n!OutcomeManagement'
import $ from 'jquery'
import {useState, useEffect} from 'react'
import {useApolloClient} from 'react-apollo'
import {GROUP_DETAIL_QUERY} from './api'

const useGroupDetail = (id) => {
  const client = useApolloClient()
  const [group, setGroup] = useState(null)
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState(null)

  const load = (currentGroup) => {
    if (id) {
      setLoading(true)
      client
        .query({
          query: GROUP_DETAIL_QUERY,
          variables: {
            id,
            outcomesCursor: currentGroup?.outcomes?.pageInfo?.endCursor,
          },
        })
        .then(({data}) => {
          if (!currentGroup) {
            setGroup(data.group)
          } else {
            setGroup({
              ...data.group,
              outcomes: {
                pageInfo: data.group.outcomes.pageInfo,
                nodes: [...currentGroup.outcomes.nodes, ...data.group.outcomes.nodes],
              },
            })
          }
        })
        .finally(() => {
          setLoading(false)
        })
        .catch((err) => {
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
    loadMore,
  }
}

export default useGroupDetail
