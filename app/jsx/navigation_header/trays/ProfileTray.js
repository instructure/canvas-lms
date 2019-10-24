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
import {string, bool, arrayOf, shape} from 'prop-types'
import {Avatar, Heading, List, Text, Spinner} from '@instructure/ui-elements'
import {Button} from '@instructure/ui-buttons'
import {View} from '@instructure/ui-layout'
import LogoutButton from '../LogoutButton'

function ProfileTab({id, html_url, label}) {
  return (
    <List.Item key={id}>
      <Button variant="link" margin="none" href={html_url}>
        {label}
      </Button>
    </List.Item>
  )
}

ProfileTab.propTypes = {
  id: string.isRequired,
  label: string.isRequired,
  html_url: string.isRequired
}

export default function ProfileTray({userDisplayName, userAvatarURL, loaded, userPronoun, tabs}) {
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
          tabs.map(tab => <ProfileTab key={tab.id} {...tab} />)
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
  tabs: arrayOf(shape(ProfileTab.propTypes)).isRequired
}
