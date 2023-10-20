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
import PropTypes from 'prop-types'
import React, {useContext} from 'react'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {UPDATE_USER_DISCUSSION_SPLITSCREEN_PREFERENCE} from '../../../graphql/Mutations'
import {useMutation} from 'react-apollo'
import {useScope as useI18nScope} from '@canvas/i18n'
import {AllThreadsState, SearchContext} from '../../utils/constants'

const I18n = useI18nScope('discussions_posts')

export const SplitScreenButton = ({
  setUserSplitScreenPreference,
  userSplitScreenPreference,
  display,
  ...props
}) => {
  const {setOnFailure, setOnSuccess} = useContext(AlertManagerContext)
  const {setAllThreadsStatus, setExpandedThreads} = useContext(SearchContext)

  const [updateUserDiscussionsSplitscreenView] = useMutation(
    UPDATE_USER_DISCUSSION_SPLITSCREEN_PREFERENCE,
    {
      onCompleted: data => {
        setOnSuccess('Splitscreen preference updated!')
        setUserSplitScreenPreference(
          data?.updateUserDiscussionsSplitscreenView?.user?.discussionsSplitscreenView ||
            !userSplitScreenPreference
        )
      },
      onError: () => {
        setOnFailure(I18n.t('Unable to update splitscreen preference.'))
        setUserSplitScreenPreference(!userSplitScreenPreference)
      },
    }
  )

  const onSplitScreenClick = () => {
    // We are safe to assume the response, because regardless of the mutation success we still act.
    // Also this way we dont need to worry about setState delay
    // Logic: if userSplitScreenPreference currently true, then it will be false, which means closeView.
    if (userSplitScreenPreference) {
      props.closeView()
    } else {
      setExpandedThreads([])
      setAllThreadsStatus(AllThreadsState.Collapsed)

      setTimeout(() => {
        setAllThreadsStatus(AllThreadsState.None)
      }, 0)
    }
    updateUserDiscussionsSplitscreenView({
      variables: {discussionsSplitscreenView: !userSplitScreenPreference},
    })
  }

  return (
    <Button onClick={onSplitScreenClick} data-testid="splitscreenButton" display={display}>
      {userSplitScreenPreference ? I18n.t('View Inline') : I18n.t('View Split Screen')}
      <ScreenReaderContent>
        {userSplitScreenPreference ? I18n.t('View Inline') : I18n.t('View Split Screen')}
      </ScreenReaderContent>
    </Button>
  )
}

SplitScreenButton.propTypes = {
  setUserSplitScreenPreference: PropTypes.func,
  userSplitScreenPreference: PropTypes.bool,
  setExpandReplies: PropTypes.func,
  closeView: PropTypes.func,
  display: PropTypes.string,
}
