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

import I18n from 'i18n!new_nav'
import React from 'react'
import {arrayOf, bool, object, shape, string} from 'prop-types'
import {Avatar, Badge, Heading, List, Text, Spinner} from '@instructure/ui-elements'
import {Button} from '@instructure/ui-buttons'
import {View} from '@instructure/ui-layout'
import LogoutButton from '../LogoutButton'
import {AccessibleContent} from '@instructure/ui-a11y'

// Trying to keep this as generalized as possible, but it's still a bit
// gross matching on the label text sent to us from Rails
const labelsToCounts = [{label: 'Shared Content', countName: 'unreadShares'}]

const a11yCount = count => (
  <AccessibleContent alt={I18n.t('%{count} unread.', {count})}>{count}</AccessibleContent>
)

function ProfileTab({id, html_url, label, counts}) {
  function renderCountBadge() {
    const found = labelsToCounts.filter(x => x.label === label)
    if (found.length === 0) return null // no count defined for this label
    const count = counts[found[0].countName]
    if (count === 0) return null // zero count is not displayed
    return <Badge count={count} standalone margin="0 0 xxx-small small" formatOutput={a11yCount} />
  }

  return (
    <List.Item key={id}>
      <Button variant="link" margin="none" href={html_url}>
        {label}
        {renderCountBadge()}
      </Button>
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
  const {userDisplayName, userAvatarURL, loaded, userPronoun, tabs, counts} = props
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
            {userPronoun && (
              <Text size="large" fontStyle="italic">
                &nbsp;({userPronoun})
              </Text>
            )}
          </Heading>
        </div>
        <LogoutButton size="small" margin="medium 0 x-small 0" />
      </View>
      <hr role="presentation" />
      <List variant="unstyled" margin="0" itemSpacing="small">
        {loaded ? (
          tabs.map(tab => <ProfileTab key={tab.id} {...tab} counts={counts} />)
        ) : (
          <List.Item key="loading">
            <div style={{textAlign: 'center'}}>
              <Spinner margin="medium" renderTitle="Loading" />
            </div>
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
  userPronoun: string,
  tabs: arrayOf(shape(ProfileTab.propTypes)).isRequired,
  counts: object.isRequired
}
