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
  CREATE_LEARNING_OUTCOME_GROUP
} from '../graphql/Management'

export const accountMocks = ({childGroupsCount = 10, accountId = '1'} = {}) => [
  {
    request: {
      query: CHILD_GROUPS_QUERY,
      variables: {
        id: accountId,
        type: 'Account'
      }
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
                title: `Account folder ${i}`
              }))
            }
          }
        }
      }
    }
  }
]

export const courseMocks = ({childGroupsCount = 1, courseId = '2'} = {}) => [
  {
    request: {
      query: CHILD_GROUPS_QUERY,
      variables: {
        id: courseId,
        type: 'Course'
      }
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
                title: `Course folder ${i}`
              }))
            }
          }
        }
      }
    }
  }
]

const buildGroup = (_id, title) => {
  if (!_id && !title) {
    return null
  }

  return {
    __typename: 'LearningOutcomeGroup',
    _id,
    title
  }
}

export const groupMocks = ({
  groupId,
  childGroupsCount = 1,
  childGroupOffset = 300,
  title = `Group ${groupId}`,
  parentOutcomeGroupId,
  parentOutcomeGroupTitle,
  childGroupTitlePrefix = `Group ${groupId} folder`
} = {}) => [
  {
    request: {
      query: CHILD_GROUPS_QUERY,
      variables: {
        id: groupId,
        type: 'LearningOutcomeGroup'
      }
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
              title: `${childGroupTitlePrefix} ${i}`
            }))
          }
        }
      }
    }
  }
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
      endCursor: ''
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
          canEdit: true
        },
        group: {
          _id: '101',
          title: 'Outcome Group 1',
          __typename: 'LearningOutcomeGroup'
        }
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
          canEdit: true
        },
        group: {
          _id: '101',
          title: 'Outcome Group 1',
          __typename: 'LearningOutcomeGroup'
        }
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
          canEdit: true
        },
        group: {
          _id: '101',
          title: 'Outcome Group 1',
          __typename: 'LearningOutcomeGroup'
        }
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
          canEdit: true
        },
        group: {
          _id: '101',
          title: 'Outcome Group 1',
          __typename: 'LearningOutcomeGroup'
        }
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
          canEdit: true
        },
        group: {
          _id: '101',
          title: 'Outcome Group 1',
          __typename: 'LearningOutcomeGroup'
        }
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
          canEdit: true
        },
        group: {
          _id: '101',
          title: 'Outcome Group 1',
          __typename: 'LearningOutcomeGroup'
        }
      }
    ]
  }
}

const createSearchGroupOutcomesOutcomeMocks = (
  canUnlink,
  canEdit,
  contextId,
  contextType,
  title,
  outcomeCount
) => {
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
          canEdit,
          contextId,
          contextType,
          friendlyDescription: null,
          __typename: 'LearningOutcome'
        },
        group: {
          _id: '101',
          title: 'Outcome Group 1',
          __typename: 'LearningOutcomeGroup'
        },
        __typename: 'ContentTag'
      },
      {
        canUnlink,
        _id: '2',
        node: {
          _id: '2',
          description: '',
          title: `Outcome 2 - ${title}`,
          displayName: '',
          canEdit,
          contextId,
          contextType,
          friendlyDescription: null,
          __typename: 'LearningOutcome'
        },
        group: {
          _id: '101',
          title: 'Outcome Group 1',
          __typename: 'LearningOutcomeGroup'
        },
        __typename: 'ContentTag'
      }
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
          canEdit,
          contextId,
          contextType,
          friendlyDescription: null,
          __typename: 'LearningOutcome'
        },
        group: {
          _id: '101',
          title: 'Outcome Group 1',
          __typename: 'LearningOutcomeGroup'
        },
        __typename: 'ContentTag'
      }
    ]
  }
}

export const groupDetailMocks = ({
  groupId = '1',
  title = `Group ${groupId}`,
  canEdit = true,
  canUnlink = true,
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
  removeOnRefetch = false
} = {}) => [
  {
    request: {
      query: FIND_GROUP_OUTCOMES,
      variables: {
        id: groupId,
        outcomesContextId: contextId,
        outcomesContextType: contextType,
        outcomeIsImported,
        targetGroupId
      }
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
              __typename: 'PageInfo'
            },
            edges: [
              {
                _id: '1',
                node: {
                  _id: '1',
                  description: '',
                  title: `Outcome 1 - ${title}`,
                  isImported: outcomeIsImported,
                  __typename: 'LearningOutcome'
                },
                __typename: 'ContentTag'
              },
              {
                _id: '2',
                node: {
                  _id: '2',
                  description: '',
                  title: `Outcome 2 - ${title}`,
                  isImported: outcomeIsImported,
                  __typename: 'LearningOutcome'
                },
                __typename: 'ContentTag'
              }
            ],
            __typename: 'ContentTagConnection'
          }
        }
      }
    }
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
        targetGroupId
      }
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
              __typename: 'PageInfo'
            },
            edges: [
              {
                _id: '1',
                node: {
                  _id: '1',
                  description: '',
                  title: `Outcome 1 - ${title}`,
                  isImported: outcomeIsImported,
                  __typename: 'LearningOutcome'
                },
                __typename: 'ContentTag'
              },
              {
                _id: '3',
                node: {
                  _id: '3',
                  description: '',
                  title: `Outcome 3 - ${title}`,
                  isImported: outcomeIsImported,
                  __typename: 'LearningOutcome'
                },
                __typename: 'ContentTag'
              }
            ],
            __typename: 'ContentTagConnection'
          },
          __typename: 'LearningOutcomeGroup'
        }
      }
    }
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
        targetGroupId
      }
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
              __typename: 'PageInfo'
            },
            edges: [
              {
                _id: '5',
                node: {
                  _id: '5',
                  description: '',
                  isImported: false,
                  friendlyDescription: null,
                  title: `Outcome 5 - ${title}`,
                  __typename: 'LearningOutcome'
                },
                __typename: 'ContentTag'
              },
              {
                _id: '6',
                node: {
                  _id: '6',
                  description: '',
                  isImported: outcomeIsImported,
                  title: `Outcome 6 - ${title}`,
                  __typename: 'LearningOutcome'
                },
                __typename: 'ContentTag'
              }
            ],
            __typename: 'ContentTagConnection'
          },
          __typename: 'LearningOutcomeGroup'
        }
      }
    }
  },
  {
    request: {
      query: SEARCH_GROUP_OUTCOMES,
      variables: {
        id: groupId,
        outcomeIsImported,
        outcomesContextId: contextId,
        outcomesContextType: contextType,
        targetGroupId
      }
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
              __typename: 'PageInfo'
            },
            edges: createSearchGroupOutcomesOutcomeMocks(
              canUnlink,
              canEdit,
              contextId,
              contextType,
              title,
              numOfOutcomes
            ),
            __typename: 'ContentTagConnection'
          },
          __typename: 'LearningOutcomeGroup'
        }
      }
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
          canEdit,
          contextId,
          contextType,
          friendlyDescription: null,
          __typename: 'LearningOutcome'
        },
        group: {
          _id: groupId,
          title: `Refetched ${title}`,
          __typename: 'LearningOutcomeGroup'
        },
        __typename: 'ContentTag'
      }
      const outcome2 = {
        canUnlink,
        _id: '2',
        node: {
          _id: '2',
          description: '',
          title: `Refetched Outcome 2 - ${title}`,
          displayName: '',
          canEdit,
          contextId,
          contextType,
          friendlyDescription: null,
          __typename: 'LearningOutcome'
        },
        group: {
          _id: groupId,
          title: `Refetched ${title}`,
          __typename: 'LearningOutcomeGroup'
        },
        __typename: 'ContentTag'
      }
      const outcome3 = {
        canUnlink,
        _id: '11',
        node: {
          _id: '11',
          description: '',
          title: `Newly Created Outcome - ${title}`,
          displayName: '',
          canEdit,
          contextId,
          contextType,
          friendlyDescription: null,
          __typename: 'LearningOutcome'
        },
        group: {
          _id: groupId,
          title: `Refetched ${title}`,
          __typename: 'LearningOutcomeGroup'
        },
        __typename: 'ContentTag'
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
                __typename: 'PageInfo'
              },
              edges: removeOnRefetch ? afterRemoveEdges : edges,
              __typename: 'ContentTagConnection'
            },
            __typename: 'LearningOutcomeGroup'
          }
        }
      }
    })
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
        targetGroupId
      }
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
              __typename: 'PageInfo'
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
                  canEdit,
                  contextId,
                  contextType,
                  friendlyDescription: null,
                  __typename: 'LearningOutcome'
                },
                group: {
                  _id: '101',
                  title: 'Outcome Group 1',
                  __typename: 'LearningOutcomeGroup'
                },
                __typename: 'ContentTag'
              },
              {
                canUnlink,
                _id: '4',
                node: {
                  _id: '4',
                  description: '',
                  title: `Outcome 4 - ${title}`,
                  displayName: '',
                  canEdit,
                  contextId,
                  contextType,
                  friendlyDescription: null,
                  __typename: 'LearningOutcome'
                },
                group: {
                  _id: '101',
                  title: 'Outcome Group 1',
                  __typename: 'LearningOutcomeGroup'
                },
                __typename: 'ContentTag'
              }
            ],
            __typename: 'ContentTagConnection'
          },
          __typename: 'LearningOutcomeGroup'
        }
      }
    }
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
        targetGroupId
      }
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
              __typename: 'PageInfo'
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
                  canEdit,
                  contextId,
                  contextType,
                  friendlyDescription: null,
                  __typename: 'LearningOutcome'
                },
                group: {
                  _id: '101',
                  title: 'Outcome Group 1',
                  __typename: 'LearningOutcomeGroup'
                },
                __typename: 'ContentTag'
              }
            ],
            __typename: 'ContentTagConnection'
          },
          __typename: 'LearningOutcomeGroup'
        }
      }
    }
  }
]

export const groupDetailMocksFetchMore = ({
  groupId = '1',
  title = `Group ${groupId}`,
  canEdit = true,
  canUnlink = true,
  contextType = 'Account',
  contextId = '1',
  withMorePage = true,
  outcomeIsImported = false,
  groupDescription = 'Group Description',
  targetGroupId,
  notImportedOutcomesCount = null
} = {}) => [
  {
    request: {
      query: SEARCH_GROUP_OUTCOMES,
      variables: {
        id: groupId,
        outcomeIsImported,
        outcomesContextId: contextId,
        outcomesContextType: contextType,
        targetGroupId
      }
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
              __typename: 'PageInfo'
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
                  canEdit,
                  contextId,
                  contextType,
                  friendlyDescription: null,
                  __typename: 'LearningOutcome'
                },
                group: {
                  _id: '101',
                  title: 'Outcome Group 1',
                  __typename: 'LearningOutcomeGroup'
                },
                __typename: 'ContentTag'
              },
              {
                canUnlink,
                _id: '2',
                node: {
                  _id: '2',
                  description: '',
                  title: `Outcome 2 - ${title}`,
                  displayName: '',
                  canEdit,
                  contextId,
                  contextType,
                  friendlyDescription: null,
                  __typename: 'LearningOutcome'
                },
                group: {
                  _id: '101',
                  title: 'Outcome Group 1',
                  __typename: 'LearningOutcomeGroup'
                },
                __typename: 'ContentTag'
              }
            ],
            __typename: 'ContentTagConnection'
          },
          __typename: 'LearningOutcomeGroup'
        }
      }
    }
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
        targetGroupId
      }
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
              __typename: 'PageInfo'
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
                  canEdit,
                  contextId,
                  contextType,
                  friendlyDescription: null,
                  __typename: 'LearningOutcome'
                },
                group: {
                  _id: '101',
                  title: 'Outcome Group 1',
                  __typename: 'LearningOutcomeGroup'
                },
                __typename: 'ContentTag'
              },
              {
                canUnlink,
                _id: '3',
                node: {
                  _id: '3',
                  description: '',
                  title: `Outcome 3 - ${title}`,
                  displayName: '',
                  canEdit,
                  contextId,
                  contextType,
                  friendlyDescription: null,
                  __typename: 'LearningOutcome'
                },
                group: {
                  _id: '101',
                  title: 'Outcome Group 1',
                  __typename: 'LearningOutcomeGroup'
                },
                __typename: 'ContentTag'
              }
            ],
            __typename: 'ContentTagConnection'
          },
          __typename: 'LearningOutcomeGroup'
        }
      }
    }
  }
]

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
  notImportedOutcomesCount = 1
} = {}) => [
  {
    request: {
      query: FIND_GROUP_OUTCOMES,
      variables: {
        id: groupId,
        outcomeIsImported,
        outcomesContextId: contextId,
        outcomesContextType: contextType,
        targetGroupId
      }
    },
    result: {
      data: {
        group: {
          _id: groupId,
          title: `Group ${groupId}`,
          contextType: outcomesGroupContextType,
          contextId: outcomesGroupContextId,
          outcomesCount,
          notImportedOutcomesCount,
          outcomes: {
            pageInfo: {
              hasNextPage: false,
              endCursor: 'Mw',
              __typename: 'PageInfo'
            },
            edges: [
              {
                _id: '5',
                node: {
                  _id: '5',
                  description: '',
                  isImported,
                  title: `Outcome 5 - Group ${groupId}`,
                  __typename: 'LearningOutcome'
                },
                __typename: 'ContentTag'
              },
              {
                _id: '6',
                node: {
                  _id: '6',
                  description: '',
                  isImported,
                  title: `Outcome 6 - Group ${groupId}`,
                  __typename: 'LearningOutcome'
                },
                __typename: 'ContentTag'
              }
            ],
            __typename: 'ContentTagConnection'
          },
          __typename: 'LearningOutcomeGroup'
        }
      }
    }
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
        targetGroupId
      }
    },
    result: {
      data: {
        group: {
          _id: groupId,
          title: `Group ${groupId}`,
          contextType: outcomesGroupContextType,
          contextId: outcomesGroupContextId,
          outcomesCount: 15,
          notImportedOutcomesCount,
          outcomes: {
            pageInfo: {
              hasNextPage: false,
              endCursor: 'Mw',
              __typename: 'PageInfo'
            },
            edges: [
              {
                _id: '5',
                node: {
                  _id: '5',
                  description: '',
                  isImported,
                  title: `Outcome 5 - Group ${groupId}`,
                  __typename: 'LearningOutcome'
                },
                __typename: 'ContentTag'
              },
              {
                _id: '6',
                node: {
                  _id: '6',
                  description: '',
                  isImported,
                  title: `Outcome 6 - Group ${groupId}`,
                  __typename: 'LearningOutcome'
                },
                __typename: 'ContentTag'
              }
            ],
            __typename: 'ContentTagConnection'
          },
          __typename: 'LearningOutcomeGroup'
        }
      }
    }
  }
]

export const setFriendlyDescriptionOutcomeMock = ({
  inputDescription = 'Updated friendly description',
  failResponse = false
} = {}) => {
  const successfulResponse = {
    data: {
      setFriendlyDescription: {
        outcomeFriendlyDescription: {
          _id: '1',
          description: 'Updated friendly description',
          __typename: 'OutcomeFriendlyDescription'
        },
        __typename: 'SetFriendlyDescriptionPayload',
        errors: null
      }
    }
  }

  const failedResponse = {
    data: null,
    errors: [
      {
        attribute: 'message',
        message: 'mutation failed'
      }
    ]
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
          outcomeId: '1'
        }
      }
    },
    result
  }
}

export const createLearningOutcomeMock = ({
  title = 'Outcome title',
  description = 'description',
  displayName = 'display name',
  groupId = '1',
  failResponse = false,
  failMutation = false
} = {}) => {
  const successfulResponse = {
    data: {
      createLearningOutcome: {
        learningOutcome: {
          _id: '1',
          title,
          description,
          displayName,
          __typename: 'LearningOutcome'
        },
        __typename: 'CreateLearningOutcomePayload',
        errors: null
      }
    },
    errors: null
  }

  const failedResponse = {
    __typename: 'ErrorResponse',
    data: null,
    errors: [
      {
        message: 'mutation failed',
        __typename: 'Error'
      }
    ]
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
            __typename: 'Error'
          }
        ]
      }
    }
  }

  let result = successfulResponse
  if (failResponse) {
    result = failedResponse
  } else if (failMutation) {
    result = failedMutation
  }

  return {
    request: {
      query: CREATE_LEARNING_OUTCOME,
      variables: {
        input: {
          description,
          title,
          groupId,
          displayName
        }
      }
    },
    result
  }
}

export const updateOutcomeMocks = ({
  id = '1',
  title = 'Updated name',
  displayName = 'Friendly outcome name',
  description = 'Updated description'
} = {}) => [
  {
    request: {
      query: UPDATE_LEARNING_OUTCOME,
      variables: {
        input: {
          id,
          title,
          displayName,
          description
        }
      }
    },
    result: {
      data: {
        updateLearningOutcome: {
          __typename: 'UpdateLearningOutcomePayload',
          learningOutcome: {
            __typename: 'LearningOutcome',
            _id: '1',
            title,
            displayName,
            description
          },
          errors: null
        }
      }
    }
  },
  {
    request: {
      query: UPDATE_LEARNING_OUTCOME,
      variables: {
        input: {
          id: '2',
          title,
          displayName,
          description
        }
      }
    },
    result: {
      data: null,
      errors: [
        {
          attribute: 'title',
          message: "can't be blank"
        }
      ]
    }
  }
]

export const importOutcomeMocks = ({
  outcomeId = '200',
  progressId = '211',
  sourceContextId = null,
  sourceContextType = null,
  targetContextId = '1',
  targetContextType = 'Account',
  failResponse = false,
  failMutationNoErrMsg = false,
  targetGroupId
} = {}) => {
  const successfulResponse = {
    data: {
      importOutcomes: {
        errors: null,
        progress: {
          _id: progressId,
          state: 'queued',
          __typename: 'Progress'
        },
        __typename: 'ImportOutcomesPayload'
      }
    }
  }

  const failedResponse = {
    __typename: 'ErrorResponse',
    data: {
      importOutcomes: null
    },
    errors: [
      {
        attribute: outcomeId,
        message: 'Network error',
        __typename: 'Error'
      }
    ]
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
            __typename: 'Error'
          }
        ]
      }
    }
  }

  let result = successfulResponse
  if (failResponse) {
    result = failedResponse
  } else if (failMutationNoErrMsg) {
    result = failedMutationNoErrMsg
  }

  let input = {
    outcomeId
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
      sourceContextType
    }
  }

  return [
    {
      request: {
        query: IMPORT_OUTCOMES,
        variables: {
          input
        }
      },
      result
    }
  ]
}

export const deleteOutcomeMock = ({
  ids = ['1'],
  failResponse = false,
  failAlignedContentMutation = false,
  failMutation = false,
  failMutationNoErrMsg = false,
  partialSuccess = false
} = {}) => {
  const successfulResponse = {
    data: {
      deleteOutcomeLinks: {
        __typename: 'DeleteOutcomeLinksPayload',
        deletedOutcomeLinkIds: ids,
        errors: []
      }
    }
  }

  const failedResponse = {
    __typename: 'ErrorResponse',
    data: null,
    errors: [
      {
        attribute: ids[0],
        message: 'Could not find associated outcome in this context',
        __typename: 'Error'
      }
    ]
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
            __typename: 'Error'
          }
        ]
      }
    }
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
            __typename: 'Error'
          }
        ]
      }
    }
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
            __typename: 'Error'
          }
        ]
      }
    }
  }

  const partialSuccessResponse = {
    data: {
      deleteOutcomeLinks: {
        __typename: 'DeleteOutcomeLinksPayload',
        deletedOutcomeLinkIds: ids.filter((_, idx) => idx !== 0),
        errors: [
          {
            attribute: ids[0],
            message: 'Could not find associated outcome in this context',
            __typename: 'Error'
          }
        ]
      }
    }
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
          ids
        }
      }
    },
    result
  }
}

export const moveOutcomeMock = ({
  groupId = '101',
  outcomeLinkIds = ['1', '2'],
  parentGroupTitle = 'Outcome Group',
  failResponse = false,
  failMutation = false,
  failMutationNoErrMsg = false,
  partialSuccess = false
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
            __typename: 'LearningOutcomeGroup'
          },
          __typename: 'ContentTag'
        })),
        errors: null
      }
    }
  }

  const failedResponse = {
    data: null,
    errors: [
      {
        attribute: outcomeLinkIds[0],
        message: 'Could not find associated outcome in this context',
        __typename: 'Error'
      }
    ]
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
            __typename: 'Error'
          }
        ]
      }
    }
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
            __typename: 'Error'
          }
        ]
      }
    }
  }

  const partialSuccessResponse = {
    data: {
      moveOutcomeLinks: {
        movedOutcomeLinks: outcomeLinkIds
          .filter((_, idx) => idx !== 0)
          .map(idx => ({
            _id: idx,
            group: {
              _id: '101',
              title: parentGroupTitle,
              __typename: 'LearningOutcomeGroup'
            },
            __typename: 'ContentTag'
          })),
        __typename: 'MoveOutcomeLinksPayload',
        errors: [
          {
            attribute: outcomeLinkIds[0],
            message: 'Could not find associated outcome in this context',
            __typename: 'Error'
          }
        ]
      }
    }
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
          outcomeLinkIds
        }
      }
    },
    result
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
  failMutationNoErrMsg = false
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
            __typename: 'LearningOutcomeGroup'
          },
          __typename: 'LearningOutcomeGroup'
        },
        errors: null,
        __typename: 'UpdateLearningOutcomeGroupPayload'
      }
    }
  }

  const failedResponse = {
    __typename: 'ErrorResponse',
    data: null,
    errors: [
      {
        attribute: id,
        message: 'Network error',
        __typename: 'Error'
      }
    ]
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
            __typename: 'Error'
          }
        ]
      }
    }
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
            __typename: 'Error'
          }
        ]
      }
    }
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
        input
      }
    },
    result
  }
}

export const importGroupMocks = ({
  groupId = '100',
  progressId = '111',
  targetContextId = '1',
  targetContextType = 'Account',
  targetGroupId,
  failResponse = false,
  failMutationNoErrMsg = false
} = {}) => {
  const successfulResponse = {
    data: {
      importOutcomes: {
        progress: {
          _id: progressId,
          state: 'queued',
          __typename: 'Progress'
        },
        errors: null,
        __typename: 'ImportOutcomesPayload'
      }
    }
  }

  const failedResponse = {
    __typename: 'ErrorResponse',
    data: {
      importOutcomes: null
    },
    errors: [
      {
        attribute: groupId,
        message: 'Network error',
        __typename: 'Error'
      }
    ]
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
            __typename: 'Error'
          }
        ]
      }
    }
  }

  let result = successfulResponse
  if (failResponse) {
    result = failedResponse
  } else if (failMutationNoErrMsg) {
    result = failedMutationNoErrMsg
  }

  const input = {
    groupId
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
          input
        }
      },
      result
    }
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
  failMutationNoErrMsg = false
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
            __typename: 'LearningOutcomeGroup'
          },
          __typename: 'LearningOutcomeGroup'
        },
        errors: null,
        __typename: 'CreateLearningOutcomeGroupPayload'
      }
    }
  }

  const failedResponse = {
    __typename: 'ErrorResponse',
    data: null,
    errors: [
      {
        attribute: id,
        message: 'Network error',
        __typename: 'Error'
      }
    ]
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
            __typename: 'Error'
          }
        ]
      }
    }
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
            __typename: 'Error'
          }
        ]
      }
    }
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
    title
  }
  if (description) input.description = description
  if (vendorGuid) input.vendorGuid = vendorGuid

  return [
    {
      request: {
        query: CREATE_LEARNING_OUTCOME_GROUP,
        variables: {
          input
        }
      },
      result
    }
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
    parentOutcomeGroupTitle: 'Root account folder'
  }),
  ...groupMocks({
    groupId: '101',
    childGroupsCount: 0,
    parentOutcomeGroupId: '1',
    title: 'Account folder 1',
    parentOutcomeGroupTitle: 'Root account folder'
  }),
  ...groupMocks({
    groupId: '400',
    childGroupsCount: 0,
    parentOutcomeGroupId: '100',
    parentOutcomeGroupTitle: 'Account folder 0',
    title: 'Group 100 folder 0'
  }),
  ...groupDetailMocks({groupId: '100'}),
  ...groupDetailMocks({groupId: '101'}),
  ...groupDetailMocks({groupId: '400'})
]
