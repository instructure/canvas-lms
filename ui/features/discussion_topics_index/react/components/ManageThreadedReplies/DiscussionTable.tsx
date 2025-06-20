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

import React from 'react'
import {View} from '@instructure/ui-view'
import {Text} from '@instructure/ui-text'
import {Flex} from '@instructure/ui-flex'
import {Checkbox} from '@instructure/ui-checkbox'
import theme from '@instructure/ui-themes'
import {IconAssignmentLine, IconDiscussionLine} from '@instructure/ui-icons'
import useDateTimeFormat from '@canvas/use-date-time-format-hook'
import {Button} from '@instructure/ui-buttons'
import {useScope as createI18nScope} from '@canvas/i18n'
import DiscussionThreadedSelect from './DiscussionThreadedSelect'
import {useManageThreadedRepliesStore} from '../../hooks/useManageThreadedRepliesStore'
import {DTRDiscussion} from './ManageThreadedReplies'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import LoadingIndicator from '@canvas/loading-indicator/react'

const I18n = createI18nScope('discussions_v2')

interface DiscussionTableProps {
  mobileOnly: boolean
  discussions: DTRDiscussion[]
}

interface DiscussionEntryProps {
  id: string
  isPublished: boolean
  title: string
  lastReplyAt: string | null
  mobileOnly: boolean
  isAssignment: boolean
}

const DiscussionEntry: React.FC<DiscussionEntryProps> = ({
  id,
  isPublished,
  title,
  lastReplyAt,
  mobileOnly,
  isAssignment,
}) => {
  const dateFormatter = useDateTimeFormat('time.formats.short')

  const lastReplyText =
    lastReplyAt && I18n.t('Last post at %{date}', {date: dateFormatter(lastReplyAt)})
  const toggleSelectedDiscussion = useManageThreadedRepliesStore(
    state => state.toggleSelectedDiscussion,
  )
  const selectedDiscussions = useManageThreadedRepliesStore(state => state.selectedDiscussions)

  return (
    <View display="block" borderWidth="small 0 0 0" borderColor="primary">
      <Flex wrap="no-wrap" alignItems="center" gap="x-small" padding="mediumSmall">
        <Flex.Item margin="0 x-small 0 0">
          <div style={{marginRight: `-${theme.spacing.small}`}}>
            <Checkbox
              data-testid={`manage-threaded-replies-select-discussion-${id}`}
              label={<ScreenReaderContent>{I18n.t('Select entry')}</ScreenReaderContent>}
              checked={selectedDiscussions.includes(id)}
              onChange={() => toggleSelectedDiscussion(id)}
            />
          </div>
        </Flex.Item>
        <Flex.Item>
          <View>
            <Text color={isPublished ? 'success' : 'secondary'}>
              {isAssignment ? <IconAssignmentLine /> : <IconDiscussionLine />}
            </Text>
          </View>
        </Flex.Item>
        <Flex.Item shouldGrow={true}>
          <Flex direction={mobileOnly ? 'column' : 'row'} gap="small">
            <Flex.Item shouldGrow={true} padding="0 x-small">
              <View as="div">
                <Text weight="bold">{title}</Text>
              </View>
              <View as="div">
                <Text size="small">{lastReplyText}</Text>
              </View>
            </Flex.Item>
            <Flex.Item padding="xx-small x-small">
              <DiscussionThreadedSelect id={id} />
            </Flex.Item>
          </Flex>
        </Flex.Item>
      </Flex>
    </View>
  )
}

const DiscussionTable: React.FC<DiscussionTableProps> = ({mobileOnly, discussions}) => {
  const selectedDiscussions = useManageThreadedRepliesStore(state => state.selectedDiscussions)
  const setDiscussionState = useManageThreadedRepliesStore(state => state.setDiscussionState)
  const isLoading = useManageThreadedRepliesStore(state => state.loading)
  const toggleSelectedDiscussions = useManageThreadedRepliesStore(
    state => state.toggleSelectedDiscussions,
  )

  const handleSelectAll = () => {
    if (selectedDiscussions.length === 0) {
      toggleSelectedDiscussions(discussions.map(d => d.id))
      return
    }

    toggleSelectedDiscussions([])
  }

  const handleChangeSelected = (state: 'threaded' | 'not_threaded') => {
    selectedDiscussions.forEach(id => {
      setDiscussionState(id, state)
    })
  }

  return (
    <View
      display="block"
      borderWidth={mobileOnly ? 'none' : 'small'}
      borderColor="primary"
      borderRadius="medium"
    >
      <View display="block" padding="0 0 x-small 0">
        <Flex
          justifyItems="space-between"
          alignItems={mobileOnly ? 'start' : 'center'}
          gap="x-small"
          direction={mobileOnly ? 'column' : 'row'}
          padding="0 x-small"
        >
          <Flex.Item padding="x-small">
            <Checkbox
              label="Select all"
              data-testid="manage-threaded-replies-select-all-checkbox"
              indeterminate={
                selectedDiscussions.length > 0 && selectedDiscussions.length != discussions.length
              }
              checked={selectedDiscussions.length === discussions.length}
              onChange={handleSelectAll}
            />
          </Flex.Item>
          <Flex.Item width={mobileOnly ? '100%' : 'auto'}>
            <Flex
              gap="mediumSmall"
              direction={mobileOnly ? 'column' : 'row'}
              width={mobileOnly ? '100%' : 'auto'}
              padding="x-small"
            >
              <Button
                data-testid="manage-threaded-replies-set-to-threaded-selected-button"
                width={mobileOnly ? '100%' : 'auto'}
                onClick={() => handleChangeSelected('threaded')}
              >
                {I18n.t('Set to Threaded')}
              </Button>
              <Button
                data-testid="manage-threaded-replies-set-to-not-threaded-selected-button"
                width={mobileOnly ? '100%' : 'auto'}
                onClick={() => handleChangeSelected('not_threaded')}
              >
                {I18n.t('Set to Not threaded')}
              </Button>
            </Flex>
          </Flex.Item>
        </Flex>
      </View>
      {isLoading && (
        <View as="div" borderWidth="small 0 0 0" borderColor="primary" padding="large">
          <LoadingIndicator />
        </View>
      )}
      {!isLoading &&
        discussions.map(discussion => (
          <DiscussionEntry key={discussion.id} {...discussion} mobileOnly={mobileOnly} />
        ))}
      {!isLoading && mobileOnly && (
        <View as="div" width="100%" borderWidth="small 0 0 0" borderColor="primary" />
      )}
    </View>
  )
}

export default DiscussionTable
