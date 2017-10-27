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

import _ from 'underscore'
import React from 'react'
import PropTypes from 'prop-types'
import $ from 'jquery'
import I18n from 'i18n!dashcards'
import ColorPicker from 'jsx/shared/ColorPicker'
import DOMElement from 'jsx/shared/proptypes/DOMElement'
import cx from 'classnames'

  // ================
  //   COLOR PICKER
  // ================

  var SPACE_NEEDED_FOR_TOOLTIP = 300;

  var DashboardColorPicker = React.createClass({

    propTypes: {
      elementID: PropTypes.string,
      isOpen: PropTypes.bool,
      settingsToggle: DOMElement
    },

    getDefaultProps () {
      return {
        elementID: '',
        isOpen: false,
        settingsToggle: null
      }
    },

    // =================
    //     LIFECYCLE
    // =================

    componentDidMount: function () {
      this.setHandlers();
    },

    componentWillUnmount: function() {
      this.unsetHandlers();
    },

    // =================
    //      ACTIONS
    // =================

    closeIfClickedOutsideOf: function(e){
      if (this.isMounted()) {

        const settingsToggle = this.props.settingsToggle;
        if (!$.contains(this.container, e.target) && !$.contains(settingsToggle, e.target) && this.props.isOpen) {
          this.props.doneEditing(e);
        }
      }
    },

    checkEsc: function(e){
      if (e.keyCode != 27) {
        return
      }
      if (this.isMounted()) {
        if ($.contains(this.container, document.activeElement) && this.props.isOpen) {
          this.props.doneEditing(e);
        }
      }
    },

    setHandlers: function(){
      $(window).resize( this.props.doneEditing );
      $(document).mouseup(this.closeIfClickedOutsideOf);
      $(document).keyup(this.checkEsc);
    },

    unsetHandlers: function(){
      $(document).unbind("keyup", this.checkEsc);
      $(document).unbind("mouseup", this.closeIfClickedOutsideOf);
      $(window).unbind("resize", this.props.doneEditing);
    },

    // =================
    //     RENDERING
    // =================

    rightOfScreen: function(){
      return $(window).width();
    },

    leftPlusElement: function(){
      var parentWidth = $(this.props.parentNode).outerWidth();
      return $(this.props.parentNode).offset().left + parentWidth;
    },

    tooltipOnRight: function(){
      var spaceToRight = this.rightOfScreen() - this.leftPlusElement();
      var spaceNeeded = SPACE_NEEDED_FOR_TOOLTIP;
      return spaceToRight >= spaceNeeded;
    },

    topPosition: function(){
      return $(this.props.parentNode).position().top + 82;
    },

    leftPosition: function(){
      return this.tooltipOnRight() ?
        (this.leftPlusElement()) :
        (this.leftPlusElement() - 360)
    },

    pickerToolTipStyle: function() {
      if (this.props.isOpen) {
        return {
          position: 'fixed',
          top: this.topPosition(),
          left: this.leftPosition(),
          zIndex: 9999
        };
      } else {
        return {
          display: 'none'
        };
      }
    },

    render: function () {
      var classes = cx({
        'ic-DashboardCardColorPicker': true,
        'right': this.isOpen && !this.tooltipOnRight(),
        'horizontal': true
      });

      return (
        <div
          id={this.props.elementID}
          className={classes}
          style={this.pickerToolTipStyle()}
          ref={(c) => { this.container = c; }}
        >
          <ColorPicker isOpen           = {this.props.isOpen}
                       assetString      = {this.props.assetString}
                       afterClose       = {this.props.doneEditing}
                       afterUpdateColor = {this.props.handleColorChange}
                       hidePrompt       = {true}
                       nonModal         = {true}
                       hideOnScroll     = {false}
                       currentColor     = {this.props.backgroundColor}
                       nicknameInfo     = {this.props.nicknameInfo}
                       parentComponent  = "DashboardColorPicker"
          />
        </div>
      )
    }
  })

export default DashboardColorPicker
