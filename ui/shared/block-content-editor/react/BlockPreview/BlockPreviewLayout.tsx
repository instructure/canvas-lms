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
import {ReactNode} from 'react'
import {View} from '@instructure/ui-view'
import {Text} from '@instructure/ui-text'
import {Heading} from '@instructure/ui-heading'
import './block-preview-layout.css'

export const BlockPreviewLayout = (props: {
  image: ReactNode
  title: string
  description: string[]
  legend: string
}) => {
  return (
    <>
      <div className="preview-image-wrapper">
        <View display="block">{props.image}</View>
      </div>
      <View display="block" margin="small 0">
        <Heading variant="titleCardMini" level="h3">
          {props.title}
        </Heading>
      </View>
      <View display="block">
        {props.description.map((line: string, index: number) => (
          <Text as="p" variant="content" key={index}>
            {line}
          </Text>
        ))}
      </View>
      <View display="block" margin="small 0">
        <Text as="p" variant="legend">
          {props.legend}
        </Text>
      </View>
    </>
  )
}
