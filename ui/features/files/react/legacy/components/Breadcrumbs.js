/*
 * Copyright (C) 2014 - present Instructure, Inc.
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

import $ from 'jquery'
import ReactDOM from 'react-dom'
import PropTypes from 'prop-types'
import customPropTypes from '@canvas/files/react/modules/customPropTypes'

const MAX_CRUMB_WIDTH = 500
const MIN_CRUMB_WIDTH = 80

export default {
  displayName: 'Breadcrumbs',

  propTypes: {
    rootTillCurrentFolder: PropTypes.arrayOf(customPropTypes.folder),
    contextAssetString: PropTypes.string.isRequired,
  },

  getInitialState() {
    return {
      maxCrumbWidth: MAX_CRUMB_WIDTH,
      availableWidth: 200000,
    }
  },

  UNSAFE_componentWillMount() {
    // Get the existing Canvas breadcrumbs, store them, and remove them
    this.fixOldCrumbs()
  },

  componentDidMount() {
    // Attach the resize listener to dynamically change the components
    // involved in the breadcrumb trail.
    $(window).on('resize', this.handleResize)
    this.handleResize()
  },

  componentWillUnmount() {
    $(window).off('resize', this.handleResize)
  },

  fixOldCrumbs() {
    const $oldCrumbs = $('#breadcrumbs')
    const heightOfOneBreadcrumb = $oldCrumbs.find('li:visible:first').height() * 1.5
    const homeName = $oldCrumbs.find('.home').text()
    const $a = $oldCrumbs.find('li').eq(1).find('a')
    const contextUrl = $a.attr('href')
    const contextName = $a.text()
    $('.ic-app-nav-toggle-and-crumbs').remove()

    this.setState({homeName, contextUrl, contextName, heightOfOneBreadcrumb})
  },

  handleResize() {
    this.startRecalculating(window.innerWidth)
  },

  startRecalculating(newAvailableWidth) {
    this.setState(
      {
        availableWidth: newAvailableWidth,
        maxCrumbWidth: MAX_CRUMB_WIDTH,
      },
      this.checkIfCrumbsFit
    )
  },

  UNSAFE_componentWillReceiveProps() {
    setTimeout(this.startRecalculating)
  },

  checkIfCrumbsFit() {
    if (!this.state.heightOfOneBreadcrumb) return

    const breadcrumbHeight = $(ReactDOM.findDOMNode(this.refs.breadcrumbs)).height()
    if (
      breadcrumbHeight > this.state.heightOfOneBreadcrumb &&
      this.state.maxCrumbWidth > MIN_CRUMB_WIDTH
    ) {
      const maxCrumbWidth = Math.max(MIN_CRUMB_WIDTH, this.state.maxCrumbWidth - 20)
      this.setState({maxCrumbWidth}, this.checkIfCrumbsFit)
    }
  },
}
