/*
 * Copyright (C) 2025 - present Instructure, Inc.
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

import type {RollupsResponseReporting} from './types'

export const MOCK_API_OUTCOMES: RollupsResponseReporting = {
  rollups: [
    {
      scores: [
        {
          score: 3.0,
          count: 0,
          links: {outcome: '1'},
        },
        {
          score: 0,
          count: 1,
          links: {outcome: '2'},
        },
        {
          score: 4.0,
          count: 2,
          links: {outcome: '3'},
        },
        {
          score: 2.9,
          count: 1,
          links: {outcome: '4'},
        },
      ],
      links: {user: '6', status: 'active'},
    },
  ],
  meta: {
    pagination: {
      per_page: 10,
      page: 1,
      count: 1,
      page_count: 1,
    },
  },
  linked: {
    users: [],
    outcomes: [
      {
        id: 1,
        context_type: 'Course',
        display_name: 'SCI.ENV.3',
        title: 'Analyze Environmental Systems',
        description:
          '<p>Students will demonstrate the ability to analyze complex environmental systems and their interconnected relationships.</p>',
        friendly_description:
          'Understand how different parts of environmental systems work together and affect each other.',
        points_possible: 4.0,
        mastery_points: 3.0,
        ratings: [
          {description: 'Exceeds Mastery', points: 4.0, color: '127A1B'},
          {description: 'Mastery', points: 3.0, color: '0B874B'},
          {description: 'Near Mastery', points: 2.0, color: 'FAB901'},
          {description: 'Below Mastery', points: 1.0, color: 'FD5D10'},
          {description: 'No Evidence', points: 0.0, color: 'E0061F'},
        ],
        calculation_method: 'decaying_average',
        calculation_int: 65,
        alignments: [1, 2],
      },
      {
        id: 2,
        context_type: 'Course',
        display_name: 'CHEM.LAB.2',
        title: 'Apply Laboratory Safety Protocols',
        description:
          '<p>Students will demonstrate safe and proper use of laboratory equipment following established safety protocols.</p>',
        friendly_description:
          'Use lab equipment safely and follow all safety rules during experiments.',
        points_possible: 4.0,
        mastery_points: 3.0,
        ratings: [
          {description: 'Exceeds Mastery', points: 4.0, color: '127A1B'},
          {description: 'Mastery', points: 3.0, color: '0B874B'},
          {description: 'Near Mastery', points: 2.0, color: 'FAB901'},
          {description: 'Below Mastery', points: 1.0, color: 'FD5D10'},
          {description: 'No Evidence', points: 0.0, color: 'E0061F'},
        ],
        calculation_method: 'decaying_average',
        calculation_int: 65,
        alignments: [1, 2, 3],
      },
      {
        id: 3,
        context_type: 'Course',
        display_name: 'MATH.DATA.5',
        title: 'Create Data Visualizations',
        description:
          '<p>Students will create clear and effective data visualizations to communicate quantitative information.</p>',
        friendly_description: 'Make graphs and charts that clearly show what the data means.',
        points_possible: 4.0,
        mastery_points: 3.0,
        ratings: [
          {description: 'Exceeds Mastery', points: 4.0, color: '127A1B'},
          {description: 'Mastery', points: 3.0, color: '0B874B'},
          {description: 'Near Mastery', points: 2.0, color: 'FAB901'},
          {description: 'Below Mastery', points: 1.0, color: 'FD5D10'},
          {description: 'No Evidence', points: 0.0, color: 'E0061F'},
        ],
        calculation_method: 'decaying_average',
        calculation_int: 65,
        alignments: [1, 2],
      },
      {
        id: 4,
        context_type: 'Course',
        display_name: 'STAT.METH.1',
        title: 'Apply Statistical Methods',
        description:
          '<p>Students will apply appropriate statistical methods to analyze data sets and draw valid conclusions.</p>',
        friendly_description: 'Use math tools to understand what patterns in numbers mean.',
        points_possible: 4.0,
        mastery_points: 3.0,
        ratings: [
          {description: 'Exceeds Mastery', points: 4.0, color: '127A1B'},
          {description: 'Mastery', points: 3.0, color: '0B874B'},
          {description: 'Near Mastery', points: 2.0, color: 'FAB901'},
          {description: 'Below Mastery', points: 1.0, color: 'FD5D10'},
          {description: 'No Evidence', points: 0.0, color: 'E0061F'},
        ],
        calculation_method: 'decaying_average',
        calculation_int: 65,
        alignments: [1],
      },
      {
        id: 5,
        context_type: 'Course',
        display_name: 'ENG.WRITE.4',
        title: 'Construct Persuasive Arguments',
        description:
          '<p>Students will construct well-reasoned persuasive arguments supported by credible evidence.</p>',
        friendly_description: 'Write convincing arguments using good reasons and reliable sources.',
        points_possible: 4.0,
        mastery_points: 3.0,
        ratings: [
          {description: 'Exceeds Mastery', points: 4.0, color: '127A1B'},
          {description: 'Mastery', points: 3.0, color: '0B874B'},
          {description: 'Near Mastery', points: 2.0, color: 'FAB901'},
          {description: 'Below Mastery', points: 1.0, color: 'FD5D10'},
          {description: 'No Evidence', points: 0.0, color: 'E0061F'},
        ],
        calculation_method: 'decaying_average',
        calculation_int: 65,
        alignments: [],
      },
    ],
  },
}
