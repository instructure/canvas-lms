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
import {View} from '@instructure/ui-view'
import {Link} from '@instructure/ui-link'
import {Text} from '@instructure/ui-text'
import {Modal} from '@instructure/ui-modal'
import {Heading} from '@instructure/ui-heading'
import {Button, CloseButton} from '@instructure/ui-buttons'
import {AccessibleContent} from '@instructure/ui-a11y-content'
import {useScope as createI18nScope} from '@canvas/i18n'
import {SVGIcon} from '@instructure/ui-svg-images'

const I18n = createI18nScope('discussion_posts')

const svg = `<svg width="18" height="18" viewBox="0 0 18 18" fill="none" xmlns="http://www.w3.org/2000/svg">
<path fill-rule="evenodd" clip-rule="evenodd" d="M9 0V1.05882C4.62071 1.05882 1.05882 4.62071 1.05882 9C1.05882 13.3793 4.62071 16.9412 9 16.9412C13.3793 16.9412 16.9412 13.3793 16.9412 9C16.9412 6.49588 15.7542 4.16329 13.7647 2.66506V6.35294H12.7059V1.05882H18V2.11765H14.7854C16.8088 3.81918 18 6.32541 18 9C18 13.9627 13.9627 18 9 18C4.03729 18 0 13.9627 0 9C0 4.03729 4.03729 0 9 0Z" fill="#2B7ABC"/>
<path d="M8.48653 8.98521L4.66046 11.8554L5.29651 12.705L9.54668 9.51558V4.19995H8.48653V8.98521Z" fill="#2B7ABC"/>
</svg>
`

interface RestoreProps {
  onClick: () => Promise<any>
  loading: boolean
}

export const Restore: React.FC<RestoreProps> = ({onClick, loading}) => {
  const [isOpen, setIsOpen] = useState(false)

  const handleClose = () => {
    setIsOpen(false)
  }

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()

    await onClick()
    setIsOpen(false)
  }

  return (
    <>
      <View className="discussion-restore-btn">
        <Link
          isWithinText={false}
          as="button"
          onClick={() => setIsOpen(true)}
          data-testid="threading-toolbar-restore"
          renderIcon={<SVGIcon src={svg} />}
        >
          <AccessibleContent alt={I18n.t('Restore to original post')}>
            <Text weight="bold">{I18n.t('Restore')}</Text>
          </AccessibleContent>
        </Link>
      </View>
      <Modal
        as="form"
        open={isOpen}
        label={I18n.t('Restore deleted entry')}
        size="small"
        data-testid="restore-entry-modal"
        onSubmit={handleSubmit}
        onDismiss={handleClose}
      >
        <Modal.Header>
          <CloseButton
            placement="end"
            offset="small"
            onClick={handleClose}
            screenReaderLabel={I18n.t('Close')}
          />
          <Heading>{I18n.t('Restore deleted entry')}</Heading>
        </Modal.Header>
        <Modal.Body>{I18n.t('The selected reply will be restored')}</Modal.Body>
        <Modal.Footer>
          <Button margin="0 x-small 0 0" onClick={handleClose} data-testid="cancel-restore">
            {I18n.t('Cancel')}
          </Button>
          <Button
            color="primary"
            type="submit"
            disabled={loading}
            data-testid="restore-entry-submit"
          >
            {I18n.t('Restore')}
          </Button>
        </Modal.Footer>
      </Modal>
    </>
  )
}
