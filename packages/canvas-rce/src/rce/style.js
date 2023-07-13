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

import {getThemeVars} from '../getThemeVars'
import {darken, lighten, alpha} from '@instructure/ui-color-utils'

export default function buildStyle() {
  /*
   * If the theme variables to be used when generating the styles below
   * are dependent on the actual theme in use, you can also pull out the
   * `key` property from the return from `getThemeVars()` and do a bit of
   * if or switch statement logic to get the result you want.
   */
  const {variables, key} = getThemeVars()

  let themeCanvasLinkColor = ''
  let themeCanvasLinkDecoration = ''
  let themeCanvasTextColor = ''
  let themeCanvasBrandColor = ''
  let themeCanvasFocusBorderColor = ''
  let themeCanvasFocusBoxShadow = ''
  let themeCanvasEnabledColor = ''
  let themeCanvasPrimaryButtonBackground = ''
  let themeCanvasPrimaryButtonColor = ''
  let themeCanvasPrimaryButtonHoverBackground = ''
  let themeActiveMenuItemBackground = ''
  let themeActiveMenuItemLabelColor = ''
  let themeTableSelectorHighlightColor = ''
  let themeCanvasButtonBackground = ''
  let themeCanvasSecondaryButtonBorderColor = ''
  switch (key) {
    case 'canvas':
      themeCanvasLinkColor = variables['ic-link-color']
      themeCanvasLinkDecoration = variables['ic-link-decoration']
      themeCanvasTextColor = variables['ic-brand-font-color-dark']
      themeCanvasBrandColor = variables['ic-brand-primary']
      themeCanvasFocusBorderColor = variables['ic-brand-primary']
      themeCanvasFocusBoxShadow = `0 0 0 2px ${variables['ic-brand-primary']}`
      themeCanvasEnabledColor = variables['ic-brand-primary']
      themeCanvasPrimaryButtonBackground = variables['ic-brand-primary']
      themeCanvasPrimaryButtonColor = variables['ic-brand-button--primary-text']
      themeCanvasPrimaryButtonHoverBackground = darken(
        variables['ic-brand-button--primary-bgd'],
        10
      )
      themeActiveMenuItemBackground = variables['ic-brand-button--primary-bgd']
      themeActiveMenuItemLabelColor = variables['ic-brand-button--primary-text']
      themeTableSelectorHighlightColor = alpha(lighten(variables['ic-brand-primary'], 10), 50)
      break
    case 'canvas-a11y':
    case 'canvas-high-contrast':
      themeCanvasButtonBackground = variables.colors.backgroundLight
      themeCanvasSecondaryButtonBorderColor = variables.colors.borderMedium
      themeCanvasLinkDecoration = 'underline'
      themeCanvasFocusBorderColor = variables.colors.borderBrand
      themeCanvasFocusBoxShadow = `0 0 0 2px ${variables.colors.brand}`
      themeCanvasBrandColor = variables.colors.brand
      break
    default:
      themeCanvasLinkColor = variables.colors.link
      themeCanvasLinkDecoration = 'none'
      themeCanvasTextColor = variables.colors.textDarkest
      themeCanvasBrandColor = variables.colors.brand
      themeCanvasFocusBorderColor = variables.borders.brand
      themeCanvasFocusBoxShadow = `0 0 0 2px ${variables.colors.brand}`
      themeCanvasEnabledColor = variables.borders.brand
      themeCanvasPrimaryButtonBackground = variables.colors.backgroundBrand
      themeCanvasPrimaryButtonColor = variables.colors.textLightest
      themeCanvasPrimaryButtonHoverBackground = darken(variables.colors.backgroundBrand, 10)
      themeActiveMenuItemBackground = variables.colors.backgroundBrand
      themeActiveMenuItemLabelColor = variables.colors.textLightest
      themeTableSelectorHighlightColor = alpha(lighten(variables.colors.brand, 10), 50)
      themeCanvasButtonBackground = variables.colors.backgroundLightest
      themeCanvasSecondaryButtonBorderColor = darken(variables.colors.backgroundLight, 10)
      break
  }

  const classNames = {
    root: 'canvas-rce__skins--root',
  }

  const toolbarButtonHoverBackgroundConst = darken(variables.colors.backgroundLightest, 5)
  const tinySplitButtonChevronHoverBackgroundConst = darken(toolbarButtonHoverBackgroundConst, 10)

  const theme = {
    canvasBackgroundColor: variables.colors.white,
    canvasTextColor: themeCanvasTextColor,
    canvasErrorColor: variables.colors.textDanger,
    canvasWarningColor: variables.colors.textWarning,
    canvasInfoColor: variables.colors.textInfo,
    canvasSuccessColor: variables.colors.textSuccess,
    canvasBorderColor: variables.colors.borderMedium,
    toolbarButtonHoverBackground: toolbarButtonHoverBackgroundConst, // copied from INSTUI "light" Button
    tinySplitButtonChevronHoverBackground: tinySplitButtonChevronHoverBackgroundConst,
    canvasBrandColor: themeCanvasBrandColor,

    activeMenuItemBackground: themeActiveMenuItemBackground,
    activeMenuItemLabelColor: themeActiveMenuItemLabelColor,
    tableSelectorHighlightColor: themeTableSelectorHighlightColor,

    canvasLinkColor: themeCanvasLinkColor,
    canvasLinkDecoration: themeCanvasLinkDecoration,

    // the instui default button
    canvasButtonBackground: themeCanvasButtonBackground,
    canvasButtonBorderColor: 'transparent',
    canvasButtonColor: variables.colors.textDarkest,
    canvasButtonHoverBackground: variables.colors.backgroundLightest,
    canvasButtonHoverColor: variables.colors.brand,
    canvasButtonActiveBackground: variables.colors.backgroundLightest,
    canvasButtonFontWeight: variables.typography.fontWeightNormal,
    canvasButtonFontSize: variables.typography.fontSizeMedium,
    canvasButtonLineHeight: variables.forms.inputHeightMedium,
    canvasButtonPadding: `0 ${variables.spacing.small}`,

    // the instui primary button
    canvasPrimaryButtonBackground: themeCanvasPrimaryButtonBackground,
    canvasPrimaryButtonColor: themeCanvasPrimaryButtonColor,
    canvasPrimaryButtonBorderColor: 'transparent',
    canvasPrimaryButtonHoverBackground: themeCanvasPrimaryButtonHoverBackground,
    canvasPrimaryButtonHoverColor: variables.colors.textLightest,

    // the instui secondary button
    canvasSecondaryButtonBackground: variables.colors.backgroundLight,
    canvasSecondaryButtonColor: variables.colors.textDarkest,
    canvasSecondaryButtonBorderColor: themeCanvasSecondaryButtonBorderColor,
    canvasSecondaryButtonHoverBackground: darken(variables.colors.backgroundLight, 10),
    canvasSecondaryButtonHoverColor: variables.colors.textDarkest,

    canvasFocusBorderColor: themeCanvasFocusBorderColor,
    canvasFocusBorderWidth: variables.borders.widthSmall, // canvas really uses widthMedium
    canvasFocusBoxShadow: themeCanvasFocusBoxShadow,
    canvasEnabledColor: themeCanvasEnabledColor,
    canvasEnabledBoxShadow: `inset 0 0 0.1875rem 0.0625rem ${darken(
      variables.colors.borderLightest,
      25
    )}`,

    canvasFontFamily: variables.typography.fontFamily,
    canvasFontSize: '1rem',
    canvasFontSizeSmall: variables.typography.fontSizeSmall,

    // modal dialogs
    canvasModalShadow: variables.shadows.depth3,
    canvasModalHeadingPadding: variables.spacing.medium,
    canvasModalHeadingFontSize: variables.typography.fontSizeXLarge,
    canvasModalHeadingFontWeight: variables.typography.fontWeightNormal,
    canvasModalBodyPadding: variables.spacing.medium,
    canvasModalFooterPadding: variables.spacing.small,
    canvasModalFooterBackground: variables.colors.backgroundLight,
    canvasFormElementMargin: `0 0 ${variables.spacing.medium} 0`,
    canvasFormElementLabelColor: variables.colors.textDarkest,
    canvasFormElementLabelMargin: `0 0 ${variables.spacing.small} 0`,
    canvasFormElementLabelFontSize: variables.typography.fontSizeMedium,
    canvasFormElementLabelFontWeight: variables.typography.fontWeightBold,

    // a11y button badge
    canvasBadgeBackgroundColor: variables.colors.textInfo,
  }

  const css = `
  .${classNames.root} {
    background-color: ${theme.canvasBackgroundColor};
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
  [dir=rtl] .tox :not(svg) {
    direction: rtl;
  }
  .tox:not(.tox-tinymce-inline) .tox-editor-header {
    background-color: ${theme.canvasBackgroundColor};
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
    font-family: ${theme.canvasFontFamily};
  }
  .tox.tox-tinymce-aux {
    z-index: 10000;
  }
  .tox .tox-button {
    background-color: ${theme.canvasPrimaryButtonHoverBackground};
    font-family: ${theme.canvasFontFamily};
    font-weight: ${theme.canvasButtonFontWeight};
    font-size: ${theme.canvasButtonFontSize};
    color: ${theme.canvasPrimaryButtonColor};
    border-color: ${theme.canvasPrimaryButtonBorderColor};
    line-height: calc(${theme.canvasButtonLineHeight} - 2px);
    padding: ${theme.canvasButtonPadding};
  }
  .tox .tox-button[disabled] {
    opacity: 0.5;
    border-color: inherit;
    color: inherit;
  }
  .tox .tox-button:focus:not(:disabled) {
    background-color: ${theme.canvasPrimaryButtonBackground};
    color: ${theme.canvasPrimaryButtonColor};
    border-color: ${theme.canvasBackgroundColor};
    box-shadow: ${theme.canvasFocusBoxShadow};
  }
  .tox .tox-button:hover:not(:disabled) {
    background-color: ${theme.canvasPrimaryButtonHoverBackground};
    color: ${theme.canvasPrimaryButtonHoverColor};
  }
  .tox .tox-button:active:not(:disabled) {
    background-color: ${theme.canvasPrimaryButtonBackground};
    border-color: ${theme.canvasPrimaryButtonBorderColor};
    color: ${theme.canvasPrimaryButtonColor};
  }
  .tox .tox-button--secondary {
    background-color: ${theme.canvasSecondaryButtonBackground};
    border-color: ${theme.canvasSecondaryButtonBorderColor};
    color: ${theme.canvasSecondaryButtonColor};
  }
  .tox .tox-button--secondary[disabled] {
    background-color: inherit;
    border-color: ${theme.canvasSecondaryButtonBorderColor};
    color: inherit;
    opacity: 0.5;
  }
  .tox .tox-button--secondary:focus:not(:disabled) {
    background-color: inherit;
    border-color: ${theme.canvasFocusBorderColor};
    color: inherit;
  }
  .tox .tox-button--secondary:hover:not(:disabled) {
    background-color: ${theme.canvasSecondaryButtonHoverBackground};
    border-color: ${theme.canvasSecondaryButtonBorderColor};
    color: ${theme.canvasSecondaryButtonHoverColor};
  }
  .tox .tox-button--secondary:active:not(:disabled) {
    background-color: inherit;
    border-color: ${theme.canvasSecondaryButtonBorderColor};
    color: inherit;
  }
  .tox .tox-button-link {
    font-family: ${theme.canvasFontFamily};
  }
  .tox .tox-button--naked {
    background: ${theme.canvasButtonBackground};
    border-color: ${theme.canvasButtonBorderColor};
    color: ${theme.canvasButtonColor};
  }
  .tox .tox-button--naked:hover:not(:disabled) {
    background-color: ${theme.canvasButtonHoverBackground};
    border-color: ${theme.canvasButtonBorderColor};
    color: ${theme.canvasButtonHoverColor};
  }
  .tox .tox-button--naked:focus:not(:disabled) {
    background-color: ${theme.canvasButtonBackground};
    color: ${theme.canvasButtonColor};
    border-color: ${theme.canvasBackgroundColor};
    box-shadow: ${theme.canvasFocusBoxShadow};
  }
  .tox .tox-button--naked:active:not(:disabled) {
    background-color: inherit;
    color: inherit;
  }
  .tox .tox-button--naked.tox-button--icon {
    color: ${theme.canvasButtonColor};
  }
  .tox .tox-button--naked.tox-button--icon:hover:not(:disabled) {
    background: ${theme.canvasButtonHoverBackground};
    color: ${theme.canvasButtonHoverColor};
  }
  .tox .tox-checkbox__icons .tox-checkbox-icon__unchecked svg {
    fill: rgba(45, 59, 69, 0.3);
  }
  .tox .tox-checkbox__icons .tox-checkbox-icon__indeterminate svg {
    fill: ${theme.canvasTextColor};
  }
  .tox .tox-checkbox__icons .tox-checkbox-icon__checked svg {
    fill: ${theme.canvasTextColor};
  }
  .tox input.tox-checkbox__input:focus + .tox-checkbox__icons {
    box-shadow: ${theme.canvasFocusBoxShadow};
  }
  .tox .tox-collection--list .tox-collection__group {
    border-color: ${theme.canvasBorderColor};
  }
  .tox .tox-collection__group-heading {
    background-color: #e3e6e8;
    color: rgba(45, 59, 69, 0.6);
  }
  .tox .tox-collection__item {
    color: ${theme.canvasTextColor};
  }
  .tox .tox-collection__item--state-disabled {
    background-color: unset;
    opacity: 0.5;
    cursor: default;
  }
  .tox .tox-collection--list .tox-collection__item--enabled {
    color: contrast(inherit, ${theme.canvasTextColor}, #fff);
  }
  .tox .tox-collection--list .tox-collection__item--active {
    background-color: ${theme.activeMenuItemBackground};
    color: ${theme.activeMenuItemLabelColor};
  }
  .tox .tox-collection--list .tox-collection__item--active:not(.tox-collection__item--state-disabled) {
    background-color: ${theme.activeMenuItemBackground};
    color: ${theme.activeMenuItemLabelColor};
  }
  .tox .tox-collection--toolbar .tox-collection__item--enabled {
    background-color: #cbced1;
    color: ${theme.canvasTextColor};
  }
  .tox .tox-collection--toolbar .tox-collection__item--active {
    background-color: #e0e2e3;
    color: ${theme.canvasTextColor};
  }
  .tox .tox-collection--grid .tox-collection__item--enabled {
    background-color: #cbced1;
    color: ${theme.canvasTextColor};
  }
  .tox .tox-collection--grid .tox-collection__item--active {
    background-color: #e0e2e3;
    color: ${theme.canvasTextColor};
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
    /* Need !important to override Chrome's focus styling unfortunately */
    border-color: ${theme.canvasErrorColor} !important;
  }
  .tox .tox-rgb-form {
    padding: 2px;
    /* make room for the canvas focus ring on contained input elements */
  }
  .tox .tox-swatches__picker-btn:hover {
    background: #e0e2e3;
  }
  .tox .tox-comment-thread {
    background: ${theme.canvasBackgroundColor};
  }
  .tox .tox-comment {
    background: ${theme.canvasBackgroundColor};
    border-color: ${theme.canvasBorderColor};
    box-shadow: 0 4px 8px 0 rgba(45, 59, 69, 0.1);
  }
  .tox .tox-comment__header {
    color: ${theme.canvasTextColor};
  }
  .tox .tox-comment__date {
    color: rgba(45, 59, 69, 0.6);
  }
  .tox .tox-comment__body {
    color: ${theme.canvasTextColor};
  }
  .tox .tox-comment__expander p {
    color: rgba(45, 59, 69, 0.6);
  }
  .tox .tox-comment-thread__overlay::after {
    background: ${theme.canvasBackgroundColor};
  }
  .tox .tox-comment__overlay {
    background: ${theme.canvasBackgroundColor};
  }
  .tox .tox-comment__loading-text {
    color: ${theme.canvasTextColor};
  }
  .tox .tox-comment__overlaytext p {
    background-color: ${theme.canvasBackgroundColor};
    color: ${theme.canvasTextColor};
  }
  .tox .tox-comment__busy-spinner {
    background-color: ${theme.canvasBackgroundColor};
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
    background-color: ${theme.canvasBackgroundColor};
    border-color: ${theme.canvasBorderColor};
    box-shadow: ${theme.canvasModalShadow};
  }
  .tox .tox-dialog__header {
    background-color: ${theme.canvasBackgroundColor};
    color: ${theme.canvasTextColor};
    border-bottom: 1px solid ${theme.canvasBorderColor};
    padding: ${theme.canvasModalHeadingPadding};
    margin: 0;
  }
  .tox .tox-dialog__title {
    font-family: ${theme.canvasFontFamily};
    font-size: ${theme.canvasModalHeadingFontSize};
    font-weight: ${theme.canvasModalHeadingFontWeight};
  }
  .tox .tox-dialog__body {
    color: ${theme.canvasTextColor};
    padding: ${theme.canvasModalBodyPadding};
  }
  .tox .tox-dialog__body-nav-item {
    color: rgba(45, 59, 69, 0.75);
  }
  .tox .tox-dialog__body-nav-item:focus {
    box-shadow: ${theme.canvasFocusBoxShadow};
  }
  .tox .tox-dialog__body-nav-item--active {
    border-bottom-color: ${theme.canvasBrandColor};
    color: ${theme.canvasBrandColor};
  }
  .tox .tox-dialog__footer {
    background-color: ${theme.canvasModalFooterBackground};
    border-top: 1px solid ${theme.canvasBorderColor};
    padding: ${theme.canvasModalFooterPadding};
    margin: 0;
  }
  .tox .tox-dialog__table tbody tr {
    border-bottom-color: ${theme.canvasBorderColor};
  }
  .tox .tox-dropzone {
    background: ${theme.canvasBackgroundColor};
    border: 2px dashed ${theme.canvasBorderColor};
  }
  .tox .tox-dropzone p {
    color: rgba(45, 59, 69, 0.6);
  }
  .tox .tox-edit-area {
    border: 1px solid ${theme.canvasBorderColor};
    border-radius: 3px;
  }
  .tox .tox-edit-area__iframe {
    background-color: ${theme.canvasBackgroundColor};
    border: ${theme.canvasFocusBorderWidth} solid transparent;
  }
  .tox.tox-inline-edit-area {
    border-color: ${theme.canvasBorderColor};
  }
  .tox .tox-form__group {
    padding: 2px;
  }
  .tox .tox-control-wrap .tox-textfield {
    padding-right: 32px;
  }
  .tox .tox-control-wrap__status-icon-invalid svg {
    fill: ${theme.canvasErrorColor};
  }
  .tox .tox-control-wrap__status-icon-unknown svg {
    fill: ${theme.canvasWarningColor};
  }
  .tox .tox-control-wrap__status-icon-valid svg {
    fill: ${theme.canvasSuccessColor};
  }
  .tox .tox-color-input span {
    border-color: rgba(45, 59, 69, 0.2);
  }
  .tox .tox-color-input span:focus {
    border-color: ${theme.canvasBrandColor};
  }
  .tox .tox-label,
  .tox .tox-toolbar-label {
    color: rgba(45, 59, 69, 0.6);
  }
  .tox .tox-form__group {
    margin: ${theme.canvasFormElementMargin};
  }
  .tox .tox-form__group:last-child {
    margin: 0;
  }
  .tox .tox-form__group .tox-label {
    color: ${theme.canvasFormElementLabelColor};
    margin: ${theme.canvasFormElementLabelMargin};
    font-size: ${theme.canvasFormElementLabelFontSize};
    font-weight: ${theme.canvasFormElementLabelFontWeight};
  }
  .tox .tox-form__group--error {
    color: ${theme.canvasErrorColor};
  }
  .tox .tox-textfield,
  .tox .tox-selectfield select,
  .tox .tox-textarea,
  .tox .tox-toolbar-textfield {
    background-color: ${theme.canvasBackgroundColor};
    border-color: ${theme.canvasBorderColor};
    color: ${theme.canvasTextColor};
    font-family: ${theme.canvasFontFamily};
  }
  .tox .tox-textfield:focus,
  .tox .tox-selectfield select:focus,
  .tox .tox-textarea:focus {
    /*border-color: ${theme.canvasFocusBorderColor};*/
    border-color: ${theme.canvasBorderColor};
    box-shadow: ${theme.canvasFocusBoxShadow};
  }
  .tox .tox-naked-btn {
    color: ${theme.canvasButtonColor};
  }
  .tox .tox-naked-btn svg {
    fill: ${theme.canvasButtonColor};
  }
  .tox .tox-insert-table-picker > div {
    border-color: #cccccc;
  }
  .tox .tox-insert-table-picker .tox-insert-table-picker__selected {
    background-color: ${theme.tableSelectorHighlightColor};
    border-color: ${theme.tableSelectorHighlightColor};
  }
  .tox-selected-menu .tox-insert-table-picker {
    background-color: ${theme.canvasBackgroundColor};
  }
  .tox .tox-insert-table-picker__label {
    color: ${theme.canvasTextColor};
  }
  .tox .tox-menu {
    background-color: ${theme.canvasBackgroundColor};
    border-color: ${theme.canvasBorderColor};
  }
  .tox .tox-menubar {
    background-color: ${theme.canvasBackgroundColor};
  }
  .tox .tox-mbtn {
    color: ${theme.canvasButtonColor};
  }
  .tox .tox-mbtn[disabled] {
    opacity: 0.5;
  }
  .tox .tox-mbtn:hover:not(:disabled) {
    background: ${theme.toolbarButtonHoverBackground};
    color: ${theme.canvasButtonColor};
  }
  .tox .tox-mbtn:focus:not(:disabled) {
    background-color: transparent;
    color: ${theme.canvasButtonColor};
    border-color: ${theme.canvasBackgroundColor};
    box-shadow: ${theme.canvasFocusBoxShadow};
  }
  .tox .tox-mbtn--active {
    background: ${theme.toolbarButtonHoverBackground};
    color: ${theme.canvasButtonColor};
  }
  .tox .tox-notification {
    background-color: ${theme.canvasBackgroundColor};
    border-color: #c5c5c5;
  }
  .tox .tox-notification--success {
    background-color: #dff0d8;
    border-color: ${theme.canvasSuccessColor};
  }
  .tox .tox-notification--error {
    background-color: #f2dede;
    border-color: ${theme.canvasErrorColor};
  }
  .tox .tox-notification--warn {
    background-color: #fcf8e3;
    border-color: ${theme.canvasWarningColor};
  }
  .tox .tox-notification--info {
    background-color: #d9edf7;
    border-color: ${theme.canvasInfoColor};
  }
  .tox .tox-notification__body {
    color: ${theme.canvasTextColor};
  }
  .tox .tox-pop__dialog {
    background-color: ${theme.canvasBackgroundColor};
    border-color: ${theme.canvasBorderColor};
  }
  .tox .tox-pop.tox-pop--bottom::before {
    border-color: ${theme.canvasBorderColor} transparent transparent transparent;
  }
  .tox .tox-pop.tox-pop--top::before {
    border-color: transparent transparent ${theme.canvasBorderColor} transparent;
  }
  .tox .tox-pop.tox-pop--left::before {
    border-color: transparent ${theme.canvasBorderColor} transparent transparent;
  }
  .tox .tox-pop.tox-pop--right::before {
    border-color: transparent transparent transparent ${theme.canvasBorderColor};
  }
  .tox .tox-slider {
    width: 100%;
  }
  .tox .tox-slider__rail {
    border-color: ${theme.canvasBorderColor};
  }
  .tox .tox-slider__handle {
    background-color: ${theme.canvasBrandColor};
  }
  .tox .tox-spinner > div {
    background-color: rgba(45, 59, 69, 0.6);
  }
  .tox .tox-tbtn {
    border-style: none;
    color: ${theme.canvasButtonColor};
    position: relative;
  }
  .tox .tox-tbtn svg {
    fill: ${theme.canvasButtonColor};
  }
  .tox .tox-tbtn.tox-tbtn--enabled {
    background: inherit;
  }
  .tox .tox-tbtn:focus,
  .tox .tox-split-button:focus {
    background: ${theme.canvasBackgroundColor};
    color: ${theme.canvasButtonColor};
    box-shadow: ${theme.canvasFocusBoxShadow};
  }
  .tox .tox-tbtn:hover,
  .tox .tox-split-button:hover,
  .tox .tox-tbtn.tox-tbtn--enabled:hover,
  .tox .tox-split-button .tox-tbtn.tox-split-button__chevron:hover {
    background: ${theme.toolbarButtonHoverBackground};
    color: ${theme.canvasButtonColor};
  }
  .tox-tbtn.tox-split-button__chevron {
    position: relative;
  }
  .tox .tox-tbtn.tox-tbtn--enabled::after {
    position: absolute;
    top: -3px;
    content: "\\25BC";
    text-align: center;
    height: 8px;
    font-size: 8px;
    width: 100%;
    color: ${theme.canvasEnabledColor};
  }
  .tox .tox-tbtn.tox-tbtn--enabled.tox-tbtn--select::after {
    text-align: left;
    padding-left: 18px;
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
    /* stylelint-disable-line no-descending-specificity */
    opacity: 0.5;
  }
  .tox .tox-tbtn__select-chevron svg {
    fill: ${theme.canvasButtonColor};
    width: 10px;
    height: 10px;
  }
  .tox .tox-split-button__chevron svg {
    fill: ${theme.canvasButtonColor};
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
    background-color: ${theme.canvasBackgroundColor};
    border-top: 1px solid ${theme.canvasBorderColor};
  }
  .tox .tox-toolbar__group:not(:last-of-type) {
    border-right: 1px solid ${theme.canvasBorderColor};
  }
  .tox .tox-tooltip__body {
    background-color: ${theme.canvasTextColor};
    box-shadow: 0 2px 4px rgba(45, 59, 69, 0.3);
    color: rgba(255, 255, 255, 0.75);
  }
  .tox .tox-tooltip--down .tox-tooltip__arrow {
    border-top-color: ${theme.canvasTextColor};
  }
  .tox .tox-tooltip--up .tox-tooltip__arrow {
    border-bottom-color: ${theme.canvasTextColor};
  }
  .tox .tox-tooltip--right .tox-tooltip__arrow {
    border-left-color: ${theme.canvasTextColor};
  }
  .tox .tox-tooltip--left .tox-tooltip__arrow {
    border-right-color: ${theme.canvasTextColor};
  }
  .tox .tox-well {
    border-color: ${theme.canvasBorderColor};
  }
  .tox .tox-custom-editor {
    border-color: ${theme.canvasBorderColor};
  }
  .tox a {
    color: ${theme.canvasLinkColor};
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
  .tox:not([dir=rtl]) .tox-toolbar__group:not(:last-of-type),
  .tox[dir=rtl] .tox-toolbar__group:not(:last-of-type) {
    border-style: none;
  }
  .tox-toolbar .tox-toolbar__group::after,
  .tox-toolbar-overlord .tox-toolbar__group::after,
  .tox-toolbar__overflow .tox-toolbar__group::after,
  .tox-tinymce-aux .tox-toolbar .tox-toolbar__group::after {
    /* popup toolbar */
    content: "";
    display: inline-block;
    box-sizing: border-box;
    border-inline-end: 1px solid ${theme.canvasBorderColor};
    width: 8px;
    height: 24px;
  }
  .tox-toolbar .tox-toolbar__group:last-child::after,
  .tox-toolbar-overlord .tox-toolbar__group:last-child::after,
  .tox-toolbar__overflow .tox-toolbar__group:last-child::after,
  .tox-tinymce-aux .tox-toolbar .tox-toolbar__group:last-child::after {
    border-inline-end-width: 0;
    padding-inline-start: 0;
    width: 0;
  }
  .tox .tox-tbtn--bespoke .tox-tbtn__select-label {
    width: auto;
    padding-inline-end: 0;
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
  .tox .tox-split-button .tox-tbtn.tox-split-button__chevron {
    margin-inline-start: 0;
  }
  .tox .tox-edit-area.active,
  .tox .tox-edit-area.active iframe {
    border-color: ${theme.canvasFocusBorderColor};
  }
  .tox .tox-split-button .tox-tbtn {
    margin-inline-end: 0;
  }
  .tox .tox-split-button .tox-tbtn.tox-split-button__chevron {
    margin-inline-start: -6px;
    background-color: ${theme.canvasBackgroundColor};
    /* Increases touch-target width of split-button dropdowns for MAT-602 */
    width: 30px;
  }
  .tox .tox-split-button:hover {
    box-shadow: none;
  }
  .tox .tox-split-button:hover .tox-split-button__chevron {
    background: ${theme.canvasBackgroundColor};
    color: ${theme.canvasButtonColor};
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
    outline-color: ${theme.canvasFocusBorderColor};
  }
  .tox .tox-toolbar-overlord .tox-toolbar__overflow {
    /* Remove the errant gray line below the expanded toolbar in "sliding" mode */
    background: none;
  }
  `
  return {css, classNames, theme}
}
