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
import $ from 'jquery'
import {useEffect, useState} from 'react'
import {useApolloClient} from 'react-apollo'
import I18n from 'i18n!OutcomeManagement'
import 'compiled/jquery.rails_flash_notifications'
import {CHILD_GROUPS_QUERY} from '../Management/api'
import {FIND_GROUPS_QUERY} from '../api'
import {useCanvasContext} from './hooks'

const ROOT_ID = 0
const ACCOUNT_FOLDER_ID = -1

const defaultStruct = (id, name) => ({
  id,
  name,
  collections: [],
  outcomesCount: 0,
  loadInfo: 'loading'
})

const mergeCollections = (groups, collections, parentGroupId) => {
  const newCollections = (groups || []).reduce((memo, g) => {
    if (g._id in collections) {
      return memo
    }
    return {
      ...memo,
      [g._id]: structFromGroup(g)
    }
  }, collections)

  if (newCollections[parentGroupId]) {
    newCollections[parentGroupId] = {
      ...newCollections[parentGroupId],
      loadInfo: 'loaded',
      collections: [...newCollections[parentGroupId].collections, ...(groups || []).map(g => g._id)]
    }
  }

  return newCollections
}

const groupDescriptor = ({childGroupsCount, outcomesCount}) => {
  return I18n.t('%{groups} Groups | %{outcomes} Outcomes', {
    groups: childGroupsCount,
    outcomes: outcomesCount
  })
}

const structFromGroup = g => ({
  id: g._id,
  name: g.title,
  descriptor: groupDescriptor(g),
  collections: [],
  outcomesCount: g.outcomesCount
})

const getCounts = rootGroups => {
  return rootGroups.reduce(
    (acc, group) => {
      return [acc[0] + group.outcomesCount, acc[1] + group.childGroupsCount]
    },
    [0, 0]
  )
}

const useTreeBrowser = () => {
  const {contextType} = useCanvasContext()
  const client = useApolloClient()
  const [collections, setCollections] = useState({[ROOT_ID]: defaultStruct(ROOT_ID)})
  const [isLoading, setIsLoading] = useState(true)
  const [error, setError] = useState(null)
  const [selectedCollection, setSelectedCollection] = useState(null)

  const updateSelectedCollection = props => {
    const {id} = props
    setSelectedCollection(id)
    queryCollections(props)
  }

  const queryCollections = ({id}) => {
    if (['loaded', 'loading'].includes(collections[id]?.loadInfo)) {
      return
    }

    const newCollections = {
      ...collections,
      [id]: {
        ...collections[id],
        loadInfo: 'loading'
      }
    }

    client
      .query({
        query: CHILD_GROUPS_QUERY,
        variables: {
          id,
          type: 'LearningOutcomeGroup'
        }
      })
      .then(({data}) => {
        setCollections(mergeCollections(data?.context?.childGroups?.nodes, newCollections, id))
      })
      .catch(err => {
        setError(err)
      })
  }

  useEffect(() => {
    if (error) {
      contextType === 'Course'
        ? $.flashError(I18n.t('An error occurred while loading course outcomes.'))
        : $.flashError(I18n.t('An error occurred while loading account outcomes.'))
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [error])

  return {
    collections,
    setCollections,
    queryCollections,
    selectedCollection,
    setSelectedCollection,
    updateSelectedCollection,
    error,
    setError,
    isLoading,
    setIsLoading
  }
}

export const useManageOutcomes = () => {
  const {contextId, contextType} = useCanvasContext()
  const client = useApolloClient()
  const {
    collections,
    setCollections,
    queryCollections,
    error,
    setError,
    isLoading,
    setIsLoading
  } = useTreeBrowser()

  useEffect(() => {
    client
      .query({
        query: CHILD_GROUPS_QUERY,
        variables: {
          id: contextId,
          type: contextType
        }
      })
      .then(({data}) => {
        setCollections(
          mergeCollections(
            data?.context?.rootOutcomeGroup?.childGroups?.nodes,
            collections,
            ROOT_ID
          )
        )
      })
      .finally(() => {
        setIsLoading(false)
      })
      .catch(err => {
        setError(err)
      })
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [])

  return {
    error,
    isLoading,
    collections,
    queryCollections,
    rootId: ROOT_ID
  }
}

export const useFindOutcomeModal = open => {
  const {contextType, contextId} = useCanvasContext()
  const client = useApolloClient()
  const {
    collections,
    setCollections,
    queryCollections,
    error,
    setError,
    isLoading,
    setIsLoading,
    selectedCollection,
    setSelectedCollection,
    updateSelectedCollection
  } = useTreeBrowser()

  useEffect(() => {
    if (!open && selectedCollection !== null) setSelectedCollection(null)
  }, [open, selectedCollection, setSelectedCollection])

  useEffect(() => {
    if (!isLoading || !open) {
      return
    }
    client
      .query({
        query: FIND_GROUPS_QUERY,
        variables: {
          id: contextId,
          type: contextType,
          rootGroupId: ENV.GLOBAL_ROOT_OUTCOME_GROUP_ID || 0,
          includeGlobalRootGroup: !!ENV.GLOBAL_ROOT_OUTCOME_GROUP_ID
        }
      })
      .then(({data}) => {
        const {context, globalRootGroup} = data
        let newCollections = {...collections}
        let accounts = []
        if (contextType === 'Course') {
          accounts = [...context.account.parentAccountsConnection?.nodes, context.account]
        } else {
          accounts = context.parentAccountsConnection?.nodes
        }
        const rootGroups = accounts.map(account => account.rootOutcomeGroup)
        const [outcomesCount, childGroupsCount] = getCounts(rootGroups)
        newCollections = mergeCollections(
          // Create 'Account Standards' Folder within the root
          [
            {
              _id: ACCOUNT_FOLDER_ID,
              title: I18n.t('Account Standards'),
              childGroupsCount,
              outcomesCount
            }
          ],
          newCollections,
          ROOT_ID
        )
        newCollections = mergeCollections(rootGroups, newCollections, ACCOUNT_FOLDER_ID)

        if (globalRootGroup) {
          newCollections = mergeCollections(
            // Create 'State Standards' Folder within the root
            [
              {
                _id: ENV.GLOBAL_ROOT_OUTCOME_GROUP_ID,
                title: I18n.t('State Standards'),
                childGroupsCount: globalRootGroup.childGroupsCount,
                outcomesCount: globalRootGroup.outcomesCount
              }
            ],
            newCollections,
            ROOT_ID
          )
        }
        setCollections(newCollections)
      })
      .finally(() => {
        setIsLoading(false)
      })
      .catch(err => {
        setError(err)
      })
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [open])

  return {
    error,
    isLoading,
    collections,
    queryCollections,
    selectedCollection,
    updateSelectedCollection,
    rootId: ROOT_ID
  }
}
