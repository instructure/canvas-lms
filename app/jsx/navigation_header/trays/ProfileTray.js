/*
 * Copyright (C) 2015 - present Instructure, Inc.
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

import I18n from 'i18n!ProfileTray'
import React from 'react'
import {arrayOf, bool, object, shape, string} from 'prop-types'
import {Avatar, Badge, Heading, List, Text, Spinner} from '@instructure/ui-elements'
import {Link} from '@instructure/ui-link'
import {View} from '@instructure/ui-layout'
import LogoutButton from '../LogoutButton'
import {AccessibleContent} from '@instructure/ui-a11y'
import {showQRLoginModal} from './QRLoginModal'

// Trying to keep this as generalized as possible, but it's still a bit
// gross matching on the id of the tray tabs given to us by Rails
const idsToCounts = [{id: 'content_shares', countName: 'unreadShares'}]

const a11yCount = count => (
  <AccessibleContent alt={I18n.t('%{count} unread.', {count})}>{count}</AccessibleContent>
)

function ProfileTab({id, html_url, label, counts}) {
  function renderCountBadge() {
    const found = idsToCounts.filter(x => x.id === id)
    if (found.length === 0) return null // no count defined for this label
    const count = counts[found[0].countName]
    if (count === 0) return null // zero count is not displayed
    return <Badge count={count} standalone margin="0 0 xxx-small small" formatOutput={a11yCount} />
  }

  return (
    <List.Item key={id}>
      <View as="div" margin="small 0">
        <Link isWithinText={false} href={html_url}>
          {label}
          {renderCountBadge()}
        </Link>
      </View>
    </List.Item>
  )
}

ProfileTab.propTypes = {
  id: string.isRequired,
  label: string.isRequired,
  html_url: string.isRequired,
  counts: object
}

export default function ProfileTray(props) {
  const {
    userDisplayName,
    userAvatarURL,
    loaded,
    userPronouns,
    tabs,
    counts,
    showQRLoginLink
  } = props

  function onOpenQRLoginModal() {
    showQRLoginModal()
  }

  return (
    <View as="div" padding="medium">
      <View textAlign="center">
        <Avatar
          name={userDisplayName}
          src={userAvatarURL}
          alt={I18n.t('User profile picture')}
          size="x-large"
          inline={false}
          margin="auto"
        />
        <div style={{wordBreak: 'break-word'}}>
          <Heading level="h3" as="h2">
            {userDisplayName}
            {userPronouns && (
              <Text size="large" fontStyle="italic">
                &nbsp;({userPronouns})
              </Text>
            )}
          </Heading>
        </div>
        <LogoutButton size="small" margin="medium 0 x-small 0" />
      </View>
      <hr role="presentation" />
      <List variant="unstyled" margin="none" itemSpacing="small">
        {loaded ? (
          tabs.map(tab => <ProfileTab key={tab.id} {...tab} counts={counts} />)
        ) : (
          <List.Item>
            <div style={{textAlign: 'center'}}>
              <Spinner margin="medium" renderTitle="Loading" />
            </div>
          </List.Item>
        )}

        {showQRLoginLink && loaded && (
          <List.Item>
            <View as="div" margin="small 0">
              <Link isWithinText={false} onClick={onOpenQRLoginModal}>
                {I18n.t('QR for Mobile Login')}
              </Link>
            </View>
          </List.Item>
        )}
      </List>
    </View>
  )
}

ProfileTray.propTypes = {
  userDisplayName: string.isRequired,
  userAvatarURL: string.isRequired,
  loaded: bool.isRequired,
  userPronouns: string,
  tabs: arrayOf(shape(ProfileTab.propTypes)).isRequired,
  counts: object.isRequired,
  showQRLoginLink: bool.isRequired
}
