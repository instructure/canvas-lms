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

import $ from 'jquery'
import {View} from '@canvas/backbone'
import CollectionView from '@canvas/backbone-collection-view'
import GroupCategoryView from './GroupCategoryView'
import GroupCategory from '@canvas/groups/backbone/models/GroupCategory'
import groupCategoriesTemplate from '../../jst/groupCategories.handlebars'
import tabTemplate from '../../jst/groupCategoryTab.handlebars'
import awaitElement from '@canvas/await-element'
import {renderCreateDialog} from '@canvas/groups/react/CreateOrEditSetModal'
import 'jqueryui/tabs'

export default class GroupCategoriesView extends CollectionView {
  static initClass() {
    this.prototype.template = groupCategoriesTemplate

    this.prototype.className = 'group_categories_area'

    this.prototype.els = {
      ...CollectionView.prototype.els,
      '#group_categories_tabs': '$tabs',
      'li.static': '$static',
      '#add-group-set': '$addGroupSetButton',
      '.empty-groupset-instructions': '$emptyInstructions',
    }

    this.prototype.events = {
      'click #add-group-set': 'addGroupSet',
      'tabsactivate #group_categories_tabs': 'activatedTab',
    }

    this.prototype.itemView = View.extend({
      tagName: 'li',
      template() {
        return tabTemplate({
          ...this.model.present(),
          id: this.model.id != null ? this.model.id : this.model.cid,
        })
      },
    })
  }

  render() {
    super.render(...arguments)
    if (this.collection.length > 1) {
      this.reorder()
    }
    this.refreshTabs()
    return this.loadTabFromUrl()
  }

  refreshTabs() {
    if (this.collection.length > 0) {
      this.$tabs.find('ul.ui-tabs-nav li.static').remove()
      this.$tabs.find('ul.ui-tabs-nav').prepend(this.$static)
    }
    // setup the tabs
    if (this.$tabs.data('ui-tabs')) {
      this.$tabs.tabs('refresh').show()
    } else {
      this.$tabs.tabs({cookie: {}}).show()
    }

    this.$tabs.tabs({
      beforeActivate(event, ui) {
        return !ui.newTab.hasClass('static')
      },
    })

    // hide/show the instruction text
    if (this.collection.length > 0) {
      this.$emptyInstructions.hide()
    } else {
      this.$emptyInstructions.show()
      // hide the emtpy tab set which may have borders that would otherwise show
      this.$tabs.hide()
    }
    this.$tabs.find('li.static a').unbind()
    return this.$tabs.on('keydown', 'li.static', function (event) {
      event.stopPropagation()
      if (event.keyCode === 13 || event.keyCode === 32) {
        return (window.location.href = $(this).find('a').attr('href'))
      }
    })
  }

  loadTabFromUrl() {
    if (window.location.hash === '#new' && !this.pendingCreation) {
      return this.addGroupSet()
    } else {
      this.pendingCreation = false
      const id = window.location.hash.split('-')[1]
      if (id != null) {
        const model = this.collection.get(id)
        if (model) {
          return this.$tabs.tabs({active: this.tabOffsetOfModel(model)})
        }
      }
    }
  }

  tabOffsetOfModel(model) {
    const index = this.collection.indexOf(model)
    const numStatic = this.$static.length
    return index + numStatic
  }

  createItemView(model) {
    // create and add tab panel
    const panelId = `tab-${model.id != null ? model.id : model.cid}`
    const $panel = $('<div/>')
      .addClass('tab-panel')
      .attr('id', panelId)
      .data('loaded', false)
      .data('model', model)
    this.$tabs.append($panel)
    // If this is the first panel, load the contents
    if (this.$tabs.find('.tab-panel').length === 1) {
      this.loadPanelView($panel, model)
    }
    // create the <li> tab view
    const view = super.createItemView(...arguments)
    view.listenTo(model, 'change', () => {
      // e.g. change name
      view.render()
      this.reorder()
      return this.refreshTabs()
    })
    return view
  }

  renderItem() {
    super.renderItem(...arguments)
    return this.refreshTabs()
  }

  removeItem(model) {
    super.removeItem(...arguments)
    // remove the linked panel and refresh the tabs
    model.itemView.remove()
    if (model.panelView != null) {
      model.panelView.remove()
    }
    return this.refreshTabs()
  }

  async addGroupSet(e) {
    e?.preventDefault?.()
    this.pendingCreation = true
    const mountPoint = await awaitElement('create-group-set-modal-mountpoint')
    const createResult = await renderCreateDialog(mountPoint)
    if (createResult) {
      const cat = new GroupCategory()
      cat.set(createResult)
      this.collection.add(cat)
      window.location.hash = `tab-${createResult.id}`
      this.reorder()
      this.refreshTabs()
      this.$tabs.tabs({active: this.tabOffsetOfModel(cat)})
    }
  }

  activatedTab(event, ui) {
    const $panel = ui.newPanel
    return this.loadPanelView($panel)
  }

  loadPanelView($panel) {
    // there is a bug here where we load the first tab, then immediately load the tab from the hash
    if (!$panel.data('loaded')) {
      const model = $panel.data('model')
      const categoryView = new GroupCategoryView({model})
      categoryView.setElement($panel)
      categoryView.render()
      // return the created tab <li> view
      model.panelView = $panel
      // store now loaded
      $panel.data('loaded', true)
    }
    return $panel
  }

  toJSON() {
    const json = super.toJSON(...arguments)
    json.ENV = ENV
    const context = ENV.context_asset_string.split('_')
    json.context = context[0]
    json.isCourse = json.context === 'course'
    json.context_id = context[1]
    return json
  }
}
GroupCategoriesView.initClass()
