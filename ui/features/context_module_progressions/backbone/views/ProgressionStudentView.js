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
import ModuleCollection from '@canvas/modules/backbone/collections/ModuleCollection'
import template from '../../jst/ProgressionStudentView.handlebars'
import collectionTemplate from '../../jst/ProgressionModuleCollection.handlebars'
import PaginatedCollectionView from '@canvas/pagination/backbone/views/PaginatedCollectionView'
import ProgressionModuleView from './ProgressionModuleView'

export default class ProgressionStudentView extends Backbone.View {
  initialize() {
    super.initialize(...arguments)
    this.$index = this.model.collection.view.$el
    this.$students = this.$index.find('#progression_students')
    return (this.$modules = this.$index.find('#progression_modules'))
  }

  afterRender() {
    super.afterRender(...arguments)
    if (!this.model.collection.currentStudentView) this.showProgressions()
    return this.syncHeight()
  }

  createProgressions() {
    const studentId = this.model.get('id')
    const modules = new ModuleCollection(null, {
      course_id: ENV.COURSE_ID,
      per_page: 50,
      params: {
        student_id: studentId,
        include: ['items'],
      },
    })
    modules.student_id = studentId
    modules.syncHeight = this.syncHeight
    modules.fetch()

    this.progressions = new PaginatedCollectionView({
      collection: modules,
      itemView: ProgressionModuleView,
      template: collectionTemplate,
      autoFetch: true,
    })

    this.progressions.render()
    return this.progressions.$el.appendTo(this.$modules)
  }

  showProgressions() {
    // this is important, we send the model to the collection so
    // it can be readed by the react header.
    this.model.collection.trigger('selectionChanged', this.model)

    this.$modules.attr('aria-busy', 'true')
    if (this.model.collection.currentStudentView != null) {
      this.model.collection.currentStudentView.hideProgressions()
    }
    this.model.collection.currentStudentView = this

    this.syncHeight()
    this.$el.addClass('active').attr('aria-selected', true)
    if (!this.progressions) {
      return this.createProgressions()
    } else {
      return this.progressions.show()
    }
  }

  hideProgressions() {
    this.progressions.hide()
    return this.$el.removeClass('active').removeAttr('aria-selected')
  }

  syncHeight = () => {
    return setTimeout(() => {
      this.$students.height(this.$modules.height())
      return this.$students
        .find('.collectionViewItems')
        .height(
          (this.$students.height() || 0) - (this.$students.find('.header').height() || 16) - 16
        )
    }, 0)
  }
}

ProgressionStudentView.prototype.tagName = 'li'
ProgressionStudentView.prototype.className = 'student'
ProgressionStudentView.prototype.template = template
ProgressionStudentView.prototype.events = {click: 'showProgressions'}
