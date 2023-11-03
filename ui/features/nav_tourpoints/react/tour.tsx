/*
 * Copyright (C) 2020 - present Instructure, Inc.
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

import React from 'react'
// @ts-expect-error
import Reactour from '@instructure/reactour/dist/reactour.cjs'
import {useScope as useI18nScope} from '@canvas/i18n'
import tourPubSub from '@canvas/tour-pubsub'
import TourContainer from './TourContainer'
import {Heading} from '@instructure/ui-heading'
import useLocalStorage from './hooks/useLocalStorage'
import adminTour from './tours/adminTour'
import teacherTour from './tours/teacherTour'
import studentTour from './tours/studentTour'
import handleOpenTray from './handleOpenTray'

const I18n = useI18nScope('TourPoints')

export type Role = 'student' | 'teacher' | 'admin'

interface ITour {
  roles: Role[]
}

const allSteps = {
  admin: adminTour,
  teacher: teacherTour,
  student: studentTour,
}

const softCloseSteps = [
  {
    selector: '.welcome-tour-link',
    content: (
      <section>
        <Heading level="h3">{I18n.t('Come back later!')}</Heading>
        {I18n.t('You can access the Welcome Tour here any time as well as other new resources.')}
      </section>
    ),
  },
]

const Tour = ({roles}: ITour) => {
  const [currentRole, setCurrentRole] = React.useState<Role>(() => {
    if (
      window.ENV?.COURSE?.is_student &&
      roles.includes('student') &&
      !localStorage.getItem(`canvas-tourpoints-shown-student`)
    ) {
      // The current page is for a course that the user is a student is in.
      // And they haven't seen the tour yet. Change roles to student.
      return 'student'
    }
    if (
      window.ENV?.COURSE?.is_instructor &&
      roles.includes('teacher') &&
      !localStorage.getItem(`canvas-tourpoints-shown-teacher`)
    ) {
      // Same for teacher
      return 'teacher'
    }
    return roles[0]
  })
  const steps = allSteps[currentRole]

  // TODO: Someday, it would be great if this were stored
  // in user data as a user setting.
  const [hasOpened, setHasOpened] = useLocalStorage(`canvas-tourpoints-shown-${currentRole}`, false)
  const [open, setOpen] = React.useState(!hasOpened)
  const [reopened, setReopened] = React.useState(false)
  const [softClose, setSoftClose] = React.useState(false)

  React.useEffect(() => {
    // Override the tray dismiss function while this
    // tour is open;
    if (open) {
      tourPubSub.publish('navigation-tray-override-dismiss', true)
    }
    return () => tourPubSub.publish('navigation-tray-override-dismiss', false)
  }, [open])

  const handleSoftClose = React.useCallback(
    async (options = {}) => {
      const {forceClose} = options
      setHasOpened(true)
      if (softClose || forceClose) {
        restoreTrayScreenReader()
        tourPubSub.publish('navigation-tray-close')
        setOpen(false)
      } else {
        // As part of the soft close, open the help tray
        await handleOpenTray('help')

        setSoftClose(true)
        const tourElement = document.getElementById('___reactour')
        if (tourElement) {
          tourElement.setAttribute('aria-hidden', 'false')
        }
      }
    },
    [setHasOpened, softClose]
  )

  React.useEffect(() => {
    const escapeClose = (e: any) => {
      if (e.keyCode === 27) {
        // Escape Key
        handleSoftClose()
      }
    }
    document.addEventListener('keydown', escapeClose)
    return () => document.removeEventListener('keydown', escapeClose)
  }, [handleSoftClose])

  const restoreTrayScreenReader = () => {
    // Restore the nav tray's screen reader visibility
    const navElement = document.getElementById('nav-tray-portal')
    if (navElement) {
      navElement.setAttribute('aria-hidden', 'false')
    }
    const appElement = document.getElementById('application')
    if (appElement) {
      appElement.setAttribute('aria-hidden', 'false')
    }
  }

  const blockApplicationScreenReader = () => {
    const navElement = document.getElementById('nav-tray-portal')
    if (navElement) {
      navElement.setAttribute('aria-hidden', 'true')
    }
    const appElement = document.getElementById('application')
    if (appElement) {
      appElement.setAttribute('aria-hidden', 'true')
    }
  }

  React.useEffect(() => {
    if (open) {
      blockApplicationScreenReader()
    }
    return () => restoreTrayScreenReader()
  }, [open])

  React.useEffect(() => {
    const unsub = tourPubSub.subscribe('tour-open', () => {
      tourPubSub.publish('navigation-tray-close')
      blockApplicationScreenReader()
      setOpen(true)
      setReopened(true)
      setSoftClose(true)

      // If we are on a course the user is a student in, show the student tour
      if (roles.length === 1) {
        setCurrentRole(roles[0])
      }
      // If user is a student, only show on courses page
      // that student is enrolled in.
      else if (window.ENV?.COURSE?.is_student && roles.includes('student')) {
        setCurrentRole('student')
      }
      // If that user is a teacher and not an admin,
      // just show the tour
      else if (roles.includes('teacher') && !roles.includes('admin')) {
        setCurrentRole('teacher')
      }
      // If that user is a teacher and an admin, only show on
      // courses page which the teacher is instructor in
      else if (
        window.ENV?.COURSE?.is_instructor &&
        roles.includes('teacher') &&
        roles.includes('admin')
      ) {
        setCurrentRole('teacher')
      }
      // If that user is an admin, show the admin tour
      else if (roles.includes('admin')) {
        setCurrentRole('admin')
      }
    })
    return () => unsub()
  }, [roles])

  if (!currentRole || !steps) return null

  const firstStepLabels = {
    student: I18n.t('Student Tour'),
    teacher: I18n.t('Teacher Tour'),
    admin: I18n.t('Admin Tour'),
  }
  if (!open) return null
  return (
    <Reactour
      key={`${softClose}-${open}-${currentRole}`}
      CustomHelper={(props: any) => (
        <TourContainer
          softClose={handleSoftClose}
          close={() => {
            tourPubSub.publish('navigation-tray-close')
            restoreTrayScreenReader()
            props.close()
          }}
          firstLabel={firstStepLabels[currentRole] || ''}
          {...props}
        />
      )}
      steps={!reopened && softClose ? softCloseSteps : steps}
      isOpen={open}
      onRequestClose={handleSoftClose}
    />
  )
}

export default Tour
