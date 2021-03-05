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

import React, {useState, useEffect} from 'react'
import PropTypes from 'prop-types'
import StaffContactInfoLayout from 'jsx/dashboard/layout/StaffContactInfoLayout'
import {fetchCourseInstructors} from 'jsx/dashboard/utils'

const fetchStaff = cards => {
  return Promise.all(
    cards.filter(c => c.isHomeroom).map(course => fetchCourseInstructors(course.id))
  )
    .then(instructors => instructors.flat(1))
    .then(instructors =>
      instructors.reduce((acc, instructor) => {
        if (!acc.find(({id}) => id === instructor.id)) {
          acc.push({
            id: instructor.id,
            name: instructor.short_name,
            bio: instructor.bio,
            email: instructor.email,
            avatarUrl: instructor.avatar_url || undefined,
            role: instructor.enrollments[0].role
          })
        }
        return acc
      }, [])
    )
}

export default function ResourcesPage({cards, visible = false}) {
  const [staff, setStaff] = useState([])

  useEffect(() => {
    fetchStaff(cards).then(setStaff)
    // Cards are only ever loaded once on the page, so this only runs on mount
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [])

  return (
    <section style={{display: visible ? 'block' : 'none'}} aria-hidden={!visible}>
      <StaffContactInfoLayout staff={staff} />
    </section>
  )
}

ResourcesPage.propTypes = {
  cards: PropTypes.array.isRequired,
  visible: PropTypes.bool
}
