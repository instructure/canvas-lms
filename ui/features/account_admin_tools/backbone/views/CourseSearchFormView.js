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

import Backbone from '@canvas/backbone'

import $ from 'jquery'
import template from '../../jst/CourseSearchForm.handlebars'
import {useScope as useI18nScope} from '@canvas/i18n'
import '@canvas/jquery/jquery.instructure_forms'

const I18n = useI18nScope('course_search')

export default class CourseSearchFormView extends Backbone.View {
  static initClass() {
    this.prototype.tagName = 'form'

    this.prototype.template = template

    this.prototype.events = {submit: 'search'}

    this.prototype.els = {'#courseSearchField': '$searchField'}
  }

  initialize() {
    this.disableSearchForm = this.disableSearchForm.bind(this)
    this.enableSearchForm = this.enableSearchForm.bind(this)
    super.initialize(...arguments)
    this.model.on('restoring', this.disableSearchForm)
    return this.model.on('doneRestoring', this.enableSearchForm)
  }

  // Validates to make sure the query wasn't empty. Shows
  // an error if its empty. If not, continues with the
  // search. @model.search returns a deferred object
  // that is used while loading.
  //
  // @api private
  search(event) {
    event.preventDefault()

    const query = $.trim(this.$searchField.val())
    if (query === '') {
      return this.$searchField.errorBox(I18n.t('cant_be_blank', "Can't be blank"))
    } else {
      const dfd = this.model.search($.trim(query))
      return this.$el.disableWhileLoading(dfd)
    }
  }

  // Re-render the search form in a disabled state.
  // @api private
  disableSearchForm() {
    return this.$el.find(':input').prop('disabled', true)
  }

  // Re-render the search form in a enabled state.
  // @api private
  enableSearchForm() {
    return this.$el.find(':input').prop('disabled', false)
  }

  toJSON(json) {
    json = super.toJSON(...arguments)
    json.formDisabled = this.disabled
    return json
  }
}
CourseSearchFormView.initClass()
