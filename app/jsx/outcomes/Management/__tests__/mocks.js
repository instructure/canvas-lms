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
import {CHILD_GROUPS_QUERY} from '../api'

export const accountMocks = ({childGroupsCount = 1, outcomesCount = 2, accountId = '1'} = {}) => [
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
            __typename: 'LearningOutcomeGroup',
            _id: 1,
            childGroups: {
              __typename: 'LearningOutcomeGroupConnection',
              nodes: new Array(childGroupsCount).fill(0).map((_v, i) => ({
                __typename: 'LearningOutcomeGroup',
                description: `Account folder description ${i}`,
                _id: 100 + i,
                outcomesCount: 2,
                childGroupsCount: 10,
                title: `Account folder ${i}`
              }))
            }
          }
        }
      }
    }
  }
]

export const courseMocks = ({childGroupsCount = 1, outcomesCount = 2, courseId = '2'} = {}) => [
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
                title: `Course folder ${i}`
              }))
            }
          }
        }
      }
    }
  }
]

export const groupMocks = ({groupId, childGroupsCount = 1} = {}) => [
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
          childGroups: {
            __typename: 'LearningOutcomeGroupConnection',
            nodes: new Array(childGroupsCount).fill(0).map((_v, i) => ({
              __typename: 'LearningOutcomeGroup',
              description: `Group ${groupId} folder description ${i}`,
              _id: 300 + i,
              outcomesCount: 2,
              childGroupsCount: 5,
              title: `Group ${groupId} folder ${i}`
            }))
          }
        }
      }
    }
  }
]

export const outcomeGroup = {
  id: '0',
  title: 'Grade.2.Math.3A.Elementary.CCSS.Calculus.1',
  description: '<p>This is a <strong><em>description</em></strong>. And because it’s so <strong>long</strong>, it will run out of space and hence be truncated. </p>'.repeat(
    2
  ),
  children: [
    {
      id: '1',
      title: 'CCSS.Math.Content.2.MD.A.1 - Outcome with regular length title and description',
      description: '<p>Partition <strong>circles</strong> and <strong><em>rectangle</em></strong> into two, three, or four equal share. </p>'.repeat(
        2
      )
    },
    {
      id: '2',
      title:
        'CCSS.Math.Content.2.MD.A.1.CCSS.Math.Content.2.MD.A.1.CCSS.Math.Content.Outcome.with.long.title.and.description',
      description: '<p>Measure the <strong><em>length</em></strong> of an <strong>object</strong> by selecting and using appropriate measurements. </p>'.repeat(
        2
      )
    },
    {
      id: '3',
      title: 'CCSS.Math.Content.2.G.A.3 - Outcome with regular length title and no description',
      description: ''
    },
    {
      id: '4',
      title:
        'CCSS.Math.Content.2.G.A.3 CCSS.Math.Content.2.G.A.3 CCSS.Math.Content.2.G.A.3 CCSS.Math',
      description: '<p><em>Partition circles and rectangle into two, three, or four equal share. </em></p>'.repeat(
        2
      )
    },
    {
      id: '5',
      title:
        'CCSS.Math.Content.2.G.A.3 CCSS.Math.Content.2.G.A.3 CCSS.Math.Content.2.G.A.3 CCSS.Math',
      description: '<p><strong>Partition circles and rectangle into two, three, or four equal share. </strong></p>'.repeat(
        2
      )
    },
    {
      id: '6',
      title: 'CCSS.Math.Content.2.G.A.3 CCSS.Math.Content.2.G.A.3',
      description: '<p>Partition circles and rectangle into two, three, or four equal share. </p>'.repeat(
        2
      )
    }
  ]
}
