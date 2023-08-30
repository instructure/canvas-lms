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
import {useScope as useI18nScope} from '@canvas/i18n'
import React, {useRef, useState} from 'react'
import {Modal} from '@instructure/ui-modal'
import {CloseButton, Button} from '@instructure/ui-buttons'
import {Heading} from '@instructure/ui-heading'
import {View} from '@instructure/ui-view'
import PropTypes from 'prop-types'
import {Text} from '@instructure/ui-text'
import {TextInput} from '@instructure/ui-text-input'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import doFetchApi from '@canvas/do-fetch-api-effect'
import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'

const I18n = useI18nScope('add_student_modal')

const AddStudentModal = ({open, handleClose, currentUserId, onStudentPaired}) => {
  const pairingCodeInputRef = useRef(null)
  const [inputMessage, setInputMessage] = useState(null)
  const canvasGuideLinkHtml =
    '<a target="canvas_guides" href="https://community.canvaslms.com/t5/Student-Guide/How-do-I-generate-a-pairing-code-for-an-observer-as-a-student/ta-p/418">$1</a>'

  const showError = error => {
    setInputMessage(error)
    setTimeout(() => {
      setInputMessage([])
    }, 10000)
  }

  const onSubmit = () => {
    const studentCode = pairingCodeInputRef.current.value
    if (studentCode) {
      submitCode(studentCode)
    } else {
      showError([{text: I18n.t('Please provide a pairing code.'), type: 'error'}])
    }
  }

  const submitCode = async studentCode => {
    try {
      const {response} = await doFetchApi({
        method: 'POST',
        path: `/api/v1/users/${currentUserId}/observees`,
        body: {pairing_code: studentCode},
      })
      showFlashAlert({
        message: I18n.t('Student paired successfully'),
        type: 'success',
      })
      if (response.ok) {
        onStudentPaired()
      }
      handleClose()
    } catch (ex) {
      showError([{text: I18n.t('Invalid pairing code.'), type: 'error'}])
      showFlashAlert({
        message: I18n.t('Failed pairing student.'),
        type: 'error',
      })
    }
  }

  return (
    <Modal
      open={open}
      onDismiss={handleClose}
      size="small"
      label={I18n.t('Pair with student')}
      shouldCloseOnDocumentClick={true}
      themeOverride={{smallMaxWidth: '27em'}}
    >
      <Modal.Header>
        <CloseButton
          placement="end"
          offset="small"
          onClick={handleClose}
          screenReaderLabel="Close"
        />
        <Heading>{I18n.t('Pair with student')}</Heading>
      </Modal.Header>
      <Modal.Body>
        <Text>{I18n.t('Enter a student pairing code below to add a student to observe.')}</Text>
        <View as="div" padding="small 0 x-small 0">
          <TextInput
            data-testid="pairing-code-input"
            messages={inputMessage}
            renderLabel={<ScreenReaderContent>{I18n.t('Pairing code')}</ScreenReaderContent>}
            inputRef={el => {
              pairingCodeInputRef.current = el
            }}
            placeholder={I18n.t('Pairing code')}
            onChange={() => {
              if (inputMessage) setInputMessage([])
            }}
          />
        </View>
        <View
          as="div"
          display="inline-block"
          dangerouslySetInnerHTML={{
            __html: I18n.t('Visit *Canvas Guides* to learn more.', {
              wrappers: [canvasGuideLinkHtml],
            }),
          }}
        />
      </Modal.Body>
      <Modal.Footer>
        <Button data-testid="close-modal" onClick={handleClose} margin="0 x-small 0 0">
          {I18n.t('Close')}
        </Button>
        <Button data-testid="add-student-btn" onClick={onSubmit} color="primary">
          {I18n.t('Pair')}
        </Button>
      </Modal.Footer>
    </Modal>
  )
}

AddStudentModal.propTypes = {
  open: PropTypes.bool.isRequired,
  handleClose: PropTypes.func.isRequired,
  currentUserId: PropTypes.string.isRequired,
  onStudentPaired: PropTypes.func.isRequired,
}

export default AddStudentModal
