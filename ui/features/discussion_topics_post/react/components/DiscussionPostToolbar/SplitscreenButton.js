/*
 * Copyright (C) 2022 - present Instructure, Inc.
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

import {AlertManagerContext} from '@canvas/alerts/react/AlertManager'
import {Button} from '@instructure/ui-buttons'
import React, {useContext, useState} from 'react'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {UPDATE_USER_DISCUSSION_SPLITSCREEN_PREFERENCE} from '../../../graphql/Mutations'
import {useMutation} from 'react-apollo'
import {useScope as useI18nScope} from '@canvas/i18n'

const I18n = useI18nScope('discussions_posts')

export const SplitscreenButton = props => {
  const {setOnFailure, setOnSuccess} = useContext(AlertManagerContext)
  const [discussionsSplitscreenView, setDiscussionsSplitscreenView] = useState(
    ENV.DISCUSSION?.preferences?.discussions_splitscreen_view || false
  )

  const [updateUserDiscussionsSplitscreenView] = useMutation(
    UPDATE_USER_DISCUSSION_SPLITSCREEN_PREFERENCE,
    {
      onCompleted: data => {
        setOnSuccess('Splitscreen preference updated!')
        setDiscussionsSplitscreenView(
          data?.updateUserDiscussionsSplitscreenView?.user?.discussionsSplitscreenView ||
            !discussionsSplitscreenView
        )
      },
      onError: () => {
        setOnFailure(I18n.t('Unable to update splitscreen preference.'))
        setDiscussionsSplitscreenView(!discussionsSplitscreenView)
      },
    }
  )

  const onSplitscreenClick = () => {
    updateUserDiscussionsSplitscreenView({
      variables: {discussionsSplitscreenView: !discussionsSplitscreenView},
    })
  }

  return (
    <span className="discussions-splitscreen-button">
      <Button onClick={onSplitscreenClick} data-testid="splitscreenButton">
        {discussionsSplitscreenView ? I18n.t('View Inline') : I18n.t('View Split Screen')}
        <ScreenReaderContent>
          {props.discussionsSplitscreenView ? I18n.t('View Inline') : I18n.t('View Split Screen')}
        </ScreenReaderContent>
      </Button>
    </span>
  )
}
