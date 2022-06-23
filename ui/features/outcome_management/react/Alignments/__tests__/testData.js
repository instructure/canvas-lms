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
    id: '1',
    type: 'Assignment',
    title: 'Assignment 1',
    url: '/courses/1/outcomes/1/alignments/3',
    moduleTitle: 'Module 1',
    moduleUrl: '/courses/1/modules/1',
    moduleWorkflowState: 'unpublished',
    assignmentContentType: 'Assignment'
  },
  {
    id: '2',
    type: 'Rubric',
    title: 'Rubric 1',
    url: '/courses/1/outcomes/1/alignments/5',
    moduleTitle: null,
    moduleUrl: null,
    moduleWorkflowState: null,
    assignmentContentType: null
  },
  {
    id: '3',
    type: 'Assignment',
    title: 'Quiz Assignment 1',
    url: '/courses/1/outcomes/1/alignments/4',
    moduleTitle: 'Module 1',
    moduleUrl: '/courses/1/modules/1',
    moduleWorkflowState: 'unpublished',
    assignmentContentType: 'Quizzes::Quiz'
  },
  {
    id: '4',
    type: 'Assignment',
    title: 'Discussion Assignment 1',
    url: '/courses/1/outcomes/1/alignments/6',
    moduleTitle: 'Module 2',
    moduleUrl: '/courses/1/modules/2',
    moduleWorkflowState: 'active',
    assignmentContentType: 'DiscussionTopic'
  }
]

export const generateOutcomes = num =>
  [...Array(num).keys()].map(el => ({
    id: String(el),
    title: `Outcome ${el + 1}`,
    description: `Outcome ${el + 1} description`,
    alignments
  }))

// Sample data - remove after index.js is integrated with graphql
export const totalOutcomes = 4200
export const alignedOutcomes = 3900
export const totalAlignments = 6800
export const totalArtifacts = 2400
export const alignedArtifacts = 2000
