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

import React from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import {IconButton} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import type {Bookmark} from './types'
import {IconArrowOpenEndLine, IconArrowOpenStartLine} from '@instructure/ui-icons'

const I18n = createI18nScope('temporary_enrollment')

interface Props {
  readonly prev?: Bookmark
  readonly next?: Bookmark
  readonly onPageClick: (page: Bookmark) => void
}

export function TempEnrollNavigation(props: Props) {
  const prevPage = props.prev ?? {page: 'first'}
  const nextPage = props.next ?? {page: 'first'}

  if (props.prev == null && props.next == null) {
    return null
  }
  return (
    <Flex as="div" justifyItems="center" gap="small">
      <IconButton
        size="small"
        withBackground={false}
        withBorder={false}
        onClick={() => props.onPageClick({...prevPage, rel: 'prev'})}
        screenReaderLabel={I18n.t('Previous Page')}
        renderIcon={IconArrowOpenStartLine}
        disabled={props.prev == null}
        data-testid="previous-bookmark"
      />
      <IconButton
        size="small"
        margin="small 0"
        withBackground={false}
        withBorder={false}
        onClick={() => props.onPageClick({...nextPage, rel: 'next'})}
        screenReaderLabel={I18n.t('Next Page')}
        renderIcon={IconArrowOpenEndLine}
        disabled={props.next == null}
        data-testid="next-bookmark"
      />
    </Flex>
  )
}
