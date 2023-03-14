/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

export const reduceDuplicateCourses = (enrollments, favoriteCourses) => {
  if (!enrollments || !favoriteCourses) {
    return []
  }
  const coursesWithoutFavorites = enrollments
    .map(c => {
      return {
        id: c.course._id,
        contextName: c.course.contextName,
        assetString: c.course.assetString,
        concluded: c.concluded,
      }
    })
    .filter(c => {
      let isMatch
      for (let i = 0; i < favoriteCourses.length; i++) {
        isMatch = favoriteCourses[i].assetString === c.assetString
        if (isMatch === true) {
          break
        }
      }
      return !isMatch
    })

  const uniqCourses = {}
  coursesWithoutFavorites.forEach(course => {
    if (!(course.assetString in uniqCourses)) {
      uniqCourses[course.assetString] = course
    } else {
      // This logic is to make sure course concluded is always false if there is at least one active enrollment in a course
      uniqCourses[course.assetString].concluded =
        course.concluded && uniqCourses[course.assetString].concluded
    }
  })

  return Object.keys(uniqCourses).map(assetString => uniqCourses[assetString])
}
