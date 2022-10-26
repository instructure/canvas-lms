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
import {uniqBy, uniq} from 'lodash'
import {useApolloClient, useQuery} from 'react-apollo'
import {useScope as useI18nScope} from '@canvas/i18n'
import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'
import {CHILD_GROUPS_QUERY, groupFields, SEARCH_GROUP_OUTCOMES} from '../graphql/Management'
import {FIND_GROUPS_QUERY} from '../graphql/Outcomes'
import useSearch from './hooks/useSearch'
import useGroupCreate from './hooks/useGroupCreate'
import useCanvasContext from './hooks/useCanvasContext'
import {gql} from '@canvas/apollo'

const I18n = useI18nScope('OutcomeManagement')

const structFromGroup = g => ({
  id: g._id,
  name: g.title,
  collections: [],
  isRootGroup: g.isRootGroup,
  parentGroupId: g.parentOutcomeGroup?._id,
})

const formatNewGroup = g => ({
  _id: g._id,
  title: g.title,
  description: g.description,
  isRootGroup: false,
  parentOutcomeGroup: {
    _id: g.parentOutcomeGroup._id,
    __typename: 'LearningOutcomeGroup',
  },
  __typename: 'LearningOutcomeGroup',
})

const ensureAllGroupFields = group => ({
  __typename: 'LearningOutcomeGroup',
  description: null,
  title: null,
  parentOutcomeGroup: null,
  isRootGroup: false,
  ...group,
})

const extractGroups = parentGroup =>
  (parentGroup?.childGroups?.nodes || [])
    .map(g => ({
      ...g,
      parentOutcomeGroup: {
        _id: parentGroup._id,
        __typename: 'LearningOutcomeGroup',
      },
    }))
    .concat(parentGroup)
    .map(ensureAllGroupFields)

const getCollectionsByParentId = groups =>
  (groups || []).reduce((memo, g) => {
    if (g.parentOutcomeGroup) {
      memo[g.parentOutcomeGroup._id] = memo[g.parentOutcomeGroup._id] || []
      memo[g.parentOutcomeGroup._id].push(g._id)
    }

    return memo
  }, {})

const GROUPS_QUERY = gql`
  query GroupsQuery($collection: String!){
    groups(collection: $collection) {
      ${groupFields}
      isRootGroup
      parentOutcomeGroup {
        _id
      }
    }
  }
`
const LOADED_GROUPS_QUERY = gql`
  query LoadedGroupsQuery($collection: String!) {
    loadedGroups(collection: $collection)
  }
`
const CONTEXT_GROUPS_QUERY = gql`
  query ContextGroupsLoadedQuery($contextType: String!, $contextId: ID!) {
    rootGroupId(contextType: $contextType, contextId: $contextId)
  }
`

const useTreeBrowser = queryVariables => {
  const {isCourse, treeBrowserRootGroupId: ROOT_GROUP_ID} = useCanvasContext()
  const client = useApolloClient()
  const [rootId, setRootId] = useState(ROOT_GROUP_ID)
  const [isLoadingRootGroup, setIsLoadingRootGroup] = useState(true)
  const [error, setError] = useState(null)
  const [selectedGroupId, setSelectedGroupId] = useState(null)
  const [selectedParentGroupId, setSelectedParentGroupId] = useState(null)
  const {data: cacheData} = useQuery(GROUPS_QUERY, {
    fetchPolicy: 'cache-only',
    variables: queryVariables,
  })
  const {data: loadedGroupsData} = useQuery(LOADED_GROUPS_QUERY, {
    fetchPolicy: 'cache-only',
    variables: queryVariables,
  })
  const groups = cacheData.groups || []
  const loadedGroups = loadedGroupsData.loadedGroups || []

  const addLoadedGroups = ids => {
    client.writeQuery({
      query: LOADED_GROUPS_QUERY,
      variables: queryVariables,
      data: {
        loadedGroups: uniq([...loadedGroups, ...ids]),
      },
    })
  }

  const removeFromLoadedGroups = ids => {
    const newLoadedGroups = loadedGroups.filter(val => ids.indexOf(val) === -1)
    client.writeQuery({
      query: LOADED_GROUPS_QUERY,
      variables: queryVariables,
      data: {
        loadedGroups: [...newLoadedGroups],
      },
    })
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
          ...structFromGroup(g),
          collections: collectionsByParentId[g._id] || [],
        },
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
        groups: newGroups,
      },
    })
  }

  const queryCollections = ({
    id,
    parentGroupId = collections[id]?.parentGroupId,
    shouldLoad = true,
  }) => {
    setSelectedGroupId(id)
    setSelectedParentGroupId(parentGroupId)

    // Will change in OUT-4760 as the group information will be gathered from the GraphQL
    // and not the collection as there is a use case that will use queryCollections but will not
    // necessarily have the aligning collection loaded
    if (collections[id]) {
      // screenreader only alert for when a user clicks on a group to load in the RHS (Find modal & Main Outcome Management)
      showFlashAlert({
        message: I18n.t(`Loading %{groupTitle}.`, {groupTitle: collections[id].name}),
        srOnly: true,
      })
    }

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
          type: 'LearningOutcomeGroup',
        },
        fetchPolicy: 'network-only',
      })
      .then(({data}) => {
        setSelectedParentGroupId(data.context.parentOutcomeGroup?._id)
        addGroups(extractGroups(data.context))
        addLoadedGroups([id])
      })
      .catch(err => {
        setError(err.message)
      })
  }

  const refetchGroup = id => {
    client
      .query({
        query: CHILD_GROUPS_QUERY,
        variables: {
          id,
          type: 'LearningOutcomeGroup',
        },
        fetchPolicy: 'network-only',
      })
      .then(({data}) => {
        addGroups(extractGroups(data.context))
        addLoadedGroups([id])
      })
      .catch(err => {
        setError(err.message)
      })
  }
  const refetchGroupOutcome = (groupId, contextId, contextType) => {
    client.query({
      query: SEARCH_GROUP_OUTCOMES,
      variables: {
        id: groupId,
        outcomeIsImported: false,
        outcomesContextId: contextId,
        outcomesContextType: contextType,
      },
      fetchPolicy: 'network-only',
    })
  }
  useEffect(() => {
    if (error) {
      const srOnlyAlert = Object.keys(collections).length === 0
      isCourse
        ? showFlashAlert({
            message: I18n.t('An error occurred while loading course learning outcome groups.'),
            type: 'error',
            srOnly: srOnlyAlert,
          })
        : showFlashAlert({
            message: I18n.t('An error occurred while loading account learning outcome groups.'),
            type: 'error',
            srOnly: srOnlyAlert,
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
    removeFromLoadedGroups,
    clearCache,
    loadedGroups,
    addNewGroup,
    removeGroup,
    setSelectedParentGroupId,
    refetchGroup,
    refetchGroupOutcome,
  }
}

export const useManageOutcomes = ({
  collection,
  initialGroupId,
  importNumber = 0,
  lhsGroupIdsToRefetch = [],
  lhsGroupId = null,
  parentsToUnload = [],
} = {}) => {
  const {contextId, contextType} = useCanvasContext()
  const client = useApolloClient()
  const {
    collections,
    queryCollections: queryCollectionsTreeBrowser,
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
    removeFromLoadedGroups,
    clearCache: clearTreeBrowserCache,
    addNewGroup,
    removeGroup,
    loadedGroups,
    setSelectedParentGroupId,
    refetchGroup,
    refetchGroupOutcome,
  } = useTreeBrowser({
    collection,
  })
  const {createGroup: graphqlGroupCreate} = useGroupCreate()

  const {data: contextGroupLoadedData} = useQuery(CONTEXT_GROUPS_QUERY, {
    fetchPolicy: 'cache-only',
    variables: {
      contextId,
      contextType,
    },
  })

  const clearCache = () => {
    client.writeQuery({
      query: CONTEXT_GROUPS_QUERY,
      variables: {
        contextType,
        contextId,
      },
      data: {
        rootGroupId: null,
      },
    })
    clearTreeBrowserCache()
  }

  const rootGroupId = contextGroupLoadedData.rootGroupId

  const {
    search: searchString,
    debouncedSearch: debouncedSearchString,
    onChangeHandler: updateSearch,
    onClearHandler: clearSearch,
  } = useSearch()

  const queryCollections = props => {
    if (props?.id !== selectedGroupId) clearSearch()
    queryCollectionsTreeBrowser(props)
  }

  useEffect(() => {
    if (
      isLoading &&
      ((Object.keys(collections).length > 0 && loadedGroups.includes(initialGroupId || rootId)) ||
        error)
    ) {
      setIsLoading(false)
    }
  }, [collections, rootId, loadedGroups, error, isLoading, setIsLoading, initialGroupId])

  useEffect(() => {
    if (lhsGroupIdsToRefetch.length > 0) {
      lhsGroupIdsToRefetch.map(groupId => refetchGroup(groupId))
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [lhsGroupIdsToRefetch])

  const saveRootGroupId = id => {
    addLoadedGroups([id])
    setRootId(id)
  }

  const fetchContextGroups = () => {
    if (initialGroupId) {
      setSelectedGroupId(initialGroupId)

      client
        .query({
          query: CHILD_GROUPS_QUERY,
          variables: {
            id: initialGroupId,
            type: 'LearningOutcomeGroup',
          },
          fetchPolicy: 'network-only',
        })
        .then(({data}) => {
          setSelectedParentGroupId(data.context.parentOutcomeGroup?._id)
          addGroups(extractGroups(data.context))
          addLoadedGroups([initialGroupId])
        })
        .catch(err => {
          setError(err.message)
        })
    } else {
      client
        .query({
          query: CHILD_GROUPS_QUERY,
          variables: {
            id: contextId,
            type: contextType,
          },
          fetchPolicy: 'network-only',
        })
        .then(({data}) => {
          const rootGroup = data.context.rootOutcomeGroup
          client.writeQuery({
            query: CONTEXT_GROUPS_QUERY,
            variables: {
              contextId,
              contextType,
            },
            data: {
              rootGroupId: rootGroup._id,
            },
          })
          saveRootGroupId(rootGroup._id)
          addGroups(extractGroups({...rootGroup, isRootGroup: true}))
          if (lhsGroupId && lhsGroupId !== rootGroup._id && loadedGroups.includes(lhsGroupId)) {
            removeFromLoadedGroups([lhsGroupId])
          }
        })
        .catch(err => {
          setError(err.message)
        })
    }
  }

  useEffect(() => {
    if (!initialGroupId && importNumber === 0 && rootGroupId) {
      saveRootGroupId(rootGroupId)
    } else {
      fetchContextGroups()
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [importNumber])
  useEffect(() => {
    if (parentsToUnload.length > 0) {
      removeFromLoadedGroups(parentsToUnload)
      parentsToUnload.forEach(id => refetchGroupOutcome(id, contextId, contextType))
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [parentsToUnload])

  const createGroup = async (groupName, parentGroupId = rootId) => {
    const newGroup = await graphqlGroupCreate(groupName, parentGroupId)
    if (newGroup?._id) {
      addNewGroup(newGroup)
      return structFromGroup(formatNewGroup(newGroup))
    }
  }

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
    loadedGroups,
    createGroup,
    searchString,
    debouncedSearchString,
    updateSearch,
    clearSearch,
  }
}

export const useFindOutcomeModal = open => {
  const {
    contextType,
    contextId,
    isCourse,
    globalRootId,
    treeBrowserRootGroupId: ROOT_GROUP_ID,
    treeBrowserAccountGroupId: ACCOUNT_GROUP_ID,
  } = useCanvasContext()
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
    loadedGroups,
  } = useTreeBrowser({
    collection: 'findOutcomesView',
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
    onClearHandler: clearSearch,
  } = useSearch()

  const toggleGroupId = props => {
    if (props?.id !== selectedGroupId) clearSearch()
    queryCollections(props)
  }

  useEffect(() => {
    if (!open && selectedGroupId !== null) {
      setTimeout(() => {
        setSelectedGroupId(null)
      }, 500)
    }
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
          rootGroupId: globalRootId || '0',
          includeGlobalRootGroup: !!globalRootId,
        },
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
            _id: ACCOUNT_GROUP_ID,
            title: I18n.t('Account Standards'),
            isRootGroup: true,
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
            __typename: 'BuildGroup',
          })
        }

        const groups = [
          ...rootGroups.flatMap(g =>
            extractGroups({
              ...g,
              isRootGroup: true,
              parentOutcomeGroup: {
                _id: ACCOUNT_GROUP_ID,
                __typename: 'LearningOutcomeGroup',
              },
            })
          ),
          ...extractGroups({
            _id: ROOT_GROUP_ID,
            isRootGroup: true,
            title: I18n.t('Root Learning Outcome Groups'),
            childGroups: {
              nodes: childGroups,
            },
          }),
        ]

        addLoadedGroups([ACCOUNT_GROUP_ID, ROOT_GROUP_ID])
        setRootId(ROOT_GROUP_ID)
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
    loadedGroups,
  }
}

export const useTargetGroupSelector = ({skipGroupId, initialGroupId}) => {
  const {queryCollections: treeBrowserQueryCollection, ...useManageOutcomesProps} =
    useManageOutcomes({collection: 'OutcomeManagementPanel', initialGroupId})

  const queryCollections = ({id, parentGroupId, shouldLoad}) => {
    // Do not query for more collections if the groupId is the same as the id passed
    if (id !== skipGroupId) {
      treeBrowserQueryCollection({id, parentGroupId, shouldLoad})
    }
  }

  return {
    ...useManageOutcomesProps,
    queryCollections,
  }
}
