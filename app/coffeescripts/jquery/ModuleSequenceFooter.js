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
import template from 'jst/jquery/ModuleSequenceFooter'
import _ from 'underscore'
import I18n from 'i18n!sequence_footer'
import htmlEscape from 'str/htmlEscape'
import 'jquery.ajaxJSON'

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
//   You can optionaly set options on the prototype for all instances of this plugin by default
//   by doing:
//
//   $.fn.moduleSequenceFooter.options = {
//     assetType: 'Assigbnment'
//     assetID: 1
//     courseID: 25
//   }
let msfInstanceCounter = 0

$.fn.moduleSequenceFooter = function (options = {}) {
  // You must pass in a assetType and assetId or we throw an error.
  if (!options.assetType || !options.assetID) {
    throw 'Option must be set with assetType and assetID'

  }

  this.msfAnimation = enabled =>
    this.find('.module-sequence-padding, .module-sequence-footer').toggleClass('no-animation', !enabled)

  // After fetching, @msfInstance will have the following
  // @hide: bool
  // @previous: Object
  // @next : Object
  this.msfInstance = new $.fn.moduleSequenceFooter.MSFClass(options)
  this.msfInstance.fetch().done(() => {
    this.msfInstance.fetch_module_items(this.msfInstance.moduleID).done(() => {
      const module = JSON.parse(window.localStorage.getItem(`module|${this.msfInstance.moduleID}`)) || {}
      const items = module.items || []
      const showModule = items.length > 0
      const currentItem = _.findWhere(items, {id: this.msfInstance.item.current.id})

      
      if (currentItem) {
        let lessons = _.where(items, {indent: 0})
        if (!lessons.length) lessons = _.where(items, {indent: currentItem.indent})
        var nextLesson, previousLesson
  
        var lessonBookendStart = _.last(lessons.filter((l) => {
          return currentItem.position >= l.position
        }))
  
        var lessonBookendEnd = _.first(lessons.filter((l) => {
          return currentItem.position <= l.position
        }))

        var next
        if (lessonBookendEnd) {
          next = ( lessonBookendStart.id === lessonBookendEnd.id ) ? lessons[lessons.findIndex((i) => {return i.id == lessonBookendEnd.id}) + 1] : lessonBookendEnd;
        } else {
          next = false
        }

        var lessonArray
        if (next) {
          lessonArray = items.filter((i) => {
            return lessonBookendStart.position < i.position && i.position < next.position
          })
        } else {
          lessonArray = items.filter((i) => {
            return lessonBookendStart.position < i.position
          })
        }
      }

      if (this.msfInstance.hide) {
        this.hide()
        return
      }

      this.html(template({
        showModule: showModule,
        items: lessonArray || [],
        module: module,
        currentItem: currentItem || false,
        currentID: this.msfInstance.assetID,
        instanceNumber: this.msfInstance.instanceNumber,
        previous: this.msfInstance.previous,
        next: this.msfInstance.next,
      }))
      if (options && options.animation !== undefined) {
        this.msfAnimation(options.animation)
      }
      this.show()
      $(window).triggerHandler('resize')

    })
  })


  return this
}

export default class ModuleSequenceFooter {

  // Icon class map used to determine which icon class should be placed
  // on a tooltip
  // @api private

  iconClasses = {
    ModuleItem: 'icon-module',
    File: 'icon-download',
    Page: 'icon-document',
    Discussion: 'icon-discussion',
    Assignment: 'icon-assignment',
    Quiz: 'icon-quiz',
    ExternalTool: 'icon-link',
    'Lti::MessageHandler': 'icon-link'
  }

  // Sets up the class variables and generates a url. Fetch should be
  // called somewhere else to set up the data.

  constructor (options = {}) {
    this.instanceNumber = msfInstanceCounter++
    this.courseID = options.courseID || (typeof ENV !== 'undefined' && ENV.course_id)
    this.assetID = options.assetID
    this.assetType = options.assetType
    this.location = options.location || document.location
    this.previous = {}
    this.next = {}
    this.current = {}
    this.url = `/api/v1/courses/${this.courseID}/module_item_sequence`
    this.module_items_url = `/api/v1/courses/${this.courseID}/modules/`
  }

  getQueryParams (qs) {
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

  fetch () {
    const params = this.getQueryParams(this.location.search)

    if (params.module_item_id) {
      return $.ajaxJSON(this.url, 'GET', {
        asset_type: 'ModuleItem',
        include: 'items',
        asset_id: params.module_item_id,
        frame_external_urls: true
      }, this.success, null, {})
    } else {
      return $.ajaxJSON(this.url, 'GET', {
        asset_type: this.assetType,
        asset_id: this.assetID,
        include: 'items',
        frame_external_urls: true
      }, this.success, null, {})
    }
  }

  fetch_module_items (id) {
    return $.ajaxJSON(`${this.module_items_url}${id}`, 'GET', {
      include: ['items', 'content_details'],
    }, this.success_module_items, null, {})
  }

  // Determines if the data retrieved should be used to generate a buttom bar or hide it. We
  // can only have 1 item in the data set for this to work else we hide the sequence bar.
  // # @api private

  success = (data) => {
    this.modules = data.modules
    // Currently only supports 1 item in the items array
    if (!(data && data.items && data.items.length === 1)) {
      this.hide = true
      return
    }
    this.current = data.current
    this.item = data.items[0]
    this.current = this.item.current || {}
    this.currentModule = _.findWhere(this.modules, {id: this.current.module_id}) || {}
    this.moduleID = this.currentModule.id || null
    // Show the buttons if they aren't null
    if ((this.next.show = this.item.next)) this.buildNextData()
    if ((this.previous.show = this.item.prev)) this.buildPreviousData()
  }

  success_module_items = (data) => {
    this.moduleID = data.id
    window.localStorage.setItem(`module|${data.id}`, JSON.stringify(data))
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

  buildPreviousData () {
    this.previous.url = this.item.prev.html_url

    if (this.item.current.module_id === this.item.prev.module_id) {
      this.previous.tooltip =
        `<i class='${htmlEscape(this.iconClasses[this.item.prev.type])}'></i> ${
          htmlEscape(this.item.prev.title)
        }`
      this.previous.tooltipText = I18n.t('prev_module_item_desc', 'Previous: *item*', {wrapper: this.item.prev.title})
    } else {
      // module id is different
      const module = _.find(this.modules, m => m.id === this.item.prev.module_id)
      this.previous.tooltip =
        `<strong style='float:left'>${
          htmlEscape(I18n.t('prev_module', 'Previous Module:'))
        }</strong> <br> ${htmlEscape(module.name)}`
      this.previous.tooltipText = I18n.t('prev_module_desc', 'Previous Module: *module*', {wrapper: module.name})
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

  buildNextData () {
    this.next.url = this.item.next.html_url

    if (this.item.current.module_id === this.item.next.module_id) {
      this.next.tooltip =
        `<i class='${htmlEscape(this.iconClasses[this.item.next.type])}'></i> ${
          htmlEscape(this.item.next.title)
        }`
      this.next.tooltipText = I18n.t('next_module_item_desc', 'Next: *item*', {wrapper: this.item.next.title})
    } else {
      // module id is different
      const module = _.find(this.modules, m => m.id === this.item.next.module_id)
      this.next.tooltip =
        `<strong style='float:left'>${
          htmlEscape(I18n.t('next_module', 'Next Module:'))
        }</strong> <br> ${htmlEscape(module.name)}`
      this.next.tooltipText = I18n.t('next_module_desc', 'Next Module: *module*', {wrapper: module.name})
    }
  } 
}

$.fn.moduleSequenceFooter.MSFClass = ModuleSequenceFooter
