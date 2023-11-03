/*
 * Copyright (C) 2023 - present Instructure, Inc.
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

import {getFirstPageUrl, hideHomeroomCourseIfK5Student} from '../coursesQuery'
import {OBSERVER_COOKIE_PREFIX} from '@canvas/observer-picker/ObserverGetObservee'

describe('getFirstPageUrl', () => {
  beforeEach(() => {
    // @ts-expect-error
    window.ENV = {}
  })

  it('returns the default url when the user is not an observer', () => {
    // @ts-expect-error
    window.ENV = {
      current_user_roles: ['student'],
      current_user_id: '1',
    }
    expect(getFirstPageUrl()).toEqual(
      '/api/v1/users/self/favorites/courses?include[]=term&exclude[]=enrollments&sort=nickname'
    )
  })

  it('returns the default url with the observed_user_id query param', () => {
    // @ts-expect-error
    window.ENV = {
      current_user_roles: ['user', 'observer'],
      current_user_id: '1',
    }
    document.cookie = `${OBSERVER_COOKIE_PREFIX}${ENV.current_user_id}=17`
    expect(getFirstPageUrl()).toEqual(
      '/api/v1/users/self/favorites/courses?include[]=term&exclude[]=enrollments&sort=nickname&observed_user_id=17'
    )
  })

  it('observed_user_id changes when observee changes', () => {
    // @ts-expect-error
    window.ENV = {
      current_user_roles: ['user', 'observer'],
      current_user_id: '1',
    }
    document.cookie = `${OBSERVER_COOKIE_PREFIX}${ENV.current_user_id}=17`
    expect(getFirstPageUrl()).toEqual(
      '/api/v1/users/self/favorites/courses?include[]=term&exclude[]=enrollments&sort=nickname&observed_user_id=17'
    )

    document.cookie = `${OBSERVER_COOKIE_PREFIX}${ENV.current_user_id}=27`
    expect(getFirstPageUrl()).toEqual(
      '/api/v1/users/self/favorites/courses?include[]=term&exclude[]=enrollments&sort=nickname&observed_user_id=27'
    )
  })
})

describe('hideHomeroomCourseIfK5Student', () => {
  it('returns true when the user is not a K5 student', () => {
    // @ts-expect-error
    window.ENV = {
      K5_USER: false,
      current_user_roles: ['student'],
    }
    expect(hideHomeroomCourseIfK5Student({homeroom_course: true})).toEqual(true)
  })

  it('returns true when the user is a K5 student but the course is not a homeroom course', () => {
    // @ts-expect-error
    window.ENV = {
      K5_USER: true,
      current_user_roles: ['student'],
    }
    expect(hideHomeroomCourseIfK5Student({homeroom_course: false})).toEqual(true)
  })

  it('returns false when the user is a K5 student and the course is a homeroom course', () => {
    // @ts-expect-error
    window.ENV = {
      K5_USER: true,
      current_user_roles: ['student'],
    }
    expect(hideHomeroomCourseIfK5Student({homeroom_course: true})).toEqual(false)
  })
})
