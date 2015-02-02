#
# Copyright (C) 2012 Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.
#

# PaginatedList.coffee
# This class paginates ajax results using a 'View More' link.
# It accepts two arguments: the element to insert the list into
# and an object literal of options. The following options are
# supported:
#   * url (required): the url to be requested
#   * template (required): the handlebars compiled template function.
#   * requestParams: additional parameters included in the GET request.
#   * presenter: a function that formats returned data for disply. should accept
#     one argument - the object or array returned from the server.
#   * start: if true, getJSON is called on construction. if not, user must
#     cal getData after instantiation.
# PaginatedList expects an empty <ul> wrapped in a <div>. The element
# passed to the constructor should be the <div>.

define ['jquery', 'i18n!paginated_list', 'vendor/spin', 'str/htmlEscape'], ($, I18n, Spinner, htmlEscape) ->
  class PaginatedList
    ##
    # I18n keys used by class
    keys:
      noResults: I18n.t('no_results_found', 'No Results')
      viewMore:  I18n.t('view_more_link', 'View More')

    ##
    # options for the wait spinners
    spinnerOptions:
      length: 4
      lines: 12
      radius: 7
      width: 2

    ##
    # default config. can be changed/overriden by @options param
    # passed to constructor.
    defaultOptions:
      presenter: false
      requestParams:
        page: 1
        per_page: 25
      start: true
      template: $.noop # empty fn, should be replaced by handlebars template
      url: '' # should be replaced by url to json data

    ##
    # PaginatedList constructor
    # @param el {element} a wrapped DOM element. should be a <div />
    #   with a single, empty <ul /> inside.
    # @param options {Object} instance-specific config.
    #   * url (required): the url to be requested. e.g. '/courses/1/enrollments'
    #   * template (required): a compiled template function from handlebars
    #   * requestParams: additional params included in the GET. overrides
    #       to paging params set in @defaultRequestParams are also included
    #       here.
    #   * presenter: a function that formats the returned data for display.
    #       function should accept an array or object parsed from JSON.
    #   * start: call getData if true. defaults to true.
    constructor: (el, options) ->
      @cacheElements(el)
      @options = $.extend {}, @defaultOptions, options
      @addEvents()
      @getData() if @options.start

    ##
    # cache all DOM elements for future use
    # @api private
    cacheElements: (el) ->
      @el =
        wrapper: el
        list: el.find('ul:first')
      if @el.wrapper.css('position') is 'static'
        @el.wrapper.css('position', 'relative')

    ##
    # attach events to DOM objects
    # @api private
    addEvents: ->
      @el.wrapper.delegate '.view-more-link', 'click', @getData

    ##
    # make ajax call to return paginated data
    # @return jqXHR (see http://api.jquery.com/jQuery.ajax/#jqXHR)
    # @api public
    getData: (e) =>
      e.preventDefault() if e
      @startSpinner(e)
      @currentRequest = $.getJSON @options.url, @options.requestParams, @onResponse

    ##
    # given paginated data, format and display it
    # @api private
    onResponse: (data) =>
      @stopSpinner()
      return @noResults() if data.length is 0
      data = @options.presenter(data) if @options.presenter
      @animateInResults $(@options.template(data))
      @updatePaging()

    ##
    # start wait spinner
    # @api private
    startSpinner: (spinnerOnBottom) ->
      @spinner = new Spinner(@spinnerOptions).spin(@el.wrapper[0]).el
      if spinnerOnBottom?
        $(@spinner).css
          bottom: 10
          top: 'auto'

    ##
    # stop wait spinner
    # @api private
    stopSpinner: ->
      $(@spinner).remove()

    ##
    # animate loaded results
    # @api private
    animateInResults: ($results) ->
      empty = @el.list.children().length == 0
      $results.css('display', 'none')
      @el.list.append $results
      $results.slideDown()

    ##
    # keep track of what page we're on. when the last page
    # has been loaded, remove the 'view more' link.
    # @api private
    updatePaging: ->
      if @hasNextPage()
        @options.requestParams.page++
        unless @pageLinkPresent
          @el.wrapper.append @viewMoreLinkHtml()
          @pageLinkPresent = true
      else
        @el.wrapper.find('.view-more-link').remove()

    ##
    # given a response, check the headers to see if there's another page.
    # @return boolean
    # @api private
    hasNextPage: ->
      @currentRequest.getAllResponseHeaders().match /rel="next"/

    ##
    # template for view more link
    # @return String
    # @api private
    viewMoreLinkHtml: ->
      '<a class="view-more-link" href="#">' + htmlEscape(@keys.viewMore) + '</a>'

    ##
    # template for no results notification
    # @return String
    # @api private
    noResults: ->
      @el.list.append "<li>#{htmlEscape @keys.noResults}</li>"
