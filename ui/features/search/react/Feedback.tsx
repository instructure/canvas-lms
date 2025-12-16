/*
 * Copyright (C) 2025 - present Instructure, Inc.
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

import React, {useState} from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Text} from '@instructure/ui-text'
import {CondensedButton} from '@instructure/ui-buttons'
import {IconLikeLine, IconLikeSolid} from '@instructure/ui-icons'
import {Flex} from '@instructure/ui-flex'
import PositiveFeedbackModal from './PositiveFeedbackModal'
import NegativeFeedbackModal from './NegativeFeedbackModal'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'

const I18n = createI18nScope('SmartSearch')

interface Props {
  courseId: string
  searchTerm: string
}

export default function Feedback(props: Props) {
  const [feedback, setFeedback] = useState<'liked' | 'disliked' | null>(null)
  const [posModalOpen, setPosModalOpen] = useState(false)
  const [negModalOpen, setNegModalOpen] = useState(false)

  const sendFeedback = async (
    action: 'LIKE' | 'DISLIKE',
    courseId: string,
    searchTerm: string,
    comment: string = '',
  ) => {
    fetch(
      `/api/v1/courses/${courseId}/smartsearch/log?q=${encodeURIComponent(searchTerm)}&a=${action}&c=${encodeURIComponent(comment)}`,
    )
  }

  const onDislike = (comment: string) => {
    sendFeedback('DISLIKE', props.courseId, props.searchTerm, comment)
    setNegModalOpen(false)
  }

  return (
    <>
      <PositiveFeedbackModal isOpen={posModalOpen} onClose={() => setPosModalOpen(false)} />
      <NegativeFeedbackModal
        isOpen={negModalOpen}
        onClose={() => onDislike('')}
        onSubmit={onDislike}
      />
      <Flex direction="row">
        <Flex.Item>
          <Text size="descriptionSection">{I18n.t('Feedback')}&ensp;</Text>
        </Flex.Item>
        <Flex.Item>
          <CondensedButton
            data-testid="positive-feedback"
            data-pendo="smart-search-positive-feedback-button"
            onClick={_ => {
              setFeedback('liked')
              sendFeedback('LIKE', props.courseId, props.searchTerm)
              setPosModalOpen(true)
            }}
            renderIcon={
              feedback === 'liked' ? (
                <IconLikeSolid color="brand" />
              ) : (
                <IconLikeLine color="brand" />
              )
            }
            aria-pressed={feedback === 'liked'}
          >
            <ScreenReaderContent>{I18n.t('I like these results')}</ScreenReaderContent>
          </CondensedButton>
        </Flex.Item>
        <Flex.Item>
          <span style={{display: 'inline-block', transform: 'rotate(180deg)'}}>
            <CondensedButton
              data-testid="negative-feedback"
              data-pendo="smart-search-negative-feedback-button"
              onClick={_ => {
                setFeedback('disliked')
                setNegModalOpen(true)
              }}
              renderIcon={
                feedback === 'disliked' ? (
                  <IconLikeSolid color="brand" />
                ) : (
                  <IconLikeLine color="brand" />
                )
              }
              aria-pressed={feedback === 'disliked'}
            >
              <ScreenReaderContent>{I18n.t('I do not like these results')}</ScreenReaderContent>
            </CondensedButton>
          </span>
        </Flex.Item>
      </Flex>
    </>
  )
}
