//
// Copyright (C) 2013 - present Instructure, Inc.
//
// This file is part of Canvas.
//
// Canvas is free software: you can redistribute it and/or modify it under
// the terms of the GNU Affero General Public License as published by the Free
// Software Foundation, version 3 of the License.
//
// Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
// A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
// details.
//
// You should have received a copy of the GNU Affero General Public License along
// with this program. If not, see <http://www.gnu.org/licenses/>.

import I18n from 'i18n!course_navigation'
import $ from 'jquery'
import Backbone from 'Backbone'
import {reorderElements, renderTray} from 'jsx/move_item'
/*
xsslint jqueryObject.identifier dragObject current_item
*/

export default class NavigationView extends Backbone.View {
  static initClass() {
    this.prototype.events = {
      'click .disable_nav_item_link': 'disableNavLink',
      'click .move_nav_item_link': 'moveNavLink',
      'click .enable_nav_item_link': 'enableNavLink'
    }

    this.prototype.els = {
      '#nav_enabled_list': '$enabled_list',
      '#nav_disabled_list': '$disabled_list',
      '.navitem': '$navitems'
    }
  }

  disableNavLink(e) {
    const $targetItem = $(e.currentTarget).closest('.navitem')
    this.$disabled_list.append($targetItem)
    $(e.currentTarget)
      .attr('class', '')
      .attr('class', 'icon-plus enable_nav_item_link')
      .text('Enable')
    return $targetItem.find('a.al-trigger').focus()
  }

  enableNavLink(e) {
    const $targetItem = $(e.currentTarget).closest('.navitem')
    this.$enabled_list.append($targetItem)
    $(e.currentTarget)
      .attr('class', '')
      .attr('class', 'icon-x disable_nav_item_link')
      .text('Disable')
    return $targetItem.find('a.al-trigger').focus()
  }

  moveNavLink(e) {
    const selectedItem = $(e.currentTarget).closest('.navitem')
    const navList = $(e.currentTarget).closest('.nav_list')
    const navOptions = navList
      .children('.navitem')
      .map((key, item) => ({
        id: item.getAttribute('id'),
        title: item.getAttribute('aria-label')
      }))
      .toArray()

    this.moveTrayProps = {
      title: I18n.t('Move Navigation Item'),
      items: [
        {
          id: selectedItem.attr('id'),
          title: selectedItem.attr('aria-label')
        }
      ],
      moveOptions: {
        siblings: navOptions
      },
      onMoveSuccess: res => reorderElements(res.data, this.$enabled_list[0], id => `#${id}`),
      focusOnExit: item => document.querySelector(`#${item.id} a.al-trigger`)
    }

    return renderTray(this.moveTrayProps, document.getElementById('not_right_side'))
  }

  focusKeyboardHelp(e) {
    $('.drag_and_drop_warning').removeClass('screenreader-only')
  }

  hideKeyboardHelp(e) {
    $('.drag_and_drop_warning').addClass('screenreader-only')
  }

  afterRender() {
    $('#navigation_tab').on('blur', this.focusKeyboardHelp)
    $('.drag_and_drop_warning').on('blur', this.hideKeyboardHelp)
  }
}
NavigationView.initClass()
