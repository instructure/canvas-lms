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

import {canvas} from '@instructure/ui-themes'

/**
 * Standard Canvas responsive breakpoints
 *
 * Based on InstUI theme values:
 * - mobile: ≤767px (canvas.breakpoints.medium - 1px)
 * - tablet: 768-1023px (canvas.breakpoints.medium to canvas.breakpoints.desktop - 1px)
 * - desktop: ≥1024px (canvas.breakpoints.desktop)
 *
 * Use these constants for consistent responsive behavior across Canvas.
 */
export const BREAKPOINTS = {
  mobile: parseInt(canvas.breakpoints.medium) * 16 - 1, // 767px
  tablet: parseInt(canvas.breakpoints.desktop) * 16 - 1, // 1023px
  desktop: parseInt(canvas.breakpoints.desktop) * 16, // 1024px
} as const

/**
 * Generates media query objects for InstUI Responsive component
 *
 * Creates mutually exclusive breakpoints to avoid overlapping matches.
 *
 * @example
 * ```tsx
 * <Responsive
 *   match="media"
 *   query={responsiveQuerySizes({mobile: true, desktop: true})}
 *   props={{
 *     mobile: {direction: 'column'},
 *     desktop: {direction: 'row'},
 *   }}
 *   render={props => <Flex direction={props.direction}>...</Flex>}
 * />
 * ```
 *
 * @param options - Which breakpoints to include
 * @returns Media query object for InstUI Responsive component
 */
export const responsiveQuerySizes = ({
  mobile = false,
  tablet = false,
  desktop = false,
}: {
  mobile?: boolean
  tablet?: boolean
  desktop?: boolean
} = {}) => {
  const querySizes: Record<string, {minWidth?: string; maxWidth?: string}> = {}

  if (mobile) {
    querySizes.mobile = {maxWidth: `${BREAKPOINTS.mobile}px`}
  }
  if (tablet) {
    querySizes.tablet = {
      minWidth: mobile ? `${BREAKPOINTS.mobile + 1}px` : '0px',
      maxWidth: `${BREAKPOINTS.tablet}px`,
    }
  }
  if (desktop) {
    querySizes.desktop = {minWidth: `${tablet ? BREAKPOINTS.desktop : BREAKPOINTS.mobile + 1}px`}
  }

  return querySizes
}
