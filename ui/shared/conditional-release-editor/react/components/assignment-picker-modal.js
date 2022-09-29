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

import React from 'react'
import PropTypes from 'prop-types'
import Modal from '@canvas/react-modal'

import ConnectedAssignmentPicker from './assignment-picker'
import {useScope as useI18nScope} from '@canvas/i18n'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {transformScore} from '../score-helpers'

const I18n = useI18nScope('conditional_release')

const {object, bool, func} = PropTypes

class AssignmentPickerModal extends React.Component {
  static get propTypes() {
    return {
      target: object,
      appElement: object,
      isOpen: bool.isRequired,
      onRequestClose: func.isRequired,
      addItemsToRange: func.isRequired,
      triggerAssignment: object,
    }
  }

  constructor() {
    super()
    this.onAfterOpen = this.onAfterOpen.bind(this)
    this.closeBtnRef = React.createRef()
  }

  UNSAFE_componentWillMount() {
    Modal.setAppElement(this.props.appElement)
  }

  onAfterOpen() {
    this.closeBtnRef.current.focus()
  }

  render() {
    const target = this.props.target
    let range = ''

    if (target) {
      const lowerBound = transformScore(
        target.get('lower_bound'),
        this.props.triggerAssignment,
        false
      )
      const upperBound = transformScore(
        target.get('upper_bound'),
        this.props.triggerAssignment,
        true
      )
      range = I18n.t('%{upper} to %{lower}', {
        upper: upperBound,
        lower: lowerBound,
      })
    }

    return (
      <Modal
        className="ReactModal__Content--canvas"
        overlayClassName="ReactModal__Overlay--canvas"
        isOpen={this.props.isOpen}
        onAfterOpen={this.onAfterOpen}
        onRequestClose={this.props.onRequestClose}
      >
        <div className="ReactModal__Layout cr-assignment-modal">
          <header className="ReactModal__Header">
            <div className="ReactModal__Header-Title">
              <span>
                {I18n.t('Add Items Into %{scoring_range_title}', {scoring_range_title: range})}
              </span>
            </div>
            <div className="ReactModal__Header-Actions">
              <button
                ref={this.closeBtnRef}
                className="Button Button--icon-action"
                onClick={this.props.onRequestClose}
                type="button"
              >
                <i aria-hidden={true} className="icon-x" />
                <ScreenReaderContent>{I18n.t('Close')}</ScreenReaderContent>
              </button>
            </div>
          </header>
          <div className="ReactModal__Body">
            <ConnectedAssignmentPicker />
          </div>
          <footer className="ReactModal__Footer">
            <div className="ReactModal__Footer-Actions">
              <button type="button" className="Button" onClick={this.props.onRequestClose}>
                {I18n.t('Cancel')}
              </button>
              <button
                type="button"
                className="Button Button--primary"
                onClick={this.props.addItemsToRange}
              >
                {I18n.t('Add Items')}
              </button>
            </div>
          </footer>
        </div>
      </Modal>
    )
  }
}

export default AssignmentPickerModal
