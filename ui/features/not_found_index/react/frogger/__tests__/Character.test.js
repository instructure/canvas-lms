/*
 * Copyright (C) 2018 - present Instructure, Inc.
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

import {Character, Obstacle, GoalObject} from '../characters'

const defaultCharacterParams = () => ({
  width: 100,
  height: 120,
  x: 10,
  y: 20,
  speed: 100,
})

test('Character constructur creates with correct paremeters', () => {
  const defaultParams = defaultCharacterParams()
  const CharacterObj = new Character(defaultParams)

  expect(CharacterObj.x).toBe(defaultParams.x)
  expect(CharacterObj.y).toBe(defaultParams.y)
  expect(CharacterObj.speed).toBe(defaultParams.speed)
  expect(CharacterObj.width).toBe(defaultParams.width)
  expect(CharacterObj.height).toBe(defaultParams.height)
})

test('Moves Character correctly based on dx and dy', () => {
  const defaultParams = defaultCharacterParams()
  const CharacterObj = new Character(defaultParams)
  CharacterObj.move(-10, -20)
  expect(CharacterObj.x).toBe(defaultParams.x - 10)
  expect(CharacterObj.y).toBe(defaultParams.y - 20)
})

test('Character collide function correct checks when outside object has colllded', () => {
  const CharacterObj = new Character(defaultCharacterParams())
  expect(CharacterObj.checkCollide(12, 22, 50, 50)).toBe(true)
})

test('Character collide function correct checks when outside object has not colllded', () => {
  const CharacterObj = new Character(defaultCharacterParams())
  expect(CharacterObj.checkCollide(110, 22, 50, 50)).toBe(false)
})

test('ObstacleObj constructur creates with correct paremeters', () => {
  const defaultParams = defaultCharacterParams()
  defaultParams.goingLeft = true
  const ObstacleObj = new Obstacle(defaultParams)

  expect(ObstacleObj.x).toBe(defaultParams.x)
  expect(ObstacleObj.y).toBe(defaultParams.y)
  expect(ObstacleObj.speed).toBe(defaultParams.speed)
  expect(ObstacleObj.width).toBe(defaultParams.width)
  expect(ObstacleObj.height).toBe(defaultParams.height)
  expect(ObstacleObj.goingLeft).toBe(true)
})

test('Obstacle inherits collide function correctly', () => {
  const ObstacleObj = new Obstacle(defaultCharacterParams())
  expect(ObstacleObj.checkCollide(110, 22, 50, 50)).toBe(false)
})

test('GoalObject constructur creates with correct paremeters', () => {
  const defaultParams = defaultCharacterParams()
  const GoalObj = new GoalObject(defaultParams)

  expect(GoalObj.x).toBe(defaultParams.x)
  expect(GoalObj.y).toBe(defaultParams.y)
  expect(GoalObj.speed).toBe(defaultParams.speed)
  expect(GoalObj.width).toBe(defaultParams.width)
  expect(GoalObj.height).toBe(defaultParams.height)
})

test('GoalObject inherits collide function correctly', () => {
  const GoalObj = new GoalObject(defaultCharacterParams())
  expect(GoalObj.checkCollide(12, 22, 50, 50)).toBe(true)
})
