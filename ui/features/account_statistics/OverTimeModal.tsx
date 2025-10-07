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

import {Modal} from '@instructure/ui-modal'
import {Heading} from '@instructure/ui-heading'
import {Button, CloseButton} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {QueryClientProvider, useQuery} from '@tanstack/react-query'
import doFetchApi from '@canvas/do-fetch-api-effect'
import {useEffect, useState} from 'react'
import {View} from '@instructure/ui-view'
import {Spinner} from '@instructure/ui-spinner'
import {queryClient} from '@canvas/query'
import {Alert} from '@instructure/ui-alerts'
import OverTimeGraph from './OverTimeGraph'
import {useScope as createI18nScope} from '@canvas/i18n'

const I18n = createI18nScope('accounts.statistics')

export default function OverTimeModal({accountId}: {accountId: string}) {
  const [isOpen, setIsOpen] = useState(false)
  const [url, setUrl] = useState('')
  const [name, setName] = useState('')

  const {data, isLoading, isError} = useQuery({
    queryKey: ['accountStatistics', url],
    queryFn: async ({queryKey}) => {
      if (queryKey === undefined || queryKey[1] === '') return null
      const {json} = await doFetchApi<Array<[number, number]>>({path: queryKey[1]})
      return json
    },
  })

  useEffect(() => {
    const links = document.querySelectorAll('.over_time_link')
    links.forEach(link => {
      link.addEventListener('click', event => {
        event.preventDefault()
        const element = event.target as HTMLElement
        const name = element.dataset.name || ''
        const url = `/accounts/${accountId}/statistics/over_time/${element.dataset.key}`
        setUrl(url)
        setName(name)
        setIsOpen(true)
      })
    })
  }, [accountId])

  const modalTitle = I18n.t('%{name} Over Time', {name})
  const closeLabel = I18n.t('Close')

  const renderBody = () => {
    if (isError) {
      return (
        <View margin="auto" textAlign="center" as="div" width="100%" height="100%">
          <Alert variant="error">{I18n.t('Failed to fetch graph data')}</Alert>
        </View>
      )
    } else if (data === undefined || data === null || isLoading) {
      return (
        <View margin="auto" textAlign="center" as="div" width="100%" height="100%">
          <Spinner size="medium" renderTitle={I18n.t('Fetching graph data')} />
        </View>
      )
    } else {
      return <OverTimeGraph data={data!} name={name} url={url} />
    }
  }
  return (
    <QueryClientProvider client={queryClient}>
      <Modal
        label={modalTitle}
        open={isOpen}
        onDismiss={() => setIsOpen(false)}
        shouldCloseOnDocumentClick={false}
      >
        <Modal.Header>
          <Heading>{modalTitle}</Heading>
          <CloseButton
            screenReaderLabel={closeLabel}
            onClick={() => setIsOpen(false)}
            placement="end"
          />
        </Modal.Header>
        <Modal.Body>{renderBody()}</Modal.Body>
        <Modal.Footer>
          <Flex gap="buttons" justifyItems="end">
            <Button color="secondary" onClick={() => setIsOpen(false)} data-testid="close-button">
              {closeLabel}
            </Button>
          </Flex>
        </Modal.Footer>
      </Modal>
    </QueryClientProvider>
  )
}
