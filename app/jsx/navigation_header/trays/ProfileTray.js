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
import {bool, string} from 'prop-types'
import Avatar from '@instructure/ui-core/lib/components/Avatar'
import Button from '@instructure/ui-core/lib/components/Button'
import Container from '@instructure/ui-core/lib/components/Container'
import Heading from '@instructure/ui-core/lib/components/Heading'
import Link from '@instructure/ui-core/lib/components/Link'
import List, {ListItem} from '@instructure/ui-core/lib/components/List'

function readCookie(key) {
  return (document.cookie.match(`(^|; )${encodeURIComponent(key)}=([^;]*)`) || 0)[2]
}

export default function ProfileTray({
  userDisplayName,
  userAvatarURL,
  profileEnabled,
  eportfoliosEnabled
}) {
  return (
    <Container as="div" padding="medium">
      <Container textAlign="center">
        <Avatar
          name={userDisplayName}
          src={userAvatarURL}
          alt={I18n.t('User profile picture')}
          size="x-large"
          inline={false}
          margin="auto"
        />
        <Heading level="h3" as="h2">{userDisplayName}</Heading>
        <form action="/logout" method="post">
          <input name="utf8" value="✓" type="hidden" />
          <input name="_method" value="delete" type="hidden" />
          <input name="authenticity_token" value={readCookie('_csrf_token')} type="hidden" />
          <Button type="submit" size="small" margin="medium 0">{I18n.t('Logout')}</Button>
        </form>
      </Container>
      <hr role="presentation"/>
      <List variant="unstyled" margin="small 0" itemSpacing="small">
        {[
          profileEnabled && (
            <ListItem key="profile">
              <Link href="/profile">{I18n.t('Profile')}</Link>
            </ListItem>
          ),
          <ListItem key="settings">
            <Link href="/profile/settings">{I18n.t('Settings')}</Link>
          </ListItem>,
          <ListItem key="notifications">
            <Link href="/profile/communication">{I18n.t('Notifications')}</Link>
          </ListItem>,
          <ListItem key="files">
            <Link href="/files">{I18n.t('Files')}</Link>
          </ListItem>,
          eportfoliosEnabled && (
            <ListItem key="eportfolios">
              <Link href="/dashboard/eportfolios">{I18n.t('ePortfolios')}</Link>
            </ListItem>
          )
        ].filter(Boolean)}
      </List>
    </Container>
  )
}

ProfileTray.propTypes = {
  userDisplayName: string.isRequired,
  userAvatarURL: string.isRequired,
  profileEnabled: bool.isRequired,
  eportfoliosEnabled: bool.isRequired
}
