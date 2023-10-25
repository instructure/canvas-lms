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
import {render} from 'react-dom'
import PropTypes from 'prop-types'
import {Alert} from '@instructure/ui-alerts'
import {InstUISettingsProvider} from '@instructure/emotion'
import {useScope as useI18nScope} from '@canvas/i18n'
import {Text} from '@instructure/ui-text'
import {Img} from '@instructure/ui-img'
import {Flex} from '@instructure/ui-flex'
import {View} from '@instructure/ui-view'
import {responsiviser} from '@canvas/planner'
import {Link} from '@instructure/ui-link'

import ZoomIcon from '../images/zoom.svg'
import MeetIcon from '../images/meet.svg'
import TeamsIcon from '../images/teams.svg'

const I18n = useI18nScope('conferences_alternatives')

const componentOverrides = {
  [Alert.componentId]: {
    boxShadow: 'none',
  },
}

const visitZoomUrl = 'https://zoom.com/meeting/schedule'
const visitMeetUrl = 'https://meet.google.com/_meet'

function ConferenceProvider({imageSource, title, text, responsiveSize}) {
  const skinny = responsiveSize === 'medium'
  return (
    <Flex direction={skinny ? 'row' : 'column'} alignItems="stretch">
      <Flex.Item
        height={skinny ? null : '10rem'}
        width={skinny ? '10rem' : null}
        background="secondary"
        margin="0 medium 0 0"
      >
        <Flex alignItems="center" justifyItems="center" height="100%">
          <Flex.Item padding="small">
            <Img src={imageSource} title={title} />
          </Flex.Item>
        </Flex>
      </Flex.Item>
      <Flex.Item shouldShrink={true} padding="small x-small">
        <Text size="large" weight="bold">
          {title}
        </Text>
        <Text size="small">
          {text.map((content, i) => (
            // eslint-disable-next-line react/no-array-index-key
            <View key={i} as="div" padding="x-small 0">
              {content}
            </View>
          ))}
        </Text>
      </Flex.Item>
    </Flex>
  )
}

ConferenceProvider.propTypes = {
  imageSource: PropTypes.string.isRequired,
  title: PropTypes.string.isRequired,
  text: PropTypes.arrayOf(PropTypes.node).isRequired,
  responsiveSize: PropTypes.oneOf(['small', 'medium', 'large']).isRequired,
}

const Zoom = props => (
  <ConferenceProvider
    {...props}
    imageSource={ZoomIcon}
    title={I18n.t('Zoom')}
    text={[
      I18n.t(
        'Paste Zoom into Calendar Events, Announcements, Discussions, and anywhere you use the Rich Content Editor (RCE).'
      ),
      [
        <Link href={visitZoomUrl}>{I18n.t('Visit Zoom')}</Link>,
        I18n.t(
          'to create a link you can use in Canvas. You’ll need to sign-up for a Zoom account if you don’t already have one.'
        ),
      ],
      // <Link href={learnZoomUrl}>{I18n.t('Learn how to use Zoom in Canvas.')}</Link>
    ]}
  />
)

const Meet = props => (
  <ConferenceProvider
    {...props}
    imageSource={MeetIcon}
    title={I18n.t('Google Meet')}
    text={[
      I18n.t(
        'Paste Google Meet links into Calendar Events, Announcements, Discussions, and anywhere you use the Rich Content Editor (RCE)'
      ),
      [
        <Link href={visitMeetUrl}>{I18n.t('Visit Google Meet')}</Link>,
        I18n.t(
          'to create a link you can use in Canvas. You’ll need a Google account to use Google Meet.'
        ),
      ],
      <Link href={I18n.t('#community.admin_hangouts_meet_lti')}>
        {I18n.t('Learn how to use Google Meet in Canvas')}
      </Link>,
    ]}
  />
)

const Teams = props => (
  <ConferenceProvider
    {...props}
    imageSource={TeamsIcon}
    title={I18n.t('Microsoft Teams')}
    text={[
      I18n.t(
        'If your school uses Microsoft Teams, you can use the Enhanced Rich Content Editor (RCE) to easily add a Team room while creating Calendar Events, Announcements, discussions posts and more.'
      ),
      <Link href={I18n.t('#community.admin_teams_meetings')}>
        {I18n.t('Learn how to use Microsoft Teams in Canvas')}
      </Link>,
    ]}
  />
)

function ConferenceAlternatives({responsiveSize}) {
  return (
    <InstUISettingsProvider theme={{componentOverrides}}>
      <Alert margin="none none medium none" variant="warning">
        {I18n.t(`Conferences, powered by BigBlueButton, is unable to handle current demand.  Consider upgrading to
        Premium BigBlueButton or use one of the following video conferencing providers.  Please talk to your local
        admin for additional guidance.`)}
      </Alert>
      <View as="div" borderWidth="small 0 0 0" borderColor="primary" padding="medium 0 0 0">
        <Flex direction={responsiveSize === 'large' ? 'row' : 'column'} alignItems="start">
          <Flex.Item shouldGrow={true} size={responsiveSize === 'large' ? '0' : null}>
            <Zoom responsiveSize={responsiveSize} />
          </Flex.Item>
          <Flex.Item
            shouldGrow={true}
            size={responsiveSize === 'large' ? '0' : null}
            padding={responsiveSize === 'large' ? '0 large' : 'large 0'}
          >
            <Meet responsiveSize={responsiveSize} />
          </Flex.Item>
          <Flex.Item shouldGrow={true} size={responsiveSize === 'large' ? '0' : null}>
            <Teams responsiveSize={responsiveSize} />
          </Flex.Item>
        </Flex>
      </View>
    </InstUISettingsProvider>
  )
}

ConferenceAlternatives.propTypes = {
  responsiveSize: PropTypes.oneOf(['small', 'medium', 'large']),
}

const ResponsiveConferenceAlternatives = responsiviser()(ConferenceAlternatives)

export default function renderConferenceAlternatives(node) {
  render(<ResponsiveConferenceAlternatives />, node)
}
