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
  'jquery'
  'Backbone'
  'i18n!content_migrations'
  'jst/content_migrations/ContentCheckbox'
  'jst/content_migrations/ContentCheckboxCollection'
  '../../collections/content_migrations/ContentCheckboxCollection'
  '../CollectionView'
  '../../str/TextHelper'
], ($, Backbone, I18n, template, checkboxCollectionTemplate, CheckboxCollection, CollectionView, TextHelper) ->
  class ContentCheckboxView extends Backbone.View
    template: template
    tagName: 'li'
    attributes: ->
      attr = {}
      attr.role = "treeitem"
      attr.id = "treeitem-#{@cid}"
      attr['data-type'] = @model.get('type')
      attr['aria-checked'] = false
      attr['aria-level'] = @model.collection?.options.ariaLevel

      if @model.collection?.isTopLevel
        attr.class = "top-level-treeitem"
      else
        attr.class = "normal-treeitem"

      attr

    els:
      '[data-content=sublevelCheckboxes]' : '$sublevelCheckboxes'

    # Bind a change event only to top level checkboxes that are
    # initially loaded.

    initialize: ->
      super
      @hasSubItemsUrl = !!@model.get('sub_items_url')
      @hasSubItems = !!@model.get('sub_items')

      if @hasSubItemsUrl || @hasSubItems
        @$el.on "fetchCheckboxes", @fetchCheckboxes

    toJSON: ->
      json = super
      json.hasSubCheckboxes = @hasSubItems || @hasSubItemsUrl
      json.isTopLevel = @model.collection?.isTopLevel
      json.iconClass = @getIconClass()

      if json.type == 'context_modules' && json.submodule_count
        @hasSubModules = true
        json.showModuleOptions = true
        json.sub_count = I18n.t({
            one: "%{count} sub-module",
            other: "%{count} sub-modules"
          },
          {count: json.submodule_count})

      json.screenreaderType = {
        assignment_groups: 'group'
        folders: 'folders'
      }[@model.get('type')]

      json

    # This is a map for icon classes depending on the type of checkbox that is being
    # rendered

    iconClasses:
      course_settings:              "icon-settings"
      syllabus_body:                "icon-syllabus"
      context_modules:              "icon-module"
      assignments:                  "icon-assignment"
      quizzes:                      "icon-quiz"
      assessment_question_banks:    "icon-collection"
      discussion_topics:            "icon-discussion"
      wiki_pages:                   "icon-note-light"
      context_external_tools:       "icon-lti"
      tool_profiles:                "icon-lti"
      announcements:                "icon-announcement"
      calendar_events:              "icon-calendar-days"
      rubrics:                      "icon-rubric"
      groups:                       "icon-group"
      learning_outcomes:            "icon-standards"
      attachments:                  "icon-document"
      assignment_groups:            "icon-folder"
      folders:                      "icon-folder"

    # This retrieves the iconClass out of the iconClasses object map
    # @api private

    getIconClass: -> @iconClasses[@model.get('type')]

    # If this checkbox model has sublevel checkboxes, create a new collection view
    # and render the sub-level checkboxes in the collection view.
    # @api custom backbone override

    afterRender: ->
      if @model.get('type') == 'context_modules' && !@model.get('count')
        $checkbox = @$el.find("#checkbox-#{@cid}")
        $checkbox.data('moduleCheckbox', true)
        if @hasSubModules
          $mo = @$el.find('.module_options')
          $mo.hide().data('checkbox', $checkbox)
          $checkbox.data('moduleOptions', $mo)

      if @hasSubItemsUrl || @hasSubItems
        @$el.attr('aria-expanded', false)

      if @hasSubItems
        @sublevelCheckboxes = new CheckboxCollection @model.get('sub_items'),
                                ariaLevel: @model.collection?.ariaLevel + 1
        @renderSublevelCheckboxes()

      if @model.get('linked_resource')
        @attachLinkedResource()

    # Determins if we should hide the sublevel checkboxes or
    # fetch new ones based on clicking the carrot next to it.
    # @returns undefined
    # @api private

    fetchCheckboxes: (event, options={}) =>
      event.preventDefault()
      event.stopPropagation()
      return unless @hasSubItemsUrl

      $target = $(event.currentTarget)

      if !@sublevelCheckboxes
        @fetchSublevelCheckboxes(options.silent)
        @renderSublevelCheckboxes()

    # Attempt to fetch sublevel in a new checkbox collection. Cache
    # the collection so it doesn't call the server twice.
    # @api private

    fetchSublevelCheckboxes: (silent) ->
      @sublevelCheckboxes = new CheckboxCollection null,
                              ariaLevel: @model.collection?.ariaLevel + 1
      @sublevelCheckboxes.url = @model.get('sub_items_url')

      dfd = @sublevelCheckboxes.fetch()
      dfd.done =>
        @$el.trigger 'doneFetchingCheckboxes', @$el.find("#checkbox-#{@cid}")
      @$el.disableWhileLoading dfd unless silent
      dfd

    # Render all sublevel checkboxes in a collection view. The template
    # should take care of rendering any "sublevel" checkboxes that may
    # be on each of these models.
    # @api private

    renderSublevelCheckboxes: ->
      checkboxCollectionView = new CollectionView
                                 collection: @sublevelCheckboxes
                                 itemView: ContentCheckboxView
                                 el: @$sublevelCheckboxes
                                 template: checkboxCollectionTemplate

      checkboxCollectionView.render()

    # Some checkboxes will have a linked resource. If they do, build the linked resource
    # property and attach it to the checkbox as a data element.

    attachLinkedResource: ->
      linkedResource = @model.get('linked_resource')
      property = "copy[#{linkedResource.type}][id_#{linkedResource.migration_id}]"

      @$el.find("#checkbox-#{@cid}").data 'linkedResourceProperty', property
