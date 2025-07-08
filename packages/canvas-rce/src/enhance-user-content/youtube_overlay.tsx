import React, {useRef, useEffect, useState, useCallback} from 'react'
import {createRoot} from 'react-dom/client'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
import {Flex} from '@instructure/ui-flex'
import {CondensedButton} from '@instructure/ui-buttons'
import {IconPlayLine} from '@instructure/ui-icons'
import formatMessage from '../format-message'

type Props = {
  iframeElement: HTMLIFrameElement
  height: number
  width: number
}

const YoutubeEmbedOverlay: React.FC<Props> = ({iframeElement, height, width}) => {
  const [showOverlay, setShowOverlay] = useState(true)
  const containerRef = useRef<HTMLDivElement>(null)

  useEffect(() => {
    if (containerRef.current && iframeElement) {
      if (width) {
        containerRef.current.style.width = `${width}px`
      }
      if (height) {
        containerRef.current.style.height = `${height}px`
      }
      containerRef.current.appendChild(iframeElement)
    }
  }, [height, iframeElement, width])

  const handleCloseOverlay = useCallback(() => {
    setShowOverlay(false)
  }, [setShowOverlay])

  return (
    <View as="div" position="relative" display="inline-block">
      {showOverlay && (
        <View
          as="div"
          position="absolute"
          width="100%"
          height="100%"
          background="primary"
          themeOverride={{
            backgroundPrimary: 'rgba(10, 71, 91, 0.65)',
          }}
          overflowY="hidden"
        >
          <Flex justifyItems="center" height="100%">
            <Flex.Item shouldShrink shouldGrow textAlign="center">
              <Flex justifyItems="center" margin="0 0 small">
                <Flex.Item>
                  <Text color="secondary-inverse" weight="bold">
                    {formatMessage('This video may display YouTube ads.')}
                  </Text>
                </Flex.Item>
              </Flex>
              <Flex justifyItems="center" margin="0 0 medium">
                <Flex.Item>
                  <CondensedButton
                    data-test-id="youtube-migration-close-overlay"
                    color="primary-inverse"
                    onClick={handleCloseOverlay}
                  >
                    <IconPlayLine />
                    &nbsp;{formatMessage('Continue to YouTube content')}
                  </CondensedButton>
                </Flex.Item>
              </Flex>
            </Flex.Item>
          </Flex>
        </View>
      )}
      <div ref={containerRef} />
    </View>
  )
}

export const createOverlay = (iframes: NodeListOf<Element>) => {
  iframes.forEach(iframe => {
    const iframeElement = iframe as HTMLIFrameElement
    const height = iframeElement.offsetHeight
    const width = iframeElement.offsetWidth
    const container = document.createElement('div')
    container.setAttribute('data-test-id', 'youtube-migration-container')
    iframe.replaceWith(container)

    createRoot(container).render(
      <YoutubeEmbedOverlay iframeElement={iframeElement} height={height} width={width} />,
    )
  })
}
