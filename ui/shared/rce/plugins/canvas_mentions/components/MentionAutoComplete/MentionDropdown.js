/*
 * Copyright (C) 2021 - present Instructure, Inc.
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
import React, {useEffect, useRef, useState, useLayoutEffect, useCallback} from 'react'
import MentionDropdownMenu from './MentionDropdownMenu'
import PropTypes from 'prop-types'
import {nanoid} from 'nanoid'
import getPosition from './getPosition'
import {MARKER_ID} from '../../constants'

const MentionMockUsers = [
  {
    id: 1,
    name: 'Jeffrey Johnson'
  },
  {
    id: 2,
    name: 'Matthew Lemon'
  },
  {
    id: 3,
    name: 'Rob Orton'
  },
  {
    id: 4,
    name: 'Davis Hyer'
  },
  {
    id: 5,
    name: 'Drake Harper'
  },
  {
    id: 6,
    name: 'Omar Soto-Fortuño'
  },
  {
    id: 7,
    name: 'Chawn Neal'
  },
  {
    id: 8,
    name: 'Mauricio Ribeiro'
  },
  {
    id: 9,
    name: 'Caleb Guanzon'
  },
  {
    id: 10,
    name: 'Jason Gillett'
  }
]

const MentionUIManager = () => {
  // Setup State
  const [menitonCordinates, setMenitonCordinates] = useState(null)

  // Setup Refs for listener access
  const uniqueInstanceId = useRef(nanoid())

  const getXYPosition = useCallback(() => {
    const responseObj = getPosition(tinyMCE.activeEditor, `#${MARKER_ID}`)
    setMenitonCordinates(responseObj)
  }, [])

  // Window resize handler
  useLayoutEffect(() => {
    window.addEventListener('resize', getXYPosition)
    window.addEventListener('scroll', getXYPosition)

    return () => {
      window.removeEventListener('resize', getXYPosition)
      window.removeEventListener('scroll', getXYPosition)
    }
  })

  // Set initial positioning
  useEffect(() => {
    getXYPosition()
  }, [getXYPosition])

  return (
    <MentionDropdownMenu
      popupId={uniqueInstanceId.current}
      mentionOptions={MentionMockUsers}
      show
      coordiantes={menitonCordinates}
    />
  )
}

export default MentionUIManager

MentionUIManager.propTypes = {
  mentionData: PropTypes.array,
  rceRef: PropTypes.object,
  onExited: PropTypes.func,
  onSelect: PropTypes.func
}

MentionUIManager.defaultProps = {
  mentionData: MentionMockUsers,
  onExited: () => {},
  onSelect: () => {}
}
