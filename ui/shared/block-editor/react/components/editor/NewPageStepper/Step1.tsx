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

import React, {useCallback, useEffect, useRef} from 'react'

import {CondensedButton} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {Img} from '@instructure/ui-img'
import {Heading} from '@instructure/ui-heading'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'

type Step1Selection = 'scratch' | 'template'

type Step1Props = {
  start?: Step1Selection
  onSelect: (start: Step1Selection) => void
}

const Step1 = ({start = 'scratch', onSelect}: Step1Props) => {
  const scratchRef = useRef<HTMLButtonElement | null>(null)
  const templateRef = useRef<HTMLButtonElement | null>(null)

  useEffect(() => {
    if (start === 'scratch') {
      scratchRef.current?.focus()
    } else {
      templateRef.current?.focus()
    }
  }, [start])

  const handleSelectScratch = useCallback(() => {
    onSelect('scratch')
  }, [onSelect])

  const handleSelectTemplate = useCallback(() => {
    onSelect('template')
  }, [onSelect])

  return (
    <View as="div">
      <Flex direction="row" gap="large">
        <Flex direction="column" width="300px">
          <View
            as="div"
            borderWidth={start === 'scratch' ? 'medium' : 'none'}
            borderColor="brand"
            padding="xxx-small"
          >
            <CondensedButton
              onClick={handleSelectScratch}
              elementRef={(el: Element | null) => {
                if (el) scratchRef.current = el as HTMLButtonElement
              }}
            >
              <Img src="/images/block_editor/scratch.png" alt="" width="300px" height="300px" />
            </CondensedButton>
          </View>
          <View as="div" margin="x-small 0 0 0">
            <Heading level="h3">Start from Scratch</Heading>
            <Text as="p">
              Select from a variety of style options or start with a blank canvas to create a page
              tailored to your specific needs.
            </Text>
          </View>
        </Flex>
        <Flex direction="column" width="300px">
          <View
            as="div"
            borderWidth={start === 'template' ? 'medium' : 'none'}
            borderColor="brand"
            padding="xxx-small"
          >
            <CondensedButton
              onClick={handleSelectTemplate}
              elementRef={(el: Element | null) => {
                if (el) templateRef.current = el as HTMLButtonElement
              }}
            >
              <Img src="/images/block_editor/template.png" alt="" width="300px" height="300px" />
            </CondensedButton>
          </View>
          <View as="div" margin="x-small 0 0 0">
            <Heading level="h3">Select a Template</Heading>
            <Text as="p">
              Select from a variety of pre-designed page layouts that are ready to be filled with
              your content.
            </Text>
          </View>
        </Flex>
      </Flex>
    </View>
  )
}

export {Step1, type Step1Selection}
