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

import {AlertManagerContext} from '@canvas/alerts/react/AlertManager'
import {CloseButton} from '@instructure/ui-buttons'
import {DISCUSSION_SUBENTRIES_QUERY} from '../../../graphql/Queries'
import {DiscussionEdit} from '../../components/DiscussionEdit/DiscussionEdit'
import {Flex} from '@instructure/ui-flex'
import {Heading} from '@instructure/ui-heading'
import I18n from 'i18n!discussion_topics_post'
import {IsolatedThreadsContainer} from '../IsolatedThreadsContainer/IsolatedThreadsContainer'
import {IsolatedParent} from './IsolatedParent'
import LoadingIndicator from '@canvas/loading-indicator'
import {ISOLATED_VIEW_MODES, PER_PAGE} from '../../utils/constants'
import PropTypes from 'prop-types'
import React, {useContext} from 'react'
import {Tray} from '@instructure/ui-tray'
import {useQuery} from 'react-apollo'
import {View} from '@instructure/ui-view'

export const IsolatedViewContainer = props => {
  const {setOnFailure} = useContext(AlertManagerContext)

  const isolatedEntry = useQuery(DISCUSSION_SUBENTRIES_QUERY, {
    variables: {
      discussionEntryID: props.discussionEntryId,
      page: btoa(0),
      perPage: PER_PAGE,
      sort: 'desc',
      courseID: window.ENV?.course_id
    }
  })

  if (isolatedEntry.error) {
    setOnFailure(I18n.t('There was an unexpected error loading the discussion entry.'))
    props.onClose()
    return null
  }

  return (
    <Tray
      open={props.open}
      placement="end"
      size="medium"
      offset="large"
      label="Isolated View"
      shouldCloseOnDocumentClick
      onDismiss={e => {
        // When the RCE is open, it stills the mouse position when using it and we do this trick
        // to avoid the whole Tray getting closed because of a click inside the RCE area.
        if (
          props.mode === ISOLATED_VIEW_MODES.REPLY_TO_ROOT_ENTRY &&
          e.clientY - e.target.offsetTop === 0
        ) {
          return
        }

        if (props.onClose) {
          props.onClose()
        }
      }}
    >
      <Flex>
        <Flex.Item shouldGrow shouldShrink>
          <Heading margin="medium medium medium" theme={{h2FontWeight: 700}}>
            Thread
          </Heading>
        </Flex.Item>
        <Flex.Item>
          <CloseButton
            placement="end"
            offset="small"
            screenReaderLabel="Close"
            onClick={() => {
              if (props.onClose) {
                props.onClose()
              }
            }}
          />
        </Flex.Item>
      </Flex>
      {isolatedEntry.loading ? (
        <LoadingIndicator />
      ) : (
        <>
          <IsolatedParent
            discussionEntry={isolatedEntry.data.legacyNode}
            onToggleUnread={() => {}}
            onDelete={() => {}}
            onOpenInSpeedGrader={() => {}}
            onReply={() => {}}
            onToggleRating={() => {}}
          >
            {props.mode === ISOLATED_VIEW_MODES.REPLY_TO_ROOT_ENTRY && (
              <View
                display="block"
                background="primary"
                borderWidth="none none none none"
                padding="none none small none"
                margin="none none x-small none"
              >
                <DiscussionEdit
                  onSubmit={() => {}}
                  onCancel={() => {
                    if (props.onClose) {
                      props.onClose()
                    }
                  }}
                />
              </View>
            )}
          </IsolatedParent>
          {props.mode !== ISOLATED_VIEW_MODES.REPLY_TO_ROOT_ENTRY && (
            <IsolatedThreadsContainer discussionEntry={isolatedEntry.data.legacyNode} />
          )}
        </>
      )}
    </Tray>
  )
}

IsolatedViewContainer.propTypes = {
  discussionEntryId: PropTypes.string,
  open: PropTypes.bool,
  mode: PropTypes.number,
  onClose: PropTypes.func
}
IsolatedViewContainer.defaultProps = {
  mode: ISOLATED_VIEW_MODES.VIEW_ROOT_ENTRY
}

export default IsolatedViewContainer
