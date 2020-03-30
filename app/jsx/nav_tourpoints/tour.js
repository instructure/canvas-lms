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
import Reactour from '@instructure/reactour/dist/reactour.cjs'
import I18n from 'i18n!TourPoints'
import {Link} from '@instructure/ui-link'
import tourPubSub from './tourPubsub'
import TourContainer from './TourContainer'
import {Heading} from '@instructure/ui-heading'
import {ScreenReaderContent} from '@instructure/ui-a11y'
import useLocalStorage from '../shared/hooks/useLocalStorage'

async function handleOpenTray(trayType) {
  tourPubSub.publish('navigation-tray-open', {type: trayType, noFocus: true})
  await new Promise(resolve => {
    let resolved = false
    let timeout
    const unsubscribe = tourPubSub.subscribe('navigation-tray-opened', type => {
      if (resolved) return
      if (type === trayType) {
        // For A11y, we need to do some DOM shenanigans so the Tour portal
        // has screen reader focus and not the greedy nav trays.
        // The Nav Tray will automatically remove this attribute when it opens
        // when the tour is done.
        const navElement = document.getElementById('nav-tray-portal')
        if (navElement) {
          navElement.setAttribute('aria-hidden', true)
        }
        const tourElement = document.getElementById('___reactour')
        if (tourElement) {
          tourElement.setAttribute('aria-hidden', false)
        }
        clearTimeout(timeout)
        unsubscribe()
        resolve()
      }
    })
    // 5 second timeout just in case it never resolves
    timeout = setTimeout(() => {
      resolved = true
      unsubscribe()
      resolve()
    }, 5000)
  })
}

const allSteps = {
  teacher: [
    {
      selector: '#global_nav_help_link',
      content: () => (
        <section>
          {/* Hide the overlay on the first step. */}
          <style>
            {`#___reactour svg rect {
              opacity:0;
            }`}
          </style>
          <Heading level="h3">
            {I18n.t(`Hello%{name}!`, {
              name:
                window.ENV.current_user && window.ENV.current_user.display_name
                  ? ` ${window.ENV.current_user.display_name}`
                  : ''
            })}
          </Heading>
          <p>
            {I18n.t(
              'We know getting your courses online quickly during this time is priority. This quick tour will show you how to:'
            )}
          </p>
          <ol>
            <li>
              <Link
                as="a"
                href="https://community.canvaslms.com/docs/DOC-13111-4152719738"
                target="_blank"
                rel="noopener noreferrer"
              >
                {I18n.t('Set up your Notifications')}
              </Link>
            </li>
            <li>
              <Link
                as="a"
                href="https://community.canvaslms.com/docs/DOC-18584-set-up-your-canvas-course-in-30-minutes-or-less"
                target="_blank"
                rel="noopener noreferrer"
              >
                {I18n.t('Get your Content online')}
              </Link>
            </li>
            <li>{I18n.t('Access Canvas Resources and Guides')}</li>
          </ol>
          <div className="tour-star-image" aria-hidden>
            <img src={require('../confetti/svg/Star.svg')} alt="star" />
          </div>
        </section>
      )
    },
    {
      observe: '.profile-tab-notifications',
      selector: '.profile-tab-notifications',
      content: (
        <section>
          <Heading level="h3">{I18n.t('Set Up Your Notifications')}</Heading>
          <ScreenReaderContent>
            {I18n.t('Click on the account navigation button to access notification preferences.')}
          </ScreenReaderContent>
          <Link
            as="a"
            href="https://community.canvaslms.com/docs/DOC-13111-4152719738"
            target="_blank"
            rel="noopener noreferrer"
          >
            {I18n.t("Don't miss notifications from your students.")}
          </Link>
          <iframe
            title="Canvas Notifications Tutorial Video"
            src="https://player.vimeo.com/video/75514816?title=0&byline=0&portrait=0"
            width="100%"
            height="277px"
            style={{marginTop: '1rem'}}
            frameBorder="0"
            allow="autoplay; fullscreen"
            allowFullScreen
          />
        </section>
      ),
      actionBefore: async () => {
        await handleOpenTray('profile')
      }
    },
    {
      selector: '.navigation-tray-container',
      content: (
        <section>
          <Heading level="h3">{I18n.t('Get Your Content Online Quickly')}</Heading>
          <ScreenReaderContent>
            {I18n.t('Click on the courses navigation button to access your courses.')}
          </ScreenReaderContent>
          <Link
            as="a"
            href="https://community.canvaslms.com/docs/DOC-18584-set-up-your-canvas-course-in-30-minutes-or-less"
            target="_blank"
            rel="noopener noreferrer"
          >
            {I18n.t('Set up your Canvas course in 30 minutes or less.')}
          </Link>
          <iframe
            title="Canvas Course Tutorial Video"
            src="https://player.vimeo.com/video/69658934?title=0&byline=0&portrait=0"
            width="100%"
            height="277px"
            style={{marginTop: '1rem'}}
            frameBorder="0"
            allow="autoplay; fullscreen"
            allowFullScreen
          />
        </section>
      ),
      actionBefore: async () => {
        await handleOpenTray('courses')
      }
    },
    {
      selector: '.navigation-tray-container',
      content: (
        <section>
          <Heading level="h3">{I18n.t('Access Canvas Resources and Guides')}</Heading>
          {I18n.t('Visit the Help section any time for new tips and guides.')}
        </section>
      ),
      actionBefore: async () => {
        await handleOpenTray('help')
      }
    }
  ],
  student: [
    {
      selector: '#global_nav_help_link',
      content: () => (
        <section>
          {/* Hide the overlay on the first step. */}
          <style>
            {`#___reactour svg rect {
              opacity:0;
            }`}
          </style>
          <Heading level="h3">
            {I18n.t(`Hello%{name}!`, {
              name:
                window.ENV.current_user && window.ENV.current_user.display_name
                  ? ` ${window.ENV.current_user.display_name}`
                  : ''
            })}
          </Heading>
          <p>{I18n.t("Here's some quick tips to get you started in Canvas!")}</p>
          <ol>
            <li>{I18n.t('How do I find my courses?')}</li>
            <li>{I18n.t('How do I contact my instructor?')}</li>
            <li>{I18n.t('How do I download the Student App?')}</li>
          </ol>
          <div className="tour-star-image" aria-hidden>
            <img src={require('../confetti/svg/Star.svg')} alt="star" />
          </div>
        </section>
      )
    },
    {
      selector: '#global_nav_dashboard_link',
      content: (
        <section>
          <Heading level="h3">{I18n.t('How do I find my courses?')}</Heading>
          {I18n.t('Find your classes or subjects in the Dashboard...')}
        </section>
      )
    },
    {
      selector: '.navigation-tray-container',
      content: (
        <section>
          <Heading level="h3">{I18n.t('How do I find my courses?')}</Heading>
          {I18n.t('...or in the Courses list.')}
        </section>
      ),
      actionBefore: async () => {
        await handleOpenTray('courses')
      }
    },
    {
      selector: '#global_nav_conversations_link',
      content: (
        <section>
          <Heading level="h3">{I18n.t('How do I contact my instructor?')}</Heading>
          {I18n.t('Start a conversation with your instructor in the Canvas Inbox.')}
        </section>
      )
    },
    {
      selector: '.navigation-tray-container',
      content: (
        <section>
          <Heading level="h3">
            {I18n.t('How do I download the Student App and get additional help?')}
          </Heading>
          {I18n.t(
            'Access your courses and groups using any iOS or Android mobile device and find more information in the Help menu.'
          )}
        </section>
      ),
      actionBefore: async () => {
        await handleOpenTray('help')
      }
    }
  ]
}

const softCloseSteps = [
  {
    selector: '.welcome-tour-link',
    content: (
      <section>
        <Heading level="h3">{I18n.t('Come back later!')}</Heading>
        {I18n.t('You can access the Welcome Tour here any time as well as other new resources.')}
      </section>
    )
  }
]

const Tour = ({roles}) => {
  const [currentRole, setCurrentRole] = React.useState(() => {
    if (
      window.ENV?.COURSE?.is_student &&
      roles.includes('student') &&
      !localStorage.getItem(`canvas-tourpoints-shown-student`)
    ) {
      // The current page is for a course that the user is a student is in.
      // And they haven't seen the tour yet. Change roles to student.
      return 'student'
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
          tourElement.setAttribute('aria-hidden', false)
        }
      }
    },
    [setHasOpened, softClose]
  )

  React.useEffect(() => {
    const escapeClose = e => {
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
      navElement.setAttribute('aria-hidden', false)
    }
    const appElement = document.getElementById('application')
    if (appElement) {
      appElement.setAttribute('aria-hidden', false)
    }
  }

  const blockApplicationScreenReader = () => {
    const navElement = document.getElementById('nav-tray-portal')
    if (navElement) {
      navElement.setAttribute('aria-hidden', true)
    }
    const appElement = document.getElementById('application')
    if (appElement) {
      appElement.setAttribute('aria-hidden', true)
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
      if (window.ENV?.COURSE?.is_student && roles.includes('student')) {
        setCurrentRole('student')
      } else if (roles.includes('teacher')) {
        setCurrentRole('teacher')
      }
    })
    return () => unsub()
  }, [roles])

  if (!currentRole || !steps) return null

  return (
    <Reactour
      key={`${softClose}-${open}-${currentRole}`}
      CustomHelper={props => (
        <TourContainer
          softClose={handleSoftClose}
          close={() => {
            tourPubSub.publish('navigation-tray-close')
            restoreTrayScreenReader()
            props.close()
          }}
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
