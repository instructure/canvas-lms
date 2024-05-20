/*
 * Copyright (C) 2023 - present Instructure, Inc.
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

import {extend} from '@canvas/backbone/utils'
import PublishButtonView from '@canvas/publish-button-view'

extend(PublishIconView, PublishButtonView)

function PublishIconView() {
  return PublishIconView.__super__.constructor.apply(this, arguments)
}

PublishIconView.prototype.publishClass = 'publish-icon-publish'

PublishIconView.prototype.publishedClass = 'publish-icon-published'

PublishIconView.prototype.unpublishClass = 'publish-icon-unpublish'

PublishIconView.prototype.tagName = 'span'

PublishIconView.prototype.className = 'publish-icon'

// This value allows the text to include the item title
PublishIconView.optionProperty('title')

// These values allow the default text to be overridden if necessary
PublishIconView.optionProperty('publishText')

PublishIconView.optionProperty('unpublishText')

PublishIconView.prototype.initialize = function () {
  PublishIconView.__super__.initialize.apply(this, arguments)
  return (this.events = {
    ...PublishButtonView.prototype.events,
    ...this.events,
  })
}

PublishIconView.prototype.setElement = function () {
  PublishIconView.__super__.setElement.apply(this, arguments)
  return this.$el.attr('data-tooltip', '')
}

PublishIconView.prototype.events = {
  keyclick: 'click',
}

export default PublishIconView
