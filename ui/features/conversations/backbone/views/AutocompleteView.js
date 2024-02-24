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

import {useScope as useI18nScope} from '@canvas/i18n'
import Backbone from '@canvas/backbone'
import $ from 'jquery'
import {map, extend, each, reduce, indexOf, debounce, isEmpty, last, head} from 'lodash'
import PaginatedCollection from '@canvas/pagination/backbone/collections/PaginatedCollection'
import ConversationSearchResult from '../models/ConversationSearchResult'
import PaginatedCollectionView from '@canvas/pagination/backbone/views/PaginatedCollectionView'
import tokenTemplate from '../../jst/autocompleteToken.handlebars'
import resultTemplate from '../../jst/autocompleteResult.handlebars'
import 'jquery-scroll-into-view'

const I18n = useI18nScope('conversations')

// Public: Helper method for capitalizing a string
//
// string - The string to capitalize.
//
// Returns a capitalized string.
const capitalize = string => string.charAt(0).toUpperCase() + string.slice(1)

export default class AutocompleteView extends Backbone.View {
  static initClass() {
    // Public: Limit selection to one result.
    this.optionProperty('single')

    // Public: If true, don't display "All in ..." results.
    this.optionProperty('excludeAll')

    // Internal: Current result set from the server.
    this.prototype.collection = null

    // Internal: Current XMLHttpRequest (if any).
    this.prototype.currentRequest = null

    // Internal: Current context to filter searches by.
    this.prototype.currentContext = null

    // Internal: Parent of the current context.
    this.prototype.parentContexts = []

    // Internal: Currently selected model.
    this.prototype.selectedModel = null

    // Internal: Currently selected results.
    this.prototype.tokens = []

    // Internal: A cache of per-context permissions.
    this.prototype.permissions = {}

    // Internal: A cache of URL results.
    this.prototype.cache = {}

    this.prototype.messages = {
      noResults: I18n.t('no_results_found', 'No results found'),
      back: I18n.t('back', 'Back'),
      everyone(context) {
        return I18n.t('all_in_context', 'All in %{context}', {context})
      },
      private: I18n.t(
        'cannot_add_to_private',
        'You cannot add participants to a private conversation.'
      ),
    }

    // Internal: Map of key names to codes.
    this.prototype.keys = {
      8: 'backspace',
      13: 'enter',
      27: 'escape',
      38: 'up',
      40: 'down',
    }

    // Internal: Cached DOM element references.
    this.prototype.els = {
      '.ac-input-box': '$inputBox',
      '.ac-input': '$input',
      '.ac-token-list': '$tokenList',
      '.ac-result-wrapper': '$resultWrapper',
      '.ac-result-container': '$resultContainer',
      '.ac-result-contents': '$resultContents',
      '.ac-result-list': '$resultList',
      '.ac-placeholder': '$placeholder',
      '.ac-clear': '$clearBtn',
      '.ac-search-btn': '$searchBtn',
      '.ac-results-status': '$resultsStatus',
      '.ac-selected-name': '$selectedName',
    }

    // Internal: Event map.
    this.prototype.events = {
      'blur      .ac-input': '_onInputBlur',
      'click     .ac-input-box': '_onWidgetClick',
      'click     .ac-clear': '_onClearTokens',
      'click     .ac-token-remove-btn': '_onRemoveToken',
      'click     .ac-search-btn': '_onSearch',
      'keyclick  .ac-search-btn': '_onSearch',
      'focus     .ac-input': '_onInputFocus',
      'input     .ac-input': '_onSearchTermChange',
      'keydown   .ac-input': '_onInputAction',
      'mousedown .ac-result': '_onResultClick',
      'mouseenter .ac-result-list': '_clearSelectedStyles',
    }

    this.prototype.modelCache = new Backbone.Collection()
  }

  // Internal: Construct the search URL for the given term.
  url(term) {
    const baseURL = '/api/v1/search/recipients?'
    const params = {
      search: term,
      per_page: 20,
      'permissions[]': 'send_messages_all',
      messageable_only: true,
      synthetic_contexts: true,
    }
    if (this.currentContext) params.context = this.currentContext.id

    return (
      baseURL +
      reduce(
        params,
        (queryString, v, k) => {
          queryString.push(`${k}=${v}`)
          return queryString
        },
        []
      ).join('&')
    )
  }

  // Public: Create and configure a new instance.
  //
  // Returns an AutocompleteView instance.
  initialize() {
    super.initialize(...arguments)
    // After battling chrome, firefox, and IE this seems to be the best place to
    // inject some hackery to prevent focus/blur issues
    this.parentContexts = []
    this.currentContext = null
    this.recipientCounts = {}
    $(document).on('mousedown', this._onDocumentMouseDown.bind(this))

    this.render() // to initialize els
    this.$span = this._initializeWidthSpan()
    setTimeout(() => {
      if (this.options.disabled) this._disable()
    }, 0)
    this._fetchResults = debounce(this.__fetchResults, 250)
    return (this.resultView = new PaginatedCollectionView({
      el: this.$resultContents,
      scrollContainer: this.$resultContainer,
      buffer: 50,
      collection: new Backbone.Collection(),
      template: null,
      itemView: Backbone.View.extend({
        template: resultTemplate,
      }),
      itemViewOptions: {
        tagName: 'li',
        attributes() {
          const classes = ['ac-result']
          if (this.model.get('isContext')) classes.push('context')
          if (this.model.get('back')) classes.push('back')
          if (this.model.get('everyone')) classes.push('everyone')
          const attributes = {
            class: classes.join(' '),
            'data-id': this.model.id,
            'data-people-count': this.model.get('user_count'),
            'aria-label': this.model.get('name'),
            id: `result-${$.guid++}`, // for aria-activedescendant
          }
          attributes['aria-haspopup'] = this.model.get('isContext')
          return attributes
        },
      },
    }))
  }

  // Internal: Manage events on the results collection.
  //
  // Returns nothing.
  _attachCollection() {
    this.resultView.switchCollection(this.resultCollection)
    this.resultView.stopListening(this.resultCollection, 'reset', this.resultView.renderOnReset)
    return this.resultView.stopListening(
      this.resultCollection,
      'remove',
      this.resultView.removeItem
    )
  }

  // Public: Toggle visibility of result list.
  //
  // isVisible - A boolean to determine if the list should be shown.
  //
  // Returns the result list jQuery object.
  toggleResultList(isVisible) {
    this.$resultWrapper.attr('aria-hidden', !isVisible)
    this.$resultWrapper.toggle(isVisible)
    this.$input.attr('aria-expanded', isVisible)
    if (!isVisible) return this.$resultList.empty()
  }

  // Internal: Disable the autocomplete input.
  //
  // Returns nothing.
  _disable() {
    this.disable()
    this.$inputBox.attr('title', this.messages.private)
    this.$inputBox.attr('data-tooltip', '{"position":"bottom"}')
    return (this.disabled = true)
  }

  // Internal: Empty the current and parent contexts.
  //
  // Returns nothing.
  _resetContext() {
    if (this.hasExternalContext) {
      this.currentContext = isEmpty(this.parentContexts)
        ? this.currentContext
        : head(this.parentContexts)
    } else {
      this.currentContext = null
    }
    return (this.parentContexts = [])
  }

  // Internal: Create a <span /> to track search term width.
  //
  // Returns a jQuery-wrapped <span />.
  _initializeWidthSpan() {
    return $('<span />')
      .css({
        fontSize: '14px',
        position: 'absolute',
        top: '-9999px',
      })
      .appendTo('body')
  }

  // Internal: Add the given model to the cache.
  //
  // This is necessary because previously selected
  // tokens may not be present in the collection.
  _addToModelCache(model) {
    return this.modelCache.add(model)
  }

  // Internal: Get the given model from the collection.
  //
  // id - The ID of the model to return.
  //
  // Returns a model object.
  _getModel(id) {
    id = id && String(id)
    return this.modelCache.get(id)
  }

  // Internal: Remove the "selected" class from result list items.
  //
  // e - Event object.
  //
  // Returns nothing.
  _clearSelectedStyles(_e) {
    this.$resultList.find('.selected').removeClass('selected')
    return (this.selectedModel = null)
  }

  // Internal: Translate clicks anywhere into clicks on the input.
  //
  // e - Event object.
  //
  // Returns nothing.
  _onWidgetClick(_e) {
    return this.$input.focus()
  }

  // Internal: Delegate special key presses to their handler (if any).
  //
  // e - Event object.
  //
  // Returns nothing.
  _onInputAction(e) {
    let key
    if (!(key = this.keys[e.keyCode])) return
    const methodName = `_on${capitalize(key)}Key`
    if (typeof this[methodName] === 'function') return this[methodName].call(this, e)
  }

  _onDocumentMouseDown(e) {
    if (!this.$inputBox.hasClass('focused')) return

    // this is a hack so we can click the scroll bar without losing the result list
    const parentClassName = '.ac'
    const targetParent = $(e.target).closest(parentClassName)
    const inputParent = this.$input.closest(parentClassName)

    // normally I would just preventDefault(), IE was making that difficult
    this._shouldPreventBlur =
      targetParent.length && inputParent.length && targetParent[0] === inputParent[0]

    if (this._shouldPreventBlur) {
      return e.preventDefault()
    } else {
      // we are focused but we clicked outside of the area we care about unfocus
      return this._onInputBlur()
    }
  }

  // Internal: Remove focus styles on widget when input is blurred.
  //
  // e - Event object.
  //
  // Returns nothing.
  _onInputBlur(_e) {
    if (this._shouldPreventBlur) {
      this._shouldPreventBlur = false
      this.$input.focus()
      return
    }

    this.$inputBox.removeAttr('role')
    this.$inputBox.removeClass('focused')
    if (!this.tokens.length && !this.$input.val()) this.$placeholder.css({opacity: 1})
    this._resetContext()
    return this.toggleResultList(false)
  }

  // Internal: Set proper styles on widget when input is focused.
  //
  // e - Event object.
  //
  // Returns nothing.
  _onInputFocus(e) {
    this.$inputBox.addClass('focused')
    this.$inputBox.attr('role', 'application')
    this.$placeholder.css({opacity: 0})
    if (!$(e.target).hasClass('ac-input')) {
      return (this.$input[0].selectionStart = this.$input.val().length)
    }
  }

  // Internal: Fetch from server when the search term changes.
  //
  // e - Event object.
  //
  // Returns nothing.
  _onSearchTermChange(_e) {
    if (!this.$input.val()) {
      this.toggleResultList(false)
    } else {
      this._fetchResults()
    }
    this.$input.width(this.$span.text(this.$input.val()).width() + 15)
    return this.resultView.collection.each(m => this.resultView.removeItem(m))
  }

  // Internal: Display search results returned from the server.
  //
  // searchResults - An array of results from the server.
  //
  // Returns nothing.
  _onSearchResultLoad() {
    extend(this.permissions, this._getPermissions())
    if (!this.excludeAll && !!this._canSendToAll()) this._addEveryoneResult(this.resultCollection)
    this.resultCollection.each(this._addToModelCache.bind(this))
    const hasResults = this.resultCollection.length
    const isFinished = !this.nextRequest
    this._addBackResult(this.resultCollection)
    this.currentRequest = null
    if (!hasResults) {
      this.resultCollection.push(
        new ConversationSearchResult({id: 'no_results', name: '', noResults: true})
      )
    }
    if (isFinished) {
      this._drawResults()
    }
    if (this.nextRequest) this._fetchResults(true)
    return this.updateStatusMessage(this.resultCollection.length)
  }

  // Internal: Determine if the current user can send to all users in the course.
  //
  // Returns a boolean.
  _canSendToAll() {
    if (!this.currentContext) return false
    const key = this.currentContext.id.replace(/_(students|teachers)$/, '')
    return this.permissions[key]
  }

  // Internal: Return permissions hashes from the current results.
  //
  // Returns a hash.
  _getPermissions() {
    const permissions = this.resultCollection.filter(r =>
      r.attributes.hasOwnProperty('permissions')
    )
    return reduce(
      permissions,
      (map, result) => {
        const key = result.id.replace(/_(students|teachers)$/, '')
        map[key] = !!result.get('permissions').send_messages_all
        return map
      },
      {}
    )
  }

  // Internal: Add, if appropriate, an "All in %{context}" result to the
  //           search results.
  //
  // results - A search results array to mutate.
  //
  // Returns a new search results array.
  _addEveryoneResult(results) {
    if (!this.currentContext) return
    const name = this.messages.everyone(this.currentContext.name)
    const searchTerm = new RegExp(this.$input.val().trim(), 'gi')
    if (searchTerm && !name.match(searchTerm)) return results

    const actual_results = results.reject(
      result => result.attributes.back || result.attributes.noResults || result.attributes.everyone
    )
    if (!actual_results.length) return results

    if (this.currentContext.id.match(/course_\d+_(group|section)/)) return

    if (!this.currentContext.peopleCount) {
      this.currentContext.peopleCount = reduce(
        actual_results,
        (count, result) => count + (result.attributes.user_count || 0),
        0
      )
    }

    const tag = {
      id: this.currentContext.id,
      name,
      everyone: true,
      people: this.currentContext.peopleCount,
    }
    return results.unshift(new ConversationSearchResult(tag))
  }

  // Internal: Add, if appropriate, an "All in %{context}" result to the
  //           search results.
  //
  // results - A search results array to mutate.
  //
  // Returns a new search results array.
  _addBackResult(results) {
    if (!this.parentContexts.length) return results
    const tag = {id: 'back', name: this.messages.back, back: true, isContext: true}
    const back = new ConversationSearchResult(tag)
    results.unshift(back)
    return this._addToModelCache(back)
  }

  // Internal: Draw out search results to the DOM.
  //
  // Returns nothing.
  _drawResults() {
    this.resultView.empty = !this.resultView.collection.length
    this.resultView.$('.collectionViewItems').empty()
    this.resultView.render()
    const $el = this.$resultList.find('li:first').addClass('selected')
    this.selectedModel = this._getModel($el.attr('data-id'))
    return this.$input.attr('aria-activedescendant', $el.attr('id'))
  }

  // Internal: Fetch and display autocomplete results from the server.
  //
  // fetchIfEmpty - Fetch a result set, even if no query exists (default: false)
  //
  // Returns nothing.
  __fetchResults(fetchIfEmpty = false) {
    if (!this.$input.val() && !fetchIfEmpty) return
    const url = this._loadURL()
    if (!url) return
    this.currentUrl = url
    if (this.cache[url]) {
      this.resultCollection = this.cache[url]
      this._attachCollection()
      this.toggleResultList(true)
      return this._onSearchResultLoad()
    } else {
      this.resultCollection = new PaginatedCollection([], {model: ConversationSearchResult})
      this.resultCollection.url = url
      this.cache[url] = this.resultCollection
      this._attachCollection()
      this.currentRequest = this.resultCollection.fetch().done(this._onSearchResultLoad.bind(this))
      return this.toggleResultList(true)
    }
  }

  // Internal: Get URL for the current request, caching it as
  //   @nextRequest if needed.
  //
  // Returns a URL string (will be empty if current request is pending).
  _loadURL() {
    const searchURL = this.url(this.$input.val())
    if (this.currentRequest) {
      this.nextRequest = searchURL
      return ''
    } else {
      const previousNextRequest = this.nextRequest
      delete this.nextRequest
      return previousNextRequest || searchURL
    }
  }

  // Internal: Delete the last token.
  //
  // e - Event object.
  //
  // Returns nothing.
  _onBackspaceKey(_e) {
    if (!this.$input.val()) {
      return this._removeToken(last(this.tokens))
    }
  }

  // Internal: Close the result list without choosing an option.
  //
  // e - Event object.
  //
  // Returns nothing.
  _onEscapeKey(e) {
    e.preventDefault() && e.stopPropagation()
    this.toggleResultList(false)
    this._resetContext()
    return setTimeout(() => this.$input.focus(), 0)
  }

  // Internal: Add the current @selectedModel to the list of tokens.
  //
  // e - Event object.
  //
  // Returns nothing.
  _onEnterKey(e) {
    e.preventDefault() && e.stopPropagation()
    return this._activateSelected(e.metaKey || e.ctrlKey)
  }

  _activateSelected(keepOpen = false) {
    if (!this.selectedModel || this.selectedModel.get('noResults')) return
    if (this.selectedModel.get('back')) {
      this.currentContext = this.parentContexts.pop()
      return this._fetchResults(true)
    } else if (this.selectedModel.get('isContext')) {
      this.parentContexts.push(this.currentContext)
      this.$input.val('')
      this.currentContext = {
        id: this.selectedModel.id,
        name: this.selectedModel.get('name'),
        peopleCount: this.selectedModel.get('user_count'),
      }
      return this._fetchResults(true)
    } else {
      return this._addToken(this.selectedModel.attributes, keepOpen)
    }
  }

  // Internal: Handle down-arrow events.
  //
  // e - Event object.
  //
  // Returns nothing.
  _onDownKey(e) {
    return this._onArrowKey(e, 1)
  }

  // Internal: Handle up-arrow events.
  //
  // e - Event object.
  //
  // Returns nothing.
  _onUpKey(e) {
    return this._onArrowKey(e, -1)
  }

  // Internal: Move the current selection based on arrow key
  //
  // e - Event object
  // inc - The increment to the current selection index. -1 = up, +1 = down
  //
  // Returns nothing.
  _onArrowKey(e, inc) {
    // no keyboard nav when popup isn't open
    if (this.$resultWrapper.css('display') !== 'block') return

    e.stopPropagation()
    e.preventDefault()

    this.$resultList.find('li.selected:first').removeClass('selected')

    const currentIndex = this.selectedModel ? this.resultCollection.indexOf(this.selectedModel) : -1
    let newIndex = currentIndex + inc
    if (newIndex < 0) {
      newIndex = 0
    }
    if (newIndex >= this.resultCollection.length) newIndex = this.resultCollection.length - 1

    this.selectedModel = this.resultCollection.at(newIndex)
    const $el = this.$resultList.find(`[data-id=${this.selectedModel.id}]`)
    $el.scrollIntoView()
    this.$input.attr('aria-activedescendant', $el.addClass('selected').attr('id'))
    return this.updateSelectedNameForScreenReaders($el.text())
  }

  // Internal: Add the clicked model to the list of tokens.
  //
  // e - Event object.
  //
  // Returns nothing.
  _onResultClick(e) {
    if (e.button !== 0) return
    e.preventDefault() && e.stopPropagation()
    const $target = $(e.currentTarget)
    this.selectedModel = this.resultCollection.get($target.attr('data-id'))
    return this._activateSelected(e.metaKey || e.ctrlKey)
  }

  // Internal: Clear the current token.
  //
  // e - Event object.
  //
  // Returns nothing.
  _onClearTokens(e) {
    e.preventDefault()
    while (this.tokens.length) this._removeToken(this.tokens[0], false)
    this.$clearBtn.hide()
    if (!this.disabled) this.$input.prop('disabled', false).focus()
    // fire a single token change event
    this.trigger('enabled')
    return this.trigger('changeToken', this.tokenParams())
  }

  // Internal: Handle clicks on token remove buttons.
  //
  // e - Event object.
  //
  // Returns nothing.
  _onRemoveToken(e) {
    e.preventDefault()
    return this._removeToken($(e.currentTarget).siblings('input').val())
  }

  // Internal: Handle clicks to the search button.
  //
  // e - Event object.
  //
  // Returns nothing.
  _onSearch(_e) {
    if (this.$searchBtn.prop('disabled')) return
    this._fetchResults(true)
    return this.$input.focus()
  }

  checkRecipientTotal() {
    const total = reduce(this.recipientCounts, (sum, c) => sum + c, 0)
    if (total > ENV.CONVERSATIONS.MAX_GROUP_CONVERSATION_SIZE) {
      return this.trigger('recipientTotalChange', true)
    } else {
      return this.trigger('recipientTotalChange', false)
    }
  }

  // Internal: Add the given model to the token list.
  //
  // model - Result model (user or course)
  //
  // Returns nothing.
  _addToken(model, keepOpen = false) {
    if (this.disabled) return
    model.name = this._formatTokenName(model)
    this.tokens.push(model.id)
    this.$tokenList.append(tokenTemplate(model))

    this.recipientCounts[model.id] = model.people || 1
    this.checkRecipientTotal()

    if (!keepOpen) {
      this.toggleResultList(false)
      this.selectedModel = null
      this._resetContext()
    }
    this.$input.val('')
    if (this.options.single) {
      this.$clearBtn.show().focus()
      this.$input.prop('disabled', true)
      this.$searchBtn.prop('disabled', true)
      this.trigger('disabled')
    }

    this.trigger('changeToken', this.tokenParams())
    return this._refreshRecipientList()
  }

  // Internal: Prepares a given model's name for display.
  //
  // model - A ConversationSearchResult model's attributes.
  //
  // Returns a formatted name.
  _formatTokenName(model) {
    let parent
    if (!model.everyone) return model.name
    if ((parent = head(this.parentContexts))) {
      return `${parent.name}: ${this.currentContext.name}`
    } else {
      return this.currentContext.name
    }
  }

  // Internal: Remove the given model from the token list.
  //
  // id - The ID of the result to remove from the token list.
  // silent - If true, don't fire a changeToken event (default: false).
  //
  // Returns nothing.
  _removeToken(id, silent = false) {
    if (this.disabled) return
    this.$tokenList.find(`input[value=${id}]`).parent().remove()
    this.tokens.splice(indexOf(this.tokens, id), 1)
    if (!this.tokens.length) this.$clearBtn.hide()
    if (this.options.single && !this.tokens.length) {
      this.$input.prop('disabled', false)
      this.$searchBtn.prop('disabled', false)
      this.trigger('enabled')
    }

    this.recipientCounts[id] = 0
    this.checkRecipientTotal()

    if (!silent) this.trigger('changeToken', this.tokenParams())
    return this._refreshRecipientList()
  }

  _refreshRecipientList() {
    const recipientNames = []
    each(this.tokenModels(), model => {
      recipientNames.push(model.get('name'))
    })
    $('#recipient-label').text(recipientNames.join(', '))
  }

  // Public: Return the current tokens as an array of params.
  //
  // Returns an array of context_id strings.
  tokenParams() {
    return map(this.tokens, t => {
      if (t.match) {
        return t
      } else {
        return `user_${t}`
      }
    })
  }

  // Public: Get the currently selected models.
  //
  // Returns an array of models.
  tokenModels() {
    return map(this.tokens, this._getModel.bind(this))
  }

  // Public: Set the current course context.
  //
  // context - A context string, e.g. "course_123"
  // disable - Disable the input if no context is given (default: false).
  //
  // Returns nothing.
  setContext(context, disable = false) {
    if (!context.id) context = null
    if (disable && !ENV.CONVERSATIONS.CAN_MESSAGE_ACCOUNT_CONTEXT && !this.disabled) {
      this.disable(!context)
    }
    if (
      (context != null ? context.id : undefined) ===
      (this.currentContext != null ? this.currentContext.id : undefined)
    )
      return
    this.currentContext = context
    this.hasExternalContext = !!context
    this.tokens = []
    this.recipientCounts = {}
    this.checkRecipientTotal()
    return this.$tokenList.find('li.ac-token').remove()
  }

  disable(value = true) {
    $('#recipient-row').toggle(!value)
  }

  // Public: Put the given tokens in the token list.
  //
  // tokens - Array of Result model object (course or user)
  //
  // Returns nothing.
  setTokens(tokens) {
    each(tokens, token => {
      this._addToModelCache(token)
      this._addToken(token)
    })
  }

  // Internal: Set the status message for screenreaders
  //
  //
  updateStatusMessage(resultCount) {
    // Empty the text
    this.$resultsStatus.text('')
    // Refill the text
    return this.$resultsStatus.text(
      I18n.t(
        'result_status',
        'The autocomplete has %{results} entries listed, use the up and down arrow keys' +
          ' to navigate to a listing, then press enter to add the person to the To field.',
        {results: resultCount}
      )
    )
  }

  // Internal: Set selected name for screenreaders
  //
  // had to add this for IE :/
  updateSelectedNameForScreenReaders(selectedName) {
    // Empty the text
    this.$selectedName.text('')
    // Refill the text
    return this.$selectedName.text(selectedName)
  }
}
AutocompleteView.initClass()
