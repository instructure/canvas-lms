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
import OutcomeGroup from '../models/OutcomeGroup'
import Progress from '@canvas/progress/backbone/models/Progress'
import DialogBaseView from '@canvas/dialog-base-view'
import SidebarView from '../../sidebar-view/backbone/views/index'
import ContentView from '../../content-view/backbone/views/index'
import browserTemplate from '../../jst/browser.handlebars'
import instructionsTemplate from '../../jst/findInstructions.handlebars'
import '@canvas/rails-flash-notifications'
import '@canvas/jquery/jquery.disableWhileLoading'

const I18n = useI18nScope('outcomesFindDialog')

// Creates a popup dialog similar to the main outcomes browser minus the toolbar.
export default class FindDialog extends DialogBaseView {
  dialogOptions() {
    return {
      id: 'import_dialog',
      title: this.title,
      width: 1000,
      resizable: true,
      close() {
        $('.find_outcome').focus()
      },
      buttons: [
        {
          text: I18n.t('#buttons.cancel', 'Cancel'),
          click: e => this.cancel(e),
        },
        {
          text: I18n.t('#buttons.import', 'Import'),
          class: 'btn-primary',
          click: e => this.import(e),
        },
      ],
      modal: true,
      zIndex: 1000,
    }
  }

  // Required options:
  //   selectedGroup, title
  // For the sidebar either directoryView or rootOutcomeGroup is required
  initialize(opts) {
    this.selectedGroup = opts.selectedGroup
    this.title = opts.title
    this.shouldImport = opts.shouldImport !== false
    this.disableGroupImport = opts.disableGroupImport

    super.initialize(...arguments)
    this.render()
    // so we don't mess with other jquery dialogs
    this.dialog.parent().find('.ui-dialog-buttonpane').css('margin-top', 0)

    this.sidebar = new SidebarView({
      el: this.$el.find('.outcomes-sidebar .wrapper'),
      directoryView: opts.directoryView,
      rootOutcomeGroup: opts.rootOutcomeGroup,
      readOnly: true,
      inFindDialog: true,
    })
    this.content = new ContentView({
      el: this.$el.find('.outcomes-content'),
      instructionsTemplate,
      readOnly: true,
      inFindDialog: true,
      setQuizMastery: opts.setQuizMastery,
      useForScoring: opts.useForScoring,
    })

    // sidebar events
    this.sidebar.on('select', this.content.show.bind(this.content))
    this.sidebar.on('select', this.showOrHideImport.bind(this))

    return this.showOrHideImport()
  }

  updateSelection(selectedGroup) {
    return (this.selectedGroup = selectedGroup)
  }

  // link an outcome or copy/link an outcome group into @selectedGroup
  import(e) {
    e.preventDefault()
    const model = this.sidebar.selectedModel()
    // add optional attributes for use in logic elsewhere
    if (this.content.setQuizMastery) {
      model.quizMasteryLevel = parseFloat(this.$el.find('#outcome_mastery_at').val()) || 0
    }
    if (this.content.useForScoring) {
      model.useForScoring = this.$el.find('#outcome_use_for_scoring').prop('checked')
    }
    if (model.get('dontImport')) {
      return alert(I18n.t('dont_import', 'This group cannot be imported.'))
    }
    if (!this.shouldImport) {
      this.trigger('import', model)
      this.close()
      return
    }
    if (window.confirm(this.confirmText(model))) {
      let dfd, url
      if (model instanceof OutcomeGroup) {
        url = this.selectedGroup.get('import_url')
        const progress = new Progress()
        dfd = $.ajaxJSON(url, 'POST', {
          source_outcome_group_id: model.get('id'),
          async: true,
        })
          .pipe(resp => {
            progress.set('url', resp.url)
            progress.poll()
            return progress.pollDfd
          })
          .pipe(() => $.ajaxJSON(progress.get('results').outcome_group_url, 'GET'))
      } else {
        url = this.selectedGroup.get('outcomes_url')
        dfd = $.ajaxJSON(url, 'POST', {outcome_id: model.get('id')})
      }
      this.$el.disableWhileLoading(dfd)
      return $.when(dfd)
        .done((response, _status, _deferred) => {
          const importedModel = model.clone()
          if (importedModel instanceof OutcomeGroup) {
            importedModel.set(response)
          } else {
            importedModel.outcomeLink = {...model.outcomeLink}
            importedModel.outcomeGroup = response.outcome_group
            importedModel.outcomeLink.url = response.url
            importedModel.set({
              context_id: response.context_id,
              context_type: response.context_type,
            })
          }
          this.trigger('import', importedModel)
          this.close()
          return $.flashMessage(I18n.t('flash.importSuccess', 'Import successful'))
        })
        .fail(() =>
          $.flashError(
            I18n.t(
              'flash.importError',
              'An error occurred while importing. Please try again later.'
            )
          )
        )
    }
  }

  render() {
    this.$el.html(browserTemplate({skipToolbar: true}))
    return this
  }

  showOrHideImport() {
    const model = this.sidebar.selectedModel()
    let canShow = true
    if (!model || model.get('dontImport')) {
      canShow = false
    } else if (model && model instanceof OutcomeGroup && this.disableGroupImport) {
      canShow = false
    }
    $('.ui-dialog-buttonpane .btn-primary').toggle(canShow)
  }

  confirmText(model) {
    const target =
      this.selectedGroup.get('title') ||
      I18n.t('top_level', '%{context} Top Level', {context: this.selectedGroup.get('context_type')})
    if (model instanceof OutcomeGroup) {
      return I18n.t('confirm.import_group', 'Import group "%{group}" to group "%{target}"?', {
        group: model.get('title'),
        target,
      })
    } else {
      return I18n.t('confirm.import_outcome', 'Import outcome "%{outcome}" to group "%{target}"?', {
        outcome: model.get('title'),
        target,
      })
    }
  }
}
