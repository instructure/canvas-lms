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

import React, {useContext, useState, useMemo} from 'react'
import {Modal} from '@instructure/ui-modal'
import {Button, CloseButton, type ButtonProps} from '@instructure/ui-buttons'
import {Heading} from '@instructure/ui-heading'
import ManageThreadedRepliesAlert from './ManageThreadedRepliesAlert'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Flex} from '@instructure/ui-flex'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
import DiscussionTable from './DiscussionTable'
import {useManageThreadedRepliesStore} from '../../hooks/useManageThreadedRepliesStore'
import {gql, useQuery} from '@apollo/client'
import {AlertManagerContext} from '@canvas/alerts/react/AlertManager'
import {updateDiscussionTopicTypes} from '../../apiClient'
import {Alert} from '@instructure/ui-alerts'

const I18n = createI18nScope('discussions_v2')

const QUERY = gql`
  query GetCourseName($courseId: ID!) {
    legacyNode(_id: $courseId, type: Course) {
      ... on Course {
        _id
        name
      }
    } 
  }
`

const BOTTOM_BUTTONS: {
  id: 'cancel' | 'confirm'
  label: string
  color: ButtonProps['color']
}[] = [
  {
    id: 'cancel',
    label: I18n.t('Cancel'),
    color: 'secondary',
  },
  {
    id: 'confirm',
    label: I18n.t('Confirm'),
    color: 'primary',
  },
]

export type DTRDiscussion = {
  id: string
  title: string
  isPublished: boolean
  isAssignment: boolean
  lastReplyAt: string | null
}

interface ManageThreadedRepliesProps {
  mobileOnly?: boolean
  courseId: string
  discussions: Partial<DTRDiscussion>[] // using Partial as the parent component doesn't use typescript
}

const ManageThreadedReplies: React.FC<ManageThreadedRepliesProps> = ({
  courseId,
  discussions: _discussions,
  mobileOnly,
}) => {
  const [isOpen, setIsOpen] = useState(false)
  const initialize = useManageThreadedRepliesStore(state => state.initialize)
  const discussionStates = useManageThreadedRepliesStore(state => state.discussionStates)
  const setModalClose = useManageThreadedRepliesStore(state => state.setModalClose)
  const isLoading = useManageThreadedRepliesStore(state => state.loading)
  const validate = useManageThreadedRepliesStore(state => state.validate)
  const errorCount = useManageThreadedRepliesStore(state => state.errorCount)
  const isDirty = useManageThreadedRepliesStore(state => state.isDirty)

  const {setOnSuccess, setOnFailure} = useContext(AlertManagerContext)

  const discussions = useMemo(
    () => _discussions?.filter((d): d is DTRDiscussion => !!d?.id) || [],
    [_discussions],
  )
  const {data} = useQuery(QUERY, {
    variables: {courseId},
  })

  const courseName = data?.legacyNode?.name || ''

  const handleOpen = () => {
    initialize(discussions.map(d => d.id))
    setIsOpen(true)
  }

  const handleClose = () => {
    setIsOpen(false)
    setModalClose()
  }

  const handleSave = async () => {
    if (!validate()) {
      return
    }

    const threaded: string[] = []
    const notThreaded: string[] = []

    Object.entries(discussionStates).forEach(([d, type]) => {
      if (type === 'threaded') {
        threaded.push(d)
      } else if (type === 'not_threaded') {
        notThreaded.push(d)
      }
    })

    try {
      const response = await updateDiscussionTopicTypes({
        contextId: ENV.COURSE_ID,
        threaded,
        notThreaded,
      })

      if (response.data.success === 'true') {
        setModalClose(true)
        setOnSuccess(I18n.t('Discussions updated successfully.'), false)
      } else {
        setModalClose(false)
        setOnFailure(I18n.t('Failed to update discussions.'), false)
      }
    } catch (_error) {
      setModalClose(false)
      setOnFailure(I18n.t('Failed to update discussions.'), false)
    } finally {
      setIsOpen(false)
    }
  }

  const bottomButtons = mobileOnly ? BOTTOM_BUTTONS.toReversed() : BOTTOM_BUTTONS

  return (
    <>
      <Modal
        label={I18n.t('Manage Discussions')}
        size="fullscreen"
        open={isOpen}
        onDismiss={handleClose}
      >
        <Modal.Header>
          <View as="div" maxWidth="1006px" margin="0 auto" padding={mobileOnly ? '0' : '0 x-small'}>
            <Flex justifyItems="space-between">
              <Heading>{I18n.t('Manage Discussions')}</Heading>
              <CloseButton
                offset="small"
                screenReaderLabel={I18n.t('Close')}
                onClick={handleClose}
              />
            </Flex>
          </View>
        </Modal.Header>
        <Modal.Body padding="0">
          <View maxWidth="1006px" as="div" margin="0 auto" padding={mobileOnly ? '0' : '0 x-small'}>
            <View
              as="div"
              margin={
                mobileOnly
                  ? 'mediumSmall mediumSmall medium mediumSmall'
                  : 'mediumSmall 0 x-large 0'
              }
            >
              <View
                as="div"
                margin="0 0 small 0"
                dangerouslySetInnerHTML={{
                  __html: I18n.t(
                    "Please set all Discussions to either *'Threaded'* or *'Not threaded'*. Use the *'Set to Threaded'* and *'Set to Not threaded'* actions to bulk update multiple selected Discussions. Use the dropdown menus to decide on individual Discussions.",
                    {
                      wrappers: [`<i>$1</i>`],
                    },
                  ),
                }}
              />
              {!isDirty && (
                <Alert variant="info">
                  {I18n.t('A selection is required for every Discussion')}
                </Alert>
              )}
              {isDirty && errorCount > 0 && (
                <Alert variant="error">
                  {I18n.t('Please select an option for the indicated Discussions')}
                </Alert>
              )}
            </View>
            <View
              as="div"
              margin={mobileOnly ? '0 mediumSmall medium mediumSmall' : '0 0 medium 0'}
            >
              <Flex
                justifyItems="space-between"
                direction={mobileOnly ? 'column' : 'row'}
                gap={mobileOnly ? 'small' : '0'}
              >
                <Flex.Item>
                  <Text weight="bold" size="large">
                    {I18n.t('Discussions in %{courseName}', {courseName})}
                  </Text>
                </Flex.Item>
                <Flex.Item>
                  <Flex direction={mobileOnly ? 'row-reverse' : 'row'} gap="small">
                    {isDirty && errorCount > 0 && (
                      <Flex.Item>
                        <Text size="small" color="danger">
                          {I18n.t('%{count} Not decided', {count: errorCount})}
                        </Text>
                      </Flex.Item>
                    )}
                    <Flex.Item>
                      <Text size="small" color="secondary">
                        {I18n.t(
                          {
                            one: '1 Discussion',
                            other: '%{count} Discussions',
                          },
                          {count: discussions.length},
                        )}
                      </Text>
                    </Flex.Item>
                  </Flex>
                </Flex.Item>
              </Flex>
            </View>
            <DiscussionTable mobileOnly={!!mobileOnly} discussions={discussions} />
          </View>
        </Modal.Body>
        <Modal.Footer>
          <View
            as="div"
            maxWidth="1006px"
            width="100%"
            margin="0 auto"
            padding={mobileOnly ? '0' : '0 x-small'}
          >
            <Flex
              gap="small"
              direction={mobileOnly ? 'column' : 'row'}
              justifyItems={mobileOnly ? 'center' : 'end'}
              width="100%"
            >
              {bottomButtons.map(button => (
                <Button
                  width={mobileOnly ? '100%' : 'auto'}
                  key={button.id}
                  id={`manage-threaded-replies-${button.id}`}
                  color={button.color}
                  disabled={button.id === 'confirm' && isLoading}
                  onClick={button.id === 'cancel' ? handleClose : handleSave}
                >
                  {button.label}
                </Button>
              ))}
            </Flex>
          </View>
        </Modal.Footer>
      </Modal>
      <ManageThreadedRepliesAlert onOpen={handleOpen} />
    </>
  )
}

export default ManageThreadedReplies
