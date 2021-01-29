/*
 * Copyright (C) 2020 - present Instructure, Inc.
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

import {ComposeActionButtons} from 'jsx/canvas_inbox/components/ComposeActionButtons/ComposeActionButtons'
import {ComposeInputWrapper} from 'jsx/canvas_inbox/components/ComposeInputWrapper/ComposeInputWrapper'
import {CourseSelect} from 'jsx/canvas_inbox/components/CourseSelect/CourseSelect'
import I18n from 'i18n!conversations_2'
import {IndividualMessageCheckbox} from 'jsx/canvas_inbox/components/IndividualMessageCheckbox/IndividualMessageCheckbox'
import {MessageBody} from 'jsx/canvas_inbox/components/MessageBody/MessageBody'
import PropTypes from 'prop-types'
import React from 'react'
import {SubjectInput} from 'jsx/canvas_inbox/components/SubjectInput/SubjectInput'

import {CloseButton} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {Heading} from '@instructure/ui-heading'
import {Modal} from '@instructure/ui-modal'
import {PresentationContent} from '@instructure/ui-a11y-content'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'

const ComposeModalContainer = props => {
  const renderModalHeader = () => (
    <Modal.Header>
      <CloseButton
        placement="end"
        offset="small"
        onClick={props.onDismiss}
        screenReaderLabel={I18n.t('Close')}
      />
      <Heading>{I18n.t('Compose Message')}</Heading>
    </Modal.Header>
  )

  const renderModalBody = () => (
    <Modal.Body padding="none">
      <Flex direction="column" width="100%" height="100%">
        {renderHeaderInputs()}
        <View borderWidth="small none none none" padding="x-small">
          <MessageBody onBodyChange={() => {}} />
        </View>
      </Flex>
    </Modal.Body>
  )

  const renderHeaderInputs = () => (
    <Flex direction="column" width="100%" height="100%" padding="small">
      <Flex.Item>
        <ComposeInputWrapper
          title={
            <PresentationContent>
              <Text size="small">{I18n.t('Course')}</Text>
            </PresentationContent>
          }
          input={renderCourseSelect()}
          shouldGrow={false}
        />
      </Flex.Item>
      <SubjectInput onChange={() => {}} value="" />
      <Flex.Item>
        <ComposeInputWrapper
          shouldGrow
          input={<IndividualMessageCheckbox onChange={() => {}} checked={false} />}
        />
      </Flex.Item>
    </Flex>
  )

  const renderCourseSelect = () => (
    <CourseSelect
      mainPage={false}
      options={{
        favoriteCourses: [],
        moreCourses: [],
        concludedCourses: [],
        groups: []
      }}
      onCourseFilterSelect={() => {}}
    />
  )

  const renderModalFooter = () => (
    <Modal.Footer>
      <ComposeActionButtons
        onAttachmentUpload={() => {}}
        onMediaUpload={() => {}}
        onCancel={props.onDismiss}
        onSend={() => {
          console.log('submitting...')
        }}
        isSending={false}
      />
    </Modal.Footer>
  )

  return (
    <Modal
      as="form"
      open={props.open}
      onDismiss={props.onDismiss}
      size="medium"
      label={I18n.t('Compose Message')}
      shouldCloseOnDocumentClick={false}
    >
      {renderModalHeader()}
      {renderModalBody()}
      {renderModalFooter()}
    </Modal>
  )
}

export default ComposeModalContainer

ComposeModalContainer.propTypes = {
  open: PropTypes.bool,
  onDismiss: PropTypes.func
}
