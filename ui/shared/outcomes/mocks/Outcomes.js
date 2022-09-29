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
  ACCOUNT_OUTCOME_PROFICIENCY_QUERY,
  COURSE_OUTCOME_PROFICIENCY_QUERY,
} from '../graphql/MasteryScale'

import {
  ACCOUNT_OUTCOME_CALCULATION_QUERY,
  COURSE_OUTCOME_CALCULATION_QUERY,
} from '../graphql/MasteryCalculation'

import {courseMocks, accountMocks} from './Management'
import {FIND_GROUPS_QUERY} from '../graphql/Outcomes'

const outcomeCalculationMethod = {
  __typename: 'OutcomeCalculationMethod',
  _id: '1',
  contextType: 'Account',
  contextId: 1,
  calculationMethod: 'decaying_average',
  calculationInt: 65,
}

const outcomeProficiency = {
  __typename: 'OutcomeProficiency',
  _id: '1',
  contextId: 1,
  contextType: 'Account',
  locked: false,
  proficiencyRatingsConnection: {
    __typename: 'ProficiencyRatingConnection',
    nodes: [
      {
        __typename: 'ProficiencyRating',
        _id: '2',
        color: '009606',
        description: 'Rating A',
        mastery: false,
        points: 9,
      },
      {
        __typename: 'ProficiencyRating',
        _id: '6',
        color: 'EF4437',
        description: 'Rating B',
        mastery: false,
        points: 6,
      },
    ],
  },
}

export const masteryScalesGraphqlMocks = [
  {
    request: {
      query: ACCOUNT_OUTCOME_PROFICIENCY_QUERY,
      variables: {
        contextId: '11',
      },
    },
    result: {
      data: {
        context: {
          __typename: 'Account',
          outcomeProficiency,
        },
      },
    },
  },
  {
    request: {
      query: COURSE_OUTCOME_PROFICIENCY_QUERY,
      variables: {
        contextId: '12',
      },
    },
    result: {
      data: {
        context: {
          __typename: 'Course',
          outcomeProficiency,
        },
      },
    },
  },
]

export const masteryCalculationGraphqlMocks = [
  {
    request: {
      query: ACCOUNT_OUTCOME_CALCULATION_QUERY,
      variables: {
        contextId: '11',
      },
    },
    result: {
      data: {
        context: {
          __typename: 'Account',
          outcomeCalculationMethod,
        },
      },
    },
  },
  {
    request: {
      query: COURSE_OUTCOME_CALCULATION_QUERY,
      variables: {
        contextId: '12',
      },
    },
    result: {
      data: {
        context: {
          __typename: 'Course',
          outcomeCalculationMethod,
        },
      },
    },
  },
]

export const outcomeGroupsMocks = [
  ...accountMocks({accountId: '11'}),
  ...courseMocks({courseId: '12'}),
]

export const findModalMocks = ({
  includeGlobalRootGroup = false,
  parentAccountChildren = 10,
} = {}) => {
  const globalGroup = includeGlobalRootGroup ? globalGroupMock() : {}

  return [
    {
      request: {
        query: FIND_GROUPS_QUERY,
        variables: {
          id: '1',
          type: 'Account',
          rootGroupId: includeGlobalRootGroup ? '1' : '0',
          includeGlobalRootGroup,
        },
      },
      result: {
        data: {
          context: {
            _id: '1',
            __typename: 'Account',
            parentAccountsConnection: parentAccountMock(parentAccountChildren),
          },
          ...globalGroup,
        },
      },
    },
    {
      request: {
        query: FIND_GROUPS_QUERY,
        variables: {
          id: '1',
          type: 'Course',
          rootGroupId: '0',
          includeGlobalRootGroup: false,
        },
      },
      result: {
        data: {
          context: {
            __typename: 'Course',
            _id: '1',
            account: {
              _id: '1',
              __typename: 'Account',
              rootOutcomeGroup: {
                title: `Course Account Outcome Group`,
                __typename: 'LearningOutcomeGroup',
                _id: '1',
              },
              parentAccountsConnection: parentAccountMock(parentAccountChildren),
            },
          },
        },
      },
    },
  ]
}

const parentAccountMock = count => ({
  __typename: 'ParentAccountsConnection',
  nodes: new Array(count).fill(0).map((_v, i) => ({
    __typename: 'Account',
    rootOutcomeGroup: {
      title: `Root Account Outcome Group ${i}`,
      __typename: 'LearningOutcomeGroup',
      _id: (100 + i).toString(),
    },
  })),
})

const globalGroupMock = () => ({
  globalRootGroup: {
    __typename: 'LearningOutcomeGroup',
    title: 'Global Root Outcome Group',
    _id: '1',
  },
})
