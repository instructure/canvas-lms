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

import {gql} from '@apollo/client'

export const GET_ASSIGNMENTS_QUERY = gql`
query getAssignments($assignmentGroupId: ID!, $gradingPeriodId: ID) {
  assignmentGroup(id: $assignmentGroupId) {
    assignmentsConnection(
      filter: {
        gradingPeriodId: $gradingPeriodId
        submissionTypes: [
          attendance,
          basic_lti_launch,
          discussion_topic,
          external_tool,
          media_recording,
          none,
          not_graded,
          on_paper,
          online_quiz,
          online_text_entry,
          online_upload,
          online_url,
          student_annotation,
        ]
      },
      first: 100,
      after: ""
    ) {
      pageInfo {
        hasNextPage
        endCursor
      }
      nodes {
        _id
        allowedAttempts
        allowedExtensions
        anonymizeStudents
        anonymousGrading
        anonymousInstructorAnnotations  
        assignmentGroupId
        assignmentVisibility
        checkpoints {
          dueAt
          lockAt
          name
          onlyVisibleToOverrides
          pointsPossible
          tag
          unlockAt
        }
        courseId
        createdAt
        dueAt
        dueDateRequired
        gradedSubmissionsExist
        gradeGroupStudentsIndividually
        gradesPublished
        gradingStandardId
        gradingType
        groupCategoryId
        hasRubric
        hasSubAssignments
        hasSubmittedSubmissions
        htmlUrl
        importantDates
        lockAt
        moderatedGradingEnabled
        moduleItems { position module { _id } }
        muted
        name
        omitFromFinalGrade
        onlyVisibleToOverrides
        peerReviews {
          anonymousReviews
          automaticReviews
          enabled
          intraReviews
        }
        pointsPossible
        position
        postManually
        postToSis
        published
        state
        submissionTypes
        unlockAt
        updatedAt
        visibleToEveryone
      }
    }
  }
}`
