// @ts-nocheck
/*
 * Copyright (C) 2017 - present Instructure, Inc.
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
import update from 'immutability-helper'
import {useScope as useI18nScope} from '@canvas/i18n'
import {Button} from '@instructure/ui-buttons'
import Modal from '@canvas/instui-bindings/react/InstuiModal'
import {Text} from '@instructure/ui-text'
import {statuses} from '../constants/statuses'
import StatusColorListItem from './StatusColorListItem'
import type {StatusColors} from '../constants/colors'

const I18n = useI18nScope('gradebook')

const {Body: ModalBody, Footer: ModalFooter} = Modal as any

type Props = {
  onClose: () => void
  colors: StatusColors
  afterUpdateStatusColors: (
    colors: StatusColors,
    successFn: () => void,
    errorFn: any
  ) => Promise<any>
}

type State = {
  colors: StatusColors
  openPopover: null | string
}

class StatusesModal extends React.Component<Props, State> {
  colorPickerButtons: {
    [key: string]: HTMLButtonElement
  }

  colorPickerContents: {
    [key: string]: HTMLDivElement
  }

  doneButton: HTMLButtonElement | null = null

  modalContentRef: HTMLDivElement | null = null

  constructor(props: Props) {
    super(props)

    this.colorPickerButtons = {}
    this.colorPickerContents = {}
    this.state = {colors: props.colors, openPopover: null}
  }

  updateStatusColorsFn =
    (status: string) => (color: string, successFn: () => void, failureFn: () => void) => {
      this.setState(
        prevState => update(prevState, {colors: {$merge: {[status]: color}}}),
        () => {
          const successFnAndClosePopover = () => {
            successFn()
            this.setState({openPopover: null})
          }
          this.props.afterUpdateStatusColors(this.state.colors, successFnAndClosePopover, failureFn)
        }
      )
    }

  isPopoverShown(status: string) {
    return this.state.openPopover === status
  }

  handleOnToggle = (status: string) => (toggle: boolean) => {
    if (toggle) {
      this.setState({openPopover: status})
    } else {
      this.setState({openPopover: null})
    }
  }

  handleColorPickerAfterClose = (status: string) => () => {
    this.setState({openPopover: null}, () => {
      // eslint-disable-next-line react/no-find-dom-node
      const element = ReactDOM.findDOMNode(this.colorPickerButtons[status])
      if (element instanceof HTMLButtonElement) {
        element.focus()
      }
    })
  }

  bindColorPickerButton = (status: string) => button => {
    this.colorPickerButtons[status] = button
  }

  bindColorPickerContent = (status: string) => content => {
    this.colorPickerContents[status] = content
  }

  bindDoneButton = button => {
    this.doneButton = button
  }

  bindContentRef = content => {
    this.modalContentRef = content
  }

  renderListItems() {
    return statuses.map(status => (
      <StatusColorListItem
        key={status}
        status={status}
        color={this.state.colors[status]}
        isColorPickerShown={this.isPopoverShown(status)}
        colorPickerOnToggle={this.handleOnToggle(status)}
        colorPickerButtonRef={this.bindColorPickerButton(status)}
        colorPickerContentRef={this.bindColorPickerContent(status)}
        colorPickerAfterClose={this.handleColorPickerAfterClose(status)}
        afterSetColor={this.updateStatusColorsFn(status)}
      />
    ))
  }

  render() {
    return (
      <Modal
        open={true}
        label={I18n.t('Statuses')}
        onDismiss={this.props.onClose}
        contentRef={this.bindContentRef}
        shouldCloseOnDocumentClick={false}
      >
        <ModalBody>
          <ul className="Gradebook__StatusModalList">
            <Text>{this.renderListItems()}</Text>
          </ul>
        </ModalBody>

        <ModalFooter>
          <Button ref={this.bindDoneButton} color="primary" onClick={() => this.props.onClose()}>
            {I18n.t('Done')}
          </Button>
        </ModalFooter>
      </Modal>
    )
  }
}

export default StatusesModal
