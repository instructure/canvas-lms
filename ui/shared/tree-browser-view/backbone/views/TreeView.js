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
import $ from 'jquery'
import {debounce, uniqueId} from 'lodash'
import PaginatedCollectionView from '@canvas/pagination/backbone/views/PaginatedCollectionView'
import TreeItemView from './TreeItemView'
import collectionTemplate from '../../jst/TreeCollection.handlebars'
import htmlEscape from '@instructure/html-escape'

extend(TreeView, Backbone.View)

function TreeView() {
  return TreeView.__super__.constructor.apply(this, arguments)
}

TreeView.prototype.tagName = 'li'

TreeView.optionProperty('nestingLevel')

TreeView.optionProperty('onlyShowSubtrees')

TreeView.optionProperty('onClick')

TreeView.optionProperty('dndOptions')

TreeView.optionProperty('href')

TreeView.optionProperty('focusStyleClass')

TreeView.optionProperty('selectedStyleClass')

TreeView.optionProperty('autoFetch')

TreeView.optionProperty('fetchItAll')

TreeView.prototype.defaults = {
  nestingLevel: 1,
}

TreeView.prototype.attributes = function () {
  return {
    role: 'treeitem',
    'data-id': this.model.id,
    'aria-expanded': '' + !!this.model.isExpanded,
    'aria-level': this.nestingLevel,
    'aria-label':
      this.model.get('custom_name') || this.model.get('name') || this.model.get('title'),
    id: this.tagId,
  }
}

TreeView.prototype.events = {
  'click .treeLabel': 'toggle',
  'selectItem .treeFile, .treeLabel': 'selectItem',
}

TreeView.prototype.initialize = function () {
  this.tagId = uniqueId('treenode-')
  this.render = debounce(this.render)
  this.model.on('all', this.render, this)
  this.model.getItems().on('all', this.render, this)
  this.model.getSubtrees().on('all', this.render, this)
  const res = TreeView.__super__.initialize.apply(this, arguments)
  this.render()
  return res
}

TreeView.prototype.render = function () {
  this.renderSelf()
  return this.renderContents()
}

TreeView.prototype.toggle = function (event) {
  // prevent it from bubbling up to parents and from following link
  event.preventDefault()
  event.stopPropagation()
  this.model.toggle({
    onlyShowSubtrees: this.onlyShowSubtrees,
  })
  return this.$el.attr(this.attributes())
}

TreeView.prototype.selectItem = function (event) {
  const $span = $(event.target).find('span')
  return $span.trigger('click')
}

TreeView.prototype.title_text = function () {
  return this.model.get('custom_name') || this.model.get('name') || this.model.get('title')
}

TreeView.prototype.renderSelf = function () {
  if (this.model.isNew()) {
    return
  }
  this.$el.attr(this.attributes())
  this.$label ||
    (this.$label = (function (_this) {
      return function () {
        _this.$labelInner = $('<span>').click(function (event) {
          // Lets this work well with file browsers like New Files
          if (_this.selectedStyleClass) {
            $('.' + _this.selectedStyleClass).each(function (key, element) {
              return $(element).removeClass(_this.selectedStyleClass)
            })
            $(event.target).addClass(_this.selectedStyleClass)
          }
          return typeof _this.onClick === 'function' ? _this.onClick(event, _this.model) : void 0
        })
        const icon_class = _this.model.get('for_submissions') ? 'icon-folder-locked' : 'icon-folder'
        const $label = $(
          '<a\n  class="treeLabel"\n  role="presentation"\n  tabindex="-1"\n>\n  <i class="icon-mini-arrow-right"></i>\n  <i class="' +
            htmlEscape(icon_class) +
            '"></i>\n</a>'
        )
          .append(_this.$labelInner)
          .prependTo(_this.$el)
        if (_this.dndOptions && !_this.model.get('for_submissions')) {
          const toggleActive = function (makeActive) {
            return function () {
              return $label.toggleClass('activeDragTarget', makeActive)
            }
          }
          $label.on({
            'dragenter dragover': function (event) {
              return _this.dndOptions.onItemDragEnterOrOver(event.originalEvent, toggleActive(true))
            },
            'dragleave dragend': function (event) {
              return _this.dndOptions.onItemDragLeaveOrEnd(event.originalEvent, toggleActive(false))
            },
            drop(event) {
              return _this.dndOptions.onItemDrop(
                event.originalEvent,
                _this.model,
                toggleActive(false)
              )
            },
          })
        }
        return $label
      }
    })(this)())
  this.$labelInner.text(this.title_text())
  this.$label
    .attr('href', (typeof this.href === 'function' ? this.href(this.model) : void 0) || '#')
    .toggleClass('expanded', !!this.model.isExpanded)
    .toggleClass('loading after', !!this.model.isExpanding)
  if (this.selectedStyleClass) {
    return this.$label.toggleClass(
      this.selectedStyleClass,
      window.location.pathname ===
        (typeof this.href === 'function' ? this.href(this.model) : void 0)
    )
  }
}

TreeView.prototype.renderContents = function () {
  let itemsView, subtreesView
  if (this.model.isExpanded) {
    if (!this.$treeContents) {
      this.$treeContents = $("<ul role='group' class='treeContents'/>").appendTo(this.$el)
      subtreesView = new PaginatedCollectionView({
        collection: this.model.getSubtrees(),
        itemView: TreeView,
        itemViewOptions: {
          nestingLevel: this.nestingLevel + 1,
          onlyShowSubtrees: this.onlyShowSubtrees,
          onClick: this.onClick,
          dndOptions: this.dndOptions,
          href: this.href,
          focusStyleClass: this.focusStyleClass,
          selectedStyleClass: this.selectedStyleClass,
          autoFetch: this.autoFetch,
          fetchItAll: this.fetchItAll,
        },
        tagName: 'li',
        className: 'subtrees',
        template: collectionTemplate,
        scrollContainer: this.$treeContents.closest('div[role=tabpanel]'),
        autoFetch: this.autoFetch,
        fetchItAll: this.fetchItAll,
      })
      this.$treeContents.append(subtreesView.render().el)
      if (!this.onlyShowSubtrees) {
        itemsView = new PaginatedCollectionView({
          collection: this.model.getItems(),
          itemView: TreeItemView,
          itemViewOptions: {
            nestingLevel: this.nestingLevel + 1,
          },
          tagName: 'li',
          className: 'items',
          template: collectionTemplate,
          scrollContainer: this.$treeContents.closest('div[role=tabpanel]'),
        })
        this.$treeContents.append(itemsView.render().el)
      }
    }
    return this.$('> .treeContents').removeClass('hidden')
  } else {
    return this.$('> .treeContents').addClass('hidden')
  }
}

export default TreeView
