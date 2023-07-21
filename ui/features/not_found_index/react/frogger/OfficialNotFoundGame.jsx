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

import React from 'react'
import {Character, Obstacle, GoalObject} from './characters'

const CANVAS_WIDTH = 180
const CANVAS_HEIGHT = 720
const GOAL_REACHED_SCORE = 13146
const MAIN_CHAR_LENGTH = 32

const randomNumberBetween = (min, max) => Math.floor(Math.random() * (max - min + 1) + min)

class OfficialNotFoundGame extends React.Component {
  constructor(props) {
    super(props)

    this.state = {
      gameTimer: 0,
    }

    this.gameStarted = false
    this.keysPressed = {}
    this.obstacles = []
    this.gameLoop = null
    this.goalObject = null

    document.body.addEventListener('keydown', event => {
      if (event.keyCode === 32 && !this.gameStarted) {
        this.startGame()
      }

      if (event.keyCode === 27 && this.gameStarted) {
        this.endGame(this.gameCanvas.getContext('2d'))
      }

      this.keysPressed[event.keyCode] = true

      // Prevent default
      if ([32, 37, 38, 39, 40].indexOf(event.keyCode) > -1) {
        event.preventDefault()
      }
    })

    document.body.addEventListener('keyup', event => {
      delete this.keysPressed[event.keyCode]
    })
  }

  componentDidMount() {
    if (!this.gameStarted) {
      this.startGame()
    }
  }

  setCanvasRef = el => {
    this.gameCanvas = el
  }

  restartGame = () => {
    this.startGame()
  }

  startGame = () => {
    this.gameStarted = true
    this.setState({gameTimer: 0})

    // This puts the positions
    this.resetCharacters()

    // Starts the event loop at 30 ms
    this.gameLoop = setInterval(this.eventGameFrameLoop, 30)
  }

  resetCharacters = () => {
    this.mainCharacter = new Character({
      width: MAIN_CHAR_LENGTH,
      height: MAIN_CHAR_LENGTH,
      x: CANVAS_WIDTH / 2 - MAIN_CHAR_LENGTH / 2,
      y: CANVAS_HEIGHT - MAIN_CHAR_LENGTH,
    })

    const ctx = this.gameCanvas.getContext('2d')
    ctx.clearRect(0, 0, this.gameCanvas.width, this.gameCanvas.height)

    this.mainCharacter.draw(ctx)

    this.goalObject = new GoalObject({
      width: MAIN_CHAR_LENGTH,
      height: MAIN_CHAR_LENGTH,
      x: randomNumberBetween(0, CANVAS_WIDTH - MAIN_CHAR_LENGTH),
      y: 0,
    })
  }

  goalReached = () => {
    this.setState({gameTimer: this.state.gameTimer + GOAL_REACHED_SCORE})
    this.resetCharacters()
  }

  createObstacle = () => {
    const obstacleWidth = 20
    const rightOrLeft = randomNumberBetween(0, 5)

    const placedY = randomNumberBetween(0, CANVAS_HEIGHT)
    let placedX = randomNumberBetween(0, CANVAS_WIDTH)

    if (rightOrLeft > 3) {
      placedX = CANVAS_WIDTH - obstacleWidth
    } else {
      placedX = 0
    }

    this.obstacles.push(
      new Obstacle({
        speed: randomNumberBetween(1, 9),
        width: obstacleWidth,
        height: obstacleWidth,
        x: placedX,
        y: placedY,
        goingLeft: rightOrLeft > 3,
      })
    )
  }

  moveCharacter = (dx, dy) => {
    this.mainCharacter.move(dx, dy)
  }

  playerController = () => {
    const playerMovement = 8
    if (this.gameStarted) {
      if (this.keysPressed[37]) {
        if (this.mainCharacter.x >= 0) {
          this.moveCharacter(-playerMovement, 0)
        }
      }

      if (this.keysPressed[38]) {
        if (this.mainCharacter.y >= 0) {
          this.moveCharacter(0, -playerMovement)
        }
      }

      if (this.keysPressed[39]) {
        if (this.mainCharacter.x + MAIN_CHAR_LENGTH <= CANVAS_WIDTH) {
          this.moveCharacter(playerMovement, 0)
        }
      }

      if (this.keysPressed[40]) {
        if (this.mainCharacter.y + MAIN_CHAR_LENGTH <= CANVAS_HEIGHT) {
          this.moveCharacter(0, playerMovement)
        }
      }
    }
  }

  endGame = ctx => {
    clearInterval(this.gameLoop)
    this.gameStarted = false
    this.obstacles = []
    this.mainCharacter = null
    ctx.clearRect(0, 0, this.gameCanvas.width, this.gameCanvas.height)
  }

  eventGameFrameLoop = () => {
    if (!this.gameStarted) {
      return false
    }
    this.setState({gameTimer: this.state.gameTimer + 1})

    const ctx = this.gameCanvas.getContext('2d')
    ctx.clearRect(0, 0, this.gameCanvas.width, this.gameCanvas.height)

    // Controls Player Movement
    this.playerController()

    this.mainCharacter.draw(ctx)

    this.goalObject.draw(ctx)

    if (
      this.goalObject.checkCollide(
        this.mainCharacter.x,
        this.mainCharacter.y,
        MAIN_CHAR_LENGTH,
        MAIN_CHAR_LENGTH
      )
    ) {
      this.goalReached()
    }

    const shouldGenerateObstacle = randomNumberBetween(0, 26) > 20
    if (shouldGenerateObstacle) {
      this.createObstacle()
    }

    for (let i = 0; i < this.obstacles.length; i++) {
      const currentObs = this.obstacles[i]
      currentObs.move()
      if (
        currentObs.checkCollide(
          this.mainCharacter.x,
          this.mainCharacter.y,
          MAIN_CHAR_LENGTH,
          MAIN_CHAR_LENGTH
        )
      ) {
        this.endGame(ctx)
        return null
      }
      currentObs.draw(ctx)
    }

    return null
  }

  checkInArena(x, y) {
    const buffer = 100
    if (
      x > -buffer &&
      x < this.CANVAS_WIDTH + buffer &&
      y > -buffer &&
      y < this.CANVAS_HEIGHT + buffer
    ) {
      return true
    } else {
      return false
    }
  }

  render() {
    return (
      <div
        className="not_found_page_game_root"
        style={{
          display: 'flex',
          flexDirection: 'column',
          alignItems: 'center',
          justifyContent: 'center',
        }}
      >
        <div
          style={{
            fontSize: '20px',
            padding: '4px',
            display: 'flex',
            flexDirection: 'row',
            alignItems: 'flex-end',
            justifyContent: 'flex-end',
          }}
        >
          <div>{`Score: ${this.state.gameTimer}`}</div>
        </div>
        <canvas
          ref={this.setCanvasRef}
          width={CANVAS_WIDTH}
          height={CANVAS_HEIGHT}
          style={{
            border: '2px',
            borderStyle: 'solid',
            borderColor: '#394B58',
          }}
        />
      </div>
    )
  }
}

export default OfficialNotFoundGame
