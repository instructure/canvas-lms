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

import React from 'react'
import styled, {keyframes} from 'styled-components'

type SparkleProps = {
  color: string
  size: number
  style: React.CSSProperties
}

// Inspired by & thanks to: https://www.joshwcomeau.com/react/animated-sparkles-in-react/
export default function Sparkle(props: SparkleProps) {
  const path =
    'M92 0C92 0 96 63.4731 108.263 75.7365C120.527 88 184 92 184 92C184 92 118.527 98 108.263 108.263C98 118.527 92 184 92 184C92 184 86.4731 119 75.7365 108.263C65 97.5269 0 92 0 92C0 92 63.9731 87.5 75.7365 75.7365C87.5 63.9731 92 0 92 0Z'

  return (
    <SparkleWrapper style={props.style}>
      <SparkleSvg width={props.size} height={props.size} fill="none" viewBox="0 0 184 184">
        <path d={path} fill={props.color} />
      </SparkleSvg>
    </SparkleWrapper>
  )
}

const comeInOut = keyframes`
  0% {
    transform: translate3d(-50%, -50%, 0) scale(0);
  }
  50% {
    transform: translate3d(-50%, -50%, 0) scale(1);
  }
  100% {
    transform: translate3d(-50%, -50%, 0) scale(0);
  }
`

const spin = keyframes`
  0% {
    transform: rotate(0deg);
  }

  100% {
    transform: rotate(100deg);
  }
`
const SparkleWrapper = styled.span`
  animation: ${comeInOut} 850ms ease-in-out forwards;
  display: block;
  pointer-events: none;
  position: absolute;
`

const SparkleSvg = styled.svg`
  animation: ${spin} 1000ms linear;
  display: block;
`
