/*
 * Copyright (C) 2026 - present Instructure, Inc.
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

import formatMessage from '../../../format-message'

export const SMALL = 'small'
export const MEDIUM = 'medium'
export const LARGE = 'large'
export const EXTRA_LARGE = 'extra-large'
export const CUSTOM = 'custom'

export const PLAYER_CONTROLS_HEIGHT = 48
export const TRANSCRIPT_SIDEBAR_WIDTH = 300
export const TRANSCRIPT_SIDEBAR_THRESHOLD = 720

export const playerLayoutDimensions: Record<string, {width: number; height: number}> = {
  [SMALL]: {width: 400, height: 273},
  [MEDIUM]: {width: 480, height: 318},
  [LARGE]: {width: 700, height: 442},
  [EXTRA_LARGE]: {width: 850, height: 357},
}

const playerLayoutSizes = [SMALL, MEDIUM, LARGE, EXTRA_LARGE, CUSTOM] as const

export type PlayerLayoutSize = (typeof playerLayoutSizes)[number]

export function getPlayerLayoutSizes(): readonly PlayerLayoutSize[] {
  return playerLayoutSizes
}

export function labelForPlayerLayoutSize(size: string): string {
  const dims = playerLayoutDimensions[size]
  switch (size) {
    case SMALL:
      return formatMessage('Small ({width} x {height}px)', dims)
    case MEDIUM:
      return formatMessage('Medium ({width} x {height}px)', dims)
    case LARGE:
      return formatMessage('Large ({width} x {height}px)', dims)
    case EXTRA_LARGE:
      return formatMessage('Extra Large ({width} x {height}px)', dims)
    default:
      return formatMessage('Custom')
  }
}

// Scale functions for the Custom player layout option.
// Signature matches scaleForWidth/scaleForHeight in DimensionUtils.js
// (naturalWidth/naturalHeight are unused here — the formula is fixed).
export function scalePlayerLayoutForWidth(
  _naturalWidth: number,
  _naturalHeight: number,
  targetWidth: number | null,
): {width: number | null; height: number | null} {
  if (targetWidth == null) return {width: null, height: null}
  const videoWidth =
    targetWidth > TRANSCRIPT_SIDEBAR_THRESHOLD
      ? targetWidth - TRANSCRIPT_SIDEBAR_WIDTH
      : targetWidth
  return {
    width: targetWidth,
    height: Math.round(videoWidth * (9 / 16) + PLAYER_CONTROLS_HEIGHT),
  }
}

export function scalePlayerLayoutForHeight(
  _naturalWidth: number,
  _naturalHeight: number,
  targetHeight: number | null,
): {width: number | null; height: number | null} {
  if (targetHeight == null) return {width: null, height: null}
  const videoWidth = (targetHeight - PLAYER_CONTROLS_HEIGHT) * (16 / 9)
  const totalWidth =
    videoWidth > TRANSCRIPT_SIDEBAR_THRESHOLD
      ? Math.round(videoWidth + TRANSCRIPT_SIDEBAR_WIDTH)
      : Math.round(videoWidth)
  return {width: totalWidth, height: targetHeight}
}
