/*
 * Copyright (C) 2013 - present Instructure, Inc.
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

import $ from 'jquery';
import 'jqueryui/menu';
import I18n from 'i18n!LongTextEditor';
import htmlEscape from './str/htmlEscape';
/*
 * this is just LongTextEditor from slick.editors.js but with i18n and a
 * stupid dontblur class to cooperate with our gradebook's onGridBlur handler
 */
function LongTextEditor (args) {
  let $input;
  let $wrapper;
  let $saveButton;
  let $cancelButton;
  let defaultValue;
  const scope = this;

  this.init = function () {
    const $container = args.alt_container ? $(args.alt_container) : $('body');

    $wrapper = $('<div/>')
      .addClass('dontblur')
      .css({
        'z-index': 10000,
        position: 'absolute',
        background: 'white',
        padding: '5px',
        border: '3px solid gray',
        '-moz-border-radius': '10px',
        'border-radius': '10px'
      })
      .appendTo($container);
    $input = $('<textarea hidefocus rows="5"/>')
      .attr('maxlength', htmlEscape(args.maxLength))
      .css({
        backround: 'white',
        width: '250px',
        height: '80px',
        border: 0,
        outline: 0
      })
      .appendTo($wrapper);

    const buttonContainer = $('<div/>')
      .css({
        'text-align': 'right'
      })
      .appendTo($wrapper);
    const saveText = I18n.t('save', 'Save');
    const cancelText = I18n.t('cancel', 'Cancel');
    $saveButton = $('<button/>').append(htmlEscape(saveText)).appendTo(buttonContainer);
    $cancelButton = $('<button/>').append(htmlEscape(cancelText)).appendTo(buttonContainer);

    $saveButton.click(this.save);
    $cancelButton.click(this.cancel);
    $wrapper.keydown(this.handleKeyDown);

    scope.position(args.position);
    $input.focus().select();
  };

  this.handleKeyDown = function (event) {
    const keyCode = event.which;
    const target = event.target;

    if (target === $input.get(0)) {
      if (keyCode === $.ui.keyCode.ENTER && event.ctrlKey) {
        event.preventDefault();
        scope.save();
      } else if (keyCode === $.ui.keyCode.ESCAPE) {
        event.preventDefault();
        scope.cancel();
      } else if (keyCode === $.ui.keyCode.TAB && event.shiftKey) {
        event.preventDefault();
        args.grid.navigatePrev();
      } else if (keyCode === $.ui.keyCode.TAB && !event.shiftKey) {
        // This explicit focus shifting allows JS specs to pass
        event.preventDefault();
        $saveButton.focus();
      }
    } else if (target === $saveButton.get(0)) {
      if (keyCode === $.ui.keyCode.TAB && event.shiftKey) {
        event.preventDefault();
        $input.focus();
      } else if (keyCode === $.ui.keyCode.TAB && !event.shiftKey) {
        // This explicit focus shifting allows JS specs to pass
        event.preventDefault();
        $cancelButton.focus();
      }
    } else if (target === $cancelButton.get(0)) {
      if (keyCode === $.ui.keyCode.TAB && event.shiftKey) {
        event.preventDefault();
        $saveButton.focus();
      } else if (keyCode === $.ui.keyCode.TAB && !event.shiftKey) {
        // This explicit focus shifting allows JS specs to pass
        event.preventDefault();
        args.grid.navigateNext();
      }
    }
  };

  this.save = function () {
    args.commitChanges();
  };

  this.cancel = function () {
    $input.val(defaultValue);
    args.cancelChanges();
  };

  this.hide = function () {
    $wrapper.hide();
  };

  this.show = function () {
    $wrapper.show();
  };

  this.position = function () {
    $wrapper.position({
      my: 'center top',
      at: 'center top',
      of: args.container
    })
  };

  this.destroy = function () {
    $wrapper.remove();
  };

  this.focus = function () {
    $input.focus();
  };

  this.loadValue = function (item) {
    $input.val(defaultValue = item[args.column.field]);
    $input.select();
  };

  this.serializeValue = function () {
    return $input.val();
  };

  this.applyValue = function (item, state) {
    item[args.column.field] = state;
  };

  this.isValueChanged = function () {
    return (!($input.val() === '' && defaultValue == null)) && ($input.val() !== defaultValue);
  };

  this.validate = function () {
    return {
      valid: true,
      msg: null
    };
  };

  this.init();
}

export default LongTextEditor;
