/*
 * Copyright (C) 2011 - present Instructure, Inc.
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

import {View} from 'Backbone'
import $ from 'jquery'
import 'compiled/jquery.rails_flash_notifications'
import 'jquery.disableWhileLoading'
import I18n from 'i18n!dashboard'
import showMoreTemplate from 'jst/dashboard/show_more_link'

export default class DashboardView extends View {
  static initClass () {
    this.prototype.el = document.body

    this.prototype.events = {
      'click .stream_header': 'toggleDetails',
      'click .stream_header .links a': 'stopPropagation',
      'click .stream-details': 'handleDetailsClick',
      'click .close_conference_link': 'closeConference',
      'focus .todo-tooltip': 'handleTooltipFocus',
      beforeremove: 'updateCategoryCounts', // ujsLinks event
    }
  }

  initialize () {
    super.initialize(...arguments)
    // setup all 'Show More' links to reflect currently being collapsed.
    $('.stream-category').each((idx, elm) => this.setShowMoreLink($(elm)))
  }

  toggleDetails (event) {
    const header = $(event.currentTarget)
    // since toggling, isExpanded is the opposite of the current DOM state
    const isExpanded = !(header.attr('aria-expanded') === 'true')
    header.attr('aria-expanded', isExpanded)
    const details = header.next('.details_container')
    details.toggle(isExpanded)
    // if expanded, focus first link in detail area
    if (isExpanded) {
      details.find('a:first').focus()
    }
    // Set the link contents. Second param for being currently expanded or collapsed
    this.setShowMoreLink(header.closest('.stream-category'), isExpanded)
  }

  setShowMoreLink ($category) {
    if (!$category) return
    // determine if currently expanded
    const isExpanded = $category.find('.details_container').is(':visible')
    // go up to stream-category to build the text to display
    const categoryName = $category.data('category')
    const count = parseInt($category.find('.count:first').text(), 10)
    const assistiveText = this.getCategoryText(categoryName, count, !isExpanded)
    const $link = $category.find('.toggle-details')
    $link.html(showMoreTemplate({expanded: isExpanded, assistiveText}))
  }

  getCategoryText (category, count, forExpand) {
    if (category === 'Announcement') {
      if (forExpand) {
        return I18n.t('announcements_expand', {
          one: 'Expand %{count} announcement',
          other: 'Expand %{count} announcements'
        }, {count})
      } else {
        return I18n.t('announcements_collapse', {
          one: 'Collapse %{count} announcement',
          other: 'Collapse %{count} announcements'
        }, {count})
      }
    } else if (category === 'Conversation') {
      if (forExpand) {
        return I18n.t('conversations_expand', {
          one: 'Expand %{count} conversation message',
          other: 'Expand %{count} conversation messages'
        }, {count})
      } else {
        return I18n.t('conversations_collapse', {
          one: 'Collapse %{count} conversation message',
          other: 'Collapse %{count} conversation messages'
        }, {count})
      }
    } else if (category === 'Assignment') {
      if (forExpand) {
        return I18n.t('assignments_expand', {
          one: 'Expand %{count} assignment notification',
          other: 'Expand %{count} assignment notifications'
        }, {count})
      } else {
        return I18n.t('assignments_collapse', {
          one: 'Collapse %{count} assignment notification',
          other: 'Collapse %{count} assignment notifications'
        }, {count})
      }
    } else if (category === 'DiscussionTopic') {
      if (forExpand) {
        return I18n.t('discussions_expand', {
          one: 'Expand %{count} discussion',
          other: 'Expand %{count} discussions'
        }, {count})
      } else {
        return I18n.t('discussions_collapse', {
          one: 'Collapse %{count} discussion',
          other: 'Collapse %{count} discussions'
        }, {count})
      }
    } else {
      return ''
    }
  }

  handleDetailsClick (event) {
    const row = $(event.target).closest('tr')
    return row.find('a')
  }

  // TODO: switch recent items to client rendering and skip all this
  // ridiculous dom manip that is likely to just get worse
  updateCategoryCounts (event) {
    const parent = $(event.target).closest('li[class^=stream-]')
    const items = parent.find('tbody tr').filter(':visible')
    if (items.length) {
      parent.find('.count').text(items.length)
    } else {
      parent.remove()
    }
    return this.setShowMoreLink($(event.target).closest('.stream-category'))
  }

  handleTooltipFocus (event) {
    // needed so that the screenreader will read target element before points possible on focus
    setTimeout(
      () => $.screenReaderFlashMessage($(event.target).find('.screenreader_points_possible').text())
      , 6000
    )
  }

  closeConference (e) {
    e.preventDefault()
    if (!confirm(I18n.t('confirm.close', 'Are you sure you want to end this conference?\n\nYou will not be able to reopen it.'))) return
    const link = $(e.currentTarget)
    return $.ajaxJSON(link.attr('href'), 'POST', {}, data =>
      link.parents('.ic-notification.conference').hide()
    )
  }
}
DashboardView.initClass()
