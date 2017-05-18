/*
 * Copyright (C) 2015 - present Instructure, Inc.
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
import customTypes from './PropTypes'
import I18n from 'i18n!theme_editor'
import rgb2hex from 'compiled/util/rgb2hex'
import classnames from 'classnames'

export default React.createClass({

    displayName: 'ThemeEditorColorRow',

    propTypes: {
      varDef: customTypes.color,
      onChange: PropTypes.func.isRequired,
      userInput: customTypes.userVariableInput,
      placeholder: PropTypes.string.isRequired
    },

    getDefaultProps(){
      return ({
        userInput: {}
      })
    },

    getInitialState(){
      return {};
    },

    showWarning(){
      return this.props.userInput.invalid && this.inputNotFocused()
    },

    warningLabel(){
      if (this.showWarning()) {
        return(
          <span role="alert">
            <div className="ic-Form-message ic-Form-message--error" tabIndex="0">
              <div className="ic-Form-message__Layout">
                <i className="icon-warning" role="presentation"></i>
                {I18n.t("'%{chosenColor}' is not a valid color.", {chosenColor: this.props.userInput.val})}
              </div>
            </div>
          </span>
        )
      } else {
        // must return empty alert span so screenreaders
        // read the error when it is inserted
        return <span role="alert" />
      }
    },

    changedColor(value) {
      var color = $('<span>').css('background-color', value).css('background-color');
       // FF returns 'transparent' for invalid colors, but we allow intentionally setting a value to 'transparent'
      var isInvalid = (color === 'transparent' && value !== 'transparent');

      return  isInvalid ? null : color
    },

    hexVal(colorString) {
      var rgbVal = this.changedColor(colorString);
      // rgb2hex will fail if rgbVal is null or undefined
      return rgbVal ? (rgb2hex(rgbVal) || rgbVal) : '';
    },

    invalidHexString(colorString) {
      return colorString.match(/#/) ?
        !colorString.match(/^#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})$/) :
        false
    },

    inputChange(value) {
      var invalidColor = !!value && (!this.changedColor(value) || this.invalidHexString(value));
      this.props.onChange(value, invalidColor);
    },

    inputNotFocused() {
      return this.refs.textInput && this.refs.textInput.getDOMNode() != document.activeElement
    },

    updateIfMounted() {
      if (this.isMounted()) {
        this.forceUpdate()
      }
    },

    textColorInput(){
      var inputClasses = classnames({
        'Theme__editor-color-block_input-text': true,
        'Theme__editor-color-block_input': true,
        'Theme__editor-color-block_input--has-error': this.props.userInput.invalid
      });

      var colorVal = this.props.userInput.val != null ? this.props.userInput.val : this.props.currentValue

      // 1st input is hidden and posts a valid hex value
      // 2nd input handles display, input events, and validation
      return(
        <span>
          <input
              type="hidden"
              name={'brand_config[variables]['+ this.props.varDef.variable_name +']'}
              value={this.hexVal(colorVal)} />
          <input
              ref="textInput"
              type="text"
              id={'brand_config[variables]['+ this.props.varDef.variable_name +']'}
              className={inputClasses}
              placeholder={this.props.placeholder}
              value={colorVal}
              aria-invalid={this.showWarning()}
              onChange={event => this.inputChange(event.target.value) }
              onBlur={this.updateIfMounted} />
        </span>
      );
    },

    render() {
      var colorInputValue = (this.props.placeholder !== "none") ? this.props.placeholder : null;
      return (
        <section className="Theme__editor-accordion_element Theme__editor-color ic-Form-control">
          <div className="Theme__editor-form--color">
            <label
              htmlFor={'brand_config[variables]['+ this.props.varDef.variable_name +']'}
              className="Theme__editor-color_title"
            >
              {this.props.varDef.human_name}
            </label>
            <div className="Theme__editor-color-block">
              {this.textColorInput()}
              {this.warningLabel()}
              <label className="Theme__editor-color-label Theme__editor-color-block_label-sample" style={{backgroundColor: this.props.placeholder}}
                /* this <label> and <input type=color> are here so if you click the 'sample',
                it will pop up a color picker on browsers that support it */
              >
                <input
                  className="Theme__editor-color-block_input-sample Theme__editor-color-block_input"
                  type="color"
                  ref="colorpicker"
                  value={colorInputValue}
                  role="presentation-only"
                  onChange={event => this.inputChange(event.target.value) } />
              </label>
            </div>
          </div>
        </section>
      )
    }
  })
