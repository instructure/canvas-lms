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

import React, {useState} from 'react'
import I18n from 'i18n!Navigation'
import useFetchApi from '@canvas/use-fetch-api-hook'
import doFetchApi from '@canvas/do-fetch-api-effect'
import {Checkbox} from '@instructure/ui-checkbox'
import {Link} from '@instructure/ui-link'
import {Pill} from '@instructure/ui-pill'
import {Text} from '@instructure/ui-text'
import {List} from '@instructure/ui-list'
import {Spinner} from '@instructure/ui-spinner'
import {View} from '@instructure/ui-view'
import {Flex} from '@instructure/ui-flex'
import {ScreenReaderContent, PresentationContent} from '@instructure/ui-a11y-content'
import {IconWarningSolid} from '@instructure/ui-icons'

// Export so that tests can look for the right strings
export const dateFormatter = new Intl.DateTimeFormat(ENV.LOCALE, {month: 'short', day: 'numeric'})

function persistBadgeDisabled(state) {
  doFetchApi({
    path: '/api/v1/users/self/settings',
    method: 'PUT',
    body: {release_notes_badge_disabled: state}
  })
}

export default function ReleaseNotesList({badgeDisabled, setBadgeDisabled}) {
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState(null)
  const [releaseNotes, setReleaseNotes] = useState([])
  useFetchApi({
    success: setReleaseNotes,
    loading: setLoading,
    error: setError,
    path: '/api/v1/release_notes/latest'
  })

  if (loading) {
    return (
      <Spinner size="small" margin="x-small" renderTitle={() => I18n.t('Loading release notes')} />
    )
  } else if (error) {
    return (
      <Text color="error">
        <IconWarningSolid size="x-small" color="error" />{' '}
        {I18n.t('Release notes could not be loaded.')}
      </Text>
    )
  } else if (releaseNotes.length === 0) {
    return null
  }

  function updateBadgeDisabled(state) {
    persistBadgeDisabled(state)
    setBadgeDisabled(state)
  }

  return (
    <View>
      <View display="block" margin="medium 0 0">
        <Flex justifyItems="space-between" alignItems="start">
          <Text weight="bold" transform="uppercase" size="small" lineHeight="double">
            {I18n.t('Release Notes')}
          </Text>
        </Flex>
        <hr role="presentation" style={{marginTop: '0'}} />
      </View>
      <List variant="unstyled" margin="small 0" itemSpacing="small">
        {releaseNotes.map(note => {
          const has_new_tag = note.new
          return (
            <List.Item key={note.id}>
              <Flex justifyItems="space-between" alignItems="start">
                <Link isWithinText={false} href={note.url} target="_blank" rel="noopener">
                  {note.title}
                </Link>
                <Text color="secondary">
                  <span style={{whiteSpace: 'nowrap'}}>
                    {dateFormatter.format(new Date(note.date))}
                  </span>
                </Text>
              </Flex>
              {has_new_tag && <ScreenReaderContent>{I18n.t('New')}</ScreenReaderContent>}
              <Flex justifyItems="space-between" alignItems="start">
                <Flex.Item size={has_new_tag ? '80%' : '100%'}>
                  {note.description && (
                    <Text as="div" size="small">
                      {note.description}
                    </Text>
                  )}
                </Flex.Item>
                <Flex.Item>
                  {has_new_tag && (
                    <PresentationContent>
                      <Pill variant="success" text={I18n.t('NEW')} />
                    </PresentationContent>
                  )}
                </Flex.Item>
              </Flex>
            </List.Item>
          )
        })}
      </List>

      <Checkbox
        label={I18n.t('Show badges for new release notes')}
        checked={!badgeDisabled}
        onChange={() => updateBadgeDisabled(!badgeDisabled)}
        variant="toggle"
        size="small"
      />
    </View>
  )
}
