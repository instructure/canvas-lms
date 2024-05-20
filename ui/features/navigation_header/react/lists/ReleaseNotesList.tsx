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

import React, {useState, useEffect} from 'react'
import {useScope as useI18nScope} from '@canvas/i18n'
import useDateTimeFormat from '@canvas/use-date-time-format-hook'
import {Checkbox} from '@instructure/ui-checkbox'
import {Link} from '@instructure/ui-link'
import {Pill} from '@instructure/ui-pill'
import {Text} from '@instructure/ui-text'
import {List} from '@instructure/ui-list'
import {Spinner} from '@instructure/ui-spinner'
import {View} from '@instructure/ui-view'
import {Flex} from '@instructure/ui-flex'
import {useQuery} from '@canvas/query'
import {useMutation, useQueryClient} from '@tanstack/react-query'
import releaseNotesQuery from '../queries/releaseNotesQuery'
import {ScreenReaderContent, PresentationContent} from '@instructure/ui-a11y-content'
import {IconWarningSolid} from '@instructure/ui-icons'
import {getSetting, setSetting} from '@canvas/settings-query/react/settingsQuery'

const I18n = useI18nScope('Navigation')

export default function ReleaseNotesList() {
  const queryClient = useQueryClient()
  const dateFormatter = useDateTimeFormat('date.formats.short')

  const countsEnabled = Boolean(
    window.ENV.current_user_id && !window.ENV.current_user?.fake_student
  )

  const {data: releaseNotesBadgeDisabled} = useQuery({
    queryKey: ['settings', 'release_notes_badge_disabled'],
    queryFn: getSetting,
    enabled: countsEnabled && ENV.FEATURES.embedded_release_notes,
    fetchAtLeastOnce: true,
  })

  const mutation = useMutation({
    mutationFn: setSetting,
    onSuccess: () =>
      queryClient.setQueryData(
        ['settings', 'release_notes_badge_disabled'],
        !releaseNotesBadgeDisabled
      ),
  })

  const {
    data: releaseNotes,
    isLoading,
    isError,
    isSuccess,
    isFetching,
  } = useQuery({
    queryKey: ['releaseNotes'],
    queryFn: releaseNotesQuery,
    enabled: countsEnabled && ENV.FEATURES.embedded_release_notes,
    fetchAtLeastOnce: true,
  })

  const [wasFetchingReleaseNotes, setWasFetchingReleaseNotes] = useState(isFetching)
  useEffect(() => {
    // when release notes are fetched, reset badget count to zero
    if (isSuccess && wasFetchingReleaseNotes) {
      setWasFetchingReleaseNotes(false)
      queryClient.setQueryData(['unread_count', 'release_notes'], 0)
    }
  }, [isSuccess, wasFetchingReleaseNotes, queryClient])

  function updateBadgeDisabled(newState: boolean) {
    mutation.mutate({
      setting: 'release_notes_badge_disabled',
      newState,
    })
  }

  if (isLoading) {
    return (
      <Spinner
        size="small"
        delay={500}
        margin="x-small"
        renderTitle={() => I18n.t('Loading release notes')}
      />
    )
  }
  if (isError) {
    return (
      <Text color="danger">
        <IconWarningSolid size="x-small" color="error" />{' '}
        {I18n.t('Release notes could not be loaded.')}
      </Text>
    )
  }
  if (isSuccess && releaseNotes.length > 0) {
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
        <List isUnstyled={true} margin="small 0" itemSpacing="small">
          {releaseNotes.map(note => {
            const has_new_tag = note.new
            return (
              <List.Item key={note.id}>
                <Flex justifyItems="space-between" alignItems="start">
                  <Link isWithinText={false} href={note.url} target="_blank" rel="noopener">
                    {note.title}
                  </Link>
                  <Text color="secondary">
                    <span style={{whiteSpace: 'nowrap'}}>{dateFormatter(note.date)}</span>
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
                        <Pill color="success">{I18n.t('NEW')}</Pill>
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
          checked={!releaseNotesBadgeDisabled}
          onChange={() => updateBadgeDisabled(!releaseNotesBadgeDisabled)}
          variant="toggle"
          size="small"
        />
      </View>
    )
  }

  return null
}
