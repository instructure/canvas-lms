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
import Avatar from '@instructure/ui-elements/lib/components/Avatar'
import Button from '@instructure/ui-buttons/lib/components/Button'
import View from '@instructure/ui-layout/lib/components/View'
import Heading from '@instructure/ui-elements/lib/components/Heading'
import List, {ListItem} from '@instructure/ui-elements/lib/components/List'
import Spinner from '@instructure/ui-elements/lib/components/Spinner'
import LogoutButton from '../LogoutButton'

function ProfileTab({id, html_url, label}) {
  return (
    <ListItem key={id}>
      <Button variant="link" theme={{mediumPadding: '0', mediumHeight: '1.5rem'}} href={html_url}>
        {label}
      </Button>
    </ListItem>
  )
}

ProfileTab.propTypes = {
  id: string.isRequired,
  label: string.isRequired,
  html_url: string.isRequired
}

export default function ProfileTray({userDisplayName, userAvatarURL, loaded, tabs}) {
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
        <Heading level="h3" as="h2">
          {userDisplayName}
        </Heading>
        <LogoutButton size="small" margin="medium 0" />
      </View>
      <hr role="presentation" />
      <List variant="unstyled" margin="small 0" itemSpacing="small">
        {loaded ? (
          tabs.map(tab => <ProfileTab key={tab.id} {...tab} />)
        ) : (
          <ListItem key="loading">
            <div style={{textAlign: 'center'}}>
              <Spinner margin="medium" title="Loading" />
            </div>
          </ListItem>
        )}
      </List>
    </View>
  )
}

ProfileTray.propTypes = {
  userDisplayName: string.isRequired,
  userAvatarURL: string.isRequired,
  loaded: bool.isRequired,
  tabs: arrayOf(shape(ProfileTab.propTypes)).isRequired
}
