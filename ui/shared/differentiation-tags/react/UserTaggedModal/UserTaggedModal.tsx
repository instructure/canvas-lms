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

import React, {useState, useEffect, useRef} from 'react'
import {useUserTags} from '../hooks/useUserTags'
import {Flex} from '@instructure/ui-flex'
import {Heading} from '@instructure/ui-heading'
import {Spinner} from '@instructure/ui-spinner'
import {Text} from '@instructure/ui-text'
import {Tag} from '@instructure/ui-tag'
import {AccessibleContent} from '@instructure/ui-a11y-content'
import {Modal} from '@instructure/ui-modal'
import {CloseButton} from '@instructure/ui-buttons'
import {RemoveTagWarningModal} from '../WarningModal'
import {useScope as createI18nScope} from '@canvas/i18n'
import {useDeleteTagMembership} from '../hooks/useDeleteTagMembership'
import {Alert} from '@instructure/ui-alerts'
import MessageBus from '@canvas/util/MessageBus'
import {QueryClientProvider} from '@tanstack/react-query'
import {queryClient} from '@canvas/query'

const I18n = createI18nScope('differentiation_tags')

export interface UserTaggedModalProps {
  isOpen: boolean
  courseId: number
  userId: number
  userName: string
  onClose: (userId: number, userName: string) => void
}

function UserTagModalContainer(props: UserTaggedModalProps) {
  const {isOpen, courseId, userId, userName, onClose} = props
  const [isWarningModalOpen, setIsWarningModalOpen] = useState(false)
  const [selectedTagId, setSelectedTagId] = useState<number>(0)
  const {
    mutate,
    isPending: isDeleting,
    isSuccess,
    isError,
    error: errorDelete,
  } = useDeleteTagMembership()
  const {data: userTagList, isPending, error, refetch} = useUserTags(courseId, userId)
  const tagRefs = useRef<Tag[]>([])
  const removeTagMembership = (userId: number, selectedTagId: number) => {
    mutate({groupId: selectedTagId, userId, refetch})
    setIsWarningModalOpen(false)
  }
  useEffect(() => {
    if (userTagList && userTagList?.length === 0) {
      MessageBus.trigger('removeUserTagIcon', {userId})
    }
    if (isSuccess && userTagList && userTagList?.length > 0) {
      delete tagRefs.current[selectedTagId]
      tagRefs.current[userTagList[0].id]?.focus()
    }
  }, [userTagList]) // eslint-disable-line react-hooks/exhaustive-deps

  const shouldLimitModalHeight = userTagList && userTagList.length >= 10

  return (
    <>
      <Modal
        open={isOpen}
        size="small"
        label={I18n.t('User Tags Modal')}
        data-testid="user-tag-modal"
      >
        <Modal.Header>
          <Heading>{I18n.t('%{name} is tagged as', {name: userName})}</Heading>
          <CloseButton
            data-testid="modal-close-button"
            placement="end"
            offset="small"
            onClick={() => onClose(userId, userName)}
            type="button"
            as="button"
            screenReaderLabel={I18n.t('Close the user tags modal')}
          />
        </Modal.Header>
        <Modal.Body data-testid="user-tags-scrollable-container">
          <Flex
            as="div"
            alignItems="start"
            justifyItems="start"
            gap="none"
            direction="column"
            width="100%"
            height={shouldLimitModalHeight ? '20rem' : 'auto'}
          >
            {isSuccess && (
              <Alert
                variant="success"
                renderCloseButtonLabel={I18n.t('Close')}
                timeout={3000}
                liveRegion={() =>
                  document.getElementById('flash_screenreader_holder') as HTMLElement
                }
                liveRegionPoliteness="polite"
              >
                {I18n.t('Tag removed successfully')}
              </Alert>
            )}
            {isError && (
              <Alert
                variant="error"
                timeout={5000}
                liveRegion={() =>
                  document.getElementById('flash_screenreader_holder') as HTMLElement
                }
                liveRegionPoliteness="assertive"
              >
                {I18n.t('Error:')} {errorDelete.message}
              </Alert>
            )}
            {isPending ? (
              <Flex.Item shouldGrow shouldShrink margin="medium">
                <Spinner renderTitle={I18n.t('Loading...')} size="small" />
              </Flex.Item>
            ) : error ? (
              <Flex.Item shouldGrow shouldShrink margin="medium">
                <Text color="danger">
                  {I18n.t('An error occurred while loading the Modal:')} {error.message}
                </Text>
              </Flex.Item>
            ) : isDeleting ? (
              <Flex.Item shouldGrow shouldShrink margin="medium">
                <Spinner renderTitle={I18n.t('Removing user from tag...')} size="small" />
              </Flex.Item>
            ) : userTagList?.length === 0 ? (
              <Flex.Item shouldGrow shouldShrink margin="medium">
                <Text>{I18n.t('No tags available for this user')}</Text>
              </Flex.Item>
            ) : (
              <Flex
                direction="column"
                padding={shouldLimitModalHeight ? 'none none medium none' : 'none'}
                width="100%"
              >
                {(userTagList || []).map(tag => (
                  <Flex.Item
                    key={`tag-flex-${tag.id}`}
                    margin="0"
                    overflowY="hidden"
                    overflowX="hidden"
                    padding="xx-small"
                  >
                    <Tag
                      ref={el => el && (tagRefs.current[tag.id] = el)}
                      data-testid={`user-tag-${tag.id}`}
                      text={
                        <AccessibleContent
                          alt={I18n.t('Remove %{tag}', {
                            tag: tag.isSingleTag
                              ? tag.groupCategoryName
                              : `${tag.groupCategoryName} | ${tag.name}`,
                          })}
                        >
                          {tag.isSingleTag
                            ? tag.groupCategoryName
                            : `${tag.groupCategoryName} | ${tag.name}`}
                        </AccessibleContent>
                      }
                      dismissible={true}
                      margin="auto"
                      size="medium"
                      onClick={function () {
                        setSelectedTagId(tag.id)
                        setIsWarningModalOpen(true)
                      }}
                      themeOverride={{
                        maxWidth: '100%',
                      }}
                    />
                  </Flex.Item>
                ))}
              </Flex>
            )}
          </Flex>
        </Modal.Body>
        <Modal.Footer />
      </Modal>
      <RemoveTagWarningModal
        open={isWarningModalOpen}
        onClose={() => setIsWarningModalOpen(false)}
        onContinue={() => removeTagMembership(userId, selectedTagId)}
      />
    </>
  )
}

export default function UserTaggedModal(props: UserTaggedModalProps) {
  return (
    <QueryClientProvider client={queryClient}>
      <UserTagModalContainer {...props} />
    </QueryClientProvider>
  )
}
