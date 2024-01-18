/*
 * Copyright (C) 2020 - present Instructure, Inc.
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
import {
  CHILD_GROUPS_QUERY,
  CREATE_LEARNING_OUTCOME,
  FIND_GROUP_OUTCOMES,
  SEARCH_GROUP_OUTCOMES,
  SET_OUTCOME_FRIENDLY_DESCRIPTION_MUTATION,
  UPDATE_LEARNING_OUTCOME,
  DELETE_OUTCOME_LINKS,
  MOVE_OUTCOME_LINKS,
  UPDATE_LEARNING_OUTCOME_GROUP,
  IMPORT_OUTCOMES,
  CREATE_LEARNING_OUTCOME_GROUP,
  COURSE_ALIGNMENT_STATS,
  SEARCH_OUTCOME_ALIGNMENTS,
} from '../graphql/Management'
import {defaultRatings, defaultMasteryPoints} from '../react/hooks/useRatings'
import {pick, uniq, flattenDeep} from 'lodash'

const testRatings = defaultRatings.map(rating => pick(rating, ['description', 'points']))

const ratingsWithTypename = ratings => ratings.map(r => ({...r, __typename: 'ProficiencyRating'}))

const maxPoints = ratings => ratings.sort((a, b) => b.points - a.points)[0].points

export const accountMocks = ({childGroupsCount = 10, accountId = '1'} = {}) => [
  {
    request: {
      query: CHILD_GROUPS_QUERY,
      variables: {
        id: accountId,
        type: 'Account',
      },
    },
    result: {
      data: {
        context: {
          __typename: 'Account',
          _id: accountId,
          rootOutcomeGroup: {
            title: `Root account folder`,
            __typename: 'LearningOutcomeGroup',
            _id: '1',
            childGroups: {
              __typename: 'LearningOutcomeGroupConnection',
              nodes: new Array(childGroupsCount).fill(0).map((_v, i) => ({
                __typename: 'LearningOutcomeGroup',
                _id: (100 + i).toString(),
                title: `Account folder ${i}`,
              })),
            },
          },
        },
      },
    },
  },
]

export const courseMocks = ({childGroupsCount = 1, courseId = '2'} = {}) => [
  {
    request: {
      query: CHILD_GROUPS_QUERY,
      variables: {
        id: courseId,
        type: 'Course',
      },
    },
    result: {
      data: {
        context: {
          __typename: 'Course',
          _id: courseId,
          rootOutcomeGroup: {
            title: `Root course folder`,
            __typename: 'LearningOutcomeGroup',
            _id: '2',
            childGroups: {
              __typename: 'LearningOutcomeGroupConnection',
              nodes: new Array(childGroupsCount).fill(0).map((_v, i) => ({
                __typename: 'LearningOutcomeGroup',
                _id: (200 + i).toString(),
                title: `Course folder ${i}`,
              })),
            },
          },
        },
      },
    },
  },
]

const buildGroup = (_id, title) => {
  if (!_id && !title) {
    return null
  }

  return {
    __typename: 'LearningOutcomeGroup',
    _id,
    title,
  }
}

// builds a treebrowser group structure
// groupsStruct should be an object with the keys as
// group id, and value as array of children
// example
// {groupsStruct: {
//   100: [101, 102],
//   101: [103],
// }}
// this will mock request when you click on group 100 in treebrowser to
// load group 101 and 102 as children
// and if you click on 101, it'll load 103, and so on

// Dont put the same group as child of more than one group, like
// {groupsStruct: {
//   100: [101, 102],
//   101: [102],
// }}
// Note that 102 is appearing as children of 100 and 101. Please don't do that

// This method will also mock requests for leaves groups. In the example above,
// Request for 102 and 103 won't break (it'll return a response without any children)

// for detailsStructure, should be an object with the key as group id and
// value as array of children outcome ids

// In this case, you can mock the same outcome to be child of multipe groups. Example
// detailsStructure: {
//   100: [1, 2, 3],
//   200: [1, 2, 3],
//   300: [1, 2, 3],
//   400: [1],
//   401: [2],
//   402: [3],
// }
// Note outcome 1 is children of 400, but outcome 1 should appear in their parent as well.
// folder structure could be 100 -> 200 -> 300 -> 400, 401, 402 (4xx are sibilings)
// so if you click on 300, you should expect all outcomes for all children

// note, this doesn't handle load more query for detailsStructure yet
// if you specify a group in groupsStructure and dont specify a children for it.
// it'll mock the group detail too without any outcome

// contextId, and contextType are the variables for find outcome group DETAIL query
// outcomesGroupContextId, and outcomesGroupContextType are the context for the outcomes in response
// default to contextId and contextType

// importedOutcomes, array of imported outcomes ids. If an outcome id is present there, it'll be used
// in group detail outcomes isImported field. the field is default to false. You can easily
// passes what outcomes are supposed to be returned as imported

// groupOutcomesNotImportedCount, object, key as group id, value as integer. Used to represent
// notImportedOutcomesCount field of a group in detail query. Default field value is null.
// You may want to set this to a positive integer to identify what groups can be imported via find
// outcome modal

// findOutcomesTargetGroupId the variable targetGroupId of find outcomes modal query

export const treeGroupMocks = ({
  groupsStruct,
  detailsStructure,
  contextId,
  contextType,
  findOutcomesTargetGroupId = null,
  groupOutcomesNotImportedCount = [],
  importedOutcomes = [],
  outcomesGroupContextId = contextId,
  outcomesGroupContextType = contextType,
  withGroupDetailsRefetch = false,
}) => {
  const toString = arg => arg.toString()

  const groupIds = Object.keys(groupsStruct)
  const stringImportedOutcomes = importedOutcomes.map(toString)
  const allGroupIds = uniq(
    flattenDeep([
      Object.keys(groupsStruct).map(toString),
      Object.values(groupsStruct).flat().map(toString),
    ])
  )
  const parents = groupIds.reduce((acc, gid) => {
    ;(groupsStruct[gid] || []).forEach(cid => (acc[cid] = gid))
    return acc
  }, {})

  const treeBrowserMocks = allGroupIds.map(gid => {
    const childGroups = groupsStruct[gid] || []
    const parentOutcomeGroupId = parents[gid]
    const parentOutcomeGroupTitle = parentOutcomeGroupId && `Group ${parentOutcomeGroupId}`

    return {
      request: {
        query: CHILD_GROUPS_QUERY,
        variables: {
          id: toString(gid),
          type: 'LearningOutcomeGroup',
        },
      },
      result: {
        data: {
          context: {
            __typename: 'LearningOutcomeGroup',
            _id: toString(gid),
            title: `Group ${gid}`,
            parentOutcomeGroup: buildGroup(parentOutcomeGroupId, parentOutcomeGroupTitle),
            childGroups: {
              __typename: 'LearningOutcomeGroupConnection',
              nodes: childGroups.map(cid => ({
                __typename: 'LearningOutcomeGroup',
                _id: toString(cid),
                title: `Group ${cid}`,
              })),
            },
          },
        },
      },
    }
  })

  const findModalGroupDetailsMocks = allGroupIds.map(gid => {
    const childrenOutcomes = (detailsStructure[gid] || []).map(toString)
    const calculationMethod = 'decaying_average'
    const calculationInt = 65
    const masteryPoints = defaultMasteryPoints
    const ratings = ratingsWithTypename(testRatings)

    const request = {
      query: FIND_GROUP_OUTCOMES,
      variables: {
        id: gid,
        outcomeIsImported: true,
        outcomesContextId: contextId,
        outcomesContextType: contextType,
        targetGroupId: findOutcomesTargetGroupId,
      },
    }

    const data = (withRefetch = false) => ({
      data: {
        group: {
          _id: gid,
          title: `${withRefetch && 'Refetched '}Group ${gid}`,
          contextType: outcomesGroupContextType,
          contextId: outcomesGroupContextId,
          outcomesCount: childrenOutcomes.length,
          notImportedOutcomesCount: groupOutcomesNotImportedCount[gid] || null,
          outcomes: {
            pageInfo: {
              hasNextPage: false,
              endCursor: 'Mw',
              __typename: 'PageInfo',
            },
            edges: childrenOutcomes.map(oid => ({
              _id: oid,
              node: {
                _id: oid,
                description: `Description for Outcome ${oid}`,
                isImported: stringImportedOutcomes.includes(oid),
                title: `${withRefetch && 'Refetched '}Outcome ${oid}`,
                calculationMethod,
                calculationInt,
                masteryPoints,
                ratings,
                __typename: 'LearningOutcome',
                friendlyDescription: {
                  _id: oid,
                  description: `Outcome ${oid} - friendly description`,
                  __typename: 'FriendlyDescription',
                },
              },
              __typename: 'ContentTag',
            })),
            __typename: 'ContentTagConnection',
          },
          __typename: 'LearningOutcomeGroup',
        },
      },
    })

    const response = {request, result: data()}

    if (withGroupDetailsRefetch) response.newData = () => data(withGroupDetailsRefetch)

    return response
  })

  return [treeBrowserMocks, findModalGroupDetailsMocks].flat()
}

export const groupMocks = ({
  groupId,
  childGroupsCount = 1,
  childGroupOffset = 300,
  title = `Group ${groupId}`,
  parentOutcomeGroupId,
  parentOutcomeGroupTitle,
  childGroupTitlePrefix = `Group ${groupId} folder`,
} = {}) => [
  {
    request: {
      query: CHILD_GROUPS_QUERY,
      variables: {
        id: groupId,
        type: 'LearningOutcomeGroup',
      },
    },
    result: {
      data: {
        context: {
          __typename: 'LearningOutcomeGroup',
          _id: groupId,
          title,
          parentOutcomeGroup: buildGroup(parentOutcomeGroupId, parentOutcomeGroupTitle),
          childGroups: {
            __typename: 'LearningOutcomeGroupConnection',
            nodes: new Array(childGroupsCount).fill(0).map((_v, i) => ({
              __typename: 'LearningOutcomeGroup',
              _id: (childGroupOffset + i).toString(),
              title: `${childGroupTitlePrefix} ${i}`,
            })),
          },
        },
      },
    },
  },
]

export const outcomeGroup = {
  _id: '0',
  title: 'Grade.2.Math.3A.Elementary.CCSS.Calculus.1',
  description:
    '<p>This is a <strong><em>description</em></strong>. And because it’s so <strong>long</strong>, it will run out of space and hence be truncated. </p>'.repeat(
      2
    ),
  outcomesCount: 15,
  outcomes: {
    pageInfo: {
      hasNextPage: false,
      endCursor: '',
    },
    edges: [
      {
        canUnlink: true,
        _id: '1',
        node: {
          _id: '1',
          title: 'CCSS.Math.Content.2.MD.A.1 - Outcome with regular length title and description',
          description:
            '<p>Partition <strong>circles</strong> and <strong><em>rectangle</em></strong> into two, three, or four equal share. </p>'.repeat(
              2
            ),
          contextType: null,
          contextId: null,
          canEdit: true,
        },
        group: {
          _id: '101',
          title: 'Outcome Group 1',
          __typename: 'LearningOutcomeGroup',
        },
      },
      {
        canUnlink: true,
        _id: '2',
        node: {
          _id: '2',
          title:
            'CCSS.Math.Content.2.MD.A.1.CCSS.Math.Content.2.MD.A.1.CCSS.Math.Content.Outcome.with.long.title.and.description',
          description:
            '<p>Measure the <strong><em>length</em></strong> of an <strong>object</strong> by selecting and using appropriate measurements. </p>'.repeat(
              2
            ),
          contextType: null,
          contextId: null,
          canEdit: true,
        },
        group: {
          _id: '101',
          title: 'Outcome Group 1',
          __typename: 'LearningOutcomeGroup',
        },
      },
      {
        canUnlink: true,
        _id: '3',
        node: {
          _id: '3',
          title: 'CCSS.Math.Content.2.G.A.3 - Outcome with regular length title and no description',
          description: '',
          contextType: null,
          contextId: null,
          canEdit: true,
        },
        group: {
          _id: '101',
          title: 'Outcome Group 1',
          __typename: 'LearningOutcomeGroup',
        },
      },
      {
        canUnlink: true,
        _id: '4',
        node: {
          _id: '4',
          title:
            'CCSS.Math.Content.2.G.A.3 CCSS.Math.Content.2.G.A.3 CCSS.Math.Content.2.G.A.3 CCSS.Math',
          description:
            '<p><em>Partition circles and rectangle into two, three, or four equal share. </em></p>'.repeat(
              2
            ),
          contextType: null,
          contextId: null,
          canEdit: true,
        },
        group: {
          _id: '101',
          title: 'Outcome Group 1',
          __typename: 'LearningOutcomeGroup',
        },
      },
      {
        canUnlink: true,
        _id: '5',
        node: {
          _id: '5',
          title:
            'CCSS.Math.Content.2.G.A.3 CCSS.Math.Content.2.G.A.3 CCSS.Math.Content.2.G.A.3 CCSS.Math',
          description:
            '<p><strong>Partition circles and rectangle into two, three, or four equal share. </strong></p>'.repeat(
              2
            ),
          contextType: null,
          contextId: null,
          canEdit: true,
        },
        group: {
          _id: '101',
          title: 'Outcome Group 1',
          __typename: 'LearningOutcomeGroup',
        },
      },
      {
        canUnlink: true,
        _id: '6',
        node: {
          _id: '6',
          title: 'CCSS.Math.Content.2.G.A.3 CCSS.Math.Content.2.G.A.3',
          description:
            '<p>Partition circles and rectangle into two, three, or four equal share. </p>'.repeat(
              2
            ),
          contextType: null,
          contextId: null,
          canEdit: true,
        },
        group: {
          _id: '101',
          title: 'Outcome Group 1',
          __typename: 'LearningOutcomeGroup',
        },
      },
    ],
  },
}

const createSearchGroupOutcomesOutcomeMocks = (
  canUnlink,
  canEdit,
  canArchive,
  contextId,
  contextType,
  title,
  outcomeCount
) => {
  const calculationMethod = 'decaying_average'
  const calculationInt = 65
  const masteryPoints = defaultMasteryPoints
  const ratings = ratingsWithTypename(testRatings)

  // Tech Debt - see OUT-4776 - need to switch this over to a dynamic array like the below code
  // for now too many tests are dependant on the number of outcomes and the order
  // of the outcomes to be exactly in the format returned by in the if statement on line 301
  if (outcomeCount === 2) {
    return [
      {
        canUnlink,
        _id: '1',
        node: {
          _id: '1',
          description: '',
          title: `Outcome 1 - ${title}`,
          displayName: '',
          calculationMethod,
          calculationInt,
          masteryPoints,
          ratings,
          canEdit,
          canArchive,
          contextId,
          contextType,
          friendlyDescription: null,
          __typename: 'LearningOutcome',
        },
        group: {
          _id: '101',
          title: 'Outcome Group 1',
          __typename: 'LearningOutcomeGroup',
        },
        __typename: 'ContentTag',
      },
      {
        canUnlink,
        _id: '2',
        node: {
          _id: '2',
          description: '',
          title: `Outcome 2 - ${title}`,
          displayName: '',
          calculationMethod,
          calculationInt,
          masteryPoints,
          ratings,
          canEdit,
          canArchive,
          contextId,
          contextType,
          friendlyDescription: null,
          __typename: 'LearningOutcome',
        },
        group: {
          _id: '101',
          title: 'Outcome Group 1',
          __typename: 'LearningOutcomeGroup',
        },
        __typename: 'ContentTag',
      },
    ]
  } else {
    return [
      {
        canUnlink,
        _id: '1',
        node: {
          _id: '1',
          description: '',
          title: `Outcome 1 - ${title}`,
          displayName: '',
          calculationMethod,
          calculationInt,
          masteryPoints,
          ratings,
          canEdit,
          canArchive,
          contextId,
          contextType,
          friendlyDescription: null,
          __typename: 'LearningOutcome',
        },
        group: {
          _id: '101',
          title: 'Outcome Group 1',
          __typename: 'LearningOutcomeGroup',
        },
        __typename: 'ContentTag',
      },
    ]
  }
}

export const groupDetailMocks = ({
  groupId = '1',
  title = `Group ${groupId}`,
  canEdit = true,
  canUnlink = true,
  canArchive = true,
  contextType = 'Account',
  contextId = '1',
  outcomeIsImported = false,
  outcomesGroupContextId = 1,
  outcomesGroupContextType = 'Account',
  searchQuery = '',
  withMorePage = true,
  groupDescription = 'Group Description',
  numOfOutcomes = 2,
  targetGroupId,
  notImportedOutcomesCount = null,
  removeOnRefetch = false,
} = {}) => {
  const calculationMethod = 'decaying_average'
  const calculationInt = 65
  const masteryPoints = defaultMasteryPoints
  const ratings = ratingsWithTypename(testRatings)

  return [
    {
      request: {
        query: FIND_GROUP_OUTCOMES,
        variables: {
          id: groupId,
          outcomesContextId: contextId,
          outcomesContextType: contextType,
          outcomeIsImported,
          targetGroupId,
        },
      },
      result: {
        data: {
          group: {
            _id: groupId,
            title,
            description: `${groupDescription} 1`,
            contextType: outcomesGroupContextType,
            contextId: outcomesGroupContextId,
            outcomesCount: numOfOutcomes,
            notImportedOutcomesCount,
            __typename: 'LearningOutcomeGroup',
            outcomes: {
              pageInfo: {
                hasNextPage: withMorePage,
                endCursor: 'Mg',
                __typename: 'PageInfo',
              },
              edges: [
                {
                  _id: '1',
                  node: {
                    _id: '1',
                    description: '',
                    title: `Outcome 1 - ${title}`,
                    calculationMethod,
                    calculationInt,
                    masteryPoints,
                    ratings,
                    canArchive,
                    isImported: outcomeIsImported,
                    __typename: 'LearningOutcome',
                    friendlyDescription: {
                      _id: '101',
                      description: 'Outcome 1 - friendly description',
                      __typename: 'FriendlyDescription',
                    },
                  },
                  __typename: 'ContentTag',
                },
                {
                  _id: '2',
                  node: {
                    _id: '2',
                    description: '',
                    title: `Outcome 2 - ${title}`,
                    calculationMethod,
                    calculationInt,
                    masteryPoints,
                    ratings,
                    canArchive,
                    isImported: outcomeIsImported,
                    __typename: 'LearningOutcome',
                    friendlyDescription: {
                      _id: '102',
                      description: 'Outcome 2 - friendly description',
                      __typename: 'FriendlyDescription',
                    },
                  },
                  __typename: 'ContentTag',
                },
              ],
              __typename: 'ContentTagConnection',
            },
          },
        },
      },
    },
    {
      request: {
        query: FIND_GROUP_OUTCOMES,
        variables: {
          id: groupId,
          outcomesContextId: contextId,
          outcomesContextType: contextType,
          outcomeIsImported,
          searchQuery,
          targetGroupId,
        },
      },
      result: {
        data: {
          group: {
            _id: groupId,
            title,
            description: `${groupDescription} 2`,
            contextType: outcomesGroupContextType,
            contextId: outcomesGroupContextId,
            outcomesCount: 0,
            notImportedOutcomesCount,
            outcomes: {
              pageInfo: {
                hasNextPage: withMorePage,
                endCursor: 'Mg',
                __typename: 'PageInfo',
              },
              edges: [
                {
                  _id: '1',
                  node: {
                    _id: '1',
                    description: '',
                    title: `Outcome 1 - ${title}`,
                    calculationMethod,
                    calculationInt,
                    masteryPoints,
                    ratings,
                    canArchive,
                    isImported: outcomeIsImported,
                    __typename: 'LearningOutcome',
                    friendlyDescription: {
                      description: 'Outcome 1 - friendly description',
                      __typename: 'FriendlyDescription',
                      _id: '101',
                    },
                  },
                  __typename: 'ContentTag',
                },
                {
                  _id: '3',
                  node: {
                    _id: '3',
                    description: '',
                    title: `Outcome 3 - ${title}`,
                    calculationMethod,
                    calculationInt,
                    masteryPoints,
                    ratings,
                    canArchive,
                    isImported: outcomeIsImported,
                    __typename: 'LearningOutcome',
                    friendlyDescription: {
                      description: 'Outcome 3 - friendly description',
                      __typename: 'FriendlyDescription',
                      _id: '103',
                    },
                  },
                  __typename: 'ContentTag',
                },
              ],
              __typename: 'ContentTagConnection',
            },
            __typename: 'LearningOutcomeGroup',
          },
        },
      },
    },
    {
      request: {
        query: FIND_GROUP_OUTCOMES,
        variables: {
          id: groupId,
          outcomesCursor: 'Mg',
          outcomeIsImported,
          outcomesContextId: contextId,
          outcomesContextType: contextType,
          searchQuery,
          targetGroupId,
        },
      },
      result: {
        data: {
          group: {
            _id: groupId,
            title,
            description: `${groupDescription} 3`,
            contextType: outcomesGroupContextType,
            contextId: outcomesGroupContextId,
            outcomesCount: 0,
            notImportedOutcomesCount,
            outcomes: {
              pageInfo: {
                hasNextPage: false,
                endCursor: 'Mw',
                __typename: 'PageInfo',
              },
              edges: [
                {
                  _id: '5',
                  node: {
                    _id: '5',
                    description: '',
                    isImported: false,
                    title: `Outcome 5 - ${title}`,
                    calculationMethod,
                    calculationInt,
                    masteryPoints,
                    ratings,
                    canArchive,
                    __typename: 'LearningOutcome',
                    friendlyDescription: {
                      description: 'Outcome 5 - friendly description',
                      __typename: 'FriendlyDescription',
                      _id: '105',
                    },
                  },
                  __typename: 'ContentTag',
                },
                {
                  _id: '6',
                  node: {
                    _id: '6',
                    description: '',
                    isImported: outcomeIsImported,
                    title: `Outcome 6 - ${title}`,
                    calculationMethod,
                    calculationInt,
                    masteryPoints,
                    ratings,
                    canArchive,
                    __typename: 'LearningOutcome',
                    friendlyDescription: {
                      description: 'Outcome 6 - friendly description',
                      __typename: 'FriendlyDescription',
                      _id: '106',
                    },
                  },
                  __typename: 'ContentTag',
                },
              ],
              __typename: 'ContentTagConnection',
            },
            __typename: 'LearningOutcomeGroup',
          },
        },
      },
    },
    {
      request: {
        query: SEARCH_GROUP_OUTCOMES,
        variables: {
          id: groupId,
          outcomeIsImported,
          outcomesContextId: contextId,
          outcomesContextType: contextType,
          targetGroupId,
        },
      },
      result: {
        data: {
          group: {
            _id: groupId,
            description: `${groupDescription} 4`,
            title,
            outcomesCount: numOfOutcomes,
            notImportedOutcomesCount,
            outcomes: {
              pageInfo: {
                hasNextPage: withMorePage,
                endCursor: 'Mx',
                __typename: 'PageInfo',
              },
              edges: createSearchGroupOutcomesOutcomeMocks(
                canUnlink,
                canEdit,
                canArchive,
                contextId,
                contextType,
                title,
                numOfOutcomes
              ),
              __typename: 'ContentTagConnection',
            },
            __typename: 'LearningOutcomeGroup',
          },
        },
      },
      // for testing graphqls refetch in index.js
      newData: jest.fn(() => {
        const outcome1 = {
          canUnlink,
          _id: '1',
          node: {
            _id: '1',
            description: '',
            title: `Refetched Outcome 1 - ${title}`,
            displayName: '',
            calculationMethod,
            calculationInt,
            masteryPoints,
            ratings,
            canArchive,
            canEdit,
            contextId,
            contextType,
            friendlyDescription: {
              _id: '26',
              description: 'friendly',
              __typename: 'OutcomeFriendlyDescriptionType',
            },
            __typename: 'LearningOutcome',
          },
          group: {
            _id: groupId,
            title: `Refetched ${title}`,
            __typename: 'LearningOutcomeGroup',
          },
          __typename: 'ContentTag',
        }
        const outcome2 = {
          canUnlink,
          _id: '2',
          node: {
            _id: '2',
            description: '',
            title: `Refetched Outcome 2 - ${title}`,
            displayName: '',
            calculationMethod,
            calculationInt,
            masteryPoints,
            ratings,
            canEdit,
            canArchive,
            contextId,
            contextType,
            friendlyDescription: null,
            __typename: 'LearningOutcome',
          },
          group: {
            _id: groupId,
            title: `Refetched ${title}`,
            __typename: 'LearningOutcomeGroup',
          },
          __typename: 'ContentTag',
        }
        const outcome3 = {
          canUnlink,
          _id: '11',
          node: {
            _id: '11',
            description: '',
            title: `Newly Created Outcome - ${title}`,
            displayName: '',
            calculationMethod,
            calculationInt,
            masteryPoints,
            ratings,
            canEdit,
            canArchive,
            contextId,
            contextType,
            friendlyDescription: null,
            __typename: 'LearningOutcome',
          },
          group: {
            _id: groupId,
            title: `Refetched ${title}`,
            __typename: 'LearningOutcomeGroup',
          },
          __typename: 'ContentTag',
        }
        const edges = [outcome1, outcome2, outcome3]
        const afterRemoveEdges = [outcome3]
        return {
          data: {
            group: {
              _id: groupId,
              description: `${groupDescription} 4`,
              title: `Refetched ${title}`,
              outcomesCount: removeOnRefetch ? afterRemoveEdges.length : edges.length,
              notImportedOutcomesCount,
              outcomes: {
                pageInfo: {
                  hasNextPage: withMorePage,
                  endCursor: 'Mx',
                  __typename: 'PageInfo',
                },
                edges: removeOnRefetch ? afterRemoveEdges : edges,
                __typename: 'ContentTagConnection',
              },
              __typename: 'LearningOutcomeGroup',
            },
          },
        }
      }),
    },
    {
      request: {
        query: SEARCH_GROUP_OUTCOMES,
        variables: {
          id: groupId,
          outcomesCursor: 'Mx',
          outcomeIsImported,
          outcomesContextId: contextId,
          outcomesContextType: contextType,
          targetGroupId,
        },
      },
      result: {
        data: {
          group: {
            _id: groupId,
            description: `${groupDescription} 5`,
            title,
            outcomesCount: 2,
            notImportedOutcomesCount,
            outcomes: {
              pageInfo: {
                hasNextPage: false,
                endCursor: null,
                __typename: 'PageInfo',
              },
              edges: [
                {
                  canUnlink,
                  _id: '3',
                  node: {
                    _id: '3',
                    description: '',
                    title: `Outcome 3 - ${title}`,
                    displayName: '',
                    calculationMethod,
                    calculationInt,
                    masteryPoints,
                    ratings,
                    canEdit,
                    canArchive,
                    contextId,
                    contextType,
                    friendlyDescription: null,
                    __typename: 'LearningOutcome',
                  },
                  group: {
                    _id: '101',
                    title: 'Outcome Group 1',
                    __typename: 'LearningOutcomeGroup',
                  },
                  __typename: 'ContentTag',
                },
                {
                  canUnlink,
                  _id: '4',
                  node: {
                    _id: '4',
                    description: '',
                    title: `Outcome 4 - ${title}`,
                    displayName: '',
                    calculationMethod,
                    calculationInt,
                    masteryPoints,
                    ratings,
                    canEdit,
                    canArchive,
                    contextId,
                    contextType,
                    friendlyDescription: null,
                    __typename: 'LearningOutcome',
                  },
                  group: {
                    _id: '101',
                    title: 'Outcome Group 1',
                    __typename: 'LearningOutcomeGroup',
                  },
                  __typename: 'ContentTag',
                },
              ],
              __typename: 'ContentTagConnection',
            },
            __typename: 'LearningOutcomeGroup',
          },
        },
      },
    },
    {
      request: {
        query: SEARCH_GROUP_OUTCOMES,
        variables: {
          id: groupId,
          outcomeIsImported,
          outcomesContextId: contextId,
          outcomesContextType: contextType,
          searchQuery,
          targetGroupId,
        },
      },
      result: {
        data: {
          group: {
            _id: groupId,
            description: `${groupDescription} 6`,
            title,
            outcomesCount: 1,
            notImportedOutcomesCount,
            outcomes: {
              pageInfo: {
                hasNextPage: false,
                endCursor: null,
                __typename: 'PageInfo',
              },
              edges: [
                {
                  canUnlink,
                  _id: '1',
                  node: {
                    _id: '1',
                    description: '',
                    title: `Outcome 1 - ${title}`,
                    displayName: '',
                    calculationMethod,
                    calculationInt,
                    masteryPoints,
                    ratings,
                    canEdit,
                    canArchive,
                    contextId,
                    contextType,
                    friendlyDescription: null,
                    __typename: 'LearningOutcome',
                  },
                  group: {
                    _id: '101',
                    title: 'Outcome Group 1',
                    __typename: 'LearningOutcomeGroup',
                  },
                  __typename: 'ContentTag',
                },
              ],
              __typename: 'ContentTagConnection',
            },
            __typename: 'LearningOutcomeGroup',
          },
        },
      },
    },
  ]
}

export const groupDetailMocksFetchMore = ({
  groupId = '1',
  title = `Group ${groupId}`,
  canEdit = true,
  canUnlink = true,
  canArchive = true,
  contextType = 'Account',
  contextId = '1',
  withMorePage = true,
  outcomeIsImported = false,
  groupDescription = 'Group Description',
  targetGroupId,
  notImportedOutcomesCount = null,
} = {}) => {
  const calculationMethod = 'decaying_average'
  const calculationInt = 65
  const masteryPoints = defaultMasteryPoints
  const ratings = ratingsWithTypename(testRatings)

  return [
    {
      request: {
        query: SEARCH_GROUP_OUTCOMES,
        variables: {
          id: groupId,
          outcomeIsImported,
          outcomesContextId: contextId,
          outcomesContextType: contextType,
          targetGroupId,
        },
      },
      result: {
        data: {
          group: {
            _id: groupId,
            description: `${groupDescription} 4`,
            title,
            outcomesCount: 2,
            notImportedOutcomesCount,
            outcomes: {
              pageInfo: {
                hasNextPage: withMorePage,
                endCursor: 'Mx',
                __typename: 'PageInfo',
              },
              edges: [
                {
                  canUnlink,
                  _id: '1',
                  node: {
                    _id: '1',
                    description: '',
                    title: `Outcome 1 - ${title}`,
                    displayName: '',
                    calculationMethod,
                    calculationInt,
                    masteryPoints,
                    ratings,
                    canEdit,
                    canArchive,
                    contextId,
                    contextType,
                    friendlyDescription: null,
                    __typename: 'LearningOutcome',
                  },
                  group: {
                    _id: '101',
                    title: 'Outcome Group 1',
                    __typename: 'LearningOutcomeGroup',
                  },
                  __typename: 'ContentTag',
                },
                {
                  canUnlink,
                  _id: '2',
                  node: {
                    _id: '2',
                    description: '',
                    title: `Outcome 2 - ${title}`,
                    displayName: '',
                    calculationMethod,
                    calculationInt,
                    masteryPoints,
                    ratings,
                    canEdit,
                    canArchive,
                    contextId,
                    contextType,
                    friendlyDescription: null,
                    __typename: 'LearningOutcome',
                  },
                  group: {
                    _id: '101',
                    title: 'Outcome Group 1',
                    __typename: 'LearningOutcomeGroup',
                  },
                  __typename: 'ContentTag',
                },
              ],
              __typename: 'ContentTagConnection',
            },
            __typename: 'LearningOutcomeGroup',
          },
        },
      },
    },
    {
      request: {
        query: SEARCH_GROUP_OUTCOMES,
        variables: {
          id: groupId,
          outcomesCursor: 'Mx',
          outcomeIsImported,
          outcomesContextId: contextId,
          outcomesContextType: contextType,
          targetGroupId,
        },
      },
      result: {
        data: {
          group: {
            _id: groupId,
            description: `${groupDescription} 5`,
            title,
            outcomesCount: 2,
            notImportedOutcomesCount,
            outcomes: {
              pageInfo: {
                hasNextPage: false,
                endCursor: null,
                __typename: 'PageInfo',
              },
              edges: [
                {
                  canUnlink,
                  _id: '1',
                  node: {
                    _id: '1',
                    description: '',
                    title: `New Outcome 1 - ${title}`,
                    displayName: '',
                    calculationMethod,
                    calculationInt,
                    masteryPoints,
                    ratings,
                    canEdit,
                    canArchive,
                    contextId,
                    contextType,
                    friendlyDescription: null,
                    __typename: 'LearningOutcome',
                  },
                  group: {
                    _id: '101',
                    title: 'Outcome Group 1',
                    __typename: 'LearningOutcomeGroup',
                  },
                  __typename: 'ContentTag',
                },
                {
                  canUnlink,
                  _id: '3',
                  node: {
                    _id: '3',
                    description: '',
                    title: `Outcome 3 - ${title}`,
                    displayName: '',
                    calculationMethod,
                    calculationInt,
                    masteryPoints,
                    ratings,
                    canEdit,
                    canArchive,
                    contextId,
                    contextType,
                    friendlyDescription: null,
                    __typename: 'LearningOutcome',
                  },
                  group: {
                    _id: '101',
                    title: 'Outcome Group 1',
                    __typename: 'LearningOutcomeGroup',
                  },
                  __typename: 'ContentTag',
                },
              ],
              __typename: 'ContentTagConnection',
            },
            __typename: 'LearningOutcomeGroup',
          },
        },
      },
    },
  ]
}

export const findOutcomesMocks = ({
  groupId = '100',
  isImported = true,
  outcomeIsImported = true,
  contextType = 'Account',
  contextId = '1',
  outcomesGroupContextId = '1',
  outcomesGroupContextType = 'Account',
  searchQuery = 'mathematics',
  outcomesCount = 25,
  targetGroupId = '0',
  notImportedOutcomesCount = 1,
  withFindGroupRefetch = false,
} = {}) => {
  const calculationMethod = 'decaying_average'
  const calculationInt = 65
  const masteryPoints = defaultMasteryPoints
  const ratings = ratingsWithTypename(testRatings)

  const data = ({numOutcomes = outcomesCount, withRefetch = false} = {}) => ({
    data: {
      group: {
        _id: groupId,
        title: `Group ${groupId}`,
        contextType: outcomesGroupContextType,
        contextId: outcomesGroupContextId,
        outcomesCount: numOutcomes,
        notImportedOutcomesCount,
        outcomes: {
          pageInfo: {
            hasNextPage: false,
            endCursor: 'Mw',
            __typename: 'PageInfo',
          },
          edges: [
            {
              _id: '5',
              node: {
                _id: '5',
                description: '',
                isImported,
                title: `${withRefetch && 'Refetched '}Outcome 5 - Group ${groupId}`,
                calculationMethod,
                calculationInt,
                masteryPoints,
                ratings,
                __typename: 'LearningOutcome',
                friendlyDescription: {
                  _id: '5',
                  description: 'Outcome 5 - friendly description',
                  __typename: 'FriendlyDescription',
                },
              },
              __typename: 'ContentTag',
            },
            {
              _id: '6',
              node: {
                _id: '6',
                description: '',
                isImported,
                title: `${withRefetch && 'Refetched '}Outcome 6 - Group ${groupId}`,
                calculationMethod,
                calculationInt,
                masteryPoints,
                ratings,
                __typename: 'LearningOutcome',
                friendlyDescription: {
                  _id: '6',
                  description: 'Outcome 6 - friendly description',
                  __typename: 'FriendlyDescription',
                },
              },
              __typename: 'ContentTag',
            },
          ],
          __typename: 'ContentTagConnection',
        },
        __typename: 'LearningOutcomeGroup',
      },
    },
  })

  const firstResponse = {result: data()}
  if (withFindGroupRefetch) firstResponse.newData = () => data({withRefetch: withFindGroupRefetch})

  const secondResponse = {result: data({numOutcomes: 15, withRefetch: withFindGroupRefetch})}

  return [
    {
      request: {
        query: FIND_GROUP_OUTCOMES,
        variables: {
          id: groupId,
          outcomeIsImported,
          outcomesContextId: contextId,
          outcomesContextType: contextType,
          targetGroupId,
        },
      },
      ...firstResponse,
    },
    {
      request: {
        query: FIND_GROUP_OUTCOMES,
        variables: {
          id: groupId,
          outcomeIsImported,
          outcomesContextId: contextId,
          outcomesContextType: contextType,
          searchQuery,
          targetGroupId,
        },
      },
      ...secondResponse,
    },
  ]
}

export const setFriendlyDescriptionOutcomeMock = ({
  inputDescription = 'Updated friendly description',
  failResponse = false,
} = {}) => {
  const successfulResponse = {
    data: {
      setFriendlyDescription: {
        outcomeFriendlyDescription: {
          _id: '1',
          description: 'Updated friendly description',
          __typename: 'OutcomeFriendlyDescription',
        },
        __typename: 'SetFriendlyDescriptionPayload',
        errors: null,
      },
    },
  }

  const failedResponse = {
    data: null,
    errors: [
      {
        attribute: 'message',
        message: 'mutation failed',
      },
    ],
  }

  let result = successfulResponse
  if (failResponse) {
    result = failedResponse
  }

  return {
    request: {
      query: SET_OUTCOME_FRIENDLY_DESCRIPTION_MUTATION,
      variables: {
        input: {
          description: inputDescription,
          contextId: '1',
          contextType: 'Account',
          outcomeId: '1',
        },
      },
    },
    result,
  }
}

export const createLearningOutcomeMock = ({
  title = 'Outcome title',
  description = 'description',
  displayName = 'display name',
  groupId = '1',
  failResponse = false,
  failMutation = false,
  calculationMethod = 'decaying_average',
  calculationInt = 65,
  individualCalculation = false,
  masteryPoints = defaultMasteryPoints,
  ratings = testRatings,
  individualRatings = false,
} = {}) => {
  const pointsPossible = maxPoints(ratings)
  const outputRatings = ratingsWithTypename(ratings)

  const successfulResponse = {
    data: {
      createLearningOutcome: {
        learningOutcome: {
          _id: '1',
          title,
          description,
          displayName,
          calculationMethod,
          calculationInt,
          masteryPoints,
          pointsPossible,
          ratings: outputRatings,
          __typename: 'LearningOutcome',
        },
        __typename: 'CreateLearningOutcomePayload',
        errors: null,
      },
    },
    errors: null,
  }

  const failedResponse = {
    __typename: 'ErrorResponse',
    data: null,
    errors: [
      {
        message: 'mutation failed',
        __typename: 'Error',
      },
    ],
  }

  const failedMutation = {
    data: {
      createLearningOutcome: {
        __typename: 'CreateLearningOutcomePayload',
        learningOutcome: null,
        errors: [
          {
            attribute: 'message',
            message: 'mutation failed',
            __typename: 'Error',
          },
        ],
      },
    },
  }

  let result = successfulResponse
  if (failResponse) {
    result = failedResponse
  } else if (failMutation) {
    result = failedMutation
  }

  const input = {
    groupId,
    title,
    description,
    displayName,
  }
  if (individualCalculation) {
    input.calculationMethod = calculationMethod
    input.calculationInt = calculationInt
  }
  if (individualRatings) {
    input.masteryPoints = masteryPoints
    input.ratings = ratings
  }

  return {
    request: {
      query: CREATE_LEARNING_OUTCOME,
      variables: {
        input,
      },
    },
    result,
  }
}

export const updateLearningOutcomeMocks = ({
  id = '1',
  title = 'Updated name',
  displayName = 'Friendly outcome name',
  description = 'Updated description',
  calculationMethod = 'decaying_average',
  calculationInt = 65,
  individualCalculation = false,
  masteryPoints = defaultMasteryPoints,
  ratings = testRatings,
  individualRatings = false,
} = {}) => {
  const pointsPossible = maxPoints(ratings)
  const outputRatings = ratingsWithTypename(ratings)

  const input = {
    title,
    displayName,
    description,
  }
  if (individualCalculation) {
    input.calculationMethod = calculationMethod
    input.calculationInt = calculationInt
  }
  if (individualRatings) {
    input.masteryPoints = masteryPoints
    input.ratings = ratings
  }
  const output = {
    ...input,
    calculationMethod,
    calculationInt,
    masteryPoints,
    pointsPossible,
    ratings: outputRatings,
  }
  if (description === null) delete input.description

  return [
    {
      request: {
        query: UPDATE_LEARNING_OUTCOME,
        variables: {
          input: {
            id,
            ...input,
          },
        },
      },
      result: {
        data: {
          updateLearningOutcome: {
            __typename: 'UpdateLearningOutcomePayload',
            learningOutcome: {
              __typename: 'LearningOutcome',
              _id: '1',
              ...output,
            },
            errors: null,
          },
        },
      },
    },
    {
      request: {
        query: UPDATE_LEARNING_OUTCOME,
        variables: {
          input: {
            id: '3',
            ...input,
          },
        },
      },
      result: {
        data: {
          updateLearningOutcome: {
            __typename: 'UpdateLearningOutcomePayload',
            learningOutcome: {
              __typename: 'LearningOutcome',
              _id: '1',
              ...output,
            },
            errors: null,
          },
        },
      },
    },
    {
      request: {
        query: UPDATE_LEARNING_OUTCOME,
        variables: {
          input: {
            id: '2',
            ...input,
          },
        },
      },
      result: {
        data: null,
        errors: [
          {
            attribute: 'title',
            message: "can't be blank",
          },
        ],
      },
    },
  ]
}

export const importOutcomeMocks = ({
  outcomeId = '200',
  progressId = '211',
  sourceContextId = null,
  sourceContextType = null,
  targetContextId = '1',
  targetContextType = 'Account',
  failResponse = false,
  failMutationNoErrMsg = false,
  targetGroupId,
} = {}) => {
  const successfulResponse = {
    data: {
      importOutcomes: {
        errors: null,
        progress: {
          _id: progressId,
          state: 'queued',
          __typename: 'Progress',
        },
        __typename: 'ImportOutcomesPayload',
      },
    },
  }

  const failedResponse = {
    __typename: 'ErrorResponse',
    data: {
      importOutcomes: null,
    },
    errors: [
      {
        attribute: outcomeId,
        message: 'Network error',
        __typename: 'Error',
      },
    ],
  }

  const failedMutationNoErrMsg = {
    data: {
      importOutcomes: {
        __typename: 'ErrorResponse',
        progress: null,
        errors: [
          {
            attribute: 'message',
            message: '',
            __typename: 'Error',
          },
        ],
      },
    },
  }

  let result = successfulResponse
  if (failResponse) {
    result = failedResponse
  } else if (failMutationNoErrMsg) {
    result = failedMutationNoErrMsg
  }

  let input = {
    outcomeId,
  }

  if (targetGroupId) {
    input.targetGroupId = targetGroupId
  } else {
    input.targetContextId = targetContextId
    input.targetContextType = targetContextType
  }

  if (sourceContextId && sourceContextType) {
    input = {
      ...input,
      sourceContextId,
      sourceContextType,
    }
  }

  return [
    {
      request: {
        query: IMPORT_OUTCOMES,
        variables: {
          input,
        },
      },
      result,
    },
  ]
}

export const deleteOutcomeMock = ({
  ids = ['1'],
  failResponse = false,
  failAlignedContentMutation = false,
  failMutation = false,
  failMutationNoErrMsg = false,
  partialSuccess = false,
} = {}) => {
  const successfulResponse = {
    data: {
      deleteOutcomeLinks: {
        __typename: 'DeleteOutcomeLinksPayload',
        deletedOutcomeLinkIds: ids,
        errors: [],
      },
    },
  }

  const failedResponse = {
    __typename: 'ErrorResponse',
    data: null,
    errors: [
      {
        attribute: ids[0],
        message: 'Could not find associated outcome in this context',
        __typename: 'Error',
      },
    ],
  }

  const failedAlignedContentMutation = {
    data: {
      deleteOutcomeLinks: {
        __typename: 'DeleteOutcomeLinksPayload',
        deletedOutcomeLinkIds: [],
        errors: [
          {
            attribute: [],
            message: 'cannot be deleted because it is aligned to content',
            __typename: 'Error',
          },
        ],
      },
    },
  }
  const failedMutation = {
    data: {
      deleteOutcomeLinks: {
        __typename: 'DeleteOutcomeLinksPayload',
        deletedOutcomeLinkIds: [],
        errors: [
          {
            attribute: 'message',
            message: '',
            __typename: 'Error',
          },
        ],
      },
    },
  }

  const failedMutationNoErrMsg = {
    data: {
      deleteOutcomeLinks: {
        __typename: 'DeleteOutcomeLinksPayload',
        deletedOutcomeLinkIds: [],
        errors: [
          {
            attribute: 'message',
            message: '',
            __typename: 'Error',
          },
        ],
      },
    },
  }

  const partialSuccessResponse = {
    data: {
      deleteOutcomeLinks: {
        __typename: 'DeleteOutcomeLinksPayload',
        deletedOutcomeLinkIds: ids.filter((_id, idx) => idx !== 0),
        errors: [
          {
            attribute: ids[0],
            message: 'Could not find associated outcome in this context',
            __typename: 'Error',
          },
        ],
      },
    },
  }

  let result = successfulResponse
  if (failResponse) {
    result = failedResponse
  } else if (failAlignedContentMutation) {
    result = failedAlignedContentMutation
  } else if (failMutation) {
    result = failedMutation
  } else if (failMutationNoErrMsg) {
    result = failedMutationNoErrMsg
  } else if (partialSuccess) {
    result = partialSuccessResponse
  }

  return {
    request: {
      query: DELETE_OUTCOME_LINKS,
      variables: {
        input: {
          ids,
        },
      },
    },
    result,
  }
}

export const deleteOutcomeMocks = ({
  ids = ['1'],
  failResponse = false,
  failAlignedContentMutation = false,
  failMutation = false,
  failMutationNoErrMsg = false,
  partialSuccess = false,
} = {}) => {
  const successfulResponse = {
    data: {
      deleteOutcomeLinks: {
        __typename: 'DeleteOutcomeLinksPayload',
        deletedOutcomeLinkIds: ids,
        errors: [],
      },
    },
  }

  const failedResponse = {
    __typename: 'ErrorResponse',
    data: null,
    errors: [
      {
        attribute: ids[0],
        message: 'Could not find associated outcome in this context',
        __typename: 'Error',
      },
    ],
  }

  const failedAlignedContentMutation = {
    data: {
      deleteOutcomeLinks: {
        __typename: 'DeleteOutcomeLinksPayload',
        deletedOutcomeLinkIds: [],
        errors: [
          {
            attribute: [],
            message: 'cannot be deleted because it is aligned to content',
            __typename: 'Error',
          },
        ],
      },
    },
  }
  const failedMutation = {
    data: {
      deleteOutcomeLinks: {
        __typename: 'DeleteOutcomeLinksPayload',
        deletedOutcomeLinkIds: [],
        errors: [
          {
            attribute: 'message',
            message: '',
            __typename: 'Error',
          },
        ],
      },
    },
  }

  const failedMutationNoErrMsg = {
    data: {
      deleteOutcomeLinks: {
        __typename: 'DeleteOutcomeLinksPayload',
        deletedOutcomeLinkIds: [],
        errors: [
          {
            attribute: 'message',
            message: '',
            __typename: 'Error',
          },
        ],
      },
    },
  }

  const partialSuccessResponse = {
    data: {
      deleteOutcomeLinks: {
        __typename: 'DeleteOutcomeLinksPayload',
        deletedOutcomeLinkIds: ids.filter((_id, idx) => idx !== 0),
        errors: [
          {
            attribute: ids[0],
            message: 'Could not find associated outcome in this context',
            __typename: 'Error',
          },
        ],
      },
    },
  }

  let result = successfulResponse
  if (failResponse) {
    result = failedResponse
  } else if (failAlignedContentMutation) {
    result = failedAlignedContentMutation
  } else if (failMutation) {
    result = failedMutation
  } else if (failMutationNoErrMsg) {
    result = failedMutationNoErrMsg
  } else if (partialSuccess) {
    result = partialSuccessResponse
  }

  return [
    {
      request: {
        query: DELETE_OUTCOME_LINKS,
        variables: {
          input: {
            ids,
          },
        },
      },
      result,
    },
  ]
}

export const moveOutcomeMock = ({
  groupId = '101',
  outcomeLinkIds = ['1', '2'],
  parentGroupTitle = 'Outcome Group',
  failResponse = false,
  failMutation = false,
  failMutationNoErrMsg = false,
  partialSuccess = false,
} = {}) => {
  const successfulResponse = {
    data: {
      moveOutcomeLinks: {
        __typename: 'MoveOutcomeLinksPayload',
        movedOutcomeLinks: outcomeLinkIds.map(idx => ({
          _id: idx,
          group: {
            _id: groupId,
            title: parentGroupTitle,
            __typename: 'LearningOutcomeGroup',
          },
          __typename: 'ContentTag',
        })),
        errors: null,
      },
    },
  }

  const failedResponse = {
    data: null,
    errors: [
      {
        attribute: outcomeLinkIds[0],
        message: 'Could not find associated outcome in this context',
        __typename: 'Error',
      },
    ],
  }

  const failedMutation = {
    data: {
      moveOutcomeLinks: {
        __typename: 'MoveOutcomeLinksPayload',
        movedOutcomeLinks: [],
        errors: [
          {
            attribute: 'message',
            message: 'Mutation failed',
            __typename: 'Error',
          },
        ],
      },
    },
  }

  const failedMutationNoErrMsg = {
    data: {
      moveOutcomeLinks: {
        __typename: 'MoveOutcomeLinksPayload',
        movedOutcomeLinks: [],
        errors: [
          {
            attribute: 'message',
            message: '',
            __typename: 'Error',
          },
        ],
      },
    },
  }

  const partialSuccessResponse = {
    data: {
      moveOutcomeLinks: {
        movedOutcomeLinks: outcomeLinkIds
          .filter((_outcomeLinkId, idx) => idx !== 0)
          .map(idx => ({
            _id: idx,
            group: {
              _id: '101',
              title: parentGroupTitle,
              __typename: 'LearningOutcomeGroup',
            },
            __typename: 'ContentTag',
          })),
        __typename: 'MoveOutcomeLinksPayload',
        errors: [
          {
            attribute: outcomeLinkIds[0],
            message: 'Could not find associated outcome in this context',
            __typename: 'Error',
          },
        ],
      },
    },
  }

  let result = successfulResponse
  if (failResponse) {
    result = failedResponse
  } else if (failMutation) {
    result = failedMutation
  } else if (failMutationNoErrMsg) {
    result = failedMutationNoErrMsg
  } else if (partialSuccess) {
    result = partialSuccessResponse
  }

  return {
    request: {
      query: MOVE_OUTCOME_LINKS,
      variables: {
        input: {
          groupId,
          outcomeLinkIds,
        },
      },
    },
    result,
  }
}

export const updateOutcomeGroupMock = ({
  id = '100',
  title = 'Updated title',
  returnTitle = 'Updated title',
  description = 'Updated description',
  vendorGuid = 'A001',
  parentOutcomeGroupId = '101',
  parentOutcomeGroupTitle = 'Parent Outcome Group',
  failResponse = false,
  failMutation = false,
  failMutationNoErrMsg = false,
} = {}) => {
  const successfulResponse = {
    data: {
      updateLearningOutcomeGroup: {
        learningOutcomeGroup: {
          _id: id,
          title: returnTitle,
          description,
          vendorGuid,
          parentOutcomeGroup: {
            _id: parentOutcomeGroupId,
            title: parentOutcomeGroupTitle,
            __typename: 'LearningOutcomeGroup',
          },
          __typename: 'LearningOutcomeGroup',
        },
        errors: null,
        __typename: 'UpdateLearningOutcomeGroupPayload',
      },
    },
  }

  const failedResponse = {
    __typename: 'ErrorResponse',
    data: null,
    errors: [
      {
        attribute: id,
        message: 'Network error',
        __typename: 'Error',
      },
    ],
  }

  const failedMutation = {
    data: {
      updateLearningOutcomeGroup: {
        __typename: 'UpdateLearningOutcomeGroupPayload',
        learningOutcomeGroup: null,
        errors: [
          {
            attribute: 'message',
            message: 'Mutation failed',
            __typename: 'Error',
          },
        ],
      },
    },
  }

  const failedMutationNoErrMsg = {
    data: {
      updateLearningOutcomeGroup: {
        __typename: 'UpdateLearningOutcomeGroupPayload',
        learningOutcomeGroup: null,
        errors: [
          {
            attribute: 'message',
            message: '',
            __typename: 'Error',
          },
        ],
      },
    },
  }

  let result = successfulResponse
  if (failResponse) {
    result = failedResponse
  } else if (failMutation) {
    result = failedMutation
  } else if (failMutationNoErrMsg) {
    result = failedMutationNoErrMsg
  }

  const input = {id}
  if (title) input.title = title
  if (description) input.description = description
  if (vendorGuid) input.vendorGuid = vendorGuid
  if (parentOutcomeGroupId) input.parentOutcomeGroupId = parentOutcomeGroupId

  return {
    request: {
      query: UPDATE_LEARNING_OUTCOME_GROUP,
      variables: {
        input,
      },
    },
    result,
  }
}

export const importGroupMocks = ({
  groupId = '100',
  progressId = '111',
  targetContextId = '1',
  targetContextType = 'Account',
  targetGroupId,
  failResponse = false,
  failMutationNoErrMsg = false,
} = {}) => {
  const successfulResponse = {
    data: {
      importOutcomes: {
        progress: {
          _id: progressId,
          state: 'queued',
          __typename: 'Progress',
        },
        errors: null,
        __typename: 'ImportOutcomesPayload',
      },
    },
  }

  const failedResponse = {
    __typename: 'ErrorResponse',
    data: {
      importOutcomes: null,
    },
    errors: [
      {
        attribute: groupId,
        message: 'Network error',
        __typename: 'Error',
      },
    ],
  }

  const failedMutationNoErrMsg = {
    data: {
      importOutcomes: {
        __typename: 'ErrorResponse',
        progress: null,
        errors: [
          {
            attribute: 'message',
            message: '',
            __typename: 'Error',
          },
        ],
      },
    },
  }

  let result = successfulResponse
  if (failResponse) {
    result = failedResponse
  } else if (failMutationNoErrMsg) {
    result = failedMutationNoErrMsg
  }

  const input = {
    groupId,
  }

  if (targetGroupId) {
    input.targetGroupId = targetGroupId
  } else {
    input.targetContextType = targetContextType
    input.targetContextId = targetContextId
  }

  return [
    {
      request: {
        query: IMPORT_OUTCOMES,
        variables: {
          input,
        },
      },
      result,
    },
  ]
}

export const createOutcomeGroupMocks = ({
  id = '101',
  title = 'New Group',
  description = null,
  vendorGuid = null,
  parentOutcomeGroupId = '100',
  parentOutcomeGroupTitle = 'Parent Outcome Group',
  failResponse = false,
  failMutation = false,
  failMutationNoErrMsg = false,
} = {}) => {
  const successfulResponse = {
    data: {
      createLearningOutcomeGroup: {
        learningOutcomeGroup: {
          _id: id,
          title,
          description,
          vendorGuid,
          parentOutcomeGroup: {
            _id: parentOutcomeGroupId,
            title: parentOutcomeGroupTitle,
            __typename: 'LearningOutcomeGroup',
          },
          __typename: 'LearningOutcomeGroup',
        },
        errors: null,
        __typename: 'CreateLearningOutcomeGroupPayload',
      },
    },
  }

  const failedResponse = {
    __typename: 'ErrorResponse',
    data: null,
    errors: [
      {
        attribute: id,
        message: 'Network error',
        __typename: 'Error',
      },
    ],
  }

  const failedMutation = {
    data: {
      createLearningOutcomeGroup: {
        __typename: 'CreateLearningOutcomeGroupPayload',
        learningOutcomeGroup: null,
        errors: [
          {
            attribute: 'message',
            message: 'Mutation failed',
            __typename: 'Error',
          },
        ],
      },
    },
  }

  const failedMutationNoErrMsg = {
    data: {
      createLearningOutcomeGroup: {
        __typename: 'CreateLearningOutcomeGroupPayload',
        learningOutcomeGroup: null,
        errors: [
          {
            attribute: 'message',
            message: '',
            __typename: 'Error',
          },
        ],
      },
    },
  }

  let result = successfulResponse
  if (failResponse) {
    result = failedResponse
  } else if (failMutation) {
    result = failedMutation
  } else if (failMutationNoErrMsg) {
    result = failedMutationNoErrMsg
  }

  const input = {
    id: parentOutcomeGroupId,
    title,
  }
  if (description) input.description = description
  if (vendorGuid) input.vendorGuid = vendorGuid

  return [
    {
      request: {
        query: CREATE_LEARNING_OUTCOME_GROUP,
        variables: {
          input,
        },
      },
      result,
    },
  ]
}

export const smallOutcomeTree = ({group100childCounts = 1} = {}) => [
  ...accountMocks({childGroupsCount: 2}),
  ...groupMocks({
    groupId: '100',
    childGroupOffset: 400,
    parentOutcomeGroupId: '1',
    childGroupsCount: group100childCounts,
    title: 'Account folder 0',
    parentOutcomeGroupTitle: 'Root account folder',
  }),
  ...groupMocks({
    groupId: '101',
    childGroupsCount: 0,
    parentOutcomeGroupId: '1',
    title: 'Account folder 1',
    parentOutcomeGroupTitle: 'Root account folder',
  }),
  ...groupMocks({
    groupId: '400',
    childGroupsCount: 0,
    parentOutcomeGroupId: '100',
    parentOutcomeGroupTitle: 'Account folder 0',
    title: 'Group 100 folder 0',
  }),
  ...groupDetailMocks({groupId: '100'}),
  ...groupDetailMocks({groupId: '101'}),
  ...groupDetailMocks({groupId: '400'}),
]

export const courseAlignmentStatsMocks = ({
  id = '1',
  totalOutcomes = 2,
  alignedOutcomes = 1,
  totalAlignments = 4,
  totalArtifacts = 5,
  alignedArtifacts = 3,
  artifactAlignments = 3,
  refetchIncrement = 10,
} = {}) => {
  const returnResult = (inc = 0) => ({
    data: {
      course: {
        outcomeAlignmentStats: {
          totalOutcomes: totalOutcomes + inc,
          alignedOutcomes: alignedOutcomes + inc,
          totalAlignments: totalAlignments + inc,
          totalArtifacts: totalArtifacts + inc,
          alignedArtifacts: alignedArtifacts + inc,
          artifactAlignments: artifactAlignments + inc,
          __typename: 'CourseOutcomeAlignmentStats',
        },
        __typename: 'Course',
      },
    },
  })

  return [
    {
      request: {
        query: COURSE_ALIGNMENT_STATS,
        variables: {id},
      },
      result: returnResult(),
      // for testing data refetch
      newData: () => returnResult(refetchIncrement),
    },
  ]
}

export const courseAlignmentMocks = ({
  groupId = '1',
  contextType = 'Course',
  contextId = '1',
  numOfOutcomes = 4,
  searchFilter = 'ALL_OUTCOMES',
  searchQuery = '',
  testSearchQuery = 'TEST',
} = {}) => {
  const generateAlignment = ({
    id = '1',
    courseId = '1',
    outcomeId = '3',
    title = 'Alignment 1',
    contentType = 'Assignment',
    assignmentContentType = 'assignment',
    assignmentWorkflowState = 'published',
    moduleName = 'Module 1',
    moduleWorkflowState = 'active',
    quizItems = [],
    alignmentsCount = 1,
  } = {}) => ({
    _id: id,
    title,
    contentType,
    assignmentContentType,
    assignmentWorkflowState,
    url: `/courses/${courseId}/outcomes/${outcomeId}/alignments/${id}`,
    moduleName,
    moduleUrl: `/courses/${courseId}/modules/1`,
    moduleWorkflowState,
    quizItems,
    alignmentsCount,
    __typename: 'Alignments',
  })

  const generateAlignments = (num = 2) =>
    [...Array(num).keys()].map(el =>
      generateAlignment({id: `${el + 1}`, title: `Alignment ${el + 1}`})
    )

  const generateOutcomeNode = (outcomeId, withAlignments = true, isRefetch = false) => ({
    _id: outcomeId,
    title: `Outcome ${outcomeId}${withAlignments ? ' with alignments' : ''}${
      isRefetch ? ' - Refetched' : ''
    }`,
    description: `Outcome ${outcomeId} description`,
    __typename: 'LearningOutcome',
    alignments: withAlignments ? generateAlignments() : null,
  })

  const generateEdges = (outcomeIds, isRefetch = false) => {
    const edges = (testSearch = false) =>
      (outcomeIds || []).map(id => ({
        node: generateOutcomeNode(id, !!(id % 2 !== 0 || testSearch), isRefetch),
        __typename: 'ContentTag',
      }))
    if (searchFilter === 'WITH_ALIGNMENTS')
      return edges().filter(edgeNode => edgeNode.node.alignments !== null)
    if (searchFilter === 'NO_ALIGNMENTS')
      return edges().filter(edgeNode => edgeNode.node.alignments === null)
    if (searchFilter === 'ALL_OUTCOMES' && searchQuery === testSearchQuery) return edges(true)
    return edges()
  }

  const variables = {
    id: groupId,
    outcomesContextId: contextId,
    outcomesContextType: contextType,
    searchFilter,
  }
  if (searchQuery) variables.searchQuery = searchQuery

  const returnResult = (isRefetch = false) => ({
    data: {
      group: {
        _id: groupId,
        outcomesCount: numOfOutcomes,
        __typename: 'LearningOutcomeGroup',
        outcomes: {
          pageInfo: {
            hasNextPage: true,
            endCursor: 'Mg',
            __typename: 'PageInfo',
          },
          edges: numOfOutcomes > 0 ? generateEdges([1, 2], isRefetch) : [],
          __typename: 'ContentTagConnection',
        },
      },
    },
  })

  return [
    {
      request: {
        query: SEARCH_OUTCOME_ALIGNMENTS,
        variables,
      },
      result: returnResult(),
      // for testing data refetch
      newData: () => returnResult(true),
    },
    {
      request: {
        query: SEARCH_OUTCOME_ALIGNMENTS,
        variables: {
          ...variables,
          outcomesCursor: 'Mg',
        },
      },
      result: {
        data: {
          group: {
            _id: groupId,
            outcomesCount: numOfOutcomes,
            __typename: 'LearningOutcomeGroup',
            outcomes: {
              pageInfo: {
                hasNextPage: false,
                endCursor: 'Mw',
                __typename: 'PageInfo',
              },
              edges: generateEdges([3, 4]),
              __typename: 'ContentTagConnection',
            },
          },
        },
      },
    },
  ]
}
