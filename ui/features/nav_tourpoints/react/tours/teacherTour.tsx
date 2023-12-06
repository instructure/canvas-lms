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
import {useScope as useI18nScope} from '@canvas/i18n'
import {Link} from '@instructure/ui-link'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
import {Heading} from '@instructure/ui-heading'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import handleOpenTray from '../handleOpenTray'
import assetFactory from '@canvas/confetti/javascript/assetFactory'

const I18n = useI18nScope('TourPoints')

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
              : '',
          })}
        </Heading>
        <Text as="p">
          {I18n.t(
            'We know getting your courses online quickly during this time is priority. This quick tour will show you how to:'
          )}
        </Text>
        <ol>
          <li>
            <Link
              as="a"
              href={I18n.t('#community.instructor_notification_preferences')}
              target="_blank"
              rel="noopener noreferrer"
            >
              {I18n.t('Set up your Notifications')}
            </Link>
          </li>
          <li>
            <Link
              as="a"
              href={I18n.t('#community.contingency_30_minute_quickstart')}
              target="_blank"
              rel="noopener noreferrer"
            >
              {I18n.t('Get your Content online')}
            </Link>
          </li>
          <li>
            <Link
              as="a"
              href={I18n.t('#community.instructor_create_conference')}
              target="_blank"
              rel="noopener noreferrer"
            >
              {I18n.t('Learn more about Video Conferencing')}
            </Link>
            <ul>
              <li>
                <Link
                  as="a"
                  href={I18n.t('#community.admin_zoom_meetings_faq')}
                  target="_blank"
                  rel="noopener noreferrer"
                >
                  Zoom
                </Link>
              </li>
              <li>
                <Link
                  as="a"
                  href={I18n.t('#community.admin_hangouts_meet_lti')}
                  target="_blank"
                  rel="noopener noreferrer"
                >
                  Google Meet
                </Link>
              </li>
              <li>
                <Link
                  as="a"
                  href="https://www.youtube.com/watch?v=zUXXeiRCFfY"
                  target="_blank"
                  rel="noopener noreferrer"
                >
                  Microsoft Teams
                </Link>
              </li>
            </ul>
          </li>
        </ol>
        <div className="tour-star-image" aria-hidden={true}>
          <img src={assetFactory('star')} alt={I18n.t('star')} />
        </div>
      </section>
    ),
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
        <Text as="p">
          <Link
            as="a"
            href={I18n.t('#community.instructor_notification_preferences')}
            target="_blank"
            rel="noopener noreferrer"
          >
            {I18n.t("Don't miss notifications from your students.")}
          </Link>
        </Text>
        <iframe
          title={I18n.t('Canvas Notifications Tutorial Video')}
          src="https://community.instructuremedia.com/embed/b515f6d4-40f9-4f14-8051-7ef8b144c9d6"
          width="100%"
          height="277px"
          style={{marginTop: '1rem'}}
          frameBorder="0"
          allow="autoplay; fullscreen"
          allowFullScreen={true}
        />
      </section>
    ),
    actionBefore: async () => {
      await handleOpenTray('profile')
    },
  },
  {
    selector: '.navigation-tray-container',
    content: (
      <section>
        <Heading level="h3">{I18n.t('Get Your Content Online Quickly')}</Heading>
        <ScreenReaderContent>
          {I18n.t('Click on the courses navigation button to access your courses.')}
        </ScreenReaderContent>
        <Text as="p">
          <Link
            as="a"
            href={I18n.t('#community.contingency_30_minute_quickstart')}
            target="_blank"
            rel="noopener noreferrer"
          >
            {I18n.t('Set up your Canvas course in 30 minutes or less.')}
          </Link>
        </Text>
        <iframe
          title={I18n.t('Canvas Course Tutorial Video')}
          src="https://community.instructuremedia.com/embed/bb5eeffe-2c18-4d91-a3be-0845f1ca1890"
          width="100%"
          height="277px"
          style={{marginTop: '1rem'}}
          frameBorder="0"
          allow="autoplay; fullscreen"
          allowFullScreen={true}
        />
      </section>
    ),
    actionBefore: async () => {
      await handleOpenTray('courses')
    },
  },
  {
    selector: '.navigation-tray-container',
    content: (
      <section>
        <Heading level="h3">{I18n.t('Learn more about Video Conferencing')}</Heading>
        <View as="div" margin="small 0 0 0">
          <ul>
            <li>
              <Link
                as="a"
                href={I18n.t('#community.admin_zoom_meetings_faq')}
                target="_blank"
                rel="noopener noreferrer"
              >
                Zoom
              </Link>
            </li>
            <li>
              <Link
                as="a"
                href={I18n.t('#community.admin_hangouts_meet_lti')}
                target="_blank"
                rel="noopener noreferrer"
              >
                Google Meet
              </Link>
            </li>
            <li>
              <Link
                as="a"
                href="https://www.youtube.com/watch?v=zUXXeiRCFfY"
                target="_blank"
                rel="noopener noreferrer"
              >
                Microsoft Teams
              </Link>
            </li>
            <li>
              <Link
                as="a"
                href={I18n.t('#community.instructor_create_conference')}
                target="_blank"
                rel="noopener noreferrer"
              >
                {I18n.t('More Video Conferencing Tools')}
              </Link>
            </li>
          </ul>
        </View>
      </section>
    ),
    actionBefore: async () => {
      await handleOpenTray('help')
    },
  },
]
