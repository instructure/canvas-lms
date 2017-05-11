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

import I18n from 'i18n!blueprint_settings'
import React from 'react'

import Heading from 'instructure-ui/lib/components/Heading'
import Typography from 'instructure-ui/lib/components/Typography'
import FriendlyDatetime from 'jsx/shared/FriendlyDatetime'
import SyncChange from './SyncChange'

import propTypes from '../propTypes'

const SyncHistoryItem = ({ migration }) => {
  const { created_at, comment, changes } = migration
  const date = Date.parse(created_at)

  return (
    <div className="bcs__history-item">
      <header className="bcs__history-item__title">
        <Heading level="h3">
          <FriendlyDatetime dateTime={date} format={I18n.t('#date.formats.full_with_weekday')} />
        </Heading>
        <Typography color="secondary" size="small">{I18n.t('%{count} pushed changes', { count: changes.length })}</Typography>
      </header>
      {comment && <Typography as="p" color="secondary">{comment}</Typography>}
      {changes.map(change => <SyncChange key={change.html_url} change={change} />)}
    </div>
  )
}

SyncHistoryItem.propTypes = {
  migration: propTypes.migration.isRequired,
}

export default SyncHistoryItem
