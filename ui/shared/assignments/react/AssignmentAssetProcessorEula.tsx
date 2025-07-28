/*
 * Copyright (C) 2025 - present Instructure, Inc.
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

import ExternalToolModalLauncher from '@canvas/external-tools/react/components/ExternalToolModalLauncher'
import {useScope as createI18nScope} from '@canvas/i18n'
import {useState, useRef, useEffect} from 'react'

const I18n = createI18nScope('assignment_publish_button')

type LaunchProp = {
  url: string
  name: string
}
interface Props {
  launches: LaunchProp[]
}

export default function AssignmentAssetProcessorEula({launches}: Props) {
  const [toLaunch, setToLaunch] = useState(launches)
  const [isOpen, setIsOpen] = useState(true)
  const timeoutRef = useRef<NodeJS.Timeout | null>(null)
  const currentLaunch = toLaunch?.[0]

  useEffect(() => {
    return () => {
      if (timeoutRef.current) {
        clearTimeout(timeoutRef.current)
      }
    }
  }, [])

  if (!currentLaunch) {
    return null
  }
  return (
    <ExternalToolModalLauncher
      isOpen={isOpen}
      title={I18n.t('EULA of %{toolName}', {toolName: currentLaunch.name})}
      iframeSrc={currentLaunch.url}
      onRequestClose={() => {
        setIsOpen(false)
        setToLaunch(prev => {
          if (prev.length > 1) {
            timeoutRef.current = setTimeout(() => setIsOpen(true), 200)
          }
          return prev.slice(1)
        })
      }}
    />
  )
}
