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

import {useEffect, useState} from 'react'
import {useApolloClient} from 'react-apollo'
import I18n from 'i18n!OutcomeManagement'
import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'
import {CHILD_GROUPS_QUERY} from '../graphql/Management'
import {FIND_GROUPS_QUERY} from '../graphql/Outcomes'
import useSearch from './hooks/useSearch'
import useCanvasContext from './hooks/useCanvasContext'

export const ROOT_ID = 0
export const ACCOUNT_FOLDER_ID = -1

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
      [g._id]: structFromGroup(g, parentGroupId)
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

const structFromGroup = (g, parentGroupId) => ({
  id: g._id,
  name: g.title,
  descriptor: groupDescriptor(g),
  collections: [],
  outcomesCount: g.outcomesCount,
  canEdit: g.canEdit,
  parentGroupId
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
  const [collections, setCollections] = useState({})
  const [rootId, setRootId] = useState(ROOT_ID)
  const [isLoading, setIsLoading] = useState(true)
  const [error, setError] = useState(null)
  const [selectedGroupId, setSelectedGroupId] = useState(null)

  const updateSelectedGroupId = props => {
    const {id} = props
    setSelectedGroupId(id)
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
        ? showFlashAlert({
            message: I18n.t('An error occurred while loading course outcomes.'),
            type: 'error'
          })
        : showFlashAlert({
            message: I18n.t('An error occurred while loading account outcomes.'),
            type: 'error'
          })
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [error])

  return {
    collections,
    setCollections,
    queryCollections,
    selectedGroupId,
    setSelectedGroupId,
    updateSelectedGroupId,
    error,
    setError,
    isLoading,
    setIsLoading,
    setRootId,
    rootId
  }
}

export const useManageOutcomes = () => {
  const {contextId, contextType} = useCanvasContext()
  const [selectedGroupId, setSelectedGroupId] = useState(null)
  const [selectedParentGroupId, setSelectedParentGroupId] = useState(null)
  const client = useApolloClient()
  const {
    collections,
    setCollections,
    queryCollections: treeBrowserQueryCollection,
    error,
    setError,
    isLoading,
    setIsLoading,
    setRootId,
    rootId
  } = useTreeBrowser()

  const queryCollections = ({id}) => {
    setSelectedGroupId(id)
    treeBrowserQueryCollection({id})
    setSelectedParentGroupId(collections[id].parentGroupId)
  }

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
        const rootGroup = data?.context?.rootOutcomeGroup
        const initialCollection = {[rootGroup._id]: structFromGroup(rootGroup, ROOT_ID)}
        setCollections(
          mergeCollections(rootGroup?.childGroups?.nodes, initialCollection, rootGroup._id)
        )
        setRootId(rootGroup._id)
      })
      .catch(err => {
        setError(err)
      })
      .finally(() => {
        setIsLoading(false)
      })
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [])

  return {
    error,
    isLoading,
    collections,
    queryCollections,
    rootId,
    selectedGroupId,
    selectedParentGroupId
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
    selectedGroupId,
    setSelectedGroupId,
    updateSelectedGroupId,
    setRootId,
    rootId
  } = useTreeBrowser()
  const {
    search: searchString,
    debouncedSearch: debouncedSearchString,
    onChangeHandler: updateSearch,
    onClearHandler: clearSearch
  } = useSearch()

  const toggleGroupId = props => {
    if (props?.id !== selectedGroupId) clearSearch()
    updateSelectedGroupId(props)
  }

  useEffect(() => {
    if (!open && selectedGroupId !== null) setSelectedGroupId(null)
  }, [open, selectedGroupId, setSelectedGroupId])

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
        let newCollections = {[ROOT_ID]: defaultStruct(ROOT_ID)}
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
        setRootId(ROOT_ID)
      })
      .catch(err => {
        setError(err)
      })
      .finally(() => {
        setIsLoading(false)
      })
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [open])

  return {
    error,
    isLoading,
    collections,
    queryCollections,
    selectedGroupId,
    toggleGroupId,
    rootId,
    searchString,
    debouncedSearchString,
    updateSearch,
    clearSearch
  }
}

export const useGroupMoveModal = groupId => {
  const {contextId, contextType} = useCanvasContext()

  const client = useApolloClient()
  const {
    collections,
    setCollections,
    queryCollections: treeBrowserQueryCollection,
    error,
    setError,
    isLoading,
    setIsLoading,
    rootId,
    setRootId
  } = useTreeBrowser()

  const queryCollections = ({id}) => {
    // Do not query for more collections if the groupId is the same as the id passed
    if (id !== groupId) {
      treeBrowserQueryCollection({id})
    }
  }

  useEffect(
    () => {
      client
        .query({
          query: CHILD_GROUPS_QUERY,
          variables: {
            id: contextId,
            type: contextType
          }
        })
        .then(({data}) => {
          const rootGroup = data?.context?.rootOutcomeGroup
          const initialCollection = {[rootGroup?._id]: structFromGroup(rootGroup, ROOT_ID)}
          setCollections(
            mergeCollections(rootGroup?.childGroups?.nodes, initialCollection, rootGroup._id)
          )
          setRootId(rootGroup._id)
        })
        .catch(err => {
          setError(err)
        })
        .finally(() => {
          setIsLoading(false)
        })
    },
    // eslint-disable-next-line react-hooks/exhaustive-deps
    []
  )

  return {
    error,
    isLoading,
    collections,
    queryCollections,
    rootId
  }
}
