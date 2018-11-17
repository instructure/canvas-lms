//
// Copyright (C) 2015 - present Instructure, Inc.
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
//
import DialogBaseView from '../DialogBaseView'
import template from 'jst/quiz/regrade'

export default class QuizRegradeView extends DialogBaseView {
  static initClass() {
    this.prototype.template = template

    this.optionProperty('regradeDisabled')
    this.optionProperty('regradeOption')
    this.optionProperty('multipleAnswer')
    this.optionProperty('question')

    this.prototype.events = {'click .regrade_option': 'enableUpdate'}
  }

  initialize() {
    this.update = this.update.bind(this)
    super.initialize(...arguments)
    return this.render()
  }

  render() {
    this.$el
      .parent()
      .find('a')
      .first()
      .focus()
    if (!this.regradeOption) {
      this.$el
        .parent()
        .find('.btn-primary')
        .attr('disabled', true)
    }
    return super.render(...arguments)
  }

  defaultOptions() {
    return {
      title: 'Regrade Options',
      width: '600px'
    }
  }

  update() {
    const selectedOption = this.$el.find('.regrade_option:checked')
    this.close()
    return this.trigger('update', selectedOption)
  }

  enableUpdate() {
    return this.$el
      .parent()
      .find('.btn-primary')
      .attr('disabled', false)
  }
}
QuizRegradeView.initClass()
