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
import I18n from 'i18n!TourPoints'
import {Link} from '@instructure/ui-link'
import {Text} from '@instructure/ui-text'
import {Heading} from '@instructure/ui-heading'
import {ScreenReaderContent} from '@instructure/ui-a11y'
import handleOpenTray from '../handleOpenTray'

export default [
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
            name: window.ENV?.current_user?.display_name
              ? `, ${window.ENV?.current_user?.display_name}`
              : ''
          })}
        </Heading>
        <p>
          {I18n.t(
            "We know it's a priority to transition your institution for online learning during this time. This quick tour will show you how to:"
          )}
        </p>
        <ol>
          <li>{I18n.t('Add People and Courses to Canvas')}</li>
          <li>{I18n.t('Quickly share Course Content and Templates with Teachers')}</li>
          <li>{I18n.t('Set up Video Conferencing and Other Tools')}</li>
          <li>{I18n.t('Find Training Resources and More Help')}</li>
        </ol>
        <div className="tour-star-image" aria-hidden>
          <img src={require('../../confetti/svg/Star.svg')} alt={I18n.t('star')} />
        </div>
      </section>
    )
  },
  {
    selector: '.navigation-tray-container',
    content: (
      <section>
        <Heading level="h3">{I18n.t('Add People and Courses to Canvas')}</Heading>
        <ScreenReaderContent>
          {I18n.t('Click on the admin navigation button to access account settings.')}
        </ScreenReaderContent>
        <Text as="p">
          <Link
            as="a"
            href="https://community.canvaslms.com/docs/DOC-10766-421455347"
            target="_blank"
            rel="noopener noreferrer"
          >
            {I18n.t('To add individual courses, click Courses.')}
          </Link>
        </Text>
        <Text as="p">
          <Link
            as="a"
            href="https://community.canvaslms.com/docs/DOC-12632-421473704"
            target="_blank"
            rel="noopener noreferrer"
          >
            {I18n.t('To add individual users, click People.')}
          </Link>
        </Text>
        <Text as="p">
          <Link
            as="a"
            href="https://community.canvaslms.com/docs/DOC-10840-4214527607"
            target="_blank"
            rel="noopener noreferrer"
          >
            {I18n.t('To add bulk users, courses, and enrollments, click SIS Imports.')}
          </Link>
        </Text>
      </section>
    ),
    actionBefore: async () => {
      await handleOpenTray('accounts')
    }
  },
  {
    selector: '.navigation-tray-container',
    content: (
      <section>
        <Heading level="h3">
          {I18n.t('Quickly Share Course Content and Templates with Teachers')}
        </Heading>
        <Text as="p">
          <Link
            as="a"
            href="https://community.canvaslms.com/docs/DOC-16697-blueprint-courses-and-canvas-commons-comparison-pdf"
            target="_blank"
            rel="noopener noreferrer"
          >
            {I18n.t('Learn more about using Commons and Blueprints.')}
          </Link>
        </Text>
      </section>
    ),
    actionBefore: async () => {
      await handleOpenTray('accounts')
    }
  },
  {
    selector: '.navigation-tray-container',
    content: (
      <section>
        <Heading level="h3">{I18n.t('Set up Video Conferencing')}</Heading>
        <Text as="p">
          <Link
            as="a"
            href="https://community.canvaslms.com/docs/DOC-18572-conferences-resources"
            target="_blank"
            rel="noopener noreferrer"
          >
            {I18n.t(
              'Video conferencing tools enable face-to-face connection between teachers and students.'
            )}
          </Link>
        </Text>
      </section>
    ),
    actionBefore: async () => {
      await handleOpenTray('accounts')
    }
  },
  {
    selector: '.navigation-tray-container',
    content: (
      <section>
        <Heading level="h3">{I18n.t('Find Training Resources and More Help')}</Heading>
        <Text as="p">
          <Link
            as="a"
            href="https://community.canvaslms.com/docs/DOC-17985-how-do-i-use-the-training-services-portal-as-an-admin"
            target="_blank"
            rel="noopener noreferrer"
          >
            {I18n.t('Access Canvas training videos and courses')}
          </Link>
        </Text>
      </section>
    ),
    actionBefore: async () => {
      await handleOpenTray('help')
    }
  }
]
