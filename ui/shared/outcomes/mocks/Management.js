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
  UPDATE_LEARNING_OUTCOME
} from '../graphql/Management'

export const accountMocks = ({
  childGroupsCount = 10,
  outcomesCount = 2,
  accountId = '1',
  canEdit = true
} = {}) => [
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
            childGroupsCount,
            outcomesCount,
            description: `Root account group`,
            title: `Root account folder`,
            canEdit,
            __typename: 'LearningOutcomeGroup',
            _id: 1,
            childGroups: {
              __typename: 'LearningOutcomeGroupConnection',
              nodes: new Array(childGroupsCount).fill(0).map((_v, i) => ({
                __typename: 'LearningOutcomeGroup',
                description: `Account folder description ${i}`,
                _id: 100 + i,
                outcomesCount,
                childGroupsCount,
                title: `Account folder ${i}`,
                canEdit
              }))
            }
          }
        }
      }
    }
  }
]

export const courseMocks = ({
  childGroupsCount = 1,
  outcomesCount = 2,
  courseId = '2',
  canEdit = true
} = {}) => [
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
            childGroupsCount,
            outcomesCount,
            description: `Root course group`,
            title: `Root course folder`,
            canEdit,
            __typename: 'LearningOutcomeGroup',
            _id: 2,
            childGroups: {
              __typename: 'LearningOutcomeGroupConnection',
              nodes: new Array(childGroupsCount).fill(0).map((_v, i) => ({
                __typename: 'LearningOutcomeGroup',
                description: `Course folder description ${i}`,
                _id: 200 + i,
                outcomesCount: 2,
                childGroupsCount: 10,
                title: `Course folder ${i}`,
                canEdit
              }))
            }
          }
        }
      }
    }
  }
]

export const groupMocks = ({
  groupId,
  childGroupsCount = 1,
  outcomesCount = 2,
  childGroupOffset = 300,
  canEdit = true
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
          childGroupsCount,
          outcomesCount,
          childGroups: {
            __typename: 'LearningOutcomeGroupConnection',
            nodes: new Array(childGroupsCount).fill(0).map((_v, i) => ({
              __typename: 'LearningOutcomeGroup',
              description: `Group ${groupId} folder description ${i}`,
              _id: childGroupOffset + i,
              outcomesCount: 2,
              childGroupsCount: 5,
              title: `Group ${groupId} folder ${i}`,
              canEdit
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
  description: '<p>This is a <strong><em>description</em></strong>. And because it’s so <strong>long</strong>, it will run out of space and hence be truncated. </p>'.repeat(
    2
  ),
  outcomesCount: 15,
  canEdit: true,
  outcomes: {
    pageInfo: {
      hasNextPage: false,
      endCursor: ''
    },
    edges: [
      {
        canUnlink: true,
        node: {
          _id: '1',
          title: 'CCSS.Math.Content.2.MD.A.1 - Outcome with regular length title and description',
          description: '<p>Partition <strong>circles</strong> and <strong><em>rectangle</em></strong> into two, three, or four equal share. </p>'.repeat(
            2
          ),
          contextType: null,
          contextId: null,
          canEdit: true
        }
      },
      {
        canUnlink: true,
        node: {
          _id: '2',
          title:
            'CCSS.Math.Content.2.MD.A.1.CCSS.Math.Content.2.MD.A.1.CCSS.Math.Content.Outcome.with.long.title.and.description',
          description: '<p>Measure the <strong><em>length</em></strong> of an <strong>object</strong> by selecting and using appropriate measurements. </p>'.repeat(
            2
          ),
          contextType: null,
          contextId: null,
          canEdit: true
        }
      },
      {
        canUnlink: true,
        node: {
          _id: '3',
          title: 'CCSS.Math.Content.2.G.A.3 - Outcome with regular length title and no description',
          description: '',
          contextType: null,
          contextId: null,
          canEdit: true
        }
      },
      {
        canUnlink: true,
        node: {
          _id: '4',
          title:
            'CCSS.Math.Content.2.G.A.3 CCSS.Math.Content.2.G.A.3 CCSS.Math.Content.2.G.A.3 CCSS.Math',
          description: '<p><em>Partition circles and rectangle into two, three, or four equal share. </em></p>'.repeat(
            2
          ),
          contextType: null,
          contextId: null,
          canEdit: true
        }
      },
      {
        canUnlink: true,
        node: {
          _id: '5',
          title:
            'CCSS.Math.Content.2.G.A.3 CCSS.Math.Content.2.G.A.3 CCSS.Math.Content.2.G.A.3 CCSS.Math',
          description: '<p><strong>Partition circles and rectangle into two, three, or four equal share. </strong></p>'.repeat(
            2
          ),
          contextType: null,
          contextId: null,
          canEdit: true
        }
      },
      {
        canUnlink: true,
        node: {
          _id: '6',
          title: 'CCSS.Math.Content.2.G.A.3 CCSS.Math.Content.2.G.A.3',
          description: '<p>Partition circles and rectangle into two, three, or four equal share. </p>'.repeat(
            2
          ),
          contextType: null,
          contextId: null,
          canEdit: true
        }
      }
    ]
  }
}

export const groupDetailMocks = ({
  groupId = '1',
  canEdit = true,
  canUnlink = true,
  contextType = 'Account',
  contextId = '1',
  outcomeIsImported = false,
  searchQuery = ''
} = {}) => [
  {
    request: {
      query: FIND_GROUP_OUTCOMES,
      variables: {
        id: groupId,
        outcomesContextId: contextId,
        outcomesContextType: contextType,
        outcomeIsImported
      }
    },
    result: {
      data: {
        group: {
          _id: groupId,
          description: '',
          title: `Group ${groupId}`,
          outcomesCount: 0,
          canEdit,
          outcomes: {
            pageInfo: {
              hasNextPage: true,
              endCursor: 'Mg',
              __typename: 'PageInfo'
            },
            edges: [
              {
                node: {
                  _id: '1',
                  description: '',
                  displayName: '',
                  title: `Outcome 1 - Group ${groupId}`,
                  __typename: 'LearningOutcome'
                },
                __typename: 'ContentTag'
              },
              {
                node: {
                  _id: '2',
                  description: '',
                  displayName: '',
                  title: `Outcome 2 - Group ${groupId}`,
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
        outcomesContextId: contextId,
        outcomesContextType: contextType,
        outcomeIsImported,
        searchQuery
      }
    },
    result: {
      data: {
        group: {
          _id: groupId,
          description: '',
          title: `Group ${groupId}`,
          outcomesCount: 0,
          canEdit,
          outcomes: {
            pageInfo: {
              hasNextPage: true,
              endCursor: 'Mg',
              __typename: 'PageInfo'
            },
            edges: [
              {
                node: {
                  _id: '1',
                  description: '',
                  displayName: '',
                  title: `Outcome 1 - Group ${groupId}`,
                  __typename: 'LearningOutcome'
                },
                __typename: 'ContentTag'
              },
              {
                node: {
                  _id: '3',
                  description: '',
                  displayName: '',
                  title: `Outcome 3 - Group ${groupId}`,
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
        searchQuery
      }
    },
    result: {
      data: {
        group: {
          _id: groupId,
          description: '',
          title: `Group ${groupId}`,
          outcomesCount: 0,
          canEdit,
          outcomes: {
            pageInfo: {
              hasNextPage: false,
              endCursor: 'Mw',
              __typename: 'PageInfo'
            },
            edges: [
              {
                node: {
                  _id: '5',
                  description: '',
                  displayName: '',
                  isImported: false,
                  friendlyDescription: null,
                  title: `Outcome 5 - Group ${groupId}`,
                  __typename: 'LearningOutcome'
                },
                __typename: 'ContentTag'
              },
              {
                node: {
                  _id: '6',
                  description: '',
                  displayName: '',
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
      query: SEARCH_GROUP_OUTCOMES,
      variables: {
        id: groupId,
        outcomeIsImported,
        outcomesContextId: contextId,
        outcomesContextType: contextType
      }
    },
    result: {
      data: {
        group: {
          _id: groupId,
          description: '',
          title: `Group ${groupId}`,
          outcomesCount: 2,
          canEdit,
          outcomes: {
            pageInfo: {
              hasNextPage: true,
              endCursor: 'Mx',
              __typename: 'PageInfo'
            },
            edges: [
              {
                canUnlink,
                node: {
                  _id: '1',
                  description: '',
                  title: `Outcome 1 - Group ${groupId}`,
                  displayName: '',
                  canEdit,
                  contextId,
                  contextType,
                  friendlyDescription: null,
                  __typename: 'LearningOutcome'
                },
                __typename: 'ContentTag'
              },
              {
                canUnlink,
                node: {
                  _id: '2',
                  description: '',
                  title: `Outcome 2 - Group ${groupId}`,
                  displayName: '',
                  canEdit,
                  contextId,
                  contextType,
                  friendlyDescription: null,
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
        outcomesCursor: 'Mx',
        outcomeIsImported,
        outcomesContextId: contextId,
        outcomesContextType: contextType
      }
    },
    result: {
      data: {
        group: {
          _id: groupId,
          description: '',
          title: `Group ${groupId}`,
          outcomesCount: 2,
          canEdit,
          outcomes: {
            pageInfo: {
              hasNextPage: false,
              endCursor: null,
              __typename: 'PageInfo'
            },
            edges: [
              {
                canUnlink,
                node: {
                  _id: '3',
                  description: '',
                  title: `Outcome 3 - Group ${groupId}`,
                  displayName: '',
                  canEdit,
                  contextId,
                  contextType,
                  friendlyDescription: null,
                  __typename: 'LearningOutcome'
                },
                __typename: 'ContentTag'
              },
              {
                canUnlink,
                node: {
                  _id: '4',
                  description: '',
                  title: `Outcome 4 - Group ${groupId}`,
                  displayName: '',
                  canEdit,
                  contextId,
                  contextType,
                  friendlyDescription: null,
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
        searchQuery
      }
    },
    result: {
      data: {
        group: {
          _id: groupId,
          description: '',
          title: `Group ${groupId}`,
          outcomesCount: 1,
          canEdit,
          outcomes: {
            pageInfo: {
              hasNextPage: false,
              endCursor: null,
              __typename: 'PageInfo'
            },
            edges: [
              {
                canUnlink,
                node: {
                  _id: '1',
                  description: '',
                  title: `Outcome 1 - Group ${groupId}`,
                  displayName: '',
                  canEdit,
                  contextId,
                  contextType,
                  friendlyDescription: null,
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

export const findOutcomesMocks = ({
  groupId = 100,
  canEdit = true,
  isImported = true,
  outcomeIsImported = true,
  contextType = 'Account',
  contextId = '1',
  searchQuery = 'mathematics'
} = {}) => [
  {
    request: {
      query: FIND_GROUP_OUTCOMES,
      variables: {
        id: groupId,
        outcomeIsImported,
        outcomesContextId: contextId,
        outcomesContextType: contextType
      }
    },
    result: {
      data: {
        group: {
          _id: groupId,
          description: '',
          title: `Group ${groupId}`,
          outcomesCount: 25,
          canEdit,
          outcomes: {
            pageInfo: {
              hasNextPage: false,
              endCursor: 'Mw',
              __typename: 'PageInfo'
            },
            edges: [
              {
                node: {
                  _id: '5',
                  description: '',
                  displayName: '',
                  isImported,
                  title: `Outcome 5 - Group ${groupId}`,
                  __typename: 'LearningOutcome'
                },
                __typename: 'ContentTag'
              },
              {
                node: {
                  _id: '6',
                  description: '',
                  displayName: '',
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
        searchQuery
      }
    },
    result: {
      data: {
        group: {
          _id: groupId,
          description: '',
          title: `Group ${groupId}`,
          outcomesCount: 15,
          canEdit,
          outcomes: {
            pageInfo: {
              hasNextPage: false,
              endCursor: 'Mw',
              __typename: 'PageInfo'
            },
            edges: [
              {
                node: {
                  _id: '5',
                  description: '',
                  displayName: '',
                  isImported,
                  title: `Outcome 5 - Group ${groupId}`,
                  __typename: 'LearningOutcome'
                },
                __typename: 'ContentTag'
              },
              {
                node: {
                  _id: '6',
                  description: '',
                  displayName: '',
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
  inputDescription = 'Updated alternate description',
  failResponse = false
} = {}) => {
  const successfulResponse = {
    data: {
      setFriendlyDescription: {
        outcomeFriendlyDescription: {
          _id: '1',
          description: 'Updated alternate description',
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
  groupId = 1,
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
          learningOutcome: {
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

export const smallOutcomeTree = () => [
  ...accountMocks({childGroupsCount: 2}),
  ...groupMocks({groupId: 100, childGroupOffset: 400}),
  ...groupMocks({groupId: 101, childGroupsCount: 0}),
  ...groupMocks({groupId: 400, childGroupsCount: 0}),
  ...groupDetailMocks({groupId: 100}),
  ...groupDetailMocks({groupId: 101}),
  ...groupDetailMocks({groupId: 400})
]
