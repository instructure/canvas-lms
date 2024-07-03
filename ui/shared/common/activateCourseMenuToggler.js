/*
 * Copyright (C) 2022 - present Instructure, Inc.
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

// show and hide the courses vertical menu when the user clicks the hamburger
// button This now lives in the courses package for usage elsewhere, but it
// sometimes needs to work in places that don't load the courses bundle.

import {initialize} from '@canvas/courses/jquery/toggleCourseNav'
import ready from '@instructure/ready'

export function up() {
  return new Promise((resolve, reject) => {
    ready(() => {
      try {
        initialize()
        resolve()
      } catch (e) {
        reject(e)
      }
    })
  })
}
