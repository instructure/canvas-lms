/*
 * Copyright (C) 2018 - present Instructure, Inc.
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
import PropTypes from 'prop-types'
import Button from '@instructure/ui-buttons/lib/components/Button'
import CloseButton from '@instructure/ui-buttons/lib/components/CloseButton'
import Heading from '@instructure/ui-elements/lib/components/Heading'
import TextArea from '@instructure/ui-forms/lib/components/TextArea'
import IconFeedback from '@instructure/ui-icons/lib/Line/IconFeedback'
import Modal, { ModalBody, ModalFooter, ModalHeader } from '@instructure/ui-overlays/lib/components/Modal'
import ScreenReaderContent from '@instructure/ui-a11y/lib/components/ScreenReaderContent'
import I18n from 'i18n!edit_rubric'

const CommentDialog = React.createClass({
  propTypes: {
    comments: PropTypes.string.isRequired,
    description: PropTypes.string.isRequired,
    finalize: PropTypes.func.isRequired,
    open: PropTypes.bool.isRequired,
    setComments: PropTypes.func.isRequired
  },

  render() {
    const { comments, description, finalize, open, setComments } = this.props
    const modalHeader = I18n.t('Additional Comments')
    const close = () => finalize(false)

    return (
      <Modal
         open={open}
         onDismiss={close}
         size="medium"
         label={modalHeader}
         defaultFocusElement={() => this.textArea}
         shouldCloseOnDocumentClick
      >
        <ModalHeader>
          <CloseButton
            placement="end"
            offset="medium"
            variant="icon"
            onClick={close}
          >
            {I18n.t('Close')}
          </CloseButton>
          <Heading>{modalHeader}</Heading>
          <Heading level="h3">{description}</Heading>
        </ModalHeader>
        <ModalBody>
          <TextArea
            label={I18n.t('Comments')}
            maxHeight='50rem'
            onChange={(e) => setComments(e.target.value)}
            value={comments}
            ref={(node) => { this.textArea = node }}
          />
        </ModalBody>
        <ModalFooter>
          <Button variant="light" margin="0 x-small 0 0" onClick={close}>
            {I18n.t('Cancel')}
          </Button>
          &nbsp;
          <Button variant="primary" margin="0 x-small 0 0" onClick={() => finalize(true)}>
            {I18n.t('Update Comment')}
          </Button>
        </ModalFooter>
      </Modal>
    )
  }
})

const CommentButton = ({ initialize, ...props }) => (
  <div>
    <Button variant="icon" icon={<IconFeedback />} margin="0 x-small 0 0" onClick={() => initialize()}>
      <ScreenReaderContent>{I18n.t('Additional Comments')}</ScreenReaderContent>
    </Button>
    <CommentDialog {...props} />
  </div>
)
CommentButton.propTypes = {
  comments: PropTypes.string,
  description: PropTypes.string.isRequired,
  finalize: PropTypes.func.isRequired,
  initialize: PropTypes.func.isRequired,
  open: PropTypes.bool,
  setComments: PropTypes.func.isRequired
}
CommentButton.defaultProps = {
  open: false,
  comments: ''
}

export default CommentButton
