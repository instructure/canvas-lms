/*
 * Copyright (C) 2024 - present Instructure, Inc.
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
import {useScope as createI18nScope} from '@canvas/i18n'

import theme from '@instructure/canvas-theme'
import {Heading} from '@instructure/ui-heading'
import {IconInfoLine} from '@instructure/ui-icons'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {Tooltip} from '@instructure/ui-tooltip'
import {View} from '@instructure/ui-view'
import {RadioInput, RadioInputGroup} from '@instructure/ui-radio-input'

import AnonymousResponseSelector from '@canvas/discussions/react/components/AnonymousResponseSelector/AnonymousResponseSelector'

const I18n = createI18nScope('discussion_create')

type Props = {
  discussionAnonymousState: string
  setDiscussionAnonymousState: (value: string) => void
  isSelectDisabled: boolean
  setIsGraded: (value: boolean) => void
  setIsGroupDiscussion: (value: boolean) => void
  setGroupCategoryId: (value: string | null) => void
  shouldShowPartialAnonymousSelector: boolean
  setAnonymousAuthorState: (value: boolean) => void
}

export const AnonymousSelector = ({
  discussionAnonymousState,
  setDiscussionAnonymousState,
  isSelectDisabled,
  setIsGraded,
  setIsGroupDiscussion,
  setGroupCategoryId,
  shouldShowPartialAnonymousSelector,
  setAnonymousAuthorState,
}: Props) => {
  return (
    <View display="block" margin="medium 0">
      {/* Title should not be read by screen readers as "dimmed", single inputs are disabled instead */}
      <RadioInputGroup
        name="anonymous"
        description={
          <>
            <View display="inline-block">
              <Heading level="h4">{I18n.t('Anonymous Discussion')}</Heading>
            </View>
            <Tooltip
              renderTip={I18n.t('Grading and Groups are not supported in Anonymous Discussions.')}
              placement="top"
              on={['hover', 'focus']}
              color="primary"
            >
              <div
                style={{display: 'inline-block', marginLeft: theme.spacing.xxSmall}}
                // eslint-disable-next-line jsx-a11y/no-noninteractive-tabindex
                tabIndex={0}
              >
                <IconInfoLine data-testid="groups_grading_not_allowed" />
                <ScreenReaderContent>
                  {I18n.t('Grading and Groups are not supported in Anonymous Discussions.')}
                </ScreenReaderContent>
              </div>
            </Tooltip>
          </>
        }
        value={discussionAnonymousState}
        onChange={(_event, value) => {
          if (value !== 'off') {
            setIsGraded(false)
            setIsGroupDiscussion(false)
            setGroupCategoryId(null)
          }
          setDiscussionAnonymousState(value)
        }}
        data-testid="anonymous-discussion-options"
      >
        <RadioInput
          key="off"
          value="off"
          label={I18n.t(
            'Off: student names and profile pictures will be visible to other members of this course',
          )}
          disabled={isSelectDisabled}
        />
        <RadioInput
          key="partial_anonymity"
          value="partial_anonymity"
          label={I18n.t('Partial: students can choose to reveal their name and profile picture')}
          disabled={isSelectDisabled}
        />
        <RadioInput
          key="full_anonymity"
          value="full_anonymity"
          label={I18n.t('Full: student names and profile pictures will be hidden')}
          disabled={isSelectDisabled}
        />
      </RadioInputGroup>
      {shouldShowPartialAnonymousSelector && (
        <View display="block" margin="medium 0">
          <AnonymousResponseSelector
            username={ENV.current_user.display_name}
            setAnonymousAuthorState={setAnonymousAuthorState}
            discussionAnonymousState={discussionAnonymousState}
          />
        </View>
      )}
    </View>
  )
}
