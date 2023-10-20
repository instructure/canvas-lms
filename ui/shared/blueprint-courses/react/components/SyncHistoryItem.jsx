/*
 * Copyright (C) 2017 - present Instructure, Inc.
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

import {useScope as useI18nScope} from '@canvas/i18n'
import React from 'react'
import PropTypes from 'prop-types'

import {Text} from '@instructure/ui-text'
import {Heading} from '@instructure/ui-heading'
import FriendlyDatetime from '@canvas/datetime/react/components/FriendlyDatetime'
import SyncChange from './SyncChange'

import propTypes from '../propTypes'

const I18n = useI18nScope('blueprint_settingsSyncHistoryItem')

const SyncHistoryItem = ({migration, heading, ChangeComponent}) => {
  const {created_at, comment, changes} = migration
  const date = Date.parse(created_at)

  return (
    <div className="bcs__history-item">
      <header className="bcs__history-item__title">
        <Heading level="h3">
          <FriendlyDatetime dateTime={date} format={I18n.t('#date.formats.full_with_weekday')} />
        </Heading>
        <Text color="secondary" size="small">
          {migration.user?.display_name
            ? I18n.t('%{count} changes pushed by %{user}', {
                count: changes.length,
                user: migration.user.display_name,
              })
            : I18n.t('%{count} pushed changes', {count: changes.length})}
        </Text>
      </header>
      {comment && <Text as="p" color="secondary" size="small">{`"${comment}"`}</Text>}
      <div>
        {changes.length ? heading : null}
        {changes.length
          ? changes.map(change => (
              <ChangeComponent key={`${change.asset_type}_${change.asset_id}`} change={change} />
            ))
          : null}
      </div>
    </div>
  )
}

SyncHistoryItem.propTypes = {
  migration: propTypes.migration.isRequired,
  ChangeComponent: PropTypes.func,
  heading: PropTypes.node,
}

SyncHistoryItem.defaultProps = {
  ChangeComponent: SyncChange,
  heading: null,
}

export default SyncHistoryItem
