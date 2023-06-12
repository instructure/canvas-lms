/*
 * Copyright (C) 2022 - present Instructure, Inc.
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

export const alignments = [
  {
    _id: '1',
    contentType: 'Assignment',
    title: 'Assignment 1',
    url: '/courses/1/outcomes/1/alignments/3',
    moduleTitle: 'Module 1',
    moduleUrl: '/courses/1/modules/1',
    moduleWorkflowState: 'unpublished',
    assignmentContentType: 'assignment',
    assignmentWorkflowState: 'published',
    quizItems: null,
    alignmentsCount: 1,
  },
  {
    _id: '2',
    contentType: 'Rubric',
    title: 'Rubric 1',
    url: '/courses/1/outcomes/1/alignments/5',
    moduleTitle: null,
    moduleUrl: null,
    moduleWorkflowState: null,
    assignmentContentType: null,
    assignmentWorkflowState: null,
    quizItems: null,
    alignmentsCount: 1,
  },
  {
    _id: '3',
    contentType: 'Assignment',
    title: 'Quiz Assignment 1',
    url: '/courses/1/outcomes/1/alignments/4',
    moduleTitle: 'Module 1',
    moduleUrl: '/courses/1/modules/1',
    moduleWorkflowState: 'unpublished',
    assignmentContentType: 'quiz',
    assignmentWorkflowState: 'published',
    quizItems: null,
    alignmentsCount: 1,
  },
  {
    _id: '4',
    contentType: 'Assignment',
    title: 'Discussion Assignment 1',
    url: '/courses/1/outcomes/1/alignments/6',
    moduleTitle: 'Module 2',
    moduleUrl: '/courses/1/modules/2',
    moduleWorkflowState: 'active',
    assignmentContentType: 'discussion',
    assignmentWorkflowState: 'published',
    quizItems: null,
    alignmentsCount: 1,
  },
  {
    _id: '5',
    contentType: 'Assignment',
    title: 'New Quiz Assignment 1',
    url: '/courses/1/assignments/5',
    moduleTitle: 'Module 2',
    moduleUrl: '/courses/1/modules/2',
    moduleWorkflowState: 'active',
    assignmentContentType: 'new_quiz',
    assignmentWorkflowState: 'published',
    quizItems: [],
    alignmentsCount: 1,
  },
]

export const generateOutcomes = num =>
  [...Array(num).keys()].map(el => ({
    node: {
      _id: String(el),
      title: `Outcome ${el + 1}`,
      description: `Outcome ${el + 1} description`,
      alignments,
    },
  }))

export const generateRootGroup = (numOutcomes, hasNextPage = false) => ({
  _id: '100',
  outcomesCount: numOutcomes,
  outcomes: {
    pageInfo: {
      hasNextPage,
      endCursor: null,
    },
    edges: generateOutcomes(numOutcomes),
  },
})
