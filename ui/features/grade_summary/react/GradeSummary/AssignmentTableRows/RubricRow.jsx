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

import React from 'react'

import {useScope as useI18nScope} from '@canvas/i18n'

import {Link} from '@instructure/ui-link'
import {Flex} from '@instructure/ui-flex'
import {Table} from '@instructure/ui-table'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'

import Rubric from '@canvas/rubrics/react/Rubric'

const I18n = useI18nScope('grade_summary')

export const rubricRow = (assignment, setOpenRubricDetailIds, openRubricDetailIds) => {
  const transformToRubricAssessmentShape = inputObject => {
    const assessmentData = inputObject.data.map(item => ({
      criterion_id: item.criterion._id,
      comments: item.comments,
      points: {
        text: null,
        value: item.points,
        valid: true,
      },
      focusPoints: null,
      saveCommentsForLater: false,
    }))

    const rubricAssessmentShapeObject = {
      data: assessmentData,
      score: inputObject.score,
    }

    return rubricAssessmentShapeObject
  }

  const transformToRubricShape = inputData => {
    const criteria = inputData.criteria.map(criterion => {
      const ratings = criterion.ratings.map(rating => ({
        points: rating.points,
        description: rating.description,
        long_description: rating.long_description,
        endOfRangePoints: null,
      }))

      return {
        id: criterion._id,
        description: criterion.description,
        long_description: criterion.long_description,
        learning_outcome_id: criterion.outcome ? criterion.outcome : undefined,
        points: criterion.points,
        ratings,
        mastery_points: null,
        criterion_use_range: criterion.criterion_use_range,
      }
    })

    const rubricShapeObject = {
      criteria,
      free_form_criterion_comments: inputData.free_form_criterion_comments,
      points_possible: inputData.points_possible,
      title: inputData.title,
    }

    return rubricShapeObject
  }

  const transformToRubricAssociationShape = inputData => {
    const rubricAssociationShapeObject = {
      hide_score_total: inputData.hide_score_total,
      summary_data: {
        saved_comments: {}, // Assuming an empty object for saved comments
      },
    }

    return rubricAssociationShapeObject
  }

  const assessorName =
    assignment?.submissionsConnection?.nodes[0]?.rubricAssessmentsConnection?.nodes[0]?.assessor
      ?.shortName ||
    assignment?.submissionsConnection?.nodes[0]?.rubricAssessmentsConnection?.nodes[0]?.assessor
      ?.name

  return (
    <Table.Row key={`assignment_rubric_${assignment._id}`}>
      <Table.Cell colSpan="5" textAlign="center">
        <Flex direction="column" width="100%">
          <Flex.Item>
            <View as="div" margin="small" padding="0 0 small 0" borderWidth="0 0 small 0">
              <Flex width="100%">
                <Flex.Item textAlign="start" shouldGrow={true}>
                  <Text weight="bold">
                    {assessorName
                      ? I18n.t('Assessment by %{assessor}', {assessor: assessorName})
                      : I18n.t('Rubric Assessment')}
                  </Text>
                </Flex.Item>
                <Flex.Item textAlign="end">
                  <Link
                    as="button"
                    isWithinText={false}
                    onClick={() => {
                      const arr = [...openRubricDetailIds]
                      const index = arr.indexOf(assignment._id)
                      if (index > -1) {
                        arr.splice(index, 1)
                        setOpenRubricDetailIds(arr)
                      }
                    }}
                  >
                    {I18n.t('Close')}
                  </Link>
                </Flex.Item>
              </Flex>
            </View>
          </Flex.Item>
          <Flex.Item>
            <Rubric
              customRatings={ENV.outcome_proficiency ? ENV.outcome_proficiency.ratings : []}
              rubric={transformToRubricShape(assignment.rubric)}
              rubricAssessment={transformToRubricAssessmentShape(
                assignment.submissionsConnection.nodes[0].rubricAssessmentsConnection.nodes[0]
              )}
              rubricAssociation={transformToRubricAssociationShape(assignment.rubricAssociation)}
              isSummary={false}
            >
              {null}
            </Rubric>
          </Flex.Item>
        </Flex>
      </Table.Cell>
    </Table.Row>
  )
}
