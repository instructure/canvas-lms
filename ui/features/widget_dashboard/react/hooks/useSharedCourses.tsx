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

import {useState, useMemo} from 'react'
import type {CourseGrade} from '../types'
import {useWidgetDashboard, type SharedCourseData} from './useWidgetDashboardContext'
import {COURSE_GRADES_WIDGET} from '../constants'

interface UseSharedCoursesOptions {
  limit?: number
}

interface UseSharedCoursesResult {
  data: CourseGrade[]
  isLoading: boolean
  error: Error | null
  hasNextPage: boolean
  hasPreviousPage: boolean
  fetchNextPage: () => void
  fetchPreviousPage: () => void
  goToPage: (pageNumber: number) => void
  currentPage: number
  totalPages: number
}

function transformSharedCourseDataToCourseGrade(sharedCourse: SharedCourseData): CourseGrade {
  return {
    courseId: sharedCourse.courseId,
    courseCode: sharedCourse.courseCode,
    courseName: sharedCourse.courseName,
    currentGrade: sharedCourse.currentGrade,
    gradingScheme: sharedCourse.gradingScheme,
    lastUpdated: new Date(sharedCourse.lastUpdated),
    courseColor: sharedCourse.courseColor,
    term: sharedCourse.term,
    image: sharedCourse.image,
  }
}

export function useSharedCourses(options: UseSharedCoursesOptions = {}): UseSharedCoursesResult {
  const {limit = COURSE_GRADES_WIDGET.MAX_GRID_ITEMS} = options
  const [currentPageIndex, setCurrentPageIndex] = useState(0)
  const {sharedCourseData} = useWidgetDashboard()

  // Transform shared data to CourseGrade format
  const transformedData = useMemo(
    () => sharedCourseData.map(transformSharedCourseDataToCourseGrade),
    [sharedCourseData],
  )

  // Paginate the data client-side
  const paginatedData = useMemo(() => {
    const totalItems = transformedData.length
    const totalPages = Math.ceil(totalItems / limit)
    const pages: CourseGrade[][] = []

    for (let i = 0; i < totalPages; i++) {
      const start = i * limit
      const end = start + limit
      pages.push(transformedData.slice(start, end))
    }

    return {pages, totalPages}
  }, [transformedData, limit])

  const currentPage = paginatedData.pages[currentPageIndex] || []
  const totalPages = paginatedData.totalPages

  const fetchNextPage = () => {
    if (currentPageIndex < totalPages - 1) {
      setCurrentPageIndex(currentPageIndex + 1)
    }
  }

  const fetchPreviousPage = () => {
    if (currentPageIndex > 0) {
      setCurrentPageIndex(currentPageIndex - 1)
    }
  }

  const goToPage = (pageNumber: number) => {
    const targetIndex = pageNumber - 1
    if (targetIndex >= 0 && targetIndex < totalPages) {
      setCurrentPageIndex(targetIndex)
    }
  }

  return {
    data: currentPage,
    isLoading: false, // Data is immediately available from ENV
    error: null, // No network errors with ENV data
    hasNextPage: currentPageIndex < totalPages - 1,
    hasPreviousPage: currentPageIndex > 0,
    fetchNextPage,
    fetchPreviousPage,
    goToPage,
    currentPage: currentPageIndex + 1,
    totalPages: Math.max(totalPages, 1),
  }
}
