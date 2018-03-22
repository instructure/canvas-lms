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
import Container from '@instructure/ui-core/lib/components/Container'
import Heading from '@instructure/ui-core/lib/components/Heading'
import Link from '@instructure/ui-core/lib/components/Link'
import List, {ListItem} from '@instructure/ui-core/lib/components/List'
import Spinner from '@instructure/ui-core/lib/components/Spinner'

export default function GroupsTray({groups, hasLoaded}) {
  return (
    <Container as="div" padding="medium">
      <Heading level="h3" as="h1">{I18n.t('Groups')}</Heading>
      <hr />
      <List variant="unstyled"  margin="small 0" itemSpacing="small">
        {hasLoaded ? (
          groups.map(group =>
            <ListItem key={group.id}>
              <Link href={`/groups/${group.id}`}>{group.name}</Link>
            </ListItem>
          ).concat([
            <ListItem key="hr"><hr /></ListItem>,
            <ListItem key="all">
              <Link href="/groups">{I18n.t('All Groups')}</Link>
            </ListItem>
          ])
        ) : (
          <ListItem>
            <Spinner size="small" title={I18n.t('Loading')} />
          </ListItem>
        )}
      </List>
    </Container>
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
