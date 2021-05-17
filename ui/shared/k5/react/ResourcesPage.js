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
import React, {useState} from 'react'
import PropTypes from 'prop-types'

import {ApplyTheme} from '@instructure/ui-themeable'

import StaffContactInfoLayout from './StaffContactInfoLayout'
import useImmediate from '@canvas/use-immediate-hook'
import {fetchCourseInstructors, fetchCourseApps, fetchImportantInfos} from './utils'
import AppsList from './AppsList'
import {showFlashError} from '@canvas/alerts/react/FlashAlert'
import ImportantInfoLayout from './ImportantInfoLayout'
import {resourcesTheme} from './k5-theme'

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

export default function ResourcesPage({
  cards,
  cardsSettled,
  visible,
  showStaff,
  filterToHomerooms
}) {
  const [infos, setInfos] = useState([])
  const [apps, setApps] = useState([])
  const [staff, setStaff] = useState([])
  const [staffAuthorized, setStaffAuthorized] = useState(true)
  const [isInfoLoading, setInfoLoading] = useState(false)
  const [isAppsLoading, setAppsLoading] = useState(false)
  const [isStaffLoading, setStaffLoading] = useState(false)

  useImmediate(
    () => {
      if (cards && cardsSettled) {
        setInfoLoading(true)
        fetchImportantInfos(filterToHomerooms ? cards.filter(c => c.isHomeroom) : cards)
          .then(setInfos)
          .catch(showFlashError(I18n.t('Failed to load important info.')))
          .finally(() => setInfoLoading(false))
        setAppsLoading(true)
        fetchApps(cards)
          .then(setApps)
          .catch(showFlashError(I18n.t('Failed to load apps.')))
          .finally(() => setAppsLoading(false))
        if (showStaff) {
          setStaffLoading(true)
          fetchStaff(cards)
            .then(setStaff)
            .catch(err => {
              if (err?.response?.status === 401) {
                return setStaffAuthorized(false)
              }
              showFlashError(I18n.t('Failed to load staff.'))(err)
            })
            .finally(() => setStaffLoading(false))
        }
      }
    },
    [cards, cardsSettled],
    {deep: true}
  )

  return (
    <ApplyTheme theme={resourcesTheme}>
      <section style={{display: visible ? 'block' : 'none'}} aria-hidden={!visible}>
        <ImportantInfoLayout isLoading={isInfoLoading} importantInfos={infos} />
        <AppsList isLoading={isAppsLoading} apps={apps} />
        {showStaff && staffAuthorized && (
          <StaffContactInfoLayout isLoading={isStaffLoading} staff={staff} />
        )}
      </section>
    </ApplyTheme>
  )
}

ResourcesPage.propTypes = {
  cards: PropTypes.array.isRequired,
  cardsSettled: PropTypes.bool.isRequired,
  visible: PropTypes.bool.isRequired,
  showStaff: PropTypes.bool.isRequired,
  filterToHomerooms: PropTypes.bool.isRequired
}
