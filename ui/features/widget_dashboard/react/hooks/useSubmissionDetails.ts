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

import {useQuery} from '@tanstack/react-query'
import {gql} from 'graphql-tag'
import {executeGraphQLQuery} from '../utils/graphql'
import type {SubmissionDetails} from '../types'

const SUBMISSION_DETAILS_QUERY = gql`
  query GetSubmissionDetails($submissionId: ID!) {
    legacyNode(_id: $submissionId, type: Submission) {
      ... on Submission {
        _id
        rubricAssessmentsConnection(first: 1) {
          nodes {
            _id
            score
            assessmentRatings {
              _id
              criterion {
                _id
                description
                longDescription
                points
              }
              description
              points
              comments
              commentsHtml
            }
          }
        }
        recentCommentsConnection: commentsConnection(first: 5, sortOrder: desc) {
          nodes {
            _id
            comment
            htmlComment
            author {
              _id
              name
            }
            createdAt
          }
        }
        allCommentsConnection: commentsConnection(first: 1) {
          pageInfo {
            totalCount
          }
        }
      }
    }
  }
`

interface GraphQLResponse {
  legacyNode: {
    _id: string
    rubricAssessmentsConnection: {
      nodes: Array<{
        _id: string
        score: number | null
        assessmentRatings: Array<{
          _id: string | null
          criterion: {
            _id: string
            description: string | null
            longDescription: string | null
            points: number | null
          } | null
          description: string | null
          points: number | null
          comments: string | null
          commentsHtml: string | null
        }>
      }>
    }
    recentCommentsConnection: {
      nodes: Array<{
        _id: string
        comment: string | null
        htmlComment: string | null
        author: {
          _id: string
          name: string
        } | null
        createdAt: string
      }>
    }
    allCommentsConnection: {
      pageInfo: {
        totalCount: number
      }
    }
  } | null
}

export function useSubmissionDetails(submissionId: string | null) {
  return useQuery({
    queryKey: ['submission-details', submissionId],
    queryFn: async (): Promise<SubmissionDetails> => {
      if (!submissionId) {
        return {rubricAssessments: [], comments: [], totalCommentsCount: 0}
      }

      const response = await executeGraphQLQuery<GraphQLResponse>(SUBMISSION_DETAILS_QUERY, {
        submissionId,
      })

      if (!response?.legacyNode) {
        return {rubricAssessments: [], comments: [], totalCommentsCount: 0}
      }

      const rubricAssessments =
        response.legacyNode.rubricAssessmentsConnection?.nodes.map(assessment => ({
          _id: assessment._id,
          score: assessment.score,
          assessmentRatings: assessment.assessmentRatings.map(rating => ({
            _id: rating._id,
            criterion: rating.criterion,
            description: rating.description,
            points: rating.points,
            comments: rating.comments,
            commentsHtml: rating.commentsHtml,
          })),
        })) || []

      const comments =
        response.legacyNode.recentCommentsConnection?.nodes.map(comment => ({
          _id: comment._id,
          comment: comment.comment,
          htmlComment: comment.htmlComment,
          author: comment.author,
          createdAt: comment.createdAt,
        })) || []

      const totalCommentsCount =
        response.legacyNode.allCommentsConnection?.pageInfo?.totalCount || 0

      return {rubricAssessments, comments, totalCommentsCount}
    },
    enabled: !!submissionId && !!window.ENV?.current_user_id,
    staleTime: 5 * 60 * 1000,
    refetchOnWindowFocus: false,
  })
}
