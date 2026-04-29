/*
 * Copyright (C) 2015 - present Instructure, Inc.
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

import React from 'react'
import PropTypes from 'prop-types'
import $ from 'jquery'

const DOCUMENT_NODE = 9
const ELEMENT_NODE = 1

class SVGWrapper extends React.Component {
  static propTypes = {
    url: PropTypes.string.isRequired,
    fillColor: PropTypes.string,
    style: PropTypes.any,
    ariaHidden: PropTypes.bool,
    ariaLabel: PropTypes.string,
  }

  componentDidMount() {
    this.fetchSVG()
  }

  UNSAFE_componentWillReceiveProps(newProps) {
    if (newProps.url !== this.props.url) {
      this.fetchSVG()
    }
    if (newProps.fillColor !== this.props.fillColor) {
      this.setSVGFillColor(newProps.fillColor)
    }
  }

  fetchSVG() {
    if (process.env.NODE_ENV === 'test') return
    $.ajax(this.props.url, {
      success: data => {
        this.svg = data

        if (data.nodeType === DOCUMENT_NODE) {
          this.svg = data.firstChild
        }

        if (this.svg.nodeType !== ELEMENT_NODE && this.svg.nodeName !== 'SVG') {
          throw new Error(
            `SVGWrapper: SVG Element must be returned by request to ${this.props.url}`,
          )
        }

        if (this.props.ariaHidden !== undefined) {
          this.svg.setAttribute('aria-hidden', this.props.ariaHidden)
        }

        if (this.props.ariaLabel) {
          this.svg.setAttribute('aria-label', this.props.ariaLabel)
        }

        this.setSVGFillColor(this.props.fillColor)
        this.svg.setAttribute('focusable', false)
        this.rootSpan.innerHTML = ''
        this.rootSpan.appendChild(this.svg)
      },
    })
  }

  setSVGFillColor(color) {
    if (!color || !this.svg) return
    this.svg.setAttribute('style', `fill:${color}`)
  }

  render() {
    return (
      <span
        style={this.props.style}
        ref={c => {
          this.rootSpan = c
        }}
      />
    )
  }
}

export default SVGWrapper
