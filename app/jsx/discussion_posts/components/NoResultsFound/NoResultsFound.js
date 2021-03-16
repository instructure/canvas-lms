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

import I18n from 'i18n!conversations_2'
import {Text} from '@instructure/ui-text'
import {List} from '@instructure/ui-list'
import React from 'react'

export const NoResultsFound = () => {
  return (
    <>
      <Text lineHeight="double">{I18n.t('Your search did not match any entries.')}</Text>
      <br />
      <Text lineHeight="double">{I18n.t('Suggestions:')}</Text>
      <List>
        <List.Item>
          <Text lineHeight="double">
            {I18n.t('Make sure all search terms are spelled correctly.')}
          </Text>
        </List.Item>
        <List.Item>
          <Text lineHeight="double">
            {I18n.t('Try different, more general, or fewer keywords.')}
          </Text>
        </List.Item>
        <List.Item>
          <Text lineHeight="double">{I18n.t('Try disabling the "Unread" filter.')}</Text>
        </List.Item>
      </List>
    </>
  )
}
