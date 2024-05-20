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
import $ from 'jquery'
import Backbone from '@canvas/backbone'
import _, {map, find} from 'lodash'
import {useScope as useI18nScope} from '@canvas/i18n'
import natcompare from '@canvas/util/natcompare'
import template from '../../../jst/subviews/CourseFindSelect.handlebars'
import autocompleteItemTemplate from '../../../jst/autocomplete_item.handlebars'
import '@canvas/jquery/jquery.ajaxJSON'
import '@canvas/jquery/jquery.disableWhileLoading'
import 'jqueryui/menu'
import 'jqueryui/autocomplete'
import {encodeQueryString} from '@canvas/query-string-encoding'

const I18n = useI18nScope('content_migrations')

extend(CourseFindSelectView, Backbone.View)

CourseFindSelectView.optionProperty('current_user_id', 'show_select')

CourseFindSelectView.prototype.template = template

function CourseFindSelectView() {
  this.updateSearch = this.updateSearch.bind(this)
  this.updateSelect = this.updateSelect.bind(this)
  this.includeConcludedCourses = true
  CourseFindSelectView.__super__.constructor.apply(this, arguments)
}

CourseFindSelectView.prototype.els = {
  '#courseSearchField': '$courseSearchField',
  '#courseSelect': '$courseSelect',
  '#courseSelectWarning': '$selectWarning',
}

CourseFindSelectView.prototype.events = {
  'change #courseSelect': 'updateSearch',
  'change #include_completed_courses': 'toggleConcludedCourses',
}

CourseFindSelectView.prototype.render = function () {
  CourseFindSelectView.__super__.render.apply(this, arguments)
  if (this.options.show_select) {
    const dfd = this.getManageableCourses()
    this.$el.disableWhileLoading(dfd)
    return dfd.done(
      (function (_this) {
        return function (data) {
          _this.courses = data
          _this.coursesByTerms = _.chain(_this.courses)
            .groupBy(function (course) {
              return course.term
            })
            .map(function (value, key) {
              return {
                term: key,
                courses: value.sort(natcompare.byKey('label')),
              }
            })
            .sort(function (a, b) {
              const astart = a.courses[0].enrollment_start
              const bstart = b.courses[0].enrollment_start
              let val = 0
              if (astart || bstart) {
                val = new Date(bstart) - new Date(astart)
              }
              if (val === 0) {
                val = natcompare.strings(a.term, b.term)
              }
              return val
            })
            .value()
          return CourseFindSelectView.__super__.render.apply(_this, arguments)
        }
      })(this)
    )
  }
}

CourseFindSelectView.prototype.afterRender = function () {
  this.$courseSearchField.autocomplete({
    source: this.manageableCourseUrl(),
    select: this.updateSelect,
  })
  this.$courseSearchField.data('ui-autocomplete')._renderItem = function (ul, item) {
    return $(autocompleteItemTemplate(item)).appendTo(ul)
  }
  // Accessiblity Hack. If you find a better solution please fix this. This makes it so the whole form isn't read
  // by the screen reader every time a user selects an auto completed item.
  const $converterDiv = $('#converter')
  this.$courseSearchField.on('focus', function () {
    return $converterDiv.attr('aria-atomic', false)
  })
  this.$courseSearchField.on('blur', function () {
    return $converterDiv.attr('aria-atomic', true)
  })
  this.$courseSelect.on('focus', function () {
    return $converterDiv.attr('aria-atomic', false)
  })
  return this.$courseSelect.on('blur', function () {
    return $converterDiv.attr('aria-atomic', true)
  })
}

CourseFindSelectView.prototype.toJSON = function () {
  const json = CourseFindSelectView.__super__.toJSON.apply(this, arguments)
  json.terms = this.coursesByTerms
  json.include_concluded = this.includeConcludedCourses
  json.show_select = this.options.show_select
  return json
}

// Grab a list of courses from the server via the managebleCourseUrl. Disable
// this view and re-render.
// @api private
CourseFindSelectView.prototype.getManageableCourses = function () {
  const dfd = $.ajaxJSON(this.manageableCourseUrl(), 'GET', {}, {}, {}, {})
  this.$el.disableWhileLoading(dfd)
  return dfd
}

// Turn on a param that lets this view know to filter terms with concluded
// courses. Also, automatically update the dropdown menu with items
// that include concluded courses.
CourseFindSelectView.prototype.toggleConcludedCourses = function () {
  this.includeConcludedCourses = !this.includeConcludedCourses
  this.$courseSearchField.autocomplete('option', 'source', this.manageableCourseUrl())
  return this.render()
}

// Generate a url from the current_user_id that is used to find courses
// that this user can manage. jQuery autocomplete will add the param
// "term=typed in stuff" automagically so we don't have to worry about
// refining the search term
CourseFindSelectView.prototype.manageableCourseUrl = function () {
  let params
  if (this.includeConcludedCourses) {
    params = encodeQueryString({
      'include[]': 'concluded',
    })
  }
  if (params) {
    return '/users/' + this.current_user_id + '/manageable_courses?' + params
  } else {
    return '/users/' + this.current_user_id + '/manageable_courses'
  }
}

// Build a list of courses that our template and autocomplete can use
// objects look like
//   {label: 'Plant Science', value: 'Plant Science', id: '42'}
// @api private
CourseFindSelectView.prototype.autocompleteCourses = function () {
  return map(this.courses, function (course) {
    return {
      label: course.label,
      id: course.id,
      value: course.label,
    }
  })
}

// After finding a course by searching via autocomplete, update the
// select menu to keep both input fields in sync. Also sets the
// source course id
// @input (jqueryEvent, uiObj)
// @api private
CourseFindSelectView.prototype.updateSelect = function (event, ui) {
  this.setSourceCourseId(ui.item.id)
  if (this.$courseSelect.length) {
    this.$courseSelect.val(ui.item.id)
  }
  return this.trigger('course_changed', ui.item)
}

// After selecting a course via the dropdown menu, update the search
// field to keep the inputs in sync. Also set the source course id
// @input jqueryEvent
// @api private
CourseFindSelectView.prototype.updateSearch = function (event) {
  const value = event.target.value && String(event.target.value)
  this.setSourceCourseId(value)
  const courses = this.autocompleteCourses()
  const courseObj = find(
    courses,
    (function (_this) {
      return function (course) {
        return course.id === value
      }
    })(this)
  )
  // eslint-disable-next-line no-void
  return this.$courseSearchField.val(courseObj != null ? courseObj.value : void 0)
}

// Given an id, set the source_course_id on the backbone model.
// @input int
// @api private
CourseFindSelectView.prototype.setSourceCourseId = function (id) {
  let course, ref
  // eslint-disable-next-line no-void
  if (id === ((ref = ENV.COURSE_ID) != null ? ref.toString() : void 0)) {
    this.$selectWarning.show()
  } else {
    this.$selectWarning.hide()
  }
  const settings = this.model.get('settings') || {}
  settings.source_course_id = id
  this.model.set('settings', settings)
  if (
    (course = find(this.courses, function (c) {
      return c.id === id
    }))
  ) {
    return this.trigger('course_changed', course)
  }
}

// Validates this form element. This validates method is a convention used
// for all sub views.
// ie:
//   error_object = {fieldName:[{type:'required', message: 'This is wrong'}]}
// -----------------------------------------------------------------------
// @expects void
// @returns void | object (error)
// @api private
CourseFindSelectView.prototype.validations = function () {
  const errors = {}
  const settings = this.model.get('settings')
  // eslint-disable-next-line no-void
  if (!(settings != null ? settings.source_course_id : void 0)) {
    errors.courseSearchField = [
      {
        type: 'required',
        message: I18n.t('You must select a course to copy content from'),
      },
    ]
  }
  return errors
}

export default CourseFindSelectView
