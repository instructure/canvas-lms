import _slicedToArray from "@babel/runtime/helpers/esm/slicedToArray";

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
import React, { Component } from 'react';
import PropTypes from 'prop-types';
import { convertLatexToMathMl } from "../mathlive/index.js";
import { TextArea } from '@instructure/ui-text-area';
import { CloseButton, Button } from '@instructure/ui-buttons';
import { Checkbox } from '@instructure/ui-checkbox';
import { Heading } from '@instructure/ui-heading';
import { Modal } from '@instructure/ui-modal';
import formatMessage from "../../../../format-message.js";
import EquationEditorToolbar from "../EquationEditorToolbar/index.js";
import { css } from 'aphrodite';
import mathml from "./mathml.js";
import styles from "./styles.js";
export default class EquationEditorModal extends Component {
  constructor(...args) {
    super(...args);
    this.state = {
      advanced: false,
      workingFormula: ''
    };
    this.originalFormula = null;
    this.previewElement = /*#__PURE__*/React.createRef();

    this.executeCommand = (cmd, advancedCmd) => {
      if (this.state.advanced) {
        this.setState(state => ({
          workingFormula: state.workingFormula + (advancedCmd || cmd)
        }));
      } else {
        this.mathField.insert(cmd, {
          focus: 'true'
        });
      }
    };

    this.handleEntered = () => {
      this.loadExistingFormula();
    };

    this.handleModalCancel = e => {
      var _this$props$onModalDi, _this$props;

      const element = e.srcElement || e.targetElement; // MathJax Menu clicks closes modal. MathJax doesn't let us to get the menu click event
      // to use stopPropagation().

      const isMathJaxEvent = element && (element.id === 'MathJax_MenuFrame' || element.classList.contains('MathJax_Menu') || element.classList.contains('MathJax_MenuItem'));

      if (isMathJaxEvent) {
        return;
      }

      (_this$props$onModalDi = (_this$props = this.props).onModalDismiss) === null || _this$props$onModalDi === void 0 ? void 0 : _this$props$onModalDi.call(_this$props);
    };

    this.handleModalDone = () => {
      const _this$props2 = this.props,
            onModalDismiss = _this$props2.onModalDismiss,
            onEquationSubmit = _this$props2.onEquationSubmit;
      const output = this.state.advanced ? this.state.workingFormula : this.mathField.getValue();

      if (output) {
        onEquationSubmit(output);
      }

      onModalDismiss();
    };

    this.toggleAdvanced = () => {
      this.setState(state => {
        if (state.advanced) {
          this.mathField.setValue(state.workingFormula || '');
          return {
            advanced: false,
            workingFormula: ''
          };
        } else {
          return {
            advanced: true,
            workingFormula: this.mathField.getValue()
          };
        }
      });
    };

    this.handleOpen = () => {
      this.originalFormula = null;
    };

    this.handleFieldRef = node => {
      this.mathField = node;
    };

    this.renderFooter = () => {
      const cancelButton = /*#__PURE__*/React.createElement(Button, {
        onClick: this.handleModalCancel
      }, formatMessage('Cancel'));
      const doneButton = /*#__PURE__*/React.createElement(Button, {
        margin: "none none none xx-small",
        onClick: this.handleModalDone,
        variant: "primary"
      }, formatMessage('Done'));
      return /*#__PURE__*/React.createElement("div", null, cancelButton, doneButton);
    };

    this.handleRef = node => {
      this.modalFooter = node;
    };

    this.render = () => {
      const _this$props3 = this.props,
            label = _this$props3.label,
            onModalClose = _this$props3.onModalClose,
            title = _this$props3.title,
            mountNode = _this$props3.mountNode;
      return /*#__PURE__*/React.createElement(Modal, {
        label: label,
        onClose: onModalClose,
        onDismiss: this.handleModalCancel,
        onEntered: this.handleEntered,
        onOpen: this.handleOpen,
        open: true,
        mountNode: mountNode,
        transition: "fade"
      }, /*#__PURE__*/React.createElement(Modal.Header, null, /*#__PURE__*/React.createElement(CloseButton, {
        placement: "end",
        offset: "medium",
        variant: "icon",
        onClick: this.handleModalCancel
      }, formatMessage('Close')), /*#__PURE__*/React.createElement(Heading, null, title || label)), /*#__PURE__*/React.createElement(Modal.Body, null, /*#__PURE__*/React.createElement("div", {
        ref: node => {
          this.modalContent = node;
        },
        className: css(styles.mathfieldContainer)
      }, /*#__PURE__*/React.createElement("div", null, /*#__PURE__*/React.createElement(EquationEditorToolbar, {
        executeCommand: this.executeCommand
      })), /*#__PURE__*/React.createElement("div", {
        className: css(styles.mathFieldContainer),
        style: {
          display: this.state.advanced ? 'none' : null
        }
      }, /*#__PURE__*/React.createElement("math-field", {
        style: {
          padding: '0.5em',
          overflow: 'auto',
          border: 'solid 1px',
          borderRadius: '4px'
        },
        ref: this.handleFieldRef,
        "default-mode": "math",
        "virtual-keyboard-mode": "off",
        "keypress-sound": "none",
        "plonk-sound": "none",
        "math-mode-space": " "
      })), /*#__PURE__*/React.createElement("div", {
        className: css(styles.mathFieldContainer),
        style: {
          display: this.state.advanced ? null : 'none'
        }
      }, /*#__PURE__*/React.createElement(TextArea, {
        style: {
          height: '5.1rem',
          overflowY: 'auto',
          lineHeight: '1.7rem'
        },
        label: "",
        value: this.state.workingFormula,
        onChange: e => this.setState({
          workingFormula: e.target.value
        })
      })), /*#__PURE__*/React.createElement("div", {
        className: css(styles.latexToggle)
      }, /*#__PURE__*/React.createElement(Checkbox, {
        onChange: this.toggleAdvanced,
        checked: this.state.advanced,
        label: formatMessage('Directly Edit LaTeX'),
        variant: "toggle"
      })), /*#__PURE__*/React.createElement("div", {
        style: {
          display: this.state.advanced ? null : 'none',
          marginTop: '1em'
        }
      }, /*#__PURE__*/React.createElement("span", {
        "data-testid": "mathml-preview-element",
        ref: this.previewElement
      })))), /*#__PURE__*/React.createElement(Modal.Footer, {
        ref: this.handleRef
      }, this.renderFooter()));
    };
  }

  // **************** //
  // Helper functions //
  // **************** //
  currentFormula(nodeValue, cursor) {
    let leftIndex, rightIndex; // The range could still contain more than one formulae, so we need to
    // isolate them and figure out which one the cursor is within.

    const formulae = nodeValue.match(EquationEditorModal.boundaryRegex);

    if (!formulae) {
      return [void 0, 0, 0];
    }

    const foundFormula = formulae.find(formula => {
      leftIndex = nodeValue.indexOf(formula);
      rightIndex = leftIndex + formula.length;
      return leftIndex < cursor && cursor < rightIndex && this.selectionIsLatex(formula);
    });
    return [foundFormula, leftIndex, rightIndex];
  }

  insertNewRange(currentFormula, startContainer, leftIndex, rightIndex) {
    const editor = this.props.editor;
    const range = document.createRange();
    range.setStart(startContainer, leftIndex);
    range.setEnd(startContainer, rightIndex);
    editor.selection.setRng(range);
    this.originalFormula = this.selectionToLatex(currentFormula);
    this.mathField.setValue(this.originalFormula || ' ');
  }

  loadExistingFormula() {
    const editor = this.props.editor;
    const selection = editor.selection.getContent();

    if (selection && this.selectionIsLatex(selection)) {
      this.originalFormula = this.selectionToLatex(selection);
      this.mathField.setValue(this.originalFormula || ' ');
    } else {
      const selnode = editor.selection.getNode();

      if (selnode.tagName === 'IMG' && selnode.classList.contains('equation_image')) {
        try {
          const src = new URL(selnode.src);
          const encoded_eq = src.pathname.replace(/^\/equation_images\//, '');
          this.originalFormula = decodeURIComponent(decodeURIComponent(encoded_eq));
          this.mathField.setValue(this.originalFormula || ' ');
        } catch (ex) {
          // probably failed to create the new URL
          // eslint-disable-next-line no-console
          console.error(ex);
        }
      } else {
        const editorRange = editor.selection.getRng();
        const startContainer = editorRange.startContainer;
        const wholeText = startContainer.wholeText;

        if (wholeText) {
          const cursor = editorRange.startOffset; // The `wholeText` value is not sufficient, since we could be dealing with
          // a number of nested ranges. The `nodeValue` is the text in the range in
          // which we have found the cursor.

          const nodeValue = startContainer.nodeValue;

          const _this$currentFormula = this.currentFormula(nodeValue, cursor),
                _this$currentFormula2 = _slicedToArray(_this$currentFormula, 3),
                currentFormula = _this$currentFormula2[0],
                leftIndex = _this$currentFormula2[1],
                rightIndex = _this$currentFormula2[2];

          if (currentFormula !== void 0) {
            this.insertNewRange(currentFormula, startContainer, leftIndex, rightIndex);
          }
        }
      }
    }
  }

  selectionIsLatex(selection) {
    return selection.startsWith('\\(') && selection.endsWith('\\)');
  }

  selectionToLatex(selection) {
    return selection.substr(2, selection.length - 4);
  } // ********* //
  // Callbacks //
  // ********* //


  setPreviewElementContent() {
    if (!this.state.advanced) {
      return;
    }

    const mathMlContent = convertLatexToMathMl(this.state.workingFormula);

    if (mathMlContent) {
      this.previewElement.current.innerHTML = `<math>${mathMlContent}</math>`;
      mathml.processNewMathInElem(this.previewElement.current);
    } else {
      this.previewElement.current.innerHTML = '';
    }
  }

  componentDidMount() {
    this.setPreviewElementContent();
  }

  componentDidUpdate(prevProps, prevState) {
    if (this.state.workingFormula !== prevState.workingFormula) {
      this.setPreviewElementContent();
    }
  }

}
EquationEditorModal.propTypes = {
  editor: PropTypes.object.isRequired,
  label: PropTypes.string.isRequired,
  onModalDismiss: PropTypes.func.isRequired,
  onModalClose: PropTypes.func.isRequired,
  onEquationSubmit: PropTypes.func.isRequired,
  title: PropTypes.node,
  mountNode: PropTypes.string
};
EquationEditorModal.boundaryRegex = /\\\((.+?)\\\)/g;
EquationEditorModal.defaultProps = {
  title: null,
  mountNode: null
};