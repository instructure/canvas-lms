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

import {useScope as useI18nScope} from '@canvas/i18n'
import React, {useState} from 'react'
import PropTypes from 'prop-types'

import {InstUISettingsProvider} from '@instructure/emotion'

import StaffContactInfoLayout from './StaffContactInfoLayout'
import useImmediate from '@canvas/use-immediate-hook'
import {fetchCourseInstructors, fetchCourseApps, fetchImportantInfos} from './utils'
import AppsList from './AppsList'
import {showFlashError} from '@canvas/alerts/react/FlashAlert'
import ImportantInfoLayout from './ImportantInfoLayout'
import {getResourcesTheme} from './k5-theme'

const resourcesTheme = getResourcesTheme()

const I18n = useI18nScope('resources_page')

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
            role: instructor.enrollments[0].role,
          })
        }
        return acc
      }, [])
    )

const fetchApps = cards => {
  const courseIds = cards.filter(c => !c.isHomeroom).map(c => c.id)
  if (!courseIds.length) return Promise.resolve([])
  return fetchCourseApps(courseIds).then(apps =>
    // Combine LTIs into a unique set each containing a list of
    // the courses with which they are associated
    apps.reduce((acc, app) => {
      const course = {id: app.context_id, name: app.context_name}
      const existing = acc.find(({id}) => id === app.id)
      if (existing) {
        existing.courses.push(course)
      } else {
        acc.push({
          id: app.id,
          courses: [course],
          title: app.course_navigation?.text || app.name,
          icon: app.course_navigation?.icon_url || app.icon_url,
          windowTarget: app.course_navigation?.windowTarget,
        })
      }
      return acc
    }, [])
  )
}

export default function ResourcesPage({cards, cardsSettled, visible, showStaff, isSingleCourse}) {
  const [infos, setInfos] = useState([])
  const [apps, setApps] = useState([])
  const [staff, setStaff] = useState([])
  const [staffAuthorized, setStaffAuthorized] = useState(true)
  const [isInfoLoading, setInfoLoading] = useState(true)
  const [isAppsLoading, setAppsLoading] = useState(true)
  const [isStaffLoading, setStaffLoading] = useState(true)
  const [alreadyLoaded, setAlreadyLoaded] = useState(false)
  const homerooms = cards.filter(c => c.isHomeroom)

  useImmediate(
    () => {
      if (cards && cardsSettled && visible && !alreadyLoaded) {
        setInfoLoading(true)
        fetchImportantInfos(!isSingleCourse ? cards.filter(c => c.isHomeroom) : cards)
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
        setAlreadyLoaded(true)
      }
    },
    [cards, cardsSettled, visible],
    {deep: true}
  )

  return (
    <InstUISettingsProvider theme={{componentOverrides: resourcesTheme}}>
      <section style={{display: visible ? 'block' : 'none'}} aria-hidden={!visible}>
        {(isSingleCourse || homerooms?.length > 0) && (
          <ImportantInfoLayout
            isLoading={isInfoLoading}
            importantInfos={infos}
            courseId={isSingleCourse ? cards[0]?.id : null}
          />
        )}
        <AppsList
          isLoading={isAppsLoading}
          apps={apps}
          courseId={isSingleCourse ? cards[0]?.id : null}
        />
        {(isSingleCourse || homerooms?.length > 0) && showStaff && staffAuthorized && (
          <StaffContactInfoLayout isLoading={isStaffLoading} staff={staff} />
        )}
      </section>
    </InstUISettingsProvider>
  )
}

ResourcesPage.propTypes = {
  cards: PropTypes.array.isRequired,
  cardsSettled: PropTypes.bool.isRequired,
  visible: PropTypes.bool.isRequired,
  showStaff: PropTypes.bool.isRequired,
  isSingleCourse: PropTypes.bool.isRequired,
}
