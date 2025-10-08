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

import React, {useState, useRef} from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import {View} from '@instructure/ui-view'
import {Heading} from '@instructure/ui-heading'
import {Text} from '@instructure/ui-text'
import {Flex} from '@instructure/ui-flex'
import {IconAiLine, IconAiSolid} from '@instructure/ui-icons'
import {Button} from '@instructure/ui-buttons'
import {AIExperience} from '../../types'
import LLMConversationView from '../../../../shared/ai-experiences/react/components/LLMConversationView'

const I18n = createI18nScope('ai_experiences_show')

interface AIExperienceShowProps {
  aiExperience: AIExperience
}

const AIExperienceShow: React.FC<AIExperienceShowProps> = ({aiExperience}) => {
  const [isConversationOpen, setIsConversationOpen] = useState(false)
  const testButtonRef = useRef<HTMLButtonElement>(null)
  console.log('AIExperienceShow received:', aiExperience)
  console.log('facts:', aiExperience.facts)
  console.log('learning_objective:', aiExperience.learning_objective)
  console.log('scenario:', aiExperience.scenario)
  console.log('Type of aiExperience:', typeof aiExperience)
  console.log('Keys:', Object.keys(aiExperience))

  return (
    <View as="div" maxWidth="1080px" margin="0 auto" padding="medium medium 0 medium">
      <Heading level="h1" margin="0 0 large 0">
        {aiExperience.title}
      </Heading>

      {aiExperience.description && (
        <View as="div" margin="0 0 medium 0">
          <Heading level="h2" margin="0 0 small 0">
            {I18n.t('Description')}
          </Heading>
          <Text>{aiExperience.description}</Text>
        </View>
      )}

      <Heading level="h2" margin="large 0 0 0">
        {I18n.t('Configurations')}
      </Heading>

      <div
        style={{
          margin: '0.75rem 0 0 0',
          borderRadius: '0.5rem',
          overflow: 'hidden',
          border: '3px solid transparent',
          backgroundImage:
            'linear-gradient(white, white), linear-gradient(90deg, rgb(106, 90, 205) 0%, rgb(70, 130, 180) 100%)',
          backgroundOrigin: 'border-box',
          backgroundClip: 'padding-box, border-box',
        }}
      >
        <div
          style={{
            padding: '1rem',
            background: 'linear-gradient(90deg, rgb(106, 90, 205) 0%, rgb(70, 130, 180) 100%)',
          }}
        >
          <Flex gap="small" alignItems="start">
            <IconAiLine color="primary-inverse" size="small" />
            <View>
              <Text color="primary-inverse" weight="bold" size="large">
                {I18n.t('Learning design')}
              </Text>
              <View as="div" margin="xx-small 0 0 0">
                <Text color="primary-inverse" size="small">
                  {I18n.t('What should students know and how should the AI behave?')}
                </Text>
              </View>
            </View>
          </Flex>
        </div>

        <View as="div" padding="medium" background="primary">
          {aiExperience.facts && (
            <View as="div" margin="0 0 medium 0">
              <Heading level="h3" margin="0 0 small 0">
                {I18n.t('Facts students should know')}
              </Heading>
              <Text>{aiExperience.facts}</Text>
            </View>
          )}

          {aiExperience.learning_objective && (
            <View as="div" margin="0 0 medium 0">
              <Heading level="h3" margin="0 0 small 0">
                {I18n.t('Learning objectives')}
              </Heading>
              <Text>{aiExperience.learning_objective}</Text>
            </View>
          )}

          {aiExperience.scenario && (
            <View as="div" margin="0 0 0 0">
              <Heading level="h3" margin="0 0 small 0">
                {I18n.t('Pedagogical guidance')}
              </Heading>
              <Text>{aiExperience.scenario}</Text>
            </View>
          )}
        </View>
      </div>

      {!isConversationOpen && (
        <View as="div" margin="large 0 large 0" textAlign="end">
          <Button
            color="ai-primary"
            renderIcon={<IconAiSolid />}
            onClick={() => setIsConversationOpen(true)}
            elementRef={el => {
              if (el) {
                // @ts-expect-error - elementRef accepts Element but we need HTMLButtonElement for focus()
                testButtonRef.current = el
              }
            }}
          >
            {I18n.t('Test AI Experience')}
          </Button>
        </View>
      )}

      {isConversationOpen && <View as="div" margin="large 0 0 0" />}

      <LLMConversationView
        isOpen={isConversationOpen}
        onClose={() => setIsConversationOpen(false)}
        returnFocusRef={testButtonRef}
        courseId={aiExperience.course_id}
        aiExperienceId={aiExperience.id}
        aiExperienceTitle={aiExperience.title}
        facts={aiExperience.facts}
        learningObjectives={aiExperience.learning_objective}
        scenario={aiExperience.scenario}
      />
    </View>
  )
}

export default AIExperienceShow
