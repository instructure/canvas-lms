#
# Copyright (C) 2012 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

define [
  'jquery'
  'compiled/jquery.kylemenu'
], ($, KyleMenu) ->

  # this is a behaviour that will automatically set up a set of .admin-links
  # when the button is clicked, see _admin_links.scss for markup
  $(document).on 'mousedown click keydown', '.al-trigger', (event) ->
    $trigger = $(this)
    return if $trigger.data('kyleMenu')
    opts = $.extend {noButton: true}, $trigger.data('kyleMenuOptions')
    opts.appendMenuTo = 'body' if $trigger.data('append-to-body')
    opts = $.extend opts,
      popupOpts:
        position:
          my: $trigger.data('popup-my')
          at: $trigger.data('popup-at')
          within: $trigger.data('popup-within')
    new KyleMenu($trigger, opts)
    $trigger.trigger(event)
