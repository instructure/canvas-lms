import _objectWithoutProperties from "@babel/runtime/helpers/esm/objectWithoutProperties";
import _objectSpread from "@babel/runtime/helpers/esm/objectSpread2";
const _excluded = ["trayProps"];

var _dec, _class, _class2, _temp;

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
import PropTypes from 'prop-types';
import React, { Suspense } from 'react';
import { Editor } from '@tinymce/tinymce-react';
import _ from 'lodash';
import themeable from '@instructure/ui-themeable';
import { IconKeyboardShortcutsLine } from '@instructure/ui-icons';
import { Alert } from '@instructure/ui-alerts';
import { Spinner } from '@instructure/ui-spinner';
import { View } from '@instructure/ui-view';
import { debounce } from '@instructure/debounce';
import getCookie from "../common/getCookie.js";
import formatMessage from "../format-message.js";
import * as contentInsertion from "./contentInsertion.js";
import indicatorRegion from "./indicatorRegion.js";
import editorLanguage from "./editorLanguage.js";
import normalizeLocale from "./normalizeLocale.js";
import { sanitizePlugins } from "./sanitizeEditorOptions.js";
import indicate from "../common/indicate.js";
import bridge from "../bridge/index.js";
import CanvasContentTray, { trayPropTypes } from "./plugins/shared/CanvasContentTray.js";
import StatusBar, { WYSIWYG_VIEW, PRETTY_HTML_EDITOR_VIEW, RAW_HTML_EDITOR_VIEW } from "./StatusBar.js";
import { VIEW_CHANGE } from "./customEvents.js";
import ShowOnFocusButton from "./ShowOnFocusButton/index.js";
import theme from "../skins/theme.js";
import { isAudio, isImage, isVideo } from "./plugins/shared/fileTypeUtils.js";
import KeyboardShortcutModal from "./KeyboardShortcutModal.js";
import AlertMessageArea from "./AlertMessageArea.js";
import alertHandler from "./alertHandler.js";
import { isFileLink, isImageEmbed } from "./plugins/shared/ContentSelection.js";
import { VIDEO_SIZE_DEFAULT, AUDIO_PLAYER_SIZE } from "./plugins/instructure_record/VideoOptionsTray/TrayController.js";
const RestoreAutoSaveModal = /*#__PURE__*/React.lazy(() => import('./RestoreAutoSaveModal'));
const RceHtmlEditor = /*#__PURE__*/React.lazy(() => import('./RceHtmlEditor'));
const ASYNC_FOCUS_TIMEOUT = 250;
const DEFAULT_RCE_HEIGHT = '400px';
const toolbarPropType = PropTypes.arrayOf(PropTypes.shape({
  // name of the toolbar the items are added to
  // if this toolbar doesn't exist, it is created
  // tinymce toolbar config does not
  // include a key to identify the individual toolbars, just a name
  // which is translated. This toolbar's name must be translated
  // in order to be merged correctly.
  name: PropTypes.string.isRequired,
  // items added to the toolbar
  // each is the name of the button some plugin has
  // registered with tinymce
  items: PropTypes.arrayOf(PropTypes.string).isRequired
}));
const menuPropType = PropTypes.objectOf( // the key is the name of the menu item a plugin has
// registered with tinymce. If it does not exist in the
// default menubar, it will be added.
PropTypes.shape({
  // if this is a new menu in the menubar, title is it's label.
  // if these are items being merged into an existing menu, title is ignored
  title: PropTypes.string,
  // items is a space separated list it menu_items
  // some plugin has registered with tinymce
  items: PropTypes.string.isRequired
}));
const ltiToolsPropType = PropTypes.arrayOf(PropTypes.shape({
  // id of the tool
  id: PropTypes.oneOfType([PropTypes.string, PropTypes.number]),
  // is this a favorite tool?
  favorite: PropTypes.bool
}));
export const editorOptionsPropType = PropTypes.shape({
  // height of the RCE.
  // if a number interpreted as pixels.
  // if a string as a CSS value.
  height: PropTypes.oneOfType([PropTypes.number, PropTypes.string]),
  // entries you want merged into the toolbar. See toolBarPropType above.
  toolbar: toolbarPropType,
  // entries you want merged into to the menus. See menuPropType above.
  // If an entry defines a new menu, tinymce's menubar config option will
  // be updated for you. In fact, if you provide an editorOptions.menubar value
  // it will be overwritten.
  menu: menuPropType,
  // additional plugins that get merged into the default list of plugins
  // it is up to you to import the plugin's definition which will
  // register it and any related toolbar or menu entries with tinymce.
  plugins: PropTypes.arrayOf(PropTypes.string),
  // is this RCE readonly?
  readonly: PropTypes.bool
}); // we  `require` instead of `import` because the ui-themeable babel require hook only works with `require`
// 2021-04-21: This is no longer true, but I didn't want to make a gratutious change when I found this out.
// see https://gerrit.instructure.com/c/canvas-lms/+/263299/2/packages/canvas-rce/src/rce/RCEWrapper.js#50
// for an `import` style solution

const styles = {
  componentId: 'dyzZI',
  template: function (theme) {
    return `




.canvas-rce__skins--root {
  background-color: ${theme.canvasBackgroundColor || 'inherit'};
}



.rce-wrapper textarea {
    width: 100%;
    box-sizing: border-box;
    min-height: auto;
  }

.tox,
  .tox *:not(svg) {
    color: inherit;
    font-family: inherit;
  }



[dir='rtl'] .tox :not(svg) {
    direction: rtl;
  }

.tox:not(.tox-tinymce-inline) .tox-editor-header {
    background-color: ${theme.canvasBackgroundColor || 'inherit'};
  }

.tox.tox-tinymce .screenreader-only {
    border: 0;
    clip: rect(0 0 0 0);
    height: 1px;
    margin: -1px;
    overflow: hidden;
    padding: 0;
    position: absolute;
    width: 1px;
    transform: translatez(0);
  }

.tox-tinymce-aux {
    font-family: ${theme.canvasFontFamily || 'inherit'};
  }



.tox.tox-tinymce-aux {
    z-index: 10000;
  }

.tox .tox-button {
    background-color: ${theme.canvasPrimaryButtonHoverBackground || 'inherit'};
    font-family: ${theme.canvasFontFamily || 'inherit'};
    font-weight: ${theme.canvasButtonFontWeight || 'inherit'};
    font-size: ${theme.canvasButtonFontSize || 'inherit'};
    color: ${theme.canvasPrimaryButtonColor || 'inherit'};
    border-color: ${theme.canvasPrimaryButtonBorderColor || 'inherit'};
    line-height: calc(${theme.canvasButtonLineHeight || 'inherit'} - 2px);
    padding: ${theme.canvasButtonPadding || 'inherit'};
  }

.tox .tox-button[disabled] {
    opacity: 0.5;
    border-color: inherit;
    color: inherit;
  }

.tox .tox-button:focus:not(:disabled) {
    background-color: ${theme.canvasPrimaryButtonBackground || 'inherit'};
    color: ${theme.canvasPrimaryButtonColor || 'inherit'};
    border-color: ${theme.canvasBackgroundColor || 'inherit'};
    box-shadow: ${theme.canvasFocusBoxShadow || 'inherit'};
  }

.tox .tox-button:hover:not(:disabled) {
    background-color: ${theme.canvasPrimaryButtonHoverBackground || 'inherit'};
    color: ${theme.canvasPrimaryButtonHoverColor || 'inherit'};
  }

.tox .tox-button:active:not(:disabled) {
    background-color: ${theme.canvasPrimaryButtonBackground || 'inherit'};
    border-color: ${theme.canvasPrimaryButtonBorderColor || 'inherit'};
    color: ${theme.canvasPrimaryButtonColor || 'inherit'};
  }

.tox .tox-button--secondary {
    background-color: ${theme.canvasSecondaryButtonBackground || 'inherit'};
    border-color: ${theme.canvasSecondaryButtonBorderColor || 'inherit'};
    color: ${theme.canvasSecondaryButtonColor || 'inherit'};
  }

.tox .tox-button--secondary[disabled] {
    background-color: inherit;
    border-color: ${theme.canvasSecondaryButtonBorderColor || 'inherit'};
    color: inherit;
    opacity: 0.5;
  }

.tox .tox-button--secondary:focus:not(:disabled) {
    background-color: inherit;
    border-color: ${theme.canvasFocusBorderColor || 'inherit'};
    color: inherit;
  }

.tox .tox-button--secondary:hover:not(:disabled) {
    background-color: ${theme.canvasSecondaryButtonHoverBackground || 'inherit'};
    border-color: ${theme.canvasSecondaryButtonBorderColor || 'inherit'};
    color: ${theme.canvasSecondaryButtonHoverColor || 'inherit'};
  }

.tox .tox-button--secondary:active:not(:disabled) {
    background-color: inherit;
    border-color: ${theme.canvasSecondaryButtonBorderColor || 'inherit'};
    color: inherit;
  }

.tox .tox-button-link {
    font-family: ${theme.canvasFontFamily || 'inherit'};
  }

.tox .tox-button--naked {
    background: ${theme.canvasButtonBackground || 'inherit'};
    border-color: ${theme.canvasButtonBorderColor || 'inherit'};
    color: ${theme.canvasButtonColor || 'inherit'};
  }

.tox .tox-button--naked:hover:not(:disabled) {
    background-color: ${theme.canvasButtonHoverBackground || 'inherit'};
    border-color: ${theme.canvasButtonBorderColor || 'inherit'};
    color: ${theme.canvasButtonHoverColor || 'inherit'};
  }

.tox .tox-button--naked:focus:not(:disabled) {
    background-color: ${theme.canvasButtonBackground || 'inherit'};
    color: ${theme.canvasButtonColor || 'inherit'};
    border-color: ${theme.canvasBackgroundColor || 'inherit'};
    box-shadow: ${theme.canvasFocusBoxShadow || 'inherit'};
  }

.tox .tox-button--naked:active:not(:disabled) {
    background-color: inherit;
    color: inherit;
  }

.tox .tox-button--naked.tox-button--icon {
    color: ${theme.canvasButtonColor || 'inherit'};
  }

.tox .tox-button--naked.tox-button--icon:hover:not(:disabled) {
    background: ${theme.canvasButtonHoverBackground || 'inherit'};
    color: ${theme.canvasButtonHoverColor || 'inherit'};
  }

.tox .tox-checkbox__icons .tox-checkbox-icon__unchecked svg {
    fill: rgba(45, 59, 69, 0.3);
  }

.tox .tox-checkbox__icons .tox-checkbox-icon__indeterminate svg {
    fill: ${theme.canvasTextColor || 'inherit'};
  }

.tox .tox-checkbox__icons .tox-checkbox-icon__checked svg {
    fill: ${theme.canvasTextColor || 'inherit'};
  }

.tox input.tox-checkbox__input:focus + .tox-checkbox__icons {
    box-shadow: ${theme.canvasFocusBoxShadow || 'inherit'};
  }

.tox .tox-collection--list .tox-collection__group {
    border-color: ${theme.canvasBorderColor || 'inherit'};
  }

.tox .tox-collection__group-heading {
    background-color: #e3e6e8;
    color: rgba(45, 59, 69, 0.6);
  }

.tox .tox-collection__item {
    color: ${theme.canvasTextColor || 'inherit'};
  }

.tox .tox-collection__item--state-disabled {
    background-color: unset;
    opacity: 0.5;
    cursor: default;
  }

.tox .tox-collection--list .tox-collection__item--enabled {
    color: contrast(inherit, ${theme.canvasTextColor || 'inherit'}, #fff);
  }

.tox .tox-collection--list .tox-collection__item--active {
    background-color: ${theme.activeMenuItemBackground || 'inherit'};
    color: ${theme.activeMenuItemLabelColor || 'inherit'};
  }

.tox
    .tox-collection--list
    .tox-collection__item--active:not(.tox-collection__item--state-disabled) {
    background-color: ${theme.activeMenuItemBackground || 'inherit'};
    color: ${theme.activeMenuItemLabelColor || 'inherit'};
  }

.tox .tox-collection--toolbar .tox-collection__item--enabled {
    background-color: #cbced1;
    color: ${theme.canvasTextColor || 'inherit'};
  }

.tox .tox-collection--toolbar .tox-collection__item--active {
    background-color: #e0e2e3;
    color: ${theme.canvasTextColor || 'inherit'};
  }

.tox .tox-collection--grid .tox-collection__item--enabled {
    background-color: #cbced1;
    color: ${theme.canvasTextColor || 'inherit'};
  }

.tox .tox-collection--grid .tox-collection__item--active {
    background-color: #e0e2e3;
    color: ${theme.canvasTextColor || 'inherit'};
  }

.tox .tox-collection--list .tox-collection__item-icon:first-child {
    margin-right: 8px;
  }

.tox .tox-collection__item-accessory {
    color: rgba(45, 59, 69, 0.6);
  }

.tox .tox-sv-palette {
    border: 1px solid black;
    box-sizing: border-box;
  }

.tox .tox-hue-slider {
    border: 1px solid black;
  }

.tox .tox-rgb-form input.tox-invalid {
    
    border-color: ${theme.canvasErrorColor || 'inherit'} !important;
  }

.tox .tox-rgb-form {
    padding: 2px; 
  }

.tox .tox-swatches__picker-btn:hover {
    background: #e0e2e3;
  }

.tox .tox-comment-thread {
    background: ${theme.canvasBackgroundColor || 'inherit'};
  }

.tox .tox-comment {
    background: ${theme.canvasBackgroundColor || 'inherit'};
    border-color: ${theme.canvasBorderColor || 'inherit'};
    box-shadow: 0 4px 8px 0 rgba(45, 59, 69, 0.1);
  }

.tox .tox-comment__header {
    color: ${theme.canvasTextColor || 'inherit'};
  }

.tox .tox-comment__date {
    color: rgba(45, 59, 69, 0.6);
  }

.tox .tox-comment__body {
    color: ${theme.canvasTextColor || 'inherit'};
  }

.tox .tox-comment__expander p {
    color: rgba(45, 59, 69, 0.6);
  }

.tox .tox-comment-thread__overlay::after {
    background: ${theme.canvasBackgroundColor || 'inherit'};
  }

.tox .tox-comment__overlay {
    background: ${theme.canvasBackgroundColor || 'inherit'};
  }

.tox .tox-comment__loading-text {
    color: ${theme.canvasTextColor || 'inherit'};
  }

.tox .tox-comment__overlaytext p {
    background-color: ${theme.canvasBackgroundColor || 'inherit'};
    color: ${theme.canvasTextColor || 'inherit'};
  }

.tox .tox-comment__busy-spinner {
    background-color: ${theme.canvasBackgroundColor || 'inherit'};
  }

.tox .tox-user__avatar svg {
    fill: rgba(45, 59, 69, 0.6);
  }

.tox .tox-user__name {
    color: rgba(45, 59, 69, 0.6);
  }

.tox .tox-dialog-wrap__backdrop {
    background-color: rgba(255, 255, 255, 0.75);
  }

.tox .tox-dialog {
    background-color: ${theme.canvasBackgroundColor || 'inherit'};
    border-color: ${theme.canvasBorderColor || 'inherit'};
    box-shadow: ${theme.canvasModalShadow || 'inherit'};
  }

.tox .tox-dialog__header {
    background-color: ${theme.canvasBackgroundColor || 'inherit'};
    color: ${theme.canvasTextColor || 'inherit'};
    border-bottom: 1px solid ${theme.canvasBorderColor || 'inherit'};
    padding: ${theme.canvasModalHeadingPadding || 'inherit'};
    margin: 0;
  }

.tox .tox-dialog__title {
    font-family: ${theme.canvasFontFamily || 'inherit'};
    font-size: ${theme.canvasModalHeadingFontSize || 'inherit'};
    font-weight: ${theme.canvasModalHeadingFontWeight || 'inherit'};
  }

.tox .tox-dialog__body {
    color: ${theme.canvasTextColor || 'inherit'};
    padding: ${theme.canvasModalBodyPadding || 'inherit'};
  }

.tox .tox-dialog__body-nav-item {
    color: rgba(45, 59, 69, 0.75);
  }

.tox .tox-dialog__body-nav-item:focus {
      box-shadow: ${theme.canvasFocusBoxShadow || 'inherit'};
    }

.tox .tox-dialog__body-nav-item--active {
    border-bottom-color: ${theme.canvasBrandColor || 'inherit'};
    color: ${theme.canvasBrandColor || 'inherit'};
  }

.tox .tox-dialog__footer {
    background-color: ${theme.canvasModalFooterBackground || 'inherit'};
    border-top: 1px solid ${theme.canvasBorderColor || 'inherit'};
    padding: ${theme.canvasModalFooterPadding || 'inherit'};
    margin: 0;
  }

.tox .tox-dialog__table tbody tr {
    border-bottom-color: ${theme.canvasBorderColor || 'inherit'};
  }

.tox .tox-dropzone {
    background: ${theme.canvasBackgroundColor || 'inherit'};
    border: 2px dashed ${theme.canvasBorderColor || 'inherit'};
  }

.tox .tox-dropzone p {
    color: rgba(45, 59, 69, 0.6);
  }

.tox .tox-edit-area {
    border: 1px solid ${theme.canvasBorderColor || 'inherit'};
    border-radius: 3px;
  }

.tox .tox-edit-area__iframe {
    background-color: ${theme.canvasBackgroundColor || 'inherit'};
    border: ${theme.canvasFocusBorderWidth || 'inherit'} solid transparent;
  }

.tox.tox-inline-edit-area {
    border-color: ${theme.canvasBorderColor || 'inherit'};
  }

.tox .tox-form__group {
    padding: 2px;
  }

.tox .tox-control-wrap .tox-textfield {
    padding-right: 32px;
  }

.tox .tox-control-wrap__status-icon-invalid svg {
    fill: ${theme.canvasErrorColor || 'inherit'};
  }

.tox .tox-control-wrap__status-icon-unknown svg {
    fill: ${theme.canvasWarningColor || 'inherit'};
  }

.tox .tox-control-wrap__status-icon-valid svg {
    fill: ${theme.canvasSuccessColor || 'inherit'};
  }

.tox .tox-color-input span {
    border-color: rgba(45, 59, 69, 0.2);
  }

.tox .tox-color-input span:focus {
    border-color: ${theme.canvasBrandColor || 'inherit'};
  }

.tox .tox-label,
  .tox .tox-toolbar-label {
    color: rgba(45, 59, 69, 0.6);
  }

.tox .tox-form__group {
    margin: ${theme.canvasFormElementMargin || 'inherit'};
  }

.tox .tox-form__group:last-child {
    margin: 0;
  }

.tox .tox-form__group .tox-label {
    color: ${theme.canvasFormElementLabelColor || 'inherit'};
    margin: ${theme.canvasFormElementLabelMargin || 'inherit'};
    font-size: ${theme.canvasFormElementLabelFontSize || 'inherit'};
    font-weight: ${theme.canvasFormElementLabelFontWeight || 'inherit'};
  }

.tox .tox-form__group--error {
    color: ${theme.canvasErrorColor || 'inherit'};
  }

.tox .tox-textfield,
  .tox .tox-selectfield select,
  .tox .tox-textarea,
  .tox .tox-toolbar-textfield {
    background-color: ${theme.canvasBackgroundColor || 'inherit'};
    border-color: ${theme.canvasBorderColor || 'inherit'};
    color: ${theme.canvasTextColor || 'inherit'};
    font-family: ${theme.canvasFontFamily || 'inherit'};
  }

.tox .tox-textfield:focus,
  .tox .tox-selectfield select:focus,
  .tox .tox-textarea:focus {
    
    border-color: ${theme.canvasBorderColor || 'inherit'};
    box-shadow: ${theme.canvasFocusBoxShadow || 'inherit'};
  }

.tox .tox-naked-btn {
    color: ${theme.canvasButtonColor || 'inherit'};
  }

.tox .tox-naked-btn svg {
    fill: ${theme.canvasButtonColor || 'inherit'};
  }

.tox .tox-insert-table-picker > div {
    border-color: #cccccc;
  }

.tox .tox-insert-table-picker .tox-insert-table-picker__selected {
    background-color: ${theme.tableSelectorHighlightColor || 'inherit'};
    border-color: ${theme.tableSelectorHighlightColor || 'inherit'};
  }

.tox-selected-menu .tox-insert-table-picker {
    background-color: ${theme.canvasBackgroundColor || 'inherit'};
  }

.tox .tox-insert-table-picker__label {
    color: ${theme.canvasTextColor || 'inherit'};
  }

.tox .tox-menu {
    background-color: ${theme.canvasBackgroundColor || 'inherit'};
    border-color: ${theme.canvasBorderColor || 'inherit'};
  }

.tox .tox-menubar {
    background-color: ${theme.canvasBackgroundColor || 'inherit'};
  }

.tox .tox-mbtn {
    color: ${theme.canvasButtonColor || 'inherit'};
  }

.tox .tox-mbtn[disabled] {
    opacity: 0.5;
  }

.tox .tox-mbtn:hover:not(:disabled) {
    background: ${theme.toolbarButtonHoverBackground || 'inherit'};
    color: ${theme.canvasButtonColor || 'inherit'};
  }

.tox .tox-mbtn:focus:not(:disabled) {
    background-color: transparent;
    color: ${theme.canvasButtonColor || 'inherit'};
    border-color: ${theme.canvasBackgroundColor || 'inherit'};
    box-shadow: ${theme.canvasFocusBoxShadow || 'inherit'};
  }

.tox .tox-mbtn--active {
    background: ${theme.toolbarButtonHoverBackground || 'inherit'};
    color: ${theme.canvasButtonColor || 'inherit'};
  }

.tox .tox-notification {
    background-color: ${theme.canvasBackgroundColor || 'inherit'};
    border-color: #c5c5c5;
  }

.tox .tox-notification--success {
    background-color: #dff0d8;
    border-color: ${theme.canvasSuccessColor || 'inherit'};
  }

.tox .tox-notification--error {
    background-color: #f2dede;
    border-color: ${theme.canvasErrorColor || 'inherit'};
  }

.tox .tox-notification--warn {
    background-color: #fcf8e3;
    border-color: ${theme.canvasWarningColor || 'inherit'};
  }

.tox .tox-notification--info {
    background-color: #d9edf7;
    border-color: ${theme.canvasInfoColor || 'inherit'};
  }

.tox .tox-notification__body {
    color: ${theme.canvasTextColor || 'inherit'};
  }

.tox .tox-pop__dialog {
    background-color: ${theme.canvasBackgroundColor || 'inherit'};
    border-color: ${theme.canvasBorderColor || 'inherit'};
  }

.tox .tox-pop.tox-pop--bottom::before {
    border-color: ${theme.canvasBorderColor || 'inherit'} transparent transparent transparent;
  }

.tox .tox-pop.tox-pop--top::before {
    border-color: transparent transparent ${theme.canvasBorderColor || 'inherit'} transparent;
  }

.tox .tox-pop.tox-pop--left::before {
    border-color: transparent ${theme.canvasBorderColor || 'inherit'} transparent transparent;
  }

.tox .tox-pop.tox-pop--right::before {
    border-color: transparent transparent transparent ${theme.canvasBorderColor || 'inherit'};
  }

.tox .tox-slider {
    width: 100%;
  }

.tox .tox-slider__rail {
    border-color: ${theme.canvasBorderColor || 'inherit'};
  }

.tox .tox-slider__handle {
    background-color: ${theme.canvasBrandColor || 'inherit'};
  }

.tox .tox-spinner > div {
    background-color: rgba(45, 59, 69, 0.6);
  }



.tox .tox-tbtn {
    border-style: none;
    color: ${theme.canvasButtonColor || 'inherit'};
    position: relative;
  }

.tox .tox-tbtn svg {
    fill: ${theme.canvasButtonColor || 'inherit'};
  }

.tox .tox-tbtn.tox-tbtn--enabled {
    background: inherit;
  }

.tox .tox-tbtn:focus,
  .tox .tox-split-button:focus {
    background: ${theme.canvasBackgroundColor || 'inherit'};
    color: ${theme.canvasButtonColor || 'inherit'};
    box-shadow: ${theme.canvasFocusBoxShadow || 'inherit'};
  }

.tox .tox-tbtn:hover,
  .tox .tox-split-button:hover,
  .tox .tox-tbtn.tox-tbtn--enabled:hover,
  .tox .tox-split-button .tox-tbtn.tox-split-button__chevron:hover {
    background: ${theme.toolbarButtonHoverBackground || 'inherit'};
    color: ${theme.canvasButtonColor || 'inherit'};
  }

.tox-tbtn.tox-split-button__chevron {
    position: relative;
  }



.tox .tox-tbtn.tox-tbtn--enabled::after {
    position: absolute;
    top: -3px;
    content: '\\25BC';
    text-align: center;
    height: 8px;
    font-size: 8px;
    width: 100%;
    color: ${theme.canvasEnabledColor || 'inherit'};
  }

[dir="ltr"] .tox .tox-tbtn.tox-tbtn--enabled::after {
    text-align: center;
  }

[dir="rtl"] .tox .tox-tbtn.tox-tbtn--enabled::after {
    text-align: center;
  }



.tox-tbtn.tox-split-button__chevron.tox-tbtn--enabled::after {
    display: none;
  }

.tox .tox-tbtn--disabled,
  .tox .tox-tbtn--disabled:hover,
  .tox .tox-tbtn:disabled,
  .tox .tox-tbtn:disabled:hover {
    opacity: 0.5;
  }

.tox .tox-tbtn--disabled svg,
  .tox .tox-tbtn--disabled:hover svg,
  .tox .tox-tbtn:disabled svg,
  .tox .tox-tbtn:disabled:hover svg {
    
    opacity: 0.5;
  }

.tox .tox-tbtn__select-chevron svg {
    fill: ${theme.canvasButtonColor || 'inherit'};
    width: 10px;
    height: 10px;
  }

.tox .tox-split-button__chevron svg {
    fill: ${theme.canvasButtonColor || 'inherit'};
    width: 10px;
    height: 10px;
  }

.tox .tox-split-button.tox-tbtn--disabled:hover,
  .tox .tox-split-button.tox-tbtn--disabled:focus,
  .tox .tox-split-button.tox-tbtn--disabled .tox-tbtn:hover,
  .tox .tox-split-button.tox-tbtn--disabled .tox-tbtn:focus {
    opacity: 0.5;
  }

.tox .tox-toolbar {
    background-color: ${theme.canvasBackgroundColor || 'inherit'};
    border-top: 1px solid ${theme.canvasBorderColor || 'inherit'};
  }

.tox .tox-toolbar__group:not(:last-of-type) {
    border-right: 1px solid ${theme.canvasBorderColor || 'inherit'};
  }

.tox .tox-tooltip__body {
    background-color: ${theme.canvasTextColor || 'inherit'};
    box-shadow: 0 2px 4px rgba(45, 59, 69, 0.3);
    color: rgba(255, 255, 255, 0.75);
  }

.tox .tox-tooltip--down .tox-tooltip__arrow {
    border-top-color: ${theme.canvasTextColor || 'inherit'};
  }

.tox .tox-tooltip--up .tox-tooltip__arrow {
    border-bottom-color: ${theme.canvasTextColor || 'inherit'};
  }

.tox .tox-tooltip--right .tox-tooltip__arrow {
    border-left-color: ${theme.canvasTextColor || 'inherit'};
  }

.tox .tox-tooltip--left .tox-tooltip__arrow {
    border-right-color: ${theme.canvasTextColor || 'inherit'};
  }

.tox .tox-well {
    border-color: ${theme.canvasBorderColor || 'inherit'};
  }

.tox .tox-custom-editor {
    border-color: ${theme.canvasBorderColor || 'inherit'};
  }

.tox a {
    color: ${theme.canvasLinkColor || 'inherit'};
  }

.tox.tox-tinymce {
    border-style: none;
  }



.tox-editor-container .tox-toolbar,
  .tox-editor-container .tox-toolbar-overlord {
    background-image: none;
    margin-bottom: 5px;
  }

.tox-editor-container .tox-toolbar__primary {
    background-image: none;
  }



.tox .tox-menubar + .tox-toolbar-overlord .tox-toolbar__primary {
    border-style: none;
  }

.tox .tox-toolbar .tox-toolbar__group,
  .tox .tox-toolbar-overlord .tox-toolbar__group,
  .tox-toolbar__overflow .tox-toolbar__group,
  .tox:not([dir='rtl']) .tox-toolbar__group:not(:last-of-type),
  .tox[dir='rtl'] .tox-toolbar__group:not(:last-of-type) {
    border-style: none;
  }

.tox-toolbar .tox-toolbar__group::after, 
  .tox-toolbar-overlord .tox-toolbar__group::after, 
  .tox-toolbar__overflow .tox-toolbar__group::after, 
  .tox-tinymce-aux .tox-toolbar .tox-toolbar__group::after {
    
    content: '';
    display: inline-block;
    box-sizing: border-box;
    border-inline-end: 1px solid ${theme.canvasBorderColor || 'inherit'};
    width: 8px;
    height: 24px;
  }

[dir="ltr"] .tox-toolbar .tox-toolbar__group::after,
[dir="ltr"] .tox-toolbar-overlord .tox-toolbar__group::after,
[dir="ltr"] .tox-toolbar__overflow .tox-toolbar__group::after,
[dir="ltr"] .tox-tinymce-aux .tox-toolbar .tox-toolbar__group::after {
    border-right: 1px solid ${theme.canvasBorderColor || 'inherit'};
  }

[dir="rtl"] .tox-toolbar .tox-toolbar__group::after,
[dir="rtl"] .tox-toolbar-overlord .tox-toolbar__group::after,
[dir="rtl"] .tox-toolbar__overflow .tox-toolbar__group::after,
[dir="rtl"] .tox-tinymce-aux .tox-toolbar .tox-toolbar__group::after {
    border-left: 1px solid ${theme.canvasBorderColor || 'inherit'};
  }

.tox-toolbar .tox-toolbar__group:last-child::after,
  .tox-toolbar-overlord .tox-toolbar__group:last-child::after,
  .tox-toolbar__overflow .tox-toolbar__group:last-child::after,
  .tox-tinymce-aux .tox-toolbar .tox-toolbar__group:last-child::after {
    border-inline-end-width: 0;
    padding-inline-start: 0;
    width: 0;
  }

[dir="ltr"] .tox-toolbar .tox-toolbar__group:last-child::after,
[dir="ltr"] .tox-toolbar-overlord .tox-toolbar__group:last-child::after,
[dir="ltr"] .tox-toolbar__overflow .tox-toolbar__group:last-child::after,
[dir="ltr"] .tox-tinymce-aux .tox-toolbar .tox-toolbar__group:last-child::after {
    border-right-width: 0;
    padding-left: 0;
  }

[dir="rtl"] .tox-toolbar .tox-toolbar__group:last-child::after,
[dir="rtl"] .tox-toolbar-overlord .tox-toolbar__group:last-child::after,
[dir="rtl"] .tox-toolbar__overflow .tox-toolbar__group:last-child::after,
[dir="rtl"] .tox-tinymce-aux .tox-toolbar .tox-toolbar__group:last-child::after {
    border-left-width: 0;
    padding-right: 0;
  }

.tox .tox-tbtn--bespoke .tox-tbtn__select-label {
    width: auto;
    padding-inline-end: 0;
  }

[dir="ltr"] .tox .tox-tbtn--bespoke .tox-tbtn__select-label {
    padding-right: 0;
  }

[dir="rtl"] .tox .tox-tbtn--bespoke .tox-tbtn__select-label {
    padding-left: 0;
  }

.tox .tox-tbtn {
    box-sizing: border-box;
  }

.tox .tox-tbtn,
  .tox .tox-split-button,
  .tox .tox-tbtn--select {
    border-style: none;
    margin: 2px 2px 3px;
  }

.tox .tox-split-button .tox-tbtn {
    margin-inline-end: 0;
  }

[dir="ltr"] .tox .tox-split-button .tox-tbtn {
    margin-right: 0;
  }

[dir="rtl"] .tox .tox-split-button .tox-tbtn {
    margin-left: 0;
  }

.tox .tox-split-button .tox-tbtn.tox-split-button__chevron {
    margin-inline-start: 0;
  }

[dir="ltr"] .tox .tox-split-button .tox-tbtn.tox-split-button__chevron {
    margin-left: 0;
  }

[dir="rtl"] .tox .tox-split-button .tox-tbtn.tox-split-button__chevron {
    margin-right: 0;
  }

.tox .tox-edit-area.active,
  .tox .tox-edit-area.active iframe {
    border-color: ${theme.canvasFocusBorderColor || 'inherit'};
  }

.tox .tox-split-button .tox-tbtn {
    margin-inline-end: 0;
  }

[dir="ltr"] .tox .tox-split-button .tox-tbtn {
    margin-right: 0;
  }

[dir="rtl"] .tox .tox-split-button .tox-tbtn {
    margin-left: 0;
  }

.tox .tox-split-button .tox-tbtn.tox-split-button__chevron {
    margin-inline-start: -6px;
    background-color: ${theme.canvasBackgroundColor || 'inherit'};
  }

[dir="ltr"] .tox .tox-split-button .tox-tbtn.tox-split-button__chevron {
    margin-left: -6px;
  }

[dir="rtl"] .tox .tox-split-button .tox-tbtn.tox-split-button__chevron {
    margin-right: -6px;
  }

.tox .tox-split-button:hover .tox-split-button__chevron {
    background: ${theme.canvasBackgroundColor || 'inherit'};
    color: ${theme.canvasButtonColor || 'inherit'};
    box-shadow: none;
  }

.tox .tox-tbtn:hover.tox-split-button__chevron,
  .tox .tox-tbtn:focus.tox-split-button__chevron {
    box-shadow: none;
  }

.tox .tox-toolbar__primary {
    border-width: 0;
  }

.tox-tbtn.tox-tbtn--select .tox-icon.tox-tbtn__icon-wrap {
    margin-inline-end: 4px;
  }

[dir="ltr"] .tox-tbtn.tox-tbtn--select .tox-icon.tox-tbtn__icon-wrap {
    margin-right: 4px;
  }

[dir="rtl"] .tox-tbtn.tox-tbtn--select .tox-icon.tox-tbtn__icon-wrap {
    margin-left: 4px;
  }



.tox .tox-icon svg:not([height]),
  .tox .tox-collection__item-icon svg:not([height]) {
    height: 16px;
  }



.tox .tox-collection--toolbar-lg .tox-collection__item-icon {
    height: 30px;
    width: 30px;
  }



.tox-selectfield__icon-js svg {
    width: 10px;
    height: 10px;
  }



[data-canvascontenttray-content]:focus {
    outline-color: ${theme.canvasFocusBorderColor || 'inherit'};
  }
`;
  },
  'root': 'canvas-rce__skins--root'
};
const skinCSS = {
  componentId: 'djgIv',
  template: function () {
    return `


.tinymce__oxide--tox{box-shadow:none;box-sizing:content-box;color:#222f3e;cursor:auto;font-family:-apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,Oxygen-Sans,Ubuntu,Cantarell,"Helvetica Neue",sans-serif;font-size:16px;font-style:normal;font-weight:400;line-height:normal;-webkit-tap-highlight-color:transparent;text-decoration:none;text-shadow:none;text-transform:none;vertical-align:baseline;vertical-align:initial;white-space:normal}

.tinymce__oxide--tox :not(svg):not(rect){box-sizing:inherit;color:inherit;cursor:inherit;direction:inherit;font-family:inherit;font-size:inherit;font-style:inherit;font-weight:inherit;line-height:inherit;-webkit-tap-highlight-color:inherit;text-align:inherit;text-decoration:inherit;text-shadow:inherit;text-transform:inherit;vertical-align:inherit;white-space:inherit}

[dir="ltr"] .tinymce__oxide--tox :not(svg):not(rect){text-align:inherit}

[dir="rtl"] .tinymce__oxide--tox :not(svg):not(rect){text-align:inherit}

.tinymce__oxide--tox :not(svg):not(rect){background:0 0;border:0;box-shadow:none;float:none;height:auto;margin:0;max-width:none;outline:0;padding:0;position:static;width:auto}

[dir="ltr"] .tinymce__oxide--tox :not(svg):not(rect){float:none}

[dir="rtl"] .tinymce__oxide--tox :not(svg):not(rect){float:none}

.tinymce__oxide--tox:not([dir=rtl]){direction:ltr;text-align:left}

[dir="ltr"] .tinymce__oxide--tox:not([dir=rtl]){text-align:left}

[dir="rtl"] .tinymce__oxide--tox:not([dir=rtl]){text-align:left}

.tinymce__oxide--tox[dir=rtl]{direction:rtl;text-align:right}

[dir="ltr"] .tinymce__oxide--tox[dir=rtl]{text-align:right}

[dir="rtl"] .tinymce__oxide--tox[dir=rtl]{text-align:right}

.tinymce__oxide--tox-tinymce{border:1px solid #ccc;border-radius:0;box-shadow:none;box-sizing:border-box;display:flex;flex-direction:column;font-family:-apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,Oxygen-Sans,Ubuntu,Cantarell,"Helvetica Neue",sans-serif;overflow:hidden;position:relative;visibility:inherit!important}

.tinymce__oxide--tox-tinymce-inline{border:none;box-shadow:none}

.tinymce__oxide--tox-tinymce-inline .tinymce__oxide--tox-editor-header{background-color:transparent;border:1px solid #ccc;border-radius:0;box-shadow:none}

.tinymce__oxide--tox-tinymce-aux{font-family:-apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,Oxygen-Sans,Ubuntu,Cantarell,"Helvetica Neue",sans-serif;z-index:1300}

.tinymce__oxide--tox-tinymce :focus,.tinymce__oxide--tox-tinymce-aux :focus{outline:0}

button::-moz-focus-inner{border:0}

.tinymce__oxide--tox .tinymce__oxide--accessibility-issue__header{align-items:center;display:flex;margin-bottom:4px}

.tinymce__oxide--tox .tinymce__oxide--accessibility-issue__description{align-items:stretch;border:1px solid #ccc;border-radius:3px;display:flex;justify-content:space-between}

.tinymce__oxide--tox .tinymce__oxide--accessibility-issue__description>div{padding-bottom:4px}

.tinymce__oxide--tox .tinymce__oxide--accessibility-issue__description>div>div{align-items:center;display:flex;margin-bottom:4px}

.tinymce__oxide--tox .tinymce__oxide--accessibility-issue__description>:last-child:not(:only-child){border-color:#ccc;border-style:solid}

.tinymce__oxide--tox .tinymce__oxide--accessibility-issue__repair{margin-top:16px}

.tinymce__oxide--tox .tinymce__oxide--tox-dialog__body-content .tinymce__oxide--accessibility-issue--info .tinymce__oxide--accessibility-issue__description{background-color:rgba(32,122,183,.1);border-color:rgba(32,122,183,.4);color:#222f3e}

.tinymce__oxide--tox .tinymce__oxide--tox-dialog__body-content .tinymce__oxide--accessibility-issue--info .tinymce__oxide--accessibility-issue__description>:last-child{border-color:rgba(32,122,183,.4)}

.tinymce__oxide--tox .tinymce__oxide--tox-dialog__body-content .tinymce__oxide--accessibility-issue--info .tinymce__oxide--tox-form__group h2{color:#207ab7}

.tinymce__oxide--tox .tinymce__oxide--tox-dialog__body-content .tinymce__oxide--accessibility-issue--info .tinymce__oxide--tox-icon svg{fill:#207ab7}

.tinymce__oxide--tox .tinymce__oxide--tox-dialog__body-content .tinymce__oxide--accessibility-issue--info a .tinymce__oxide--tox-icon{color:#207ab7}

.tinymce__oxide--tox .tinymce__oxide--tox-dialog__body-content .tinymce__oxide--accessibility-issue--warn .tinymce__oxide--accessibility-issue__description{background-color:rgba(255,165,0,.1);border-color:rgba(255,165,0,.5);color:#222f3e}

.tinymce__oxide--tox .tinymce__oxide--tox-dialog__body-content .tinymce__oxide--accessibility-issue--warn .tinymce__oxide--accessibility-issue__description>:last-child{border-color:rgba(255,165,0,.5)}

.tinymce__oxide--tox .tinymce__oxide--tox-dialog__body-content .tinymce__oxide--accessibility-issue--warn .tinymce__oxide--tox-form__group h2{color:#cc8500}

.tinymce__oxide--tox .tinymce__oxide--tox-dialog__body-content .tinymce__oxide--accessibility-issue--warn .tinymce__oxide--tox-icon svg{fill:#cc8500}

.tinymce__oxide--tox .tinymce__oxide--tox-dialog__body-content .tinymce__oxide--accessibility-issue--warn a .tinymce__oxide--tox-icon{color:#cc8500}

.tinymce__oxide--tox .tinymce__oxide--tox-dialog__body-content .tinymce__oxide--accessibility-issue--error .tinymce__oxide--accessibility-issue__description{background-color:rgba(204,0,0,.1);border-color:rgba(204,0,0,.4);color:#222f3e}

.tinymce__oxide--tox .tinymce__oxide--tox-dialog__body-content .tinymce__oxide--accessibility-issue--error .tinymce__oxide--accessibility-issue__description>:last-child{border-color:rgba(204,0,0,.4)}

.tinymce__oxide--tox .tinymce__oxide--tox-dialog__body-content .tinymce__oxide--accessibility-issue--error .tinymce__oxide--tox-form__group h2{color:#c00}

.tinymce__oxide--tox .tinymce__oxide--tox-dialog__body-content .tinymce__oxide--accessibility-issue--error .tinymce__oxide--tox-icon svg{fill:#c00}

.tinymce__oxide--tox .tinymce__oxide--tox-dialog__body-content .tinymce__oxide--accessibility-issue--error a .tinymce__oxide--tox-icon{color:#c00}

.tinymce__oxide--tox .tinymce__oxide--tox-dialog__body-content .tinymce__oxide--accessibility-issue--success .tinymce__oxide--accessibility-issue__description{background-color:rgba(120,171,70,.1);border-color:rgba(120,171,70,.4);color:#222f3e}

.tinymce__oxide--tox .tinymce__oxide--tox-dialog__body-content .tinymce__oxide--accessibility-issue--success .tinymce__oxide--accessibility-issue__description>:last-child{border-color:rgba(120,171,70,.4)}

.tinymce__oxide--tox .tinymce__oxide--tox-dialog__body-content .tinymce__oxide--accessibility-issue--success .tinymce__oxide--tox-form__group h2{color:#78ab46}

.tinymce__oxide--tox .tinymce__oxide--tox-dialog__body-content .tinymce__oxide--accessibility-issue--success .tinymce__oxide--tox-icon svg{fill:#78ab46}

.tinymce__oxide--tox .tinymce__oxide--tox-dialog__body-content .tinymce__oxide--accessibility-issue--success a .tinymce__oxide--tox-icon{color:#78ab46}

.tinymce__oxide--tox .tinymce__oxide--tox-dialog__body-content .tinymce__oxide--accessibility-issue__header h1,.tinymce__oxide--tox .tinymce__oxide--tox-dialog__body-content .tinymce__oxide--tox-form__group .tinymce__oxide--accessibility-issue__description h2{margin-top:0}

.tinymce__oxide--tox:not([dir=rtl]) .tinymce__oxide--tox-dialog__body-content .tinymce__oxide--accessibility-issue__header .tinymce__oxide--tox-button{margin-left:4px}

.tinymce__oxide--tox:not([dir=rtl]) .tinymce__oxide--tox-dialog__body-content .tinymce__oxide--accessibility-issue__header>:nth-last-child(2){margin-left:auto}

.tinymce__oxide--tox:not([dir=rtl]) .tinymce__oxide--tox-dialog__body-content .tinymce__oxide--accessibility-issue__description{padding:4px 4px 4px 8px}

.tinymce__oxide--tox:not([dir=rtl]) .tinymce__oxide--tox-dialog__body-content .tinymce__oxide--accessibility-issue__description>:last-child{border-left-width:1px;padding-left:4px}

.tinymce__oxide--tox[dir=rtl] .tinymce__oxide--tox-dialog__body-content .tinymce__oxide--accessibility-issue__header .tinymce__oxide--tox-button{margin-right:4px}

.tinymce__oxide--tox[dir=rtl] .tinymce__oxide--tox-dialog__body-content .tinymce__oxide--accessibility-issue__header>:nth-last-child(2){margin-right:auto}

.tinymce__oxide--tox[dir=rtl] .tinymce__oxide--tox-dialog__body-content .tinymce__oxide--accessibility-issue__description{padding:4px 8px 4px 4px}

.tinymce__oxide--tox[dir=rtl] .tinymce__oxide--tox-dialog__body-content .tinymce__oxide--accessibility-issue__description>:last-child{border-right-width:1px;padding-right:4px}

.tinymce__oxide--tox .tinymce__oxide--tox-anchorbar{display:flex;flex:0 0 auto}

.tinymce__oxide--tox .tinymce__oxide--tox-bar{display:flex;flex:0 0 auto}

.tinymce__oxide--tox .tinymce__oxide--tox-button{background-color:#207ab7;background-image:none;background-position:0 0;background-repeat:repeat;border-color:#207ab7;border-radius:3px;border-style:solid;border-width:1px;box-shadow:none;box-sizing:border-box;color:#fff;cursor:pointer;display:inline-block;font-family:-apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,Oxygen-Sans,Ubuntu,Cantarell,"Helvetica Neue",sans-serif;font-size:14px;font-style:normal;font-weight:700;letter-spacing:normal;line-height:24px;margin:0;outline:0;padding:4px 16px;text-align:center;text-decoration:none;text-transform:none;white-space:nowrap}

[dir="ltr"] .tinymce__oxide--tox .tinymce__oxide--tox-button{text-align:center}

[dir="rtl"] .tinymce__oxide--tox .tinymce__oxide--tox-button{text-align:center}

.tinymce__oxide--tox .tinymce__oxide--tox-button[disabled]{background-color:#207ab7;background-image:none;border-color:#207ab7;box-shadow:none;color:rgba(255,255,255,.5);cursor:not-allowed}

.tinymce__oxide--tox .tinymce__oxide--tox-button:focus:not(:disabled){background-color:#1c6ca1;background-image:none;border-color:#1c6ca1;box-shadow:none;color:#fff}

.tinymce__oxide--tox .tinymce__oxide--tox-button:hover:not(:disabled){background-color:#1c6ca1;background-image:none;border-color:#1c6ca1;box-shadow:none;color:#fff}

.tinymce__oxide--tox .tinymce__oxide--tox-button:active:not(:disabled){background-color:#185d8c;background-image:none;border-color:#185d8c;box-shadow:none;color:#fff}

.tinymce__oxide--tox .tinymce__oxide--tox-button--secondary{background-color:#f0f0f0;background-image:none;background-position:0 0;background-repeat:repeat;border-color:#f0f0f0;border-radius:3px;border-style:solid;border-width:1px;box-shadow:none;color:#222f3e;font-size:14px;font-style:normal;font-weight:700;letter-spacing:normal;outline:0;padding:4px 16px;text-decoration:none;text-transform:none}

.tinymce__oxide--tox .tinymce__oxide--tox-button--secondary[disabled]{background-color:#f0f0f0;background-image:none;border-color:#f0f0f0;box-shadow:none;color:rgba(34,47,62,.5)}

.tinymce__oxide--tox .tinymce__oxide--tox-button--secondary:focus:not(:disabled){background-color:#e3e3e3;background-image:none;border-color:#e3e3e3;box-shadow:none;color:#222f3e}

.tinymce__oxide--tox .tinymce__oxide--tox-button--secondary:hover:not(:disabled){background-color:#e3e3e3;background-image:none;border-color:#e3e3e3;box-shadow:none;color:#222f3e}

.tinymce__oxide--tox .tinymce__oxide--tox-button--secondary:active:not(:disabled){background-color:#d6d6d6;background-image:none;border-color:#d6d6d6;box-shadow:none;color:#222f3e}

.tinymce__oxide--tox .tinymce__oxide--tox-button--icon,.tinymce__oxide--tox .tinymce__oxide--tox-button.tinymce__oxide--tox-button--icon,.tinymce__oxide--tox .tinymce__oxide--tox-button.tinymce__oxide--tox-button--secondary.tinymce__oxide--tox-button--icon{padding:4px}

.tinymce__oxide--tox .tinymce__oxide--tox-button--icon .tinymce__oxide--tox-icon svg,.tinymce__oxide--tox .tinymce__oxide--tox-button.tinymce__oxide--tox-button--icon .tinymce__oxide--tox-icon svg,.tinymce__oxide--tox .tinymce__oxide--tox-button.tinymce__oxide--tox-button--secondary.tinymce__oxide--tox-button--icon .tinymce__oxide--tox-icon svg{display:block;fill:currentColor}

.tinymce__oxide--tox .tinymce__oxide--tox-button-link{background:0;border:none;box-sizing:border-box;cursor:pointer;display:inline-block;font-family:-apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,Oxygen-Sans,Ubuntu,Cantarell,"Helvetica Neue",sans-serif;font-size:16px;font-weight:400;line-height:1.3;margin:0;padding:0;white-space:nowrap}

.tinymce__oxide--tox .tinymce__oxide--tox-button-link--sm{font-size:14px}

.tinymce__oxide--tox .tinymce__oxide--tox-button--naked{background-color:transparent;border-color:transparent;box-shadow:unset;color:#222f3e}

.tinymce__oxide--tox .tinymce__oxide--tox-button--naked[disabled]{background-color:#f0f0f0;border-color:#f0f0f0;box-shadow:none;color:rgba(34,47,62,.5)}

.tinymce__oxide--tox .tinymce__oxide--tox-button--naked:hover:not(:disabled){background-color:#e3e3e3;border-color:#e3e3e3;box-shadow:none;color:#222f3e}

.tinymce__oxide--tox .tinymce__oxide--tox-button--naked:focus:not(:disabled){background-color:#e3e3e3;border-color:#e3e3e3;box-shadow:none;color:#222f3e}

.tinymce__oxide--tox .tinymce__oxide--tox-button--naked:active:not(:disabled){background-color:#d6d6d6;border-color:#d6d6d6;box-shadow:none;color:#222f3e}

.tinymce__oxide--tox .tinymce__oxide--tox-button--naked .tinymce__oxide--tox-icon svg{fill:currentColor}

.tinymce__oxide--tox .tinymce__oxide--tox-button--naked.tinymce__oxide--tox-button--icon:hover:not(:disabled){color:#222f3e}

.tinymce__oxide--tox .tinymce__oxide--tox-checkbox{align-items:center;border-radius:3px;cursor:pointer;display:flex;height:36px;min-width:36px}

.tinymce__oxide--tox .tinymce__oxide--tox-checkbox__input{height:1px;overflow:hidden;position:absolute;top:auto;width:1px}

.tinymce__oxide--tox .tinymce__oxide--tox-checkbox__icons{align-items:center;border-radius:3px;box-shadow:0 0 0 2px transparent;box-sizing:content-box;display:flex;height:24px;justify-content:center;padding:calc(4px - 1px);width:24px}

.tinymce__oxide--tox .tinymce__oxide--tox-checkbox__icons .tinymce__oxide--tox-checkbox-icon__unchecked svg{display:block;fill:rgba(34,47,62,.3)}

.tinymce__oxide--tox .tinymce__oxide--tox-checkbox__icons .tinymce__oxide--tox-checkbox-icon__indeterminate svg{display:none;fill:#207ab7}

.tinymce__oxide--tox .tinymce__oxide--tox-checkbox__icons .tinymce__oxide--tox-checkbox-icon__checked svg{display:none;fill:#207ab7}

.tinymce__oxide--tox .tinymce__oxide--tox-checkbox--disabled{color:rgba(34,47,62,.5);cursor:not-allowed}

.tinymce__oxide--tox .tinymce__oxide--tox-checkbox--disabled .tinymce__oxide--tox-checkbox__icons .tinymce__oxide--tox-checkbox-icon__checked svg{fill:rgba(34,47,62,.5)}

.tinymce__oxide--tox .tinymce__oxide--tox-checkbox--disabled .tinymce__oxide--tox-checkbox__icons .tinymce__oxide--tox-checkbox-icon__unchecked svg{fill:rgba(34,47,62,.5)}

.tinymce__oxide--tox .tinymce__oxide--tox-checkbox--disabled .tinymce__oxide--tox-checkbox__icons .tinymce__oxide--tox-checkbox-icon__indeterminate svg{fill:rgba(34,47,62,.5)}

.tinymce__oxide--tox input.tinymce__oxide--tox-checkbox__input:checked+.tinymce__oxide--tox-checkbox__icons .tinymce__oxide--tox-checkbox-icon__unchecked svg{display:none}

.tinymce__oxide--tox input.tinymce__oxide--tox-checkbox__input:checked+.tinymce__oxide--tox-checkbox__icons .tinymce__oxide--tox-checkbox-icon__checked svg{display:block}

.tinymce__oxide--tox input.tinymce__oxide--tox-checkbox__input:indeterminate+.tinymce__oxide--tox-checkbox__icons .tinymce__oxide--tox-checkbox-icon__unchecked svg{display:none}

.tinymce__oxide--tox input.tinymce__oxide--tox-checkbox__input:indeterminate+.tinymce__oxide--tox-checkbox__icons .tinymce__oxide--tox-checkbox-icon__indeterminate svg{display:block}

.tinymce__oxide--tox input.tinymce__oxide--tox-checkbox__input:focus+.tinymce__oxide--tox-checkbox__icons{border-radius:3px;box-shadow:inset 0 0 0 1px #207ab7;padding:calc(4px - 1px)}

.tinymce__oxide--tox:not([dir=rtl]) .tinymce__oxide--tox-checkbox__label{margin-left:4px}

.tinymce__oxide--tox:not([dir=rtl]) .tinymce__oxide--tox-checkbox__input{left:-10000px}

.tinymce__oxide--tox:not([dir=rtl]) .tinymce__oxide--tox-bar .tinymce__oxide--tox-checkbox{margin-left:4px}

.tinymce__oxide--tox[dir=rtl] .tinymce__oxide--tox-checkbox__label{margin-right:4px}

.tinymce__oxide--tox[dir=rtl] .tinymce__oxide--tox-checkbox__input{right:-10000px}

.tinymce__oxide--tox[dir=rtl] .tinymce__oxide--tox-bar .tinymce__oxide--tox-checkbox{margin-right:4px}

.tinymce__oxide--tox .tinymce__oxide--tox-collection--toolbar .tinymce__oxide--tox-collection__group{display:flex;padding:0}

.tinymce__oxide--tox .tinymce__oxide--tox-collection--grid .tinymce__oxide--tox-collection__group{display:flex;flex-wrap:wrap;max-height:208px;overflow-x:hidden;overflow-y:auto;padding:0}

.tinymce__oxide--tox .tinymce__oxide--tox-collection--list .tinymce__oxide--tox-collection__group{border-bottom-width:0;border-color:#ccc;border-left-width:0;border-right-width:0;border-style:solid;border-top-width:1px;padding:4px 0}

.tinymce__oxide--tox .tinymce__oxide--tox-collection--list .tinymce__oxide--tox-collection__group:first-child{border-top-width:0}

.tinymce__oxide--tox .tinymce__oxide--tox-collection__group-heading{background-color:#e6e6e6;color:rgba(34,47,62,.7);cursor:default;font-size:12px;font-style:normal;font-weight:400;margin-bottom:4px;margin-top:-4px;padding:4px 8px;text-transform:none;-webkit-touch-callout:none;-webkit-user-select:none;user-select:none}

.tinymce__oxide--tox .tinymce__oxide--tox-collection__item{align-items:center;color:#222f3e;cursor:pointer;display:flex;-webkit-touch-callout:none;-webkit-user-select:none;user-select:none}

.tinymce__oxide--tox .tinymce__oxide--tox-collection--list .tinymce__oxide--tox-collection__item{padding:4px 8px}

.tinymce__oxide--tox .tinymce__oxide--tox-collection--toolbar .tinymce__oxide--tox-collection__item{border-radius:3px;padding:4px}

.tinymce__oxide--tox .tinymce__oxide--tox-collection--grid .tinymce__oxide--tox-collection__item{border-radius:3px;padding:4px}

.tinymce__oxide--tox .tinymce__oxide--tox-collection--list .tinymce__oxide--tox-collection__item--enabled{background-color:#fff;color:#222f3e}

.tinymce__oxide--tox .tinymce__oxide--tox-collection--list .tinymce__oxide--tox-collection__item--active{background-color:#dee0e2}

.tinymce__oxide--tox .tinymce__oxide--tox-collection--toolbar .tinymce__oxide--tox-collection__item--enabled{background-color:#c8cbcf;color:#222f3e}

.tinymce__oxide--tox .tinymce__oxide--tox-collection--toolbar .tinymce__oxide--tox-collection__item--active{background-color:#dee0e2}

.tinymce__oxide--tox .tinymce__oxide--tox-collection--grid .tinymce__oxide--tox-collection__item--enabled{background-color:#c8cbcf;color:#222f3e}

.tinymce__oxide--tox .tinymce__oxide--tox-collection--grid .tinymce__oxide--tox-collection__item--active:not(.tinymce__oxide--tox-collection__item--state-disabled){background-color:#dee0e2;color:#222f3e}

.tinymce__oxide--tox .tinymce__oxide--tox-collection--list .tinymce__oxide--tox-collection__item--active:not(.tinymce__oxide--tox-collection__item--state-disabled){color:#222f3e}

.tinymce__oxide--tox .tinymce__oxide--tox-collection--toolbar .tinymce__oxide--tox-collection__item--active:not(.tinymce__oxide--tox-collection__item--state-disabled){color:#222f3e}

.tinymce__oxide--tox .tinymce__oxide--tox-collection__item--state-disabled{background-color:transparent;color:rgba(34,47,62,.5);cursor:not-allowed}

.tinymce__oxide--tox .tinymce__oxide--tox-collection__item-checkmark,.tinymce__oxide--tox .tinymce__oxide--tox-collection__item-icon{align-items:center;display:flex;height:24px;justify-content:center;width:24px}

.tinymce__oxide--tox .tinymce__oxide--tox-collection__item-checkmark svg,.tinymce__oxide--tox .tinymce__oxide--tox-collection__item-icon svg{fill:currentColor}

.tinymce__oxide--tox .tinymce__oxide--tox-collection--toolbar-lg .tinymce__oxide--tox-collection__item-icon{height:48px;width:48px}

.tinymce__oxide--tox .tinymce__oxide--tox-collection__item-label{color:currentColor;display:inline-block;flex:1;-ms-flex-preferred-size:auto;font-size:14px;font-style:normal;font-weight:400;line-height:24px;text-transform:none;word-break:break-all}

.tinymce__oxide--tox .tinymce__oxide--tox-collection__item-accessory{color:rgba(34,47,62,.7);display:inline-block;font-size:14px;height:24px;line-height:24px;text-transform:none}

.tinymce__oxide--tox .tinymce__oxide--tox-collection__item-caret{align-items:center;display:flex;min-height:24px}

.tinymce__oxide--tox .tinymce__oxide--tox-collection__item-caret::after{content:'';font-size:0;min-height:inherit}

.tinymce__oxide--tox .tinymce__oxide--tox-collection__item-caret svg{fill:#222f3e}

.tinymce__oxide--tox .tinymce__oxide--tox-collection--list .tinymce__oxide--tox-collection__item:not(.tinymce__oxide--tox-collection__item--enabled) .tinymce__oxide--tox-collection__item-checkmark svg{display:none}

.tinymce__oxide--tox .tinymce__oxide--tox-collection--list .tinymce__oxide--tox-collection__item:not(.tinymce__oxide--tox-collection__item--enabled) .tinymce__oxide--tox-collection__item-accessory+.tinymce__oxide--tox-collection__item-checkmark{display:none}

.tinymce__oxide--tox .tinymce__oxide--tox-collection--horizontal{background-color:#fff;border:1px solid #ccc;border-radius:3px;box-shadow:0 1px 3px rgba(0,0,0,.15);display:flex;flex:0 0 auto;flex-shrink:0;flex-wrap:nowrap;margin-bottom:0;overflow-x:auto;padding:0}

.tinymce__oxide--tox .tinymce__oxide--tox-collection--horizontal .tinymce__oxide--tox-collection__group{align-items:center;display:flex;flex-wrap:nowrap;margin:0;padding:0 4px}

.tinymce__oxide--tox .tinymce__oxide--tox-collection--horizontal .tinymce__oxide--tox-collection__item{height:34px;margin:2px 0 3px 0;padding:0 4px}

.tinymce__oxide--tox .tinymce__oxide--tox-collection--horizontal .tinymce__oxide--tox-collection__item-label{white-space:nowrap}

.tinymce__oxide--tox .tinymce__oxide--tox-collection--horizontal .tinymce__oxide--tox-collection__item-caret{margin-left:4px}

.tinymce__oxide--tox .tinymce__oxide--tox-collection__item-container{display:flex}

.tinymce__oxide--tox .tinymce__oxide--tox-collection__item-container--row{align-items:center;flex:1 1 auto;flex-direction:row}

.tinymce__oxide--tox .tinymce__oxide--tox-collection__item-container--row.tinymce__oxide--tox-collection__item-container--align-left{margin-right:auto}

.tinymce__oxide--tox .tinymce__oxide--tox-collection__item-container--row.tinymce__oxide--tox-collection__item-container--align-right{justify-content:flex-end;margin-left:auto}

.tinymce__oxide--tox .tinymce__oxide--tox-collection__item-container--row.tinymce__oxide--tox-collection__item-container--valign-top{align-items:flex-start;margin-bottom:auto}

.tinymce__oxide--tox .tinymce__oxide--tox-collection__item-container--row.tinymce__oxide--tox-collection__item-container--valign-middle{align-items:center}

.tinymce__oxide--tox .tinymce__oxide--tox-collection__item-container--row.tinymce__oxide--tox-collection__item-container--valign-bottom{align-items:flex-end;margin-top:auto}

.tinymce__oxide--tox .tinymce__oxide--tox-collection__item-container--column{align-self:center;flex:1 1 auto;flex-direction:column}

.tinymce__oxide--tox .tinymce__oxide--tox-collection__item-container--column.tinymce__oxide--tox-collection__item-container--align-left{align-items:flex-start}

.tinymce__oxide--tox .tinymce__oxide--tox-collection__item-container--column.tinymce__oxide--tox-collection__item-container--align-right{align-items:flex-end}

.tinymce__oxide--tox .tinymce__oxide--tox-collection__item-container--column.tinymce__oxide--tox-collection__item-container--valign-top{align-self:flex-start}

.tinymce__oxide--tox .tinymce__oxide--tox-collection__item-container--column.tinymce__oxide--tox-collection__item-container--valign-middle{align-self:center}

.tinymce__oxide--tox .tinymce__oxide--tox-collection__item-container--column.tinymce__oxide--tox-collection__item-container--valign-bottom{align-self:flex-end}

.tinymce__oxide--tox:not([dir=rtl]) .tinymce__oxide--tox-collection--horizontal .tinymce__oxide--tox-collection__group:not(:last-of-type){border-right:1px solid #ccc}

.tinymce__oxide--tox:not([dir=rtl]) .tinymce__oxide--tox-collection--list .tinymce__oxide--tox-collection__item>:not(:first-child){margin-left:8px}

.tinymce__oxide--tox:not([dir=rtl]) .tinymce__oxide--tox-collection--list .tinymce__oxide--tox-collection__item>.tinymce__oxide--tox-collection__item-label:first-child{margin-left:4px}

.tinymce__oxide--tox:not([dir=rtl]) .tinymce__oxide--tox-collection__item-accessory{margin-left:16px;text-align:right}

[dir="ltr"] .tinymce__oxide--tox:not([dir=rtl]) .tinymce__oxide--tox-collection__item-accessory{text-align:right}

[dir="rtl"] .tinymce__oxide--tox:not([dir=rtl]) .tinymce__oxide--tox-collection__item-accessory{text-align:right}

.tinymce__oxide--tox:not([dir=rtl]) .tinymce__oxide--tox-collection .tinymce__oxide--tox-collection__item-caret{margin-left:16px}

.tinymce__oxide--tox[dir=rtl] .tinymce__oxide--tox-collection--horizontal .tinymce__oxide--tox-collection__group:not(:last-of-type){border-left:1px solid #ccc}

.tinymce__oxide--tox[dir=rtl] .tinymce__oxide--tox-collection--list .tinymce__oxide--tox-collection__item>:not(:first-child){margin-right:8px}

.tinymce__oxide--tox[dir=rtl] .tinymce__oxide--tox-collection--list .tinymce__oxide--tox-collection__item>.tinymce__oxide--tox-collection__item-label:first-child{margin-right:4px}

.tinymce__oxide--tox[dir=rtl] .tinymce__oxide--tox-collection__item-icon-rtl .tinymce__oxide--tox-collection__item-icon svg{transform:rotateY(180deg)}

.tinymce__oxide--tox[dir=rtl] .tinymce__oxide--tox-collection__item-accessory{margin-right:16px;text-align:left}

[dir="ltr"] .tinymce__oxide--tox[dir=rtl] .tinymce__oxide--tox-collection__item-accessory{text-align:left}

[dir="rtl"] .tinymce__oxide--tox[dir=rtl] .tinymce__oxide--tox-collection__item-accessory{text-align:left}

.tinymce__oxide--tox[dir=rtl] .tinymce__oxide--tox-collection .tinymce__oxide--tox-collection__item-caret{margin-right:16px;transform:rotateY(180deg)}

.tinymce__oxide--tox[dir=rtl] .tinymce__oxide--tox-collection--horizontal .tinymce__oxide--tox-collection__item-caret{margin-right:4px}

.tinymce__oxide--tox .tinymce__oxide--tox-color-picker-container{display:flex;flex-direction:row;height:225px;margin:0}

.tinymce__oxide--tox .tinymce__oxide--tox-sv-palette{box-sizing:border-box;display:flex;height:100%}

.tinymce__oxide--tox .tinymce__oxide--tox-sv-palette-spectrum{height:100%}

.tinymce__oxide--tox .tinymce__oxide--tox-sv-palette,.tinymce__oxide--tox .tinymce__oxide--tox-sv-palette-spectrum{width:225px}

.tinymce__oxide--tox .tinymce__oxide--tox-sv-palette-thumb{background:0 0;border:1px solid #000;border-radius:50%;box-sizing:content-box;height:12px;position:absolute;width:12px}

.tinymce__oxide--tox .tinymce__oxide--tox-sv-palette-inner-thumb{border:1px solid #fff;border-radius:50%;height:10px;position:absolute;width:10px}

.tinymce__oxide--tox .tinymce__oxide--tox-hue-slider{box-sizing:border-box;height:100%;width:25px}

.tinymce__oxide--tox .tinymce__oxide--tox-hue-slider-spectrum{background:linear-gradient(to bottom,red,#ff0080,#f0f,#8000ff,#00f,#0080ff,#0ff,#00ff80,#0f0,#80ff00,#ff0,#ff8000,red);height:100%;width:100%}

.tinymce__oxide--tox .tinymce__oxide--tox-hue-slider,.tinymce__oxide--tox .tinymce__oxide--tox-hue-slider-spectrum{width:20px}

.tinymce__oxide--tox .tinymce__oxide--tox-hue-slider-thumb{background:#fff;border:1px solid #000;box-sizing:content-box;height:4px;width:100%}

.tinymce__oxide--tox .tinymce__oxide--tox-rgb-form{display:flex;flex-direction:column;justify-content:space-between}

.tinymce__oxide--tox .tinymce__oxide--tox-rgb-form div{align-items:center;display:flex;justify-content:space-between;margin-bottom:5px;width:inherit}

.tinymce__oxide--tox .tinymce__oxide--tox-rgb-form input{width:6em}

.tinymce__oxide--tox .tinymce__oxide--tox-rgb-form input.tinymce__oxide--tox-invalid{border:1px solid red!important}

.tinymce__oxide--tox .tinymce__oxide--tox-rgb-form .tinymce__oxide--tox-rgba-preview{border:1px solid #000;flex-grow:2;margin-bottom:0}

.tinymce__oxide--tox:not([dir=rtl]) .tinymce__oxide--tox-sv-palette{margin-right:15px}

.tinymce__oxide--tox:not([dir=rtl]) .tinymce__oxide--tox-hue-slider{margin-right:15px}

.tinymce__oxide--tox:not([dir=rtl]) .tinymce__oxide--tox-hue-slider-thumb{margin-left:-1px}

.tinymce__oxide--tox:not([dir=rtl]) .tinymce__oxide--tox-rgb-form label{margin-right:.5em}

.tinymce__oxide--tox[dir=rtl] .tinymce__oxide--tox-sv-palette{margin-left:15px}

.tinymce__oxide--tox[dir=rtl] .tinymce__oxide--tox-hue-slider{margin-left:15px}

.tinymce__oxide--tox[dir=rtl] .tinymce__oxide--tox-hue-slider-thumb{margin-right:-1px}

.tinymce__oxide--tox[dir=rtl] .tinymce__oxide--tox-rgb-form label{margin-left:.5em}

.tinymce__oxide--tox .tinymce__oxide--tox-toolbar .tinymce__oxide--tox-swatches,.tinymce__oxide--tox .tinymce__oxide--tox-toolbar__overflow .tinymce__oxide--tox-swatches,.tinymce__oxide--tox .tinymce__oxide--tox-toolbar__primary .tinymce__oxide--tox-swatches{margin:2px 0 3px 4px}

.tinymce__oxide--tox .tinymce__oxide--tox-collection--list .tinymce__oxide--tox-collection__group .tinymce__oxide--tox-swatches-menu{border:0;margin:-4px 0}

.tinymce__oxide--tox .tinymce__oxide--tox-swatches__row{display:flex}

.tinymce__oxide--tox .tinymce__oxide--tox-swatch{height:30px;transition:transform .15s,box-shadow .15s;width:30px}

.tinymce__oxide--tox .tinymce__oxide--tox-swatch:focus,.tinymce__oxide--tox .tinymce__oxide--tox-swatch:hover{box-shadow:0 0 0 1px rgba(127,127,127,.3) inset;transform:scale(.8)}

.tinymce__oxide--tox .tinymce__oxide--tox-swatch--remove{align-items:center;display:flex;justify-content:center}

.tinymce__oxide--tox .tinymce__oxide--tox-swatch--remove svg path{stroke:#e74c3c}

.tinymce__oxide--tox .tinymce__oxide--tox-swatches__picker-btn{align-items:center;background-color:transparent;border:0;cursor:pointer;display:flex;height:30px;justify-content:center;outline:0;padding:0;width:30px}

.tinymce__oxide--tox .tinymce__oxide--tox-swatches__picker-btn svg{height:24px;width:24px}

.tinymce__oxide--tox .tinymce__oxide--tox-swatches__picker-btn:hover{background:#dee0e2}

.tinymce__oxide--tox:not([dir=rtl]) .tinymce__oxide--tox-swatches__picker-btn{margin-left:auto}

.tinymce__oxide--tox[dir=rtl] .tinymce__oxide--tox-swatches__picker-btn{margin-right:auto}

.tinymce__oxide--tox .tinymce__oxide--tox-comment-thread{background:#fff;position:relative}

.tinymce__oxide--tox .tinymce__oxide--tox-comment-thread>:not(:first-child){margin-top:8px}

.tinymce__oxide--tox .tinymce__oxide--tox-comment{background:#fff;border:1px solid #ccc;border-radius:3px;box-shadow:0 4px 8px 0 rgba(34,47,62,.1);padding:8px 8px 16px 8px;position:relative}

.tinymce__oxide--tox .tinymce__oxide--tox-comment__header{align-items:center;color:#222f3e;display:flex;justify-content:space-between}

.tinymce__oxide--tox .tinymce__oxide--tox-comment__date{color:rgba(34,47,62,.7);font-size:12px}

.tinymce__oxide--tox .tinymce__oxide--tox-comment__body{color:#222f3e;font-size:14px;font-style:normal;font-weight:400;line-height:1.3;margin-top:8px;position:relative;text-transform:none;text-transform:initial}

.tinymce__oxide--tox .tinymce__oxide--tox-comment__body textarea{resize:none;white-space:normal;width:100%}

.tinymce__oxide--tox .tinymce__oxide--tox-comment__expander{padding-top:8px}

.tinymce__oxide--tox .tinymce__oxide--tox-comment__expander p{color:rgba(34,47,62,.7);font-size:14px;font-style:normal}

.tinymce__oxide--tox .tinymce__oxide--tox-comment__body p{margin:0}

.tinymce__oxide--tox .tinymce__oxide--tox-comment__buttonspacing{padding-top:16px;text-align:center}

[dir="ltr"] .tinymce__oxide--tox .tinymce__oxide--tox-comment__buttonspacing{text-align:center}

[dir="rtl"] .tinymce__oxide--tox .tinymce__oxide--tox-comment__buttonspacing{text-align:center}

.tinymce__oxide--tox .tinymce__oxide--tox-comment-thread__overlay::after{background:#fff;bottom:0;content:"";display:flex;left:0;opacity:.9;position:absolute;right:0;top:0;z-index:5}

.tinymce__oxide--tox .tinymce__oxide--tox-comment__reply{display:flex;flex-shrink:0;flex-wrap:wrap;justify-content:flex-end;margin-top:8px}

.tinymce__oxide--tox .tinymce__oxide--tox-comment__reply>:first-child{margin-bottom:8px;width:100%}

.tinymce__oxide--tox .tinymce__oxide--tox-comment__edit{display:flex;flex-wrap:wrap;justify-content:flex-end;margin-top:16px}

.tinymce__oxide--tox .tinymce__oxide--tox-comment__gradient::after{background:linear-gradient(rgba(255,255,255,0),#fff);bottom:0;content:"";display:block;height:5em;margin-top:-40px;position:absolute;width:100%}

.tinymce__oxide--tox .tinymce__oxide--tox-comment__overlay{background:#fff;bottom:0;display:flex;flex-direction:column;flex-grow:1;left:0;opacity:.9;position:absolute;right:0;text-align:center;top:0;z-index:5}

[dir="ltr"] .tinymce__oxide--tox .tinymce__oxide--tox-comment__overlay{text-align:center}

[dir="rtl"] .tinymce__oxide--tox .tinymce__oxide--tox-comment__overlay{text-align:center}

.tinymce__oxide--tox .tinymce__oxide--tox-comment__loading-text{align-items:center;color:#222f3e;display:flex;flex-direction:column;position:relative}

.tinymce__oxide--tox .tinymce__oxide--tox-comment__loading-text>div{padding-bottom:16px}

.tinymce__oxide--tox .tinymce__oxide--tox-comment__overlaytext{bottom:0;flex-direction:column;font-size:14px;left:0;padding:1em;position:absolute;right:0;top:0;z-index:10}

.tinymce__oxide--tox .tinymce__oxide--tox-comment__overlaytext p{background-color:#fff;box-shadow:0 0 8px 8px #fff;color:#222f3e;text-align:center}

[dir="ltr"] .tinymce__oxide--tox .tinymce__oxide--tox-comment__overlaytext p{text-align:center}

[dir="rtl"] .tinymce__oxide--tox .tinymce__oxide--tox-comment__overlaytext p{text-align:center}

.tinymce__oxide--tox .tinymce__oxide--tox-comment__overlaytext div:nth-of-type(2){font-size:.8em}

.tinymce__oxide--tox .tinymce__oxide--tox-comment__busy-spinner{align-items:center;background-color:#fff;bottom:0;display:flex;justify-content:center;left:0;position:absolute;right:0;top:0;z-index:20}

.tinymce__oxide--tox .tinymce__oxide--tox-comment__scroll{display:flex;flex-direction:column;flex-shrink:1;overflow:auto}

.tinymce__oxide--tox .tinymce__oxide--tox-conversations{margin:8px}

.tinymce__oxide--tox:not([dir=rtl]) .tinymce__oxide--tox-comment__edit{margin-left:8px}

.tinymce__oxide--tox:not([dir=rtl]) .tinymce__oxide--tox-comment__buttonspacing>:last-child,.tinymce__oxide--tox:not([dir=rtl]) .tinymce__oxide--tox-comment__edit>:last-child,.tinymce__oxide--tox:not([dir=rtl]) .tinymce__oxide--tox-comment__reply>:last-child{margin-left:8px}

.tinymce__oxide--tox[dir=rtl] .tinymce__oxide--tox-comment__edit{margin-right:8px}

.tinymce__oxide--tox[dir=rtl] .tinymce__oxide--tox-comment__buttonspacing>:last-child,.tinymce__oxide--tox[dir=rtl] .tinymce__oxide--tox-comment__edit>:last-child,.tinymce__oxide--tox[dir=rtl] .tinymce__oxide--tox-comment__reply>:last-child{margin-right:8px}

.tinymce__oxide--tox .tinymce__oxide--tox-user{align-items:center;display:flex}

.tinymce__oxide--tox .tinymce__oxide--tox-user__avatar svg{fill:rgba(34,47,62,.7)}

.tinymce__oxide--tox .tinymce__oxide--tox-user__name{color:rgba(34,47,62,.7);font-size:12px;font-style:normal;font-weight:700;text-transform:uppercase}

.tinymce__oxide--tox:not([dir=rtl]) .tinymce__oxide--tox-user__avatar svg{margin-right:8px}

.tinymce__oxide--tox:not([dir=rtl]) .tinymce__oxide--tox-user__avatar+.tinymce__oxide--tox-user__name{margin-left:8px}

.tinymce__oxide--tox[dir=rtl] .tinymce__oxide--tox-user__avatar svg{margin-left:8px}

.tinymce__oxide--tox[dir=rtl] .tinymce__oxide--tox-user__avatar+.tinymce__oxide--tox-user__name{margin-right:8px}

.tinymce__oxide--tox .tinymce__oxide--tox-dialog-wrap{align-items:center;bottom:0;display:flex;justify-content:center;left:0;position:fixed;right:0;top:0;z-index:1100}

.tinymce__oxide--tox .tinymce__oxide--tox-dialog-wrap__backdrop{background-color:rgba(255,255,255,.75);bottom:0;left:0;position:absolute;right:0;top:0;z-index:1}

.tinymce__oxide--tox .tinymce__oxide--tox-dialog-wrap__backdrop--opaque{background-color:#fff}

.tinymce__oxide--tox .tinymce__oxide--tox-dialog{background-color:#fff;border-color:#ccc;border-radius:3px;border-style:solid;border-width:1px;box-shadow:0 16px 16px -10px rgba(34,47,62,.15),0 0 40px 1px rgba(34,47,62,.15);display:flex;flex-direction:column;max-height:100%;max-width:480px;overflow:hidden;position:relative;width:95vw;z-index:2}

@media only screen and (max-width:767px){body:not(.tinymce__oxide--tox-force-desktop) .tinymce__oxide--tox .tinymce__oxide--tox-dialog{align-self:flex-start;margin:8px auto;width:calc(100vw - 16px)}}

.tinymce__oxide--tox .tinymce__oxide--tox-dialog-inline{z-index:1100}

.tinymce__oxide--tox .tinymce__oxide--tox-dialog__header{align-items:center;background-color:#fff;border-bottom:none;color:#222f3e;display:flex;font-size:16px;justify-content:space-between;padding:8px 16px 0 16px;position:relative}

.tinymce__oxide--tox .tinymce__oxide--tox-dialog__header .tinymce__oxide--tox-button{z-index:1}

.tinymce__oxide--tox .tinymce__oxide--tox-dialog__draghandle{cursor:grab;height:100%;left:0;position:absolute;top:0;width:100%}

.tinymce__oxide--tox .tinymce__oxide--tox-dialog__draghandle:active{cursor:grabbing}

.tinymce__oxide--tox .tinymce__oxide--tox-dialog__dismiss{margin-left:auto}

.tinymce__oxide--tox .tinymce__oxide--tox-dialog__title{font-family:-apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,Oxygen-Sans,Ubuntu,Cantarell,"Helvetica Neue",sans-serif;font-size:20px;font-style:normal;font-weight:400;line-height:1.3;margin:0;text-transform:none}

.tinymce__oxide--tox .tinymce__oxide--tox-dialog__body{color:#222f3e;display:flex;flex:1;-ms-flex-preferred-size:auto;font-size:16px;font-style:normal;font-weight:400;line-height:1.3;min-width:0;text-align:left;text-transform:none}

[dir="ltr"] .tinymce__oxide--tox .tinymce__oxide--tox-dialog__body{text-align:left}

[dir="rtl"] .tinymce__oxide--tox .tinymce__oxide--tox-dialog__body{text-align:left}

@media only screen and (max-width:767px){body:not(.tinymce__oxide--tox-force-desktop) .tinymce__oxide--tox .tinymce__oxide--tox-dialog__body{flex-direction:column}}

.tinymce__oxide--tox .tinymce__oxide--tox-dialog__body-nav{align-items:flex-start;display:flex;flex-direction:column;padding:16px 16px}

@media only screen and (max-width:767px){body:not(.tinymce__oxide--tox-force-desktop) .tinymce__oxide--tox .tinymce__oxide--tox-dialog__body-nav{flex-direction:row;-webkit-overflow-scrolling:touch;overflow-x:auto;padding-bottom:0}}

.tinymce__oxide--tox .tinymce__oxide--tox-dialog__body-nav-item{border-bottom:2px solid transparent;color:rgba(34,47,62,.7);display:inline-block;font-size:14px;line-height:1.3;margin-bottom:8px;text-decoration:none;white-space:nowrap}

.tinymce__oxide--tox .tinymce__oxide--tox-dialog__body-nav-item:focus{background-color:rgba(32,122,183,.1)}

.tinymce__oxide--tox .tinymce__oxide--tox-dialog__body-nav-item--active{border-bottom:2px solid #207ab7;color:#207ab7}

.tinymce__oxide--tox .tinymce__oxide--tox-dialog__body-content{box-sizing:border-box;display:flex;flex:1;flex-direction:column;-ms-flex-preferred-size:auto;max-height:650px;overflow:auto;-webkit-overflow-scrolling:touch;padding:16px 16px}

.tinymce__oxide--tox .tinymce__oxide--tox-dialog__body-content>*{margin-bottom:0;margin-top:16px}

.tinymce__oxide--tox .tinymce__oxide--tox-dialog__body-content>:first-child{margin-top:0}

.tinymce__oxide--tox .tinymce__oxide--tox-dialog__body-content>:last-child{margin-bottom:0}

.tinymce__oxide--tox .tinymce__oxide--tox-dialog__body-content>:only-child{margin-bottom:0;margin-top:0}

.tinymce__oxide--tox .tinymce__oxide--tox-dialog__body-content a{color:#207ab7;cursor:pointer;text-decoration:none}

.tinymce__oxide--tox .tinymce__oxide--tox-dialog__body-content a:focus,.tinymce__oxide--tox .tinymce__oxide--tox-dialog__body-content a:hover{color:#185d8c;text-decoration:none}

.tinymce__oxide--tox .tinymce__oxide--tox-dialog__body-content a:active{color:#185d8c;text-decoration:none}

.tinymce__oxide--tox .tinymce__oxide--tox-dialog__body-content svg{fill:#222f3e}

.tinymce__oxide--tox .tinymce__oxide--tox-dialog__body-content ul{display:block;list-style-type:disc;margin-bottom:16px;margin-inline-end:0;margin-inline-start:0;padding-inline-start:2.5rem}

[dir="ltr"] .tinymce__oxide--tox .tinymce__oxide--tox-dialog__body-content ul{margin-right:0;margin-left:0;padding-left:2.5rem}

[dir="rtl"] .tinymce__oxide--tox .tinymce__oxide--tox-dialog__body-content ul{margin-left:0;margin-right:0;padding-right:2.5rem}

.tinymce__oxide--tox .tinymce__oxide--tox-dialog__body-content .tinymce__oxide--tox-form__group h1{color:#222f3e;font-size:20px;font-style:normal;font-weight:700;letter-spacing:normal;margin-bottom:16px;margin-top:2rem;text-transform:none}

.tinymce__oxide--tox .tinymce__oxide--tox-dialog__body-content .tinymce__oxide--tox-form__group h2{color:#222f3e;font-size:16px;font-style:normal;font-weight:700;letter-spacing:normal;margin-bottom:16px;margin-top:2rem;text-transform:none}

.tinymce__oxide--tox .tinymce__oxide--tox-dialog__body-content .tinymce__oxide--tox-form__group p{margin-bottom:16px}

.tinymce__oxide--tox .tinymce__oxide--tox-dialog__body-content .tinymce__oxide--tox-form__group h1:first-child,.tinymce__oxide--tox .tinymce__oxide--tox-dialog__body-content .tinymce__oxide--tox-form__group h2:first-child,.tinymce__oxide--tox .tinymce__oxide--tox-dialog__body-content .tinymce__oxide--tox-form__group p:first-child{margin-top:0}

.tinymce__oxide--tox .tinymce__oxide--tox-dialog__body-content .tinymce__oxide--tox-form__group h1:last-child,.tinymce__oxide--tox .tinymce__oxide--tox-dialog__body-content .tinymce__oxide--tox-form__group h2:last-child,.tinymce__oxide--tox .tinymce__oxide--tox-dialog__body-content .tinymce__oxide--tox-form__group p:last-child{margin-bottom:0}

.tinymce__oxide--tox .tinymce__oxide--tox-dialog__body-content .tinymce__oxide--tox-form__group h1:only-child,.tinymce__oxide--tox .tinymce__oxide--tox-dialog__body-content .tinymce__oxide--tox-form__group h2:only-child,.tinymce__oxide--tox .tinymce__oxide--tox-dialog__body-content .tinymce__oxide--tox-form__group p:only-child{margin-bottom:0;margin-top:0}

.tinymce__oxide--tox .tinymce__oxide--tox-dialog--width-lg{height:650px;max-width:1200px}

.tinymce__oxide--tox .tinymce__oxide--tox-dialog--width-md{max-width:800px}

.tinymce__oxide--tox .tinymce__oxide--tox-dialog--width-md .tinymce__oxide--tox-dialog__body-content{overflow:auto}

.tinymce__oxide--tox .tinymce__oxide--tox-dialog__body-content--centered{text-align:center}

[dir="ltr"] .tinymce__oxide--tox .tinymce__oxide--tox-dialog__body-content--centered{text-align:center}

[dir="rtl"] .tinymce__oxide--tox .tinymce__oxide--tox-dialog__body-content--centered{text-align:center}

.tinymce__oxide--tox .tinymce__oxide--tox-dialog__footer{align-items:center;background-color:#fff;border-top:1px solid #ccc;display:flex;justify-content:space-between;padding:8px 16px}

.tinymce__oxide--tox .tinymce__oxide--tox-dialog__footer-end,.tinymce__oxide--tox .tinymce__oxide--tox-dialog__footer-start{display:flex}

.tinymce__oxide--tox .tinymce__oxide--tox-dialog__busy-spinner{align-items:center;background-color:rgba(255,255,255,.75);bottom:0;display:flex;justify-content:center;left:0;position:absolute;right:0;top:0;z-index:3}

.tinymce__oxide--tox .tinymce__oxide--tox-dialog__table{border-collapse:collapse;width:100%}

.tinymce__oxide--tox .tinymce__oxide--tox-dialog__table thead th{font-weight:700;padding-bottom:8px}

.tinymce__oxide--tox .tinymce__oxide--tox-dialog__table tbody tr{border-bottom:1px solid #ccc}

.tinymce__oxide--tox .tinymce__oxide--tox-dialog__table tbody tr:last-child{border-bottom:none}

.tinymce__oxide--tox .tinymce__oxide--tox-dialog__table td{padding-bottom:8px;padding-top:8px}

.tinymce__oxide--tox .tinymce__oxide--tox-dialog__popups{position:absolute;width:100%;z-index:1100}

.tinymce__oxide--tox .tinymce__oxide--tox-dialog__body-iframe{display:flex;flex:1;flex-direction:column;-ms-flex-preferred-size:auto}

.tinymce__oxide--tox .tinymce__oxide--tox-dialog__body-iframe .tinymce__oxide--tox-navobj{display:flex;flex:1;-ms-flex-preferred-size:auto}

.tinymce__oxide--tox .tinymce__oxide--tox-dialog__body-iframe .tinymce__oxide--tox-navobj :nth-child(2){flex:1;-ms-flex-preferred-size:auto;height:100%}

.tinymce__oxide--tox .tinymce__oxide--tox-dialog-dock-fadeout{opacity:0;visibility:hidden}

.tinymce__oxide--tox .tinymce__oxide--tox-dialog-dock-fadein{opacity:1;visibility:visible}

.tinymce__oxide--tox .tinymce__oxide--tox-dialog-dock-transition{transition:visibility 0s linear .3s,opacity .3s ease}

.tinymce__oxide--tox .tinymce__oxide--tox-dialog-dock-transition.tinymce__oxide--tox-dialog-dock-fadein{transition-delay:0s}

.tinymce__oxide--tox.tinymce__oxide--tox-platform-ie .tinymce__oxide--tox-dialog-wrap{position:-ms-device-fixed}

@media only screen and (max-width:767px){body:not(.tinymce__oxide--tox-force-desktop) .tinymce__oxide--tox:not([dir=rtl]) .tinymce__oxide--tox-dialog__body-nav{margin-right:0}}

@media only screen and (max-width:767px){body:not(.tinymce__oxide--tox-force-desktop) .tinymce__oxide--tox:not([dir=rtl]) .tinymce__oxide--tox-dialog__body-nav-item:not(:first-child){margin-left:8px}}

.tinymce__oxide--tox:not([dir=rtl]) .tinymce__oxide--tox-dialog__footer .tinymce__oxide--tox-dialog__footer-end>*,.tinymce__oxide--tox:not([dir=rtl]) .tinymce__oxide--tox-dialog__footer .tinymce__oxide--tox-dialog__footer-start>*{margin-left:8px}

.tinymce__oxide--tox[dir=rtl] .tinymce__oxide--tox-dialog__body{text-align:right}

[dir="ltr"] .tinymce__oxide--tox[dir=rtl] .tinymce__oxide--tox-dialog__body{text-align:right}

[dir="rtl"] .tinymce__oxide--tox[dir=rtl] .tinymce__oxide--tox-dialog__body{text-align:right}

@media only screen and (max-width:767px){body:not(.tinymce__oxide--tox-force-desktop) .tinymce__oxide--tox[dir=rtl] .tinymce__oxide--tox-dialog__body-nav{margin-left:0}}

@media only screen and (max-width:767px){body:not(.tinymce__oxide--tox-force-desktop) .tinymce__oxide--tox[dir=rtl] .tinymce__oxide--tox-dialog__body-nav-item:not(:first-child){margin-right:8px}}

.tinymce__oxide--tox[dir=rtl] .tinymce__oxide--tox-dialog__footer .tinymce__oxide--tox-dialog__footer-end>*,.tinymce__oxide--tox[dir=rtl] .tinymce__oxide--tox-dialog__footer .tinymce__oxide--tox-dialog__footer-start>*{margin-right:8px}

body.tinymce__oxide--tox-dialog__disable-scroll{overflow:hidden}

.tinymce__oxide--tox .tinymce__oxide--tox-dropzone-container{display:flex;flex:1;-ms-flex-preferred-size:auto}

.tinymce__oxide--tox .tinymce__oxide--tox-dropzone{align-items:center;background:#fff;border:2px dashed #ccc;box-sizing:border-box;display:flex;flex-direction:column;flex-grow:1;justify-content:center;min-height:100px;padding:10px}

.tinymce__oxide--tox .tinymce__oxide--tox-dropzone p{color:rgba(34,47,62,.7);margin:0 0 16px 0}

.tinymce__oxide--tox .tinymce__oxide--tox-edit-area{display:flex;flex:1;-ms-flex-preferred-size:auto;overflow:hidden;position:relative}

.tinymce__oxide--tox .tinymce__oxide--tox-edit-area__iframe{background-color:#fff;border:0;box-sizing:border-box;flex:1;-ms-flex-preferred-size:auto;height:100%;position:absolute;width:100%}

.tinymce__oxide--tox.tinymce__oxide--tox-inline-edit-area{border:1px dotted #ccc}

.tinymce__oxide--tox .tinymce__oxide--tox-editor-container{display:flex;flex:1 1 auto;flex-direction:column;overflow:hidden}

.tinymce__oxide--tox .tinymce__oxide--tox-editor-header{z-index:1}

.tinymce__oxide--tox:not(.tinymce__oxide--tox-tinymce-inline) .tinymce__oxide--tox-editor-header{box-shadow:none;transition:box-shadow .5s}

.tinymce__oxide--tox.tinymce__oxide--tox-tinymce--toolbar-bottom .tinymce__oxide--tox-editor-header,.tinymce__oxide--tox.tinymce__oxide--tox-tinymce-inline .tinymce__oxide--tox-editor-header{margin-bottom:-1px}

.tinymce__oxide--tox.tinymce__oxide--tox-tinymce--toolbar-sticky-on .tinymce__oxide--tox-editor-header{background-color:transparent;box-shadow:0 4px 4px -3px rgba(0,0,0,.25)}

.tinymce__oxide--tox-editor-dock-fadeout{opacity:0;visibility:hidden}

.tinymce__oxide--tox-editor-dock-fadein{opacity:1;visibility:visible}

.tinymce__oxide--tox-editor-dock-transition{transition:visibility 0s linear .25s,opacity .25s ease}

.tinymce__oxide--tox-editor-dock-transition.tinymce__oxide--tox-editor-dock-fadein{transition-delay:0s}

.tinymce__oxide--tox .tinymce__oxide--tox-control-wrap{flex:1;position:relative}

.tinymce__oxide--tox .tinymce__oxide--tox-control-wrap:not(.tinymce__oxide--tox-control-wrap--status-invalid) .tinymce__oxide--tox-control-wrap__status-icon-invalid,.tinymce__oxide--tox .tinymce__oxide--tox-control-wrap:not(.tinymce__oxide--tox-control-wrap--status-unknown) .tinymce__oxide--tox-control-wrap__status-icon-unknown,.tinymce__oxide--tox .tinymce__oxide--tox-control-wrap:not(.tinymce__oxide--tox-control-wrap--status-valid) .tinymce__oxide--tox-control-wrap__status-icon-valid{display:none}

.tinymce__oxide--tox .tinymce__oxide--tox-control-wrap svg{display:block}

.tinymce__oxide--tox .tinymce__oxide--tox-control-wrap__status-icon-wrap{position:absolute;top:50%;transform:translateY(-50%)}

.tinymce__oxide--tox .tinymce__oxide--tox-control-wrap__status-icon-invalid svg{fill:#c00}

.tinymce__oxide--tox .tinymce__oxide--tox-control-wrap__status-icon-unknown svg{fill:orange}

.tinymce__oxide--tox .tinymce__oxide--tox-control-wrap__status-icon-valid svg{fill:green}

.tinymce__oxide--tox:not([dir=rtl]) .tinymce__oxide--tox-control-wrap--status-invalid .tinymce__oxide--tox-textfield,.tinymce__oxide--tox:not([dir=rtl]) .tinymce__oxide--tox-control-wrap--status-unknown .tinymce__oxide--tox-textfield,.tinymce__oxide--tox:not([dir=rtl]) .tinymce__oxide--tox-control-wrap--status-valid .tinymce__oxide--tox-textfield{padding-right:32px}

.tinymce__oxide--tox:not([dir=rtl]) .tinymce__oxide--tox-control-wrap__status-icon-wrap{right:4px}

.tinymce__oxide--tox[dir=rtl] .tinymce__oxide--tox-control-wrap--status-invalid .tinymce__oxide--tox-textfield,.tinymce__oxide--tox[dir=rtl] .tinymce__oxide--tox-control-wrap--status-unknown .tinymce__oxide--tox-textfield,.tinymce__oxide--tox[dir=rtl] .tinymce__oxide--tox-control-wrap--status-valid .tinymce__oxide--tox-textfield{padding-left:32px}

.tinymce__oxide--tox[dir=rtl] .tinymce__oxide--tox-control-wrap__status-icon-wrap{left:4px}

.tinymce__oxide--tox .tinymce__oxide--tox-autocompleter{max-width:25em}

.tinymce__oxide--tox .tinymce__oxide--tox-autocompleter .tinymce__oxide--tox-menu{max-width:25em}

.tinymce__oxide--tox .tinymce__oxide--tox-autocompleter .tinymce__oxide--tox-autocompleter-highlight{font-weight:700}

.tinymce__oxide--tox .tinymce__oxide--tox-color-input{display:flex;position:relative;z-index:1}

.tinymce__oxide--tox .tinymce__oxide--tox-color-input .tinymce__oxide--tox-textfield{z-index:-1}

.tinymce__oxide--tox .tinymce__oxide--tox-color-input span{border-color:rgba(34,47,62,.2);border-radius:3px;border-style:solid;border-width:1px;box-shadow:none;box-sizing:border-box;height:24px;position:absolute;top:6px;width:24px}

.tinymce__oxide--tox .tinymce__oxide--tox-color-input span:focus:not([aria-disabled=true]),.tinymce__oxide--tox .tinymce__oxide--tox-color-input span:hover:not([aria-disabled=true]){border-color:#207ab7;cursor:pointer}

.tinymce__oxide--tox .tinymce__oxide--tox-color-input span::before{background-image:linear-gradient(45deg,rgba(0,0,0,.25) 25%,transparent 25%),linear-gradient(-45deg,rgba(0,0,0,.25) 25%,transparent 25%),linear-gradient(45deg,transparent 75%,rgba(0,0,0,.25) 75%),linear-gradient(-45deg,transparent 75%,rgba(0,0,0,.25) 75%);background-position:0 0,0 6px,6px -6px,-6px 0;background-size:12px 12px;border:1px solid #fff;border-radius:3px;box-sizing:border-box;content:'';height:24px;left:-1px;position:absolute;top:-1px;width:24px;z-index:-1}

.tinymce__oxide--tox .tinymce__oxide--tox-color-input span[aria-disabled=true]{cursor:not-allowed}

.tinymce__oxide--tox:not([dir=rtl]) .tinymce__oxide--tox-color-input .tinymce__oxide--tox-textfield{padding-left:36px}

.tinymce__oxide--tox:not([dir=rtl]) .tinymce__oxide--tox-color-input span{left:6px}

.tinymce__oxide--tox[dir=rtl] .tinymce__oxide--tox-color-input .tinymce__oxide--tox-textfield{padding-right:36px}

.tinymce__oxide--tox[dir=rtl] .tinymce__oxide--tox-color-input span{right:6px}

.tinymce__oxide--tox .tinymce__oxide--tox-label,.tinymce__oxide--tox .tinymce__oxide--tox-toolbar-label{color:rgba(34,47,62,.7);display:block;font-size:14px;font-style:normal;font-weight:400;line-height:1.3;padding:0 8px 0 0;text-transform:none;white-space:nowrap}

.tinymce__oxide--tox .tinymce__oxide--tox-toolbar-label{padding:0 8px}

.tinymce__oxide--tox[dir=rtl] .tinymce__oxide--tox-label{padding:0 0 0 8px}

.tinymce__oxide--tox .tinymce__oxide--tox-form{display:flex;flex:1;flex-direction:column;-ms-flex-preferred-size:auto}

.tinymce__oxide--tox .tinymce__oxide--tox-form__group{box-sizing:border-box;margin-bottom:4px}

.tinymce__oxide--tox .tinymce__oxide--tox-form-group--maximize{flex:1}

.tinymce__oxide--tox .tinymce__oxide--tox-form__group--error{color:#c00}

.tinymce__oxide--tox .tinymce__oxide--tox-form__group--collection{display:flex}

.tinymce__oxide--tox .tinymce__oxide--tox-form__grid{display:flex;flex-direction:row;flex-wrap:wrap;justify-content:space-between}

.tinymce__oxide--tox .tinymce__oxide--tox-form__grid--2col>.tinymce__oxide--tox-form__group{width:calc(50% - (8px / 2))}

.tinymce__oxide--tox .tinymce__oxide--tox-form__grid--3col>.tinymce__oxide--tox-form__group{width:calc(100% / 3 - (8px / 2))}

.tinymce__oxide--tox .tinymce__oxide--tox-form__grid--4col>.tinymce__oxide--tox-form__group{width:calc(25% - (8px / 2))}

.tinymce__oxide--tox .tinymce__oxide--tox-form__controls-h-stack{align-items:center;display:flex}

.tinymce__oxide--tox .tinymce__oxide--tox-form__group--inline{align-items:center;display:flex}

.tinymce__oxide--tox .tinymce__oxide--tox-form__group--stretched{display:flex;flex:1;flex-direction:column;-ms-flex-preferred-size:auto}

.tinymce__oxide--tox .tinymce__oxide--tox-form__group--stretched .tinymce__oxide--tox-textarea{flex:1;-ms-flex-preferred-size:auto}

.tinymce__oxide--tox .tinymce__oxide--tox-form__group--stretched .tinymce__oxide--tox-navobj{display:flex;flex:1;-ms-flex-preferred-size:auto}

.tinymce__oxide--tox .tinymce__oxide--tox-form__group--stretched .tinymce__oxide--tox-navobj :nth-child(2){flex:1;-ms-flex-preferred-size:auto;height:100%}

.tinymce__oxide--tox:not([dir=rtl]) .tinymce__oxide--tox-form__controls-h-stack>:not(:first-child){margin-left:4px}

.tinymce__oxide--tox[dir=rtl] .tinymce__oxide--tox-form__controls-h-stack>:not(:first-child){margin-right:4px}

.tinymce__oxide--tox .tinymce__oxide--tox-lock.tinymce__oxide--tox-locked .tinymce__oxide--tox-lock-icon__unlock,.tinymce__oxide--tox .tinymce__oxide--tox-lock:not(.tinymce__oxide--tox-locked) .tinymce__oxide--tox-lock-icon__lock{display:none}

.tinymce__oxide--tox .tinymce__oxide--tox-listboxfield .tinymce__oxide--tox-listbox--select,.tinymce__oxide--tox .tinymce__oxide--tox-textarea,.tinymce__oxide--tox .tinymce__oxide--tox-textfield,.tinymce__oxide--tox .tinymce__oxide--tox-toolbar-textfield{-webkit-appearance:none;appearance:none;background-color:#fff;border-color:#ccc;border-radius:3px;border-style:solid;border-width:1px;box-shadow:none;box-sizing:border-box;color:#222f3e;font-family:-apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,Oxygen-Sans,Ubuntu,Cantarell,"Helvetica Neue",sans-serif;font-size:16px;line-height:24px;margin:0;min-height:34px;outline:0;padding:5px 4.75px;resize:none;width:100%}

.tinymce__oxide--tox .tinymce__oxide--tox-textarea[disabled],.tinymce__oxide--tox .tinymce__oxide--tox-textfield[disabled]{background-color:#f2f2f2;color:rgba(34,47,62,.85);cursor:not-allowed}

.tinymce__oxide--tox .tinymce__oxide--tox-listboxfield .tinymce__oxide--tox-listbox--select:focus,.tinymce__oxide--tox .tinymce__oxide--tox-textarea:focus,.tinymce__oxide--tox .tinymce__oxide--tox-textfield:focus{background-color:#fff;border-color:#207ab7;box-shadow:none;outline:0}

.tinymce__oxide--tox .tinymce__oxide--tox-toolbar-textfield{border-width:0;margin-bottom:3px;margin-top:2px;max-width:250px}

.tinymce__oxide--tox .tinymce__oxide--tox-naked-btn{background-color:transparent;border:0;border-color:transparent;box-shadow:unset;color:#207ab7;cursor:pointer;display:block;margin:0;padding:0}

.tinymce__oxide--tox .tinymce__oxide--tox-naked-btn svg{display:block;fill:#222f3e}

.tinymce__oxide--tox:not([dir=rtl]) .tinymce__oxide--tox-toolbar-textfield+*{margin-left:4px}

.tinymce__oxide--tox[dir=rtl] .tinymce__oxide--tox-toolbar-textfield+*{margin-right:4px}

.tinymce__oxide--tox .tinymce__oxide--tox-listboxfield{cursor:pointer;position:relative}

.tinymce__oxide--tox .tinymce__oxide--tox-listboxfield .tinymce__oxide--tox-listbox--select[disabled]{background-color:#f2f2f2;color:rgba(34,47,62,.85);cursor:not-allowed}

.tinymce__oxide--tox .tinymce__oxide--tox-listbox__select-label{cursor:default;flex:1;margin:0 4px}

.tinymce__oxide--tox .tinymce__oxide--tox-listbox__select-chevron{align-items:center;display:flex;justify-content:center;width:16px}

.tinymce__oxide--tox .tinymce__oxide--tox-listbox__select-chevron svg{fill:#222f3e}

.tinymce__oxide--tox .tinymce__oxide--tox-listboxfield .tinymce__oxide--tox-listbox--select{align-items:center;display:flex}

.tinymce__oxide--tox:not([dir=rtl]) .tinymce__oxide--tox-listboxfield svg{right:8px}

.tinymce__oxide--tox[dir=rtl] .tinymce__oxide--tox-listboxfield svg{left:8px}

.tinymce__oxide--tox .tinymce__oxide--tox-selectfield{cursor:pointer;position:relative}

.tinymce__oxide--tox .tinymce__oxide--tox-selectfield select{-webkit-appearance:none;appearance:none;background-color:#fff;border-color:#ccc;border-radius:3px;border-style:solid;border-width:1px;box-shadow:none;box-sizing:border-box;color:#222f3e;font-family:-apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,Oxygen-Sans,Ubuntu,Cantarell,"Helvetica Neue",sans-serif;font-size:16px;line-height:24px;margin:0;min-height:34px;outline:0;padding:5px 4.75px;resize:none;width:100%}

.tinymce__oxide--tox .tinymce__oxide--tox-selectfield select[disabled]{background-color:#f2f2f2;color:rgba(34,47,62,.85);cursor:not-allowed}

.tinymce__oxide--tox .tinymce__oxide--tox-selectfield select::-ms-expand{display:none}

.tinymce__oxide--tox .tinymce__oxide--tox-selectfield select:focus{background-color:#fff;border-color:#207ab7;box-shadow:none;outline:0}

.tinymce__oxide--tox .tinymce__oxide--tox-selectfield svg{pointer-events:none;position:absolute;top:50%;transform:translateY(-50%)}

.tinymce__oxide--tox:not([dir=rtl]) .tinymce__oxide--tox-selectfield select[size="0"],.tinymce__oxide--tox:not([dir=rtl]) .tinymce__oxide--tox-selectfield select[size="1"]{padding-right:24px}

.tinymce__oxide--tox:not([dir=rtl]) .tinymce__oxide--tox-selectfield svg{right:8px}

.tinymce__oxide--tox[dir=rtl] .tinymce__oxide--tox-selectfield select[size="0"],.tinymce__oxide--tox[dir=rtl] .tinymce__oxide--tox-selectfield select[size="1"]{padding-left:24px}

.tinymce__oxide--tox[dir=rtl] .tinymce__oxide--tox-selectfield svg{left:8px}

.tinymce__oxide--tox .tinymce__oxide--tox-textarea{-webkit-appearance:textarea;appearance:textarea;white-space:pre-wrap}

.tinymce__oxide--tox-fullscreen{border:0;height:100%;left:0;margin:0;overflow:hidden;overscroll-behavior:none;padding:0;position:fixed;top:0;touch-action:pinch-zoom;width:100%}

.tinymce__oxide--tox.tinymce__oxide--tox-tinymce.tinymce__oxide--tox-fullscreen .tinymce__oxide--tox-statusbar__resize-handle{display:none}

.tinymce__oxide--tox.tinymce__oxide--tox-tinymce.tinymce__oxide--tox-fullscreen{background-color:transparent;z-index:1200}

.tinymce__oxide--tox-shadowhost.tinymce__oxide--tox-fullscreen{z-index:1200}

.tinymce__oxide--tox-fullscreen .tinymce__oxide--tox.tinymce__oxide--tox-tinymce-aux,.tinymce__oxide--tox-fullscreen~.tinymce__oxide--tox.tinymce__oxide--tox-tinymce-aux{z-index:1201}

.tinymce__oxide--tox .tinymce__oxide--tox-help__more-link{list-style:none;margin-top:1em}

.tinymce__oxide--tox .tinymce__oxide--tox-image-tools{width:100%}

.tinymce__oxide--tox .tinymce__oxide--tox-image-tools__toolbar{align-items:center;display:flex;justify-content:center}

.tinymce__oxide--tox .tinymce__oxide--tox-image-tools__image{background-color:#666;height:380px;overflow:auto;position:relative;width:100%}

.tinymce__oxide--tox .tinymce__oxide--tox-image-tools__image,.tinymce__oxide--tox .tinymce__oxide--tox-image-tools__image+.tinymce__oxide--tox-image-tools__toolbar{margin-top:8px}

.tinymce__oxide--tox .tinymce__oxide--tox-image-tools__image-bg{background:url(data:image/gif;base64,R0lGODdhDAAMAIABAMzMzP///ywAAAAADAAMAAACFoQfqYeabNyDMkBQb81Uat85nxguUAEAOw==)}

.tinymce__oxide--tox .tinymce__oxide--tox-image-tools__toolbar>.tinymce__oxide--tox-spacer{flex:1;-ms-flex-preferred-size:auto}

.tinymce__oxide--tox .tinymce__oxide--tox-croprect-block{background:#000;opacity:.5;position:absolute;zoom:1}

.tinymce__oxide--tox .tinymce__oxide--tox-croprect-handle{border:2px solid #fff;height:20px;left:0;position:absolute;top:0;width:20px}

.tinymce__oxide--tox .tinymce__oxide--tox-croprect-handle-move{border:0;cursor:move;position:absolute}

.tinymce__oxide--tox .tinymce__oxide--tox-croprect-handle-nw{border-width:2px 0 0 2px;cursor:nw-resize;left:100px;margin:-2px 0 0 -2px;top:100px}

.tinymce__oxide--tox .tinymce__oxide--tox-croprect-handle-ne{border-width:2px 2px 0 0;cursor:ne-resize;left:200px;margin:-2px 0 0 -20px;top:100px}

.tinymce__oxide--tox .tinymce__oxide--tox-croprect-handle-sw{border-width:0 0 2px 2px;cursor:sw-resize;left:100px;margin:-20px 2px 0 -2px;top:200px}

.tinymce__oxide--tox .tinymce__oxide--tox-croprect-handle-se{border-width:0 2px 2px 0;cursor:se-resize;left:200px;margin:-20px 0 0 -20px;top:200px}

.tinymce__oxide--tox:not([dir=rtl]) .tinymce__oxide--tox-image-tools__toolbar>.tinymce__oxide--tox-slider:not(:first-of-type){margin-left:8px}

.tinymce__oxide--tox:not([dir=rtl]) .tinymce__oxide--tox-image-tools__toolbar>.tinymce__oxide--tox-button+.tinymce__oxide--tox-slider{margin-left:32px}

.tinymce__oxide--tox:not([dir=rtl]) .tinymce__oxide--tox-image-tools__toolbar>.tinymce__oxide--tox-slider+.tinymce__oxide--tox-button{margin-left:32px}

.tinymce__oxide--tox[dir=rtl] .tinymce__oxide--tox-image-tools__toolbar>.tinymce__oxide--tox-slider:not(:first-of-type){margin-right:8px}

.tinymce__oxide--tox[dir=rtl] .tinymce__oxide--tox-image-tools__toolbar>.tinymce__oxide--tox-button+.tinymce__oxide--tox-slider{margin-right:32px}

.tinymce__oxide--tox[dir=rtl] .tinymce__oxide--tox-image-tools__toolbar>.tinymce__oxide--tox-slider+.tinymce__oxide--tox-button{margin-right:32px}

.tinymce__oxide--tox .tinymce__oxide--tox-insert-table-picker{display:flex;flex-wrap:wrap;width:170px}

.tinymce__oxide--tox .tinymce__oxide--tox-insert-table-picker>div{border-color:#ccc;border-style:solid;border-width:0 1px 1px 0;box-sizing:border-box;height:17px;width:17px}

.tinymce__oxide--tox .tinymce__oxide--tox-collection--list .tinymce__oxide--tox-collection__group .tinymce__oxide--tox-insert-table-picker{margin:-4px 0}

.tinymce__oxide--tox .tinymce__oxide--tox-insert-table-picker .tinymce__oxide--tox-insert-table-picker__selected{background-color:rgba(32,122,183,.5);border-color:rgba(32,122,183,.5)}

.tinymce__oxide--tox .tinymce__oxide--tox-insert-table-picker__label{color:rgba(34,47,62,.7);display:block;font-size:14px;padding:4px;text-align:center;width:100%}

[dir="ltr"] .tinymce__oxide--tox .tinymce__oxide--tox-insert-table-picker__label{text-align:center}

[dir="rtl"] .tinymce__oxide--tox .tinymce__oxide--tox-insert-table-picker__label{text-align:center}

.tinymce__oxide--tox:not([dir=rtl]) .tinymce__oxide--tox-insert-table-picker>div:nth-child(10n){border-right:0}

.tinymce__oxide--tox[dir=rtl] .tinymce__oxide--tox-insert-table-picker>div:nth-child(10n+1){border-right:0}

.tinymce__oxide--tox .tinymce__oxide--tox-menu{background-color:#fff;border:1px solid #ccc;border-radius:3px;box-shadow:0 4px 8px 0 rgba(34,47,62,.1);display:inline-block;overflow:hidden;vertical-align:top;z-index:1150}

.tinymce__oxide--tox .tinymce__oxide--tox-menu.tinymce__oxide--tox-collection.tinymce__oxide--tox-collection--list{padding:0}

.tinymce__oxide--tox .tinymce__oxide--tox-menu.tinymce__oxide--tox-collection.tinymce__oxide--tox-collection--toolbar{padding:4px}

.tinymce__oxide--tox .tinymce__oxide--tox-menu.tinymce__oxide--tox-collection.tinymce__oxide--tox-collection--grid{padding:4px}

.tinymce__oxide--tox .tinymce__oxide--tox-menu__label blockquote,.tinymce__oxide--tox .tinymce__oxide--tox-menu__label code,.tinymce__oxide--tox .tinymce__oxide--tox-menu__label h1,.tinymce__oxide--tox .tinymce__oxide--tox-menu__label h2,.tinymce__oxide--tox .tinymce__oxide--tox-menu__label h3,.tinymce__oxide--tox .tinymce__oxide--tox-menu__label h4,.tinymce__oxide--tox .tinymce__oxide--tox-menu__label h5,.tinymce__oxide--tox .tinymce__oxide--tox-menu__label h6,.tinymce__oxide--tox .tinymce__oxide--tox-menu__label p{margin:0}

.tinymce__oxide--tox .tinymce__oxide--tox-menubar{background:url("data:image/svg+xml;charset=utf8,%3Csvg height='39px' viewBox='0 0 40 39px' width='40' xmlns='http://www.w3.org/2000/svg'%3E%3Crect x='0' y='38px' width='100' height='1' fill='%23cccccc'/%3E%3C/svg%3E") left 0 top 0 #fff;background-color:#fff;display:flex;flex:0 0 auto;flex-shrink:0;flex-wrap:wrap;padding:0 4px 0 4px}

.tinymce__oxide--tox.tinymce__oxide--tox-tinymce:not(.tinymce__oxide--tox-tinymce-inline) .tinymce__oxide--tox-editor-header:not(:first-child) .tinymce__oxide--tox-menubar{border-top:1px solid #ccc}

.tinymce__oxide--tox .tinymce__oxide--tox-mbtn{align-items:center;background:0 0;border:0;border-radius:3px;box-shadow:none;color:#222f3e;display:flex;flex:0 0 auto;font-size:14px;font-style:normal;font-weight:400;height:34px;justify-content:center;margin:2px 0 3px 0;outline:0;overflow:hidden;padding:0 4px;text-transform:none;width:auto}

.tinymce__oxide--tox .tinymce__oxide--tox-mbtn[disabled]{background-color:transparent;border:0;box-shadow:none;color:rgba(34,47,62,.5);cursor:not-allowed}

.tinymce__oxide--tox .tinymce__oxide--tox-mbtn:focus:not(:disabled){background:#dee0e2;border:0;box-shadow:none;color:#222f3e}

.tinymce__oxide--tox .tinymce__oxide--tox-mbtn--active{background:#c8cbcf;border:0;box-shadow:none;color:#222f3e}

.tinymce__oxide--tox .tinymce__oxide--tox-mbtn:hover:not(:disabled):not(.tinymce__oxide--tox-mbtn--active){background:#dee0e2;border:0;box-shadow:none;color:#222f3e}

.tinymce__oxide--tox .tinymce__oxide--tox-mbtn__select-label{cursor:default;font-weight:400;margin:0 4px}

.tinymce__oxide--tox .tinymce__oxide--tox-mbtn[disabled] .tinymce__oxide--tox-mbtn__select-label{cursor:not-allowed}

.tinymce__oxide--tox .tinymce__oxide--tox-mbtn__select-chevron{align-items:center;display:flex;justify-content:center;width:16px;display:none}

.tinymce__oxide--tox .tinymce__oxide--tox-notification{border-radius:3px;border-style:solid;border-width:1px;box-shadow:none;box-sizing:border-box;display:grid;font-size:14px;font-weight:400;grid-template-columns:minmax(40px,1fr) auto minmax(40px,1fr);margin-top:4px;opacity:0;padding:4px;transition:transform .1s ease-in,opacity 150ms ease-in}

.tinymce__oxide--tox .tinymce__oxide--tox-notification p{font-size:14px;font-weight:400}

.tinymce__oxide--tox .tinymce__oxide--tox-notification a{text-decoration:underline}

.tinymce__oxide--tox .tinymce__oxide--tox-notification--in{opacity:1}

.tinymce__oxide--tox .tinymce__oxide--tox-notification--success{background-color:#e4eeda;border-color:#d7e6c8;color:#222f3e}

.tinymce__oxide--tox .tinymce__oxide--tox-notification--success p{color:#222f3e}

.tinymce__oxide--tox .tinymce__oxide--tox-notification--success a{color:#547831}

.tinymce__oxide--tox .tinymce__oxide--tox-notification--success svg{fill:#222f3e}

.tinymce__oxide--tox .tinymce__oxide--tox-notification--error{background-color:#f8dede;border-color:#f2bfbf;color:#222f3e}

.tinymce__oxide--tox .tinymce__oxide--tox-notification--error p{color:#222f3e}

.tinymce__oxide--tox .tinymce__oxide--tox-notification--error a{color:#c00}

.tinymce__oxide--tox .tinymce__oxide--tox-notification--error svg{fill:#222f3e}

.tinymce__oxide--tox .tinymce__oxide--tox-notification--warn,.tinymce__oxide--tox .tinymce__oxide--tox-notification--warning{background-color:#fffaea;border-color:#ffe89d;color:#222f3e}

.tinymce__oxide--tox .tinymce__oxide--tox-notification--warn p,.tinymce__oxide--tox .tinymce__oxide--tox-notification--warning p{color:#222f3e}

.tinymce__oxide--tox .tinymce__oxide--tox-notification--warn a,.tinymce__oxide--tox .tinymce__oxide--tox-notification--warning a{color:#222f3e}

.tinymce__oxide--tox .tinymce__oxide--tox-notification--warn svg,.tinymce__oxide--tox .tinymce__oxide--tox-notification--warning svg{fill:#222f3e}

.tinymce__oxide--tox .tinymce__oxide--tox-notification--info{background-color:#d9edf7;border-color:#779ecb;color:#222f3e}

.tinymce__oxide--tox .tinymce__oxide--tox-notification--info p{color:#222f3e}

.tinymce__oxide--tox .tinymce__oxide--tox-notification--info a{color:#222f3e}

.tinymce__oxide--tox .tinymce__oxide--tox-notification--info svg{fill:#222f3e}

.tinymce__oxide--tox .tinymce__oxide--tox-notification__body{align-self:center;color:#222f3e;font-size:14px;-ms-grid-column-span:1;grid-column-end:3;grid-column-start:2;-ms-grid-row-span:1;grid-row-end:2;grid-row-start:1;text-align:center;white-space:normal;word-break:break-all;word-break:break-word}

[dir="ltr"] .tinymce__oxide--tox .tinymce__oxide--tox-notification__body{text-align:center}

[dir="rtl"] .tinymce__oxide--tox .tinymce__oxide--tox-notification__body{text-align:center}

.tinymce__oxide--tox .tinymce__oxide--tox-notification__body>*{margin:0}

.tinymce__oxide--tox .tinymce__oxide--tox-notification__body>*+*{margin-top:1rem}

.tinymce__oxide--tox .tinymce__oxide--tox-notification__icon{align-self:center;-ms-grid-column-span:1;grid-column-end:2;grid-column-start:1;-ms-grid-row-span:1;grid-row-end:2;grid-row-start:1;justify-self:end}

.tinymce__oxide--tox .tinymce__oxide--tox-notification__icon svg{display:block}

.tinymce__oxide--tox .tinymce__oxide--tox-notification__dismiss{align-self:start;-ms-grid-column-span:1;grid-column-end:4;grid-column-start:3;-ms-grid-row-span:1;grid-row-end:2;grid-row-start:1;justify-self:end}

.tinymce__oxide--tox .tinymce__oxide--tox-notification .tinymce__oxide--tox-progress-bar{-ms-grid-column-span:3;grid-column-end:4;grid-column-start:1;-ms-grid-row-span:1;grid-row-end:3;grid-row-start:2;justify-self:center}

.tinymce__oxide--tox .tinymce__oxide--tox-pop{display:inline-block;position:relative}

.tinymce__oxide--tox .tinymce__oxide--tox-pop--resizing{transition:width .1s ease}

.tinymce__oxide--tox .tinymce__oxide--tox-pop--resizing .tinymce__oxide--tox-toolbar{flex-wrap:nowrap}

.tinymce__oxide--tox .tinymce__oxide--tox-pop__dialog{background-color:#fff;border:1px solid #ccc;border-radius:3px;box-shadow:0 1px 3px rgba(0,0,0,.15);min-width:0;overflow:hidden}

.tinymce__oxide--tox .tinymce__oxide--tox-pop__dialog>:not(.tinymce__oxide--tox-toolbar){margin:4px 4px 4px 8px}

.tinymce__oxide--tox .tinymce__oxide--tox-pop__dialog .tinymce__oxide--tox-toolbar{background-color:transparent;margin-bottom:-1px}

.tinymce__oxide--tox .tinymce__oxide--tox-pop::after,.tinymce__oxide--tox .tinymce__oxide--tox-pop::before{border-style:solid;content:'';display:block;height:0;position:absolute;width:0}

.tinymce__oxide--tox .tinymce__oxide--tox-pop.tinymce__oxide--tox-pop--bottom::after,.tinymce__oxide--tox .tinymce__oxide--tox-pop.tinymce__oxide--tox-pop--bottom::before{left:50%;top:100%}

.tinymce__oxide--tox .tinymce__oxide--tox-pop.tinymce__oxide--tox-pop--bottom::after{border-color:#fff transparent transparent transparent;border-width:8px;margin-left:-8px;margin-top:-1px}

.tinymce__oxide--tox .tinymce__oxide--tox-pop.tinymce__oxide--tox-pop--bottom::before{border-color:#ccc transparent transparent transparent;border-width:9px;margin-left:-9px}

.tinymce__oxide--tox .tinymce__oxide--tox-pop.tinymce__oxide--tox-pop--top::after,.tinymce__oxide--tox .tinymce__oxide--tox-pop.tinymce__oxide--tox-pop--top::before{left:50%;top:0;transform:translateY(-100%)}

.tinymce__oxide--tox .tinymce__oxide--tox-pop.tinymce__oxide--tox-pop--top::after{border-color:transparent transparent #fff transparent;border-width:8px;margin-left:-8px;margin-top:1px}

.tinymce__oxide--tox .tinymce__oxide--tox-pop.tinymce__oxide--tox-pop--top::before{border-color:transparent transparent #ccc transparent;border-width:9px;margin-left:-9px}

.tinymce__oxide--tox .tinymce__oxide--tox-pop.tinymce__oxide--tox-pop--left::after,.tinymce__oxide--tox .tinymce__oxide--tox-pop.tinymce__oxide--tox-pop--left::before{left:0;top:calc(50% - 1px);transform:translateY(-50%)}

.tinymce__oxide--tox .tinymce__oxide--tox-pop.tinymce__oxide--tox-pop--left::after{border-color:transparent #fff transparent transparent;border-width:8px;margin-left:-15px}

.tinymce__oxide--tox .tinymce__oxide--tox-pop.tinymce__oxide--tox-pop--left::before{border-color:transparent #ccc transparent transparent;border-width:10px;margin-left:-19px}

.tinymce__oxide--tox .tinymce__oxide--tox-pop.tinymce__oxide--tox-pop--right::after,.tinymce__oxide--tox .tinymce__oxide--tox-pop.tinymce__oxide--tox-pop--right::before{left:100%;top:calc(50% + 1px);transform:translateY(-50%)}

.tinymce__oxide--tox .tinymce__oxide--tox-pop.tinymce__oxide--tox-pop--right::after{border-color:transparent transparent transparent #fff;border-width:8px;margin-left:-1px}

.tinymce__oxide--tox .tinymce__oxide--tox-pop.tinymce__oxide--tox-pop--right::before{border-color:transparent transparent transparent #ccc;border-width:10px;margin-left:-1px}

.tinymce__oxide--tox .tinymce__oxide--tox-pop.tinymce__oxide--tox-pop--align-left::after,.tinymce__oxide--tox .tinymce__oxide--tox-pop.tinymce__oxide--tox-pop--align-left::before{left:20px}

.tinymce__oxide--tox .tinymce__oxide--tox-pop.tinymce__oxide--tox-pop--align-right::after,.tinymce__oxide--tox .tinymce__oxide--tox-pop.tinymce__oxide--tox-pop--align-right::before{left:calc(100% - 20px)}

.tinymce__oxide--tox .tinymce__oxide--tox-sidebar-wrap{display:flex;flex-direction:row;flex-grow:1;-ms-flex-preferred-size:0;min-height:0}

.tinymce__oxide--tox .tinymce__oxide--tox-sidebar{background-color:#fff;display:flex;flex-direction:row;justify-content:flex-end}

.tinymce__oxide--tox .tinymce__oxide--tox-sidebar__slider{display:flex;overflow:hidden}

.tinymce__oxide--tox .tinymce__oxide--tox-sidebar__pane-container{display:flex}

.tinymce__oxide--tox .tinymce__oxide--tox-sidebar__pane{display:flex}

.tinymce__oxide--tox .tinymce__oxide--tox-sidebar--sliding-closed{opacity:0}

.tinymce__oxide--tox .tinymce__oxide--tox-sidebar--sliding-open{opacity:1}

.tinymce__oxide--tox .tinymce__oxide--tox-sidebar--sliding-growing,.tinymce__oxide--tox .tinymce__oxide--tox-sidebar--sliding-shrinking{transition:width .5s ease,opacity .5s ease}

.tinymce__oxide--tox .tinymce__oxide--tox-selector{background-color:#4099ff;border-color:#4099ff;border-style:solid;border-width:1px;box-sizing:border-box;display:inline-block;height:10px;position:absolute;width:10px}

.tinymce__oxide--tox.tinymce__oxide--tox-platform-touch .tinymce__oxide--tox-selector{height:12px;width:12px}

.tinymce__oxide--tox .tinymce__oxide--tox-slider{align-items:center;display:flex;flex:1;-ms-flex-preferred-size:auto;height:24px;justify-content:center;position:relative}

.tinymce__oxide--tox .tinymce__oxide--tox-slider__rail{background-color:transparent;border:1px solid #ccc;border-radius:3px;height:10px;min-width:120px;width:100%}

.tinymce__oxide--tox .tinymce__oxide--tox-slider__handle{background-color:#207ab7;border:2px solid #185d8c;border-radius:3px;box-shadow:none;height:24px;left:50%;position:absolute;top:50%;transform:translateX(-50%) translateY(-50%);width:14px}

.tinymce__oxide--tox .tinymce__oxide--tox-source-code{overflow:auto}

.tinymce__oxide--tox .tinymce__oxide--tox-spinner{display:flex}

.tinymce__oxide--tox .tinymce__oxide--tox-spinner>div{animation:tinymce__oxide--tam-bouncing-dots 1.5s ease-in-out 0s infinite both;background-color:rgba(34,47,62,.7);border-radius:100%;height:8px;width:8px}

.tinymce__oxide--tox .tinymce__oxide--tox-spinner>div:nth-child(1){animation-delay:-.32s}

.tinymce__oxide--tox .tinymce__oxide--tox-spinner>div:nth-child(2){animation-delay:-.16s}

@keyframes tinymce__oxide--tam-bouncing-dots{0%,100%,80%{transform:scale(0)}40%{transform:scale(1)}}

.tinymce__oxide--tox:not([dir=rtl]) .tinymce__oxide--tox-spinner>div:not(:first-child){margin-left:4px}

.tinymce__oxide--tox[dir=rtl] .tinymce__oxide--tox-spinner>div:not(:first-child){margin-right:4px}

.tinymce__oxide--tox .tinymce__oxide--tox-statusbar{align-items:center;background-color:#fff;border-top:1px solid #ccc;color:rgba(34,47,62,.7);display:flex;flex:0 0 auto;font-size:12px;font-weight:400;height:18px;overflow:hidden;padding:0 8px;position:relative;text-transform:uppercase}

.tinymce__oxide--tox .tinymce__oxide--tox-statusbar__text-container{display:flex;flex:1 1 auto;justify-content:flex-end;overflow:hidden}

.tinymce__oxide--tox .tinymce__oxide--tox-statusbar__path{display:flex;flex:1 1 auto;margin-right:auto;overflow:hidden;text-overflow:ellipsis;white-space:nowrap}

.tinymce__oxide--tox .tinymce__oxide--tox-statusbar__path>*{display:inline;white-space:nowrap}

.tinymce__oxide--tox .tinymce__oxide--tox-statusbar__wordcount{flex:0 0 auto;margin-left:1ch}

.tinymce__oxide--tox .tinymce__oxide--tox-statusbar a,.tinymce__oxide--tox .tinymce__oxide--tox-statusbar__path-item,.tinymce__oxide--tox .tinymce__oxide--tox-statusbar__wordcount{color:rgba(34,47,62,.7);text-decoration:none}

.tinymce__oxide--tox .tinymce__oxide--tox-statusbar a:focus:not(:disabled):not([aria-disabled=true]),.tinymce__oxide--tox .tinymce__oxide--tox-statusbar a:hover:not(:disabled):not([aria-disabled=true]),.tinymce__oxide--tox .tinymce__oxide--tox-statusbar__path-item:focus:not(:disabled):not([aria-disabled=true]),.tinymce__oxide--tox .tinymce__oxide--tox-statusbar__path-item:hover:not(:disabled):not([aria-disabled=true]),.tinymce__oxide--tox .tinymce__oxide--tox-statusbar__wordcount:focus:not(:disabled):not([aria-disabled=true]),.tinymce__oxide--tox .tinymce__oxide--tox-statusbar__wordcount:hover:not(:disabled):not([aria-disabled=true]){cursor:pointer;text-decoration:underline}

.tinymce__oxide--tox .tinymce__oxide--tox-statusbar__resize-handle{align-items:flex-end;align-self:stretch;cursor:nwse-resize;display:flex;flex:0 0 auto;justify-content:flex-end;margin-left:auto;margin-right:-8px;padding-left:1ch}

.tinymce__oxide--tox .tinymce__oxide--tox-statusbar__resize-handle svg{display:block;fill:rgba(34,47,62,.7)}

.tinymce__oxide--tox .tinymce__oxide--tox-statusbar__resize-handle:focus svg{background-color:#dee0e2;border-radius:1px;box-shadow:0 0 0 2px #dee0e2}

.tinymce__oxide--tox:not([dir=rtl]) .tinymce__oxide--tox-statusbar__path>*{margin-right:4px}

.tinymce__oxide--tox:not([dir=rtl]) .tinymce__oxide--tox-statusbar__branding{margin-left:1ch}

.tinymce__oxide--tox[dir=rtl] .tinymce__oxide--tox-statusbar{flex-direction:row-reverse}

.tinymce__oxide--tox[dir=rtl] .tinymce__oxide--tox-statusbar__path>*{margin-left:4px}

.tinymce__oxide--tox .tinymce__oxide--tox-throbber{z-index:1299}

.tinymce__oxide--tox .tinymce__oxide--tox-throbber__busy-spinner{align-items:center;background-color:rgba(255,255,255,.6);bottom:0;display:flex;justify-content:center;left:0;position:absolute;right:0;top:0}

.tinymce__oxide--tox .tinymce__oxide--tox-tbtn{align-items:center;background:0 0;border:0;border-radius:3px;box-shadow:none;color:#222f3e;display:flex;flex:0 0 auto;font-size:14px;font-style:normal;font-weight:400;height:34px;justify-content:center;margin:2px 0 3px 0;outline:0;overflow:hidden;padding:0;text-transform:none;width:34px}

.tinymce__oxide--tox .tinymce__oxide--tox-tbtn svg{display:block;fill:#222f3e}

.tinymce__oxide--tox .tinymce__oxide--tox-tbtn.tinymce__oxide--tox-tbtn-more{padding-left:5px;padding-right:5px;width:inherit}

.tinymce__oxide--tox .tinymce__oxide--tox-tbtn:focus{background:#dee0e2;border:0;box-shadow:none}

.tinymce__oxide--tox .tinymce__oxide--tox-tbtn:hover{background:#dee0e2;border:0;box-shadow:none;color:#222f3e}

.tinymce__oxide--tox .tinymce__oxide--tox-tbtn:hover svg{fill:#222f3e}

.tinymce__oxide--tox .tinymce__oxide--tox-tbtn:active{background:#c8cbcf;border:0;box-shadow:none;color:#222f3e}

.tinymce__oxide--tox .tinymce__oxide--tox-tbtn:active svg{fill:#222f3e}

.tinymce__oxide--tox .tinymce__oxide--tox-tbtn--disabled,.tinymce__oxide--tox .tinymce__oxide--tox-tbtn--disabled:hover,.tinymce__oxide--tox .tinymce__oxide--tox-tbtn:disabled,.tinymce__oxide--tox .tinymce__oxide--tox-tbtn:disabled:hover{background:0 0;border:0;box-shadow:none;color:rgba(34,47,62,.5);cursor:not-allowed}

.tinymce__oxide--tox .tinymce__oxide--tox-tbtn--disabled svg,.tinymce__oxide--tox .tinymce__oxide--tox-tbtn--disabled:hover svg,.tinymce__oxide--tox .tinymce__oxide--tox-tbtn:disabled svg,.tinymce__oxide--tox .tinymce__oxide--tox-tbtn:disabled:hover svg{fill:rgba(34,47,62,.5)}

.tinymce__oxide--tox .tinymce__oxide--tox-tbtn--enabled,.tinymce__oxide--tox .tinymce__oxide--tox-tbtn--enabled:hover{background:#c8cbcf;border:0;box-shadow:none;color:#222f3e}

.tinymce__oxide--tox .tinymce__oxide--tox-tbtn--enabled:hover>*,.tinymce__oxide--tox .tinymce__oxide--tox-tbtn--enabled>*{transform:none}

.tinymce__oxide--tox .tinymce__oxide--tox-tbtn--enabled svg,.tinymce__oxide--tox .tinymce__oxide--tox-tbtn--enabled:hover svg{fill:#222f3e}

.tinymce__oxide--tox .tinymce__oxide--tox-tbtn:focus:not(.tinymce__oxide--tox-tbtn--disabled){color:#222f3e}

.tinymce__oxide--tox .tinymce__oxide--tox-tbtn:focus:not(.tinymce__oxide--tox-tbtn--disabled) svg{fill:#222f3e}

.tinymce__oxide--tox .tinymce__oxide--tox-tbtn:active>*{transform:none}

.tinymce__oxide--tox .tinymce__oxide--tox-tbtn--md{height:51px;width:51px}

.tinymce__oxide--tox .tinymce__oxide--tox-tbtn--lg{flex-direction:column;height:68px;width:68px}

.tinymce__oxide--tox .tinymce__oxide--tox-tbtn--return{align-self:stretch;height:unset;width:16px}

.tinymce__oxide--tox .tinymce__oxide--tox-tbtn--labeled{padding:0 4px;width:unset}

.tinymce__oxide--tox .tinymce__oxide--tox-tbtn__vlabel{display:block;font-size:10px;font-weight:400;letter-spacing:-.025em;margin-bottom:4px;white-space:nowrap}

.tinymce__oxide--tox .tinymce__oxide--tox-tbtn--select{margin:2px 0 3px 0;padding:0 4px;width:auto}

.tinymce__oxide--tox .tinymce__oxide--tox-tbtn__select-label{cursor:default;font-weight:400;margin:0 4px}

.tinymce__oxide--tox .tinymce__oxide--tox-tbtn__select-chevron{align-items:center;display:flex;justify-content:center;width:16px}

.tinymce__oxide--tox .tinymce__oxide--tox-tbtn__select-chevron svg{fill:rgba(34,47,62,.5)}

.tinymce__oxide--tox .tinymce__oxide--tox-tbtn--bespoke .tinymce__oxide--tox-tbtn__select-label{overflow:hidden;text-overflow:ellipsis;white-space:nowrap;width:7em}

.tinymce__oxide--tox .tinymce__oxide--tox-split-button{border:0;border-radius:3px;box-sizing:border-box;display:flex;margin:2px 0 3px 0;overflow:hidden}

.tinymce__oxide--tox .tinymce__oxide--tox-split-button:hover{box-shadow:0 0 0 1px #dee0e2 inset}

.tinymce__oxide--tox .tinymce__oxide--tox-split-button:focus{background:#dee0e2;box-shadow:none;color:#222f3e}

.tinymce__oxide--tox .tinymce__oxide--tox-split-button>*{border-radius:0}

.tinymce__oxide--tox .tinymce__oxide--tox-split-button__chevron{width:16px}

.tinymce__oxide--tox .tinymce__oxide--tox-split-button__chevron svg{fill:rgba(34,47,62,.5)}

.tinymce__oxide--tox .tinymce__oxide--tox-split-button .tinymce__oxide--tox-tbtn{margin:0}

.tinymce__oxide--tox.tinymce__oxide--tox-platform-touch .tinymce__oxide--tox-split-button .tinymce__oxide--tox-tbtn:first-child{width:30px}

.tinymce__oxide--tox.tinymce__oxide--tox-platform-touch .tinymce__oxide--tox-split-button__chevron{width:20px}

.tinymce__oxide--tox .tinymce__oxide--tox-split-button.tinymce__oxide--tox-tbtn--disabled .tinymce__oxide--tox-tbtn:focus,.tinymce__oxide--tox .tinymce__oxide--tox-split-button.tinymce__oxide--tox-tbtn--disabled .tinymce__oxide--tox-tbtn:hover,.tinymce__oxide--tox .tinymce__oxide--tox-split-button.tinymce__oxide--tox-tbtn--disabled:focus,.tinymce__oxide--tox .tinymce__oxide--tox-split-button.tinymce__oxide--tox-tbtn--disabled:hover{background:0 0;box-shadow:none;color:rgba(34,47,62,.5)}

.tinymce__oxide--tox .tinymce__oxide--tox-toolbar-overlord{background-color:#fff}

.tinymce__oxide--tox .tinymce__oxide--tox-toolbar,.tinymce__oxide--tox .tinymce__oxide--tox-toolbar__overflow,.tinymce__oxide--tox .tinymce__oxide--tox-toolbar__primary{background:url("data:image/svg+xml;charset=utf8,%3Csvg height='39px' viewBox='0 0 40 39px' width='40' xmlns='http://www.w3.org/2000/svg'%3E%3Crect x='0' y='38px' width='100' height='1' fill='%23cccccc'/%3E%3C/svg%3E") left 0 top 0 #fff;background-color:#fff;display:flex;flex:0 0 auto;flex-shrink:0;flex-wrap:wrap;padding:0 0}

.tinymce__oxide--tox .tinymce__oxide--tox-toolbar__overflow.tinymce__oxide--tox-toolbar__overflow--closed{height:0;opacity:0;padding-bottom:0;padding-top:0;visibility:hidden}

.tinymce__oxide--tox .tinymce__oxide--tox-toolbar__overflow--growing{transition:height .3s ease,opacity .2s linear .1s}

.tinymce__oxide--tox .tinymce__oxide--tox-toolbar__overflow--shrinking{transition:opacity .3s ease,height .2s linear .1s,visibility 0s linear .3s}

.tinymce__oxide--tox .tinymce__oxide--tox-menubar+.tinymce__oxide--tox-toolbar,.tinymce__oxide--tox .tinymce__oxide--tox-menubar+.tinymce__oxide--tox-toolbar-overlord .tinymce__oxide--tox-toolbar__primary{border-top:1px solid #ccc;margin-top:-1px}

.tinymce__oxide--tox .tinymce__oxide--tox-toolbar--scrolling{flex-wrap:nowrap;overflow-x:auto}

.tinymce__oxide--tox .tinymce__oxide--tox-pop .tinymce__oxide--tox-toolbar{border-width:0}

.tinymce__oxide--tox .tinymce__oxide--tox-toolbar--no-divider{background-image:none}

.tinymce__oxide--tox-tinymce:not(.tinymce__oxide--tox-tinymce-inline) .tinymce__oxide--tox-editor-header:not(:first-child) .tinymce__oxide--tox-toolbar-overlord:first-child .tinymce__oxide--tox-toolbar__primary,.tinymce__oxide--tox-tinymce:not(.tinymce__oxide--tox-tinymce-inline) .tinymce__oxide--tox-editor-header:not(:first-child) .tinymce__oxide--tox-toolbar:first-child{border-top:1px solid #ccc}

.tinymce__oxide--tox.tinymce__oxide--tox-tinymce-aux .tinymce__oxide--tox-toolbar__overflow{background-color:#fff;border:1px solid #ccc;border-radius:3px;box-shadow:0 1px 3px rgba(0,0,0,.15)}

.tinymce__oxide--tox[dir=rtl] .tinymce__oxide--tox-tbtn__icon-rtl svg{transform:rotateY(180deg)}

.tinymce__oxide--tox .tinymce__oxide--tox-toolbar__group{align-items:center;display:flex;flex-wrap:wrap;margin:0 0;padding:0 4px 0 4px}

.tinymce__oxide--tox .tinymce__oxide--tox-toolbar__group--pull-right{margin-left:auto}

.tinymce__oxide--tox .tinymce__oxide--tox-toolbar--scrolling .tinymce__oxide--tox-toolbar__group{flex-shrink:0;flex-wrap:nowrap}

.tinymce__oxide--tox:not([dir=rtl]) .tinymce__oxide--tox-toolbar__group:not(:last-of-type){border-right:1px solid #ccc}

.tinymce__oxide--tox[dir=rtl] .tinymce__oxide--tox-toolbar__group:not(:last-of-type){border-left:1px solid #ccc}

.tinymce__oxide--tox .tinymce__oxide--tox-tooltip{display:inline-block;padding:8px;position:relative}

.tinymce__oxide--tox .tinymce__oxide--tox-tooltip__body{background-color:#222f3e;border-radius:3px;box-shadow:0 2px 4px rgba(34,47,62,.3);color:rgba(255,255,255,.75);font-size:14px;font-style:normal;font-weight:400;padding:4px 8px;text-transform:none}

.tinymce__oxide--tox .tinymce__oxide--tox-tooltip__arrow{position:absolute}

.tinymce__oxide--tox .tinymce__oxide--tox-tooltip--down .tinymce__oxide--tox-tooltip__arrow{border-left:8px solid transparent;border-right:8px solid transparent;border-top:8px solid #222f3e;bottom:0;left:50%;position:absolute;transform:translateX(-50%)}

.tinymce__oxide--tox .tinymce__oxide--tox-tooltip--up .tinymce__oxide--tox-tooltip__arrow{border-bottom:8px solid #222f3e;border-left:8px solid transparent;border-right:8px solid transparent;left:50%;position:absolute;top:0;transform:translateX(-50%)}

.tinymce__oxide--tox .tinymce__oxide--tox-tooltip--right .tinymce__oxide--tox-tooltip__arrow{border-bottom:8px solid transparent;border-left:8px solid #222f3e;border-top:8px solid transparent;position:absolute;right:0;top:50%;transform:translateY(-50%)}

.tinymce__oxide--tox .tinymce__oxide--tox-tooltip--left .tinymce__oxide--tox-tooltip__arrow{border-bottom:8px solid transparent;border-right:8px solid #222f3e;border-top:8px solid transparent;left:0;position:absolute;top:50%;transform:translateY(-50%)}

.tinymce__oxide--tox .tinymce__oxide--tox-well{border:1px solid #ccc;border-radius:3px;padding:8px;width:100%}

.tinymce__oxide--tox .tinymce__oxide--tox-well>:first-child{margin-top:0}

.tinymce__oxide--tox .tinymce__oxide--tox-well>:last-child{margin-bottom:0}

.tinymce__oxide--tox .tinymce__oxide--tox-well>:only-child{margin:0}

.tinymce__oxide--tox .tinymce__oxide--tox-custom-editor{border:1px solid #ccc;border-radius:3px;display:flex;flex:1;position:relative}

.tinymce__oxide--tox .tinymce__oxide--tox-dialog-loading::before{background-color:rgba(0,0,0,.5);content:"";height:100%;position:absolute;width:100%;z-index:1000}

.tinymce__oxide--tox .tinymce__oxide--tox-tab{cursor:pointer}

.tinymce__oxide--tox .tinymce__oxide--tox-dialog__content-js{display:flex;flex:1;-ms-flex-preferred-size:auto}

.tinymce__oxide--tox .tinymce__oxide--tox-dialog__body-content .tinymce__oxide--tox-collection{display:flex;flex:1;-ms-flex-preferred-size:auto}

.tinymce__oxide--tox .tinymce__oxide--tox-image-tools-edit-panel{height:60px}

.tinymce__oxide--tox .tinymce__oxide--tox-image-tools__sidebar{height:60px}
`;
  },
  'tox': 'tinymce__oxide--tox',
  'tox-tinymce': 'tinymce__oxide--tox-tinymce',
  'tox-tinymce-inline': 'tinymce__oxide--tox-tinymce-inline',
  'tox-editor-header': 'tinymce__oxide--tox-editor-header',
  'tox-tinymce-aux': 'tinymce__oxide--tox-tinymce-aux',
  'accessibility-issue__header': 'tinymce__oxide--accessibility-issue__header',
  'accessibility-issue__description': 'tinymce__oxide--accessibility-issue__description',
  'accessibility-issue__repair': 'tinymce__oxide--accessibility-issue__repair',
  'tox-dialog__body-content': 'tinymce__oxide--tox-dialog__body-content',
  'accessibility-issue--info': 'tinymce__oxide--accessibility-issue--info',
  'tox-form__group': 'tinymce__oxide--tox-form__group',
  'tox-icon': 'tinymce__oxide--tox-icon',
  'accessibility-issue--warn': 'tinymce__oxide--accessibility-issue--warn',
  'accessibility-issue--error': 'tinymce__oxide--accessibility-issue--error',
  'accessibility-issue--success': 'tinymce__oxide--accessibility-issue--success',
  'tox-button': 'tinymce__oxide--tox-button',
  'tox-anchorbar': 'tinymce__oxide--tox-anchorbar',
  'tox-bar': 'tinymce__oxide--tox-bar',
  'tox-button--secondary': 'tinymce__oxide--tox-button--secondary',
  'tox-button--icon': 'tinymce__oxide--tox-button--icon',
  'tox-button-link': 'tinymce__oxide--tox-button-link',
  'tox-button-link--sm': 'tinymce__oxide--tox-button-link--sm',
  'tox-button--naked': 'tinymce__oxide--tox-button--naked',
  'tox-checkbox': 'tinymce__oxide--tox-checkbox',
  'tox-checkbox__input': 'tinymce__oxide--tox-checkbox__input',
  'tox-checkbox__icons': 'tinymce__oxide--tox-checkbox__icons',
  'tox-checkbox-icon__unchecked': 'tinymce__oxide--tox-checkbox-icon__unchecked',
  'tox-checkbox-icon__indeterminate': 'tinymce__oxide--tox-checkbox-icon__indeterminate',
  'tox-checkbox-icon__checked': 'tinymce__oxide--tox-checkbox-icon__checked',
  'tox-checkbox--disabled': 'tinymce__oxide--tox-checkbox--disabled',
  'tox-checkbox__label': 'tinymce__oxide--tox-checkbox__label',
  'tox-collection--toolbar': 'tinymce__oxide--tox-collection--toolbar',
  'tox-collection__group': 'tinymce__oxide--tox-collection__group',
  'tox-collection--grid': 'tinymce__oxide--tox-collection--grid',
  'tox-collection--list': 'tinymce__oxide--tox-collection--list',
  'tox-collection__group-heading': 'tinymce__oxide--tox-collection__group-heading',
  'tox-collection__item': 'tinymce__oxide--tox-collection__item',
  'tox-collection__item--enabled': 'tinymce__oxide--tox-collection__item--enabled',
  'tox-collection__item--active': 'tinymce__oxide--tox-collection__item--active',
  'tox-collection__item--state-disabled': 'tinymce__oxide--tox-collection__item--state-disabled',
  'tox-collection__item-checkmark': 'tinymce__oxide--tox-collection__item-checkmark',
  'tox-collection__item-icon': 'tinymce__oxide--tox-collection__item-icon',
  'tox-collection--toolbar-lg': 'tinymce__oxide--tox-collection--toolbar-lg',
  'tox-collection__item-label': 'tinymce__oxide--tox-collection__item-label',
  'tox-collection__item-accessory': 'tinymce__oxide--tox-collection__item-accessory',
  'tox-collection__item-caret': 'tinymce__oxide--tox-collection__item-caret',
  'tox-collection--horizontal': 'tinymce__oxide--tox-collection--horizontal',
  'tox-collection__item-container': 'tinymce__oxide--tox-collection__item-container',
  'tox-collection__item-container--row': 'tinymce__oxide--tox-collection__item-container--row',
  'tox-collection__item-container--align-left': 'tinymce__oxide--tox-collection__item-container--align-left',
  'tox-collection__item-container--align-right': 'tinymce__oxide--tox-collection__item-container--align-right',
  'tox-collection__item-container--valign-top': 'tinymce__oxide--tox-collection__item-container--valign-top',
  'tox-collection__item-container--valign-middle': 'tinymce__oxide--tox-collection__item-container--valign-middle',
  'tox-collection__item-container--valign-bottom': 'tinymce__oxide--tox-collection__item-container--valign-bottom',
  'tox-collection__item-container--column': 'tinymce__oxide--tox-collection__item-container--column',
  'tox-collection': 'tinymce__oxide--tox-collection',
  'tox-collection__item-icon-rtl': 'tinymce__oxide--tox-collection__item-icon-rtl',
  'tox-color-picker-container': 'tinymce__oxide--tox-color-picker-container',
  'tox-sv-palette': 'tinymce__oxide--tox-sv-palette',
  'tox-sv-palette-spectrum': 'tinymce__oxide--tox-sv-palette-spectrum',
  'tox-sv-palette-thumb': 'tinymce__oxide--tox-sv-palette-thumb',
  'tox-sv-palette-inner-thumb': 'tinymce__oxide--tox-sv-palette-inner-thumb',
  'tox-hue-slider': 'tinymce__oxide--tox-hue-slider',
  'tox-hue-slider-spectrum': 'tinymce__oxide--tox-hue-slider-spectrum',
  'tox-hue-slider-thumb': 'tinymce__oxide--tox-hue-slider-thumb',
  'tox-rgb-form': 'tinymce__oxide--tox-rgb-form',
  'tox-invalid': 'tinymce__oxide--tox-invalid',
  'tox-rgba-preview': 'tinymce__oxide--tox-rgba-preview',
  'tox-toolbar': 'tinymce__oxide--tox-toolbar',
  'tox-swatches': 'tinymce__oxide--tox-swatches',
  'tox-toolbar__overflow': 'tinymce__oxide--tox-toolbar__overflow',
  'tox-toolbar__primary': 'tinymce__oxide--tox-toolbar__primary',
  'tox-swatches-menu': 'tinymce__oxide--tox-swatches-menu',
  'tox-swatches__row': 'tinymce__oxide--tox-swatches__row',
  'tox-swatch': 'tinymce__oxide--tox-swatch',
  'tox-swatch--remove': 'tinymce__oxide--tox-swatch--remove',
  'tox-swatches__picker-btn': 'tinymce__oxide--tox-swatches__picker-btn',
  'tox-comment-thread': 'tinymce__oxide--tox-comment-thread',
  'tox-comment': 'tinymce__oxide--tox-comment',
  'tox-comment__header': 'tinymce__oxide--tox-comment__header',
  'tox-comment__date': 'tinymce__oxide--tox-comment__date',
  'tox-comment__body': 'tinymce__oxide--tox-comment__body',
  'tox-comment__expander': 'tinymce__oxide--tox-comment__expander',
  'tox-comment__buttonspacing': 'tinymce__oxide--tox-comment__buttonspacing',
  'tox-comment-thread__overlay': 'tinymce__oxide--tox-comment-thread__overlay',
  'tox-comment__reply': 'tinymce__oxide--tox-comment__reply',
  'tox-comment__edit': 'tinymce__oxide--tox-comment__edit',
  'tox-comment__gradient': 'tinymce__oxide--tox-comment__gradient',
  'tox-comment__overlay': 'tinymce__oxide--tox-comment__overlay',
  'tox-comment__loading-text': 'tinymce__oxide--tox-comment__loading-text',
  'tox-comment__overlaytext': 'tinymce__oxide--tox-comment__overlaytext',
  'tox-comment__busy-spinner': 'tinymce__oxide--tox-comment__busy-spinner',
  'tox-comment__scroll': 'tinymce__oxide--tox-comment__scroll',
  'tox-conversations': 'tinymce__oxide--tox-conversations',
  'tox-user': 'tinymce__oxide--tox-user',
  'tox-user__avatar': 'tinymce__oxide--tox-user__avatar',
  'tox-user__name': 'tinymce__oxide--tox-user__name',
  'tox-dialog-wrap': 'tinymce__oxide--tox-dialog-wrap',
  'tox-dialog-wrap__backdrop': 'tinymce__oxide--tox-dialog-wrap__backdrop',
  'tox-dialog-wrap__backdrop--opaque': 'tinymce__oxide--tox-dialog-wrap__backdrop--opaque',
  'tox-dialog': 'tinymce__oxide--tox-dialog',
  'tox-force-desktop': 'tinymce__oxide--tox-force-desktop',
  'tox-dialog-inline': 'tinymce__oxide--tox-dialog-inline',
  'tox-dialog__header': 'tinymce__oxide--tox-dialog__header',
  'tox-dialog__draghandle': 'tinymce__oxide--tox-dialog__draghandle',
  'tox-dialog__dismiss': 'tinymce__oxide--tox-dialog__dismiss',
  'tox-dialog__title': 'tinymce__oxide--tox-dialog__title',
  'tox-dialog__body': 'tinymce__oxide--tox-dialog__body',
  'tox-dialog__body-nav': 'tinymce__oxide--tox-dialog__body-nav',
  'tox-dialog__body-nav-item': 'tinymce__oxide--tox-dialog__body-nav-item',
  'tox-dialog__body-nav-item--active': 'tinymce__oxide--tox-dialog__body-nav-item--active',
  'tox-dialog--width-lg': 'tinymce__oxide--tox-dialog--width-lg',
  'tox-dialog--width-md': 'tinymce__oxide--tox-dialog--width-md',
  'tox-dialog__body-content--centered': 'tinymce__oxide--tox-dialog__body-content--centered',
  'tox-dialog__footer': 'tinymce__oxide--tox-dialog__footer',
  'tox-dialog__footer-end': 'tinymce__oxide--tox-dialog__footer-end',
  'tox-dialog__footer-start': 'tinymce__oxide--tox-dialog__footer-start',
  'tox-dialog__busy-spinner': 'tinymce__oxide--tox-dialog__busy-spinner',
  'tox-dialog__table': 'tinymce__oxide--tox-dialog__table',
  'tox-dialog__popups': 'tinymce__oxide--tox-dialog__popups',
  'tox-dialog__body-iframe': 'tinymce__oxide--tox-dialog__body-iframe',
  'tox-navobj': 'tinymce__oxide--tox-navobj',
  'tox-dialog-dock-fadeout': 'tinymce__oxide--tox-dialog-dock-fadeout',
  'tox-dialog-dock-fadein': 'tinymce__oxide--tox-dialog-dock-fadein',
  'tox-dialog-dock-transition': 'tinymce__oxide--tox-dialog-dock-transition',
  'tox-platform-ie': 'tinymce__oxide--tox-platform-ie',
  'tox-dialog__disable-scroll': 'tinymce__oxide--tox-dialog__disable-scroll',
  'tox-dropzone-container': 'tinymce__oxide--tox-dropzone-container',
  'tox-dropzone': 'tinymce__oxide--tox-dropzone',
  'tox-edit-area': 'tinymce__oxide--tox-edit-area',
  'tox-edit-area__iframe': 'tinymce__oxide--tox-edit-area__iframe',
  'tox-inline-edit-area': 'tinymce__oxide--tox-inline-edit-area',
  'tox-editor-container': 'tinymce__oxide--tox-editor-container',
  'tox-tinymce--toolbar-bottom': 'tinymce__oxide--tox-tinymce--toolbar-bottom',
  'tox-tinymce--toolbar-sticky-on': 'tinymce__oxide--tox-tinymce--toolbar-sticky-on',
  'tox-editor-dock-fadeout': 'tinymce__oxide--tox-editor-dock-fadeout',
  'tox-editor-dock-fadein': 'tinymce__oxide--tox-editor-dock-fadein',
  'tox-editor-dock-transition': 'tinymce__oxide--tox-editor-dock-transition',
  'tox-control-wrap': 'tinymce__oxide--tox-control-wrap',
  'tox-control-wrap--status-invalid': 'tinymce__oxide--tox-control-wrap--status-invalid',
  'tox-control-wrap__status-icon-invalid': 'tinymce__oxide--tox-control-wrap__status-icon-invalid',
  'tox-control-wrap--status-unknown': 'tinymce__oxide--tox-control-wrap--status-unknown',
  'tox-control-wrap__status-icon-unknown': 'tinymce__oxide--tox-control-wrap__status-icon-unknown',
  'tox-control-wrap--status-valid': 'tinymce__oxide--tox-control-wrap--status-valid',
  'tox-control-wrap__status-icon-valid': 'tinymce__oxide--tox-control-wrap__status-icon-valid',
  'tox-control-wrap__status-icon-wrap': 'tinymce__oxide--tox-control-wrap__status-icon-wrap',
  'tox-textfield': 'tinymce__oxide--tox-textfield',
  'tox-autocompleter': 'tinymce__oxide--tox-autocompleter',
  'tox-menu': 'tinymce__oxide--tox-menu',
  'tox-autocompleter-highlight': 'tinymce__oxide--tox-autocompleter-highlight',
  'tox-color-input': 'tinymce__oxide--tox-color-input',
  'tox-label': 'tinymce__oxide--tox-label',
  'tox-toolbar-label': 'tinymce__oxide--tox-toolbar-label',
  'tox-form': 'tinymce__oxide--tox-form',
  'tox-form-group--maximize': 'tinymce__oxide--tox-form-group--maximize',
  'tox-form__group--error': 'tinymce__oxide--tox-form__group--error',
  'tox-form__group--collection': 'tinymce__oxide--tox-form__group--collection',
  'tox-form__grid': 'tinymce__oxide--tox-form__grid',
  'tox-form__grid--2col': 'tinymce__oxide--tox-form__grid--2col',
  'tox-form__grid--3col': 'tinymce__oxide--tox-form__grid--3col',
  'tox-form__grid--4col': 'tinymce__oxide--tox-form__grid--4col',
  'tox-form__controls-h-stack': 'tinymce__oxide--tox-form__controls-h-stack',
  'tox-form__group--inline': 'tinymce__oxide--tox-form__group--inline',
  'tox-form__group--stretched': 'tinymce__oxide--tox-form__group--stretched',
  'tox-textarea': 'tinymce__oxide--tox-textarea',
  'tox-lock': 'tinymce__oxide--tox-lock',
  'tox-locked': 'tinymce__oxide--tox-locked',
  'tox-lock-icon__unlock': 'tinymce__oxide--tox-lock-icon__unlock',
  'tox-lock-icon__lock': 'tinymce__oxide--tox-lock-icon__lock',
  'tox-listboxfield': 'tinymce__oxide--tox-listboxfield',
  'tox-listbox--select': 'tinymce__oxide--tox-listbox--select',
  'tox-toolbar-textfield': 'tinymce__oxide--tox-toolbar-textfield',
  'tox-naked-btn': 'tinymce__oxide--tox-naked-btn',
  'tox-listbox__select-label': 'tinymce__oxide--tox-listbox__select-label',
  'tox-listbox__select-chevron': 'tinymce__oxide--tox-listbox__select-chevron',
  'tox-selectfield': 'tinymce__oxide--tox-selectfield',
  'tox-fullscreen': 'tinymce__oxide--tox-fullscreen',
  'tox-statusbar__resize-handle': 'tinymce__oxide--tox-statusbar__resize-handle',
  'tox-shadowhost': 'tinymce__oxide--tox-shadowhost',
  'tox-help__more-link': 'tinymce__oxide--tox-help__more-link',
  'tox-image-tools': 'tinymce__oxide--tox-image-tools',
  'tox-image-tools__toolbar': 'tinymce__oxide--tox-image-tools__toolbar',
  'tox-image-tools__image': 'tinymce__oxide--tox-image-tools__image',
  'tox-image-tools__image-bg': 'tinymce__oxide--tox-image-tools__image-bg',
  'tox-spacer': 'tinymce__oxide--tox-spacer',
  'tox-croprect-block': 'tinymce__oxide--tox-croprect-block',
  'tox-croprect-handle': 'tinymce__oxide--tox-croprect-handle',
  'tox-croprect-handle-move': 'tinymce__oxide--tox-croprect-handle-move',
  'tox-croprect-handle-nw': 'tinymce__oxide--tox-croprect-handle-nw',
  'tox-croprect-handle-ne': 'tinymce__oxide--tox-croprect-handle-ne',
  'tox-croprect-handle-sw': 'tinymce__oxide--tox-croprect-handle-sw',
  'tox-croprect-handle-se': 'tinymce__oxide--tox-croprect-handle-se',
  'tox-slider': 'tinymce__oxide--tox-slider',
  'tox-insert-table-picker': 'tinymce__oxide--tox-insert-table-picker',
  'tox-insert-table-picker__selected': 'tinymce__oxide--tox-insert-table-picker__selected',
  'tox-insert-table-picker__label': 'tinymce__oxide--tox-insert-table-picker__label',
  'tox-menu__label': 'tinymce__oxide--tox-menu__label',
  'tox-menubar': 'tinymce__oxide--tox-menubar',
  'tox-mbtn': 'tinymce__oxide--tox-mbtn',
  'tox-mbtn--active': 'tinymce__oxide--tox-mbtn--active',
  'tox-mbtn__select-label': 'tinymce__oxide--tox-mbtn__select-label',
  'tox-mbtn__select-chevron': 'tinymce__oxide--tox-mbtn__select-chevron',
  'tox-notification': 'tinymce__oxide--tox-notification',
  'tox-notification--in': 'tinymce__oxide--tox-notification--in',
  'tox-notification--success': 'tinymce__oxide--tox-notification--success',
  'tox-notification--error': 'tinymce__oxide--tox-notification--error',
  'tox-notification--warn': 'tinymce__oxide--tox-notification--warn',
  'tox-notification--warning': 'tinymce__oxide--tox-notification--warning',
  'tox-notification--info': 'tinymce__oxide--tox-notification--info',
  'tox-notification__body': 'tinymce__oxide--tox-notification__body',
  'tox-notification__icon': 'tinymce__oxide--tox-notification__icon',
  'tox-notification__dismiss': 'tinymce__oxide--tox-notification__dismiss',
  'tox-progress-bar': 'tinymce__oxide--tox-progress-bar',
  'tox-pop': 'tinymce__oxide--tox-pop',
  'tox-pop--resizing': 'tinymce__oxide--tox-pop--resizing',
  'tox-pop__dialog': 'tinymce__oxide--tox-pop__dialog',
  'tox-pop--bottom': 'tinymce__oxide--tox-pop--bottom',
  'tox-pop--top': 'tinymce__oxide--tox-pop--top',
  'tox-pop--left': 'tinymce__oxide--tox-pop--left',
  'tox-pop--right': 'tinymce__oxide--tox-pop--right',
  'tox-pop--align-left': 'tinymce__oxide--tox-pop--align-left',
  'tox-pop--align-right': 'tinymce__oxide--tox-pop--align-right',
  'tox-sidebar-wrap': 'tinymce__oxide--tox-sidebar-wrap',
  'tox-sidebar': 'tinymce__oxide--tox-sidebar',
  'tox-sidebar__slider': 'tinymce__oxide--tox-sidebar__slider',
  'tox-sidebar__pane-container': 'tinymce__oxide--tox-sidebar__pane-container',
  'tox-sidebar__pane': 'tinymce__oxide--tox-sidebar__pane',
  'tox-sidebar--sliding-closed': 'tinymce__oxide--tox-sidebar--sliding-closed',
  'tox-sidebar--sliding-open': 'tinymce__oxide--tox-sidebar--sliding-open',
  'tox-sidebar--sliding-growing': 'tinymce__oxide--tox-sidebar--sliding-growing',
  'tox-sidebar--sliding-shrinking': 'tinymce__oxide--tox-sidebar--sliding-shrinking',
  'tox-selector': 'tinymce__oxide--tox-selector',
  'tox-platform-touch': 'tinymce__oxide--tox-platform-touch',
  'tox-slider__rail': 'tinymce__oxide--tox-slider__rail',
  'tox-slider__handle': 'tinymce__oxide--tox-slider__handle',
  'tox-source-code': 'tinymce__oxide--tox-source-code',
  'tox-spinner': 'tinymce__oxide--tox-spinner',
  'tam-bouncing-dots': 'tinymce__oxide--tam-bouncing-dots',
  'tox-statusbar': 'tinymce__oxide--tox-statusbar',
  'tox-statusbar__text-container': 'tinymce__oxide--tox-statusbar__text-container',
  'tox-statusbar__path': 'tinymce__oxide--tox-statusbar__path',
  'tox-statusbar__wordcount': 'tinymce__oxide--tox-statusbar__wordcount',
  'tox-statusbar__path-item': 'tinymce__oxide--tox-statusbar__path-item',
  'tox-statusbar__branding': 'tinymce__oxide--tox-statusbar__branding',
  'tox-throbber': 'tinymce__oxide--tox-throbber',
  'tox-throbber__busy-spinner': 'tinymce__oxide--tox-throbber__busy-spinner',
  'tox-tbtn': 'tinymce__oxide--tox-tbtn',
  'tox-tbtn-more': 'tinymce__oxide--tox-tbtn-more',
  'tox-tbtn--disabled': 'tinymce__oxide--tox-tbtn--disabled',
  'tox-tbtn--enabled': 'tinymce__oxide--tox-tbtn--enabled',
  'tox-tbtn--md': 'tinymce__oxide--tox-tbtn--md',
  'tox-tbtn--lg': 'tinymce__oxide--tox-tbtn--lg',
  'tox-tbtn--return': 'tinymce__oxide--tox-tbtn--return',
  'tox-tbtn--labeled': 'tinymce__oxide--tox-tbtn--labeled',
  'tox-tbtn__vlabel': 'tinymce__oxide--tox-tbtn__vlabel',
  'tox-tbtn--select': 'tinymce__oxide--tox-tbtn--select',
  'tox-tbtn__select-label': 'tinymce__oxide--tox-tbtn__select-label',
  'tox-tbtn__select-chevron': 'tinymce__oxide--tox-tbtn__select-chevron',
  'tox-tbtn--bespoke': 'tinymce__oxide--tox-tbtn--bespoke',
  'tox-split-button': 'tinymce__oxide--tox-split-button',
  'tox-split-button__chevron': 'tinymce__oxide--tox-split-button__chevron',
  'tox-toolbar-overlord': 'tinymce__oxide--tox-toolbar-overlord',
  'tox-toolbar__overflow--closed': 'tinymce__oxide--tox-toolbar__overflow--closed',
  'tox-toolbar__overflow--growing': 'tinymce__oxide--tox-toolbar__overflow--growing',
  'tox-toolbar__overflow--shrinking': 'tinymce__oxide--tox-toolbar__overflow--shrinking',
  'tox-toolbar--scrolling': 'tinymce__oxide--tox-toolbar--scrolling',
  'tox-toolbar--no-divider': 'tinymce__oxide--tox-toolbar--no-divider',
  'tox-tbtn__icon-rtl': 'tinymce__oxide--tox-tbtn__icon-rtl',
  'tox-toolbar__group': 'tinymce__oxide--tox-toolbar__group',
  'tox-toolbar__group--pull-right': 'tinymce__oxide--tox-toolbar__group--pull-right',
  'tox-tooltip': 'tinymce__oxide--tox-tooltip',
  'tox-tooltip__body': 'tinymce__oxide--tox-tooltip__body',
  'tox-tooltip__arrow': 'tinymce__oxide--tox-tooltip__arrow',
  'tox-tooltip--down': 'tinymce__oxide--tox-tooltip--down',
  'tox-tooltip--up': 'tinymce__oxide--tox-tooltip--up',
  'tox-tooltip--right': 'tinymce__oxide--tox-tooltip--right',
  'tox-tooltip--left': 'tinymce__oxide--tox-tooltip--left',
  'tox-well': 'tinymce__oxide--tox-well',
  'tox-custom-editor': 'tinymce__oxide--tox-custom-editor',
  'tox-dialog-loading': 'tinymce__oxide--tox-dialog-loading',
  'tox-tab': 'tinymce__oxide--tox-tab',
  'tox-dialog__content-js': 'tinymce__oxide--tox-dialog__content-js',
  'tox-image-tools-edit-panel': 'tinymce__oxide--tox-image-tools-edit-panel',
  'tox-image-tools__sidebar': 'tinymce__oxide--tox-image-tools__sidebar'
}.template().replace(/tinymce__oxide--/g, '');
const contentCSS = {
  componentId: 'bKkob',
  template: function () {
    return `


.tinymce__oxide--mce-content-body .tinymce__oxide--mce-item-anchor {
  background: transparent url("data:image/svg+xml;charset=UTF-8,%3Csvg%20width%3D'8'%20height%3D'12'%20xmlns%3D'http%3A%2F%2Fwww.w3.org%2F2000%2Fsvg'%3E%3Cpath%20d%3D'M0%200L8%200%208%2012%204.09117821%209%200%2012z'%2F%3E%3C%2Fsvg%3E%0A") no-repeat center;
  cursor: default;
  display: inline-block;
  height: 12px !important;
  padding: 0 2px;
  -webkit-user-modify: read-only;
  -moz-user-modify: read-only;
  -webkit-user-select: all;
      user-select: all;
  width: 8px !important;
}
.tinymce__oxide--mce-content-body .tinymce__oxide--mce-item-anchor[data-mce-selected] {
  outline-offset: 1px;
}
.tinymce__oxide--tox-comments-visible .tinymce__oxide--tox-comment {
  background-color: #fff0b7;
}
.tinymce__oxide--tox-comments-visible .tinymce__oxide--tox-comment--active {
  background-color: #ffe168;
}
.tinymce__oxide--tox-checklist > li:not(.tinymce__oxide--tox-checklist--hidden) {
  list-style: none;
  margin: 0.25em 0;
}
.tinymce__oxide--tox-checklist > li:not(.tinymce__oxide--tox-checklist--hidden)::before {
  content: url("data:image/svg+xml;charset=UTF-8,%3Csvg%20xmlns%3D%22http%3A%2F%2Fwww.w3.org%2F2000%2Fsvg%22%20width%3D%2216%22%20height%3D%2216%22%20viewBox%3D%220%200%2016%2016%22%3E%3Cg%20id%3D%22checklist-unchecked%22%20fill%3D%22none%22%20fill-rule%3D%22evenodd%22%3E%3Crect%20id%3D%22Rectangle%22%20width%3D%2215%22%20height%3D%2215%22%20x%3D%22.5%22%20y%3D%22.5%22%20fill-rule%3D%22nonzero%22%20stroke%3D%22%234C4C4C%22%20rx%3D%222%22%2F%3E%3C%2Fg%3E%3C%2Fsvg%3E%0A");
  cursor: pointer;
  height: 1em;
  margin-left: -1.5em;
  margin-top: 0.125em;
  position: absolute;
  width: 1em;
}
.tinymce__oxide--tox-checklist li:not(.tinymce__oxide--tox-checklist--hidden).tinymce__oxide--tox-checklist--checked::before {
  content: url("data:image/svg+xml;charset=UTF-8,%3Csvg%20xmlns%3D%22http%3A%2F%2Fwww.w3.org%2F2000%2Fsvg%22%20width%3D%2216%22%20height%3D%2216%22%20viewBox%3D%220%200%2016%2016%22%3E%3Cg%20id%3D%22checklist-checked%22%20fill%3D%22none%22%20fill-rule%3D%22evenodd%22%3E%3Crect%20id%3D%22Rectangle%22%20width%3D%2216%22%20height%3D%2216%22%20fill%3D%22%234099FF%22%20fill-rule%3D%22nonzero%22%20rx%3D%222%22%2F%3E%3Cpath%20id%3D%22Path%22%20fill%3D%22%23FFF%22%20fill-rule%3D%22nonzero%22%20d%3D%22M11.5703186%2C3.14417309%20C11.8516238%2C2.73724603%2012.4164781%2C2.62829933%2012.83558%2C2.89774797%20C13.260121%2C3.17069355%2013.3759736%2C3.72932262%2013.0909105%2C4.14168582%20L7.7580587%2C11.8560195%20C7.43776896%2C12.3193404%206.76483983%2C12.3852142%206.35607322%2C11.9948725%20L3.02491697%2C8.8138662%20C2.66090143%2C8.46625845%202.65798871%2C7.89594698%203.01850234%2C7.54483354%20C3.373942%2C7.19866177%203.94940006%2C7.19592841%204.30829608%2C7.5386474%20L6.85276923%2C9.9684299%20L11.5703186%2C3.14417309%20Z%22%2F%3E%3C%2Fg%3E%3C%2Fsvg%3E%0A");
}
[dir=rtl] .tinymce__oxide--tox-checklist > li:not(.tinymce__oxide--tox-checklist--hidden)::before {
  margin-left: 0;
  margin-right: -1.5em;
}



code[class*="language-"],
pre[class*="language-"] {
  color: black;
  background: none;
  text-shadow: 0 1px white;
  font-family: Consolas, Monaco, 'Andale Mono', 'Ubuntu Mono', monospace;
  font-size: 1em;
  text-align: left;
  white-space: pre;
  word-spacing: normal;
  word-break: normal;
  word-wrap: normal;
  line-height: 1.5;
  -moz-tab-size: 4;
  tab-size: 4;
  -webkit-hyphens: none;
  hyphens: none;
}
[dir="ltr"] code[class*="language-"],
[dir="ltr"] pre[class*="language-"] {
  text-align: left;
}
[dir="rtl"] code[class*="language-"],
[dir="rtl"] pre[class*="language-"] {
  text-align: left;
}
pre[class*="language-"]::selection,
pre[class*="language-"] ::selection,
code[class*="language-"]::selection,
code[class*="language-"] ::selection {
  text-shadow: none;
  background: #b3d4fc;
}
@media print {
  code[class*="language-"],
  pre[class*="language-"] {
    text-shadow: none;
  }
}

pre[class*="language-"] {
  padding: 1em;
  margin: 0.5em 0;
  overflow: auto;
}
:not(pre) > code[class*="language-"],
pre[class*="language-"] {
  background: #f5f2f0;
}

:not(pre) > code[class*="language-"] {
  padding: 0.1em;
  border-radius: 0.3em;
  white-space: normal;
}
.tinymce__oxide--token.tinymce__oxide--comment,
.tinymce__oxide--token.tinymce__oxide--prolog,
.tinymce__oxide--token.tinymce__oxide--doctype,
.tinymce__oxide--token.tinymce__oxide--cdata {
  color: slategray;
}
.tinymce__oxide--token.tinymce__oxide--punctuation {
  color: #999;
}
.tinymce__oxide--namespace {
  opacity: 0.7;
}
.tinymce__oxide--token.tinymce__oxide--property,
.tinymce__oxide--token.tinymce__oxide--tag,
.tinymce__oxide--token.tinymce__oxide--boolean,
.tinymce__oxide--token.tinymce__oxide--number,
.tinymce__oxide--token.tinymce__oxide--constant,
.tinymce__oxide--token.tinymce__oxide--symbol,
.tinymce__oxide--token.tinymce__oxide--deleted {
  color: #905;
}
.tinymce__oxide--token.tinymce__oxide--selector,
.tinymce__oxide--token.tinymce__oxide--attr-name,
.tinymce__oxide--token.tinymce__oxide--string,
.tinymce__oxide--token.tinymce__oxide--char,
.tinymce__oxide--token.tinymce__oxide--builtin,
.tinymce__oxide--token.tinymce__oxide--inserted {
  color: #690;
}
.tinymce__oxide--token.tinymce__oxide--operator,
.tinymce__oxide--token.tinymce__oxide--entity,
.tinymce__oxide--token.tinymce__oxide--url,
.tinymce__oxide--language-css .tinymce__oxide--token.tinymce__oxide--string,
.tinymce__oxide--style .tinymce__oxide--token.tinymce__oxide--string {
  color: #9a6e3a;
  background: hsla(0, 0%, 100%, 0.5);
}
.tinymce__oxide--token.tinymce__oxide--atrule,
.tinymce__oxide--token.tinymce__oxide--attr-value,
.tinymce__oxide--token.tinymce__oxide--keyword {
  color: #07a;
}
.tinymce__oxide--token.tinymce__oxide--function,
.tinymce__oxide--token.tinymce__oxide--class-name {
  color: #DD4A68;
}
.tinymce__oxide--token.tinymce__oxide--regex,
.tinymce__oxide--token.tinymce__oxide--important,
.tinymce__oxide--token.tinymce__oxide--variable {
  color: #e90;
}
.tinymce__oxide--token.tinymce__oxide--important,
.tinymce__oxide--token.tinymce__oxide--bold {
  font-weight: bold;
}
.tinymce__oxide--token.tinymce__oxide--italic {
  font-style: italic;
}
.tinymce__oxide--token.tinymce__oxide--entity {
  cursor: help;
}

.tinymce__oxide--mce-content-body {
  overflow-wrap: break-word;
  word-wrap: break-word;
}
.tinymce__oxide--mce-content-body .tinymce__oxide--mce-visual-caret {
  background-color: black;
  background-color: currentColor;
  position: absolute;
}
.tinymce__oxide--mce-content-body .tinymce__oxide--mce-visual-caret-hidden {
  display: none;
}
.tinymce__oxide--mce-content-body *[data-mce-caret] {
  left: -1000px;
  margin: 0;
  padding: 0;
  position: absolute;
  right: auto;
  top: 0;
}
.tinymce__oxide--mce-content-body .tinymce__oxide--mce-offscreen-selection {
  left: -2000000px;
  max-width: 1000000px;
  position: absolute;
}
.tinymce__oxide--mce-content-body *[contentEditable=false] {
  cursor: default;
}
.tinymce__oxide--mce-content-body *[contentEditable=true] {
  cursor: text;
}
.tinymce__oxide--tox-cursor-format-painter {
  cursor: url("data:image/svg+xml;charset=UTF-8,%3Csvg%20xmlns%3D%22http%3A%2F%2Fwww.w3.org%2F2000%2Fsvg%22%20width%3D%2224%22%20height%3D%2224%22%20viewBox%3D%220%200%2024%2024%22%3E%0A%20%20%3Cg%20fill%3D%22none%22%20fill-rule%3D%22evenodd%22%3E%0A%20%20%20%20%3Cpath%20fill%3D%22%23000%22%20fill-rule%3D%22nonzero%22%20d%3D%22M15%2C6%20C15%2C5.45%2014.55%2C5%2014%2C5%20L6%2C5%20C5.45%2C5%205%2C5.45%205%2C6%20L5%2C10%20C5%2C10.55%205.45%2C11%206%2C11%20L14%2C11%20C14.55%2C11%2015%2C10.55%2015%2C10%20L15%2C9%20L16%2C9%20L16%2C12%20L9%2C12%20L9%2C19%20C9%2C19.55%209.45%2C20%2010%2C20%20L11%2C20%20C11.55%2C20%2012%2C19.55%2012%2C19%20L12%2C14%20L18%2C14%20L18%2C7%20L15%2C7%20L15%2C6%20Z%22%2F%3E%0A%20%20%20%20%3Cpath%20fill%3D%22%23000%22%20fill-rule%3D%22nonzero%22%20d%3D%22M1%2C1%20L8.25%2C1%20C8.66421356%2C1%209%2C1.33578644%209%2C1.75%20L9%2C1.75%20C9%2C2.16421356%208.66421356%2C2.5%208.25%2C2.5%20L2.5%2C2.5%20L2.5%2C8.25%20C2.5%2C8.66421356%202.16421356%2C9%201.75%2C9%20L1.75%2C9%20C1.33578644%2C9%201%2C8.66421356%201%2C8.25%20L1%2C1%20Z%22%2F%3E%0A%20%20%3C%2Fg%3E%0A%3C%2Fsvg%3E%0A"), default;
}
.tinymce__oxide--mce-content-body figure.tinymce__oxide--align-left {
  float: left;
}
[dir="ltr"] .tinymce__oxide--mce-content-body figure.tinymce__oxide--align-left {
  float: left;
}
[dir="rtl"] .tinymce__oxide--mce-content-body figure.tinymce__oxide--align-left {
  float: left;
}
.tinymce__oxide--mce-content-body figure.tinymce__oxide--align-right {
  float: right;
}
[dir="ltr"] .tinymce__oxide--mce-content-body figure.tinymce__oxide--align-right {
  float: right;
}
[dir="rtl"] .tinymce__oxide--mce-content-body figure.tinymce__oxide--align-right {
  float: right;
}
.tinymce__oxide--mce-content-body figure.tinymce__oxide--image.tinymce__oxide--align-center {
  display: table;
  margin-left: auto;
  margin-right: auto;
}
.tinymce__oxide--mce-preview-object {
  border: 1px solid gray;
  display: inline-block;
  line-height: 0;
  margin: 0 2px 0 2px;
  position: relative;
}
.tinymce__oxide--mce-preview-object .tinymce__oxide--mce-shim {
  background: url(data:image/gif;base64,R0lGODlhAQABAIAAAAAAAP///yH5BAEAAAAALAAAAAABAAEAAAIBRAA7);
  height: 100%;
  left: 0;
  position: absolute;
  top: 0;
  width: 100%;
}
.tinymce__oxide--mce-preview-object[data-mce-selected="2"] .tinymce__oxide--mce-shim {
  display: none;
}
.tinymce__oxide--mce-object {
  background: transparent url("data:image/svg+xml;charset=UTF-8,%3Csvg%20xmlns%3D%22http%3A%2F%2Fwww.w3.org%2F2000%2Fsvg%22%20width%3D%2224%22%20height%3D%2224%22%3E%3Cpath%20d%3D%22M4%203h16a1%201%200%200%201%201%201v16a1%201%200%200%201-1%201H4a1%201%200%200%201-1-1V4a1%201%200%200%201%201-1zm1%202v14h14V5H5zm4.79%202.565l5.64%204.028a.5.5%200%200%201%200%20.814l-5.64%204.028a.5.5%200%200%201-.79-.407V7.972a.5.5%200%200%201%20.79-.407z%22%2F%3E%3C%2Fsvg%3E%0A") no-repeat center;
  border: 1px dashed #aaa;
}
.tinymce__oxide--mce-pagebreak {
  border: 1px dashed #aaa;
  cursor: default;
  display: block;
  height: 5px;
  margin-top: 15px;
  page-break-before: always;
  width: 100%;
}
@media print {
  .tinymce__oxide--mce-pagebreak {
    border: 0;
  }
}
.tinymce__oxide--tiny-pageembed .tinymce__oxide--mce-shim {
  background: url(data:image/gif;base64,R0lGODlhAQABAIAAAAAAAP///yH5BAEAAAAALAAAAAABAAEAAAIBRAA7);
  height: 100%;
  left: 0;
  position: absolute;
  top: 0;
  width: 100%;
}
.tinymce__oxide--tiny-pageembed[data-mce-selected="2"] .tinymce__oxide--mce-shim {
  display: none;
}
.tinymce__oxide--tiny-pageembed {
  display: inline-block;
  position: relative;
}
.tinymce__oxide--tiny-pageembed--21by9,
.tinymce__oxide--tiny-pageembed--16by9,
.tinymce__oxide--tiny-pageembed--4by3,
.tinymce__oxide--tiny-pageembed--1by1 {
  display: block;
  overflow: hidden;
  padding: 0;
  position: relative;
  width: 100%;
}
.tinymce__oxide--tiny-pageembed--21by9 {
  padding-top: 42.857143%;
}
.tinymce__oxide--tiny-pageembed--16by9 {
  padding-top: 56.25%;
}
.tinymce__oxide--tiny-pageembed--4by3 {
  padding-top: 75%;
}
.tinymce__oxide--tiny-pageembed--1by1 {
  padding-top: 100%;
}
.tinymce__oxide--tiny-pageembed--21by9 iframe,
.tinymce__oxide--tiny-pageembed--16by9 iframe,
.tinymce__oxide--tiny-pageembed--4by3 iframe,
.tinymce__oxide--tiny-pageembed--1by1 iframe {
  border: 0;
  height: 100%;
  left: 0;
  position: absolute;
  top: 0;
  width: 100%;
}
.tinymce__oxide--mce-content-body[data-mce-placeholder] {
  position: relative;
}
.tinymce__oxide--mce-content-body[data-mce-placeholder]:not(.tinymce__oxide--mce-visualblocks)::before {
  color: rgba(34, 47, 62, 0.7);
  content: attr(data-mce-placeholder);
  position: absolute;
}
.tinymce__oxide--mce-content-body:not([dir=rtl])[data-mce-placeholder]:not(.tinymce__oxide--mce-visualblocks)::before {
  left: 1px;
}
.tinymce__oxide--mce-content-body[dir=rtl][data-mce-placeholder]:not(.tinymce__oxide--mce-visualblocks)::before {
  right: 1px;
}
.tinymce__oxide--mce-content-body div.tinymce__oxide--mce-resizehandle {
  background-color: #4099ff;
  border-color: #4099ff;
  border-style: solid;
  border-width: 1px;
  box-sizing: border-box;
  height: 10px;
  position: absolute;
  width: 10px;
  z-index: 10000;
}
.tinymce__oxide--mce-content-body div.tinymce__oxide--mce-resizehandle:hover {
  background-color: #4099ff;
}
.tinymce__oxide--mce-content-body div.tinymce__oxide--mce-resizehandle:nth-of-type(1) {
  cursor: nwse-resize;
}
.tinymce__oxide--mce-content-body div.tinymce__oxide--mce-resizehandle:nth-of-type(2) {
  cursor: nesw-resize;
}
.tinymce__oxide--mce-content-body div.tinymce__oxide--mce-resizehandle:nth-of-type(3) {
  cursor: nwse-resize;
}
.tinymce__oxide--mce-content-body div.tinymce__oxide--mce-resizehandle:nth-of-type(4) {
  cursor: nesw-resize;
}
.tinymce__oxide--mce-content-body .tinymce__oxide--mce-resize-backdrop {
  z-index: 10000;
}
.tinymce__oxide--mce-content-body .tinymce__oxide--mce-clonedresizable {
  cursor: default;
  opacity: 0.5;
  outline: 1px dashed black;
  position: absolute;
  z-index: 10001;
}
.tinymce__oxide--mce-content-body .tinymce__oxide--mce-clonedresizable.tinymce__oxide--mce-resizetable-columns th,
.tinymce__oxide--mce-content-body .tinymce__oxide--mce-clonedresizable.tinymce__oxide--mce-resizetable-columns td {
  border: 0;
}
.tinymce__oxide--mce-content-body .tinymce__oxide--mce-resize-helper {
  background: #555;
  background: rgba(0, 0, 0, 0.75);
  border: 1px;
  border-radius: 3px;
  color: white;
  display: none;
  font-family: sans-serif;
  font-size: 12px;
  line-height: 14px;
  margin: 5px 10px;
  padding: 5px;
  position: absolute;
  white-space: nowrap;
  z-index: 10002;
}
.tinymce__oxide--tox-rtc-user-selection {
  position: relative;
}
.tinymce__oxide--tox-rtc-user-cursor {
  bottom: 0;
  cursor: default;
  position: absolute;
  top: 0;
  width: 2px;
}
.tinymce__oxide--tox-rtc-user-cursor::before {
  background-color: inherit;
  border-radius: 50%;
  content: '';
  display: block;
  height: 8px;
  position: absolute;
  right: -3px;
  top: -3px;
  width: 8px;
}
.tinymce__oxide--tox-rtc-user-cursor:hover::after {
  background-color: inherit;
  border-radius: 100px;
  box-sizing: border-box;
  color: #fff;
  content: attr(data-user);
  display: block;
  font-size: 12px;
  font-weight: bold;
  left: -5px;
  min-height: 8px;
  min-width: 8px;
  padding: 0 12px;
  position: absolute;
  top: -11px;
  white-space: nowrap;
  z-index: 1000;
}
.tinymce__oxide--tox-rtc-user-selection--1 .tinymce__oxide--tox-rtc-user-cursor {
  background-color: #2dc26b;
}
.tinymce__oxide--tox-rtc-user-selection--2 .tinymce__oxide--tox-rtc-user-cursor {
  background-color: #e03e2d;
}
.tinymce__oxide--tox-rtc-user-selection--3 .tinymce__oxide--tox-rtc-user-cursor {
  background-color: #f1c40f;
}
.tinymce__oxide--tox-rtc-user-selection--4 .tinymce__oxide--tox-rtc-user-cursor {
  background-color: #3598db;
}
.tinymce__oxide--tox-rtc-user-selection--5 .tinymce__oxide--tox-rtc-user-cursor {
  background-color: #b96ad9;
}
.tinymce__oxide--tox-rtc-user-selection--6 .tinymce__oxide--tox-rtc-user-cursor {
  background-color: #e67e23;
}
.tinymce__oxide--tox-rtc-user-selection--7 .tinymce__oxide--tox-rtc-user-cursor {
  background-color: #aaa69d;
}
.tinymce__oxide--tox-rtc-user-selection--8 .tinymce__oxide--tox-rtc-user-cursor {
  background-color: #f368e0;
}
.tinymce__oxide--tox-rtc-remote-image {
  background: #eaeaea url("data:image/svg+xml;charset=UTF-8,%3Csvg%20width%3D%2236%22%20height%3D%2212%22%20viewBox%3D%220%200%2036%2012%22%20xmlns%3D%22http%3A%2F%2Fwww.w3.org%2F2000%2Fsvg%22%3E%0A%20%20%3Ccircle%20cx%3D%226%22%20cy%3D%226%22%20r%3D%223%22%20fill%3D%22rgba(0%2C%200%2C%200%2C%20.2)%22%3E%0A%20%20%20%20%3Canimate%20attributeName%3D%22r%22%20values%3D%223%3B5%3B3%22%20calcMode%3D%22linear%22%20dur%3D%221s%22%20repeatCount%3D%22indefinite%22%20%2F%3E%0A%20%20%3C%2Fcircle%3E%0A%20%20%3Ccircle%20cx%3D%2218%22%20cy%3D%226%22%20r%3D%223%22%20fill%3D%22rgba(0%2C%200%2C%200%2C%20.2)%22%3E%0A%20%20%20%20%3Canimate%20attributeName%3D%22r%22%20values%3D%223%3B5%3B3%22%20calcMode%3D%22linear%22%20begin%3D%22.33s%22%20dur%3D%221s%22%20repeatCount%3D%22indefinite%22%20%2F%3E%0A%20%20%3C%2Fcircle%3E%0A%20%20%3Ccircle%20cx%3D%2230%22%20cy%3D%226%22%20r%3D%223%22%20fill%3D%22rgba(0%2C%200%2C%200%2C%20.2)%22%3E%0A%20%20%20%20%3Canimate%20attributeName%3D%22r%22%20values%3D%223%3B5%3B3%22%20calcMode%3D%22linear%22%20begin%3D%22.66s%22%20dur%3D%221s%22%20repeatCount%3D%22indefinite%22%20%2F%3E%0A%20%20%3C%2Fcircle%3E%0A%3C%2Fsvg%3E%0A") no-repeat center center;
  border: 1px solid #ccc;
  min-height: 240px;
  min-width: 320px;
}
.tinymce__oxide--mce-match-marker {
  background: #aaa;
  color: #fff;
}
.tinymce__oxide--mce-match-marker-selected {
  background: #39f;
  color: #fff;
}
.tinymce__oxide--mce-match-marker-selected::selection {
  background: #39f;
  color: #fff;
}
.tinymce__oxide--mce-content-body img[data-mce-selected],
.tinymce__oxide--mce-content-body video[data-mce-selected],
.tinymce__oxide--mce-content-body audio[data-mce-selected],
.tinymce__oxide--mce-content-body object[data-mce-selected],
.tinymce__oxide--mce-content-body embed[data-mce-selected],
.tinymce__oxide--mce-content-body table[data-mce-selected] {
  outline: 3px solid #b4d7ff;
}
.tinymce__oxide--mce-content-body hr[data-mce-selected] {
  outline: 3px solid #b4d7ff;
  outline-offset: 1px;
}
.tinymce__oxide--mce-content-body *[contentEditable=false] *[contentEditable=true]:focus {
  outline: 3px solid #b4d7ff;
}
.tinymce__oxide--mce-content-body *[contentEditable=false] *[contentEditable=true]:hover {
  outline: 3px solid #b4d7ff;
}
.tinymce__oxide--mce-content-body *[contentEditable=false][data-mce-selected] {
  cursor: not-allowed;
  outline: 3px solid #b4d7ff;
}
.tinymce__oxide--mce-content-body.tinymce__oxide--mce-content-readonly *[contentEditable=true]:focus,
.tinymce__oxide--mce-content-body.tinymce__oxide--mce-content-readonly *[contentEditable=true]:hover {
  outline: none;
}
.tinymce__oxide--mce-content-body *[data-mce-selected="inline-boundary"] {
  background-color: #b4d7ff;
}
.tinymce__oxide--mce-content-body .tinymce__oxide--mce-edit-focus {
  outline: 3px solid #b4d7ff;
}
.tinymce__oxide--mce-content-body td[data-mce-selected],
.tinymce__oxide--mce-content-body th[data-mce-selected] {
  position: relative;
}
.tinymce__oxide--mce-content-body td[data-mce-selected]::selection,
.tinymce__oxide--mce-content-body th[data-mce-selected]::selection {
  background: none;
}
.tinymce__oxide--mce-content-body td[data-mce-selected] *,
.tinymce__oxide--mce-content-body th[data-mce-selected] * {
  outline: none;
  -webkit-touch-callout: none;
  -webkit-user-select: none;
          user-select: none;
}
.tinymce__oxide--mce-content-body td[data-mce-selected]::after,
.tinymce__oxide--mce-content-body th[data-mce-selected]::after {
  background-color: rgba(180, 215, 255, 0.7);
  border: 1px solid rgba(180, 215, 255, 0.7);
  bottom: -1px;
  content: '';
  left: -1px;
  mix-blend-mode: multiply;
  position: absolute;
  right: -1px;
  top: -1px;
}
@media screen and (-ms-high-contrast: active), (-ms-high-contrast: none) {
  .tinymce__oxide--mce-content-body td[data-mce-selected]::after,
  .tinymce__oxide--mce-content-body th[data-mce-selected]::after {
    border-color: rgba(0, 84, 180, 0.7);
  }
}
.tinymce__oxide--mce-content-body img::selection {
  background: none;
}
.tinymce__oxide--ephox-snooker-resizer-bar {
  background-color: #b4d7ff;
  opacity: 0;
  -webkit-user-select: none;
  user-select: none;
}
.tinymce__oxide--ephox-snooker-resizer-cols {
  cursor: col-resize;
}
.tinymce__oxide--ephox-snooker-resizer-rows {
  cursor: row-resize;
}
.tinymce__oxide--ephox-snooker-resizer-bar.tinymce__oxide--ephox-snooker-resizer-bar-dragging {
  opacity: 1;
}
.tinymce__oxide--mce-spellchecker-word {
  background-image: url("data:image/svg+xml;charset=UTF-8,%3Csvg%20width%3D'4'%20height%3D'4'%20xmlns%3D'http%3A%2F%2Fwww.w3.org%2F2000%2Fsvg'%3E%3Cpath%20stroke%3D'%23ff0000'%20fill%3D'none'%20stroke-linecap%3D'round'%20stroke-opacity%3D'.75'%20d%3D'M0%203L2%201%204%203'%2F%3E%3C%2Fsvg%3E%0A");
  background-position: 0 calc(100% + 1px);
  background-repeat: repeat-x;
  background-size: auto 6px;
  cursor: default;
  height: 2rem;
}
.tinymce__oxide--mce-spellchecker-grammar {
  background-image: url("data:image/svg+xml;charset=UTF-8,%3Csvg%20width%3D'4'%20height%3D'4'%20xmlns%3D'http%3A%2F%2Fwww.w3.org%2F2000%2Fsvg'%3E%3Cpath%20stroke%3D'%2300A835'%20fill%3D'none'%20stroke-linecap%3D'round'%20d%3D'M0%203L2%201%204%203'%2F%3E%3C%2Fsvg%3E%0A");
  background-position: 0 calc(100% + 1px);
  background-repeat: repeat-x;
  background-size: auto 6px;
  cursor: default;
}
.tinymce__oxide--mce-toc {
  border: 1px solid gray;
}
.tinymce__oxide--mce-toc h2 {
  margin: 4px;
}
.tinymce__oxide--mce-toc li {
  list-style-type: none;
}
table[style*="border-width: 0px"],
.tinymce__oxide--mce-item-table:not([border]),
.tinymce__oxide--mce-item-table[border="0"],
table[style*="border-width: 0px"] td,
.tinymce__oxide--mce-item-table:not([border]) td,
.tinymce__oxide--mce-item-table[border="0"] td,
table[style*="border-width: 0px"] th,
.tinymce__oxide--mce-item-table:not([border]) th,
.tinymce__oxide--mce-item-table[border="0"] th,
table[style*="border-width: 0px"] caption,
.tinymce__oxide--mce-item-table:not([border]) caption,
.tinymce__oxide--mce-item-table[border="0"] caption {
  border: 1px dashed #bbb;
}
.tinymce__oxide--mce-visualblocks p,
.tinymce__oxide--mce-visualblocks h1,
.tinymce__oxide--mce-visualblocks h2,
.tinymce__oxide--mce-visualblocks h3,
.tinymce__oxide--mce-visualblocks h4,
.tinymce__oxide--mce-visualblocks h5,
.tinymce__oxide--mce-visualblocks h6,
.tinymce__oxide--mce-visualblocks div:not([data-mce-bogus]),
.tinymce__oxide--mce-visualblocks section,
.tinymce__oxide--mce-visualblocks article,
.tinymce__oxide--mce-visualblocks blockquote,
.tinymce__oxide--mce-visualblocks address,
.tinymce__oxide--mce-visualblocks pre,
.tinymce__oxide--mce-visualblocks figure,
.tinymce__oxide--mce-visualblocks figcaption,
.tinymce__oxide--mce-visualblocks hgroup,
.tinymce__oxide--mce-visualblocks aside,
.tinymce__oxide--mce-visualblocks ul,
.tinymce__oxide--mce-visualblocks ol,
.tinymce__oxide--mce-visualblocks dl {
  background-repeat: no-repeat;
  border: 1px dashed #bbb;
  margin-left: 3px;
  padding-top: 10px;
}
.tinymce__oxide--mce-visualblocks p {
  background-image: url(data:image/gif;base64,R0lGODlhCQAJAJEAAAAAAP///7u7u////yH5BAEAAAMALAAAAAAJAAkAAAIQnG+CqCN/mlyvsRUpThG6AgA7);
}
.tinymce__oxide--mce-visualblocks h1 {
  background-image: url(data:image/gif;base64,R0lGODlhDQAKAIABALu7u////yH5BAEAAAEALAAAAAANAAoAAAIXjI8GybGu1JuxHoAfRNRW3TWXyF2YiRUAOw==);
}
.tinymce__oxide--mce-visualblocks h2 {
  background-image: url(data:image/gif;base64,R0lGODlhDgAKAIABALu7u////yH5BAEAAAEALAAAAAAOAAoAAAIajI8Hybbx4oOuqgTynJd6bGlWg3DkJzoaUAAAOw==);
}
.tinymce__oxide--mce-visualblocks h3 {
  background-image: url(data:image/gif;base64,R0lGODlhDgAKAIABALu7u////yH5BAEAAAEALAAAAAAOAAoAAAIZjI8Hybbx4oOuqgTynJf2Ln2NOHpQpmhAAQA7);
}
.tinymce__oxide--mce-visualblocks h4 {
  background-image: url(data:image/gif;base64,R0lGODlhDgAKAIABALu7u////yH5BAEAAAEALAAAAAAOAAoAAAIajI8HybbxInR0zqeAdhtJlXwV1oCll2HaWgAAOw==);
}
.tinymce__oxide--mce-visualblocks h5 {
  background-image: url(data:image/gif;base64,R0lGODlhDgAKAIABALu7u////yH5BAEAAAEALAAAAAAOAAoAAAIajI8HybbxIoiuwjane4iq5GlW05GgIkIZUAAAOw==);
}
.tinymce__oxide--mce-visualblocks h6 {
  background-image: url(data:image/gif;base64,R0lGODlhDgAKAIABALu7u////yH5BAEAAAEALAAAAAAOAAoAAAIajI8HybbxIoiuwjan04jep1iZ1XRlAo5bVgAAOw==);
}
.tinymce__oxide--mce-visualblocks div:not([data-mce-bogus]) {
  background-image: url(data:image/gif;base64,R0lGODlhEgAKAIABALu7u////yH5BAEAAAEALAAAAAASAAoAAAIfjI9poI0cgDywrhuxfbrzDEbQM2Ei5aRjmoySW4pAAQA7);
}
.tinymce__oxide--mce-visualblocks section {
  background-image: url(data:image/gif;base64,R0lGODlhKAAKAIABALu7u////yH5BAEAAAEALAAAAAAoAAoAAAI5jI+pywcNY3sBWHdNrplytD2ellDeSVbp+GmWqaDqDMepc8t17Y4vBsK5hDyJMcI6KkuYU+jpjLoKADs=);
}
.tinymce__oxide--mce-visualblocks article {
  background-image: url(data:image/gif;base64,R0lGODlhKgAKAIABALu7u////yH5BAEAAAEALAAAAAAqAAoAAAI6jI+pywkNY3wG0GBvrsd2tXGYSGnfiF7ikpXemTpOiJScasYoDJJrjsG9gkCJ0ag6KhmaIe3pjDYBBQA7);
}
.tinymce__oxide--mce-visualblocks blockquote {
  background-image: url(data:image/gif;base64,R0lGODlhPgAKAIABALu7u////yH5BAEAAAEALAAAAAA+AAoAAAJPjI+py+0Knpz0xQDyuUhvfoGgIX5iSKZYgq5uNL5q69asZ8s5rrf0yZmpNkJZzFesBTu8TOlDVAabUyatguVhWduud3EyiUk45xhTTgMBBQA7);
}
.tinymce__oxide--mce-visualblocks address {
  background-image: url(data:image/gif;base64,R0lGODlhLQAKAIABALu7u////yH5BAEAAAEALAAAAAAtAAoAAAI/jI+pywwNozSP1gDyyZcjb3UaRpXkWaXmZW4OqKLhBmLs+K263DkJK7OJeifh7FicKD9A1/IpGdKkyFpNmCkAADs=);
}
.tinymce__oxide--mce-visualblocks pre {
  background-image: url(data:image/gif;base64,R0lGODlhFQAKAIABALu7uwAAACH5BAEAAAEALAAAAAAVAAoAAAIjjI+ZoN0cgDwSmnpz1NCueYERhnibZVKLNnbOq8IvKpJtVQAAOw==);
}
.tinymce__oxide--mce-visualblocks figure {
  background-image: url(data:image/gif;base64,R0lGODlhJAAKAIAAALu7u////yH5BAEAAAEALAAAAAAkAAoAAAI0jI+py+2fwAHUSFvD3RlvG4HIp4nX5JFSpnZUJ6LlrM52OE7uSWosBHScgkSZj7dDKnWAAgA7);
}
.tinymce__oxide--mce-visualblocks figcaption {
  border: 1px dashed #bbb;
}
.tinymce__oxide--mce-visualblocks hgroup {
  background-image: url(data:image/gif;base64,R0lGODlhJwAKAIABALu7uwAAACH5BAEAAAEALAAAAAAnAAoAAAI3jI+pywYNI3uB0gpsRtt5fFnfNZaVSYJil4Wo03Hv6Z62uOCgiXH1kZIIJ8NiIxRrAZNMZAtQAAA7);
}
.tinymce__oxide--mce-visualblocks aside {
  background-image: url(data:image/gif;base64,R0lGODlhHgAKAIABAKqqqv///yH5BAEAAAEALAAAAAAeAAoAAAItjI+pG8APjZOTzgtqy7I3f1yehmQcFY4WKZbqByutmW4aHUd6vfcVbgudgpYCADs=);
}
.tinymce__oxide--mce-visualblocks ul {
  background-image: url(data:image/gif;base64,R0lGODlhDQAKAIAAALu7u////yH5BAEAAAEALAAAAAANAAoAAAIXjI8GybGuYnqUVSjvw26DzzXiqIDlVwAAOw==);
}
.tinymce__oxide--mce-visualblocks ol {
  background-image: url(data:image/gif;base64,R0lGODlhDQAKAIABALu7u////yH5BAEAAAEALAAAAAANAAoAAAIXjI8GybH6HHt0qourxC6CvzXieHyeWQAAOw==);
}
.tinymce__oxide--mce-visualblocks dl {
  background-image: url(data:image/gif;base64,R0lGODlhDQAKAIABALu7u////yH5BAEAAAEALAAAAAANAAoAAAIXjI8GybEOnmOvUoWznTqeuEjNSCqeGRUAOw==);
}
.tinymce__oxide--mce-visualblocks:not([dir=rtl]) p,
.tinymce__oxide--mce-visualblocks:not([dir=rtl]) h1,
.tinymce__oxide--mce-visualblocks:not([dir=rtl]) h2,
.tinymce__oxide--mce-visualblocks:not([dir=rtl]) h3,
.tinymce__oxide--mce-visualblocks:not([dir=rtl]) h4,
.tinymce__oxide--mce-visualblocks:not([dir=rtl]) h5,
.tinymce__oxide--mce-visualblocks:not([dir=rtl]) h6,
.tinymce__oxide--mce-visualblocks:not([dir=rtl]) div:not([data-mce-bogus]),
.tinymce__oxide--mce-visualblocks:not([dir=rtl]) section,
.tinymce__oxide--mce-visualblocks:not([dir=rtl]) article,
.tinymce__oxide--mce-visualblocks:not([dir=rtl]) blockquote,
.tinymce__oxide--mce-visualblocks:not([dir=rtl]) address,
.tinymce__oxide--mce-visualblocks:not([dir=rtl]) pre,
.tinymce__oxide--mce-visualblocks:not([dir=rtl]) figure,
.tinymce__oxide--mce-visualblocks:not([dir=rtl]) figcaption,
.tinymce__oxide--mce-visualblocks:not([dir=rtl]) hgroup,
.tinymce__oxide--mce-visualblocks:not([dir=rtl]) aside,
.tinymce__oxide--mce-visualblocks:not([dir=rtl]) ul,
.tinymce__oxide--mce-visualblocks:not([dir=rtl]) ol,
.tinymce__oxide--mce-visualblocks:not([dir=rtl]) dl {
  margin-left: 3px;
}
.tinymce__oxide--mce-visualblocks[dir=rtl] p,
.tinymce__oxide--mce-visualblocks[dir=rtl] h1,
.tinymce__oxide--mce-visualblocks[dir=rtl] h2,
.tinymce__oxide--mce-visualblocks[dir=rtl] h3,
.tinymce__oxide--mce-visualblocks[dir=rtl] h4,
.tinymce__oxide--mce-visualblocks[dir=rtl] h5,
.tinymce__oxide--mce-visualblocks[dir=rtl] h6,
.tinymce__oxide--mce-visualblocks[dir=rtl] div:not([data-mce-bogus]),
.tinymce__oxide--mce-visualblocks[dir=rtl] section,
.tinymce__oxide--mce-visualblocks[dir=rtl] article,
.tinymce__oxide--mce-visualblocks[dir=rtl] blockquote,
.tinymce__oxide--mce-visualblocks[dir=rtl] address,
.tinymce__oxide--mce-visualblocks[dir=rtl] pre,
.tinymce__oxide--mce-visualblocks[dir=rtl] figure,
.tinymce__oxide--mce-visualblocks[dir=rtl] figcaption,
.tinymce__oxide--mce-visualblocks[dir=rtl] hgroup,
.tinymce__oxide--mce-visualblocks[dir=rtl] aside,
.tinymce__oxide--mce-visualblocks[dir=rtl] ul,
.tinymce__oxide--mce-visualblocks[dir=rtl] ol,
.tinymce__oxide--mce-visualblocks[dir=rtl] dl {
  background-position-x: right;
  margin-right: 3px;
}
.tinymce__oxide--mce-nbsp,
.tinymce__oxide--mce-shy {
  background: #aaa;
}
.tinymce__oxide--mce-shy::after {
  content: '-';
}
body {
  font-family: sans-serif;
}
table {
  border-collapse: collapse;
}
`;
  },
  'mce-content-body': 'tinymce__oxide--mce-content-body',
  'mce-item-anchor': 'tinymce__oxide--mce-item-anchor',
  'tox-comments-visible': 'tinymce__oxide--tox-comments-visible',
  'tox-comment': 'tinymce__oxide--tox-comment',
  'tox-comment--active': 'tinymce__oxide--tox-comment--active',
  'tox-checklist': 'tinymce__oxide--tox-checklist',
  'tox-checklist--hidden': 'tinymce__oxide--tox-checklist--hidden',
  'tox-checklist--checked': 'tinymce__oxide--tox-checklist--checked',
  'token': 'tinymce__oxide--token',
  'comment': 'tinymce__oxide--comment',
  'prolog': 'tinymce__oxide--prolog',
  'doctype': 'tinymce__oxide--doctype',
  'cdata': 'tinymce__oxide--cdata',
  'punctuation': 'tinymce__oxide--punctuation',
  'namespace': 'tinymce__oxide--namespace',
  'property': 'tinymce__oxide--property',
  'tag': 'tinymce__oxide--tag',
  'boolean': 'tinymce__oxide--boolean',
  'number': 'tinymce__oxide--number',
  'constant': 'tinymce__oxide--constant',
  'symbol': 'tinymce__oxide--symbol',
  'deleted': 'tinymce__oxide--deleted',
  'selector': 'tinymce__oxide--selector',
  'attr-name': 'tinymce__oxide--attr-name',
  'string': 'tinymce__oxide--string',
  'char': 'tinymce__oxide--char',
  'builtin': 'tinymce__oxide--builtin',
  'inserted': 'tinymce__oxide--inserted',
  'operator': 'tinymce__oxide--operator',
  'entity': 'tinymce__oxide--entity',
  'url': 'tinymce__oxide--url',
  'language-css': 'tinymce__oxide--language-css',
  'style': 'tinymce__oxide--style',
  'atrule': 'tinymce__oxide--atrule',
  'attr-value': 'tinymce__oxide--attr-value',
  'keyword': 'tinymce__oxide--keyword',
  'function': 'tinymce__oxide--function',
  'class-name': 'tinymce__oxide--class-name',
  'regex': 'tinymce__oxide--regex',
  'important': 'tinymce__oxide--important',
  'variable': 'tinymce__oxide--variable',
  'bold': 'tinymce__oxide--bold',
  'italic': 'tinymce__oxide--italic',
  'mce-visual-caret': 'tinymce__oxide--mce-visual-caret',
  'mce-visual-caret-hidden': 'tinymce__oxide--mce-visual-caret-hidden',
  'mce-offscreen-selection': 'tinymce__oxide--mce-offscreen-selection',
  'tox-cursor-format-painter': 'tinymce__oxide--tox-cursor-format-painter',
  'align-left': 'tinymce__oxide--align-left',
  'align-right': 'tinymce__oxide--align-right',
  'image': 'tinymce__oxide--image',
  'align-center': 'tinymce__oxide--align-center',
  'mce-preview-object': 'tinymce__oxide--mce-preview-object',
  'mce-shim': 'tinymce__oxide--mce-shim',
  'mce-object': 'tinymce__oxide--mce-object',
  'mce-pagebreak': 'tinymce__oxide--mce-pagebreak',
  'tiny-pageembed': 'tinymce__oxide--tiny-pageembed',
  'tiny-pageembed--21by9': 'tinymce__oxide--tiny-pageembed--21by9',
  'tiny-pageembed--16by9': 'tinymce__oxide--tiny-pageembed--16by9',
  'tiny-pageembed--4by3': 'tinymce__oxide--tiny-pageembed--4by3',
  'tiny-pageembed--1by1': 'tinymce__oxide--tiny-pageembed--1by1',
  'mce-visualblocks': 'tinymce__oxide--mce-visualblocks',
  'mce-resizehandle': 'tinymce__oxide--mce-resizehandle',
  'mce-resize-backdrop': 'tinymce__oxide--mce-resize-backdrop',
  'mce-clonedresizable': 'tinymce__oxide--mce-clonedresizable',
  'mce-resizetable-columns': 'tinymce__oxide--mce-resizetable-columns',
  'mce-resize-helper': 'tinymce__oxide--mce-resize-helper',
  'tox-rtc-user-selection': 'tinymce__oxide--tox-rtc-user-selection',
  'tox-rtc-user-cursor': 'tinymce__oxide--tox-rtc-user-cursor',
  'tox-rtc-user-selection--1': 'tinymce__oxide--tox-rtc-user-selection--1',
  'tox-rtc-user-selection--2': 'tinymce__oxide--tox-rtc-user-selection--2',
  'tox-rtc-user-selection--3': 'tinymce__oxide--tox-rtc-user-selection--3',
  'tox-rtc-user-selection--4': 'tinymce__oxide--tox-rtc-user-selection--4',
  'tox-rtc-user-selection--5': 'tinymce__oxide--tox-rtc-user-selection--5',
  'tox-rtc-user-selection--6': 'tinymce__oxide--tox-rtc-user-selection--6',
  'tox-rtc-user-selection--7': 'tinymce__oxide--tox-rtc-user-selection--7',
  'tox-rtc-user-selection--8': 'tinymce__oxide--tox-rtc-user-selection--8',
  'tox-rtc-remote-image': 'tinymce__oxide--tox-rtc-remote-image',
  'mce-match-marker': 'tinymce__oxide--mce-match-marker',
  'mce-match-marker-selected': 'tinymce__oxide--mce-match-marker-selected',
  'mce-content-readonly': 'tinymce__oxide--mce-content-readonly',
  'mce-edit-focus': 'tinymce__oxide--mce-edit-focus',
  'ephox-snooker-resizer-bar': 'tinymce__oxide--ephox-snooker-resizer-bar',
  'ephox-snooker-resizer-cols': 'tinymce__oxide--ephox-snooker-resizer-cols',
  'ephox-snooker-resizer-rows': 'tinymce__oxide--ephox-snooker-resizer-rows',
  'ephox-snooker-resizer-bar-dragging': 'tinymce__oxide--ephox-snooker-resizer-bar-dragging',
  'mce-spellchecker-word': 'tinymce__oxide--mce-spellchecker-word',
  'mce-spellchecker-grammar': 'tinymce__oxide--mce-spellchecker-grammar',
  'mce-toc': 'tinymce__oxide--mce-toc',
  'mce-item-table': 'tinymce__oxide--mce-item-table',
  'mce-nbsp': 'tinymce__oxide--mce-nbsp',
  'mce-shy': 'tinymce__oxide--mce-shy'
}.template().replace(/tinymce__oxide--/g, ''); // If we ever get our jest tests configured so they can handle importing real esModules,
// we can move this to plugins/instructure-ui-icons/plugin.js like the rest.

function addKebabIcon(editor) {
  editor.ui.registry.addIcon('more-drawer', `
    <svg viewBox="0 0 1920 1920">
      <path d="M1129.412 1637.647c0 93.448-75.964 169.412-169.412 169.412-93.448 0-169.412-75.964-169.412-169.412 0-93.447 75.964-169.412 169.412-169.412 93.448 0 169.412 75.965 169.412 169.412zm0-677.647c0 93.448-75.964 169.412-169.412 169.412-93.448 0-169.412-75.964-169.412-169.412 0-93.448 75.964-169.412 169.412-169.412 93.448 0 169.412 75.964 169.412 169.412zm0-677.647c0 93.447-75.964 169.412-169.412 169.412-93.448 0-169.412-75.965-169.412-169.412 0-93.448 75.964-169.412 169.412-169.412 93.448 0 169.412 75.964 169.412 169.412z" stroke="none" stroke-width="1" fill-rule="evenodd"/>
    </svg>
  `);
} // Get oxide the default skin injected into the DOM before the overrides loaded by themeable


let inserted = false;

function injectTinySkin() {
  if (inserted) return;
  inserted = true;
  const style = document.createElement('style');
  style.setAttribute('data-skin', 'tiny oxide skin');
  style.appendChild( // the .replace here is because the ui-themeable babel hook adds that prefix to all the class names
  document.createTextNode(skinCSS));
  const beforeMe = document.head.querySelector('style[data-glamor]') || // find instui's themeable stylesheet
  document.head.querySelector('style') || // find any stylesheet
  document.head.firstElementChild;
  document.head.insertBefore(style, beforeMe);
}

const editorWrappers = new WeakMap();

function focusToolbar(el) {
  const $firstToolbarButton = el.querySelector('.tox-tbtn');
  $firstToolbarButton && $firstToolbarButton.focus();
}

function focusFirstMenuButton(el) {
  const $firstMenu = el.querySelector('.tox-mbtn');
  $firstMenu && $firstMenu.focus();
}

function isElementWithinTable(node) {
  let elem = node;

  while (elem) {
    if (elem.tagName === 'TABLE' || elem.tagName === 'TD' || elem.tagName === 'TH') {
      return true;
    }

    elem = elem.parentElement;
  }

  return false;
} // determines if localStorage is available for our use.
// see https://developer.mozilla.org/en-US/docs/Web/API/Web_Storage_API/Using_the_Web_Storage_API


export function storageAvailable() {
  let storage;

  try {
    storage = window.localStorage;
    storage.setItem("__storage_test__", "__storage_test__");
    storage.removeItem("__storage_test__");
    return true;
  } catch (e) {
    return e instanceof DOMException && (e.code === 22 || // Firefox
    e.code === 1014 || // test name field too, because code might not be present
    // everything except Firefox
    e.name === 'QuotaExceededError' || // Firefox
    e.name === 'NS_ERROR_DOM_QUOTA_REACHED') && // acknowledge QuotaExceededError only if there's something already stored
    storage && storage.length !== 0;
  }
}

function getHtmlEditorCookie() {
  const value = getCookie('rce.htmleditor');
  return value === RAW_HTML_EDITOR_VIEW || value === PRETTY_HTML_EDITOR_VIEW ? value : PRETTY_HTML_EDITOR_VIEW;
}

function renderLoading() {
  return formatMessage('Loading');
} // safari implements only the webkit prefixed version of the fullscreen api


const FS_ELEMENT = document.fullscreenElement === void 0 ? 'webkitFullscreenElement' : 'fullscreenElement';
const FS_REQUEST = document.body.requestFullscreen ? 'requestFullscreen' : 'webkitRequestFullscreen';
const FS_EXIT = document.exitFullscreen ? 'exitFullscreen' : 'webkitExitFullscreen';
let alertIdValue = 0;
let RCEWrapper = (_dec = themeable(theme, styles), _dec(_class = (_temp = _class2 = class RCEWrapper extends React.Component {
  static getByEditor(editor) {
    return editorWrappers.get(editor);
  }

  constructor(props) {
    var _props$editorOptions;

    super(props);

    this.onRemove = () => {
      bridge.detachEditor(this);
      this.props.onRemove && this.props.onRemove(this);
    };

    this.toggleView = newView => {
      // coming from the menubar, we don't have a newView,
      const wasFullscreen = this._isFullscreen();

      if (wasFullscreen) this._exitFullscreen();
      let newState;

      switch (this.state.editorView) {
        case WYSIWYG_VIEW:
          newState = {
            editorView: newView || PRETTY_HTML_EDITOR_VIEW
          };
          break;

        case PRETTY_HTML_EDITOR_VIEW:
          newState = {
            editorView: newView || WYSIWYG_VIEW
          };
          break;

        case RAW_HTML_EDITOR_VIEW:
          newState = {
            editorView: newView || WYSIWYG_VIEW
          };
      }

      this.setState(newState, () => {
        if (wasFullscreen) {
          window.setTimeout(() => {
            this._enterFullscreen();
          }, 200); // due to the animation it takes some time for fullscreen to complete
        }
      });
      this.checkAccessibility();

      if (newView === PRETTY_HTML_EDITOR_VIEW || newView === RAW_HTML_EDITOR_VIEW) {
        document.cookie = `rce.htmleditor=${newView};path=/;max-age=31536000`;
      } // Emit view change event


      this.mceInstance().fire(VIEW_CHANGE, {
        target: this.editor,
        newView: newState.editorView
      });
    };

    this.contentTrayClosing = false;
    this.blurTimer = 0;

    this.handleFocusRCE = event => {
      this.handleFocus(event);
    };

    this.handleBlurRCE = event => {
      var _this$_elementRef$cur;

      if (event.relatedTarget === null) {
        // focus might be moving to tinymce
        this.handleBlur(event);
      }

      if (!((_this$_elementRef$cur = this._elementRef.current) !== null && _this$_elementRef$cur !== void 0 && _this$_elementRef$cur.contains(event.relatedTarget))) {
        this.handleBlur(event);
      }
    };

    this.handleFocusEditor = event => {
      // use .active to put a focus ring around the content area
      // when the editor has focus. This isn't perfect, but it's
      // what we've got for now.
      const ifr = this.iframe;
      ifr && ifr.parentElement.classList.add('active');

      this._forceCloseFloatingToolbar();

      this.handleFocus(event);
    };

    this.handleFocusHtmlEditor = event => {
      this.handleFocus(event);
    };

    this.handleBlurEditor = event => {
      const ifr = this.iframe;
      ifr && ifr.parentElement.classList.remove('active');
      this.handleBlur(event);
    };

    this.handleKey = event => {
      if (event.code === 'F9' && event.altKey) {
        event.preventDefault();
        event.stopPropagation();
        focusFirstMenuButton(this._elementRef.current);
      } else if (event.code === 'F10' && event.altKey) {
        event.preventDefault();
        event.stopPropagation();
        focusToolbar(this._elementRef.current);
      } else if ((event.code === 'F8' || event.code === 'Digit0') && event.altKey) {
        event.preventDefault();
        event.stopPropagation();
        this.openKBShortcutModal();
      } else if (event.code === 'Escape') {
        this._forceCloseFloatingToolbar();

        if (this.state.fullscreenState.isTinyFullscreen) {
          this.mceInstance().execCommand('mceFullScreen'); // turn it off
        } else {
          bridge.hideTrays();
        }
      } else if (['n', 'N', 'd', 'D'].indexOf(event.key) !== -1) {
        // Prevent key events from bubbling up on touch screen device
        event.stopPropagation();
      }
    };

    this.handleClickFullscreen = () => {
      if (this._isFullscreen()) {
        this._exitFullscreen();
      } else {
        this._enterFullscreen();
      }
    };

    this.handleExternalClick = () => {
      this._forceCloseFloatingToolbar();

      debounce(this.checkAccessibility, 1000)();
    };

    this.handleInputChange = () => {
      this.checkAccessibility();
    };

    this.onInit = (_event, editor) => {
      var _this$props$onInitted, _this$props;

      editor.rceWrapper = this;
      this.editor = editor;
      const textarea = this.editor.getElement(); // expected by canvas

      textarea.dataset.rich_text = true; // start with the textarea and tinymce in sync

      textarea.value = this.getCode();
      textarea.style.height = this.state.height; // Capture click events outside the iframe

      document.addEventListener('click', this.handleExternalClick);

      if (document.body.classList.contains('Underline-All-Links__enabled')) {
        this.iframe.contentDocument.body.classList.add('Underline-All-Links__enabled');
      }

      editor.on('wordCountUpdate', this.onWordCountUpdate); // add an aria-label to the application div that wraps RCE
      // and change role from "application" to "document" to ensure
      // the editor gets properly picked up by screen readers

      const tinyapp = document.querySelector('.tox-tinymce[role="application"]');

      if (tinyapp) {
        tinyapp.setAttribute('aria-label', formatMessage('Rich Content Editor'));
        tinyapp.setAttribute('role', 'document');
        tinyapp.setAttribute('tabIndex', '-1');
      } // Probably should do this in tinymce.scss, but we only want it in new rce


      textarea.style.resize = 'none';
      editor.on('ExecCommand', this._forceCloseFloatingToolbar);
      editor.on('keydown', this.handleKey);
      editor.on('FullscreenStateChanged', this._toggleFullscreen); // This propagates click events on the editor out of the iframe to the parent
      // document. We need this so that click events get captured properly by instui
      // focus-trapping components, so they properly ignore trapping focus on click.

      editor.on('click', () => window.top.document.body.click(), true);

      if (this.props.use_rce_a11y_checker_notifications) {
        editor.on('Cut Paste Change input Undo Redo', debounce(this.handleInputChange, 1000));
      }

      this.announceContextToolbars(editor);

      if (this.isAutoSaving) {
        this.initAutoSave(editor);
      } // first view


      this.setEditorView(this.state.editorView); // readonly should have been handled via the init property passed
      // to <Editor>, but it's not.

      editor.mode.set(this.props.readOnly ? 'readonly' : 'design');
      (_this$props$onInitted = (_this$props = this.props).onInitted) === null || _this$props$onInitted === void 0 ? void 0 : _this$props$onInitted.call(_this$props, editor);
    };

    this._toggleFullscreen = event => {
      const header = document.getElementById('header');

      if (header) {
        if (event.state) {
          this.setState({
            fullscreenState: {
              headerDisp: header.style.display,
              isTinyFullscreen: true
            }
          });
          header.style.display = 'none';
        } else {
          header.style.display = this.state.fullscreenState.headerDisp;
          this.setState({
            fullscreenState: {
              isTinyFullscreen: false
            }
          });
        }
      } // if we're leaving fullscreen, remove event listeners on the fullscreen element


      if (!document[FS_ELEMENT] && this.state.fullscreenElem) {
        this.state.fullscreenElem.removeEventListener('fullscreenchange', this._toggleFullscreen);
        this.state.fullscreenElem.removeEventListener('webkitfullscreenchange', this._toggleFullscreen);
        this.setState({
          fullscreenState: {
            fullscreenElem: null
          }
        });
      } // if we don't defer setState, the pretty editor's height isn't correct
      // when entering fullscreen


      window.setTimeout(() => {
        if (document[FS_ELEMENT]) {
          this.setState(state => {
            return {
              fullscreenState: _objectSpread(_objectSpread({}, state.fullscreenState), {}, {
                fullscreenElem: document[FS_ELEMENT]
              })
            };
          });
        } else {
          this.forceUpdate();
        }

        this.focusCurrentView();
      }, 0);
    };

    this._forceCloseFloatingToolbar = () => {
      if (this._elementRef.current) {
        const moreButton = this._elementRef.current.querySelector('.tox-toolbar-overlord .tox-toolbar__group:last-child button:last-child');

        if (moreButton !== null && moreButton !== void 0 && moreButton.getAttribute('aria-owns')) {
          // the floating toolbar is open
          moreButton.click(); // close the floating toolbar

          const editor = this.mceInstance(); // return focus to the editor

          editor === null || editor === void 0 ? void 0 : editor.focus();
        }
      }
    };

    this.announcing = 0;

    this.initAutoSave = editor => {
      this.storage = window.localStorage;

      if (this.storage) {
        editor.on('change Undo Redo', this.doAutoSave);
        editor.on('blur', this.doAutoSave);
        this.cleanupAutoSave();

        try {
          const autosaved = this.getAutoSaved(this.autoSaveKey);

          if (autosaved && autosaved.content) {
            // We'll compare just the text of the autosave content, since
            // Canvas is prone to swizzling images and iframes which will
            // make the editor content and autosave content never match up
            const editorContent = this.patchAutosavedContent(editor.getContent({
              no_events: true
            }), true);
            const autosavedContent = this.patchAutosavedContent(autosaved.content, true);

            if (autosavedContent !== editorContent) {
              this.setState({
                confirmAutoSave: true,
                autoSavedContent: this.patchAutosavedContent(autosaved.content)
              });
            } else {
              this.storage.removeItem(this.autoSaveKey);
            }
          }
        } catch (ex) {
          // log and ignore
          // eslint-disable-next-line no-console
          console.error('Failed initializing rce autosave', ex);
        }
      }
    };

    this.cleanupAutoSave = (deleteAll = false) => {
      if (this.storage) {
        const expiry = deleteAll ? Date.now() : Date.now() - this.props.autosave.maxAge;
        let i = 0;
        let key;

        while (key = this.storage.key(i++)) {
          if (/^rceautosave:/.test(key)) {
            const autosaved = this.getAutoSaved(key);

            if (autosaved && autosaved.autosaveTimestamp < expiry) {
              this.storage.removeItem(key);
            }
          }
        }
      }
    };

    this.restoreAutoSave = ans => {
      this.setState({
        confirmAutoSave: false
      }, () => {
        const editor = this.mceInstance();

        if (ans) {
          editor.setContent(this.state.autoSavedContent, {});
        }

        this.storage.removeItem(this.autoSaveKey);
      });
      this.checkAccessibility();
    };

    this.doAutoSave = (e, retry = false) => {
      if (this.storage) {
        const editor = this.mceInstance(); // if the editor is empty don't save

        if (editor.dom.isEmpty(editor.getBody())) {
          return;
        }

        const content = editor.getContent({
          no_events: true
        });

        try {
          this.storage.setItem(this.autoSaveKey, JSON.stringify({
            autosaveTimestamp: Date.now(),
            content
          }));
        } catch (ex) {
          if (!retry) {
            // probably failed because there's not enough space
            // delete up all the other entries and try again
            this.cleanupAutoSave(true);
            this.doAutoSave(e, true);
          } else {
            console.error('Autosave failed:', ex); // eslint-disable-line no-console
          }
        }
      }
    };

    this.onWordCountUpdate = e => {
      this.setState(state => {
        if (e.wordCount.words !== state.wordCount) {
          return {
            wordCount: e.wordCount.words
          };
        } else return null;
      });
    };

    this.onNodeChange = e => {
      // This is basically copied out of the tinymce silver theme code for the status bar
      const path = e.parents.filter(p => p.nodeName !== 'BR' && !p.getAttribute('data-mce-bogus') && p.getAttribute('data-mce-type') !== 'bookmark').map(p => p.nodeName.toLowerCase()).reverse();
      this.setState({
        path
      });
    };

    this.onEditorChange = content => {
      var _this$props$onContent, _this$props2;

      (_this$props$onContent = (_this$props2 = this.props).onContentChange) === null || _this$props$onContent === void 0 ? void 0 : _this$props$onContent.call(_this$props2, content);
    };

    this.onResize = (_e, coordinates) => {
      const editor = this.mceInstance();

      if (editor) {
        const container = editor.getContainer();
        if (!container) return;
        const currentContainerHeight = Number.parseInt(container.style.height, 10);
        if (isNaN(currentContainerHeight)) return; // eslint-disable-line no-restricted-globals

        const modifiedHeight = currentContainerHeight + coordinates.deltaY;
        const newHeight = `${modifiedHeight}px`;
        container.style.height = newHeight;
        this.getTextarea().style.height = newHeight;
        this.setState({
          height: newHeight
        }); // play nice and send the same event that the silver theme would send

        editor.fire('ResizeEditor');
      }
    };

    this.onA11yChecker = () => {
      // eslint-disable-next-line promise/catch-or-return
      this.a11yCheckerReady.then(() => {
        this.onTinyMCEInstance('openAccessibilityChecker', {
          skip_focus: true
        });
      });
    };

    this.checkAccessibility = () => {
      if (!this.props.use_rce_a11y_checker_notifications) {
        return;
      }

      const editor = this.mceInstance();
      editor.execCommand('checkAccessibility', false, {
        done: errors => {
          this.setState({
            a11yErrorsCount: errors.length
          });
        }
      }, {
        skip_focus: true
      });
    };

    this.openKBShortcutModal = () => {
      this.setState({
        KBShortcutModalOpen: true,
        KBShortcutFocusReturn: document.activeElement
      });
    };

    this.closeKBShortcutModal = () => {
      this.setState({
        KBShortcutModalOpen: false
      });
    };

    this.KBShortcutModalExited = () => {
      if (this.state.KBShortcutFocusReturn === this.iframe) {
        // if the iframe has focus, we need to forward it on to tinymce
        this.editor.focus(false);
      } else if (this._showOnFocusButton && document.activeElement === document.body) {
        // when the modal is opened from the showOnFocus button, focus doesn't
        // get automatically returned to the button like it should.
        this._showOnFocusButton.focus();
      } else {
        var _this$_showOnFocusBut;

        (_this$_showOnFocusBut = this._showOnFocusButton) === null || _this$_showOnFocusBut === void 0 ? void 0 : _this$_showOnFocusBut.focus();
      }
    };

    this.handleTextareaChange = () => {
      if (this.isHidden()) {
        this.setCode(this.textareaValue());
        this.doAutoSave();
      }
    };

    this.addAlert = alert => {
      alert.id = alertIdValue++;
      this.setState(state => {
        let messages = state.messages.concat(alert);
        messages = _.uniqBy(messages, 'text'); // Don't show the same message twice

        return {
          messages
        };
      });
    };

    this.removeAlert = messageId => {
      this.setState(state => {
        const messages = state.messages.filter(message => message.id !== messageId);
        return {
          messages
        };
      });
    };

    this.resetAlertId = () => {
      if (this.state.messages.length > 0) {
        throw new Error('There are messages currently, you cannot reset when they are non-zero');
      }

      alertIdValue = 0;
    };

    this.editor = null; // my tinymce editor instance

    this.language = normalizeLocale(this.props.language); // interface consistent with editorBox

    this.get_code = this.getCode;
    this.set_code = this.setCode;
    this.insert_code = this.insertCode; // test override points

    this.indicator = false;
    this._elementRef = /*#__PURE__*/React.createRef();
    this._editorPlaceholderRef = /*#__PURE__*/React.createRef();
    this._prettyHtmlEditorRef = /*#__PURE__*/React.createRef();
    this._showOnFocusButton = null;
    injectTinySkin();
    let ht = ((_props$editorOptions = props.editorOptions) === null || _props$editorOptions === void 0 ? void 0 : _props$editorOptions.height) || DEFAULT_RCE_HEIGHT;

    if (!Number.isNaN(ht)) {
      ht = `${ht}px`;
    }

    const currentRCECount = document.querySelectorAll('.rce-wrapper').length;
    const maxInitRenderedRCEs = Number.isNaN(props.maxInitRenderedRCEs) ? RCEWrapper.defaultProps.maxInitRenderedRCEs : props.maxInitRenderedRCEs;
    this.state = {
      path: [],
      wordCount: 0,
      editorView: props.editorView || WYSIWYG_VIEW,
      shouldShowOnFocusButton: props.renderKBShortcutModal === void 0 ? true : props.renderKBShortcutModal,
      KBShortcutModalOpen: false,
      messages: [],
      announcement: null,
      confirmAutoSave: false,
      autoSavedContent: '',
      id: this.props.id || this.props.textareaId || `${Date.now()}`,
      height: ht,
      fullscreenState: {
        headerDisp: 'static',
        isTinyFullscreen: false
      },
      a11yErrorsCount: 0,
      shouldShowEditor: typeof IntersectionObserver === 'undefined' || maxInitRenderedRCEs <= 0 || currentRCECount < maxInitRenderedRCEs
    };
    this.pendingEventHandlers = []; // Get top 2 favorited LTI Tools

    this.ltiToolFavorites = this.props.ltiTools.filter(e => e.favorite).map(e => `instructure_external_button_${e.id}`).slice(0, 2) || [];
    this.tinymceInitOptions = this.wrapOptions(props.editorOptions);
    alertHandler.alertFunc = this.addAlert;
    this.handleContentTrayClosing = this.handleContentTrayClosing.bind(this);
    this.a11yCheckerReady = import('./initA11yChecker').then(initA11yChecker => {
      initA11yChecker.default(this.language);
      this.checkAccessibility();
    }).catch(err => {
      // eslint-disable-next-line no-console
      console.error('Failed initializing a11y checker', err);
    });
  } // getCode and setCode naming comes from tinyMCE
  // kind of strange but want to be consistent


  getCode() {
    return this.isHidden() ? this.textareaValue() : this.mceInstance().getContent();
  }

  checkReadyToGetCode(promptFunc) {
    let status = true; // Check for remaining placeholders

    if (this.mceInstance().dom.doc.querySelector(`[data-placeholder-for]`)) {
      status = promptFunc(formatMessage('Content is still being uploaded, if you continue it will not be embedded properly.'));
    }

    return status;
  }

  setCode(newContent) {
    var _this$mceInstance;

    (_this$mceInstance = this.mceInstance()) === null || _this$mceInstance === void 0 ? void 0 : _this$mceInstance.setContent(newContent);
  } // This function is called imperatively by the page that renders the RCE.
  // It should be called when the RCE content is done being edited.


  RCEClosed() {
    // We want to clear the autosaved content, since the page was legitimately closed.
    if (this.storage) {
      this.storage.removeItem(this.autoSaveKey);
    }
  }

  indicateEditor(element) {
    if (document.querySelector('[role="dialog"][data-mce-component]')) {
      // there is a modal open, which zeros out the vertical scroll
      // so the indicator is in the wrong place.  Give it a chance to close
      window.setTimeout(() => {
        this.indicateEditor(element);
      }, 100);
      return;
    }

    const editor = this.mceInstance();

    if (this.indicator) {
      this.indicator(editor, element);
    } else if (!this.isHidden()) {
      indicate(indicatorRegion(editor, element));
    }
  }

  contentInserted(element) {
    this.indicateEditor(element);
    this.checkImageLoadError(element);
    this.sizeEditorForContent(element);
  } // make a attempt at sizing the editor so that the new content fits.
  // works under the assumptions the body's box-sizing is not content-box
  // and that the content is w/in a <p> whose margin is 12px top and bottom
  // (which, in canvas, is set in app/stylesheets/components/_ic-typography.scss)


  sizeEditorForContent(elem) {
    let height;

    if (elem && elem.nodeType === 1) {
      height = elem.clientHeight;
    }

    if (height) {
      const ifr = this.iframe;

      if (ifr) {
        const editor_body_style = ifr.contentWindow.getComputedStyle(this.iframe.contentDocument.body);
        const editor_ht = ifr.contentDocument.body.clientHeight - parseInt(editor_body_style['padding-top'], 10) - parseInt(editor_body_style['padding-bottom'], 10);
        const reserve_ht = Math.ceil(height + 24);

        if (reserve_ht > editor_ht) {
          this.onResize(null, {
            deltaY: reserve_ht - editor_ht
          });
        }
      }
    }
  }

  checkImageLoadError(element) {
    if (!element || element.tagName !== 'IMG') {
      return;
    }

    if (!element.complete) {
      element.onload = () => this.checkImageLoadError(element);

      return;
    } // checking naturalWidth in a future event loop run prevents a race
    // condition between the onload callback and naturalWidth being set.


    setTimeout(() => {
      if (element.naturalWidth === 0) {
        element.style.border = '1px solid #000';
        element.style.padding = '2px';
      }
    }, 0);
  }

  insertCode(code) {
    const editor = this.mceInstance();
    const element = contentInsertion.insertContent(editor, code);
    this.contentInserted(element);
  }

  insertEmbedCode(code) {
    const editor = this.mceInstance(); // don't replace selected text, but embed after

    editor.selection.collapse(); // tinymce treats iframes uniquely, and doesn't like adding attributes
    // once it's in the editor, and I'd rather not parse the incomming html
    // string with a regex, so let's create a temp copy, then add a title
    // attribute if one doesn't exist. This will let screenreaders announce
    // that there's some embedded content helper
    // From what I've read, "title" is more reliable than "aria-label" for
    // elements like iframes and embeds.

    const temp = document.createElement('div');
    temp.innerHTML = code;
    const code_elem = temp.firstElementChild;

    if (code_elem) {
      if (!code_elem.hasAttribute('title') && !code_elem.hasAttribute('aria-label')) {
        code_elem.setAttribute('title', formatMessage('embedded content'));
      }

      code = code_elem.outerHTML;
    } // inserting an iframe in tinymce (as is often the case with
    // embedded content) causes it to wrap it in a span
    // and it's often inserted into a <p> on top of that.  Find the
    // iframe and use it to flash the indicator.


    const element = contentInsertion.insertContent(editor, code);
    const ifr = element && element.querySelector && element.querySelector('iframe');

    if (ifr) {
      this.contentInserted(ifr);
    } else {
      this.contentInserted(element);
    }
  }

  insertImage(image) {
    var _element$nextSibling, _element$nextSibling$;

    const editor = this.mceInstance();
    let element = contentInsertion.insertImage(editor, image); // Removes TinyMCE's caret &nbsp; text if exists.

    if ((element === null || element === void 0 ? void 0 : (_element$nextSibling = element.nextSibling) === null || _element$nextSibling === void 0 ? void 0 : (_element$nextSibling$ = _element$nextSibling.data) === null || _element$nextSibling$ === void 0 ? void 0 : _element$nextSibling$.trim()) === '') {
      element.nextSibling.remove();
    }

    if (element && element.complete) {
      this.contentInserted(element);
    } else if (element) {
      element.onload = () => this.contentInserted(element);

      element.onerror = () => this.checkImageLoadError(element);
    }
  }

  insertImagePlaceholder(fileMetaProps) {
    let width, height;
    let align = 'middle';

    if (isImage(fileMetaProps.contentType) && fileMetaProps.displayAs !== 'link') {
      const image = new Image();
      image.src = fileMetaProps.domObject.preview;
      width = image.width;
      height = image.height; // we constrain the <img> to max-width: 100%, so scale the size down if necessary

      const maxWidth = this.iframe.contentDocument.body.clientWidth;

      if (width > maxWidth) {
        height = Math.round(maxWidth / width * height);
        width = maxWidth;
      }

      width = `${width}px`;
      height = `${height}px`;
    } else if (isVideo(fileMetaProps.contentType || fileMetaProps.type)) {
      width = VIDEO_SIZE_DEFAULT.width;
      height = VIDEO_SIZE_DEFAULT.height;
      align = 'bottom';
    } else if (isAudio(fileMetaProps.contentType || fileMetaProps.type)) {
      width = AUDIO_PLAYER_SIZE.width;
      height = AUDIO_PLAYER_SIZE.height;
      align = 'bottom';
    } else {
      width = `${fileMetaProps.name.length}rem`;
      height = '1rem';
    } // if you're wondering, the &nbsp; scatter about in the svg
    // is because tinymce will strip empty elements


    const markup = `
    <span
      aria-label="${formatMessage('Loading')}"
      data-placeholder-for="${encodeURIComponent(fileMetaProps.name)}"
      style="width: ${width}; height: ${height}; vertical-align: ${align};"
    >
      <svg xmlns="http://www.w3.org/2000/svg" version="1.1" x="0px" y="0px" viewBox="0 0 100 100" height="100px" width="100px">
        <g style="stroke-width:.5rem;fill:none;stroke-linecap:round;">&nbsp;
          <circle class="c1" cx="50%" cy="50%" r="28px">&nbsp;</circle>
          <circle class="c2" cx="50%" cy="50%" r="28px">&nbsp;</circle>
          &nbsp;
        </g>
        &nbsp;
      </svg>
    </span>`;
    const editor = this.mceInstance();
    editor.undoManager.ignore(() => {
      editor.execCommand('mceInsertContent', false, markup);
    });
  }

  insertVideo(video) {
    const editor = this.mceInstance();
    const element = contentInsertion.insertVideo(editor, video);
    this.contentInserted(element);
  }

  insertAudio(audio) {
    const editor = this.mceInstance();
    const element = contentInsertion.insertAudio(editor, audio);
    this.contentInserted(element);
  }

  insertMathEquation(tex) {
    const ed = this.mceInstance();
    const docSz = parseFloat(ed.dom.doc.defaultView.getComputedStyle(ed.dom.doc.body).getPropertyValue('font-size')) || 1;
    const sel = ed.selection.getNode();
    const imgSz = sel ? parseFloat(ed.dom.doc.defaultView.getComputedStyle(sel).getPropertyValue('font-size')) || 1 : docSz;
    const url = `/equation_images/${encodeURIComponent(encodeURIComponent(tex))}?scale=${imgSz / docSz}`; // if I simply create the html string, xsslint fails jenkins

    const img = document.createElement('img');
    img.setAttribute('alt', `LaTeX: ${tex}`);
    img.setAttribute('title', tex);
    img.setAttribute('class', 'equation_image');
    img.setAttribute('data-equation-content', tex);
    img.setAttribute('src', url);
    this.insertCode(img.outerHTML);
  }

  removePlaceholders(name) {
    const placeholder = this.mceInstance().dom.doc.querySelector(`[data-placeholder-for="${encodeURIComponent(name)}"]`);

    if (placeholder) {
      const editor = this.mceInstance();
      editor.undoManager.ignore(() => {
        editor.dom.remove(placeholder);
      });
    }
  }

  insertLink(link) {
    const editor = this.mceInstance();
    const element = contentInsertion.insertLink(editor, link);
    this.contentInserted(element);
  }

  existingContentToLink() {
    const editor = this.mceInstance();
    return contentInsertion.existingContentToLink(editor);
  }

  existingContentToLinkIsImg() {
    const editor = this.mceInstance();
    return contentInsertion.existingContentToLinkIsImg(editor);
  } // since we may defer rendering tinymce, queue up any tinymce event handlers


  tinymceOn(tinymceEventName, handler) {
    if (this.state.shouldShowEditor) {
      this.mceInstance().on(tinymceEventName, handler);
    } else {
      this.pendingEventHandlers.push({
        name: tinymceEventName,
        handler
      });
    }
  }

  mceInstance() {
    if (this.editor) {
      return this.editor;
    }

    const editors = this.props.tinymce.editors || [];
    return editors.filter(ed => ed.id === this.props.textareaId)[0];
  }

  onTinyMCEInstance(command, args) {
    const editor = this.mceInstance();

    if (editor) {
      if (command === 'mceRemoveEditor') {
        editor.execCommand('mceNewDocument');
      } // makes sure content can't persist past removal


      editor.execCommand(command, false, this.props.textareaId, args);
    }
  }

  destroy() {
    this._destroyCalled = true;
    this.unhandleTextareaChange();
    this.props.handleUnmount && this.props.handleUnmount();
  }

  getTextarea() {
    return document.getElementById(this.props.textareaId);
  }

  textareaValue() {
    return this.getTextarea().value;
  }

  get id() {
    return this.state.id;
  }

  _isFullscreen() {
    return this.state.fullscreenState.isTinyFullscreen || document[FS_ELEMENT];
  }

  _enterFullscreen() {
    switch (this.state.editorView) {
      case PRETTY_HTML_EDITOR_VIEW:
        this._prettyHtmlEditorRef.current.addEventListener('fullscreenchange', this._toggleFullscreen);

        this._prettyHtmlEditorRef.current.addEventListener('webkitfullscreenchange', this._toggleFullscreen); // if I don't focus first, FF complains that the element
        // is not in the active browser tab and requestFullscreen fails


        this._prettyHtmlEditorRef.current.focus();

        this._prettyHtmlEditorRef.current[FS_REQUEST]();

        break;

      case RAW_HTML_EDITOR_VIEW:
        this.getTextarea().addEventListener('fullscreenchange', this._toggleFullscreen);
        this.getTextarea().addEventListener('webkitfullscreenchange', this._toggleFullscreen);
        this.getTextarea()[FS_REQUEST]();
        break;

      case WYSIWYG_VIEW:
        this.mceInstance().execCommand('mceFullScreen');
        break;
    }
  }

  _exitFullscreen() {
    if (this.state.fullscreenState.isTinyFullscreen) {
      this.mceInstance().execCommand('mceFullScreen');
    } else if (document[FS_ELEMENT]) {
      document[FS_ELEMENT][FS_EXIT]();
    }
  }

  focus() {
    this.onTinyMCEInstance('mceFocus'); // tinymce doesn't always call the focus handler.

    this.handleFocusEditor(new Event('focus', {
      target: this.mceInstance()
    }));
  }

  focusCurrentView() {
    switch (this.state.editorView) {
      case WYSIWYG_VIEW:
        this.mceInstance().focus();
        break;

      case PRETTY_HTML_EDITOR_VIEW:
        {
          const cmta = this._elementRef.current.querySelector('.CodeMirror textarea');

          if (cmta) {
            cmta.focus();
          } else {
            window.setTimeout(() => {
              var _this$_elementRef$cur2;

              (_this$_elementRef$cur2 = this._elementRef.current.querySelector('.CodeMirror textarea')) === null || _this$_elementRef$cur2 === void 0 ? void 0 : _this$_elementRef$cur2.focus();
            }, 200);
          }
        }
        break;

      case RAW_HTML_EDITOR_VIEW:
        this.getTextarea().focus();
        break;
    }
  }

  is_dirty() {
    var _this$mceInstance2;

    if (this.mceInstance().isDirty()) {
      return true;
    }

    const content = this.isHidden() ? this.textareaValue() : (_this$mceInstance2 = this.mceInstance()) === null || _this$mceInstance2 === void 0 ? void 0 : _this$mceInstance2.getContent();
    return content !== this.cleanInitialContent();
  }

  cleanInitialContent() {
    if (!this._cleanInitialContent) {
      const el = window.document.createElement('div');
      el.innerHTML = this.props.defaultContent;
      const serializer = this.mceInstance().serializer;
      this._cleanInitialContent = serializer.serialize(el, {
        getInner: true
      });
    }

    return this._cleanInitialContent;
  }

  isHtmlView() {
    return this.state.editorView !== WYSIWYG_VIEW;
  }

  isHidden() {
    return this.mceInstance().isHidden();
  }

  get iframe() {
    return document.getElementById(`${this.props.textareaId}_ifr`);
  } // these focus and blur event handlers work together so that RCEWrapper
  // can report focus and blur events from the RCE at-large


  get focused() {
    return this === bridge.getEditor();
  }

  handleFocus() {
    if (!this.focused) {
      bridge.focusEditor(this);
      this.props.onFocus && this.props.onFocus(this);
    }
  }

  handleContentTrayClosing(isClosing) {
    this.contentTrayClosing = isClosing;
  }

  handleBlur(event) {
    if (this.blurTimer) return;

    if (this.focused) {
      // because the old active element fires blur before the next element gets focus
      // we often need a moment to see if focus comes back
      event && event.persist && event.persist();
      this.blurTimer = window.setTimeout(() => {
        var _this$_elementRef$cur3, _event$focusedEditor, _event$relatedTarget, _event$relatedTarget$;

        this.blurTimer = 0;

        if (this.contentTrayClosing) {
          // the CanvasContentTray is in the process of closing
          // wait until it finishes
          return;
        }

        if ((_this$_elementRef$cur3 = this._elementRef.current) !== null && _this$_elementRef$cur3 !== void 0 && _this$_elementRef$cur3.contains(document.activeElement)) {
          // focus is still somewhere w/in me
          return;
        }

        const activeClass = document.activeElement && document.activeElement.getAttribute('class');

        if ((event.focusedEditor === void 0 || event.target.id === ((_event$focusedEditor = event.focusedEditor) === null || _event$focusedEditor === void 0 ? void 0 : _event$focusedEditor.id)) && activeClass !== null && activeClass !== void 0 && activeClass.includes('tox-')) {
          // if a toolbar button has focus, then the user clicks on the "more" button
          // focus jumps to the body, then eventually to the popped up toolbar. This
          // catches that case.
          return;
        }

        if (event !== null && event !== void 0 && (_event$relatedTarget = event.relatedTarget) !== null && _event$relatedTarget !== void 0 && (_event$relatedTarget$ = _event$relatedTarget.getAttribute('class')) !== null && _event$relatedTarget$ !== void 0 && _event$relatedTarget$.includes('tox-')) {
          // a tinymce popup has focus
          return;
        }

        const popup = document.querySelector('[data-mce-component]');

        if (popup && popup.contains(document.activeElement)) {
          // one of our popups has focus
          return;
        }

        bridge.blurEditor(this);
        this.props.onBlur && this.props.onBlur(event);
      }, ASYNC_FOCUS_TIMEOUT);
    }
  }

  call(methodName, ...args) {
    // since exists? has a ? and cant be a regular function just return true
    // rather than calling as a fn on the editor
    if (methodName === 'exists?') {
      return true;
    }

    return this[methodName](...args);
  }

  announceContextToolbars(editor) {
    editor.on('NodeChange', () => {
      const node = editor.selection.getNode();

      if (isImageEmbed(node, editor)) {
        if (this.announcing !== 1) {
          this.setState({
            announcement: formatMessage('type Control F9 to access image options. {text}', {
              text: node.getAttribute('alt')
            })
          });
          this.announcing = 1;
        }
      } else if (isFileLink(node, editor)) {
        if (this.announcing !== 2) {
          this.setState({
            announcement: formatMessage('type Control F9 to access link options. {text}', {
              text: node.textContent
            })
          });
          this.announcing = 2;
        }
      } else if (isElementWithinTable(node, editor)) {
        if (this.announcing !== 3) {
          this.setState({
            announcement: formatMessage('type Control F9 to access table options. {text}', {
              text: node.textContent
            })
          });
          this.announcing = 3;
        }
      } else {
        this.setState({
          announcement: null
        });
        this.announcing = 0;
      }
    });
  }
  /* ********** autosave support *************** */


  // if a placeholder image shows up in autosaved content, we have to remove it
  // because the data url gets converted to a blob, which is not valid when restored.
  // besides, the placeholder is intended to be temporary while the file
  // is being uploaded
  patchAutosavedContent(content, asText) {
    const temp = document.createElement('div');
    temp.innerHTML = content;
    temp.querySelectorAll('[data-placeholder-for]').forEach(placeholder => {
      placeholder.parentElement.removeChild(placeholder);
    });
    if (asText) return temp.textContent;
    return temp.innerHTML;
  }

  getAutoSaved(key) {
    let autosaved = null;

    try {
      autosaved = this.storage && JSON.parse(this.storage.getItem(key));
    } catch (_ex) {
      this.storage.removeItem(this.autoSaveKey);
    }

    return autosaved;
  } // only autosave if the feature flag is set, and there is only 1 RCE on the page
  // the latter condition is necessary because the popup RestoreAutoSaveModal
  // is lousey UX when there are >1


  get isAutoSaving() {
    // If the editor is invisible for some reason, don't show the autosave modal
    // This doesn't apply if the editor is off-screen or has visibility:hidden;
    // only if it isn't rendered or has display:none;
    const editorVisible = this.editor.getContainer().offsetParent;
    return this.props.autosave.enabled && editorVisible && document.querySelectorAll('.rce-wrapper').length === 1 && storageAvailable();
  }

  get autoSaveKey() {
    var _this$props$trayProps;

    const userId = (_this$props$trayProps = this.props.trayProps) === null || _this$props$trayProps === void 0 ? void 0 : _this$props$trayProps.containingContext.userId;
    return `rceautosave:${userId}${window.location.href}:${this.props.textareaId}`;
  }

  componentWillUnmount() {
    if (this.state.shouldShowEditor) {
      var _this$mutationObserve, _this$intersectionObs;

      window.clearTimeout(this.blurTimer);

      if (!this._destroyCalled) {
        this.destroy();
      }

      this._elementRef.current.removeEventListener('keydown', this.handleKey, true);

      (_this$mutationObserve = this.mutationObserver) === null || _this$mutationObserve === void 0 ? void 0 : _this$mutationObserve.disconnect();
      (_this$intersectionObs = this.intersectionObserver) === null || _this$intersectionObs === void 0 ? void 0 : _this$intersectionObs.disconnect();
    }
  }

  wrapOptions(options = {}) {
    var _this$props$trayProps2, _this$props$trayProps3, _this$props$trayProps4;

    const rcsExists = !!((_this$props$trayProps2 = this.props.trayProps) !== null && _this$props$trayProps2 !== void 0 && _this$props$trayProps2.host && (_this$props$trayProps3 = this.props.trayProps) !== null && _this$props$trayProps3 !== void 0 && _this$props$trayProps3.jwt);
    const setupCallback = options.setup;
    const canvasPlugins = rcsExists ? ['instructure_links', 'instructure_image', 'instructure_documents', 'instructure_equation', 'instructure_external_tools'] : ['instructure_links'];

    if (rcsExists && !this.props.instRecordDisabled) {
      canvasPlugins.splice(2, 0, 'instructure_record');
    }

    if (rcsExists && this.props.use_rce_buttons_and_icons && ((_this$props$trayProps4 = this.props.trayProps) === null || _this$props$trayProps4 === void 0 ? void 0 : _this$props$trayProps4.contextType) === 'course') {
      canvasPlugins.push('instructure_buttons');
    }

    const possibleNewMenubarItems = this.props.editorOptions.menu ? Object.keys(this.props.editorOptions.menu).join(' ') : void 0;

    const wrappedOpts = _objectSpread(_objectSpread({}, options), {}, {
      readonly: this.props.readOnly,
      theme: 'silver',
      // some older code specified 'modern', which doesn't exist any more
      height: options.height || DEFAULT_RCE_HEIGHT,
      language: editorLanguage(this.language),
      block_formats: options.block_formats || [`${formatMessage('Heading 2')}=h2`, `${formatMessage('Heading 3')}=h3`, `${formatMessage('Heading 4')}=h4`, `${formatMessage('Preformatted')}=pre`, `${formatMessage('Paragraph')}=p`].join('; '),
      setup: editor => {
        var _bridge$trayProps;

        addKebabIcon(editor);
        editorWrappers.set(editor, this);

        const trayPropsWithColor = _objectSpread({
          brandColor: this.theme.canvasBrandColor
        }, this.props.trayProps);

        (_bridge$trayProps = bridge.trayProps) === null || _bridge$trayProps === void 0 ? void 0 : _bridge$trayProps.set(editor, trayPropsWithColor);
        bridge.languages = this.props.languages;

        if (typeof setupCallback === 'function') {
          setupCallback(editor);
        }
      },
      // Consumers can, and should!, still pass a content_css prop so that the content
      // in the editor matches the styles of the app it will be displayed in when saved.
      // This is just so we inject the helper class names that tinyMCE uses for
      // things like table resizing and stuff.
      content_css: options.content_css || [],
      content_style: contentCSS,
      menubar: mergeMenuItems('edit view insert format tools table', possibleNewMenubarItems),
      // default menu options listed at https://www.tiny.cloud/docs/configure/editor-appearance/#menu
      // tinymce's default edit and table menus are fine
      // we include all the canvas specific items in the menu and toolbar
      // and rely on tinymce only showing them if the plugin is provided.
      menu: mergeMenu({
        format: {
          title: formatMessage('Format'),
          items: 'bold italic underline strikethrough superscript subscript codeformat | formats blockformats fontformats fontsizes align directionality | forecolor backcolor | removeformat'
        },
        insert: {
          title: formatMessage('Insert'),
          items: 'instructure_links instructure_image instructure_media instructure_document instructure_buttons | instructure_equation inserttable instructure_media_embed | hr'
        },
        tools: {
          title: formatMessage('Tools'),
          items: 'wordcount lti_tools_menuitem'
        },
        view: {
          title: formatMessage('View'),
          items: 'fullscreen instructure_html_view'
        }
      }, options.menu),
      toolbar: mergeToolbar([{
        name: formatMessage('Styles'),
        items: ['fontsizeselect', 'formatselect']
      }, {
        name: formatMessage('Formatting'),
        items: ['bold', 'italic', 'underline', 'forecolor', 'backcolor', 'inst_subscript', 'inst_superscript']
      }, {
        name: formatMessage('Content'),
        items: ['instructure_links', 'instructure_image', 'instructure_record', 'instructure_documents', 'instructure_buttons']
      }, {
        name: formatMessage('External Tools'),
        items: [...this.ltiToolFavorites, 'lti_tool_dropdown', 'lti_mru_button']
      }, {
        name: formatMessage('Alignment and Lists'),
        items: ['align', 'bullist', 'inst_indent', 'inst_outdent']
      }, {
        name: formatMessage('Miscellaneous'),
        items: ['removeformat', 'table', 'instructure_equation', 'instructure_media_embed']
      }], options.toolbar),
      contextmenu: '',
      // show the browser's native context menu
      toolbar_mode: 'floating',
      toolbar_sticky: true,
      plugins: mergePlugins(['autolink', 'media', 'paste', 'table', 'link', 'directionality', 'lists', 'hr', 'fullscreen', 'instructure-ui-icons', 'instructure_condensed_buttons', 'instructure_links', 'instructure_html_view', 'instructure_media_embed', 'instructure_external_tools', 'a11y_checker', 'wordcount', ...canvasPlugins], sanitizePlugins(options.plugins))
    });

    if (this.props.trayProps) {
      wrappedOpts.canvas_rce_user_context = {
        type: this.props.trayProps.contextType,
        id: this.props.trayProps.contextId
      };
      wrappedOpts.canvas_rce_containing_context = {
        type: this.props.trayProps.containingContext.contextType,
        id: this.props.trayProps.containingContext.contextId
      };
    }

    return wrappedOpts;
  }

  unhandleTextareaChange() {
    if (this._textareaEl) {
      this._textareaEl.removeEventListener('input', this.handleTextareaChange);
    }
  }

  registerTextareaChange() {
    const el = this.getTextarea();

    if (this._textareaEl !== el) {
      this.unhandleTextareaChange();

      if (el) {
        el.addEventListener('input', this.handleTextareaChange);

        if (this.props.textareaClassName) {
          // split the string on whitespace because classList doesn't let you add multiple
          // space seperated classes at a time but does let you add an array of them
          el.classList.add(...this.props.textareaClassName.split(/\s+/));
        }

        this._textareaEl = el;
      }
    }
  }

  componentDidMount() {
    if (this.state.shouldShowEditor) {
      this.editorReallyDidMount();
    } else {
      this.intersectionObserver = new IntersectionObserver(entries => {
        const entry = entries[0];

        if (entry.isIntersecting || entry.intersectionRatio > 0) {
          this.setState({
            shouldShowEditor: true
          });
        }
      }, // initialize the RCE when it gets close to entering the viewport
      {
        root: null,
        rootMargin: '200px 0px',
        threshold: 0.0
      });
      this.intersectionObserver.observe(this._editorPlaceholderRef.current);
    }
  }

  componentDidUpdate(prevProps, prevState) {
    if (this.state.shouldShowEditor) {
      if (!prevState.shouldShowEditor) {
        var _this$intersectionObs2;

        this.editorReallyDidMount();
        (_this$intersectionObs2 = this.intersectionObserver) === null || _this$intersectionObs2 === void 0 ? void 0 : _this$intersectionObs2.disconnect();
      } else {
        this.registerTextareaChange();

        if (prevState.editorView !== this.state.editorView) {
          this.setEditorView(this.state.editorView);
          this.focusCurrentView();
        }

        if (prevProps.readOnly !== this.props.readOnly) {
          this.mceInstance().mode.set(this.props.readOnly ? 'readonly' : 'design');
        }
      }
    }
  }

  editorReallyDidMount() {
    const myTiny = this.mceInstance();
    this.pendingEventHandlers.forEach(e => {
      myTiny.on(e.name, e.handler);
    });
    this.registerTextareaChange();

    this._elementRef.current.addEventListener('keydown', this.handleKey, true); // give the textarea its initial size


    this.onResize(null, {
      deltaY: 0
    }); // Preload the LTI Tools modal
    // This helps with loading the favorited external tools

    if (this.ltiToolFavorites.length > 0) {
      import('./plugins/instructure_external_tools/components/LtiToolsModal');
    } // .tox-tinymce-aux is where tinymce puts the floating toolbar when
    // the user clicks the More... button
    // Tinymce doesn't fire onFocus when the user clicks More... from somewhere
    // outside, so we'll handle that here by watching for the floating toolbar
    // to come and go.


    const portals = document.querySelectorAll('.tox-tinymce-aux'); // my portal will be the last one in the doc because tinyumce appends them

    const tinymce_floating_toolbar_portal = portals[portals.length - 1];

    if (tinymce_floating_toolbar_portal) {
      this.mutationObserver = new MutationObserver(mutationList => {
        mutationList.forEach(mutation => {
          if (mutation.type === 'childList' && mutation.addedNodes.length > 0) {
            this.handleFocusEditor(new Event('focus', {
              target: mutation.target
            }));
          }
        });
      });
      this.mutationObserver.observe(tinymce_floating_toolbar_portal, {
        childList: true
      });
    }

    bridge.renderEditor(this);
  }

  setEditorView(view) {
    var _this$getTextarea$lab, _this$getTextarea$lab2, _this$getTextarea$lab3, _this$getTextarea$lab4, _this$_elementRef$cur4, _this$getTextarea$lab5, _this$getTextarea$lab6;

    switch (view) {
      case RAW_HTML_EDITOR_VIEW:
        this.getTextarea().removeAttribute('aria-hidden');
        (_this$getTextarea$lab = this.getTextarea().labels) === null || _this$getTextarea$lab === void 0 ? void 0 : (_this$getTextarea$lab2 = _this$getTextarea$lab[0]) === null || _this$getTextarea$lab2 === void 0 ? void 0 : _this$getTextarea$lab2.removeAttribute('aria-hidden');
        this.mceInstance().hide();
        break;

      case PRETTY_HTML_EDITOR_VIEW:
        this.getTextarea().setAttribute('aria-hidden', true);
        (_this$getTextarea$lab3 = this.getTextarea().labels) === null || _this$getTextarea$lab3 === void 0 ? void 0 : (_this$getTextarea$lab4 = _this$getTextarea$lab3[0]) === null || _this$getTextarea$lab4 === void 0 ? void 0 : _this$getTextarea$lab4.setAttribute('aria-hidden', true);
        this.mceInstance().hide();
        (_this$_elementRef$cur4 = this._elementRef.current.querySelector('.CodeMirror')) === null || _this$_elementRef$cur4 === void 0 ? void 0 : _this$_elementRef$cur4.CodeMirror.setCursor(0, 0);
        break;

      case WYSIWYG_VIEW:
        this.setCode(this.textareaValue());
        this.getTextarea().setAttribute('aria-hidden', true);
        (_this$getTextarea$lab5 = this.getTextarea().labels) === null || _this$getTextarea$lab5 === void 0 ? void 0 : (_this$getTextarea$lab6 = _this$getTextarea$lab5[0]) === null || _this$getTextarea$lab6 === void 0 ? void 0 : _this$getTextarea$lab6.setAttribute('aria-hidden', true);
        this.mceInstance().show();
    }
  }

  renderHtmlEditor() {
    // the div keeps the editor from collapsing while the code editor is downloaded
    return /*#__PURE__*/React.createElement(Suspense, {
      fallback: /*#__PURE__*/React.createElement("div", {
        style: {
          height: this.state.height,
          display: 'flex',
          justifyContent: 'center',
          alignItems: 'center'
        }
      }, /*#__PURE__*/React.createElement(Spinner, {
        renderTitle: renderLoading,
        size: "medium"
      }))
    }, /*#__PURE__*/React.createElement(View, {
      as: "div",
      borderRadius: "medium",
      borderWidth: "small"
    }, /*#__PURE__*/React.createElement(RceHtmlEditor, {
      ref: this._prettyHtmlEditorRef,
      height: document[FS_ELEMENT] ? `${window.screen.height}px` : this.state.height,
      code: this.getCode(),
      onChange: value => {
        this.getTextarea().value = value;
        this.handleTextareaChange();
      },
      onFocus: this.handleFocusHtmlEditor
    })));
  }

  render() {
    const _this$props3 = this.props,
          trayProps = _this$props3.trayProps,
          mceProps = _objectWithoutProperties(_this$props3, _excluded);

    if (!this.state.shouldShowEditor) {
      return /*#__PURE__*/React.createElement("div", {
        ref: this._editorPlaceholderRef,
        style: {
          width: `${this.props.editorOptions.width}px`,
          height: `${this.props.editorOptions.height}px`,
          border: '1px solid grey'
        }
      });
    }

    return /*#__PURE__*/React.createElement("div", {
      key: this.id,
      className: `${styles.root} rce-wrapper`,
      ref: this._elementRef,
      onFocus: this.handleFocusRCE,
      onBlur: this.handleBlurRCE
    }, this.state.shouldShowOnFocusButton && /*#__PURE__*/React.createElement(ShowOnFocusButton, {
      onClick: this.openKBShortcutModal,
      margin: "xx-small",
      screenReaderLabel: formatMessage('View keyboard shortcuts'),
      ref: el => this._showOnFocusButton = el
    }, /*#__PURE__*/React.createElement(IconKeyboardShortcutsLine, null)), /*#__PURE__*/React.createElement(AlertMessageArea, {
      messages: this.state.messages,
      liveRegion: this.props.liveRegion,
      afterDismiss: this.removeAlert
    }), this.state.editorView === PRETTY_HTML_EDITOR_VIEW && this.renderHtmlEditor(), /*#__PURE__*/React.createElement("div", {
      style: {
        display: this.state.editorView === PRETTY_HTML_EDITOR_VIEW ? 'none' : 'block'
      }
    }, /*#__PURE__*/React.createElement(Editor, {
      id: mceProps.textareaId,
      textareaName: mceProps.name,
      init: this.tinymceInitOptions,
      initialValue: mceProps.defaultContent,
      onInit: this.onInit,
      onClick: this.handleFocusEditor,
      onKeypress: this.handleFocusEditor,
      onActivate: this.handleFocusEditor,
      onRemove: this.onRemove,
      onFocus: this.handleFocusEditor,
      onBlur: this.handleBlurEditor,
      onNodeChange: this.onNodeChange,
      onEditorChange: this.onEditorChange
    })), /*#__PURE__*/React.createElement(StatusBar, {
      readOnly: this.props.readOnly,
      onChangeView: newView => this.toggleView(newView),
      path: this.state.path,
      wordCount: this.state.wordCount,
      editorView: this.state.editorView,
      preferredHtmlEditor: getHtmlEditorCookie(),
      onResize: this.onResize,
      onKBShortcutModalOpen: this.openKBShortcutModal,
      onA11yChecker: this.onA11yChecker,
      onFullscreen: this.handleClickFullscreen,
      use_rce_a11y_checker_notifications: this.props.use_rce_a11y_checker_notifications,
      a11yBadgeColor: this.theme.canvasBadgeBackgroundColor,
      a11yErrorsCount: this.state.a11yErrorsCount
    }), this.props.trayProps && this.props.trayProps.containingContext && /*#__PURE__*/React.createElement(CanvasContentTray, Object.assign({
      key: this.id,
      bridge: bridge,
      editor: this,
      onTrayClosing: this.handleContentTrayClosing,
      use_rce_buttons_and_icons: this.props.use_rce_buttons_and_icons
    }, trayProps)), /*#__PURE__*/React.createElement(KeyboardShortcutModal, {
      onExited: this.KBShortcutModalExited,
      onDismiss: this.closeKBShortcutModal,
      open: this.state.KBShortcutModalOpen
    }), this.state.confirmAutoSave ? /*#__PURE__*/React.createElement(Suspense, {
      fallback: /*#__PURE__*/React.createElement(Spinner, {
        renderTitle: renderLoading,
        size: "small"
      })
    }, /*#__PURE__*/React.createElement(RestoreAutoSaveModal, {
      savedContent: this.state.autoSavedContent,
      open: this.state.confirmAutoSave,
      onNo: () => this.restoreAutoSave(false),
      onYes: () => this.restoreAutoSave(true)
    })) : null, /*#__PURE__*/React.createElement(Alert, {
      screenReaderOnly: true,
      liveRegion: this.props.liveRegion
    }, this.state.announcement));
  }

}, _class2.propTypes = {
  autosave: PropTypes.shape({
    enabled: PropTypes.bool,
    maxAge: PropTypes.number
  }),
  defaultContent: PropTypes.string,
  editorOptions: editorOptionsPropType,
  handleUnmount: PropTypes.func,
  editorView: PropTypes.oneOf([WYSIWYG_VIEW, PRETTY_HTML_EDITOR_VIEW, RAW_HTML_EDITOR_VIEW]),
  renderKBShortcutModal: PropTypes.bool,
  id: PropTypes.string,
  language: PropTypes.string,
  liveRegion: PropTypes.func.isRequired,
  ltiTools: ltiToolsPropType,
  onContentChange: PropTypes.func,
  onFocus: PropTypes.func,
  onBlur: PropTypes.func,
  onInitted: PropTypes.func,
  onRemove: PropTypes.func,
  textareaClassName: PropTypes.string,
  textareaId: PropTypes.string.isRequired,
  languages: PropTypes.arrayOf(PropTypes.shape({
    id: PropTypes.string.isRequired,
    label: PropTypes.string.isRequired
  })),
  readOnly: PropTypes.bool,
  tinymce: PropTypes.object,
  trayProps: trayPropTypes,
  toolbar: toolbarPropType,
  menu: menuPropType,
  plugins: PropTypes.arrayOf(PropTypes.string),
  instRecordDisabled: PropTypes.bool,
  highContrastCSS: PropTypes.arrayOf(PropTypes.string),
  maxInitRenderedRCEs: PropTypes.number,
  use_rce_buttons_and_icons: PropTypes.bool,
  use_rce_a11y_checker_notifications: PropTypes.bool
}, _class2.defaultProps = {
  trayProps: null,
  languages: [{
    id: 'en',
    label: 'English'
  }],
  autosave: {
    enabled: false
  },
  highContrastCSS: [],
  ltiTools: [],
  maxInitRenderedRCEs: -1
}, _class2.skinCssInjected = false, _temp)) || _class); // standard: string of tinymce menu commands
// e.g. 'instructure_links | inserttable instructure_media_embed | hr'
// custom: a string of tinymce menu commands
// returns: standard + custom with any duplicate commands removed from custom

function mergeMenuItems(standard, custom) {
  var _custom$trim;

  let c = custom === null || custom === void 0 ? void 0 : (_custom$trim = custom.trim) === null || _custom$trim === void 0 ? void 0 : _custom$trim.call(custom);
  if (!c) return standard;
  const s = new Set(standard.split(/[\s|]+/)); // remove any duplicates

  c = c.split(/\s+/).filter(m => !s.has(m));
  c = c.join(' ').replace(/^\s*\|\s*/, '').replace(/\s*\|\s*$/, '');
  return `${standard} | ${c}`;
} // standard: the incoming tinymce menu object
// custom: tinymce menu object to merge into standard
// returns: the merged result by mutating incoming standard arg.
// It will add commands to existing menus, or add a new menu
// if the custom one does not exist


function mergeMenu(standard, custom) {
  if (!custom) return standard;
  Object.keys(custom).forEach(k => {
    const curr_m = standard[k];

    if (curr_m) {
      curr_m.items = mergeMenuItems(curr_m.items, custom[k].items);
    } else {
      standard[k] = _objectSpread({}, custom[k]);
    }
  });
  return standard;
} // standard: incoming tinymce toolbar array
// custom: tinymce toolbar array to merge into standard
// returns: the merged result by mutating the incoming standard arg.
// It will add commands to existing toolbars, or add a new toolbar
// if the custom one does not exist


function mergeToolbar(standard, custom) {
  if (!custom) return standard; // merge given toolbar data into the default toolbar

  custom.forEach(tb => {
    const curr_tb = standard.find(t => tb.name && formatMessage(tb.name) === t.name);

    if (curr_tb) {
      curr_tb.items.splice(curr_tb.items.length, 0, ...tb.items);
    } else {
      standard.push(tb);
    }
  });
  return standard;
} // standard: incoming array of plugin names
// custom: array of plugin names to merge
// returns: the merged result, duplicates removed


function mergePlugins(standard, custom) {
  if (!custom) return standard;
  const union = new Set(standard);

  for (const p of custom) {
    union.add(p);
  }

  return [...union];
}

export default RCEWrapper;
export { toolbarPropType, menuPropType, ltiToolsPropType, mergeMenuItems, mergeMenu, mergeToolbar, mergePlugins };