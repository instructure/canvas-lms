/*
 * Copyright (C) 2023 - present Instructure, Inc.
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
import {Button, CloseButton} from '@instructure/ui-buttons'
// @ts-expect-error
import {IconUserSolid} from '@instructure/ui-icons'
import {Heading} from '@instructure/ui-heading'
// @ts-expect-error
import {Modal} from '@instructure/ui-modal'
import {View} from '@instructure/ui-view'
import {Text} from '@instructure/ui-text'
// @ts-expect-error
import {TextArea} from '@instructure/ui-text-area'
import {TextInput} from '@instructure/ui-text-input'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {Link} from '@instructure/ui-link'
import {Avatar} from '@instructure/ui-avatar'
import {Flex} from '@instructure/ui-flex'

const I18n = useI18nScope('enhanced_individual_gradebook')

const {Header: ModalHeader, Body: ModalBody} = Modal as any

const {Item: FlexItem} = Flex as any

type Props = {
  modalOpen: boolean
  handleClose: () => void
}

export default function SubmissionDetailModal({modalOpen, handleClose}: Props) {
  // Sample Data
  const studentName = 'Sample Student'
  const assignmentName = 'Sample Assignment'
  const submissionDate = 'Jun 7 at 9:46am'
  const comments = [
    {id: 1, author: 'Sample Teacher 1', date: '2021-01-01', comment: 'Sample Comment 1'},
    {id: 2, author: 'Sample Teacher 2', date: '2021-01-02', comment: 'Sample Comment 2'},
    {id: 3, author: 'Sample Teacher 3', date: '2021-01-03', comment: 'Sample Comment 3'},
  ]

  return (
    <Modal
      open={modalOpen}
      onDismiss={() => {}}
      size="small"
      label="Student Submission Detail Modal"
      shouldCloseOnDocumentClick={false}
    >
      <ModalHeader>
        <CloseButton
          placement="end"
          offset="small"
          onClick={() => handleClose()}
          screenReaderLabel="Close Submission Detail"
        />
        <Heading level="h4">{studentName}</Heading>
      </ModalHeader>
      <ModalBody padding="none">
        <View as="div" padding="medium medium 0 medium">
          <Heading level="h3">{assignmentName}</Heading>
        </View>

        <View as="div" margin="small 0" padding="0 medium">
          <Flex>
            <FlexItem shouldGrow={true} shouldShrink={true}>
              <Text>{I18n.t('Grade:')} </Text>
              <View as="span" margin="0 x-small 0 x-small">
                <TextInput
                  renderLabel={
                    <ScreenReaderContent>{I18n.t('Submission Score')}</ScreenReaderContent>
                  }
                  display="inline-block"
                  width="4rem"
                />
              </View>
              <Text>{I18n.t('out of (score)')}</Text>
            </FlexItem>
            <FlexItem align="start">
              <Button>{I18n.t('Update Grade')}</Button>
            </FlexItem>
          </Flex>
        </View>

        <View as="div" margin="small 0" padding="0 medium">
          <Link href="http://instructure.design" isWithinText={false}>
            {I18n.t('More details in the SpeedGrader')}
          </Link>
        </View>

        <View as="div" margin="small 0" padding="0 medium">
          <View as="b">
            {I18n.t('Submitted:')} {submissionDate}
          </View>
        </View>

        {comments.length > 0 && (
          <View as="div" margin="small 0" padding="0 medium">
            <Heading level="h3">{I18n.t('Comments')}</Heading>

            <View as="div" margin="small 0" maxHeight="9rem" overflowX="auto">
              {comments.map((comment, index) => (
                <View as="div" key={comment.id}>
                  <Flex alignItems="start">
                    <FlexItem>
                      <Avatar name="user" renderIcon={<IconUserSolid />} color="ash" />
                    </FlexItem>
                    <FlexItem shouldGrow={true} shouldShrink={true} padding="0 0 0 small">
                      <Heading level="h5">
                        <Link href="#" isWithinText={false}>
                          {comment.author}
                        </Link>
                      </Heading>
                      <Text size="small">{comment.comment}</Text>
                    </FlexItem>
                    <FlexItem align="start">
                      <Heading level="h5">{comment.date}</Heading>
                    </FlexItem>
                  </Flex>
                  {index < comments.length - 1 && (
                    <hr key="hrcomment-{comment.id}" style={{margin: '.6rem 0'}} />
                  )}
                </View>
              ))}
            </View>
            {/* <a href="http://canvas.docker/courses/1/users/3" className="fs-exclude avatar" style={{"backgroundImage": "url(http://canvas.instructure.com/images/messages/avatar-50.png)"}}>
                <span className="screenreader-only">Jim Halpert</span>
                </a>
              <a href="{{media_comment.url}}" className="play_comment_link media-comment instructure_inline_media_comment">
                click here to view
              </a> */}
          </View>
        )}

        <div style={{backgroundColor: '#F2F2F2', borderTop: '1px solid #bbb'}}>
          <View as="div" padding="small medium">
            <TextArea label={I18n.t('Add a comment')} maxHeight="4rem" />
            <View as="div" margin="small 0 0 0" textAlign="end">
              <Button>{I18n.t('Post Comment')}</Button>
            </View>
          </View>
        </div>
      </ModalBody>
    </Modal>
  )
}
