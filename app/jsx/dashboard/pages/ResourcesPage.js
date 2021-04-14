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

import I18n from 'i18n!dashboard_pages_ResourcesPage'
import React, {useState, useEffect} from 'react'
import PropTypes from 'prop-types'
import StaffContactInfoLayout from 'jsx/dashboard/layout/StaffContactInfoLayout'
import {fetchCourseInstructors, fetchCourseApps} from 'jsx/dashboard/utils'
import AppsList from 'jsx/dashboard/pages/AppsList'
import {showFlashError} from 'jsx/shared/FlashAlert'

const fetchStaff = cards =>
  Promise.all(cards.filter(c => c.isHomeroom).map(course => fetchCourseInstructors(course.id)))
    .then(instructors => instructors.flat(1))
    .then(instructors =>
      instructors.reduce((acc, instructor) => {
        if (!acc.find(({id}) => id === instructor.id)) {
          acc.push({
            id: instructor.id,
            name: instructor.short_name,
            bio: instructor.bio,
            avatarUrl: instructor.avatar_url || undefined,
            role: instructor.enrollments[0].role
          })
        }
        return acc
      }, [])
    )

const fetchApps = cards =>
  Promise.all(
    cards
      .filter(c => !c.isHomeroom)
      .map(course =>
        // reduce the results of each promise separately so we can include the course id
        // and course title, which are not returned by the api call
        fetchCourseApps(course.id).then(apps =>
          apps.map(app => ({
            id: app.id,
            courses: [{id: course.id, name: course.originalName}],
            title: app.course_navigation.text || app.name,
            icon: app.course_navigation.icon_url || app.icon_url
          }))
        )
      )
  )
    // combine each course's array of apps into a single array of all the apps
    .then(apps => apps.flat(1))
    // combine duplicate apps, but remember which course each is associated with
    .then(apps =>
      apps.reduce((acc, app) => {
        const i = acc.findIndex(({id}) => id === app.id)
        i === -1 ? acc.push(app) : acc[i].courses.push(app.courses[0])
        return acc
      }, [])
    )

export default function ResourcesPage({cards, visible = false}) {
  const [apps, setApps] = useState([])
  const [staff, setStaff] = useState([])
  const [isAppsLoading, setAppsLoading] = useState(false)
  const [isStaffLoading, setStaffLoading] = useState(false)

  useEffect(() => {
    setAppsLoading(true)
    fetchApps(cards)
      .then(data => {
        setApps(data)
        setAppsLoading(false)
      })
      .catch(err => {
        setAppsLoading(false)
        showFlashError(I18n.t('Failed to load apps.'))(err)
      })

    setStaffLoading(true)
    fetchStaff(cards)
      .then(data => {
        setStaff(data)
        setStaffLoading(false)
      })
      .catch(err => {
        setStaffLoading(false)
        showFlashError(I18n.t('Failed to load staff.'))(err)
      })

    // Cards are only ever loaded once on the page, so this only runs on mount
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [])

  return (
    <section style={{display: visible ? 'block' : 'none'}} aria-hidden={!visible}>
      <AppsList isLoading={isAppsLoading} apps={apps} />
      <StaffContactInfoLayout isLoading={isStaffLoading} staff={staff} />
    </section>
  )
}

ResourcesPage.propTypes = {
  cards: PropTypes.array.isRequired,
  visible: PropTypes.bool
}
