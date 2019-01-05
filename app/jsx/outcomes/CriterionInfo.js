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
import ReactDOM from 'react-dom'
import ScreenReaderContent from '@instructure/ui-a11y/lib/components/ScreenReaderContent'
import Button from '@instructure/ui-buttons/lib/components/Button'
import CloseButton from '@instructure/ui-buttons/lib/components/CloseButton'
import Heading from '@instructure/ui-elements/lib/components/Heading'
import Text from '@instructure/ui-elements/lib/components/Text'
import IconQuestion from '@instructure/ui-icons/lib/Line/IconQuestion'
import Modal, { ModalHeader, ModalBody } from '@instructure/ui-overlays/lib/components/Modal'
import I18n from 'i18n!outcomes'

const spiel = () => I18n.t(`
Learning outcomes can be included in assignment rubrics as an easy way to assess
mastery of outcomes aligned to specific assignments.  When you define a learning
outcome, you should also define a criterion that can be used when building
assignment rubrics.  Define as many rubric columns as you need, and specify a
point threshold that will be used to define mastery of this outcome.
`)

export default class CriterionInfo extends React.Component {
  constructor (props) {
    super(props)

    this.state = {
      open: false
    }
  }

  handleButtonClick = () => {
    this.setState((state) => ({ open: !state.open }))
  }

  renderCloseButton () {
    return (
      <CloseButton
        placement="end"
        offset="medium"
        variant="icon"
        onClick={this.handleButtonClick}
      >
        {I18n.t('Close')}
      </CloseButton>
    )
  }

  renderModal () {
    if (this.state.open) {
      return (
        <Modal
          as="form"
          open={this.state.open}
          onDismiss={() => { this.setState({ open: false }) }}
          size='medium'
          label={I18n.t('Criterion Ratings')}
          shouldCloseOnDocumentClick
        >
          <ModalHeader>
            {this.renderCloseButton()}
            <Heading>{I18n.t('Criterion Ratings')}</Heading>
          </ModalHeader>
          <ModalBody>
            <Text lineHeight="double">{spiel()}</Text>
          </ModalBody>
        </Modal>
      )
    }
  }

  render () {
    return (
      <span>
        <Button
          variant="icon"
          icon={<IconQuestion />}
          onClick={this.handleButtonClick}
        >
          <ScreenReaderContent>{I18n.t('More Information About Ratings')}</ScreenReaderContent>
        </Button>
        {this.renderModal()}
      </span>
    )
  }
}

export const addCriterionInfoButton = (element) => {
  ReactDOM.render(<CriterionInfo />, element)
}
