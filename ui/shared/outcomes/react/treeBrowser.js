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

import {useEffect, useMemo, useState} from 'react'
import {uniqBy} from 'lodash'
import {useApolloClient, useQuery} from 'react-apollo'
import I18n from 'i18n!OutcomeManagement'
import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'
import {CHILD_GROUPS_QUERY, groupFields} from '../graphql/Management'
import {FIND_GROUPS_QUERY} from '../graphql/Outcomes'
import useSearch from './hooks/useSearch'
import useCanvasContext from './hooks/useCanvasContext'
import {gql} from '@canvas/apollo'

export const ROOT_ID = '0'
export const ACCOUNT_FOLDER_ID = '-1'

const structFromGroup = (g, parentGroupId) => ({
  id: g._id,
  name: g.title,
  collections: [],
  isRootGroup: g.isRootGroup,
  parentGroupId
})

const formatNewGroup = g => ({
  _id: g.id,
  title: g.title,
  description: g.description,
  isRootGroup: false,
  parentGroupId: g.parent_outcome_group.id,
  __typename: 'LearningOutcomeGroup'
})

const ensureAllGroupFields = group => ({
  __typename: 'LearningOutcomeGroup',
  description: null,
  title: null,
  parentGroupId: null,
  isRootGroup: false,
  ...group
})

const extractGroups = parentGroup =>
  (parentGroup?.childGroups?.nodes || [])
    .map(g => ({
      ...g,
      parentGroupId: parentGroup._id
    }))
    .concat(parentGroup)
    .map(ensureAllGroupFields)

const getCollectionsByParentId = groups =>
  (groups || []).reduce((memo, g) => {
    if (g.parentGroupId) {
      memo[g.parentGroupId] = memo[g.parentGroupId] || []
      memo[g.parentGroupId].push(g._id)
    }

    return memo
  }, {})

const GROUPS_QUERY = gql`
  query GroupsQuery($collection: String!){
    groups(collection: $collection) {
      ${groupFields}
      isRootGroup
      parentGroupId
    }
  }
`

const useTreeBrowser = queryVariables => {
  const {isCourse} = useCanvasContext()
  const client = useApolloClient()
  const [rootId, setRootId] = useState(ROOT_ID)
  const [isLoadingRootGroup, setIsLoadingRootGroup] = useState(true)
  const [error, setError] = useState(null)
  const [selectedGroupId, setSelectedGroupId] = useState(null)
  const [selectedParentGroupId, setSelectedParentGroupId] = useState(null)
  const [loadedGroups, setLoadedGroups] = useState([])
  const {data: cacheData} = useQuery(GROUPS_QUERY, {
    fetchPolicy: 'cache-only',
    variables: queryVariables
  })
  const groups = cacheData.groups || []

  const addLoadedGroups = ids => {
    setLoadedGroups([...loadedGroups, ...ids])
  }

  const clearCache = () => {
    updateCache([])
  }

  const collections = useMemo(() => {
    const collectionsByParentId = getCollectionsByParentId(groups)
    return groups.reduce(
      (memo, g) => ({
        ...memo,
        [g._id]: {
          ...structFromGroup(g, g.parentGroupId),
          collections: collectionsByParentId[g._id] || []
        }
      }),
      {}
    )
  }, [groups])

  const addGroups = groupsToAdd => {
    const newGroups = uniqBy([...groups, ...groupsToAdd], '_id')
    updateCache(newGroups)
  }

  const addNewGroup = group => {
    addGroups([formatNewGroup(group)])
  }

  const removeGroup = groupId => {
    const newGroups = groups.filter(group => group._id !== groupId)
    updateCache(newGroups)
  }

  const updateCache = newGroups => {
    client.writeQuery({
      query: GROUPS_QUERY,
      variables: queryVariables,
      data: {
        groups: newGroups
      }
    })
  }

  const queryCollections = ({
    id,
    parentGroupId = collections[id].parentGroupId,
    shouldLoad = true
  }) => {
    setSelectedGroupId(id)
    setSelectedParentGroupId(parentGroupId)

    if (loadedGroups.includes(id)) {
      return
    }

    if (!shouldLoad) {
      addLoadedGroups([id])
      return
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
        addGroups(extractGroups(data.context))
        addLoadedGroups([id])
      })
      .catch(err => {
        setError(err.message)
      })
  }

  useEffect(() => {
    if (error) {
      const srOnlyAlert = Object.keys(collections).length === 0
      isCourse
        ? showFlashAlert({
            message: I18n.t('An error occurred while loading course learning outcome groups.'),
            type: 'error',
            srOnly: srOnlyAlert
          })
        : showFlashAlert({
            message: I18n.t('An error occurred while loading account learning outcome groups.'),
            type: 'error',
            srOnly: srOnlyAlert
          })
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [error])

  return {
    collections,
    queryCollections,
    selectedGroupId,
    setSelectedGroupId,
    error,
    setError,
    isLoading: isLoadingRootGroup,
    setIsLoading: setIsLoadingRootGroup,
    setRootId,
    rootId,
    selectedParentGroupId,
    addGroups,
    addLoadedGroups,
    clearCache,
    loadedGroups,
    addNewGroup,
    removeGroup
  }
}

export const useManageOutcomes = collection => {
  const {contextId, contextType} = useCanvasContext()
  const client = useApolloClient()
  const {
    collections,
    queryCollections,
    error,
    setError,
    isLoading,
    setIsLoading,
    setRootId,
    rootId,
    setSelectedGroupId,
    selectedGroupId,
    selectedParentGroupId,
    addGroups,
    addLoadedGroups,
    clearCache,
    addNewGroup,
    removeGroup,
    loadedGroups
  } = useTreeBrowser({
    collection
  })

  useEffect(() => {
    if (isLoading && Object.keys(collections).length > 0 && loadedGroups.includes(rootId)) {
      setIsLoading(false)
    } else if (isLoading && error) {
      setIsLoading(false)
    }
  }, [collections, rootId, loadedGroups, error, isLoading, setIsLoading])

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
        addLoadedGroups([rootGroup._id])
        setRootId(rootGroup._id)
        addGroups(extractGroups({...rootGroup, isRootGroup: true}))
      })
      .catch(err => {
        setError(err.message)
      })
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [])

  return {
    error,
    isLoading,
    collections,
    queryCollections,
    rootId,
    setSelectedGroupId,
    selectedGroupId,
    selectedParentGroupId,
    clearCache,
    addNewGroup,
    removeGroup,
    loadedGroups
  }
}

export const useFindOutcomeModal = open => {
  const {contextType, contextId, isCourse} = useCanvasContext()
  const client = useApolloClient()
  const {
    collections,
    addGroups,
    queryCollections,
    error,
    setError,
    isLoading,
    setIsLoading,
    selectedGroupId,
    setSelectedGroupId,
    setRootId,
    rootId,
    addLoadedGroups,
    loadedGroups
  } = useTreeBrowser({
    collection: 'findOutcomesView'
  })

  useEffect(() => {
    if (isLoading && Object.keys(collections).length > 0 && loadedGroups.includes(rootId)) {
      setIsLoading(false)
    } else if (isLoading && error) {
      setIsLoading(false)
    }
  }, [collections, rootId, loadedGroups, error, isLoading, setIsLoading])

  const {
    search: searchString,
    debouncedSearch: debouncedSearchString,
    onChangeHandler: updateSearch,
    onClearHandler: clearSearch
  } = useSearch()

  const toggleGroupId = props => {
    if (props?.id !== selectedGroupId) clearSearch()
    queryCollections(props)
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
          rootGroupId: ENV.GLOBAL_ROOT_OUTCOME_GROUP_ID || '0',
          includeGlobalRootGroup: !!ENV.GLOBAL_ROOT_OUTCOME_GROUP_ID
        }
      })
      .then(({data}) => {
        const {context, globalRootGroup} = data
        let accounts
        if (isCourse) {
          accounts = [...context.account.parentAccountsConnection.nodes, context.account]
        } else {
          accounts = context.parentAccountsConnection.nodes
        }

        const rootGroups = accounts.map(account => account.rootOutcomeGroup)
        const childGroups = []

        if (rootGroups.length > 0) {
          childGroups.push({
            _id: ACCOUNT_FOLDER_ID,
            title: I18n.t('Account Standards'),
            isRootGroup: true
          })
        }

        if (globalRootGroup) {
          childGroups.push({
            ...globalRootGroup,
            isRootGroup: true,
            title: I18n.t('State Standards'),
            // add a different typename than LearningOutcomeGroup
            // because useDetail will load this group with a title
            // of "ROOT" and will update this cache. We don't want
            // to update cache for this group
            __typename: 'BuildGroup'
          })
        }

        const groups = [
          ...rootGroups.flatMap(g =>
            extractGroups({
              ...g,
              isRootGroup: true,
              parentGroupId: ACCOUNT_FOLDER_ID
            })
          ),
          ...extractGroups({
            _id: ROOT_ID,
            isRootGroup: true,
            title: I18n.t('Root Learning Outcome Groups'),
            childGroups: {
              nodes: childGroups
            }
          })
        ]

        addLoadedGroups([ACCOUNT_FOLDER_ID, ROOT_ID])
        setRootId(ROOT_ID)
        addGroups(groups)
      })
      .catch(err => {
        setError(err.message)
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
    clearSearch,
    loadedGroups
  }
}

export const useTargetGroupSelector = (groupId, collection) => {
  const {
    error,
    isLoading,
    collections,
    rootId,
    clearCache,
    queryCollections: treeBrowserQueryCollection,
    addNewGroup,
    selectedGroupId,
    selectedParentGroupId,
    loadedGroups
  } = useManageOutcomes(collection)

  const queryCollections = ({id, parentGroupId, shouldLoad}) => {
    // Do not query for more collections if the groupId is the same as the id passed
    if (id !== groupId) {
      treeBrowserQueryCollection({id, parentGroupId, shouldLoad})
    }
  }

  // This will prevent to show child groups if the group id is the same as the
  // id passed
  // This will happen when user wants to move group A, load group B children,
  // closes the move modal and opens group B to be moved.
  // We won't query group b children, but this will be on cache, so to prevent
  // of showing, we clear the cache
  useEffect(() => {
    return () => {
      clearCache()
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [])

  return {
    error,
    isLoading,
    collections,
    queryCollections,
    rootId,
    addNewGroup,
    selectedGroupId,
    selectedParentGroupId,
    loadedGroups
  }
}
