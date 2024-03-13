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
import {useScope as useI18nScope} from '@canvas/i18n'
import Backbone from '@canvas/backbone'
import Outcome from '../../../backbone/models/Outcome'
import OutcomeGroup from '../../../backbone/models/OutcomeGroup'
import OutcomeView from './OutcomeView'
import OutcomeGroupView from './OutcomeGroupView'
import TreeBrowserView from '@canvas/tree-browser-view'
import RootOutcomesFinder from './RootOutcomesFinder'
import dialogTemplate from '../../jst/MoveOutcomeDialog.handlebars'
import noOutcomesWarning from '../../jst/noOutcomesWarning.handlebars'
import DefaultUrlMixin from '@canvas/backbone/DefaultUrlMixin'
import {subscribe} from 'jquery-tinypubsub'
import {raw} from '@instructure/html-escape'

const I18n = useI18nScope('contentview')

// This view is a wrapper for showing details for outcomes and groups.
// It uses OutcomeView and OutcomeGroupView to render

export default class ContentView extends Backbone.View {
  initialize({
    readOnly,
    setQuizMastery,
    useForScoring,
    instructionsTemplate,
    renderInstructions,
    inFindDialog,
  }) {
    this.readOnly = readOnly
    this.inFindDialog = inFindDialog
    this.setQuizMastery = setQuizMastery
    this.useForScoring = useForScoring
    this.instructionsTemplate = instructionsTemplate
    this.renderInstructions = renderInstructions
    super.initialize(...arguments)
    subscribe('renderNoOutcomeWarning', this.renderNoOutcomeWarning.bind(this))
    subscribe('clearNoOutcomeWarning', this.clearNoOutcomeWarning.bind(this))
    return this.render()
  }

  // accepts: Outcome and OutcomeGroup
  show(model) {
    if (model != null ? model.isNew() : undefined) return
    return this._show({model})
  }

  // accepts: Outcome and OutcomeGroup
  add(model) {
    this._show({model, state: 'add'})
    this.trigger('adding')
    return this.innerView.on('addSuccess', m => this.trigger('addSuccess', m))
  }

  // private
  _show(viewOpts) {
    viewOpts = {
      ...viewOpts,
      readOnly: this.readOnly,
      inFindDialog: this.inFindDialog,
      setQuizMastery: this.setQuizMastery,
      useForScoring: this.useForScoring,
    }
    if (this.innerView != null) {
      this.innerView.remove()
    }
    this.innerView = (() => {
      if (viewOpts.model instanceof Outcome) {
        return new OutcomeView(viewOpts)
      } else if (viewOpts.model instanceof OutcomeGroup) {
        return new OutcomeGroupView(viewOpts)
      }
    })()
    this.render()
    if (this.innerView instanceof OutcomeView) {
      return this.innerView.screenreaderTitleFocus()
    }
  }

  resetContent() {
    this.innerView = null
    return this.render()
  }

  render() {
    this.attachEvents()
    const html = (() => {
      if (this.innerView) {
        return this.innerView.render().el
      } else if (this.renderInstructions) {
        return this.instructionsTemplate()
      }
    })()
    this.$el.html(html)
    return this
  }

  attachEvents() {
    if (this.innerView == null) return
    this.innerView.on('deleteSuccess', () => this.trigger('deleteSuccess'))
    return this.innerView.on('move', outcomeItem => this.openDialog(outcomeItem))
  }

  openDialog(outcomeItem) {
    const dialogTree = this.createTree()
    const dialogWindow = this.createDialog()

    const moveDialog = {
      tree: dialogTree,
      window: dialogWindow,
      model: outcomeItem,
    }

    $(dialogTree.$el).appendTo('.form-dialog-content')
    $('.form-controls .btn[type=button]').bind('click', () => dialogWindow.dialog('close'))
    $('.form-controls .btn[type=submit]').bind('click', e => {
      e.preventDefault()
      if (dialogTree.activeTree) {
        this.trigger('move', moveDialog.model, dialogTree.activeTree.model)
        return moveDialog.model.on('finishedMoving', () => dialogWindow.dialog('close'))
      } else {
        return $.flashError(
          I18n.t("No directory is selected, please select a directory before clicking 'move'")
        )
      }
    })

    $(moveDialog.window).dialog(
      'option',
      'title',
      I18n.t('Where would you like to move %{title}?', {title: outcomeItem.get('title')})
    )
    $('.ui-dialog :button').blur()
    setTimeout(() => moveDialog.tree.focusOnOpen(), 200)
  }

  createTree() {
    const treeBrowser = new TreeBrowserView({
      rootModelsFinder: new RootOutcomesFinder(),
      focusStyleClass: 'MoveDialog__folderItem--focused',
      selectedStyleClass: 'MoveDialog__folderItem--selected',
      onlyShowSubtrees: true,
      onClick() {
        TreeBrowserView.prototype.setActiveTree(this, treeBrowser)
      },
    }).render()
    return treeBrowser
  }

  createDialog() {
    const dialog = $(dialogTemplate()).dialog({
      dialogClass: 'moveDialog',
      width: 600,
      height: 270,
      open() {
        $(this).show()
      },
      close(_e) {
        $(this).remove()
      },
      modal: true,
      zIndex: 1000,
    })
    return dialog
  }

  remove() {
    return this.innerView != null ? this.innerView.off('addSuccess') : undefined
  }

  renderNoOutcomeWarning() {
    if (this.$el != null) {
      this.$el.empty()
    }
    const noOutcomesLinkLabel = I18n.t(
      'You have no outcomes. Click here to go to the outcomes page.'
    )
    return this.$el != null
      ? this.$el.append(
          raw(
            noOutcomesWarning({
              addOutcomesUrl: `/${this._contextPath()}/outcomes`,
              noOutcomesLinkLabel,
            })
          )
        )
      : undefined
  }

  clearNoOutcomeWarning() {
    return this.$el != null ? this.$el.find('.no-outcomes-warning').empty() : undefined
  }
}
ContentView.mixin(DefaultUrlMixin)
