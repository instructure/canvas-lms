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

import React, {useState} from 'react'
import {useScope as useI18nScope} from '@canvas/i18n'
import PropTypes from 'prop-types'
import {View} from '@instructure/ui-view'
import {Text} from '@instructure/ui-text'
import {Img} from '@instructure/ui-img'
import Modal from '@canvas/instui-bindings/react/InstuiModal'
import {Link} from '@instructure/ui-link'
import {TruncateText} from '@instructure/ui-truncate-text'
import {Tooltip} from '@instructure/ui-tooltip'
import {IconLtiSolid} from '@instructure/ui-icons'
import {PresentationContent} from '@instructure/ui-a11y-content'
import {getK5ThemeVars} from './k5-theme'
import {Flex} from '@instructure/ui-flex'

const k5ThemeVariables = getK5ThemeVars()

const I18n = useI18nScope('k5_app_link')

export default function K5AppLink({app}) {
  const [isModalOpen, setModalOpen] = useState(false)
  const [isTruncated, setTruncated] = useState(false)

  const launchApp = () => {
    if (app.courses.length > 1) {
      setModalOpen(true)
    } else if (app.windowTarget) {
      window.open(launchUrl(app.courses[0].id), app.windowTarget)
    } else {
      window.location.assign(launchUrl(app.courses[0].id))
    }
  }

  const launchUrl = courseId =>
    `/courses/${courseId}/external_tools/${app.id}${
      app.windowTarget && app.windowTarget === '_blank' ? `?display=borderless` : ''
    }`

  const renderButton = () => (
    <View
      data-testid="k5-app-button"
      position="relative"
      margin="small"
      padding="small"
      width="18em"
      textAlign="start"
      borderWidth="small"
      borderColor="primary"
      borderRadius="medium"
      background="transparent"
      shadow="resting"
      onClick={launchApp}
    >
      <Flex alignItems="center">
        <Flex.Item padding="0 x-small 0 0">
          {app.icon ? (
            <Img
              src={app.icon}
              // docs require provided LTI icons to be at least 16px
              width="16px"
              height="16px"
              constrain="contain"
              data-testid="renderedIcon"
            />
          ) : (
            <IconLtiSolid data-testid="defaultIcon" />
          )}
        </Flex.Item>
        <Flex.Item shouldGrow={true} shouldShrink={true}>
          <Text size="small">
            <TruncateText maxLines="1" onUpdate={(truncated, _text) => setTruncated(truncated)}>
              {app.title}
            </TruncateText>
          </Text>
        </Flex.Item>
      </Flex>
    </View>
  )

  return (
    <>
      {isTruncated ? <Tooltip renderTip={app.title}>{renderButton()}</Tooltip> : renderButton()}
      {/* show modal if there's more than one course with this tool installed */}
      {app.courses.length > 1 && (
        <Modal
          label={I18n.t('Choose a Course')}
          open={isModalOpen}
          size="small"
          onDismiss={() => setModalOpen(false)}
        >
          <Modal.Body>
            {app.courses.map(course => (
              <View key={course.id}>
                <Link
                  display="block"
                  href={launchUrl(course.id)}
                  isWithinText={false}
                  themeOverride={{
                    color: k5ThemeVariables.colors.textDarkest,
                    hoverColor: k5ThemeVariables.colors.textDarkest,
                  }}
                  target={app.windowTarget}
                >
                  {course.name}
                </Link>
                <PresentationContent>
                  <hr style={{margin: '0.6em 0'}} />
                </PresentationContent>
              </View>
            ))}
          </Modal.Body>
        </Modal>
      )}
    </>
  )
}

export const AppShape = {
  id: PropTypes.string.isRequired,
  courses: PropTypes.arrayOf(
    PropTypes.shape({id: PropTypes.string.isRequired, name: PropTypes.string.isRequired})
  ).isRequired,
  title: PropTypes.string.isRequired,
  icon: PropTypes.string,
  windowTarget: PropTypes.string,
}

K5AppLink.propTypes = {
  app: PropTypes.shape(AppShape).isRequired,
}
