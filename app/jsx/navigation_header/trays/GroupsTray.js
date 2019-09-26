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
import {bool, arrayOf, shape, string} from 'prop-types'
import {View} from '@instructure/ui-layout'
import {Heading, List, Spinner} from '@instructure/ui-elements'
import {Button} from '@instructure/ui-buttons'

export default function GroupsTray({groups, hasLoaded}) {
  return (
    <View as="div" padding="medium">
      <Heading level="h3" as="h2">{I18n.t('Groups')}</Heading>
      <hr role="presentation"/>
      <List variant="unstyled"  margin="small 0" itemSpacing="small">
        {hasLoaded ? (
          groups.map(group =>
            <List.Item key={group.id}>
              <Button variant="link" theme={{ mediumPadding: '0', mediumHeight: '1.5rem' }} href={`/groups/${group.id}`}>{group.name}</Button>
            </List.Item>
          ).concat([
            <List.Item key="hr"><hr role="presentation"/></List.Item>,
            <List.Item key="all">
              <Button variant="link" theme={{ mediumPadding: '0', mediumHeight: '1.5rem' }} href="/groups">{I18n.t('All Groups')}</Button>
            </List.Item>
          ])
        ) : (
          <List.Item>
            <Spinner size="small" renderTitle={I18n.t('Loading')} />
          </List.Item>
        )}
      </List>
    </View>
  )
}

GroupsTray.propTypes = {
  groups: arrayOf(shape({
    id: string.isRequired,
    name: string.isRequired
  })).isRequired,
  hasLoaded: bool.isRequired
}

GroupsTray.defaultProps = {
  groups: []
}
