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

const I18n = useI18nScope('grade_summary')

const ScoreDistributionGraph = props => {
  const {assignment} = props
  const GRAPH_SCALAR = 150.0
  const GRAY_COLOR = '#556572'
  const BLUE_COLOR = '#224488'
  const BLUE_FILL_COLOR = '#aabbdd'

  const scaleStatValue = stat => {
    return (stat / assignment?.pointsPossible) * GRAPH_SCALAR
  }

  const graph = {
    title: I18n.t('Score Distribution Graph - %{title}', {title: assignment?.name}),
    max_pos: GRAPH_SCALAR,
    low_pos: scaleStatValue(assignment?.scoreStatistic?.minimum),
    lq_pos: scaleStatValue(assignment?.scoreStatistic?.lowerQ),
    uq_pos: scaleStatValue(assignment?.scoreStatistic?.upperQ),
    high_pos: scaleStatValue(assignment?.scoreStatistic?.maximum),
    median_pos: scaleStatValue(assignment?.scoreStatistic?.median),
    score_pos: scaleStatValue(assignment?.submissionsConnection?.nodes[0]?.score),
  }

  const style = {
    cursor: 'pointer',
    float: 'right',
    height: '30px',
    marginLeft: 'left: 20px',
    width: '161px',
    position: 'relative',
    marginRight: 'right: 30px',
  }

  const zeroPosition = '0'
  const maxSvgHeight = '27'
  const minSvgHeight = '3'
  const displaySvgHeight = '24'
  const startSvgHeight = '6'
  const strokeWidthDefault = '2'
  const midSvgHeight = '15'

  const myScoreBoxHeight = '14'
  const myScoreBoxStartPos = '8'

  const viewBoxValues = '-1 0 160 30'

  const createSvgLine = (
    className,
    x1,
    y1,
    x2,
    y2,
    strokeWidth = strokeWidthDefault,
    rx,
    fill
  ) => ({
    className,
    x1,
    y1,
    x2,
    y2,
    strokeWidth,
    rx,
    fill,
  })

  const svgLines = [
    createSvgLine('zero', zeroPosition, minSvgHeight, zeroPosition, maxSvgHeight),
    createSvgLine('possible', `${graph.max_pos}`, minSvgHeight, `${graph.max_pos}`, maxSvgHeight),
    createSvgLine(
      'min',
      `${graph.low_pos}`,
      startSvgHeight,
      `${graph.low_pos}`,
      displaySvgHeight,
      strokeWidthDefault
    ),
    createSvgLine(
      'bottomQ',
      `${graph.low_pos}`,
      midSvgHeight,
      `${graph.lq_pos}`,
      midSvgHeight,
      strokeWidthDefault
    ),
    createSvgLine(
      'topQ',
      `${graph.uq_pos}`,
      midSvgHeight,
      `${graph.high_pos}`,
      midSvgHeight,
      strokeWidthDefault
    ),
    createSvgLine(
      'max',
      `${graph.high_pos}`,
      startSvgHeight,
      `${graph.high_pos}`,
      displaySvgHeight,
      strokeWidthDefault
    ),
    createSvgLine(
      'median',
      `${graph.median_pos}`,
      minSvgHeight,
      `${graph.median_pos}`,
      maxSvgHeight,
      strokeWidthDefault
    ),
  ]

  const mid50Rect = {
    className: 'mid50',
    x: `${graph.lq_pos}`,
    y: minSvgHeight,
    width: `${graph.uq_pos - graph.lq_pos}`,
    height: displaySvgHeight,
    strokeWidth: strokeWidthDefault,
    rx: minSvgHeight,
    fill: 'none',
  }

  const myScoreRect = {
    x: `${graph.score_pos - 7}`,
    y: myScoreBoxStartPos,
    width: myScoreBoxHeight,
    height: myScoreBoxHeight,
    strokeWidth: strokeWidthDefault,
    rx: minSvgHeight,
    fill: BLUE_FILL_COLOR,
  }

  return (
    <svg
      viewBox={viewBoxValues}
      xmlns="http://www.w3.org/2000/svg"
      style={style}
      aria-hidden="true"
      data-testid="scoreDistributionGraph"
    >
      <title>{graph.title}</title>

      {svgLines.map(lineInstructions => (
        <line key={lineInstructions.className} {...lineInstructions} stroke={GRAY_COLOR} />
      ))}

      <rect {...mid50Rect} stroke={GRAY_COLOR} />

      {assignment?.submissionsConnection?.nodes[0]?.score && (
        <rect className="myScore" {...myScoreRect} stroke={BLUE_COLOR}>
          <title>
            {I18n.t('Mean: %{mean}, High: %{high}, Low: %{low}', {
              mean: graph.mean,
              high: graph.maximum,
              low: graph.minimum,
            })}
          </title>
        </rect>
      )}
    </svg>
  )
}

export default ScoreDistributionGraph
