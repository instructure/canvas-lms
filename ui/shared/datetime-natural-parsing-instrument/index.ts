/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

export type DTNPIEvent = {
  // A unique ID for the widget that generated this event, which can be used
  // to group related events to get an idea of the whole interaction.
  id: string
  type: string
  locale?: string | null
  method: 'pick' | 'type' | 'paste'
  // Will be null if the value did not parse into a date.
  parsed?: string | null
  value: string | null
}

let state: {
  events: DTNPIEvent[]
} = {events: []}

export function configure({events}: {events: Array<DTNPIEvent>}) {
  const previousState = {...state}
  state = {events}
  return previousState
}

export const log = (event: DTNPIEvent): void => {
  state.events.push(event)
}
