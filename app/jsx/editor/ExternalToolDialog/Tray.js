/*
 * Copyright (C) 2019 - present Instructure, Inc.
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
import PropTypes from 'prop-types'
import Tray from '@instructure/ui-overlays/lib/components/Tray'
import Heading from '@instructure/ui-elements/lib/components/Heading'
import Button from '@instructure/ui-buttons/lib/components/Button'
import Flex from '@instructure/ui-layout/lib/components/Flex'
import FlexItem from '@instructure/ui-layout/lib/components/Flex/FlexItem'
import IconX from '@instructure/ui-icons/lib/Line/IconX'
import ScreenReaderContent from '@instructure/ui-a11y/lib/components/ScreenReaderContent'

export default function ExternalToolDialogTray(props) {
  const {open, label, onOpen, onClose, onCloseButton, closeLabel, name, children} = props
  return (
    <Tray
      open={open}
      label={label}
      onOpen={onOpen}
      onClose={onClose}
      placement="end"
      size="regular"
    >
      <Flex direction="column" height="100vh">
        <FlexItem padding="small">
          <Flex>
            <FlexItem margin="0 small 0 0">
              <Button variant="icon" icon={IconX} onClick={onCloseButton} size="small">
                <ScreenReaderContent>{closeLabel}</ScreenReaderContent>
              </Button>
            </FlexItem>
            <FlexItem grow shrink>
              <Heading ellipsis level="h3" as="h2">
                {name}
              </Heading>
            </FlexItem>
          </Flex>
        </FlexItem>
        {children}
      </Flex>
    </Tray>
  )
}

ExternalToolDialogTray.propTypes = {
  open: PropTypes.bool,
  label: PropTypes.string.isRequired,
  onOpen: PropTypes.func,
  onClose: PropTypes.func,
  onCloseButton: PropTypes.func,
  closeLabel: PropTypes.string.isRequired,
  name: PropTypes.string.isRequired,
  children: PropTypes.node
}
