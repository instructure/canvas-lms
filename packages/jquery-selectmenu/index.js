/* eslint-disable  no-useless-concat */
/* eslint-disable  vars-on-top */
/* eslint-disable  no-var */
/* eslint-disable  block-scoped-var */
/* eslint-disable  no-restricted-globals */
/*
 * jQuery UI selectmenu dev version
 *
 * Copyright (c) 2009 AUTHORS.txt (http://jqueryui.com/about)
 * Dual licensed under the MIT (MIT-LICENSE.txt)
 * and GPL (GPL-LICENSE.txt) licenses.
 *
 * http://docs.jquery.com/UI
 * https://github.com/fnagel/jquery-ui/wiki/Selectmenu
 */

import $ from 'jquery'
import 'jquery-scroll-to-visible/jquery.scrollTo'
import 'jqueryui/widget'

$.widget('ui.selectmenu', {
  getter: 'value',
  version: '1.9',
  eventPrefix: 'selectmenu',
  options: {
    transferClasses: true,
    appendTo: 'body',
    typeAhead: 1000,
    style: 'dropdown',
    positionOptions: {
      my: 'left top',
      at: 'left bottom',
      offset: null,
    },
    width: null,
    menuWidth: null,
    handleWidth: 26,
    maxHeight: null,
    icons: null,
    format: null,
    escapeHtml: false,
    bgImage() {},
  },

  _create() {
    const self = this,
      o = this.options

    // set a default id value, generate a new random one if not set by developer
    const selectmenuId = (
      this.element.attr('id') || 'ui-selectmenu-' + Math.random().toString(16).slice(2, 10)
    ).replace(':', '\\:')

    // quick array of button and menu id's
    this.ids = [selectmenuId, selectmenuId + '-button', selectmenuId + '-menu']

    // define safe mouseup for future toggling
    this._safemouseup = true
    this.isOpen = false

    // create menu button wrapper
    this.newelement = $('<a />', {
      class: this.widgetBaseClass + ' ui-widget ui-state-default ui-corner-all',
      id: this.ids[1],
      role: 'button',
      href: '#nogo',
      tabindex: this.element.prop('disabled') ? 1 : 0,
      'aria-haspopup': true,
      'aria-owns': this.ids[2],
    })
    this.newelementWrap = $('<span />').append(this.newelement).insertAfter(this.element)

    // transfer tabindex
    const tabindex = this.element.attr('tabindex')
    if (tabindex) {
      this.newelement.attr('tabindex', tabindex)
    }

    // save reference to select in data for ease in calling methods
    this.newelement.data('selectelement', this.element)

    // menu icon
    this.selectmenuIcon = $(
      '<span class="' + this.widgetBaseClass + '-icon ui-icon"></span>'
    ).prependTo(this.newelement)

    // append status span to button
    this.newelement.prepend('<span class="' + self.widgetBaseClass + '-status" />')

    // make associated form label trigger focus
    this.element.bind({
      'click.selectmenu': function (event) {
        self.newelement.focus()
        event.preventDefault()
      },
    })

    // click toggle for menu visibility
    this.newelement
      .bind('mousedown.selectmenu', function (event) {
        self._toggle(event, true)
        // make sure a click won't open/close instantly
        if (o.style == 'popup') {
          self._safemouseup = false
          setTimeout(function () {
            self._safemouseup = true
          }, 300)
        }
        return false
      })
      .bind('click.selectmenu', function () {
        return false
      })
      .bind('keydown.selectmenu', function (event) {
        let ret = false
        let movement

        switch (event.keyCode) {
          case $.ui.keyCode.ENTER:
            ret = true
            break
          case $.ui.keyCode.SPACE:
            self._toggle(event)
            break
          case $.ui.keyCode.UP:
            if (event.altKey) {
              self.open(event)
            } else {
              self._moveSelection(-1)
            }
            break
          case $.ui.keyCode.DOWN:
            if (event.altKey) {
              self.open(event)
            } else {
              self._moveSelection(1)
            }
            break
          case $.ui.keyCode.LEFT:
            self._moveSelection(-1)
            break
          case $.ui.keyCode.RIGHT:
            self._moveSelection(1)
            break
          case $.ui.keyCode.TAB:
            // This monstrosity of a widget is not part of the page's tabbable
            // elements, and will only be receiving tab events if it's open or
            // was just closed because an item got selected. Preemptively focus
            // the real (hidden) select menu, which is actually tabbable, so
            // that it can decide where to direct the tab. This may be a terrible
            // idea, but it seems to work.

            document.getElementById('students_selectmenu').focus()
            ret = true
            break
          case $.ui.keyCode.PAGE_UP:
          case $.ui.keyCode.HOME:
            movement = self._movementToDirectChild('first')
            if (movement < 0) {
              self._moveSelection(movement)
            }
            break
          case $.ui.keyCode.PAGE_DOWN:
          case $.ui.keyCode.END:
            movement = self._movementToDirectChild('last')
            if (movement > 0) {
              self._moveSelection(movement)
            }
            break
          default:
            ret = true
        }
        return ret
      })
      .bind('keypress.selectmenu', function (event) {
        if (event.which > 0) {
          self._typeAhead(event.which, 'mouseup')
        }
        return true
      })
      .bind('mouseover.selectmenu', function () {
        if (!o.disabled) $(this).addClass('ui-state-hover')
      })
      .bind('mouseout.selectmenu', function () {
        if (!o.disabled) $(this).removeClass('ui-state-hover')
      })
      .bind('focus.selectmenu', function () {
        if (!o.disabled) $(this).addClass('ui-state-focus')
      })
      .bind('blur.selectmenu', function () {
        if (!o.disabled) $(this).removeClass('ui-state-focus')
      })

    // document click closes menu
    $(document).bind('mousedown.selectmenu-' + this.ids[0], function (event) {
      if (self.isOpen) {
        self.close(event)
      }
    })

    // change event on original selectmenu
    this.element
      .bind('click.selectmenu', function () {
        self._refreshValue()
      })
      // FIXME: newelement can be null under unclear circumstances in IE8
      // TODO not sure if this is still a problem (fnagel 20.03.11)
      .bind('focus.selectmenu', function () {
        if (self.newelement) {
          self.newelement[0].focus()
        }
      })

    // set width when not set via options
    if (!o.width) {
      o.width = this.element.outerWidth()
    }
    // set menu button width
    this.newelement.width(o.width)

    // hide original selectmenu element
    this.element.hide()

    // create menu portion, append to body
    this.list = $('<ul />', {
      class: 'ui-widget ui-widget-content',
      'aria-hidden': true,
      role: 'listbox',
      'aria-labelledby': this.ids[1],
      id: this.ids[2],
    })
    this.listWrap = $('<div />', {
      class: self.widgetBaseClass + '-menu',
    })
      .append(this.list)
      .appendTo(o.appendTo)

    // transfer menu click to menu button
    this.list
      .bind('keydown.selectmenu', function (event) {
        let ret = false
        switch (event.keyCode) {
          case $.ui.keyCode.UP:
            if (event.altKey) {
              self.close(event, true)
            } else {
              self._moveFocus(-1)
            }
            break
          case $.ui.keyCode.DOWN:
            if (event.altKey) {
              self.close(event, true)
            } else {
              self._moveFocus(1)
            }
            break
          case $.ui.keyCode.LEFT:
            self._moveFocus(-1)
            break
          case $.ui.keyCode.RIGHT:
            self._moveFocus(1)
            break
          case $.ui.keyCode.HOME:
            self._moveFocus(':first')
            break
          case $.ui.keyCode.PAGE_UP:
            self._scrollPage('up')
            break
          case $.ui.keyCode.PAGE_DOWN:
            self._scrollPage('down')
            break
          case $.ui.keyCode.END:
            self._moveFocus(':last')
            break
          case $.ui.keyCode.ENTER:
          case $.ui.keyCode.SPACE:
            self.close(event, true)
            $(event.target).parents('li:eq(0)').trigger('mouseup')
            break
          case $.ui.keyCode.TAB:
            ret = true
            self.close(event, true)
            $(event.target).parents('li:eq(0)').trigger('mouseup')
            break
          case $.ui.keyCode.ESCAPE:
            self.close(event, true)
            break
          default:
            ret = true
        }
        return ret
      })
      .bind('keypress.selectmenu', function (event) {
        if (event.which > 0) {
          self._typeAhead(event.which, 'focus')
        }
        return true
      })
      // this allows for using the scrollbar in an overflowed list
      .bind('mousedown.selectmenu mouseup.selectmenu', function () {
        return false
      })

    // needed when window is resized
    $(window).bind('resize.selectmenu-' + this.ids[0], $.proxy(self.close, this))
  },

  _init() {
    const self = this,
      o = this.options

    // serialize selectmenu element options
    const selectOptionData = []
    this.element.find('option').each(function () {
      const opt = $(this)
      selectOptionData.push({
        value: opt.attr('value'),
        text: self._formatText(opt.text()),
        selected: opt.prop('selected'),
        disabled: opt.prop('disabled'),
        classes: opt.attr('class'),
        typeahead: opt.attr('typeahead'),
        parentOptGroup: opt.parent('optgroup'),
        bgImage: o.bgImage.call(opt),
      })
    })

    // active state class is only used in popup style
    const activeClass = self.options.style == 'popup' ? ' ui-state-active' : ''

    // empty list so we can refresh the selectmenu via selectmenu()
    this.list.html('')

    // write li's
    if (selectOptionData.length) {
      for (let i = 0; i < selectOptionData.length; i++) {
        const thisLiAttr = {role: 'presentation'}
        if (selectOptionData[i].disabled) {
          thisLiAttr.class = this.namespace + '-state-disabled'
        }
        const thisAAttr = {
          html: selectOptionData[i].text || '&nbsp;',
          href: '#nogo',
          tabindex: -1,
          role: 'option',
          'aria-selected': false,
        }
        if (selectOptionData[i].disabled) {
          thisAAttr['aria-disabled'] = selectOptionData[i].disabled
        }
        if (selectOptionData[i].typeahead) {
          thisAAttr.typeahead = selectOptionData[i].typeahead
        }
        const thisA = $('<a/>', thisAAttr)
        const thisLi = $('<li/>', thisLiAttr)
          .append(thisA)
          .data('index', i)
          .addClass(selectOptionData[i].classes)
          .data('optionClasses', selectOptionData[i].classes || '')
          .bind('mouseup.selectmenu', function (event) {
            if (
              self._safemouseup &&
              !self._disabled(event.currentTarget) &&
              !self._disabled(
                $(event.currentTarget).parents('ul>li.' + self.widgetBaseClass + '-group ')
              )
            ) {
              const changed = $(this).data('index') != self._selectedIndex()
              self.index($(this).data('index'))
              self.select(event)
              if (changed) {
                self.change(event)
              }
              self.close(event, true)
            }
            return false
          })
          .bind('click.selectmenu', function () {
            return false
          })
          .bind('mouseover.selectmenu focus.selectmenu', function (e) {
            // no hover if disabled
            if (
              !$(e.currentTarget).hasClass(self.namespace + '-state-disabled') &&
              !$(e.currentTarget)
                .parent('ul')
                .parent('li')
                .hasClass(self.namespace + '-state-disabled')
            ) {
              self._selectedOptionLi().addClass(activeClass)
              self
                ._focusedOptionLi()
                .removeClass(self.widgetBaseClass + '-item-focus ui-state-hover')
              $(this)
                .removeClass('ui-state-active')
                .addClass(self.widgetBaseClass + '-item-focus ui-state-hover')
            }
          })
          .bind('mouseout.selectmenu blur.selectmenu', function () {
            if ($(this).is(self._selectedOptionLi())) {
              $(this).addClass(activeClass)
            }
            $(this).removeClass(self.widgetBaseClass + '-item-focus ui-state-hover')
          })

        // optgroup or not...
        if (selectOptionData[i].parentOptGroup.length) {
          const optGroupName =
            self.widgetBaseClass +
            '-group-' +
            this.element.find('optgroup').index(selectOptionData[i].parentOptGroup)
          if (this.list.find('li.' + optGroupName).length) {
            this.list.find('li.' + optGroupName + ':last ul').append(thisLi)
          } else {
            $(
              ' <li role="presentation" class="' +
                self.widgetBaseClass +
                '-group ' +
                optGroupName +
                (selectOptionData[i].parentOptGroup.prop('disabled')
                  ? ' ' + this.namespace + '-state-disabled" aria-disabled="true"'
                  : '"') +
                '><span class="' +
                self.widgetBaseClass +
                '-group-label">' +
                selectOptionData[i].parentOptGroup.attr('label') +
                '</span><ul></ul></li> '
            )
              .appendTo(this.list)
              .find('ul')
              .append(thisLi)
          }
        } else {
          thisLi.appendTo(this.list)
        }

        // append icon if option is specified
        if (o.icons) {
          for (const j in o.icons) {
            if (thisLi.is(o.icons[j].find)) {
              thisLi
                .data(
                  'optionClasses',
                  selectOptionData[i].classes + ' ' + self.widgetBaseClass + '-hasIcon'
                )
                .addClass(self.widgetBaseClass + '-hasIcon')
              const iconClass = o.icons[j].icon || ''
              thisLi
                .find('a:eq(0)')
                .prepend(
                  '<span class="' +
                    self.widgetBaseClass +
                    '-item-icon ui-icon ' +
                    iconClass +
                    '"></span>'
                )
              if (selectOptionData[i].bgImage) {
                thisLi.find('span').css('background-image', selectOptionData[i].bgImage)
              }
            }
          }
        }
      }
    } else {
      $('<li role="presentation"><a href="#nogo" tabindex="-1" role="option"></a></li>').appendTo(
        this.list
      )
    }
    // we need to set and unset the CSS classes for dropdown and popup style
    const isDropDown = o.style == 'dropdown'
    this.newelement
      .toggleClass(self.widgetBaseClass + '-dropdown', isDropDown)
      .toggleClass(self.widgetBaseClass + '-popup', !isDropDown)
    this.list
      .toggleClass(self.widgetBaseClass + '-menu-dropdown ui-corner-bottom', isDropDown)
      .toggleClass(self.widgetBaseClass + '-menu-popup ui-corner-all', !isDropDown)
      // add corners to top and bottom menu items
      .find('li:first')
      .toggleClass('ui-corner-top', !isDropDown)
      .end()
      .find('li:last')
      .addClass('ui-corner-bottom')
    this.selectmenuIcon
      .toggleClass('ui-icon-triangle-1-s', isDropDown)
      .toggleClass('ui-icon-triangle-2-n-s', !isDropDown)

    // transfer classes to selectmenu and list
    if (o.transferClasses) {
      const transferClasses = this.element.attr('class') || ''
      this.newelement.add(this.list).addClass(transferClasses)
    }

    // set menu width to either menuWidth option value, width option value, or select width
    if (o.style == 'dropdown') {
      this.list.width(o.menuWidth ? o.menuWidth : o.width)
    } else {
      this.list.width(o.menuWidth ? o.menuWidth : o.width - o.handleWidth)
    }

    // reset height to auto
    this.list.css('height', 'auto')
    const listH = this.listWrap.height()
    const winH = $(window).height()
    // calculate default max height
    const maxH = o.maxHeight ? Math.min(o.maxHeight, winH) : winH / 3
    if (listH > maxH) this.list.height(maxH)

    // save reference to actionable li's (not group label li's)
    this._optionLis = this.list.find('li:not(.' + self.widgetBaseClass + '-group)')

    // transfer disabled state
    if (this.element.prop('disabled')) {
      this.disable()
    } else {
      this.enable()
    }

    // update value
    this.index(this._selectedIndex())

    // set selected item so movefocus has intial state
    this._selectedOptionLi().addClass(this.widgetBaseClass + '-item-focus')

    // needed when selectmenu is placed at the very bottom / top of the page
    clearTimeout(this.refreshTimeout)
    this.refreshTimeout = window.setTimeout(function () {
      self._refreshPosition()
    }, 200)

    this.element.on('change', event => {
      // The real select menu (aka "this.element") is hidden from view but can
      // be accessed via keyboard navigation. Make sure changes to its selection
      // are picked up by the widget.
      this._refreshValue()
    })
  },

  destroy() {
    this.element
      .removeData(this.widgetName)
      .removeClass(this.widgetBaseClass + '-disabled' + ' ' + this.namespace + '-state-disabled')
      .removeAttr('aria-disabled')
      .unbind('.selectmenu')

    $(window).unbind('.selectmenu-' + this.ids[0])
    $(document).unbind('.selectmenu-' + this.ids[0])

    this.newelementWrap.remove()
    this.listWrap.remove()

    // unbind click event and show original select
    this.element.unbind('.selectmenu').show()

    // call widget destroy function
    $.Widget.prototype.destroy.apply(this, arguments)
  },

  _typeAhead(code, eventType) {
    let self = this,
      c = String.fromCharCode(code).toLowerCase(),
      matchee = null,
      nextIndex = null

    // Clear any previous timer if present
    if (self._typeAhead_timer) {
      window.clearTimeout(self._typeAhead_timer)
      self._typeAhead_timer = undefined
    }

    // Store the character typed
    self._typeAhead_chars = (
      self._typeAhead_chars === undefined ? '' : self._typeAhead_chars
    ).concat(c)

    // Detect if we are in cyciling mode or direct selection mode
    if (
      self._typeAhead_chars.length < 2 ||
      (self._typeAhead_chars.substr(-2, 1) === c && self._typeAhead_cycling)
    ) {
      self._typeAhead_cycling = true

      // Match only the first character and loop
      matchee = c
    } else {
      // We won't be cycling anymore until the timer expires
      self._typeAhead_cycling = false

      // Match all the characters typed
      matchee = self._typeAhead_chars
    }

    // We need to determine the currently active index, but it depends on
    // the used context: if it's in the element, we want the actual
    // selected index, if it's in the menu, just the focused one
    // I copied this code from _moveSelection() and _moveFocus()
    // respectively --thg2k
    const selectedIndex =
      (eventType !== 'focus'
        ? this._selectedOptionLi().data('index')
        : this._focusedOptionLi().data('index')) || 0

    for (let i = 0; i < this._optionLis.length; i++) {
      const thisText = this._optionLis.eq(i).text().substr(0, matchee.length).toLowerCase()

      if (thisText === matchee) {
        if (self._typeAhead_cycling) {
          if (nextIndex === null) nextIndex = i

          if (i > selectedIndex) {
            nextIndex = i
            break
          }
        } else {
          nextIndex = i
        }
      }
    }

    if (nextIndex !== null) {
      // Why using trigger() instead of a direct method to select the
      // index? Because we don't what is the exact action to do, it
      // depends if the user is typing on the element or on the popped
      // up menu
      this._optionLis.eq(nextIndex).find('a').trigger(eventType)
    }

    self._typeAhead_timer = window.setTimeout(function () {
      self._typeAhead_timer = undefined
      self._typeAhead_chars = undefined
      self._typeAhead_cycling = undefined
    }, self.options.typeAhead)
  },

  // returns some usefull information, called by callbacks only
  _uiHash() {
    const index = this.index()
    return {
      index,
      option: $('option', this.element).get(index),
      value: this.element[0].value,
    }
  },

  open(event) {
    const self = this,
      o = this.options
    if (self.newelement.attr('aria-disabled') != 'true') {
      self._closeOthers(event)
      self.newelement.addClass('ui-state-active')

      self.listWrap.appendTo(o.appendTo)
      self.list.attr('aria-hidden', false)
      self.listWrap.addClass(self.widgetBaseClass + '-open')

      const selected = this._selectedOptionLi()
      if (o.style == 'dropdown') {
        self.newelement.removeClass('ui-corner-all').addClass('ui-corner-top')
      } else {
        // center overflow and avoid flickering
        this.list
          .css('left', -5000)
          .scrollTop(
            this.list.scrollTop() +
              selected.position().top -
              this.list.outerHeight() / 2 +
              selected.outerHeight() / 2
          )
          .css('left', 'auto')
      }

      self._refreshPosition()

      const link = selected.find('a')
      // update focus classes to match whatever item is selected, since it
      // may have changed since this menu was last open
      this._focusItem(this._selectedOptionLi())
      if (link.length) link[0].focus()

      self.isOpen = true
      self._trigger('open', event, self._uiHash())
    }
  },

  close(event, retainFocus) {
    if (this.newelement.is('.ui-state-active')) {
      this.newelement.removeClass('ui-state-active')
      this.listWrap.removeClass(this.widgetBaseClass + '-open')
      this.list.attr('aria-hidden', true)
      if (this.options.style == 'dropdown') {
        this.newelement.removeClass('ui-corner-top').addClass('ui-corner-all')
      }
      if (retainFocus) {
        this.newelement.focus()
      }
      this.isOpen = false
      this._trigger('close', event, this._uiHash())
    }
  },

  change(event) {
    this.element.trigger('change')
    this._trigger('change', event, this._uiHash())
  },

  select(event) {
    if (this._disabled(event.currentTarget)) {
      return false
    }
    this._trigger('select', event, this._uiHash())
  },

  widget() {
    return this.listWrap.add(this.newelementWrap)
  },

  _closeOthers(event) {
    $('.' + this.widgetBaseClass + '.ui-state-active')
      .not(this.newelement)
      .each(function () {
        $(this).data('selectelement').selectmenu('close', event)
      })
    $('.' + this.widgetBaseClass + '.ui-state-hover').trigger('mouseout')
  },

  _toggle(event, retainFocus) {
    if (this.isOpen) {
      this.close(event, retainFocus)
    } else {
      this.open(event)
    }
  },

  _formatText(text) {
    if (this.options.format) {
      text = this.options.format(text)
    } else if (this.options.escapeHtml) {
      text = $('<div />').text(text).html()
    }
    return text
  },

  _selectedIndex() {
    return this.element[0].selectedIndex
  },

  _selectedOptionLi() {
    return this._optionLis.eq(this._selectedIndex())
  },

  _focusedOptionLi() {
    return this.list.find('.' + this.widgetBaseClass + '-item-focus')
  },

  _moveSelection(amt, recIndex) {
    // do nothing if disabled
    if (!this.options.disabled) {
      const currIndex = parseInt(this._selectedOptionLi().data('index') || 0, 10)
      let newIndex = currIndex + amt
      // do not loop when using up key

      if (newIndex < 0) {
        newIndex = 0
      }
      if (newIndex > this._optionLis.size() - 1) {
        newIndex = this._optionLis.size() - 1
      }
      // Occurs when a full loop has been made
      if (newIndex === recIndex) {
        return false
      }

      if (this._optionLis.eq(newIndex).hasClass(this.namespace + '-state-disabled')) {
        // if option at newIndex is disabled, call _moveFocus, incrementing amt by one
        amt > 0 ? ++amt : --amt
        this._moveSelection(amt, newIndex)
      } else {
        this._optionLis.eq(newIndex).trigger('mouseover').trigger('mouseup')
      }
    }
  },

  _moveFocus(amt, recIndex) {
    let newIndex
    if (!isNaN(amt)) {
      const currIndex = parseInt(this._focusedOptionLi().data('index') || 0, 10)
      newIndex = currIndex + amt
    } else if (amt === ':first') {
      // Pressing the Home key attempts to take the user to the topmost item,
      // which may be a section and not a student. If it's a section, navigation
      // doesn't work at all, so just select the first student instead.
      const firstStudent = this._optionLis.filter((_, el) => $(el).data('index') != null).first()
      newIndex = firstStudent != null ? parseInt(firstStudent.data('index'), 10) : 0
    } else {
      newIndex = parseInt(this._optionLis.filter(amt).data('index'), 10)
    }

    if (newIndex < 0) {
      newIndex = 0
    }
    if (newIndex > this._optionLis.size() - 1) {
      newIndex = this._optionLis.size() - 1
    }

    // Occurs when a full loop has been made
    if (newIndex === recIndex) {
      return false
    }

    const activeID = this.widgetBaseClass + '-item-' + Math.round(Math.random() * 1000)

    this._focusedOptionLi().find('a:eq(0)').attr('id', '')

    if (this._optionLis.eq(newIndex).hasClass(this.namespace + '-state-disabled')) {
      // if option at newIndex is disabled, call _moveFocus, incrementing amt by one
      amt > 0 ? ++amt : --amt
      this._moveFocus(amt, newIndex)
    } else {
      this._optionLis.eq(newIndex).find('a:eq(0)').attr('id', activeID).focus()

      this._focusItem(this._optionLis.eq(newIndex))
    }

    this.list.attr('aria-activedescendant', activeID)
  },

  _focusItem($item) {
    // This function does not actually attempt to focus anything; it only
    // updates CSS classes related to focused elements.
    const classes = `${this.widgetBaseClass}-item-focus ui-state-hover`
    this._focusedOptionLi().removeClass(classes)
    $item.addClass(classes)
  },

  _scrollPage(direction) {
    let numPerPage = Math.floor(this.list.outerHeight() / this._optionLis.first().outerHeight())
    numPerPage = direction == 'up' ? -numPerPage : numPerPage
    this._moveFocus(numPerPage)
  },

  _setOption(key, value) {
    this.options[key] = value
    // set
    if (key == 'disabled') {
      if (value) this.close()
      this.element
        .add(this.newelement)
        .add(this.list)
        [value ? 'addClass' : 'removeClass'](
          this.widgetBaseClass + '-disabled' + ' ' + this.namespace + '-state-disabled'
        )
        .attr('aria-disabled', value)
    }
  },

  disable(index, type) {
    // if options is not provided, call the parents disable function
    if (typeof index === 'undefined') {
      this._setOption('disabled', true)
    } else if (type == 'optgroup') {
      this._disableOptgroup(index)
    } else {
      this._disableOption(index)
    }
  },

  enable(index, type) {
    // if options is not provided, call the parents enable function
    if (typeof index === 'undefined') {
      this._setOption('disabled', false)
    } else if (type == 'optgroup') {
      this._enableOptgroup(index)
    } else {
      this._enableOption(index)
    }
  },

  _disabled(elem) {
    return $(elem).hasClass(this.namespace + '-state-disabled')
  },

  _disableOption(index) {
    const optionElem = this._optionLis.eq(index)
    if (optionElem) {
      optionElem
        .addClass(this.namespace + '-state-disabled')
        .find('a')
        .attr('aria-disabled', true)
      this.element.find('option').eq(index).prop('disabled', true)
    }
  },

  _enableOption(index) {
    const optionElem = this._optionLis.eq(index)
    if (optionElem) {
      optionElem
        .removeClass(this.namespace + '-state-disabled')
        .find('a')
        .attr('aria-disabled', false)
      this.element.find('option').eq(index).removeAttr('disabled')
    }
  },

  _disableOptgroup(index) {
    const optGroupElem = this.list.find('li.' + this.widgetBaseClass + '-group-' + index)
    if (optGroupElem) {
      optGroupElem.addClass(this.namespace + '-state-disabled').attr('aria-disabled', true)
      this.element.find('optgroup').eq(index).prop('disabled', true)
    }
  },

  _enableOptgroup(index) {
    const optGroupElem = this.list.find('li.' + this.widgetBaseClass + '-group-' + index)
    if (optGroupElem) {
      optGroupElem.removeClass(this.namespace + '-state-disabled').attr('aria-disabled', false)
      this.element.find('optgroup').eq(index).removeAttr('disabled')
    }
  },

  index(newValue) {
    if (arguments.length) {
      if (!this._disabled($(this._optionLis[newValue]))) {
        this.element[0].selectedIndex = newValue
        this._refreshValue()
      } else {
        return false
      }
    } else {
      return this._selectedIndex()
    }
  },

  value(newValue) {
    if (arguments.length) {
      this.element[0].value = newValue
      this._refreshValue()
    } else {
      return this.element[0].value
    }
  },

  _refreshValue() {
    const activeClass = this.options.style == 'popup' ? ' ui-state-active' : ''
    const activeID = this.widgetBaseClass + '-item-' + Math.round(Math.random() * 1000)
    // deselect previous
    this.list
      .find('.' + this.widgetBaseClass + '-item-selected')
      .removeClass(this.widgetBaseClass + '-item-selected' + activeClass)
      .find('a')
      .attr('aria-selected', 'false')
      .attr('id', '')
    this._selectedOptionLi()
      .addClass(this.widgetBaseClass + '-item-selected' + activeClass)
      .find('a')
      .attr('aria-selected', 'true')
      .attr('id', activeID)

    // toggle any class brought in from option
    const currentOptionClasses = this.newelement.data('optionClasses')
      ? this.newelement.data('optionClasses')
      : ''
    const newOptionClasses = this._selectedOptionLi().data('optionClasses')
      ? this._selectedOptionLi().data('optionClasses')
      : ''
    this.newelement
      .removeClass(currentOptionClasses)
      .data('optionClasses', newOptionClasses)
      .addClass(newOptionClasses)
      .find('.' + this.widgetBaseClass + '-status')
      .html(this._selectedOptionLi().find('a:eq(0)').html())

    this.list.attr('aria-activedescendant', activeID)
  },

  _refreshPosition() {
    const o = this.options

    // if its a pop-up we need to calculate the position of the selected li
    if (o.style == 'popup' && !o.positionOptions.offset) {
      const selected = this._selectedOptionLi()
      var _offset =
        '0 ' +
        (this.list.offset().top -
          selected.offset().top -
          (this.newelement.outerHeight() + selected.outerHeight()) / 2)
    }
    this.listWrap.zIndex(this.element.zIndex() + 1).position({
      // set options for position plugin
      of: o.positionOptions.of || this.newelement,
      my: o.positionOptions.my,
      at: o.positionOptions.at,
      offset: o.positionOptions.offset || _offset,
      collision: o.positionOptions.collision || o.style == 'popup' ? 'fit' : 'flip',
    })
  },

  _movementToDirectChild(position) {
    const options = Object.values(this._optionLis || {})
    const ids = this.ids || []
    const isDirectChild = option => ids.includes(option?.parentElement?.id)

    let defaultIndex
    let foundIndex
    if (position === 'first') {
      defaultIndex = 0
      foundIndex = this._firstDirectChildIndex(options, isDirectChild)
    } else {
      defaultIndex = this._optionLis.length - 1
      foundIndex = this._lastDirectChildIndex(options, isDirectChild)
    }

    const destIndex = foundIndex < 0 ? defaultIndex : foundIndex
    const currIndex = parseInt(this._selectedOptionLi().data('index') || 0, 10)
    return destIndex - currIndex
  },

  _firstDirectChildIndex(options, isDirectChild) {
    return options.findIndex(isDirectChild)
  },

  _lastDirectChildIndex(options, isDirectChild) {
    for (let i = options.length - 1; i >= 0; i--) {
      if (isDirectChild(options[i])) {
        return i
      }
    }
    return -1
  },
})
