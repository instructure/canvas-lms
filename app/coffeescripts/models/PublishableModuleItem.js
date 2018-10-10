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
  '../backbone-ext/DefaultUrlMixin'
  'Backbone'
  'i18n!publishableModuleItem'
], (DefaultUrlMixin, {Model}, I18n) ->


  # A slightly terrible class that branches the urls and json data for the
  # different module types
  class PublishableModuleItem extends Model

    defaults:
      module_type: null
      course_id: null
      module_id: null
      published: true
      publishable: true
      unpublishable: true
      module_item_name: null

    branch: (key) ->
      (@[key][@get('module_type')] or @[key].generic).call(this)

    url:             -> @branch('urls')
    toJSON:          -> @branch('toJSONs')
    disabledMessage: -> @branch('disabledMessages')

    baseUrl: -> "/api/v1/courses/#{@get('course_id')}"

    urls:
      generic:          -> "#{@baseUrl()}/modules/#{@get('module_id')}/items/#{@get('module_item_id')}"
      module:           -> "#{@baseUrl()}/modules/#{@get('id')}"

    toJSONs:
      generic: ->          module_item: { published: @get('published') }
      module: ->           module: { published: @get('published') }

    disabledMessages:
      generic:          -> if @get('module_item_name')
                             I18n.t('Publishing %{item_name} is disabled', {item_name: @get('module_item_name')})
                           else
                             I18n.t('Publishing is disabled for this item')

      assignment:       -> if @get('module_item_name')
                             I18n.t("Can't unpublish %{item_name} if there are student submissions", {item_name: @get('module_item_name')})
                           else
                             I18n.t("Can't unpublish if there are student submissions")

      quiz:             -> if @get('module_item_name')
                             I18n.t("Can't unpublish %{item_name} if there are student submissions", {item_name: @get('module_item_name')})
                           else
                             I18n.t("Can't unpublish if there are student submissions")
      discussion_topic: -> if @get('module_item_name')
                             I18n.t("Can't unpublish %{item_name} if there are student submissions", {item_name: @get('module_item_name')})
                           else
                             I18n.t("Can't unpublish if there are student submissions")

    publish: ->
      @save 'published', yes

    unpublish: ->
      @save 'published', no

