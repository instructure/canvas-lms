define(['jquery'],function($) {

/* ============================================================
 * bootstrap-dropdown.js v2.3.2
 * http://twitter.github.com/bootstrap/javascript.html#dropdowns
 * ============================================================
 * Copyright 2012 Twitter, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 * ============================================================ */

// INSTRUCTURE modified

!function ($) {

  "use strict"; // jshint ;_;


 /* DROPDOWN CLASS DEFINITION
  * ========================= */

  var toggle = '[data-toggle=dropdown]'
    , Dropdown = function (element) {
        var $el = $(element).on('click.dropdown.data-api', this.toggle)
        $('html').on('click.dropdown.data-api', function () {
          // INSTRUCTURE added aria-expanded
          $el.parent().removeClass('open').attr('aria-expanded', 'false')
        })
      }

  Dropdown.prototype = {

    constructor: Dropdown

  , toggle: function (e) {
      var $this = $(this)
        , $parent
        , $parentsParent
        , isActive

      if ($this.is('.disabled, :disabled')) return

      $parent = getParent($this)
      $parentsParent = getParent($parent)

      isActive = $parent.hasClass('open')

      clearMenus()

      if (!isActive) {
        if ('ontouchstart' in document.documentElement) {
          // if mobile we we use a backdrop because click events don't delegate
          $('<div class="dropdown-backdrop"/>').insertBefore($(this)).on('click', clearMenus)
        }
        // INSTRUCTURE added aria-expanded and role='application'
        $parent.toggleClass('open').attr('aria-expanded', 'true')
        $parent.trigger("show.bs.dropdown")

        if ($parent.hasClass('open')){
          $parentsParent.attr('role', 'application');
        }

        // if this causes issues in the future, we should trackdown the event handler that is
        // stealing focus after the fact
        window.setTimeout(function (){$parent.find('>div.dropdown-menu>ul>li[rel=0]').focus()},0)
      } else {
        $parentsParent.removeAttr('role');
        $parent.trigger("hide.bs.dropdown")
      }

      $parent.trigger("toggle.bs.dropdown")
      $this.focus()

      return false
    }

  , keydown: function (e) {
      var $this
        , $items
        , $active
        , $parent
        , $list
        , isActive
        , index

      // INSTRUCTURE
      if (e.keyCode == 9) return clearMenus()
      if ($(e.target).is('input')) return

      if (!/(32|13|37|38|39|40|27)/.test(e.keyCode)) return

      $this = $(this)

      e.preventDefault()
      e.stopPropagation()

      if ($this.is('.disabled, :disabled')) return

      $parent = getParent($this)

      isActive = $parent.hasClass('open')

      if (!isActive || (isActive && e.keyCode == 27)) {
        if (e.which == 27) $parent.find(toggle).focus()
        // INSTRUCTURE
        setTimeout(function() {$('li:not(.divider):visible > a', $parent).first().focus()}, 0)
        return $this.click()
      }

      // INSTRUCTURE--modified the rest of the method
      // left
      if (e.keyCode == 37) {
        $list = $(e.target).closest('ul')
        if ($list.is('[role=group]')) {
          $list.closest('li').children('a').focus()
        }
        return
      }

      // right
      if (e.keyCode == 39) {
        $list = $(e.target).next()
        if ($list.is('.dropdown-menu')) {
          $list.find('li:not(.divider):visible > a').eq(0).focus()
          e.preventDefault()
        }
        return
      }

      if ($(e.target).is('a')) {
        $list = $(e.target).closest('ul')
      } else {
        $list = $('[role=menu]', $parent)
      }
      $items = $('> li:not(.divider):visible > a', $list)

      if (!$items.length) return

      index = $items.index($items.filter(':focus'))

      if (e.keyCode == 38 && index > 0) index--                                        // up
      if (e.keyCode == 40 && index < $items.length - 1) index++                        // down
      if (!~index) index = 0

      $items
        .eq(index)
        .focus()
      if((e.keyCode == 13 || e.keyCode == 32)) {
        var parent = $($items.eq(index).closest('li'));
        if (parent.hasClass("dropdown-submenu") ){
          parent.find(".dropdown-menu input").focus()
        }
      }

    }

    // INSTRUCTURE
    , focusSubmenu: function(e) {
      $(this).attr('role', 'application')
      $(this).addClass('open').attr('aria-expanded', 'true')
    }

    , blurSubmenu: function(e) {
      var self = this;
      setTimeout(function() {
        if ($.contains(self, document.activeElement)) {return;}
        $(self).removeAttr('role')
        $(self).removeClass('open').attr('aria-expanded', 'false')
      }, 0)
    }

    , clickSubmenu: function(e) {
      var subMenu = $(e.target).closest('li');
      if (subMenu.hasClass('dropdown-submenu')){
        subMenu.find(".dropdown-menu input").focus();
      } else {
        return;
      }
      e.stopPropagation();
      e.preventDefault();
    }
  }

  function clearMenus() {
    // INSTRUCTURE--maintain focus
    var $list = $(document.activeElement).closest('.dropdown-menu')
    if ($list) {
      $list.parent().prev().focus();
    }
    $('.dropdown-backdrop').remove()
    $(toggle).each(function () {
      // INSTRUCTURE added aria-expanded
      getParent($(this)).removeClass('open').attr('aria-expanded', 'false')
    })
    // INSTRUCTURE
    $('.dropdown-submenu').each(function() {
      $(this).removeClass('open').attr('aria-expanded', 'false')
    })
  }

  function getParent($this) {
    var selector = $this.attr('data-target')
      , $parent

    if (!selector) {
      selector = $this.attr('href')
      selector = selector && /#/.test(selector) && selector.replace(/.*(?=#[^\s]*$)/, '') //strip for ie7
    }

    $parent = selector && $(selector)

    if (!$parent || !$parent.length) $parent = $this.parent()

    return $parent
  }


  /* DROPDOWN PLUGIN DEFINITION
   * ========================== */

  var old = $.fn.dropdown

  $.fn.dropdown = function (option) {
    return this.each(function () {
      var $this = $(this)
        , data = $this.data('dropdown')
      if (!data) $this.data('dropdown', (data = new Dropdown(this)))
      if (typeof option == 'string') data[option].call($this)
    })
  }

  $.fn.dropdown.Constructor = Dropdown


 /* DROPDOWN NO CONFLICT
  * ==================== */

  $.fn.dropdown.noConflict = function () {
    $.fn.dropdown = old
    return this
  }


  /* APPLY TO STANDARD DROPDOWN ELEMENTS
   * =================================== */

  $(document)
    .on('click.dropdown.data-api', clearMenus)
    .on('click.dropdown.data-api', '.dropdown form', function (e) { e.stopPropagation() })
    .on('click.dropdown.data-api'  , toggle, Dropdown.prototype.toggle)
    .on('keydown.dropdown.data-api', toggle + ', [role=menu]' , Dropdown.prototype.keydown)
    // INSTRUCTURE
    .on('focus.dropdown.data-api', '.dropdown-submenu', Dropdown.prototype.focusSubmenu)
    .on('blur.dropdown.data-api', '.dropdown-submenu', Dropdown.prototype.blurSubmenu)
    .on('click.dropdown.data-api', '.dropdown-submenu', Dropdown.prototype.clickSubmenu)

}(window.jQuery);

});
