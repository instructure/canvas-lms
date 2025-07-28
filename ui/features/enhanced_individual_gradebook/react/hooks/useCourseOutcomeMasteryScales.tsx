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

import {useQuery} from '@tanstack/react-query'
import {fetchCourseOutcomeMasteryScales} from '../../queries/Queries'

export const useCourseOutcomeMasteryScales = (courseId: string) => {
  const isAccountLevelMasteryScalesEnabled = window.ENV?.FEATURES?.account_level_mastery_scales

  const queryKey = ['individual-gradebook-course-outcome-mastery-scales', courseId]
  const {data, error, isLoading} = useQuery({
    queryKey,
    queryFn: fetchCourseOutcomeMasteryScales,
    enabled: isAccountLevelMasteryScalesEnabled && !!courseId,
  })

  if (!isAccountLevelMasteryScalesEnabled) {
    return {
      outcomeCalculationMethod: null,
      outcomeProficiency: null,
      courseOutcomeMasteryScalesLoading: false,
      courseOutcomeMasteryScalesSuccessful: true,
    }
  }

  const outcomeCalculationMethod = data?.course.outcomeCalculationMethod || null
  const outcomeProficiency = data?.course.outcomeProficiency || null

  return {
    outcomeCalculationMethod,
    outcomeProficiency,
    courseOutcomeMasteryScalesLoading: isLoading,
    courseOutcomeMasteryScalesSuccessful: !error && !isLoading,
  }
}
