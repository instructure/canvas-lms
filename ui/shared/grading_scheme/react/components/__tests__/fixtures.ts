/*
 * Copyright (C) 2023 - present Instructure, Inc.
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

import type {GradingSchemeSummary, UsedLocation} from '@canvas/grading_scheme/gradingSchemeApiModel'
import type {GradingScheme, GradingSchemeCardData} from '../../../index'

export const AccountGradingSchemes: GradingScheme[] = [
  {
    assessed_assignment: false,
    context_id: '1',
    context_type: 'Course',
    context_name: 'Test Course',
    data: [{name: 'A', value: 0}],
    id: '1',
    permissions: {manage: true},
    points_based: false,
    scaling_factor: 1,
    title: 'Grading Scheme 1',
    workflow_state: 'active',
  },
  {
    assessed_assignment: false,
    context_id: '1',
    context_type: 'Account',
    context_name: 'Test Account',
    data: [{name: 'A', value: 90}],
    id: '2',
    permissions: {manage: true},
    points_based: false,
    scaling_factor: 1,
    title: 'Grading Scheme 2',
    workflow_state: 'active',
  },
  {
    assessed_assignment: false,
    context_id: '1',
    context_type: 'Course',
    context_name: 'Test Course',
    data: [{name: 'A', value: 90}],
    id: '3',
    permissions: {manage: true},
    points_based: false,
    scaling_factor: 1,
    title: 'Grading Scheme 3',
    workflow_state: 'archived',
  },
]

export const ExtraGradingSchemes: GradingScheme[] = [
  ...AccountGradingSchemes,
  {
    assessed_assignment: false,
    context_id: '1',
    context_type: 'Course',
    context_name: 'Test Course',
    data: [{name: 'A', value: 90}],
    id: '4',
    permissions: {manage: true},
    points_based: false,
    scaling_factor: 1,
    title: 'Grading Scheme 4',
    workflow_state: 'active',
  },
  {
    assessed_assignment: false,
    context_id: '1',
    context_type: 'Account',
    context_name: 'Test Account',
    data: [{name: 'A', value: 90}],
    id: '5',
    permissions: {manage: true},
    points_based: false,
    scaling_factor: 1,
    title: 'Grading Scheme 5',
    workflow_state: 'active',
  },
  {
    assessed_assignment: false,
    context_id: '1',
    context_type: 'Course',
    context_name: 'Test Course',
    data: [{name: 'A', value: 90}],
    id: '6',
    permissions: {manage: true},
    points_based: false,
    scaling_factor: 1,
    title: 'Grading Scheme 6',
    workflow_state: 'active',
  },
  {
    assessed_assignment: false,
    context_id: '1',
    context_type: 'Account',
    context_name: 'Test Account',
    data: [{name: 'A', value: 90}],
    id: '7',
    permissions: {manage: true},
    points_based: false,
    scaling_factor: 1,
    title: 'Grading Scheme 7',
    workflow_state: 'active',
  },
  {
    assessed_assignment: false,
    context_id: '1',
    context_type: 'Course',
    context_name: 'Test Course',
    data: [{name: 'A', value: 90}],
    id: '8',
    permissions: {manage: true},
    points_based: false,
    scaling_factor: 1,
    title: 'Grading Scheme 8',
    workflow_state: 'active',
  },
  {
    assessed_assignment: false,
    context_id: '1',
    context_type: 'Account',
    context_name: 'Test Account',
    data: [{name: 'A', value: 90}],
    id: '9',
    permissions: {manage: true},
    points_based: false,
    scaling_factor: 1,
    title: 'Grading Scheme 9',
    workflow_state: 'archived',
  },
  {
    assessed_assignment: false,
    context_id: '1',
    context_type: 'Course',
    context_name: 'Test Course',
    data: [{name: 'A', value: 90}],
    id: '10',
    permissions: {manage: true},
    points_based: false,
    scaling_factor: 1,
    title: 'Grading Scheme 10',
    workflow_state: 'active',
  },
  {
    assessed_assignment: false,
    context_id: '1',
    context_type: 'Account',
    context_name: 'Test Account',
    data: [{name: 'A', value: 90}],
    id: '11',
    permissions: {manage: true},
    points_based: false,
    scaling_factor: 1,
    title: 'Grading Scheme 11',
    workflow_state: 'archived',
  },
]

export const GradingSchemeSummaries: GradingSchemeSummary[] = AccountGradingSchemes.map(scheme => ({
  title: scheme.title,
  id: scheme.id,
  context_type: scheme.context_type,
}))

export const DefaultGradingScheme: GradingScheme = {
  id: '',
  title: 'Default Canvas Grading Scheme',
  context_id: '2',
  context_type: 'Account',
  workflow_state: 'active',
  points_based: false,
  scaling_factor: 1.0,
  context_name: 'Rohan Chugh Instructure Test',
  permissions: {
    manage: true,
  },
  data: [
    {
      name: 'A',
      value: 0.94,
    },
    {
      name: 'A-',
      value: 0.9,
    },
    {
      name: 'B+',
      value: 0.87,
    },
    {
      name: 'B',
      value: 0.84,
    },
    {
      name: 'B-',
      value: 0.8,
    },
    {
      name: 'C+',
      value: 0.77,
    },
    {
      name: 'C',
      value: 0.74,
    },
    {
      name: 'C-',
      value: 0.7,
    },
    {
      name: 'D+',
      value: 0.67,
    },
    {
      name: 'D',
      value: 0.64,
    },
    {
      name: 'D-',
      value: 0.61,
    },
    {
      name: 'F',
      value: 0.0,
    },
  ],
  assessed_assignment: false,
}

export const AccountGradingSchemeCards: GradingSchemeCardData[] = AccountGradingSchemes.map(
  scheme => ({
    gradingScheme: scheme,
    editing: false,
  })
)

export const ExtraGradingSchemeCards: GradingSchemeCardData[] = ExtraGradingSchemes.map(scheme => ({
  gradingScheme: scheme,
  editing: false,
}))

export const DefaultUsedLocations: UsedLocation[] = [
  {
    id: '2',
    name: 'English',
    'concluded?': false,
    assignments: [
      {
        id: '12',
        title: 'Demo Assignment 1',
      },
      {
        id: '6',
        title: 'Rubric Example',
      },
    ],
  },
  {
    id: '7',
    name: 'Course with name assignment',
    'concluded?': true,
    assignments: [
      {
        id: '8',
        title: 'Assignment 8',
      },
      {
        id: '11',
        title: 'Same Name',
      },
    ],
  },
  {
    id: '8',
    name: 'Same Name',
    'concluded?': false,
    assignments: [
      {
        id: '13',
        title: 'Assignment 13',
      },
    ],
  },
  {
    id: '4',
    name: 'Everything but the Kitchen Sink',
    'concluded?': false,
    assignments: [
      {
        id: '29',
        title: 'test ',
      },
    ],
  },
  {
    id: '3',
    name: 'Icirrus City',
    'concluded?': false,
    assignments: [
      {
        id: '10',
        title: 'Focus Energy',
      },
      {
        id: '9',
        title: 'Spike Cannon',
      },
    ],
  },
  {
    id: '5',
    name: 'Sections',
    'concluded?': false,
    assignments: [
      {
        id: '35',
        title: 'test assignment',
      },
    ],
  },
  {
    id: '1',
    name: 'Temp',
    'concluded?': false,
    assignments: [
      {
        id: '1',
        title: 'Sample',
      },
    ],
  },
]

export const secondUsedLocations = [
  {
    id: '1',
    name: 'Temp',
    'concluded?': false,
    assignments: [
      {
        id: '2',
        title: 'Sample 2',
      },
      {
        id: '3',
        title: 'Sample 3',
      },
    ],
  },
  {
    id: '6',
    name: 'Course 6',
    'concluded?': false,
    assignments: [
      {
        id: '7',
        title: 'Assignment 7',
      },
    ],
  },
]

export class IntersectionObserver {
  root = null

  rootMargin = ''

  thresholds = []

  // eslint-disable-next-line no-undef
  callback: IntersectionObserverCallback

  // eslint-disable-next-line no-undef
  constructor(callback: IntersectionObserverCallback) {
    this.callback = callback
    return this
  }

  disconnect() {
    return this
  }

  takeRecords() {
    return []
  }

  unobserve() {
    return this
  }

  observe() {
    const mockRect: DOMRectReadOnly = {
      bottom: 0,
      height: 0,
      left: 0,
      right: 0,
      top: 0,
      width: 0,
      x: 0,
      y: 0,
      toJSON: () => {},
    }
    const mockEntry: IntersectionObserverEntry = {
      boundingClientRect: mockRect,
      intersectionRatio: 0,
      intersectionRect: mockRect,
      rootBounds: null,
      isIntersecting: true,
      target: document.createElement('div'),
      time: 0,
    }
    this.callback([mockEntry], this)
  }
}
