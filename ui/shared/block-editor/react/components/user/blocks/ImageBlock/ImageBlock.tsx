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

import React, {type CSSProperties, useCallback, useEffect, useRef, useState} from 'react'
import {useEditor, useNode} from '@craftjs/core'
import {ImageBlockToolbar} from './ImageBlockToolbar'
import {useClassNames} from '../../../../utils'
import {type ImageBlockProps, type ImageVariant, type ImageConstraint} from './types'
import {BlockResizer} from '../../../editor/BlockResizer'
import {Spinner} from '@instructure/ui-spinner'

import {useScope as createI18nScope} from '@canvas/i18n'

const I18n = createI18nScope('block-editor')

const ImageBlock = ({
  src,
  width,
  height,
  constraint,
  maintainAspectRatio,
  sizeVariant,
  alt,
}: ImageBlockProps) => {
  const {enabled} = useEditor(state => ({
    enabled: state.options.enabled,
  }))
  const {
    actions: {setCustom},
    connectors: {connect, drag},
  } = useNode()
  const clazz = useClassNames(enabled, {empty: !src}, ['block', 'image-block'])
  const [styl, setStyl] = useState<any>({})
  const [imageLoaded, setImageLoaded] = useState(false)
  // in preview mode, node.dom is null, so use a ref to the element
  const [blockRef, setBlockRef] = useState<HTMLDivElement | null>(null)
  const imgRef = useRef<HTMLImageElement | null>(null)

  const [isSVG, setIsSVG] = useState(false)
  const [svg, setSVG] = useState<string | null>(null)

  useEffect(() => {
    if (!src) return

    fetch(src, {mode: 'cors'})
      .then(response => {
        if (response.headers.get('content-type')?.includes('image/svg')) {
          setIsSVG(true)
          return response.text()
        } else {
          setIsSVG(false)
          return null
        }
      })
      .then(text => {
        setSVG(text)
      })
      .then(() => {
        setImageLoaded(true)
      })
      .catch(_err => {
        setIsSVG(false)
      })
  }, [src])

  const loadingStyle = {
    position: 'absolute',
    left: '10px',
    top: '10px',
    width: '100px',
    height: '100px',
  } as CSSProperties

  const setSize = useCallback(() => {
    if (!blockRef) return

    if (!src || sizeVariant === 'auto') {
      setStyl({
        width: 'auto',
        height: 'auto',
      })
      return
    }
    const sty: any = {}
    const unit = sizeVariant === 'percent' ? '%' : 'px'
    if (width) {
      sty.width = `${width}${unit}`
    }
    if (maintainAspectRatio) {
      sty.height = 'auto'
    } else {
      sty.height = `${height}px` // A set height is always px
    }
    setStyl(sty)
  }, [blockRef, height, maintainAspectRatio, sizeVariant, src, width])

  useEffect(() => {
    setSize()
  }, [width, height, setSize])

  useEffect(() => {
    setCustom((ctsm: any) => {
      ctsm.isResizable = !!src && sizeVariant !== 'auto'
    })
  }, [setCustom, sizeVariant, src])

  const imgConstrain =
    (maintainAspectRatio ? 'cover' : constraint) || ImageBlock.craft.defaultProps.constraint

  const renderImage = () => {
    return (
      <div
        role="treeitem"
        aria-label={ImageBlock.craft.displayName}
        tabIndex={-1}
        className={clazz}
        style={{...styl, position: 'relative'}}
        ref={el => {
          el && connect(drag(el as HTMLDivElement))
          setBlockRef(el)
        }}
      >
        {!imageLoaded ? (
          <div style={loadingStyle}>
            <Spinner renderTitle={I18n.t('Loading')} size="x-small" />
          </div>
        ) : null}

        <img
          ref={imgRef}
          src={src || ImageBlock.craft.defaultProps.src}
          alt={alt || ''}
          style={{width: '100%', height: '100%', objectFit: imgConstrain, display: 'inline-block'}}
          onLoad={() => setImageLoaded(true)}
        />
      </div>
    )
  }

  const renderInlineSVG = () => {
    return (
      <div
        role="treeitem"
        aria-label={ImageBlock.craft.displayName}
        tabIndex={-1}
        className={clazz}
        style={{...styl, position: 'relative'}}
        ref={el => {
          el && connect(drag(el as HTMLDivElement))
          setBlockRef(el)
        }}
      >
        {!imageLoaded ? (
          <div style={loadingStyle}>
            <Spinner renderTitle={I18n.t('Loading')} size="x-small" />
          </div>
        ) : null}

        <div
          // @ts-expect-error
          ref={imgRef}
          dangerouslySetInnerHTML={{__html: svg || ''}}
          style={{width: '100%', height: '100%', objectFit: imgConstrain, display: 'inline-block'}}
        />
      </div>
    )
  }

  if (!src) {
    return (
      <div
        role="treeitem"
        aria-label={ImageBlock.craft.displayName}
        tabIndex={-1}
        className={clazz}
        style={styl}
        ref={el => el && connect(drag(el as HTMLDivElement))}
      />
    )
  } else if (isSVG) {
    return renderInlineSVG()
  } else {
    return renderImage()
  }
}

ImageBlock.craft = {
  displayName: I18n.t('Image'),
  defaultProps: {
    src: '',
    variant: 'default' as ImageVariant,
    constraint: 'cover' as ImageConstraint,
    maintainAspectRatio: false,
    sizeVariant: 'auto',
    alt: '',
  },
  related: {
    toolbar: ImageBlockToolbar,
    resizer: BlockResizer,
  },
  custom: {
    isResizable: true,
    isBlock: true,
  },
}

export {ImageBlock}
