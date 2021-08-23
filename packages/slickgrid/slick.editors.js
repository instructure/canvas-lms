/*
 * Copyright (c) 2010 Michael Leibman, http://github.com/mleibman/slickgrid
 *
 * Permission is hereby granted, free of charge, to any person obtaining
 * a copy of this software and associated documentation files (the
 * "Software"), to deal in the Software without restriction, including
 * without limitation the rights to use, copy, modify, merge, publish,
 * distribute, sublicense, and/or sell copies of the Software, and to
 * permit persons to whom the Software is furnished to do so, subject to
 * the following conditions:
 *
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 * NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
 * LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
 * OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
 * WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

import jQuery from 'jquery'
import './slick.core'

/** *
 * Contains basic SlickGrid editors.
 * @module Editors
 * @namespace Slick
 */

;(function($) {
  // register namespace
  $.extend(true, window, {
    Slick: {
      Editors: {
        Text: TextEditor,
        Integer: IntegerEditor,
        Date: DateEditor,
        YesNoSelect: YesNoSelectEditor,
        Checkbox: CheckboxEditor,
        PercentComplete: PercentCompleteEditor,
        LongText: LongTextEditor,
        UploadGradeCellEditor
      }
    }
  })

  function TextEditor(args) {
    let $input
    let defaultValue
    const scope = this

    this.init = function() {
      $input = $("<INPUT type=text class='editor-text' />")
        .appendTo(args.container)
        .bind('keydown.nav', e => {
          if (e.keyCode === $.ui.keyCode.LEFT || e.keyCode === $.ui.keyCode.RIGHT) {
            e.stopImmediatePropagation()
          }
        })
        .focus()
        .select()
    }

    this.destroy = function() {
      $input.remove()
    }

    this.focus = function() {
      $input.focus()
    }

    this.getValue = function() {
      return $input.val()
    }

    this.setValue = function(val) {
      $input.val(val)
    }

    this.loadValue = function(item) {
      defaultValue = item[args.column.field] || ''
      $input.val(defaultValue)
      $input[0].defaultValue = defaultValue
      $input.select()
    }

    this.serializeValue = function() {
      return $input.val()
    }

    this.applyValue = function(item, state) {
      item[args.column.field] = state
    }

    this.isValueChanged = function() {
      return !($input.val() == '' && defaultValue == null) && $input.val() != defaultValue
    }

    this.validate = function() {
      if (args.column.validator) {
        const validationResults = args.column.validator($input.val())
        if (!validationResults.valid) {
          return validationResults
        }
      }

      return {
        valid: true,
        msg: null
      }
    }

    this.init()
  }

  function IntegerEditor(args) {
    let $input
    let defaultValue
    const scope = this

    this.init = function() {
      $input = $("<INPUT type=text class='editor-text' />")

      $input.bind('keydown.nav', e => {
        if (e.keyCode === $.ui.keyCode.LEFT || e.keyCode === $.ui.keyCode.RIGHT) {
          e.stopImmediatePropagation()
        }
      })

      $input.appendTo(args.container)
      $input.focus().select()
    }

    this.destroy = function() {
      $input.remove()
    }

    this.focus = function() {
      $input.focus()
    }

    this.loadValue = function(item) {
      defaultValue = item[args.column.field]
      $input.val(defaultValue)
      $input[0].defaultValue = defaultValue
      $input.select()
    }

    this.serializeValue = function() {
      return parseInt($input.val(), 10) || 0
    }

    this.applyValue = function(item, state) {
      item[args.column.field] = state
    }

    this.isValueChanged = function() {
      return !($input.val() == '' && defaultValue == null) && $input.val() != defaultValue
    }

    this.validate = function() {
      if (isNaN($input.val())) {
        return {
          valid: false,
          msg: 'Please enter a valid integer'
        }
      }

      return {
        valid: true,
        msg: null
      }
    }

    this.init()
  }

  function DateEditor(args) {
    let $input
    let defaultValue
    const scope = this
    let calendarOpen = false

    this.init = function() {
      $input = $("<INPUT type=text class='editor-text' />")
      $input.appendTo(args.container)
      $input.focus().select()
      $input.datepicker({
        showOn: 'button',
        buttonImageOnly: true,
        buttonImage: '../images/calendar.gif',
        beforeShow() {
          calendarOpen = true
        },
        onClose() {
          calendarOpen = false
        }
      })
      $input.width($input.width() - 18)
    }

    this.destroy = function() {
      $.datepicker.dpDiv.stop(true, true)
      $input.datepicker('hide')
      $input.datepicker('destroy')
      $input.remove()
    }

    this.show = function() {
      if (calendarOpen) {
        $.datepicker.dpDiv.stop(true, true).show()
      }
    }

    this.hide = function() {
      if (calendarOpen) {
        $.datepicker.dpDiv.stop(true, true).hide()
      }
    }

    this.position = function(position) {
      if (!calendarOpen) {
        return
      }
      $.datepicker.dpDiv.css('top', position.top + 30).css('left', position.left)
    }

    this.focus = function() {
      $input.focus()
    }

    this.loadValue = function(item) {
      defaultValue = item[args.column.field]
      $input.val(defaultValue)
      $input[0].defaultValue = defaultValue
      $input.select()
    }

    this.serializeValue = function() {
      return $input.val()
    }

    this.applyValue = function(item, state) {
      item[args.column.field] = state
    }

    this.isValueChanged = function() {
      return !($input.val() == '' && defaultValue == null) && $input.val() != defaultValue
    }

    this.validate = function() {
      return {
        valid: true,
        msg: null
      }
    }

    this.init()
  }

  function YesNoSelectEditor(args) {
    let $select
    let defaultValue
    const scope = this

    this.init = function() {
      $select = $(
        "<SELECT tabIndex='0' class='editor-yesno'><OPTION value='yes'>Yes</OPTION><OPTION value='no'>No</OPTION></SELECT>"
      )
      $select.appendTo(args.container)
      $select.focus()
    }

    this.destroy = function() {
      $select.remove()
    }

    this.focus = function() {
      $select.focus()
    }

    this.loadValue = function(item) {
      $select.val((defaultValue = item[args.column.field]) ? 'yes' : 'no')
      $select.select()
    }

    this.serializeValue = function() {
      return $select.val() == 'yes'
    }

    this.applyValue = function(item, state) {
      item[args.column.field] = state
    }

    this.isValueChanged = function() {
      return $select.val() != defaultValue
    }

    this.validate = function() {
      return {
        valid: true,
        msg: null
      }
    }

    this.init()
  }

  function CheckboxEditor(args) {
    let $select
    let defaultValue
    const scope = this

    this.init = function() {
      $select = $("<INPUT type=checkbox value='true' class='editor-checkbox' hideFocus>")
      $select.appendTo(args.container)
      $select.focus()
    }

    this.destroy = function() {
      $select.remove()
    }

    this.focus = function() {
      $select.focus()
    }

    this.loadValue = function(item) {
      defaultValue = !!item[args.column.field]
      if (defaultValue) {
        $select.prop('checked', true)
      } else {
        $select.prop('checked', false)
      }
    }

    this.serializeValue = function() {
      return $select.prop('checked')
    }

    this.applyValue = function(item, state) {
      item[args.column.field] = state
    }

    this.isValueChanged = function() {
      return this.serializeValue() !== defaultValue
    }

    this.validate = function() {
      return {
        valid: true,
        msg: null
      }
    }

    this.init()
  }

  function PercentCompleteEditor(args) {
    let $input, $picker
    let defaultValue
    const scope = this

    this.init = function() {
      $input = $("<INPUT type=text class='editor-percentcomplete' />")
      $input.width($(args.container).innerWidth() - 25)
      $input.appendTo(args.container)

      $picker = $("<div class='editor-percentcomplete-picker' />").appendTo(args.container)
      $picker.append(
        "<div class='editor-percentcomplete-helper'><div class='editor-percentcomplete-wrapper'><div class='editor-percentcomplete-slider' /><div class='editor-percentcomplete-buttons' /></div></div>"
      )

      $picker
        .find('.editor-percentcomplete-buttons')
        .append(
          '<button val=0>Not started</button><br/><button val=50>In Progress</button><br/><button val=100>Complete</button>'
        )

      $input.focus().select()

      $picker.find('.editor-percentcomplete-slider').slider({
        orientation: 'vertical',
        range: 'min',
        value: defaultValue,
        slide(event, ui) {
          $input.val(ui.value)
        }
      })

      $picker.find('.editor-percentcomplete-buttons button').bind('click', function(e) {
        $input.val($(this).attr('val'))
        $picker.find('.editor-percentcomplete-slider').slider('value', $(this).attr('val'))
      })
    }

    this.destroy = function() {
      $input.remove()
      $picker.remove()
    }

    this.focus = function() {
      $input.focus()
    }

    this.loadValue = function(item) {
      $input.val((defaultValue = item[args.column.field]))
      $input.select()
    }

    this.serializeValue = function() {
      return parseInt($input.val(), 10) || 0
    }

    this.applyValue = function(item, state) {
      item[args.column.field] = state
    }

    this.isValueChanged = function() {
      return (
        !($input.val() == '' && defaultValue == null) &&
        (parseInt($input.val(), 10) || 0) != defaultValue
      )
    }

    this.validate = function() {
      if (isNaN(parseInt($input.val(), 10))) {
        return {
          valid: false,
          msg: 'Please enter a valid positive number'
        }
      }

      return {
        valid: true,
        msg: null
      }
    }

    this.init()
  }

  /*
   * An example of a "detached" editor.
   * The UI is added onto document BODY and .position(), .show() and .hide() are implemented.
   * KeyDown events are also handled to provide handling for Tab, Shift-Tab, Esc and Ctrl-Enter.
   */
  function LongTextEditor(args) {
    let $input, $wrapper
    let defaultValue
    const scope = this

    this.init = function() {
      const $container = $('body')

      $wrapper = $(
        "<DIV style='z-index:10000;position:absolute;background:white;padding:5px;border:3px solid gray; -moz-border-radius:10px; border-radius:10px;'/>"
      ).appendTo($container)

      $input = $(
        "<TEXTAREA hidefocus rows=5 style='backround:white;width:250px;height:80px;border:0;outline:0'>"
      ).appendTo($wrapper)

      $(
        "<DIV style='text-align:right'><BUTTON>Save</BUTTON><BUTTON>Cancel</BUTTON></DIV>"
      ).appendTo($wrapper)

      $wrapper.find('button:first').bind('click', this.save)
      $wrapper.find('button:last').bind('click', this.cancel)
      $input.bind('keydown', this.handleKeyDown)

      scope.position(args.position)
      $input.focus().select()
    }

    this.handleKeyDown = function(e) {
      if (e.which == $.ui.keyCode.ENTER && e.ctrlKey) {
        scope.save()
      } else if (e.which == $.ui.keyCode.ESCAPE) {
        e.preventDefault()
        scope.cancel()
      } else if (e.which == $.ui.keyCode.TAB && e.shiftKey) {
        e.preventDefault()
        args.grid.navigatePrev()
      } else if (e.which == $.ui.keyCode.TAB) {
        e.preventDefault()
        args.grid.navigateNext()
      }
    }

    this.save = function() {
      args.commitChanges()
    }

    this.cancel = function() {
      $input.val(defaultValue)
      args.cancelChanges()
    }

    this.hide = function() {
      $wrapper.hide()
    }

    this.show = function() {
      $wrapper.show()
    }

    this.position = function(position) {
      $wrapper.css('top', position.top - 5).css('left', position.left - 5)
    }

    this.destroy = function() {
      $wrapper.remove()
    }

    this.focus = function() {
      $input.focus()
    }

    this.loadValue = function(item) {
      $input.val((defaultValue = item[args.column.field]))
      $input.select()
    }

    this.serializeValue = function() {
      return $input.val()
    }

    this.applyValue = function(item, state) {
      item[args.column.field] = state
    }

    this.isValueChanged = function() {
      return !($input.val() == '' && defaultValue == null) && $input.val() != defaultValue
    }

    this.validate = function() {
      return {
        valid: true,
        msg: null
      }
    }

    this.init()
  }

  function UploadGradeCellEditor(args) {
    let $container = args.container,
      columnDef = args.column,
      value = args.item[columnDef.id]

    if (columnDef.active) {
      value = value || {}
      var $input
      let defaultValue

      if (columnDef.editorFormatter === 'custom_column') {
        defaultValue = value.new_content
      } else if (columnDef.editorFormatter === 'override_score') {
        defaultValue = value.new_score
      } else {
        defaultValue = value.grade
      }

      const scope = this

      this.init = function() {
        switch (columnDef.grading_type) {
          case 'letter_grade':
            var letterGrades = [
              {text: '--', value: ''},
              {text: 'A', value: 'A'},
              {text: 'A-', value: 'A-'},
              {text: 'B+', value: 'B+'},
              {text: 'B', value: 'B'},
              {text: 'B-', value: 'B-'},
              {text: 'C+', value: 'C+'},
              {text: 'C-', value: 'C-'},
              {text: 'D+', value: 'D+'},
              {text: 'D', value: 'D'},
              {text: 'D-', value: 'D-'},
              {text: 'F', value: 'F'}
            ]
            var outputString = ''
            $.each(letterGrades, function() {
              outputString += `<option value="${this.value}" ${
                this.value === value.grade ? 'selected' : ''
              }>${this.text}</option>`
            })
            $input = $(`<select>${outputString}</select>`)
            break

          default:
            $input = $("<INPUT type=text class='editor-text' />")
        }

        // if there is something typed in to the grade,
        // can't do if (value.grade) because if they had a grade of 0 it would break.
        if (typeof value.grade !== 'undefined' && `${value.grade}` !== '') {
          if (typeof columnDef.editorFormatter === 'function') {
            $input[0].defaultValue = columnDef.editorFormatter(value.grade)
            $input.val($input[0].defaultValue)
          } else {
            $input[0].defaultValue = value.grade
            $input.val(defaultValue)
          }
        } else if (columnDef.editorFormatter === 'custom_column') {
          $input[0].defaultValue = value.new_content
          $input.val(defaultValue)
        } else if (columnDef.editorFormatter === 'override_score') {
          $input[0].defaultValue = value.new_score
          $input.val(defaultValue)
        }

        $input.appendTo($container)
        $input.focus().select()

        if (typeof value.uploaded_grade === 'undefined') {
          value.uploaded_grade = value.grade
        }
      }
      this.serializeValue = function serializeValue() {
        return $input.val()
      }

      this.loadValue = function() {}

      this.destroy = function() {
        $input.remove()
      }

      this.focus = function() {
        $input.focus()
      }

      this.applyValue = function(item, state) {
        if (typeof columnDef.editorParser === 'function') {
          item[columnDef.id].grade = columnDef.editorParser(state)
        } else if (columnDef.editorParser === 'custom_column') {
          item[columnDef.id].new_content = state
        } else if (columnDef.editorParser === 'override_score') {
          item[columnDef.id].new_score = state
        } else {
          item[columnDef.id].grade = state
        }
      }

      this.getValue = function() {
        return $input.val()
      }

      this.isValueChanged = function() {
        return !($input.val() === '' && defaultValue == null) && $input.val() !== defaultValue
      }

      this.validate = function() {
        if (columnDef.validator) {
          const validationResults = columnDef.validator(scope.getValue())
          if (!validationResults.valid) return validationResults
        }

        return {
          valid: true,
          msg: null
        }
      }

      this.init()
    } else {
      var $input
      this.init = function() {
        const html = value ? value.grade : ''
        $container.removeClass('selected editable').html(html)
      }

      this.destroy = function() {}

      this.focus = function() {}

      this.setValue = function() {}

      this.getValue = function() {
        return value
      }

      this.isValueChanged = function() {
        return false
      }

      this.validate = function() {
        return {
          valid: true,
          msg: null
        }
      }

      this.init()
    }
  }
})(jQuery)
