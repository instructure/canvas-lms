/*
 * Copyright (C) 2023 - present Instructure, Inc.
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

import React, {useEffect, useState} from 'react'
import {Img} from '@instructure/ui-img'
import {useScope as useI18nScope} from '@canvas/i18n'
import imageSource from './StudiousPandaSource'

const I18n = useI18nScope('not_found_page_slide_puzzle')

const GRID_SIZE = 4
const DIMENSION = 556
const TILE_DIMENSION = DIMENSION / GRID_SIZE

interface Delta {
  xOffset: number
  yOffset: number
}

interface TileData {
  value: number
  position: number // eslint-disable-line react/no-unused-prop-types
  x: number
  y: number
  translation: string
}

const DeltaMap: Record<string, Delta> = {
  ArrowUp: {xOffset: 0, yOffset: TILE_DIMENSION},
  ArrowDown: {xOffset: 0, yOffset: -TILE_DIMENSION},
  ArrowLeft: {xOffset: TILE_DIMENSION, yOffset: 0},
  ArrowRight: {xOffset: -TILE_DIMENSION, yOffset: 0},
}

function generateTiles(): TileData[] {
  const tiles: TileData[] = []
  for (let i = 0; i < GRID_SIZE * GRID_SIZE; i++) {
    const x = (i % GRID_SIZE) * TILE_DIMENSION
    const y = Math.floor(i / GRID_SIZE) * TILE_DIMENSION
    tiles.push({
      position: i,
      value: i + 1,
      x,
      y,
      translation: `-${x}px -${y}px`,
    })
  }
  return tiles
}

function swapTiles(tile1: TileData, tile2: TileData) {
  const tempValue = tile1.value
  tile1.value = tile2.value
  tile2.value = tempValue

  const tempTranslation = tile1.translation
  tile1.translation = tile2.translation
  tile2.translation = tempTranslation
}

function shuffleTiles(tiles: TileData[]): TileData[] {
  for (let i = 0; i < 500; i++) {
    const move = Object.keys(DeltaMap)[Math.floor(Math.random() * 4)]
    tryMove(tiles, move)
  }
  return tiles
}

function isSolved(tiles: TileData[]): boolean {
  return tiles.every(tile => tile.value === tile.position + 1)
}

function tryMove(tiles: TileData[], move: string): boolean {
  const emptyTile = tiles.find(tile => tile.value === GRID_SIZE * GRID_SIZE)!
  const {xOffset, yOffset} = DeltaMap[move]
  const tileToMove = tiles.find(
    tile => tile.x === emptyTile.x + xOffset && tile.y === emptyTile.y + yOffset
  )
  if (tileToMove) {
    swapTiles(emptyTile, tileToMove)
    return true
  }
  return false
}

const Tile = ({value, x, y, translation}: TileData) => {
  const enabled = value !== GRID_SIZE * GRID_SIZE
  const background = enabled ? `url(${imageSource}) ${translation}` : 'black'
  return (
    <div
      className="tile"
      style={{
        width: `${DIMENSION / GRID_SIZE}px`,
        height: `${DIMENSION / GRID_SIZE}px`,
        border: '1px solid black',
        position: 'absolute',
        left: `${x}px`,
        top: `${y}px`,
        background,
        color: 'yellow',
        fontSize: '1.25em',
      }}
    >
      {enabled && value}
    </div>
  )
}

const SlidePuzzle = () => {
  const [tiles] = useState(shuffleTiles(generateTiles()))
  const [moveCount, setMoveCount] = useState(0)

  useEffect(() => {
    function handleKeyUp(e: KeyboardEvent) {
      if (!Object.keys(DeltaMap).includes(e.key)) return
      if (tryMove(tiles, e.key)) {
        setMoveCount(prevCount => prevCount + 1)
      }
    }
    document.addEventListener('keyup', handleKeyUp)
    return () => {
      document.removeEventListener('keyup', handleKeyUp)
    }
  }, [tiles])

  return (
    <div
      id="puzzle-container"
      style={{
        display: 'flex',
        flexDirection: 'column',
        justifyContent: 'center',
        alignItems: 'center',
      }}
    >
      <div
        id="score-container"
        style={{
          fontSize: '1.8em',
          display: 'flex',
          justifyContent: 'flex-end',
          alignItems: 'flex-end',
        }}
      >
        {I18n.t('Moves:')} {moveCount}
      </div>
      <div
        id="tile-container"
        style={{
          width: `${DIMENSION}px`,
          height: `${DIMENSION}px`,
          border: '1px solid',
          position: 'relative',
          display: 'inline-block',
        }}
      >
        {!isSolved(tiles) ? (
          tiles.map(tileData => {
            return <Tile {...tileData} key={tileData.value} />
          })
        ) : (
          <Img src={imageSource} alt={I18n.t('A studious panda')} />
        )}
      </div>
    </div>
  )
}

export default SlidePuzzle
