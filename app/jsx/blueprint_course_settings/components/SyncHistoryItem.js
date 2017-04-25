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
