/*
 * Copyright (C) 2024 - present Instructure, Inc.
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

import React, {useCallback, useState} from 'react'
import _ from 'lodash'
import Sparkle from './Sparkle'
import useRandomInterval from '@canvas/use-random-interval-hook'

enum Layer {
  Lower = 1,
  Middle = 2,
  Upper = 3,
}

type Size = 'small' | 'medium'

type SparklesProps = {
  enabled: boolean
  children: React.ReactNode
  size: Size
}

type SparkleState = {
  createdAt: number
  component: React.ReactNode
}

const CONSTANTS = {
  LIFESPAN_MS: 800,
  INTERVAL_MIN_MS: 100,
  INTERVAL_MAX_MS: 400,
  PLACEMENT_MIN_PERCENT: 5,
  PLACEMENT_MAX_PERCENT: 90,
  SMALL_SIZE_MIN_PX: 13.5,
  SMALL_SIZE_MAX_PX: 28.5,
  MEDIUM_SIZE_MIN_PX: 18,
  MEDIUM_SIZE_MAX_PX: 38,
}

const generateSparkle = (size: Size) => {
  const colors = ['hsl(50deg, 100%, 65%)', 'hsl(210deg, 100%, 65%)', 'hsl(340deg, 100%, 60%)']
  const randomPlacement = () =>
    `${_.random(CONSTANTS.PLACEMENT_MIN_PERCENT, CONSTANTS.PLACEMENT_MAX_PERCENT)}%`
  const min = size === 'small' ? CONSTANTS.SMALL_SIZE_MIN_PX : CONSTANTS.MEDIUM_SIZE_MIN_PX
  const max = size === 'small' ? CONSTANTS.SMALL_SIZE_MAX_PX : CONSTANTS.MEDIUM_SIZE_MAX_PX
  const props = {
    color: _.sample(colors) as string,
    key: _.uniqueId('sparkle-'),
    size: _.random(min, max),
    style: {
      top: randomPlacement(),
      left: randomPlacement(),
      zIndex: _.sample([Layer.Lower, Layer.Upper, Layer.Upper]), // 1/3 behind, 2/3 in front
    },
  }

  return <Sparkle {...props} />
}

// Inspired by & thanks to: https://www.joshwcomeau.com/react/animated-sparkles-in-react/
export default function Sparkles(props: SparklesProps) {
  const [sparkles, setSparkles] = useState<SparkleState[]>([])

  const animate = useCallback(() => {
    setSparkles(prevSparkles => {
      const now = Date.now()
      return [
        ...prevSparkles.filter((s: SparkleState) => s.createdAt + CONSTANTS.LIFESPAN_MS > now),
        {createdAt: now, component: generateSparkle(props.size)},
      ]
    })
  }, [props.size])

  useRandomInterval(animate, CONSTANTS.INTERVAL_MIN_MS, CONSTANTS.INTERVAL_MAX_MS, props.enabled)

  return (
    <span style={{display: 'inline-block', position: 'relative'}}>
      {props.enabled && sparkles.map(s => s.component)}
      <span style={{position: 'relative', zIndex: Layer.Middle}}>{props.children}</span>
    </span>
  )
}
