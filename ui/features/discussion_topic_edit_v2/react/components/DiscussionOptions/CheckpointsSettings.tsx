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
import React, {useContext} from 'react'
import {useScope as useI18nScope} from '@canvas/i18n'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
import {PointsPossible} from './PointsPossible'
import {GradedDiscussionDueDatesContext} from '../../util/constants'

const I18n = useI18nScope('discussion_create')

export const CheckpointsSettings = () => {
  const {
    pointsPossibleReplyToTopic,
    setPointsPossibleReplyToTopic,
    pointsPossibleReplyToEntry,
    setPointsPossibleReplyToEntry,
  } = useContext(GradedDiscussionDueDatesContext)

  return (
    <>
      <View as="div" margin="medium 0">
        <Text size="large">{I18n.t('Checkpoint Settings')}</Text>
      </View>
      <View as="div" margin="0 0 medium 0">
        <PointsPossible
          pointsPossible={pointsPossibleReplyToTopic || 0}
          setPointsPossible={setPointsPossibleReplyToTopic}
          pointsPossibleLabel={I18n.t('Points Possible: Reply to Topic')}
          pointsPossibleDataTestId="points-possible-input-reply-to-topic"
        />
      </View>
      <View as="div" margin="0 0 medium 0">
        <PointsPossible
          pointsPossible={pointsPossibleReplyToEntry || 0}
          setPointsPossible={setPointsPossibleReplyToEntry}
          pointsPossibleLabel={I18n.t('Points Possible: Additional Replies')}
          pointsPossibleDataTestId="points-possible-input-reply-to-entry"
        />
      </View>
      <View as="div" margin="0 0 medium 0">
        <Text size="large">
          {I18n.t('Total Points Possible: %{totalPoints}', {
            totalPoints: pointsPossibleReplyToTopic + pointsPossibleReplyToEntry,
          })}
        </Text>
      </View>
    </>
  )
}
