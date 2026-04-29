/*
 * Copyright (C) 2025 - present Instructure, Inc.
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
import {View} from '@instructure/ui-view'
import {Flex} from '@instructure/ui-flex'
import {ToggleDetails} from '@instructure/ui-toggle-details'
import {Text} from '@instructure/ui-text'
import {IconPinSolid} from '@instructure/ui-icons'
import {useScope as createI18nScope} from '@canvas/i18n'
import {borders, spacing} from '@instructure/canvas-theme'
import {PinnedEntry} from './PinnedEntry/PinnedEntry'
import DateHelper from '@canvas/datetime/dateHelper'
import {useMemo} from 'react'

const I18n = createI18nScope('discussion_pinned_post')

const Header = ({count}: {count: number}) => (
  <Flex margin="0 0 0 xx-small" justifyItems="space-between" alignItems="stretch" as="div">
    <Flex gap="small">
      <View>
        <IconPinSolid color="brand" />
      </View>
      <View>
        <Text weight="bold" size="large">
          {I18n.t('Pinned Replies')}
        </Text>
      </View>
    </Flex>
    <View>
      <Text>
        {I18n.t(
          {
            one: '1 reply',
            other: '%{pinnedCount} replies',
          },
          {
            count: count,
            pinnedCount: count,
          },
        )}
      </Text>
    </View>
  </Flex>
)

interface PinnedContainerProps {
  entries: Record<string, any>[]
  topic: Record<string, any>
  breakpoints: Record<string, any>
}

/*
 * Basic filter for removing pinned entries if they are not updated correctly
 */
const entryFilter = (entry: PinnedContainerProps['entries'][number]): boolean => {
  if (!entry) {
    return false
  }

  if (entry.deleted) {
    return false
  }

  if (!entry.message) {
    return false
  }

  return true
}

const PinnedContainer = ({entries, topic, breakpoints}: PinnedContainerProps) => {
  const pinnedEntries = useMemo(() => {
    return entries.filter(entryFilter)
  }, [entries])

  if (pinnedEntries.length === 0) {
    return null
  }

  // TOOD: VICE-5381, get from discussionThread
  const lastReplyAtDisplay = new Date().toLocaleString('en-US', {
    month: 'short',
    day: 'numeric',
    hour: 'numeric',
    minute: 'numeric',
    hour12: true,
  })

  return (
    <View
      as="div"
      padding="medium large"
      borderColor="primary"
      borderWidth="small"
      borderRadius="medium"
    >
      <ToggleDetails
        summary={<Header count={pinnedEntries.length} />}
        defaultExpanded={true}
        size="large"
        fluidWidth={true}
      >
        {pinnedEntries.map((entry, index) => (
          <>
            <PinnedEntry
              key={entry.id}
              entry={entry}
              isAnnouncement={false}
              breakpoints={breakpoints}
              delayedPostAt={DateHelper.formatDatetimeForDiscussions(topic.delayedPostAt)}
              lastReplyAtDisplay={lastReplyAtDisplay} // VICE-5381 should come from discussionThread
              editor={topic.editor}
            />
            {pinnedEntries.length > 1 && index < pinnedEntries.length - 1 && (
              <hr
                data-testid="pinned-post-separator"
                style={{
                  height: borders.widthSmall,
                  borderColor: '#E8EAEC',
                  margin: `${spacing.medium} 0`,
                }}
              />
            )}
          </>
        ))}
      </ToggleDetails>
    </View>
  )
}

export {PinnedContainer}
