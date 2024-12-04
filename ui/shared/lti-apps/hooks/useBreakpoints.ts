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

import {useMedia} from 'react-use'
import {breakpoints} from '../utils/breakpoints'

export default function useBreakpoints() {
  const isDesktop = useMedia(`(min-width: ${breakpoints.desktop})`)
  const isTablet = useMedia(`(min-width: ${breakpoints.tablet})`) && !isDesktop
  const isMobile = useMedia(`(min-width: ${breakpoints.mobile})`) && !isTablet && !isDesktop

  const isMaxMobile = useMedia(`(max-width: ${breakpoints.mobile})`)
  const isMaxTablet = useMedia(`(max-width: ${breakpoints.tablet})`)

  return {isDesktop, isTablet, isMobile, isMaxMobile, isMaxTablet}
}
