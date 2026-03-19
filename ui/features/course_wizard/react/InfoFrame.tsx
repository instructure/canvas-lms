/*
 * Copyright (C) 2014 - present Instructure, Inc.
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

import $ from 'jquery'
import {find} from 'es-toolkit/compat'
import React, {useState, useEffect, useRef} from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import ListItems, {type ListItem} from './ListItems'
import getCookie from '@instructure/get-cookie'

const I18n = createI18nScope('course_wizard')

interface DefaultItem {
  text: string
  warning?: string
  iconClass: string
}

const courseNotSetUpItem: DefaultItem = {
  get text() {
    return I18n.t(
      "Great, so you've got a course. Now what? Well, before you go publishing it to the world, you may want to check and make sure you've got the basics laid out.  Work through the list on the left to ensure that your course is ready to use.",
    )
  },
  get warning() {
    return I18n.t('This course is visible only to teachers until it is published.')
  },
  iconClass: 'icon-instructure',
}

const checklistComplete: DefaultItem = {
  get text() {
    return I18n.t(
      "Now that your course is set up and available, you probably won't need this checklist anymore. But we'll keep it around in case you realize later you want to try something new, or you just want a little extra help as you make changes to your course content.",
    )
  },
  iconClass: 'icon-instructure',
}

export interface InfoFrameProps {
  closeModal: () => void
  className?: string
  itemToShow?: string
}

export default function InfoFrame({
  closeModal,
  className,
  itemToShow,
}: InfoFrameProps): React.JSX.Element {
  const [itemShown, setItemShown] = useState<ListItem | DefaultItem>(() => {
    // @ts-expect-error - ENV.COURSE_WIZARD not typed in GlobalEnv
    if (window.ENV.COURSE_WIZARD.checklist_states.publish_step) {
      return checklistComplete
    }
    return courseNotSetUpItem
  })

  const messageBox = useRef<HTMLDivElement>(null)
  const messageIcon = useRef<HTMLDivElement>(null)
  const callToAction = useRef<HTMLAnchorElement | HTMLButtonElement>(null)

  useEffect(() => {
    if (itemToShow) {
      const item = find(ListItems, {key: itemToShow})
      if (item) {
        setItemShown(item)

        // Animation logic
        // @ts-expect-error - jQuery types don't properly handle $(HTMLElement)
        const $messageBox = $(messageBox.current)
        // @ts-expect-error - jQuery types don't properly handle $(HTMLElement)
        const $messageIcon = $(messageIcon.current)

        // I would use .toggle, but it has too much potential to get all out
        // of whack having to be called twice to force the animation.

        // Remove the animation classes in case they are there already.
        // @ts-expect-error - jQuery types don't properly handle $(HTMLElement).removeClass
        $messageBox.removeClass('ic-wizard-box__message-inner--is-fired')
        // @ts-expect-error - jQuery types don't properly handle $(HTMLElement).removeClass
        $messageIcon.removeClass('ic-wizard-box__message-icon--is-fired')

        // Add them back
        setTimeout(() => {
          // @ts-expect-error - jQuery types don't properly handle $(HTMLElement).addClass
          $messageBox.addClass('ic-wizard-box__message-inner--is-fired')
          // @ts-expect-error - jQuery types don't properly handle $(HTMLElement).addClass
          $messageIcon.addClass('ic-wizard-box__message-icon--is-fired')
        }, 100)

        // Set the focus to the call to action 'button' if it's there
        // otherwise the text.
        if (callToAction.current) {
          callToAction.current.focus()
        } else {
          messageBox.current?.focus()
        }
      }
    }
  }, [itemToShow])

  const getHref = (): string => {
    return 'url' in itemShown && itemShown.url ? itemShown.url : '#'
  }

  const chooseHomePage = (event: React.MouseEvent<HTMLAnchorElement>): void => {
    event.preventDefault()
    closeModal()
    $('.choose_home_page_link').click()
  }

  const renderButton = (): React.ReactNode => {
    if ('key' in itemShown && itemShown.key === 'home_page') {
      return (
        // TODO: use InstUI button
        // eslint-disable-next-line jsx-a11y/anchor-is-valid, jsx-a11y/click-events-have-key-events, jsx-a11y/interactive-supports-focus
        <a
          role="button"
          ref={callToAction as React.RefObject<HTMLAnchorElement>}
          onClick={chooseHomePage}
          className="Button Button--primary"
          aria-label={`Start task: ${'title' in itemShown ? itemShown.title : ''}`}
          aria-describedby="ic-wizard-box__message-text"
        >
          {'title' in itemShown ? itemShown.title : ''}
        </a>
      )
    }
    if ('key' in itemShown && itemShown.key === 'publish_course') {
      // @ts-expect-error - ENV.COURSE_WIZARD not typed in GlobalEnv
      if (window.ENV.COURSE_WIZARD.permissions.can_change_course_publish_state) {
        return (
          <form
            acceptCharset="UTF-8"
            // @ts-expect-error - ENV.COURSE_WIZARD not typed in GlobalEnv
            action={window.ENV.COURSE_WIZARD.publish_course}
            method="post"
          >
            <input name="utf8" type="hidden" value="✓" />
            <input name="_method" type="hidden" value="put" />
            <input name="authenticity_token" type="hidden" value={getCookie('_csrf_token')} />
            <input type="hidden" name="course[event]" value="offer" />
            <button
              ref={callToAction as React.RefObject<HTMLButtonElement>}
              type="submit"
              className="Button Button--success"
            >
              {'title' in itemShown ? itemShown.title : ''}
            </button>
          </form>
        )
      } else {
        return <b>{I18n.t('You do not have permission to publish this course.')}</b>
      }
    }
    if ('title' in itemShown) {
      return (
        <a
          ref={callToAction as React.RefObject<HTMLAnchorElement>}
          href={getHref()}
          className="Button Button--primary"
          aria-label={`Start task: ${itemShown.title}`}
          aria-describedby="ic-wizard-box__message-text"
        >
          {itemShown.title}
        </a>
      )
    } else if ('warning' in itemShown && itemShown.warning) {
      return <b>{itemShown.warning}</b>
    } else {
      return null
    }
  }

  return (
    <div className={className}>
      <h1 className="ic-wizard-box__headline">{I18n.t('Next Steps')}</h1>
      <div className="ic-wizard-box__message">
        <div className="ic-wizard-box__message-layout">
          <div
            ref={messageIcon}
            className="ic-wizard-box__message-icon ic-wizard-box__message-icon--is-fired"
          >
            <i className={itemShown.iconClass} />
          </div>
          <div
            ref={messageBox}
            tabIndex={-1}
            className="ic-wizard-box__message-inner ic-wizard-box__message-inner--is-fired"
          >
            <p className="ic-wizard-box__message-text" id="ic-wizard-box__message-text">
              {itemShown.text}
            </p>
            <div className="ic-wizard-box__message-button">{renderButton()}</div>
          </div>
        </div>
      </div>
    </div>
  )
}
