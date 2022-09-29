// Copyright (C) 2021 - present Instructure, Inc.
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

import {cloneElement, useEffect, useRef} from 'react'
import PropTypes from 'prop-types'

const Focus = ({children, timeout = 0}) => {
  const ref = useRef(null)

  useEffect(() => {
    const focus = () => {
      ref.current.focus()
    }

    const theTimeout = setTimeout(focus, timeout)

    return () => {
      clearTimeout(theTimeout)
    }
  }, []) // eslint-disable-line react-hooks/exhaustive-deps

  return cloneElement(children, {ref})
}

Focus.propTypes = {
  children: PropTypes.node.isRequired,
  timeout: PropTypes.number,
}

export default Focus
