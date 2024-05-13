/*
 * Copyright (C) 2024 - present Instructure, Inc.
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

import IconAlarm from './alarm'
import IconApple from './apple'
import IconAtom from './atom'
import IconBasketball from './basketball'
import IconBell from './bell'
import IconBriefcase from './briefcase'
import IconCalculator from './calculator'
import IconCalendar from './calendar'
import IconClock from './clock'
import IconCog from './cog'
import IconCommunication from './communication'
import IconConicalFlask from './conical_flask'
import IconFlask from './flask'
import IconGlasses from './glasses'
import IconGlobe from './globe'
import IconIdea from './idea'
import IconMonitor from './monitor'
import IconNotePaper from './note_paper'
import IconNotebook from './notebook'
import IconNotes from './notes'
import IconPencil from './pencil'
import IconResume from './resume'
import IconRuler from './ruler'
import IconSchedule from './schedule'
import IconTestTube from './test_tube'
import {
  IconAnnouncement,
  IconGradebook,
  IconModule,
  IconVideo,
  IconArrowUp,
  IconLike,
} from './instuiIcons'
import {type IconProps, type IconSize} from './iconTypes'

type IconType = React.FC<IconProps>

const iconMap: Record<string, IconType> = {
  alarm: IconAlarm,
  apple: IconApple,
  atom: IconAtom,
  basketball: IconBasketball,
  bell: IconBell,
  briefcase: IconBriefcase,
  calculator: IconCalculator,
  calendar: IconCalendar,
  clock: IconClock,
  cog: IconCog,
  communication: IconCommunication,
  conical_flask: IconConicalFlask,
  flask: IconFlask,
  glasses: IconGlasses,
  globe: IconGlobe,
  idea: IconIdea,
  monitor: IconMonitor,
  note_paper: IconNotePaper,
  notebook: IconNotebook,
  notes: IconNotes,
  pencil: IconPencil,
  resume: IconResume,
  ruler: IconRuler,
  schedule: IconSchedule,
  test_tube: IconTestTube,
  announcement: IconAnnouncement,
  module: IconGradebook,
  video: IconModule,
  gradebook: IconVideo,
  arrow_up: IconArrowUp,
  like: IconLike,
}
Object.freeze(iconMap)

function getIcon(name: string): IconType {
  return iconMap[name]
}

export {
  getIcon,
  type IconProps,
  type IconSize,
  iconMap,
  IconAlarm,
  IconApple,
  IconAtom,
  IconBasketball,
  IconBell,
  IconBriefcase,
  IconCalculator,
  IconCalendar,
  IconClock,
  IconCog,
  IconCommunication,
  IconConicalFlask,
  IconFlask,
  IconGlasses,
  IconGlobe,
  IconIdea,
  IconMonitor,
  IconNotePaper,
  IconNotebook,
  IconNotes,
  IconPencil,
  IconResume,
  IconRuler,
  IconSchedule,
  IconTestTube,
  IconAnnouncement,
  IconGradebook,
  IconModule,
  IconVideo,
  IconArrowUp,
  IconLike,
}
