#
# Copyright (C) 2013 - present Instructure, Inc.
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
  './PublishButtonView',
  'underscore'
], (PublishButtonView, _) ->

  class PublishIconView extends PublishButtonView
    publishClass: 'publish-icon-publish'
    publishedClass: 'publish-icon-published'
    unpublishClass: 'publish-icon-unpublish'

    tagName: 'span'
    className: 'publish-icon'

    # This value allows the text to include the item title
    @optionProperty 'title'

    # These values allow the default text to be overridden if necessary
    @optionProperty 'publishText'
    @optionProperty 'unpublishText'

    initialize: ->
      super
      @events = _.extend({}, PublishButtonView.prototype.events, @events)

    events: {'keyclick' : 'click'}
