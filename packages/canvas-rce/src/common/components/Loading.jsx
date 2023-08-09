/*
 * Copyright (C) 2018 - present Instructure, Inc.
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

import PropTypes from 'prop-types'

import React, {Component} from 'react'
import formatMessage from '../../format-message'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {StyleSheet, css} from 'aphrodite'

function Loading(props) {
  const className = (css(styles.loading) + ' ' + props.className).trim()
  return (
    <span className={className}>
      <ScreenReaderContent>{formatMessage('Loading...')}</ScreenReaderContent>
      <span className={css(styles.dot, styles.dot0)} />
      <span className={css(styles.dot, styles.dot1)} />
      <span className={css(styles.dot, styles.dot2)} />
    </span>
  )
}

Loading.propTypes = {
  className: PropTypes.string,
}

Loading.defaultProps = {
  className: '',
}

const opacityKeyframes = {
  '0%': {
    opacity: 0,
  },
  '50%': {
    opacity: 1,
  },
  '100%': {
    opacity: 0,
  },
}

const styles = StyleSheet.create({
  loading: {
    display: 'inline-flex',
    alignItems: 'center',
    justifyContent: 'space-around',
    width: '48px',
    height: '10px',
  },
  dot: {
    animationName: [opacityKeyframes],
    animationDuration: '1.95s',
    animationIterationCount: 'infinite',
    animationDirection: 'linear',
    background: '#666',
    borderRadius: '8px',
    width: '10px',
    height: '10px',
    flex: 'none',
  },
  dot0: {
    animationDelay: '-1.8s',
  },
  dot1: {
    animationDelay: '-1.6s',
  },
  dot2: {
    animationDelay: '-1.4s',
  },
})

export default Loading
