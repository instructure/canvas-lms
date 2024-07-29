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

import React, {useEffect, useState} from 'react'

export default function useIsInSpeedGrader() {
  const [isInSpeedGrader, setIsInSpeedGrader] = useState(false)

  useEffect(() => {
    const checkSpeedGrader = () => {
      try {
        const currentUrl = new URL(window.location.href)

        // Check if speed_grader parameter is set to 1
        const params = new URLSearchParams(currentUrl.search)
        if (params.get('speed_grader') === '1') {
          setIsInSpeedGrader(true)
          return
        }

        setIsInSpeedGrader(false)
      } catch (error) {
        // If we can't access top window location due to cross-origin restrictions,
        // we assume we're not in SpeedGrader
        setIsInSpeedGrader(false)
      }
    }

    checkSpeedGrader()
  }, [])

  return isInSpeedGrader
}
