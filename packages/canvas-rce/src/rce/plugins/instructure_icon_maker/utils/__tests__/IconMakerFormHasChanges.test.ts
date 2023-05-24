// @ts-nocheck
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

import {IconMakerFormHasChanges} from '../IconMakerFormHasChanges'
import {Shape} from '../../svg/shape'
import {Size} from '../../svg/constants'

describe('detect if icon maker form has changes', () => {
  let initialSettings, currentSettings
  let imFormHasChanges: IconMakerFormHasChanges

  beforeEach(() => {
    initialSettings = initializeSettings()
    currentSettings = initializeSettings()
  })

  describe('hasNameChange', () => {
    it('returns false if names match exactly', () => {
      imFormHasChanges = new IconMakerFormHasChanges(initialSettings, currentSettings)
      const result = imFormHasChanges.hasNameChange()
      expect(result).toBe(false)
    })

    it('returns true if names do not match exactly', () => {
      currentSettings.name = 'new-file-name.svg'
      imFormHasChanges = new IconMakerFormHasChanges(initialSettings, currentSettings)
      const result = imFormHasChanges.hasNameChange()
      expect(result).toBe(true)
    })
  })

  describe('hasAltChange', () => {
    it('returns false if alt texts match exactly', () => {
      imFormHasChanges = new IconMakerFormHasChanges(initialSettings, currentSettings)
      const result = imFormHasChanges.hasAltChange()
      expect(result).toBe(false)
    })

    it('returns true if alt texts do not match exactly', () => {
      currentSettings.alt = 'new alt text'
      imFormHasChanges = new IconMakerFormHasChanges(initialSettings, currentSettings)
      const result = imFormHasChanges.hasAltChange()
      expect(result).toBe(true)
    })
  })

  describe('hasShapeNameChange', () => {
    it('returns false if shape names match exactly', () => {
      imFormHasChanges = new IconMakerFormHasChanges(initialSettings, currentSettings)
      const result = imFormHasChanges.hasShapeNameChange()
      expect(result).toBe(false)
    })

    it('returns true if shape names do not match exactly', () => {
      currentSettings.shape = Shape.Diamond
      imFormHasChanges = new IconMakerFormHasChanges(initialSettings, currentSettings)
      const result = imFormHasChanges.hasShapeNameChange()
      expect(result).toBe(true)
    })
  })

  describe('hasShapeSizeChange', () => {
    it('returns false if shape sizes match exactly', () => {
      imFormHasChanges = new IconMakerFormHasChanges(initialSettings, currentSettings)
      const result = imFormHasChanges.hasShapeSizeChange()
      expect(result).toBe(false)
    })

    it('returns true if shape sizes do not match exactly', () => {
      currentSettings.size = Size.ExtraLarge
      imFormHasChanges = new IconMakerFormHasChanges(initialSettings, currentSettings)
      const result = imFormHasChanges.hasShapeSizeChange()
      expect(result).toBe(true)
    })
  })

  describe('hasColorNameChange', () => {
    it('returns false if color names match exactly', () => {
      imFormHasChanges = new IconMakerFormHasChanges(initialSettings, currentSettings)
      const result = imFormHasChanges.hasColorNameChange()
      expect(result).toBe(false)
    })

    it('returns true if color names do not match exactly', () => {
      currentSettings.color = Color.Black
      imFormHasChanges = new IconMakerFormHasChanges(initialSettings, currentSettings)
      const result = imFormHasChanges.hasColorNameChange()
      expect(result).toBe(true)
    })

    it('returns false if both color names are null', () => {
      initialSettings.color = null
      currentSettings.color = null
      imFormHasChanges = new IconMakerFormHasChanges(initialSettings, currentSettings)
      const result = imFormHasChanges.hasColorNameChange()
      expect(result).toBe(false)
    })

    it('returns true if one color is null and the other is a valid color', () => {
      initialSettings.color = null
      imFormHasChanges = new IconMakerFormHasChanges(initialSettings, currentSettings)
      const result = imFormHasChanges.hasColorNameChange()
      expect(result).toBe(true)
    })
  })

  describe('hasOutlineSizeChange', () => {
    it('returns false if color outline sizes match exactly', () => {
      imFormHasChanges = new IconMakerFormHasChanges(initialSettings, currentSettings)
      const result = imFormHasChanges.hasOutlineSizeChange()
      expect(result).toBe(false)
    })

    it('returns true if color outline sizes do not match exactly', () => {
      currentSettings.outlineSize = 'medium'
      imFormHasChanges = new IconMakerFormHasChanges(initialSettings, currentSettings)
      const result = imFormHasChanges.hasOutlineSizeChange()
      expect(result).toBe(true)
    })
  })

  describe('hasOutlineColorChange', () => {
    it('returns false if outline colors match exactly', () => {
      imFormHasChanges = new IconMakerFormHasChanges(initialSettings, currentSettings)
      const result = imFormHasChanges.hasOutlineColorChange()
      expect(result).toBe(false)
    })

    it('returns true if outline colors do not match exactly', () => {
      currentSettings.outlineColor = Color.Green
      imFormHasChanges = new IconMakerFormHasChanges(initialSettings, currentSettings)
      const result = imFormHasChanges.hasOutlineColorChange()
      expect(result).toBe(true)
    })
  })

  describe('hasTextChange', () => {
    it('returns false if text entries match exactly', () => {
      imFormHasChanges = new IconMakerFormHasChanges(initialSettings, currentSettings)
      const result = imFormHasChanges.hasTextChange()
      expect(result).toBe(false)
    })

    it('returns true if text entries do not match exactly', () => {
      currentSettings.text = 'text-has-changed'
      imFormHasChanges = new IconMakerFormHasChanges(initialSettings, currentSettings)
      const result = imFormHasChanges.hasTextChange()
      expect(result).toBe(true)
    })
  })

  describe('hasTextSizeChange', () => {
    it('returns false if text sizes match exactly', () => {
      imFormHasChanges = new IconMakerFormHasChanges(initialSettings, currentSettings)
      const result = imFormHasChanges.hasTextSizeChange()
      expect(result).toBe(false)
    })

    it('returns true if text sizes do not match exactly', () => {
      currentSettings.textSize = Size.ExtraLarge
      imFormHasChanges = new IconMakerFormHasChanges(initialSettings, currentSettings)
      const result = imFormHasChanges.hasTextSizeChange()
      expect(result).toBe(true)
    })
  })

  describe('hasTextColorChange', () => {
    it('returns false if text colors match exactly', () => {
      imFormHasChanges = new IconMakerFormHasChanges(initialSettings, currentSettings)
      const result = imFormHasChanges.hasTextColorChange()
      expect(result).toBe(false)
    })

    it('returns true if text colors do not match exactly', () => {
      currentSettings.textColor = Color.Red
      imFormHasChanges = new IconMakerFormHasChanges(initialSettings, currentSettings)
      const result = imFormHasChanges.hasTextColorChange()
      expect(result).toBe(true)
    })
  })

  describe('hasTextBackgroundColorChange', () => {
    it('returns false if text background colors match exactly', () => {
      imFormHasChanges = new IconMakerFormHasChanges(initialSettings, currentSettings)
      const result = imFormHasChanges.hasTextBackgroundColorChange()
      expect(result).toBe(false)
    })

    it('returns true if text background colors do not match exactly', () => {
      currentSettings.textBackgroundColor = Color.Green
      imFormHasChanges = new IconMakerFormHasChanges(initialSettings, currentSettings)
      const result = imFormHasChanges.hasTextBackgroundColorChange()
      expect(result).toBe(true)
    })
  })

  describe('hasTextPositionChange', () => {
    it('returns false if text positions match exactly', () => {
      imFormHasChanges = new IconMakerFormHasChanges(initialSettings, currentSettings)
      const result = imFormHasChanges.hasTextPositionChange()
      expect(result).toBe(false)
    })

    it('returns true if text positions do not match exactly', () => {
      currentSettings.textPosition = 'below'
      imFormHasChanges = new IconMakerFormHasChanges(initialSettings, currentSettings)
      const result = imFormHasChanges.hasTextPositionChange()
      expect(result).toBe(true)
    })
  })

  describe('hasImageSettingsChange', () => {
    it('returns false if image settings match exactly', () => {
      imFormHasChanges = new IconMakerFormHasChanges(initialSettings, currentSettings)
      const result = imFormHasChanges.hasImageSettingsChange()
      expect(result).toBe(false)
    })

    it('returns true if image settings do not match exactly', () => {
      currentSettings.imageSettings.iconFillColor = Color.Black
      imFormHasChanges = new IconMakerFormHasChanges(initialSettings, currentSettings)
      const result = imFormHasChanges.hasImageSettingsChange()
      expect(result).toBe(true)
    })
  })

  describe('hasChanges', () => {
    it('returns false if all properties match exactly', () => {
      imFormHasChanges = new IconMakerFormHasChanges(initialSettings, currentSettings)
      const result = imFormHasChanges.hasChanges()
      expect(result).toBe(false)
    })

    it('returns true if imageSettings property is not an exact match', () => {
      currentSettings.imageSettings.iconFillColor = Color.Black
      imFormHasChanges = new IconMakerFormHasChanges(initialSettings, currentSettings)
      const result = imFormHasChanges.hasChanges()
      expect(result).toBe(true)
    })

    it('returns true if textPosition property is not an exact match', () => {
      currentSettings.textPosition = 'below'
      imFormHasChanges = new IconMakerFormHasChanges(initialSettings, currentSettings)
      const result = imFormHasChanges.hasChanges()
      expect(result).toBe(true)
    })

    it('returns true if textBackgroundColor property is not an exact match', () => {
      currentSettings.textBackgroundColor = Color.Yellow
      imFormHasChanges = new IconMakerFormHasChanges(initialSettings, currentSettings)
      const result = imFormHasChanges.hasChanges()
      expect(result).toBe(true)
    })

    it('returns true if textColor property is not an exact match', () => {
      currentSettings.textColor = Color.Red
      imFormHasChanges = new IconMakerFormHasChanges(initialSettings, currentSettings)
      const result = imFormHasChanges.hasChanges()
      expect(result).toBe(true)
    })

    it('returns true if textSize property is not an exact match', () => {
      currentSettings.textSize = Size.ExtraLarge
      imFormHasChanges = new IconMakerFormHasChanges(initialSettings, currentSettings)
      const result = imFormHasChanges.hasChanges()
      expect(result).toBe(true)
    })

    it('returns true if text property is not an exact match', () => {
      currentSettings.text = 'text-has-changed'
      imFormHasChanges = new IconMakerFormHasChanges(initialSettings, currentSettings)
      const result = imFormHasChanges.hasChanges()
      expect(result).toBe(true)
    })

    it('returns true if outlineColor property is not an exact match', () => {
      currentSettings.outlineColor = Color.Green
      imFormHasChanges = new IconMakerFormHasChanges(initialSettings, currentSettings)
      const result = imFormHasChanges.hasChanges()
      expect(result).toBe(true)
    })

    it('returns true if outlineSize property is not an exact match', () => {
      currentSettings.outlineSize = 'medium'
      imFormHasChanges = new IconMakerFormHasChanges(initialSettings, currentSettings)
      const result = imFormHasChanges.hasChanges()
      expect(result).toBe(true)
    })

    it('returns true if color property is not an exact match', () => {
      currentSettings.color = Color.Black
      imFormHasChanges = new IconMakerFormHasChanges(initialSettings, currentSettings)
      const result = imFormHasChanges.hasChanges()
      expect(result).toBe(true)
    })

    it('returns true if size property is not an exact match', () => {
      currentSettings.size = Size.ExtraLarge
      imFormHasChanges = new IconMakerFormHasChanges(initialSettings, currentSettings)
      const result = imFormHasChanges.hasChanges()
      expect(result).toBe(true)
    })

    it('returns true if shape property is not an exact match', () => {
      currentSettings.shape = Shape.Diamond
      imFormHasChanges = new IconMakerFormHasChanges(initialSettings, currentSettings)
      const result = imFormHasChanges.hasChanges()
      expect(result).toBe(true)
    })

    it('returns true if alt property is not an exact match', () => {
      currentSettings.alt = 'new alt text'
      imFormHasChanges = new IconMakerFormHasChanges(initialSettings, currentSettings)
      const result = imFormHasChanges.hasChanges()
      expect(result).toBe(true)
    })

    it('returns true if name property is not an exact match', () => {
      currentSettings.name = 'new name'
      imFormHasChanges = new IconMakerFormHasChanges(initialSettings, currentSettings)
      const result = imFormHasChanges.hasChanges()
      expect(result).toBe(true)
    })
  })
})

const Color = {
  Black: '#000000',
  White: '#FFFFFF',
  Yellow: '#FFFF00',
  Green: '#00FF00',
  Red: '#FF0000',
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
        label: 'Art Icon',
      },
      iconFillColor: Color.White,
      image: 'Art Icon',
      mode: 'SingleColor',
    },
  }
}
