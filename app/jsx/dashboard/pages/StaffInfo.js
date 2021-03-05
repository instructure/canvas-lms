/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

import I18n from 'i18n!k5_dashboard'
import React from 'react'
import {Text} from '@instructure/ui-text'
import {Flex} from '@instructure/ui-flex'
import {IconButton} from '@instructure/ui-buttons'
import {IconEmailLine} from '@instructure/ui-icons'
import {PresentationContent} from '@instructure/ui-a11y-content'
import {View} from '@instructure/ui-view'
import {readableRoleName} from 'jsx/dashboard/utils'
import {Avatar} from '@instructure/ui-avatar'
import PropTypes from 'prop-types'
import {Heading} from '@instructure/ui-heading'

export default function StaffInfo({
  name,
  bio,
  email,
  avatarUrl = '/images/messages/avatar-50.png',
  role
}) {
  return (
    <View>
      <Flex>
        <Flex.Item align="start">
          <Avatar name={name} src={avatarUrl} alt={I18n.t('Avatar for %{name}', {name})} />
        </Flex.Item>
        <Flex.Item shouldGrow padding="0 small">
          <Heading level="h3">{name}</Heading>
          <Text as="div" size="small">
            {readableRoleName(role)}
          </Text>
          {bio && <Text as="div">{bio}</Text>}
        </Flex.Item>
        {email && (
          <Flex.Item>
            <IconButton
              screenReaderLabel={I18n.t('Email %{name}', {name})}
              size="small"
              withBackground={false}
              withBorder={false}
              href={`mailto:${email}`}
            >
              <IconEmailLine />
            </IconButton>
          </Flex.Item>
        )}
      </Flex>
      <PresentationContent>
        <hr style={{margin: '0.8em 0'}} />
      </PresentationContent>
    </View>
  )
}

export const StaffShape = {
  // id used in StaffContactInfoLayout
  // eslint-disable-next-line react/no-unused-prop-types
  id: PropTypes.string.isRequired,
  name: PropTypes.string.isRequired,
  bio: PropTypes.string,
  email: PropTypes.string,
  avatarUrl: PropTypes.string,
  role: PropTypes.string.isRequired
}

StaffInfo.propTypes = StaffShape
