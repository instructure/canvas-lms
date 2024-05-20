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
import {each, clone, indexOf, find, last} from 'lodash'
import Backbone from '@canvas/backbone'
import Outcome from '../../../backbone/models/Outcome'
import OutcomeGroup from '../../../backbone/models/OutcomeGroup'
import OutcomesDirectoryView from './OutcomesDirectoryView'
import FindDirectoryView from './FindDirectoryView'

const I18n = useI18nScope('outcomesSidebarView')

let findDialog

export default class SidebarView extends Backbone.View {
  static initClass() {
    this.prototype.directoryWidth = 200
    this.prototype.entryHeight = 30

    this.prototype.events = {'click .outcome-level': 'clickOutcomeLevel'}
  }

  // options must include rootOutcomeGroup or directoryView
  initialize(opts) {
    super.initialize(...arguments)
    this.inFindDialog = opts.inFindDialog
    this.readOnly = opts.readOnly
    this.selectFirstItem = opts.selectFirstItem
    this.directories = []
    this.cachedDirectories = {}
    this.$sidebar = this.$el.parent()
    this.$sidebar.width(this.directoryWidth)
    if ((this.rootOutcomeGroup = opts.rootOutcomeGroup)) {
      this.addDirFor(this.rootOutcomeGroup, true)
    } else {
      this.addDir(opts.directoryView)
    }
    return this.render()
  }

  clickOutcomeLevel(e) {
    const clickedOutside = e.target === e.currentTarget
    if (!clickedOutside) return
    const dir = $(e.target).data('view')
    return this.selectDir(dir)
  }

  resetSidebar() {
    each(this.directories, d => d.remove())
    this.directories = []
    this.cachedDirectories = {}
    return this.addDirFor(this.rootOutcomeGroup, true)
  }

  // Adds a directory view for an outcome group.
  // Returns the directory view.
  addDirFor(outcomeGroup, isRoot = false) {
    let dir
    if (this.cachedDirectories[outcomeGroup.id]) {
      dir = this.cachedDirectories[outcomeGroup.id]
    } else {
      const parent = last(this.directories)
      const DirectoryClass = outcomeGroup.get('directoryClass') || OutcomesDirectoryView
      const i = indexOf(this.directories, this.selectedDir())
      dir = new DirectoryClass({
        outcomeGroup,
        parent,
        readOnly: this.readOnly,
        selectFirstItem: isRoot && this.selectFirstItem,
        inFindDialog: this.inFindDialog,
        directoryDepth: i + 1,
      })
      this.firstDir = false
    }
    return this.addDir(dir)
  }

  // Adds a directory view.
  // Returns the directory view.
  addDir(dir) {
    if (dir.outcomeGroup) this.cachedDirectories[dir.outcomeGroup.id] = dir
    dir.off('select')
    dir.on('select', this.selectDir, this)
    dir.sidebar = this
    dir.clearSelection()
    this.directories.push(dir)
    this.updateSidebarWidth()
    this.renderDir(dir)
    return dir
  }

  // Insert and select a newly created/imported outcome or group.
  addAndSelect(model) {
    // verify outcomeGroup is set
    if (model instanceof Outcome) {
      model.outcomeGroup = this.selectedGroup().toJSON()
    } else {
      model.set('parent_outcome_group', this.selectedGroup().toJSON())
    }

    // add to collection
    const dir = this._findLastDir(d => !d.selectedModel || d.selectedModel instanceof Outcome)
    if (model instanceof Outcome) {
      dir.outcomes.add(model)
    } else {
      dir.groups.add(model)
    }
    this._scrollToDir(indexOf(this.directories, dir), model)

    // select the view
    return model.trigger('select')
  }

  // Select the directory view and optionally select an Outcome or Group.
  selectDir(dir, selectedModel) {
    // If root selection is an outcome, don't have a dir. Get root most dir to clear selection.
    const useDir = dir || this.directories[0]
    if (useDir && !selectedModel) useDir.clearSelection()

    // remove all directories after the selected dir from @directories and the view
    const i = indexOf(this.directories, useDir)
    const dirsToRemove = this.directories.splice(i + 1, this.directories.length - (i + 1))
    each(dirsToRemove, d => d.remove())
    const isAddingDir = selectedModel instanceof OutcomeGroup && !selectedModel.isNew()
    if (isAddingDir) this.addDirFor(selectedModel)
    this.updateSidebarWidth()
    const scrollIndex = isAddingDir ? i + 1 : i
    this._scrollToDir(scrollIndex, selectedModel)
    // Determine which model to select based on going forward/backward and where we are in the tree.
    let wantSelectModel = selectedModel
    if (this.goingBack) {
      if (!useDir.parent) {
        wantSelectModel = null
      } else {
        wantSelectModel = useDir.outcomeGroup
      }
    }
    return this.trigger('select', wantSelectModel, this.directories)
  }

  refreshSelection(model) {
    const dir = this.selectedDir()
    if (model === dir.selectedModel) {
      dir.clearSelection()
      return model.trigger('select')
    }
  }

  selectedDir() {
    return this._findLastDir(d => d.selectedModel)
  }

  selectedModel() {
    return __guard__(this.selectedDir(), x => x.selectedModel)
  }

  selectedGroup() {
    let g = null
    this._findLastDir(d => {
      if (d.selectedModel instanceof OutcomeGroup) {
        return (g = d.selectedModel)
      }
    })
    return g || this.rootOutcomeGroup
  }

  clearOutcomeSelection() {
    return last(this.directories).clearOutcomeSelection()
  }

  // Go up a directory.
  goBack() {
    this.goingBack = true
    if (this.selectedModel() instanceof OutcomeGroup) {
      this.selectDir(this.selectedDir())
    } else {
      const i = indexOf(this.directories, this.selectedDir())
      this.selectDir(this.directories[i - 1])
    }

    this.selectedDir().makeFocusable()

    return (this.goingBack = false)
  }
  //      if @selectedModel() instanceof OutcomeGroup
  //        parentDir = @selectedDir().parent
  // #        @selectDir @selectedDir(), @selectedDir().parent?.selectedModel
  //      else
  //        i = _.indexOf @directories, @selectedDir()
  //        @selectDir @directories[i - 1]
  //      @goingBack = false

  updateSidebarWidth() {
    const sidebarWidth =
      this.directories.length === 1 ? this.directoryWidth : this.directoryWidth * 2
    this.$el.css({width: this.directoryWidth * this.directories.length})
    return this.$sidebar.animate({width: sidebarWidth})
  }

  renderDir(dir) {
    return this.$el.append(dir.render().el)
  }

  render() {
    this.$el.empty()
    each(this.directories, dir => this.renderDir(dir))
    return this
  }

  // passing in FindDialog because of circular dependency
  findDialog(FindDialog) {
    if (!findDialog) {
      findDialog = new FindDialog({
        title: I18n.t('titles.find_outcomes', 'Find Outcomes'),
        selectedGroup: this.selectedGroup(),
        directoryView: new FindDirectoryView({
          outcomeGroup: this.selectedGroup(),
        }),
      })
      findDialog.on('import', this.addAndSelect, this)
    } else {
      findDialog.updateSelection(this.selectedGroup())
    }
    return findDialog.show()
  }

  // Find a directory for a given outcome group or add a new directory view.
  dirForGroup(outcomeGroup) {
    return (
      find(this.directories, d => d.outcomeGroup === outcomeGroup) || this.addDirFor(outcomeGroup)
    )
  }

  moveItem(model, newGroup) {
    let dfd
    const originalGroup = model.get('parent_outcome_group') || model.outcomeGroup
    const originalDir = this.cachedDirectories[originalGroup.id]
    const targetDir = this.cachedDirectories[newGroup.id]
    if (originalGroup.id === newGroup.id) {
      $.flashError(
        I18n.t('%{model} is already located in %{newGroup}', {
          model: model.get('title'),
          newGroup: newGroup.get('title'),
        })
      )
      return
    }
    if (model instanceof OutcomeGroup) {
      dfd = originalDir.moveGroup(model, newGroup.toJSON())
    } else {
      dfd = originalDir.changeLink(model, newGroup.toJSON())
    }
    return dfd.done(() => {
      const itemType = model instanceof OutcomeGroup ? 'groups' : 'outcomes'
      if (targetDir) {
        dfd = targetDir[itemType].fetch()
        dfd.done(() => {
          return (targetDir.needsReset = true)
        })
      }
      originalDir[itemType].fetch()
      const parentDir = originalDir.parent
      if (parentDir) {
        this.selectDir(parentDir, parentDir.selectedModel)
      }
      model.trigger('finishedMoving')
      $('.selected:last').focus()
      // timeout necessary to announce move after modal closes following finishedMoving event
      return setTimeout(
        () =>
          $.flashMessage(
            I18n.t('Successfully moved %{model} to %{newGroup}', {
              model: model.get('title'),
              newGroup: newGroup.get('title'),
            })
          ),
        1500
      )
    })
  }

  _scrollToDir(dirIndex, model) {
    const scrollLeft = this.directoryWidth * (model instanceof Outcome ? dirIndex - 1 : dirIndex)
    this.$sidebar.animate({scrollLeft}, {duration: 200})
    const scrollTop =
      (this.entryHeight + 1) *
      indexOf(
        this.directories[dirIndex].views(),
        find(this.directories[dirIndex].views(), v => v.model === model)
      )
    return this.directories[dirIndex].$el.animate({scrollTop}, {duration: 200})
  }

  _findLastDir(f) {
    return find(clone(this.directories).reverse(), f) || last(this.directories)
  }
}
SidebarView.initClass()

function __guard__(value, transform) {
  return typeof value !== 'undefined' && value !== null ? transform(value) : undefined
}
