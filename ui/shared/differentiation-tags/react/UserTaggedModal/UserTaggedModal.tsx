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

import React, {useState} from 'react'
import {QueryProvider} from '@canvas/query'
import {useUserTags} from '../hooks/useUserTags'
import {View} from '@instructure/ui-view'
import {Flex} from '@instructure/ui-flex'
import {Heading} from '@instructure/ui-heading'
import {Spinner} from '@instructure/ui-spinner'
import {Text} from '@instructure/ui-text'
import {Tag} from "@instructure/ui-tag"
import {AccessibleContent} from '@instructure/ui-a11y-content'
import {Modal} from '@instructure/ui-modal'
import {CloseButton} from '@instructure/ui-buttons'
import {DeleteTagWarningModal} from '../WarningModal'
import {useScope as createI18nScope} from '@canvas/i18n'


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
  const {
    data: userTagList,
    isLoading,
    error,
  } = useUserTags(courseId, userId)

  return (
    <View id="user-tag-modal-container" width="100%" display="block">
      <Modal
        open={isOpen}
        size="small"
        label="User Tags Modal"
        shouldCloseOnDocumentClick={false}
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
            screenReaderLabel={I18n.t("Close the user tags modal")}
          />
        </Modal.Header>
        <Modal.Body>
          {isLoading ? (
            <Flex.Item shouldGrow shouldShrink margin="medium">
              <Spinner renderTitle={I18n.t('Loading...')} size="small" />
            </Flex.Item>
          ) : error ? (
            <Flex.Item shouldGrow shouldShrink margin="medium">
              <Text color="danger">
                {I18n.t('An error occurred while loading the Modal:')} {error.message}
              </Text>
            </Flex.Item>
          ) : userTagList.length === 0 ? (
            <Flex.Item shouldGrow shouldShrink margin="medium">
              <Text>{I18n.t('No tags available for this user')}</Text>
            </Flex.Item>
          ) : (
              userTagList.map( tag =>(
                <Flex.Item key={`tag-flex-${tag.id}`} shouldGrow shouldShrink margin="medium">
                  <Tag
                    data-testid={`user-tag-${tag.id}`}
                    text={
                      <AccessibleContent alt="Remove dismissible tag">
                        {`${tag.groupCategoryName} | ${tag.name}`}
                      </AccessibleContent>
                    }
                    dismissible
                    margin="auto"
                    size="medium"
                    onClick={function () {
                      setIsWarningModalOpen(true)
                    }}
                    themeOverride={{
                      maxWidth: '100%'
                    }}
                    />
                </Flex.Item>
              ))
            )}
        </Modal.Body>
        <Modal.Footer>
        </Modal.Footer>
      </Modal>
      <DeleteTagWarningModal
        open={isWarningModalOpen}
        onClose={() => setIsWarningModalOpen(false)}
        onContinue={() => setIsWarningModalOpen(false)}
      />
    </View>
  )
}

export default function UserTaggedModal(props: UserTaggedModalProps) {
  return (
    <QueryProvider>
      <UserTagModalContainer {...props} />
    </QueryProvider>
  )
}
