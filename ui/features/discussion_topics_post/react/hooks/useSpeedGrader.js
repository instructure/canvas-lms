/*
 * Copyright (C) 2024 - present Instructure, Inc.
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

import {useEffect, useState} from 'react'
import {isSpeedGraderInTopUrl} from '../utils/constants'

export default function useSpeedGrader() {
  const [isInSpeedGrader, setIsInSpeedGrader] = useState(false)

  useEffect(() => {
    const checkSpeedGrader = () => {
      try {
        setIsInSpeedGrader(isSpeedGraderInTopUrl)
      } catch (error) {
        setIsInSpeedGrader(false)
      }
    }
    checkSpeedGrader()
  }, [])

  const handleJumpFocusToSpeedGrader = () => {
    window.top.postMessage(
      {
        subject: 'SG.focusPreviousStudentButton',
      },
      '*',
    )
  }

  function sendPostMessage(message) {
    window.postMessage(message, '*')
    window.top.postMessage(message, '*')
  }

  function handlePreviousStudentReply() {
    const message = {subject: 'DT.previousStudentReplyTab'}
    sendPostMessage(message)
  }

  const handleNextStudentReply = () => {
    const message = {subject: 'DT.nextStudentReplyTab'}
    sendPostMessage(message)
  }

  const handleSwitchClick = () => {
    const message = {subject: 'SG.switchToIndividualPosts'}
    sendPostMessage(message)
  }

  const handleCommentKeyPress = () => {
    const message = {subject: 'SG.commentKeyPress'}
    sendPostMessage(message)
  }

  const handleGradeKeyPress = () => {
    const message = {subject: 'SG.gradeKeyPress'}
    sendPostMessage(message)
  }

  return {
    isInSpeedGrader,
    handlePreviousStudentReply,
    handleNextStudentReply,
    handleJumpFocusToSpeedGrader,
    handleSwitchClick,
    handleCommentKeyPress,
    handleGradeKeyPress,
  }
}
