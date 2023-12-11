import {render} from '@testing-library/react'
import React from 'react'
import MicrosoftSyncDebugInfo from '../MicrosoftSyncDebugInfo'

jest.mock('@canvas/do-fetch-api-effect')

describe('MicrosoftSyncDebugInfo', () => {
  const props = overrides => ({
    debugInfo: [
      {timestamp: "2020-10-20T02:02:02Z", msg: "Debug item 1", user_ids: [1, 2]},
      {timestamp: "2020-10-21T03:03:03Z", msg: "Debug item 2"}
    ],
    ...overrides,
  })
  const subject = overrides => render(<MicrosoftSyncDebugInfo {...props(overrides)} />)

  it('renders expandable debugging info', () => {
    const {getByText} = subject()
    expect(getByText("Debugging Info (Advanced)...")).toBeInTheDocument()
  })

  it('renders the debugInfo array as a list of text items', async () =>  {
    // click the toggle button to expand the debugging info:
    const {getByText, findByText} = subject()
    getByText("Toggle Debugging Info").click()
    expect(getByText('Debug item 1')).toBeInTheDocument()
    expect(getByText('Debug item 2')).toBeInTheDocument()
    expect(getByText(/Oct 20/)).toBeInTheDocument()
    expect(getByText(/2:02/)).toBeInTheDocument()
    expect(getByText(/Oct 21/)).toBeInTheDocument()
    expect(getByText(/3:03/)).toBeInTheDocument()
  })
})
