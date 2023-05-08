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

import PropTypes from 'prop-types'

export const alignmentShape = PropTypes.shape({
  _id: PropTypes.string.isRequired,
  contentType: PropTypes.oneOf(['Assignment', 'Rubric', 'AssessmentQuestionBank']).isRequired,
  title: PropTypes.string.isRequired,
  url: PropTypes.string.isRequired,
  moduleTitle: PropTypes.string,
  moduleUrl: PropTypes.string,
  moduleWorkflowState: PropTypes.string,
  assignmentContentType: PropTypes.oneOf(['assignment', 'discussion', 'quiz', 'new_quiz']),
  assignmentWorkflowState: PropTypes.string,
  quizItems: PropTypes.arrayOf(
    PropTypes.shape({
      _id: PropTypes.string.isRequired,
      title: PropTypes.string.isRequired,
    })
  ),
  alignmentsCount: PropTypes.number.isRequired,
})

export const outcomeWithAlignmentShape = PropTypes.shape({
  _id: PropTypes.string.isRequired,
  title: PropTypes.string.isRequired,
  description: PropTypes.string,
  alignments: PropTypes.arrayOf(alignmentShape),
})

export const groupDataShape = PropTypes.shape({
  _id: PropTypes.string.isRequired,
  outcomesCount: PropTypes.number.isRequired,
  outcomes: PropTypes.shape({
    pageInfo: PropTypes.shape({
      hasNextPage: PropTypes.bool.isRequired,
      endCursor: PropTypes.string,
    }),
    edges: PropTypes.arrayOf(
      PropTypes.shape({
        node: PropTypes.shape({
          _id: PropTypes.string.isRequired,
          title: PropTypes.string.isRequired,
          description: PropTypes.string,
          alignments: PropTypes.arrayOf(alignmentShape),
        }),
      })
    ),
  }),
})
