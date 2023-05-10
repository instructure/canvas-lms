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

/* eslint-disable no-void */

import {extend} from '@canvas/backbone/utils'
import Backbone from '@canvas/backbone'
import {useScope as useI18nScope} from '@canvas/i18n'
import template from '../../jst/ContentCheckbox.handlebars'
import checkboxCollectionTemplate from '../../jst/ContentCheckboxCollection.handlebars'
import CheckboxCollection from '../collections/ContentCheckboxCollection'
import CollectionView from '@canvas/backbone-collection-view'

const I18n = useI18nScope('content_migrations')

extend(ContentCheckboxView, Backbone.View)

function ContentCheckboxView() {
  this.fetchCheckboxes = this.fetchCheckboxes.bind(this)
  return ContentCheckboxView.__super__.constructor.apply(this, arguments)
}

ContentCheckboxView.prototype.template = template

ContentCheckboxView.prototype.tagName = 'li'

ContentCheckboxView.prototype.attributes = function () {
  let ref, ref1
  const attr = {}
  attr.role = 'treeitem'
  attr.id = 'treeitem-' + this.cid
  attr['data-type'] = this.model.get('type')
  attr['aria-checked'] = false
  attr['aria-level'] = (ref = this.model.collection) != null ? ref.options.ariaLevel : void 0
  if ((ref1 = this.model.collection) != null ? ref1.isTopLevel : void 0) {
    attr.class = 'top-level-treeitem'
  } else {
    attr.class = 'normal-treeitem'
  }
  return attr
}

ContentCheckboxView.prototype.els = {
  '[data-content=sublevelCheckboxes]': '$sublevelCheckboxes',
}

// Bind a change event only to top level checkboxes that are
// initially loaded
ContentCheckboxView.prototype.initialize = function () {
  ContentCheckboxView.__super__.initialize.apply(this, arguments)
  this.hasSubItemsUrl = !!this.model.get('sub_items_url')
  this.hasSubItems = !!this.model.get('sub_items')
  if (this.hasSubItemsUrl || this.hasSubItems) {
    return this.$el.on('fetchCheckboxes', this.fetchCheckboxes)
  }
}

ContentCheckboxView.prototype.toJSON = function () {
  const json = ContentCheckboxView.__super__.toJSON.apply(this, arguments)
  let ref
  json.hasSubCheckboxes = this.hasSubItems || this.hasSubItemsUrl
  json.isTopLevel = (ref = this.model.collection) != null ? ref.isTopLevel : void 0
  json.iconClass = this.getIconClass()
  if (json.type === 'context_modules' && json.submodule_count) {
    this.hasSubModules = true
    json.showModuleOptions = true
    json.sub_count = I18n.t(
      {
        one: '%{count} sub-module',
        other: '%{count} sub-modules',
      },
      {
        count: json.submodule_count,
      }
    )
  }
  json.screenreaderType = {
    assignment_groups: 'group',
    folders: 'folders',
  }[this.model.get('type')]
  return json
}

// This is a map for icon classes depending on the type of checkbox that is being
// rendered
ContentCheckboxView.prototype.iconClasses = {
  course_settings: 'icon-settings',
  syllabus_body: 'icon-syllabus',
  context_modules: 'icon-module',
  assignments: 'icon-assignment',
  quizzes: 'icon-quiz',
  assessment_question_banks: 'icon-collection',
  discussion_topics: 'icon-discussion',
  wiki_pages: 'icon-note-light',
  context_external_tools: 'icon-lti',
  tool_profiles: 'icon-lti',
  announcements: 'icon-announcement',
  calendar_events: 'icon-calendar-days',
  rubrics: 'icon-rubric',
  groups: 'icon-group',
  learning_outcomes: ENV.SHOW_SELECTABLE_OUTCOMES_IN_IMPORT ? 'icon-outcomes' : 'icon-standards',
  learning_outcome_groups: 'icon-folder',
  attachments: 'icon-document',
  assignment_groups: 'icon-folder',
  folders: 'icon-folder',
  blueprint_settings: 'icon-settings',
}

ContentCheckboxView.prototype.getIconClass = function () {
  return this.iconClasses[this.model.get('type')]
}

// If this checkbox model has sublevel checkboxes, create a new collection view
// and render the sub-level checkboxes in the collection view.
// @api custom backbone override
ContentCheckboxView.prototype.afterRender = function () {
  if (this.model.get('type') === 'context_modules' && !this.model.get('count')) {
    const $checkbox = this.$el.find('#checkbox-' + this.cid)
    $checkbox.data('moduleCheckbox', true)
    if (this.hasSubModules) {
      const $mo = this.$el.find('.module_options')
      $mo.hide().data('checkbox', $checkbox)
      $checkbox.data('moduleOptions', $mo)
    }
  }
  if (this.hasSubItemsUrl || this.hasSubItems) {
    this.$el.attr('aria-expanded', false)
  }
  let ref
  if (this.hasSubItems) {
    this.sublevelCheckboxes = new CheckboxCollection(this.model.get('sub_items'), {
      ariaLevel: ((ref = this.model.collection) != null ? ref.ariaLevel : void 0) + 1,
    })
    this.renderSublevelCheckboxes()
  }
  if (this.model.get('linked_resource')) {
    return this.attachLinkedResource()
  }
}

// Determines if we should hide the sublevel checkboxes or
// fetch new ones based on clicking the carrot next to it.
// @returns undefined
// @api private
ContentCheckboxView.prototype.fetchCheckboxes = function (event, options) {
  if (options == null) {
    options = {}
  }
  event.preventDefault()
  event.stopPropagation()
  if (!this.hasSubItemsUrl) {
    return
  }
  if (!this.sublevelCheckboxes) {
    this.fetchSublevelCheckboxes(options.silent)
    return this.renderSublevelCheckboxes()
  }
}

// Attempt to fetch sublevel in a new checkbox collection. Cache
// the collection so it doesn't call the server twice.
// @api private
ContentCheckboxView.prototype.fetchSublevelCheckboxes = function (silent) {
  let ref
  this.sublevelCheckboxes = new CheckboxCollection(null, {
    ariaLevel: ((ref = this.model.collection) != null ? ref.ariaLevel : void 0) + 1,
  })
  this.sublevelCheckboxes.url = this.model.get('sub_items_url')
  const dfd = this.sublevelCheckboxes.fetch()
  dfd.done(
    (function (_this) {
      return function () {
        return _this.$el.trigger('doneFetchingCheckboxes', _this.$el.find('#checkbox-' + _this.cid))
      }
    })(this)
  )
  if (!silent) {
    this.$el.disableWhileLoading(dfd)
  }
  return dfd
}

// Render all sublevel checkboxes in a collection view. The template
// should take care of rendering any "sublevel" checkboxes that may
// be on each of these models.
// @api private
ContentCheckboxView.prototype.renderSublevelCheckboxes = function () {
  const checkboxCollectionView = new CollectionView({
    collection: this.sublevelCheckboxes,
    itemView: ContentCheckboxView,
    el: this.$sublevelCheckboxes,
    template: checkboxCollectionTemplate,
  })
  return checkboxCollectionView.render()
}

// Some checkboxes will have a linked resource. If they do, build the linked resource
// property and attach it to the checkbox as a data element.
ContentCheckboxView.prototype.attachLinkedResource = function () {
  const linkedResource = this.model.get('linked_resource')
  const property = 'copy[' + linkedResource.type + '][id_' + linkedResource.migration_id + ']'
  return this.$el.find('#checkbox-' + this.cid).data('linkedResourceProperty', property)
}

export default ContentCheckboxView
