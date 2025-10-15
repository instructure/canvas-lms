/* eslint-disable react/prop-types */
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

import {Button, CondensedButton} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {View} from '@instructure/ui-view'
import {useEffect, useRef, useState} from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import {PresentationContent, ScreenReaderContent} from '@instructure/ui-a11y-content'
import {Text} from '@instructure/ui-text'
import shave from '@canvas/shave'
import DeleteCommentIconButton from './DeleteCommentIconButton'

const I18n = createI18nScope('CommentLibrary')

type FocusedCommentProps = {
  onClick: () => void
  comment: string
  isExpanded: boolean
  setIsTruncated: (value: boolean) => void
  index: number
}
const FocusedComment: React.FC<FocusedCommentProps> = ({
  onClick,
  comment,
  isExpanded,
  setIsTruncated,
  index,
}) => {
  const [isFocused, setIsFocused] = useState(false)
  const commentRef = useRef<Element | null>(null)

  useEffect(() => {
    if (!isExpanded && commentRef.current) {
      const truncated = shave(commentRef.current, 70) ?? true
      setIsTruncated(truncated)
    }
  }, [isExpanded, setIsTruncated])

  return (
    <View
      as="div"
      padding="small"
      cursor="pointer"
      onClick={onClick}
      background={isFocused ? 'brand' : 'transparent'}
      onMouseEnter={() => setIsFocused(true)}
      onMouseLeave={() => setIsFocused(false)}
      onFocus={() => setIsFocused(true)}
      onBlur={() => setIsFocused(false)}
      tabIndex={0}
    >
      <PresentationContent>
        {/* key=isExpanded make sure it'll rebuild this component when key changes */}
        <Text
          key={`${isExpanded}`}
          wrap="break-word"
          elementRef={el => {
            commentRef.current = el
          }}
        >
          {comment}
        </Text>
      </PresentationContent>
      <ScreenReaderContent>
        <Button
          onClick={e => {
            e.stopPropagation()
            onClick()
          }}
          data-testid={`comment-library-item-use-button-${index}`}
        >
          {I18n.t('Use comment {{comment}}', {comment})}
        </Button>
      </ScreenReaderContent>
    </View>
  )
}

export type CommentReadViewProps = {
  id: string
  comment: string
  index: number
  onClick: () => void
}
const CommentReadView: React.FC<CommentReadViewProps> = ({comment, index, onClick, id}) => {
  const [isTruncated, setIsTruncated] = useState<boolean>(false)
  const [isExpanded, setIsExpanded] = useState(false)

  return (
    <View
      as="div"
      position="relative"
      borderWidth="none none small none"
      data-testid={`comment-library-item-${index}`}
    >
      <Flex as="div" alignItems="start">
        <Flex.Item as="div" shouldGrow={true} size="80%" shouldShrink={true}>
          <FocusedComment
            onClick={onClick}
            comment={comment}
            setIsTruncated={setIsTruncated}
            isExpanded={isExpanded}
            index={index}
          />
        </Flex.Item>
        <Flex.Item as="div" size="20%" shouldGrow={true}>
          <Flex as="div" direction="column">
            <Flex.Item as="div" padding="xx-small">
              <Flex as="div" justifyItems="center">
                <DeleteCommentIconButton comment={comment} id={id} index={index} />
              </Flex>
            </Flex.Item>
            {isTruncated && (
              <Flex.Item as="div" padding="xx-small">
                <Flex as="div" justifyItems="center">
                  <CondensedButton
                    size="small"
                    color="primary"
                    onClick={() => setIsExpanded(!isExpanded)}
                  >
                    {isExpanded ? I18n.t('show less') : I18n.t('show more')}
                  </CondensedButton>
                </Flex>
              </Flex.Item>
            )}
          </Flex>
        </Flex.Item>
      </Flex>
    </View>
  )
}

export default CommentReadView
