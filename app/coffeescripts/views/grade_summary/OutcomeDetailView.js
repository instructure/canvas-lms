//
// Copyright (C) 2014 - present Instructure, Inc.
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

import _ from 'underscore'
import Backbone from 'Backbone'
import OutcomeResultCollection from '../../collections/OutcomeResultCollection'
import DialogBaseView from '../DialogBaseView'
import CollectionView from '../CollectionView'
import AlignmentView from './AlignmentView'
import ProgressBarView from './ProgressBarView'
import template from 'jst/grade_summary/outcome_detail'

export default class OutcomeDetailView extends DialogBaseView {
  static initClass() {
    this.prototype.template = template
  }

  dialogOptions() {
    return {
      containerId: 'outcome_detail',
      close: this.onClose,
      buttons: [],
      width: 640
    }
  }

  initialize() {
    this.alignmentsForView = new Backbone.Collection([])
    this.alignmentsView = new CollectionView({
      collection: this.alignmentsForView,
      itemView: AlignmentView
    })
    return super.initialize(...arguments)
  }

  onClose() {
    return (window.location.hash = 'tab-outcomes')
  }

  render() {
    super.render(...arguments)
    this.alignmentsView.setElement(this.$('.alignments'))
    this.allAlignments = new OutcomeResultCollection([], {
      outcome: this.model
    })

    this.allAlignments.on('fetched:last', () => this.alignmentsForView.reset(this.allAlignments.toArray()));

    return this.allAlignments.fetch()
  }

  show(model) {
    this.model = model
    this.$el.dialog('option', 'title', this.model.group.get('title')).css('maxHeight', 340)
    this.progress = new ProgressBarView({model: this.model})
    this.render()
    return super.show(...arguments)
  }

  toJSON() {
    const json = super.toJSON(...arguments)
    return _.extend(json, {progress: this.progress})
  }
}
OutcomeDetailView.initClass()
