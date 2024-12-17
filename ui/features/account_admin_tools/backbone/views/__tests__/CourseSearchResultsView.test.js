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

import CourseSearchResultsView from '../CourseSearchResultsView'
import CourseRestore from '../../models/CourseRestore'
import {initFlashContainer} from '@canvas/rails-flash-notifications'

const errorMessageJSON = {
  status: 'not_found',
  message: 'There was no foo bar in the baz',
}

const courseJSON = {
  account_id: 6,
  course_code: 'Super',
  default_view: 'feed',
  end_at: null,
  enrollments: [],
  hide_final_grades: false,
  id: 58,
  name: 'Super Fun Deleted Course',
  sis_course_id: null,
  start_at: null,
  workflow_state: 'deleted',
}

describe('CourseSearchResultsView', () => {
  let courseRestore
  let courseSearchResultsView
  let flashContainer

  beforeEach(() => {
    courseRestore = new CourseRestore({account_id: 6})
    courseSearchResultsView = new CourseSearchResultsView({model: courseRestore})
    flashContainer = document.createElement('div')
    flashContainer.id = 'flash_screenreader_holder'
    document.body.appendChild(flashContainer)
    document.body.appendChild(courseSearchResultsView.render().el)
  })

  afterEach(() => {
    document.body.innerHTML = ''
  })

  it('sets restored to false when initialized', () => {
    expect(courseRestore.get('restored')).toBeFalsy()
  })

  it('re-renders when model changes', () => {
    const renderSpy = jest.spyOn(courseSearchResultsView, 'render')
    courseSearchResultsView.applyBindings()
    courseRestore.trigger('change')
    expect(renderSpy).toHaveBeenCalledTimes(1)
  })

  it('calls restore on the model when restore button is clicked', () => {
    courseRestore.set(courseJSON)
    const restoreSpy = jest.spyOn(courseRestore, 'restore').mockResolvedValue()
    courseSearchResultsView.$restoreCourseBtn.click()
    expect(restoreSpy).toHaveBeenCalledTimes(1)
  })

  it('displays error message when course is not found', () => {
    courseRestore.clear({silent: true})
    courseRestore.set(errorMessageJSON)
    const errorMessage = courseSearchResultsView.$el.find('.alert-error')
    expect(errorMessage.length).toBeGreaterThan(0)
  })

  it('displays restore button when deleted course is found', () => {
    courseRestore.set(courseJSON)
    const restoreButton = courseSearchResultsView.$el.find('#restoreCourseBtn')
    expect(restoreButton.length).toBeGreaterThan(0)
  })

  describe('screenreader messages', () => {
    beforeEach(() => {
      initFlashContainer()
    })

    it('announces when course is not found', () => {
      courseRestore.clear({silent: true})
      courseRestore.set(errorMessageJSON)
      courseSearchResultsView.resultsFound()
      expect(flashContainer.textContent).toMatch('Course not found')
    })

    it('announces when deleted course is found', () => {
      courseRestore.set(courseJSON)
      courseSearchResultsView.resultsFound()
      expect(flashContainer.textContent).toMatch('Course found')
    })

    it('announces when non-deleted course is found', () => {
      courseRestore.set({
        ...courseJSON,
        workflow_state: 'active',
      })
      courseSearchResultsView.resultsFound()
      expect(flashContainer.textContent).toMatch(/Course found \(not deleted\)/)
    })
  })

  describe('course restore options', () => {
    it('shows success message and navigation options after course is restored', () => {
      courseRestore.set(courseJSON, {silent: true})
      courseRestore.set('restored', true, {silent: true})
      courseRestore.set('workflow_state', 'active')

      const successMessage = courseSearchResultsView.$el.find('.alert-success')
      const viewCourseLink = courseSearchResultsView.$el.find('#viewCourse')
      const addEnrollmentsLink = courseSearchResultsView.$el.find('#addEnrollments')

      expect(successMessage.length).toBeGreaterThan(0)
      expect(viewCourseLink.length).toBeGreaterThan(0)
      expect(addEnrollmentsLink.length).toBeGreaterThan(0)
    })

    it('shows navigation options for non-deleted courses', () => {
      courseRestore.set(courseJSON, {silent: true})
      courseRestore.set('workflow_state', 'active')

      const viewCourseLink = courseSearchResultsView.$el.find('#viewCourse')
      const addEnrollmentsLink = courseSearchResultsView.$el.find('#addEnrollments')

      expect(viewCourseLink.length).toBeGreaterThan(0)
      expect(addEnrollmentsLink.length).toBeGreaterThan(0)
    })
  })
})
