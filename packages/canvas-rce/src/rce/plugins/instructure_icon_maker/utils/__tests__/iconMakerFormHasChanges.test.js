/*
 * Copyright (C) 2022 - present Instructure, Inc.
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

import {
  hasNameChange,
  hasAltChange,
  hasShapeSizeChange,
  hasShapeNameChange,
  hasColorNameChange,
  hasOutlineSizeChange,
  hasOutlineColorChange,
  hasChanges,
  hasTextChange,
  hasTextSizeChange,
  hasTextColorChange,
  hasTextBackgroundColorChange,
  hasTextPositionChange,
  hasImageSettingsChange
} from '../iconMakerFormHasChanges'
import {Shape} from '../../svg/shape'
import {Size} from '../../svg/constants'

describe('detect if icon maker form has changes', () => {
  let initialSettings, currentSettings

  beforeEach(() => {
    initialSettings = initializeSettings()
    currentSettings = initializeSettings()
  })

  describe('hasNameChange', () => {
    it('returns false if names match exactly', () => {
      expect(hasNameChange(initialSettings, currentSettings)).toBe(false)
    })

    it('returns true if names do not match exactly', () => {
      currentSettings.name = 'new-file-name.svg'
      expect(hasNameChange(initialSettings, currentSettings)).toBe(true)
    })
  })

  describe('hasAltChange', () => {
    it('returns false if alt texts match exactly', () => {
      expect(hasAltChange(initialSettings, currentSettings)).toBe(false)
    })

    it('returns true if alt texts do not match exactly', () => {
      currentSettings.alt = 'new alt text'
      expect(hasAltChange(initialSettings, currentSettings)).toBe(true)
    })
  })

  describe('hasShapeNameChange', () => {
    it('returns false if shape names match exactly', () => {
      expect(hasShapeNameChange(initialSettings, currentSettings)).toBe(false)
    })

    it('returns true if shape names do not match exactly', () => {
      currentSettings.shape = Shape.Diamond
      expect(hasShapeNameChange(initialSettings, currentSettings)).toBe(true)
    })
  })

  describe('hasShapeSizeChange', () => {
    it('returns false if shape sizes match exactly', () => {
      expect(hasShapeSizeChange(initialSettings, currentSettings)).toBe(false)
    })

    it('returns true if shape sizes do not match exactly', () => {
      currentSettings.size = Size.ExtraLarge
      expect(hasShapeSizeChange(initialSettings, currentSettings)).toBe(true)
    })
  })

  describe('hasColorNameChange', () => {
    it('returns false if color names match exactly', () => {
      expect(hasColorNameChange(initialSettings, currentSettings)).toBe(false)
    })

    it('returns true if color names do not match exactly', () => {
      currentSettings.color = Color.Black
      expect(hasColorNameChange(initialSettings, currentSettings)).toBe(true)
    })

    it('returns false if both color names are null', () => {
      initialSettings.color = null
      currentSettings.color = null
      expect(hasColorNameChange(initialSettings, currentSettings)).toBe(false)
    })

    it('returns true if one color is null and the other is a valid color', () => {
      initialSettings.color = null
      expect(hasColorNameChange(initialSettings, currentSettings)).toBe(true)
    })
  })

  describe('hasOutlineSizeChange', () => {
    it('returns false if color outline sizes match exactly', () => {
      expect(hasOutlineSizeChange(initialSettings, currentSettings)).toBe(false)
    })

    it('returns true if color outline sizes do not match exactly', () => {
      currentSettings.outlineSize = 'medium'
      expect(hasOutlineSizeChange(initialSettings, currentSettings)).toBe(true)
    })
  })

  describe('hasOutlineColorChange', () => {
    it('returns false if outline colors match exactly', () => {
      expect(hasOutlineColorChange(initialSettings, currentSettings)).toBe(false)
    })

    it('returns true if outline colors do not match exactly', () => {
      currentSettings.outlineColor = Color.Green
      expect(hasOutlineColorChange(initialSettings, currentSettings)).toBe(true)
    })
  })

  describe('hasTextChange', () => {
    it('returns false if text entries match exactly', () => {
      expect(hasTextChange(initialSettings, currentSettings)).toBe(false)
    })

    it('returns true if text entries do not match exactly', () => {
      currentSettings.text = 'text-has-changed'
      expect(hasTextChange(initialSettings, currentSettings)).toBe(true)
    })
  })

  describe('hasTextSizeChange', () => {
    it('returns false if text sizes match exactly', () => {
      expect(hasTextSizeChange(initialSettings, currentSettings)).toBe(false)
    })

    it('returns true if text sizes do not match exactly', () => {
      currentSettings.textSize = Size.ExtraLarge
      expect(hasTextSizeChange(initialSettings, currentSettings)).toBe(true)
    })
  })

  describe('hasTextColorChange', () => {
    it('returns false if text colors match exactly', () => {
      expect(hasTextColorChange(initialSettings, currentSettings)).toBe(false)
    })

    it('returns true if text colors do not match exactly', () => {
      currentSettings.textColor = Color.Red
      expect(hasTextColorChange(initialSettings, currentSettings)).toBe(true)
    })
  })

  describe('hasTextBackgroundColorChange', () => {
    it('returns false if text background colors match exactly', () => {
      expect(hasTextBackgroundColorChange(initialSettings, currentSettings)).toBe(false)
    })

    it('returns true if text background colors do not match exactly', () => {
      currentSettings.textBackgroundColor = Color.Green
      expect(hasTextBackgroundColorChange(initialSettings, currentSettings)).toBe(true)
    })
  })

  describe('hasTextPositionChange', () => {
    it('returns false if text positions match exactly', () => {
      expect(hasTextPositionChange(initialSettings, currentSettings)).toBe(false)
    })

    it('returns true if text positions do not match exactly', () => {
      currentSettings.textPosition = 'below'
      expect(hasTextPositionChange(initialSettings, currentSettings)).toBe(true)
    })
  })

  describe('hasImageSettingsChange', () => {
    it('returns false if image settings match exactly', () => {
      expect(hasImageSettingsChange(initialSettings, currentSettings)).toBe(false)
    })

    it('returns true if image settings do not match exactly', () => {
      currentSettings.imageSettings.iconFillColor = Color.Black
      expect(hasImageSettingsChange(initialSettings, currentSettings)).toBe(true)
    })
  })

  describe('hasChanges', () => {
    it('returns false if all properties match exactly', () => {
      expect(hasChanges(initialSettings, currentSettings)).toBe(false)
    })

    it('returns true if imageSettings property is not an exact match', () => {
      currentSettings.imageSettings.iconFillColor = Color.Black
      expect(hasChanges(initialSettings, currentSettings)).toBe(true)
    })

    it('returns true if textPosition property is not an exact match', () => {
      currentSettings.textPosition = 'below'
      expect(hasChanges(initialSettings, currentSettings)).toBe(true)
    })

    it('returns true if textBackgroundColor property is not an exact match', () => {
      currentSettings.textBackgroundColor = Color.Yellow
      expect(hasChanges(initialSettings, currentSettings)).toBe(true)
    })

    it('returns true if textColor property is not an exact match', () => {
      currentSettings.textColor = Color.Red
      expect(hasChanges(initialSettings, currentSettings)).toBe(true)
    })

    it('returns true if textSize property is not an exact match', () => {
      currentSettings.textSize = Size.ExtraLarge
      expect(hasChanges(initialSettings, currentSettings)).toBe(true)
    })

    it('returns true if text property is not an exact match', () => {
      currentSettings.text = 'text-has-changed'
      expect(hasChanges(initialSettings, currentSettings)).toBe(true)
    })

    it('returns true if outlineColor property is not an exact match', () => {
      currentSettings.outlineColor = Color.Green
      expect(hasChanges(initialSettings, currentSettings)).toBe(true)
    })

    it('returns true if outlineSize property is not an exact match', () => {
      currentSettings.outlineSize = 'medium'
      expect(hasChanges(initialSettings, currentSettings)).toBe(true)
    })

    it('returns true if color property is not an exact match', () => {
      currentSettings.color = Color.Black
      expect(hasChanges(initialSettings, currentSettings)).toBe(true)
    })

    it('returns true if size property is not an exact match', () => {
      currentSettings.size = Size.ExtraLarge
      expect(hasChanges(initialSettings, currentSettings)).toBe(true)
    })

    it('returns true if shape property is not an exact match', () => {
      currentSettings.shape = Shape.Diamond
      expect(hasChanges(initialSettings, currentSettings)).toBe(true)
    })

    it('returns true if alt property is not an exact match', () => {
      currentSettings.alt = 'new alt text'
      expect(hasChanges(initialSettings, currentSettings)).toBe(true)
    })

    it('returns true if name property is not an exact match', () => {
      currentSettings.name = 'new name'
      expect(hasChanges(initialSettings, currentSettings)).toBe(true)
    })
  })
})

const Color = {
  Black: '#000000',
  White: '#FFFFFF',
  Yellow: '#FFFF00',
  Green: '#00FF00',
  Red: '#FF0000'
}

function initializeSettings() {
  return {
    name: 'file1',
    alt: 'alt text',
    size: Size.Medium,
    shape: Shape.Circle,
    color: Color.White,
    outlineSize: 'none',
    outlineColor: Color.Yellow,
    text: '',
    textSize: Size.Small,
    textColor: Color.Green,
    textBackgroundColor: Color.Red,
    textPosition: 'middle',
    imageSettings: {
      cropperSettings: null,
      icon: {
        label: 'Art Icon'
      },
      iconFillColor: Color.White,
      image: 'Art Icon',
      mode: 'SingleColor'
    }
  }
}
