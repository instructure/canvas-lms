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

import {StyleSheet} from 'aphrodite'

export default StyleSheet.create({
  container: {
    marginBottom: '1em',
    overflow: 'auto',
  },
  list: {
    margin: '0 0 0 .8em',
    padding: '0 0 0 .2em',
    borderLeft: '1px dotted #ccc',
    listStyle: 'none outside',
    flex: 1,
  },
  node: {
    margin: 0,
    padding: 0,
    display: 'block',
  },
  loading: {
    marginLeft: '.8em',
    borderLeft: '1px dotted #ccc',
    padding: '.5em .7em',
  },
  button: {
    display: 'block',
    padding: '.3em',
    borderRadius: '.3em',
    backgroundColor: 'transparent',
    textAlign: 'left',
    margin: 0,
    fontFamily: 'inherit',
    fontSize: 'inherit',
    flex: 1,
    width: '100%',
    boxSizing: 'border-box',
    border: '1px solid transparent',
    transition: 'background-color 0.3s',
    wordBreak: 'break-all',
    ':hover': {
      backgroundColor: '#eee',
    },
    ':focus': {
      border: '1px solid #000',
      outline: 0,
    },
    ':active': {
      backgroundColor: '#ddd',
    },
  },
  file: {
    ':active': {
      backgroundColor: '#008a14',
    },
  },
})
