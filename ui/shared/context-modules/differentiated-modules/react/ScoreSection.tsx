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

import React from "react"
import PropTypes from "prop-types"
import { useScope as createI18nScope } from "@canvas/i18n"
import { View } from "@instructure/ui-view"
import { Flex } from "@instructure/ui-flex"
import { Text } from "@instructure/ui-text"
import type { FormMessage } from '@instructure/ui-form-field'
import type { Requirement, ScoreType, PointsInputMessages } from "./types"
import CanvasSelect from "@canvas/instui-bindings/react/Select"
import { NumberInput } from "@instructure/ui-number-input"
import { ScreenReaderContent } from "@instructure/ui-a11y-content"
import { responsiviser } from "@canvas/planner"

const I18n = createI18nScope("differentiated_modules")

const scoreTypeOptions = ["score", "percentage"]

const scoreTypeLabelMap: Record<ScoreType, string> = {
  score: I18n.t("Points"),
  percentage: I18n.t("Percentage"),
}

export interface ScoreSectionProps {
  index: number
  requirement: Requirement
  pointsInputMessages: PointsInputMessages
  onUpdateRequirement: (requirement: Requirement, index: number) => void
  validatePointsInput: (requirement: Requirement) => void
  responsiveSize: string
}

const ScoreSection = (props: ScoreSectionProps) => {
  const {
    requirement,
    index,
    onUpdateRequirement,
    pointsInputMessages,
    validatePointsInput,
    responsiveSize,
  } = props

  const minimumScore = 'minimumScore' in requirement ? Number(requirement.minimumScore) : 0

  const handleRequirementChange = ((scoreType: string, minimumScore: string) => {
    if (isNaN(Number(minimumScore)))
      return

    const updatedRequirement = {
      ...requirement,
      type: scoreType,
      minimumScore: minimumScore,
    } as Requirement

    onUpdateRequirement(updatedRequirement, index)
    validatePointsInput(updatedRequirement)
  })

  const pointsPossibleLabel =
    requirement.type === "score" ? requirement.pointsPossible : "100%"

  const messages = pointsInputMessages
    .filter((item) => item.requirementId === requirement.id)
    .map((item): FormMessage => ({ type: "newError", text: <View width={'8.188rem'} display='inline-block'>{item.message}</View> }))

  const getScoreTypeSelectWidth = () => {
    if (responsiveSize === "small") return ""
    return requirement.type === "score" ? "16.313rem" : "15.25rem"
  }

  const minimumScoreSection = (
    <Flex
      justifyItems="start"
      width="7.5rem"
      alignItems="start"
      gap="xxx-small"
    >
      <Flex.Item as="div" align="center" padding="0 0 small 0" height="2.375rem">
        <NumberInput
          allowStringValue={true}
          value={minimumScore}
          width="4rem"
          height="2.375rem"
          showArrows={false}
          renderLabel={
            <ScreenReaderContent>
              {I18n.t("Minimum Score")}
            </ScreenReaderContent>
          }
          onChange={(event) => {
            handleRequirementChange(requirement.type, event.target.value)
          }}
          messages={messages}
        />
      </Flex.Item>
      <Flex.Item>
        {requirement.pointsPossible && (
          <View as="div" margin="x-small 0 0 0">
            <ScreenReaderContent>
              {I18n.t("Points Possible")}
            </ScreenReaderContent>
            <Text data-testid="points-possible-value">{`/ ${pointsPossibleLabel}`}</Text>
          </View>
        )}
      </Flex.Item>
    </Flex>)

  const scoreTypeSelect = (

    <CanvasSelect
      id={`score-type-${index}`}
      value={requirement.type}
      label={
        <ScreenReaderContent>{I18n.t("Score Type")}</ScreenReaderContent>
      }
      onChange={(_, value) => {
        handleRequirementChange(value, minimumScore.toString())
      }}
    >
      {scoreTypeOptions.map((scoreTypeValue) => (
        <CanvasSelect.Option
          id={scoreTypeValue}
          key={`score_type_key_${scoreTypeValue}`}
          value={scoreTypeValue}
        >
          {scoreTypeLabelMap[scoreTypeValue as ScoreType]}
        </CanvasSelect.Option>
      ))}
    </CanvasSelect>

  )

  if (responsiveSize === "small") {
    return (
      <>
        <View as="div" padding="small 0">
          {scoreTypeSelect}
        </View>
        {minimumScoreSection}
      </>
    )
  }

  return (
    <Flex
      padding="small 0"
      justifyItems="space-between"
      direction="row"
      alignItems="start"
    >
      <Flex.Item margin="0 xx-small 0 0" width={getScoreTypeSelectWidth()}>
        {scoreTypeSelect}
      </Flex.Item>
      <Flex.Item>
        {minimumScoreSection}
      </Flex.Item>
    </Flex>
  )
}

ScoreSection.propTypes = {
  index: PropTypes.number,
  requirement: PropTypes.object,
  pointsInputMessages: PropTypes.array,
  onUpdateRequirement: PropTypes.func,
  validatePointsInput: PropTypes.func,
  responsiveSize: PropTypes.oneOf(["small", "medium", "large"]),
}

export default responsiviser()(ScoreSection)
