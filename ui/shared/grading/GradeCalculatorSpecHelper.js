/*
 * Copyright (C) 2018 - present Instructure, Inc.
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

export function createCourseGradesWithGradingPeriods() {
  return {
    assignmentGroups: {
      301: {
        assignmentGroupId: 301,
        assignmentGroupWeight: 40,
        current: {score: 5, possible: 10, submissions: []},
        final: {score: 5, possible: 20, submissions: []},
      },

      302: {
        assignmentGroupId: 302,
        assignmentGroupWeight: 60,
        current: {score: 12, possible: 15, submissions: []},
        final: {score: 12, possible: 25, submissions: []},
      },
    },

    gradingPeriods: {
      701: {
        gradingPeriodId: 701,
        gradingPeriodWeight: 25,
        assignmentGroups: {
          301: {
            assignmentGroupId: 301,
            assignmentGroupWeight: 40,
            current: {score: 5, possible: 10, submissions: []},
            final: {score: 5, possible: 20, submissions: []},
          },
        },
        current: {score: 5, possible: 10, submissions: []},
        final: {score: 5, possible: 20, submissions: []},
      },

      702: {
        gradingPeriodId: 702,
        gradingPeriodWeight: 75,
        assignmentGroups: {
          302: {
            assignmentGroupId: 302,
            assignmentGroupWeight: 60,
            current: {score: 12, possible: 15, submissions: []},
            final: {score: 12, possible: 25, submissions: []},
          },
        },
        current: {score: 12, possible: 15, submissions: []},
        final: {score: 12, possible: 25, submissions: []},
      },
    },

    current: {score: 17, possible: 25, submissions: []},
    final: {score: 17, possible: 45, submissions: []},
  }
}
