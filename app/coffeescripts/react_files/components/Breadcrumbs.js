#
# Copyright (C) 2014 - present Instructure, Inc.
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

define [
  'i18n!react_files'
  'jquery'
  'underscore'
  'react'
  'react-dom'
  'prop-types'
  'jsx/files/BreadcrumbCollapsedContainer'
  '../modules/customPropTypes'
], (I18n, $, _, React, ReactDOM, PropTypes, BreadcrumbCollapsedContainerComponent, customPropTypes) ->

  MAX_CRUMB_WIDTH = 500
  MIN_CRUMB_WIDTH = 80

  BreadcrumbCollapsedContainer =   BreadcrumbCollapsedContainerComponent

  Breadcrumbs =
    displayName: 'Breadcrumbs'

    propTypes:
      rootTillCurrentFolder: PropTypes.arrayOf(customPropTypes.folder)
      contextAssetString: PropTypes.string.isRequired

    getInitialState: ->
      {
        maxCrumbWidth: MAX_CRUMB_WIDTH
        availableWidth: 200000
      }

    componentWillMount: ->
      # Get the existing Canvas breadcrumbs, store them, and remove them
      @fixOldCrumbs()

    componentDidMount: ->
      # Attach the resize listener to dynamically change the components
      # involved in the breadcrumb trail.
      $(window).on('resize', @handleResize)
      @handleResize()


    componentWillUnmount: ->
      $(window).off('resize', @handleResize)

    fixOldCrumbs: ->
      $oldCrumbs = $('#breadcrumbs')
      heightOfOneBreadcrumb = $oldCrumbs.find('li:visible:first').height() * 1.5
      homeName = $oldCrumbs.find('.home').text()
      $a = $oldCrumbs.find('li').eq(1).find('a')
      contextUrl = $a.attr('href')
      contextName = $a.text()
      $('.ic-app-nav-toggle-and-crumbs').remove()

      @setState({homeName, contextUrl, contextName, heightOfOneBreadcrumb})

    handleResize: ->
      @startRecalculating(window.innerWidth)

    startRecalculating: (newAvailableWidth) ->
      @setState({
        availableWidth: newAvailableWidth
        maxCrumbWidth: MAX_CRUMB_WIDTH
      }, @checkIfCrumbsFit)

    componentWillReceiveProps: -> setTimeout(@startRecalculating)

    checkIfCrumbsFit: ->
      return unless @state.heightOfOneBreadcrumb
      breadcrumbHeight = $(ReactDOM.findDOMNode(@refs.breadcrumbs)).height()
      if (breadcrumbHeight > @state.heightOfOneBreadcrumb) and (@state.maxCrumbWidth > MIN_CRUMB_WIDTH)
        maxCrumbWidth = Math.max(MIN_CRUMB_WIDTH, @state.maxCrumbWidth - 20)
        @setState({maxCrumbWidth}, @checkIfCrumbsFit)
