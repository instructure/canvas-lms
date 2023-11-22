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
import {Heading} from '@instructure/ui-heading'
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
        <Text as="p">{I18n.t("Here's some quick tips to get you started in Canvas!")}</Text>
        <ol>
          <li>{I18n.t('How do I find my courses?')}</li>
          <li>{I18n.t('How do I contact my instructor?')}</li>
          <li>{I18n.t('How do I download the Student App?')}</li>
        </ol>
        <div className="tour-star-image" aria-hidden={true}>
          <img src={assetFactory('star')} alt={I18n.t('star')} />
        </div>
      </section>
    ),
  },
  {
    selector: '#global_nav_dashboard_link',
    content: (
      <section>
        <Heading level="h3">{I18n.t('How do I find my courses?')}</Heading>
        <Text as="p">{I18n.t('Find your classes or subjects in the Dashboard...')}</Text>
      </section>
    ),
  },
  {
    selector: '.navigation-tray-container',
    content: (
      <section>
        <Heading level="h3">{I18n.t('How do I find my courses?')}</Heading>
        <Text as="p">{I18n.t('...or in the Courses list.')}</Text>
      </section>
    ),
    actionBefore: async () => {
      await handleOpenTray('courses')
    },
  },
  {
    selector: '#global_nav_conversations_link',
    content: (
      <section>
        <Heading level="h3">{I18n.t('How do I contact my instructor?')}</Heading>
        <Text as="p">
          {I18n.t('Start a conversation with your instructor in the Canvas Inbox.')}
        </Text>
      </section>
    ),
  },
  {
    selector: '.navigation-tray-container',
    content: (
      <section>
        <Heading level="h3">
          {I18n.t('How do I download the Student App and get additional help?')}
        </Heading>
        <Text as="p">
          {I18n.t(
            'Access your courses and groups using any iOS or Android mobile device and find more information in the Help menu.'
          )}
        </Text>
        <ul>
          <li>
            <Link
              as="a"
              href="https://apps.apple.com/us/app/canvas-student/id480883488"
              target="_blank"
              rel="noopener noreferrer"
              aria-label={I18n.t(`Download Canvas iOS app`)}
            >
              iOS
            </Link>
          </li>
          <li>
            <Link
              as="a"
              href="https://play.google.com/store/apps/details?id=com.instructure.candroid&hl=en_US"
              target="_blank"
              rel="noopener noreferrer"
              aria-label={I18n.t(`Download Canvas Android app`)}
            >
              Android
            </Link>
          </li>
        </ul>
      </section>
    ),
    actionBefore: async () => {
      await handleOpenTray('help')
    },
  },
]
