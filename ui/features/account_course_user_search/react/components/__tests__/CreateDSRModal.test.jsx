import React from 'react'
import { render, fireEvent, waitFor } from '@testing-library/react'
import '@testing-library/jest-dom/extend-expect'
import {Tooltip} from '@instructure/ui-tooltip'
import {IconButton} from '@instructure/ui-buttons'
import {IconEditLine, IconMasqueradeLine, IconMessageLine, IconExportLine} from '@instructure/ui-icons'
import {useScope as useI18nScope} from '@canvas/i18n'
import CreateDSRModal from '../CreateDSRModal'
import axios from '@canvas/axios'

const I18n = useI18nScope('account_course_user_search')

jest.mock('@canvas/axios')

const mockUser = {
  id: '1',
  name: 'John Doe',
  email: 'john.doe@example.com',
}

const mockAccountId = '123'

describe('CreateDSRModal', () => {
  const afterSave = jest.fn()

  beforeAll(() => {
    window.ENV.ROOT_ACCOUNT_NAME = 'Root Account'
  })

  const renderComponent = (props = {}) =>
    render(
      <CreateDSRModal accountId={mockAccountId} user={mockUser} afterSave={afterSave} {...props}>
        <span>
              <Tooltip
                data-testid="user-list-row-tooltip"
                renderTip={I18n.t('Create DSR Request for %{name}', {name: mockUser.name})}
              >
                <IconButton
                  withBorder={false}
                  withBackground={false}
                  size="small"
                  screenReaderLabel={I18n.t('Create DSR Request for %{name}', {name: mockUser.name})}
                >
                  <IconExportLine title={I18n.t('Create DSR Request for %{name}', {name: mockUser.name})} />
                </IconButton>
              </Tooltip>
            </span>
      </CreateDSRModal>
    )

  it('should not show latest request if there is none', async () => {
    axios.get.mockResolvedValueOnce({ status: 204, data: {} })

    const { queryByText, getByTitle } = renderComponent()
    fireEvent.click(getByTitle('Create DSR Request for John Doe'))

    await waitFor(() => {
      expect(queryByText('Latest DSR:')).not.toBeInTheDocument()
    })
  })

  it('should fetch the latest DSR request on modal open', async () => {
    axios.get.mockResolvedValueOnce({
      status: 200,
      data: {
        request_name: 'Latest Request',
        progress_status: 'completed',
        download_url: 'http://download',
      },
    })

    const { getByText, getByTitle } = renderComponent()
    fireEvent.click(getByTitle('Create DSR Request for John Doe'))

    await waitFor(() => {
      expect(getByText('Latest DSR:')).toBeInTheDocument()
      expect(getByText('Latest Request')).toBeInTheDocument()
    })
  })

  it('should not have a download link and show the status when pending', async () => {
    axios.get.mockResolvedValueOnce({
      status: 200,
      data: {
        request_name: 'Latest Request',
        progress_status: 'running',
      },
    })

    const { getByText, queryByText, getByTitle } = renderComponent()
    fireEvent.click(getByTitle('Create DSR Request for John Doe'))

    await waitFor(() => {
      expect(getByText((_, element) => element.textContent === 'Latest DSR: In progress')).toBeInTheDocument()
      expect(queryByText('Download:')).not.toBeInTheDocument()
    })
  })
})