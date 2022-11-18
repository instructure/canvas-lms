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

import React, {Component} from 'react'
import PropTypes from 'prop-types'
import {TextArea} from '@instructure/ui-text-area'
import {CloseButton, Button} from '@instructure/ui-buttons'
import {Checkbox} from '@instructure/ui-checkbox'
import {Heading} from '@instructure/ui-heading'
import {Modal} from '@instructure/ui-modal'
import {Flex} from '@instructure/ui-flex'
import {debounce} from '@instructure/debounce'
import {ConditionalTooltip} from '../../shared/ConditionalTooltip'

import formatMessage from '../../../../format-message'

import MemoizedEquationEditorToolbar from '../EquationEditorToolbar'
import {containsAdvancedSyntax} from './advancedOnlySyntax'
import advancedPreference from './advancedPreference'

import {css} from 'aphrodite'
import mathml from './mathml'
import styles from './styles'

// Import the <math-field> container and all
// the relevant math fonts from mathlive
import '../mathlive'

export default class EquationEditorModal extends Component {
  static debounceRate = 1000

  state = {
    advanced: this.props.openAdvanced || !!this.props.originalLatex.advancedOnly,
    workingFormula: this.props.originalLatex.latex || '',
  }

  hostPageDisablesShortcuts = null

  previewElement = React.createRef()

  // **************** //
  // Helper functions //
  // **************** //

  insertNewRange() {
    const {editor, originalLatex} = this.props
    const {startContainer, leftIndex, rightIndex} = originalLatex

    if (!startContainer) return

    const range = document.createRange()
    range.setStart(startContainer, leftIndex)
    range.setEnd(startContainer, rightIndex)
    editor.selection.setRng(range)
  }

  advancedModeOnly(latex) {
    const normalizedLatex = latex.replace(/\s+/, '')
    return containsAdvancedSyntax(normalizedLatex)
  }

  usedInCanvas() {
    return typeof ENV !== 'undefined' && ENV && ENV.hasOwnProperty('disable_keyboard_shortcuts')
  }

  // ********* //
  // Callbacks //
  // ********* //

  executeCommand = (cmd, advancedCmd) => {
    if (this.state.advanced) {
      const effectiveCmd = advancedCmd || cmd
      this.setState(state => ({workingFormula: state.workingFormula + effectiveCmd}))
    } else {
      this.mathField.insert(cmd, {focus: 'true'})
    }
  }

  handleModalCancel = () => {
    if (this.usedInCanvas()) {
      // restore the original value
      ENV.disable_keyboard_shortcuts = this.hostPageDisablesShortcuts
    }
    this.props.onModalDismiss()
  }

  handleModalDone = () => {
    const {onModalDismiss, onEquationSubmit} = this.props
    const output = this.state.advanced ? this.state.workingFormula : this.mathField.getValue()

    if (output) {
      onEquationSubmit(output)
    }

    if (this.usedInCanvas()) {
      // restore the original value
      ENV.disable_keyboard_shortcuts = this.hostPageDisablesShortcuts
    }
    onModalDismiss()
  }

  renderMathInAdvancedPreview = debounce(
    () => {
      if (this.previewElement.current) {
        this.previewElement.current.innerHTML = String.raw`\(${this.state.workingFormula}\)`
        mathml.processNewMathInElem(this.previewElement.current)
      }
    },
    EquationEditorModal.debounceRate,
    {
      leading: false,
      trailing: true,
    }
  )

  setPreviewElementContent() {
    if (this.state.workingFormula) {
      this.renderMathInAdvancedPreview()
    } else {
      this.previewElement.current.innerHTML = ''
    }
  }

  toggleAdvanced = () => {
    this.setState(state => {
      if (state.advanced) {
        this.mathField.setValue(state.workingFormula || '')
        return {advanced: false, workingFormula: ''}
      } else {
        return {advanced: true, workingFormula: this.mathField.getValue()}
      }
    })
    this.setPreviewElementContent()
  }

  toggleAndUpdatePreference = () => {
    this.toggleAdvanced()
    advancedPreference.isSet() ? advancedPreference.clear() : advancedPreference.set()
  }

  registerBasicEditorListener = () => {
    const basicEditor = document.querySelector('math-field')
    basicEditor.addEventListener('input', e => {
      if (this.advancedModeOnly(e.target.value)) {
        this.toggleAdvanced()
        this.setState({workingFormula: e.target.value})
      }
    })
  }

  handleOpen = () => {
    if (this.usedInCanvas()) {
      // store the original value (so it can be restored later)
      this.hostPageDisablesShortcuts = ENV.disable_keyboard_shortcuts

      // And disable keyboard shortcuts while we
      // are inside the equation editor
      ENV.disable_keyboard_shortcuts = true
    }
  }

  handleFieldRef = node => {
    this.mathField = node
  }

  // ******************* //
  // Rendering functions //
  // ******************* //

  renderFooter = () => {
    return (
      <>
        <Button data-testid="equation-editor-modal-cancel" onClick={this.handleModalCancel}>
          {formatMessage('Cancel')}
        </Button>
        <Button
          data-testid="equation-editor-modal-done"
          margin="none none none xx-small"
          onClick={this.handleModalDone}
          color="primary"
        >
          {formatMessage('Done')}
        </Button>
      </>
    )
  }

  renderToggle = () => {
    const lockToggle = this.state.advanced && this.advancedModeOnly(this.state.workingFormula)

    return (
      <ConditionalTooltip
        condition={lockToggle}
        renderTip={formatMessage('This equation cannot be rendered in Basic View.')}
        on={['hover', 'focus']}
      >
        <Checkbox
          onChange={this.toggleAndUpdatePreference}
          checked={this.state.advanced}
          label={formatMessage('Directly Edit LaTeX')}
          variant="toggle"
          disabled={lockToggle}
          data-testid="advanced-toggle"
        />
      </ConditionalTooltip>
    )
  }

  componentDidMount() {
    this.registerBasicEditorListener()
    this.setPreviewElementContent()
    this.stubMacros()
    if (!this.state.advanced) this.mathField.setValue(this.state.workingFormula)
    this.insertNewRange()
  }

  componentDidUpdate(prevProps, prevState) {
    if (this.state.workingFormula !== prevState.workingFormula) {
      this.setPreviewElementContent()
    }
  }

  stubMacros() {
    // Mathlive's macros exist for a different use case;
    // we don't intend for our users to utilize them.
    // This effectively disables all of them to prevent
    // weird behaviors that users don't expect.
    this.mathField?.setOptions({macros: {}})
  }

  render = () => {
    const {onModalClose, mountNode} = this.props

    return (
      <Modal
        data-mce-component={true}
        label={formatMessage('Equation Editor')}
        onClose={onModalClose}
        onDismiss={this.handleModalCancel}
        onOpen={this.handleOpen}
        open={true}
        mountNode={mountNode}
        transition="fade"
        shouldCloseOnDocumentClick={false}
      >
        <Modal.Header>
          <CloseButton
            data-testid="equation-editor-modal-close"
            placement="end"
            offset="medium"
            color="primary"
            onClick={this.handleModalCancel}
            screenReaderLabel={formatMessage('Close')}
          />
          <Heading>{formatMessage('Equation Editor')}</Heading>
        </Modal.Header>
        <Modal.Body>
          <div className={css(styles.mathfieldContainer)}>
            <MemoizedEquationEditorToolbar executeCommand={this.executeCommand} />
            <div style={{display: this.state.advanced ? 'none' : null}}>
              <math-field
                style={{
                  padding: '0.5em',
                  overflow: 'auto',
                  border: 'solid 1px',
                  borderRadius: '4px',
                }}
                ref={this.handleFieldRef}
                default-mode="inline-math"
                virtual-keyboard-mode="off"
                keypress-sound="none"
                plonk-sound="none"
                math-mode-space=" "
              />
            </div>
            <div style={{display: this.state.advanced ? null : 'none'}}>
              <TextArea
                style={{
                  height: '5.1rem',
                  overflowY: 'auto',
                  lineHeight: '1.7rem',
                }}
                label=""
                value={this.state.workingFormula}
                onChange={e => this.setState({workingFormula: e.target.value})}
              />
            </div>
            <div className={css(styles.latexToggle)}>
              <Flex>
                <Flex.Item>{this.renderToggle()}</Flex.Item>
              </Flex>
            </div>
            <div style={{display: this.state.advanced ? null : 'none', marginTop: '1em'}}>
              <span data-testid="mathml-preview-element" ref={this.previewElement} />
            </div>
          </div>
        </Modal.Body>
        <Modal.Footer>{this.renderFooter()}</Modal.Footer>
      </Modal>
    )
  }
}

EquationEditorModal.propTypes = {
  editor: PropTypes.object.isRequired,
  onModalDismiss: PropTypes.func.isRequired,
  onModalClose: PropTypes.func.isRequired,
  onEquationSubmit: PropTypes.func.isRequired,
  mountNode: PropTypes.string,
  originalLatex: PropTypes.shape({
    latex: PropTypes.string,
    advancedOnly: PropTypes.bool,
    startContainer: PropTypes.element,
    leftIndex: PropTypes.number,
    rightIndex: PropTypes.number,
  }).isRequired,
  openAdvanced: PropTypes.bool.isRequired,
}

EquationEditorModal.defaultProps = {
  mountNode: null,
}
