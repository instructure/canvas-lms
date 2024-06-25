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

import React, {useRef, useEffect, useCallback} from 'react'
import {CondensedButton} from '@instructure/ui-buttons'
import {View, type ViewProps} from '@instructure/ui-view'
import {Img} from '@instructure/ui-img'
import {Text} from '@instructure/ui-text'
import {Grid} from '@instructure/ui-grid'
import {Flex} from '@instructure/ui-flex'

interface PageTemplatesProps {
  selectedTemplate: string
  onSelectTemplate: (templateId: string) => void
}

const PageTemplates = ({selectedTemplate = 'template-1', onSelectTemplate}: PageTemplatesProps) => {
  const firstTemplateRef = useRef<HTMLButtonElement | null>(null)
  const secondTemplateRef = useRef<HTMLButtonElement | null>(null)

  useEffect(() => {
    if (selectedTemplate === 'template-1') {
      firstTemplateRef.current?.focus()
    } else {
      secondTemplateRef.current?.focus()
    }
  }, [selectedTemplate])

  const handleSelectTemplate = useCallback(
    (e: React.KeyboardEvent<ViewProps> | React.MouseEvent<ViewProps, MouseEvent>) => {
      const target = e.target as HTMLElement
      onSelectTemplate(target.id)
    },
    [onSelectTemplate]
  )

  return (
    <Flex direction="column" gap="small">
      <Text size="large">Browse Templates</Text>
      <Text size="small">
        Select from a variety of pre-designed page layouts that are ready to be filled with your
        content.
      </Text>
      <Text size="large">Home Pages</Text>
      <Text size="small">
        A home page is the main or introductory page of a course. The home page is typically the
        first page you see. It serves as a central hub, guiding visitors to other parts of the
        course.
      </Text>
      <View
        as="div"
        position="relative"
        width="100%"
        maxWidth="100%"
        padding="small"
        borderRadius="large large none none"
        background="secondary"
      >
        <Flex gap="small">
          <View
            as="div"
            borderWidth={selectedTemplate === 'template-1' ? 'medium' : 'none'}
            borderColor="brand"
            padding="xxx-small"
            borderRadius="large large large large"
          >
            <CondensedButton
              id="template-1"
              onClick={handleSelectTemplate}
              elementRef={(el: Element | null) => {
                if (el) firstTemplateRef.current = el as HTMLButtonElement
              }}
            >
              <Img src="/images/block_editor/template-1.png" alt="" width="230px" height="350px" />
            </CondensedButton>
          </View>
          <View
            as="div"
            borderWidth={selectedTemplate === 'template-2' ? 'medium' : 'none'}
            borderColor="brand"
            padding="xxx-small"
            borderRadius="large large large large"
          >
            <CondensedButton
              id="template-2"
              onClick={handleSelectTemplate}
              elementRef={(el: Element | null) => {
                if (el) secondTemplateRef.current = el as HTMLButtonElement
              }}
            >
              <Img src="/images/block_editor/template-2.png" alt="" width="230px" height="350px" />
            </CondensedButton>
          </View>
        </Flex>
      </View>
    </Flex>
  )
}

export {PageTemplates}
