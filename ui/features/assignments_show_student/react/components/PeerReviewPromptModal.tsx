// @ts-nocheck
/*
 * Copyright (C) 2023 - present Instructure, Inc.
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

import {Button, CloseButton} from '@instructure/ui-buttons'
import {Modal} from '@instructure/ui-modal'
import {View} from '@instructure/ui-view'
import {Text} from '@instructure/ui-text'
import {useScope as useI18nScope} from '@canvas/i18n'
import React from 'react'
// @ts-ignore
import successSVG from '../../images/Success.svg'

import type {ViewProps} from '@instructure/ui-view'

type Spacing = ViewProps['margin']
type BorderWidth = ViewProps['borderWidth']
type BorderColor = ViewProps['borderColor']

const I18n = useI18nScope('assignments_2')

export type PeerReviewSubheader = {
  text: string
  props: SubHeaderProps
}

type SubHeaderProps = {
  size: 'large' | 'medium' | 'small'
  weight?: 'bold'
}

type HeaderMap = {
  id: number
  header: string
}

type SubHeaderMap = {
  id: number
  props?: SubHeaderProps
  text: string
}

export type PeerReviewPromptModalProps = {
  headerText: string[]
  headerMargin?: Spacing
  subHeaderText?: PeerReviewSubheader[]
  showSubHeaderBorder?: boolean
  peerReviewButtonText: string | null
  peerReviewButtonDisabled?: boolean
  onRedirect: () => void
  onClose: () => void
  open: boolean
}

export default ({
  headerText,
  headerMargin,
  subHeaderText,
  showSubHeaderBorder,
  peerReviewButtonText,
  peerReviewButtonDisabled,
  onRedirect,
  onClose,
  open,
}: PeerReviewPromptModalProps) => {
  const subHeaderBorder = showSubHeaderBorder
    ? {
        borderWidth: 'small none none' as BorderWidth,
        borderColor: 'primary' as BorderColor,
        padding: 'small 0 0' as Spacing,
      }
    : {borderWidth: undefined, borderColor: undefined, padding: undefined}
  const headerTextMap: HeaderMap[] = headerText.map((header, idx) => ({id: idx, header}))
  const subHeaderTextMap: SubHeaderMap[] | undefined = subHeaderText?.map((subHeader, idx) => {
    return {
      id: idx,
      props: subHeader.props,
      text: subHeader.text,
    }
  })

  return (
    <Modal
      label={I18n.t('Peer Review Prompt')}
      open={open}
      size="small"
      data-testid="peer-review-prompt-modal"
    >
      <Modal.Body>
        <CloseButton
          placement="end"
          offset="medium"
          color="primary"
          onClick={onClose}
          screenReaderLabel={I18n.t('Close')}
        />
        <View as="div">
          <View as="div" margin="small 0" textAlign="center">
            <Text lineHeight="fit" size="x-large">
              {I18n.t('SUCCESS!')}
            </Text>
          </View>
          <View as="div" margin="x-small 0" textAlign="center">
            <img alt="" src={successSVG} />
          </View>
          <View
            as="div"
            margin={headerMargin || 'small 0 0'}
            textAlign="center"
            data-testid="peer-review-header-text"
          >
            {headerTextMap.map(({id, header}) => (
              <View as="div" key={`header-${id}`}>
                <Text size="large">{header}</Text>
              </View>
            ))}
          </View>
          {subHeaderTextMap != null && subHeaderTextMap.length > 0 && (
            <>
              <View
                as="div"
                margin="small 0 0"
                data-testid="peer-review-sub-header-text"
                textAlign="center"
                {...subHeaderBorder}
              >
                {subHeaderTextMap?.map(({props, text, id}) => (
                  <View as="div" key={`subHeader-${id}`}>
                    <Text {...props}>{text}</Text>
                  </View>
                ))}
              </View>
            </>
          )}
        </View>
      </Modal.Body>
      {peerReviewButtonText && (
        <Modal.Footer style={{display: 'none'}}>
          <Button onClick={onClose} margin="0 x-small" data-testid="peer-review-close-button">
            {I18n.t('Close')}
          </Button>
          <Button
            interaction={peerReviewButtonDisabled ? 'disabled' : 'enabled'}
            onClick={onRedirect}
            color="primary"
            data-testid="peer-review-next-button"
          >
            {peerReviewButtonText}
          </Button>
        </Modal.Footer>
      )}
    </Modal>
  )
}
