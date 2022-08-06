/*
 * Copyright (C) 2020 - present Instructure, Inc.
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
import {render, fireEvent} from '@testing-library/react'
import Confetti from '../Confetti'
import React from 'react'
import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'
import ConfettiGenerator from '@canvas/confetti/javascript/ConfettiGenerator'

const mockRender = jest.fn()
const mockClear = jest.fn()
jest.mock('@canvas/alerts/react/FlashAlert')
jest.mock('../../javascript/ConfettiGenerator', () => {
  return jest.fn().mockImplementation(() => {
    return {render: mockRender, clear: mockClear}
  })
})
jest.useFakeTimers()

describe('Confetti', () => {
  beforeEach(() => {
    mockRender.mockClear()
    mockClear.mockClear()
    ConfettiGenerator.mockClear()
  })

  it('renders confetti', () => {
    render(<Confetti />)
    expect(mockRender).toHaveBeenCalled()
  })

  it('clears confetti after 3 seconds', () => {
    render(<Confetti />)
    expect(mockClear).not.toHaveBeenCalled()
    jest.advanceTimersByTime(3000)
    expect(mockClear).toHaveBeenCalled()
  })

  it('provides square particles and a random emoji', () => {
    render(<Confetti />)
    expect(ConfettiGenerator).toHaveBeenCalledWith(
      expect.objectContaining({
        props: [
          'square',
          expect.objectContaining({
            size: 40
          })
        ]
      })
    )
  })

  describe('when an branding config is present', () => {
    let env
    beforeEach(() => {
      env = window.ENV
      window.ENV = {
        confetti_branding_enabled: true
      }
    })

    afterEach(() => {
      window.ENV = env
    })
    describe('colors', () => {
      it('provides only the primary color when secondary is not specified', () => {
        window.ENV = {
          ...window.ENV,
          active_brand_config: {
            variables: {
              'ic-brand-primary': '#000000'
            }
          }
        }
        render(<Confetti />)
        expect(ConfettiGenerator).toHaveBeenCalledWith(
          expect.objectContaining({
            colors: [[0, 0, 0]]
          })
        )
      })

      it('provides only the secondary color when primary is not specified', () => {
        window.ENV = {
          ...window.ENV,
          active_brand_config: {
            variables: {
              'ic-brand-global-nav-bgd': '#ffffff'
            }
          }
        }
        render(<Confetti />)
        expect(ConfettiGenerator).toHaveBeenCalledWith(
          expect.objectContaining({
            colors: [[255, 255, 255]]
          })
        )
      })

      it('provides both colors when both are specified', () => {
        window.ENV = {
          ...window.ENV,
          active_brand_config: {
            variables: {
              'ic-brand-primary': '#000000',
              'ic-brand-global-nav-bgd': '#ffffff'
            }
          }
        }
        render(<Confetti />)
        expect(ConfettiGenerator).toHaveBeenCalledWith(
          expect.objectContaining({
            colors: [
              [0, 0, 0],
              [255, 255, 255]
            ]
          })
        )
      })

      it('does not provide any colors if none are specified', () => {
        window.ENV = {
          ...window.ENV,
          active_brand_config: {
            variables: {}
          }
        }
        render(<Confetti />)
        expect(ConfettiGenerator.mock.calls[0][0]).not.toHaveProperty('colors')
      })

      describe('confetti_branding flag is disabled', () => {
        it('does not provide any custom colors', () => {
          window.ENV = {
            confetti_branding_enabled: false,
            active_brand_config: {
              variables: {
                'ic-brand-primary': '#000000',
                'ic-brand-global-nav-bgd': '#ffffff'
              }
            }
          }

          render(<Confetti />)
          expect(ConfettiGenerator.mock.calls[0][0]).not.toHaveProperty('colors')
        })
      })
    })

    describe('logo', () => {
      it('provides the logo if one exists', () => {
        window.ENV = {
          ...window.ENV,
          active_brand_config: {
            variables: {
              'ic-brand-header-image': '/public/images/canvas-logo.svg'
            }
          }
        }
        render(<Confetti />)
        expect(ConfettiGenerator).toHaveBeenCalledWith(
          expect.objectContaining({
            props: expect.arrayContaining([expect.objectContaining({key: 'logo'})])
          })
        )
      })

      it('does not provide a logo if one does not exist', () => {
        window.ENV = {
          ...window.ENV,
          active_brand_config: {
            variables: {}
          }
        }
        render(<Confetti />)
        expect(ConfettiGenerator).toHaveBeenCalledWith(
          expect.objectContaining({
            props: expect.not.arrayContaining([expect.objectContaining({key: 'logo'})])
          })
        )
      })

      describe('confetti_branding flag is disabled', () => {
        it('does not a logo', () => {
          window.ENV = {
            confetti_branding_enabled: false,
            active_brand_config: {
              variables: {
                'ic-brand-header-image': '/public/images/canvas-logo.svg'
              }
            }
          }

          render(<Confetti />)
          expect(ConfettiGenerator).toHaveBeenCalledWith(
            expect.objectContaining({
              props: expect.not.arrayContaining([expect.objectContaining({key: 'logo'})])
            })
          )
        })
      })
    })
  })

  describe('screenreader content', () => {
    it('announces the text', () => {
      render(<Confetti />)
      jest.advanceTimersByTime(2500)
      expect(showFlashAlert).toHaveBeenCalledWith({
        message: 'Great work! From the Canvas developers',
        srOnly: true
      })
    })
  })

  describe('keyboard clearing', () => {
    it('clears confetti when pressing `SPACE`', () => {
      render(<Confetti />)
      expect(mockClear).not.toHaveBeenCalled()
      fireEvent.keyDown(document.body, {key: 'Space', keyCode: 32})
      expect(mockClear).toHaveBeenCalled()
    })

    it('clears confetti when pressing `ESC`', () => {
      render(<Confetti />)
      expect(mockClear).not.toHaveBeenCalled()
      fireEvent.keyDown(document.body, {key: 'Escape', keyCode: 27})
      expect(mockClear).toHaveBeenCalled()
    })
  })

  describe('user has disabled celebrations', () => {
    let env
    beforeEach(() => {
      env = window.ENV
      window.ENV = {
        disable_celebrations: true
      }
    })

    afterEach(() => {
      window.ENV = env
    })

    it('does not render confetti', () => {
      render(<Confetti />)
      expect(mockRender).not.toHaveBeenCalled()
    })
  })
})
