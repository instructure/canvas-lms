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
import {find} from 'lodash'
import template from '../jst/ModuleSequenceFooter.handlebars'
import {useScope as useI18nScope} from '@canvas/i18n'
import htmlEscape from '@instructure/html-escape'
import '@canvas/jquery/jquery.ajaxJSON'

const I18n = useI18nScope('sequence_footer')

// Summary
//   Creates a new ModuleSequenceFooter so clicking to see the next item in a module
//   can be done easily.
//
//   Required options:
//     assetType : string
//     assetID   : integer
//
//   ie:
//     $('#footerDiv').moduleSequenceFooter({
//       assetType: 'Assignment'
//       assetID: 1
//       courseID: 25
//     })
//
//   You can optionally set options on the prototype for all instances of this plugin by default
//   by doing:
//
//   $.fn.moduleSequenceFooter.options = {
//     assetType: 'Assignment'
//     assetID: 1
//     courseID: 25
//   }
let msfInstanceCounter = 0

$.fn.moduleSequenceFooter = function (options = {}) {
  // You must pass in a assetType and assetId or we throw an error.
  if (!options.assetType || !options.assetID) {
    throw new Error('Option must be set with assetType and assetID')
  }

  this.msfAnimation = enabled =>
    this.find('.module-sequence-padding, .module-sequence-footer').toggleClass(
      'no-animation',
      !enabled
    )

  if (!this.data('msfInstance')) {
    // After fetching, @msfInstance will have the following
    // @hide: bool
    // @previous: Object
    // @next : Object
    this.msfInstance = new $.fn.moduleSequenceFooter.MSFClass(options)
    this.data('msfInstance', this.msfInstance)
    this.msfInstance.fetch().done(() => {
      if (this.msfInstance.hide) {
        this.hide()
        return
      }

      this.html(
        template({
          instanceNumber: this.msfInstance.instanceNumber,
          previous: this.msfInstance.previous,
          next: this.msfInstance.next,
        })
      )
      if (options && options.animation !== undefined) {
        this.msfAnimation(options.animation)
      }
      this.show()
      $(window).triggerHandler('resize')

      if (options.onFetchSuccess) {
        options.onFetchSuccess()
      }
    })
  }
  return this
}

export default class ModuleSequenceFooter {
  // Icon class map used to determine which icon class should be placed
  // on a tooltip
  // @api private

  iconClasses = {
    ModuleItem: 'icon-module',
    File: 'icon-paperclip',
    Page: 'icon-document',
    Discussion: 'icon-discussion',
    Assignment: 'icon-assignment',
    Quiz: 'icon-quiz',
    ExternalTool: 'icon-link',
    ExternalUrl: 'icon-link',
    'Lti::MessageHandler': 'icon-link',
  }

  // Sets up the class variables and generates a url. Fetch should be
  // called somewhere else to set up the data.

  constructor(options = {}) {
    this.instanceNumber = msfInstanceCounter++
    this.courseID = options.courseID || (typeof ENV !== 'undefined' && ENV.course_id)
    this.assetID = options.assetID
    this.assetType = options.assetType
    this.location = options.location || document.location
    this.previous = {}
    this.next = {}
    this.url = `/api/v1/courses/${this.courseID}/module_item_sequence`
  }

  getQueryParams(qs) {
    let tokens
    qs = qs.split('+').join(' ')
    const params = {}
    const re = /[?&]?([^=]+)=([^&]*)/g

    while ((tokens = re.exec(qs))) {
      params[decodeURIComponent(tokens[1])] = decodeURIComponent(tokens[2])
    }

    return params
  }

  // Retrieve data based on the url, asset_type and asset_id. @success is called after a
  // fetch is finished. This will then setup data to be used elsewhere.
  // @api public

  fetch() {
    const params = this.getQueryParams(this.location.search)
    if (params.module_item_id) {
      return $.ajaxJSON(
        this.url,
        'GET',
        {
          asset_type: 'ModuleItem',
          asset_id: params.module_item_id,
          frame_external_urls: true,
        },
        this.success,
        null,
        {}
      )
    } else {
      return $.ajaxJSON(
        this.url,
        'GET',
        {
          asset_type: this.assetType,
          asset_id: this.assetID,
          frame_external_urls: true,
        },
        this.success,
        null,
        {}
      )
    }
  }

  // Determines if the data retrieved should be used to generate a buttom bar or hide it. We
  // can only have 1 item in the data set for this to work else we hide the sequence bar.
  // # @api private

  success = data => {
    this.modules = data.modules

    // Currently only supports 1 item in the items array
    if (!(data && data.items && data.items.length === 1)) {
      this.hide = true
      return
    }

    this.item = data.items[0]
    // Show the buttons if they aren't null or paths are locked/processing
    if ((this.previous.show = this.item.prev)) this.buildPreviousData()
    if (this.item.next || this.awaitingPathProgress()) {
      this.next.show = true
      const awaitingPathProgress = this.awaitingPathProgress()
      awaitingPathProgress ? this.buildNextPathData() : this.buildNextData()
    }
  }

  // Each button needs to build a data that the handlebars template can use. For example, data for
  // each button could look like this:
  //  @previous = previous: {
  //     show: true
  //     url: http://foobar.baz
  //     tooltip: <strong>Previous Module:</strong> <br> Going to the fair
  //     tooltipText: Previous Module: Going to the fair
  //   }
  //
  // If the previous item is in another module, then the module ids won't be the same and we need
  // to display the module name instead of the item title.
  // @api private

  buildPreviousData() {
    this.previous.url = this.item.prev.html_url
    this.previous.externalItem = this.item.prev.type === 'ExternalUrl' && this.item.prev.new_tab

    if (this.item.current.module_id === this.item.prev.module_id) {
      this.previous.tooltip = `<i class='${htmlEscape(
        this.iconClasses[this.item.prev.type]
      )}'></i> ${htmlEscape(this.item.prev.title)}`
      this.previous.tooltipText = I18n.t('prev_module_item_desc', 'Previous: *item*', {
        wrapper: this.item.prev.title,
      })
    } else {
      // module id is different
      const module = find(this.modules, m => m.id === this.item.prev.module_id)
      this.previous.tooltip = `<strong style='float:left'>${htmlEscape(
        I18n.t('prev_module', 'Previous Module:')
      )}</strong> <br> ${htmlEscape(module.name)}`
      this.previous.tooltipText = I18n.t('prev_module_desc', 'Previous Module: *module*', {
        wrapper: module.name,
      })
    }
  }

  // Each button needs to build a data that the handlebars template can use. For example, data for
  // each button could look like this:
  //  @next = next: {
  //     show: true
  //     url: http://foobar.baz
  //     tooltip: <strong>Next Module:</strong> <br> Going to the fair
  //     tooltipText: Next Module: Going to the fair
  //   }
  //
  // If the next item is in another module, then the module ids won't be the same and we need
  // to display the module name instead of the item title.
  // @api private

  buildNextPathData() {
    const masteryPath = this.item.mastery_path
    if (masteryPath.awaiting_choice) {
      this.next.url = masteryPath.choose_url
      this.next.tooltipText = I18n.t('Choose the next mastery path')
    } else {
      const lockedMessage = I18n.t('Next mastery path is currently locked')
      const processingMessage = I18n.t(
        'Next mastery path is still processing, please periodically refresh the page'
      )
      const tooltipText = masteryPath.locked ? lockedMessage : processingMessage
      this.next.modules_tab_disabled = masteryPath.modules_tab_disabled
      this.next.url = masteryPath.modules_url
      this.next.tooltipText = tooltipText
    }
    // xsslint safeString.property tooltipText
    this.next.tooltip = `<i class='${htmlEscape(this.iconClasses.ModuleItem)}'/> ${
      this.next.tooltipText
    }`
  }

  buildNextData() {
    this.next.url = this.item.next.html_url
    this.next.externalItem = this.item.next.type === 'ExternalUrl' && this.item.next.new_tab

    if (this.item.current.module_id === this.item.next.module_id) {
      this.next.tooltip = `<i class='${htmlEscape(
        this.iconClasses[this.item.next.type]
      )}'></i> ${htmlEscape(this.item.next.title)}`
      this.next.tooltipText = I18n.t('Next: *item*', {wrapper: this.item.next.title})
    } else {
      // module id is different
      const module = find(this.modules, m => m.id === this.item.next.module_id)
      this.next.tooltip = `<strong style='float:left'>${htmlEscape(
        I18n.t('next_module', 'Next Module:')
      )}</strong> <br> ${htmlEscape(module.name)}`
      this.next.tooltipText = I18n.t('next_module_desc', 'Next Module: *module*', {
        wrapper: module.name,
      })
    }
  }

  awaitingPathProgress() {
    const masteryPath = this.item.mastery_path
    if (masteryPath && masteryPath.is_student) {
      return masteryPath.awaiting_choice || masteryPath.locked || masteryPath.still_processing
    }
  }
}

$.fn.moduleSequenceFooter.MSFClass = ModuleSequenceFooter
