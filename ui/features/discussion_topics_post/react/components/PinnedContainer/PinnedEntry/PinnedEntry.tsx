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
import {Flex} from '@instructure/ui-flex'
import {View} from '@instructure/ui-view'
import {Text} from '@instructure/ui-text'
import {theme} from '@instructure/canvas-theme'
import {IconPinSolid, IconMoveDownLine, IconLikeLine} from '@instructure/ui-icons'
import DateHelper from '@canvas/datetime/dateHelper'
import {AuthorAvatar} from '../../AuthorInfo/AuthorAvatar'
import {Timestamps} from '../../AuthorInfo/Timestamps'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Button, IconButton} from '@instructure/ui-buttons'
import {InlineList} from '@instructure/ui-list'
import {getFullReplyText} from '../../../utils/helpers'

const I18n = createI18nScope('discussion_pinned_post')

interface PinnedEntryProps {
  entry: Record<string, any>
  published?: boolean // comming from discussion topic
  isAnnouncement?: boolean // comming from discussion topic
  lastReplyAtDisplay: string // DateHelper.formatDatetimeFordiscussions (discussionEntry)
  delayedPostAt?: string
  editor?: Record<string, any>

  breakpoints: Record<string, any> // comming from withBreakpoints or somewhere
}

const Buttons = () => (
  <>
    <InlineList delimiter="pipe">
      <InlineList.Item>
        {/* TODO: VICE-5382 */}
        <View className="discussion-pin-btn" style={{display: 'inline-flex', alignItems: 'center'}}>
          <IconButton
            color="primary"
            as="a"
            withBackground={false}
            withBorder={false}
            onClick={() => {
              console.log('Pin clicked')
            }}
            screenReaderLabel={I18n.t('Pin')}
            data-testid="pin-button"
            size="small"
          >
            <IconMoveDownLine />
          </IconButton>
        </View>
      </InlineList.Item>
      <InlineList.Item>
        {/* TODO: VICE-5358 */}
        {/* allow liking only if available */}
        <Button
          color="primary"
          withBackground={false}
          onClick={() => {
            console.log('Like clicked')
          }}
          data-testid="like-button"
          size="small"
          renderIcon={<IconLikeLine />}
          themeOverride={{
            borderWidth: '0px',
          }}
        >
          <Text weight="weightImportant">3</Text>
        </Button>
      </InlineList.Item>
      <InlineList.Item>
        {/* TODO: VICE-5366 */}
        <IconButton
          color="primary"
          withBackground={false}
          withBorder={false}
          screenReaderLabel={I18n.t('Pin')}
          onClick={() => {
            console.log('Pin clicked')
          }}
          data-testid="pin-button"
        >
          <IconPinSolid />
        </IconButton>
      </InlineList.Item>
    </InlineList>
  </>
)

const PinnedEntry = ({
  entry,
  published,
  isAnnouncement,
  lastReplyAtDisplay,
  delayedPostAt,
  editor,
  breakpoints,
}: PinnedEntryProps) => {
  const timestampTextSize = 'small'

  // TODO: VICE-5381 get real values
  const repliesText = getFullReplyText(2, 1)

  return (
    <Flex justifyItems="space-between" wrap={breakpoints?.desktopOnly ? 'no-wrap' : 'wrap'}>
      <Flex gap="mediumSmall">
        <View>
          {/* Avatar size is different than the normal entry it should be always small */}
          <AuthorAvatar entry={entry} avatarSize={'small'} />
        </View>
        <View>
          <Flex direction="column">
            <Flex.Item>
              <div
                style={{
                  display: 'block',
                  maxHeight: '7rem', // just an approximation for 4 lines
                  overflowY: 'hidden',
                  fontSize: theme.typography.fontSizeSmall,
                  fontWeight: theme.typography.weightImportant,
                }}
                dangerouslySetInnerHTML={{__html: entry.message}}
              ></div>
            </Flex.Item>
            <Flex.Item as="div">
              <Timestamps
                author={entry.author}
                editor={editor}
                delayedPostAt={delayedPostAt} // Not using hopefully
                createdAt={DateHelper.formatDatetimeForDiscussions(entry.createdAt)}
                editedTimingDisplay={DateHelper.formatDatetimeForDiscussions(
                  entry.deleted ? entry.updatedAt : entry.editedAt,
                )}
                lastReplyAtDisplay={lastReplyAtDisplay}
                showCreatedAsTooltip={false}
                timestampTextSize={timestampTextSize}
                mobileOnly={breakpoints?.mobileOnly}
                isTopic={false} // no pinned will be topic
                published={published}
                isAnnouncement={isAnnouncement}
                withoutPadding={true}
                container="pinned"
                replyNode={
                  <Flex.Item>
                    <Text size={timestampTextSize}>
                      {' | '}
                      {repliesText}
                    </Text>
                  </Flex.Item>
                }
              />
            </Flex.Item>
          </Flex>
        </View>
      </Flex>
      <Flex.Item shouldShrink={false}>
        {/* <Replies count={entry?.subentriesCount} unread={null} /> */}
        <Buttons />
      </Flex.Item>
    </Flex>
  )
}

export {PinnedEntry}
