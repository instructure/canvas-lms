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
import {useScope as useI18nScope} from '@canvas/i18n'

import {View} from '@instructure/ui-view'
import {RadioInput, RadioInputGroup} from '@instructure/ui-radio-input'

import AnonymousResponseSelector from '@canvas/discussions/react/components/AnonymousResponseSelector/AnonymousResponseSelector'

const I18n = useI18nScope('discussion_create')

type Props = {
  discussionAnonymousState: string
  setDiscussionAnonymousState: (value: string) => void
  isEditing: boolean
  isGraded: boolean
  setIsGraded: (value: boolean) => void
  setIsGroupDiscussion: (value: boolean) => void
  setGroupCategoryId: (value: string | null) => void
  shouldShowPartialAnonymousSelector: boolean
  setAnonymousAuthorState: (value: boolean) => void
}

export const AnonymousSelector = ({
  discussionAnonymousState,
  setDiscussionAnonymousState,
  isEditing,
  isGraded,
  setIsGraded,
  setIsGroupDiscussion,
  setGroupCategoryId,
  shouldShowPartialAnonymousSelector,
  setAnonymousAuthorState,
}: Props) => {
  return (
    <View display="block" margin="medium 0">
      <RadioInputGroup
        name="anonymous"
        description={I18n.t('Anonymous Discussion')}
        value={discussionAnonymousState}
        onChange={(_event, value) => {
          if (value !== 'off') {
            setIsGraded(false)
            setIsGroupDiscussion(false)
            setGroupCategoryId(null)
          }
          setDiscussionAnonymousState(value)
        }}
        disabled={isEditing || isGraded}
      >
        <RadioInput
          key="off"
          value="off"
          label={I18n.t(
            'Off: student names and profile pictures will be visible to other members of this course'
          )}
        />
        <RadioInput
          key="partial_anonymity"
          value="partial_anonymity"
          label={I18n.t('Partial: students can choose to reveal their name and profile picture')}
        />
        <RadioInput
          key="full_anonymity"
          value="full_anonymity"
          label={I18n.t('Full: student names and profile pictures will be hidden')}
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
