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

import I18n from 'i18n!conversations'
import $ from 'jquery'
import _ from 'underscore'
import {View} from 'Backbone'
import SearchableSubmenuView from './SearchableSubmenuView'
import template from 'jst/conversations/courseOptions'
import 'jquery.instructure_date_and_time'
import 'vendor/bootstrap/bootstrap-dropdown'
import 'vendor/bootstrap-select/bootstrap-select'

export default class CourseSelectionView extends View {
  constructor(...args) {
    {
      // Hack: trick Babel/TypeScript into allowing this before super.
      if (false) { super(); }
      let thisFn = (() => { return this; }).toString();
      let thisName = thisFn.slice(thisFn.indexOf('return') + 6 + 1, thisFn.lastIndexOf(';')).trim();
      eval(`${thisName} = this;`);
    }
    this.render = this.render.bind(this)
    this.loadAll = this.loadAll.bind(this)
    this.truncate_course = this.truncate_course.bind(this)
    super(...args)
  }

  static initClass() {
    this.prototype.events = {change: 'onChange'}

    this.prototype._value = ''
  }

  initialize() {
    super.initialize(...arguments)
    if (!this.options.defaultOption)
      this.options.defaultOption = I18n.t('all_courses', 'All Courses')
    this.$el.addClass('show-tick')
    this.$el
      .selectpicker({useSubmenus: true})
      .next()
      .on('mouseover', this.loadAll)
      .find('.dropdown-toggle')
      .on('focus', this.loadAll)
    this.options.courses.favorites.on('reset', this.render)
    this.options.courses.all.on('reset', this.render)
    this.options.courses.all.on('add', this.render)
    this.options.courses.groups.on('reset', this.render)
    this.options.courses.groups.on('add', this.render)
    this.$picker = this.$el.next()
    return this.render()
  }

  render() {
    super.render()
    const more = []
    const concluded = []
    const now = $.fudgeDateForProfileTimezone(new Date())
    this.options.courses.all.each(course => {
      if (this.options.courses.favorites.get(course.id)) return
      if (course.get('access_restricted_by_date')) return

      const is_complete = this.is_complete(course, now)

      const collection = is_complete ? concluded : more
      return collection.push(course.toJSON())
    })

    let group_json = this.options.courses.groups.toJSON()

    if (this.options.messageableOnly) {
      group_json = _.filter(group_json, g => g.can_message)
    }
    const data = {
      defaultOption: this.options.defaultOption,
      favorites: this.options.courses.favorites.toJSON(),
      more,
      concluded,
      groups: group_json
    }

    this.truncate_course_name_data(data)
    this.$el.html(template(data))
    this.$el.selectpicker('refresh')
    this.$picker.find('.paginatedLoadingIndicator').remove()
    this.getAriaLabel()
    this.createSearchViews()
    if (!this.renderValue()) return this.loadAll()
  }

  is_complete(course, asOf) {
    if (course.get('workflow_state') === 'completed') return true
    if (course.get('end_at') && course.get('restrict_enrollments_to_course_dates'))
      return new Date(course.get('end_at')) < asOf
    if (course.get('term') && course.get('term').end_at)
      return new Date(course.get('term').end_at) < asOf
    return false
  }

  createSearchViews() {
    const searchViews = []
    this.$picker.find('.dropdown-submenu').each(function() {
      searchViews.push(new SearchableSubmenuView({el: this}))
    })
    return (this.searchViews = searchViews)
  }

  loadAll() {
    const {all} = this.options.courses
    if (all._loading) return
    all.fetch()
    all._loading = true
    this.options.courses.groups.fetchAll()
    return this.$picker.find('> .dropdown-menu').append(
      $('<div />')
        .attr('class', 'paginatedLoadingIndicator')
        .css('clear', 'both')
    )
  }

  setValue(value) {
    this._value = value || ''
    this.renderValue()
    return this.triggerEvent()
  }

  renderValue() {
    this.silenced = true
    this.$el.selectpicker('val', this._value)
    this.silenced = false
    return this.$el.val() === this._value
  }

  onChange() {
    if (this.silenced) return
    this._value = this.$el.val()
    this.triggerEvent()
    this.getAriaLabel()
    return this.searchViews.forEach(view => view.clearSearch())
  }

  getAriaLabel() {
    if (ENV.CONVERSATIONS.CAN_MESSAGE_ACCOUNT_CONTEXT) return
    const label =
      this.getCurrentContext().name ||
      I18n.t('Select course: a selection is required before recipients field will become available')
    return this.$picker.find('button').attr('aria-label', label)
  }

  getCurrentContext() {
    let course
    const matches = this._value.match(/(\w+)_(\d+)/)
    if (!matches) return {}
    const [match, type, id] = Array.from(matches)
    const context =
      type === 'course'
        ? (course = this.options.courses.favorites.get(id) || this.options.courses.all.get(id))
        : this.options.courses.groups.get(id)
    if (context) {
      return {name: context.get('name'), id: this._value}
    } else {
      return {}
    }
  }

  triggerEvent() {
    return this.trigger('course', this.getCurrentContext())
  }

  focus() {
    return this.$el
      .next()
      .find('.dropdown-toggle')
      .focus()
  }

  truncate_course_name_data(course_data) {
    return _.each(['favorites', 'more', 'concluded', 'groups'], key =>
      this.truncate_course_names(course_data[key])
    )
  }

  truncate_course_names(courses) {
    return _.each(courses, this.truncate_course)
  }

  truncate_course(course) {
    const name = course.name
    const truncated = this.middle_truncate(name)
    if (name !== truncated) {
      return (course.truncated_name = truncated)
    }
  }

  middle_truncate(name) {
    if (name.length > 25) {
      return `${name.slice(0, 10)}…${name.slice(-10)}`
    } else {
      return name
    }
  }
}
CourseSelectionView.initClass()
