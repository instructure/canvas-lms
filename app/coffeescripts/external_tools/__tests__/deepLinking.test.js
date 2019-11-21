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

import {handleDeepLinkingError, handleContentItem} from '../deepLinking'
import $ from 'jquery'

describe('handleContentItem', () => {
  const result = {
    type: 'file',
    text: 'text',
    title: 'title',
    icon: 'https://www.test.com/image.png'
  }
  const contentView = {
    trigger: jest.fn()
  }
  const callback = jest.fn()

  beforeEach(() => {
    contentView.trigger.mockReset()
    callback.mockReset()
    handleContentItem(result, contentView, callback)
  })

  it('processes the content item', () => {
    expect(contentView.trigger).toHaveBeenCalledWith('ready', {
      contentItems: [
        {
          '@type': 'FileItem',
          text: result.text,
          title: result.title,
          thumbnail: {
            '@id': result.icon
          }
        }
      ]
    })
  })

  it('calls the callback', () => {
    expect(callback).toHaveBeenCalledTimes(1)
  })
})

describe('handleDeepLinkingError', () => {
  const error = 'Some error'
  const contentView = {
    model: {
      id: 1
    }
  }
  const reloadTool = jest.fn()

  beforeEach(() => {
    reloadTool.mockReset()
    jest.spyOn($, 'flashError').mockImplementation()
    jest.spyOn(console, 'error').mockImplementation()
    handleDeepLinkingError(error, contentView, reloadTool)
  })

  it('displays an error to the user', () => {
    expect(console.error).toHaveBeenCalled()
    expect($.flashError).toHaveBeenCalledWith('Error retrieving content')
  })

  it('reloads the tool', () => {
    expect(console.error).toHaveBeenCalled()
    expect(reloadTool).toHaveBeenCalledWith(contentView.model.id)
  })
})
