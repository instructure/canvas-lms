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

import {useScope as useI18nScope} from '@canvas/i18n'
import $ from 'jquery'
import {map, each, isEmpty, last} from 'lodash'
import htmlEscape from '@instructure/html-escape'
import PaginatedView from '@canvas/pagination/backbone/views/PaginatedView'
import OutcomeGroup from '../../../backbone/models/OutcomeGroup'
import OutcomeCollection from '../../../backbone/collections/OutcomeCollection'
import OutcomeGroupCollection from '../collections/OutcomeGroupCollection'
import OutcomeGroupIconView from './OutcomeGroupIconView'
import OutcomeIconView from './OutcomeIconView'
import {publish} from 'jquery-tinypubsub'
import '@canvas/jquery/jquery.disableWhileLoading'
import 'jqueryui/draggable'
import 'jqueryui/droppable'
import '@canvas/rails-flash-notifications'

const I18n = useI18nScope('OutcomesDirectoryView')

// The outcome group "directory" browser.
export default class OutcomesDirectoryView extends PaginatedView {
  static initClass() {
    this.prototype.tagName = 'ul'
    this.prototype.className = 'outcome-level'
  }

  // if opts includes 'outcomeGroup', an instance of OutcomeGroup,
  // then the groups and the outcomes for the outcomeGroup will be fetched.
  initialize(opts) {
    this.inFindDialog = opts.inFindDialog
    this.readOnly = opts.readOnly
    this.parent = opts.parent
    const outcomeGroupTitle = opts.outcomeGroup.attributes.title
    const ariaLabel = `Listing of child outcomes for ${outcomeGroupTitle}`
    this.$el.attr('aria-label', ariaLabel)
    // the way the event listeners work between OutcomeIconView, OutcomesDirectoryView
    // and SidebarView can cause items to become unselectable following a move. The
    // below attribute is using brute-force to make the view reset to address this problem
    // until we can find a better solution
    this.needsReset = false

    if ((this.outcomeGroup = opts.outcomeGroup)) {
      if (!this.groups) {
        this.groups = new OutcomeGroupCollection()
        this.groups.url = this.outcomeGroup.get('subgroups_url')
      }
      this.groups.on('add reset', this.reset, this) // TODO: make add more efficient
      this.groups.on('remove', this.removeGroup, this)
      this.groups.on('fetched:last', this.fetchOutcomes, this)

      if (!this.outcomes) {
        this.outcomes = new OutcomeCollection()
        this.outcomes.url = this.outcomeGroup.get('outcomes_url') + '?outcome_style=full'
      }
      this.outcomes.on('add remove reset', this.reset, this)
    }

    // for PaginatedView
    // @collection starts as @groups but can later change to @outcomes
    this.collection = this.groups
    this.paginationScrollContainer = this.$el
    super.initialize(opts)

    this.loadDfd = $.Deferred()

    if (this.outcomeGroup) {
      this.$el.disableWhileLoading(this.groups.fetch())
    }

    if (opts.selectFirstItem) return this.loadDfd.done(this.selectFirstOutcome.bind(this))
  }

  initDroppable() {
    return this.$el.droppable({
      scope: 'outcomes',
      hoverClass: 'outcome-level-hover',
      drop: (e, ui) => {
        // don't re-add to this group
        if (ui.draggable.parent().get(0) === e.target) return
        const {model} = ui.draggable.data('view')
        return this.moveModelHere(model)
      },
    })
  }

  // use this promise to know when both groups and outcomes have been loaded
  promise() {
    return this.loadDfd.promise()
  }

  // Public: move a model from some dir to this
  moveModelHere(model, originalDir) {
    let dfd
    model.collection.remove(model)
    if (model instanceof OutcomeGroup) {
      this.groups.add(model)
      dfd = this.moveGroup(model, this.outcomeGroup.toJSON())
    } else {
      this.outcomes.add(model)
      dfd = this.changeLink(model, this.outcomeGroup.toJSON())
    }
    return dfd.done(() => {
      model.trigger('select')
      if (originalDir) return (originalDir.needsReset = true)
    })
  }

  // Internal: change the outcome link to the newGroup
  changeLink(outcome, newGroup) {
    const disablingDfd = new $.Deferred()
    this.$el.disableWhileLoading(disablingDfd)

    function onFail(_m, _r) {
      disablingDfd.reject()
      return $.flashError(
        I18n.t('flash.error', 'An error occurred. Please refresh the page and try again.')
      )
    }

    // create new link
    const oldGroup = outcome.outcomeGroup
    outcome.outcomeGroup = newGroup
    outcome.setUrlTo('add')
    $.ajaxJSON(outcome.url, 'POST', {outcome_id: outcome.get('id'), move_from: oldGroup.id})
      .done(modelData => {
        // reset urls etc.
        outcome.set(outcome.parse(modelData))
        $.flashMessage(I18n.t('flash.updateSuccess', 'Update successful'))
        return disablingDfd.resolve()
      })
      .fail(onFail)

    return disablingDfd
  }

  // Internal: change the group's parent to the newGroup
  moveGroup(group, newGroup) {
    const disablingDfd = new $.Deferred()

    function onFail(_m, _r) {
      disablingDfd.reject()
      return $.flashError(
        I18n.t('flash.error', 'An error occurred. Please refresh the page and try again.')
      )
    }

    group.setUrlTo('edit')
    $.ajaxJSON(group.url, 'PUT', {parent_outcome_group_id: newGroup.id})
      .done(modelData => {
        // reset urls etc.
        group.set(group.parse(modelData))
        $.flashMessage(I18n.t('flash.updateSuccess', 'Update successful'))
        return disablingDfd.resolve()
      })
      .fail(onFail)

    this.$el.disableWhileLoading(disablingDfd)
    return disablingDfd
  }

  makeFocusable() {
    if (this.$el.find('[tabindex=0]').length > 0) return
    if (this.views().length > 0) {
      return this.views()[0].makeFocusable()
    }
  }

  selectFirstOutcome() {
    $('ul.outcome-level li:first').click()
  }

  // Overriding
  paginationLoaderTemplate() {
    return `<li><span class='loading-more'> \
${htmlEscape(I18n.t('Loading more results'))}</span></li>`
  }

  // Overriding to insert into the ul.
  showPaginationLoader() {
    if (this.$paginationLoader == null) {
      this.$paginationLoader = $(this.paginationLoaderTemplate())
    }
    return this.$el.append(this.$paginationLoader)
  }

  // Fetch outcomes after all the groups have been fetched.
  fetchOutcomes() {
    this.collection = this.outcomes
    this.bindPaginationEvents()
    this.outcomes.fetch({success: () => this.loadDfd.resolve(this)})
    this.startPaginationListener()
    return this.showPaginationLoader()
  }

  triggerSelect(sv) {
    this.clearSelection()
    this.selectedModel = sv.model
    sv.select()
    return this.trigger('select', this, sv.model)
  }

  // Cache the backbone views for outcomes and groups.
  // Groups are shown first.
  views() {
    if (this._views && !isEmpty(this._views)) {
      return this._views
    }

    this._views = this._viewsFor(this.groups.models, OutcomeGroupIconView).concat(
      this._viewsFor(this.outcomes.models, OutcomeIconView)
    )
    for (const v of this._views) {
      v.on('select', this.triggerSelect.bind(this))
      if (v.model === this.selectedModel) v.select()
    }
    return this._views
  }

  reset() {
    this.needsReset = false
    this._clearViews()
    return this.render()
  }

  removeGroup(group) {
    this.reset()
    if (group === __guard__(last(this.sidebar.directories), x => x.outcomeGroup)) {
      return this.trigger('select', this, null)
    }
  }

  remove() {
    this._clearViews()
    this.selectedModel = null
    return super.remove(...arguments)
  }

  clearSelection(e) {
    if (e != null) {
      e.preventDefault()
    }
    this.prevSelectedModel = this.selectedModel
    this.selectedModel = null
    each(this.views(), v => v.unSelect())
  }

  clearOutcomeSelection() {
    // eslint-disable-next-line no-undef
    if (typeof Outcome !== 'undefined' && this.selectedModel instanceof Outcome) {
      return this.clearSelection()
    }
  }

  render() {
    this.$el.empty()
    if (this.needsReset) return this.reset()
    each(this.views(), v => this.$el.append(v.render().el))
    if (this.inFindDialog) this.handleWarning()
    if (!this.readOnly) this.initDroppable()
    this.startPaginationListener()
    // Make the first <li /> tabbable for accessibility purposes.
    this.$('li:first').attr('tabindex', 0)
    this.$el.data('view', this)
    return this
  }

  handleWarning() {
    if (
      !this.parent &&
      isEmpty(this.groups.models) &&
      isEmpty(this.outcomes.models) &&
      isEmpty(this.views())
    ) {
      return publish('renderNoOutcomeWarning')
    } else {
      return publish('clearNoOutcomeWarning')
    }
  }

  // private
  _viewsFor(models, ViewClass) {
    return map(models, model => new ViewClass({model, readOnly: this.readOnly, dir: this}))
  }

  // private
  _clearViews() {
    each(this._views, v => v.remove())
    return (this._views = null)
  }
}
OutcomesDirectoryView.initClass()

function __guard__(value, transform) {
  return typeof value !== 'undefined' && value !== null ? transform(value) : undefined
}
