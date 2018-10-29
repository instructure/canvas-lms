//
// Copyright (C) 2012 - present Instructure, Inc.
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

import $ from 'jquery'

import _ from 'underscore'
import h from 'str/htmlEscape'
import Outcome from '../../models/Outcome'
import OutcomeIconBase from './OutcomeIconBase'
import 'jquery.disableWhileLoading'

export default class OutcomeGroupIconView extends OutcomeIconBase {
  static initClass() {
    this.prototype.className = 'outcome-group'
    this.prototype.attributes = _.extend({}, this.attributes, {'aria-expanded': false})
  }

  // Internal: Treat right arrow presses like a click.
  //
  // Return nothing.
  onRightArrowKey(e, $target) {
    $target.attr('aria-expanded', true).attr('tabindex', -1)
    this.triggerSelect()
    return setTimeout(
      () =>
        $target
          .parent()
          .next()
          .find('li[tabindex=0]')
          .focus(),
      1000
    )
  }

  initDroppable() {
    return this.$el.droppable({
      scope: 'outcomes',
      hoverClass: 'droppable',
      greedy: true,
      drop: (e, ui) => {
        const {model} = ui.draggable.data('view')
        const group = model instanceof Outcome ? model.outcomeGroup : model
        // don't re-add to group
        if (group.id === this.model.id) return
        const originaldir = this.dir.sidebar._findLastDir()
        this.triggerSelect() // select to get the directory ready
        const disablingDfd = new $.Deferred()
        this.dir.$el.disableWhileLoading(disablingDfd)
        return this.dir.sidebar
          .dirForGroup(this.model)
          .promise()
          .done(dir => dir.moveModelHere(model, originaldir).done(() => disablingDfd.resolve()))
      }
    })
  }

  render() {
    this.$el.attr('data-id', this.model.get('id'))
    this.$el.html(`\
<a href="#" class="ellipsis" title="${h(this.model.get('title'))}">
<i class="icon-folder"></i>
<span>${h(this.model.get('title'))}</span>
</a>\
`)
    this.initDroppable()
    return super.render(...arguments)
  }
}
OutcomeGroupIconView.initClass()
