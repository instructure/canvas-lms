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

import {SVGIcon} from '@instructure/ui-svg-images'

// Based on https://github.com/instructure/instructure-ui/blob/master/packages/ui-icons/svg/Solid/ai.svg
const iconString = `
<svg viewBox="0 0 1920 1920" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <linearGradient id="IgniteGradient">
      <stop offset="0%" stop-color="#7F61B3" />
      <stop offset="100%" stop-color="#32759C" />
    </linearGradient>
  </defs>
  <style>
    .ignite-icon {
      fill: url(#IgniteGradient);
    }
  </style>
  <g fill-rule="evenodd" clip-rule="evenodd" stroke="none" stroke-width="1">
    <path class="ignite-icon" d="M960 0L1219.29 700.713L1920 960L1219.29 1219.29L960 1920L700.713 1219.29L0 960L700.713 700.713L960 0Z"/>
    <path class="ignite-icon" d="M1600 0L1686.43 233.571L1920 320L1686.43 406.429L1600 640L1513.57 406.429L1280 320L1513.57 233.571L1600 0Z"/>
  </g>
</svg>
`

export const IgniteAiIcon = () => {
  return <SVGIcon src={iconString} title="IgniteAI Icon" />
}
