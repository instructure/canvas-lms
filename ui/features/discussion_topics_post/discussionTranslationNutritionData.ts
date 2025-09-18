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

import {useScope as createI18nScope} from '@canvas/i18n'
import {NutritionFactsExternalRoot} from '@canvas/nutrition-facts/react/types'
const I18n = createI18nScope('nutrition_facts')

export const DISCUSSION_TRANSLATION_NUTRITION_DATA: NutritionFactsExternalRoot = {
  id: 'canvascoursetranslation',
  name: I18n.t('Discussions Translation'),
  sha256: '143a3113a933aa37629e07aa2b49abfedf938ab52d1f3ff9daa3ff00a26a9a09',
  lastUpdated: '1758643492',
  nutritionFacts: {
    name: I18n.t('Discussions Translation'),
    description: I18n.t(
      'Translation of Discussion threads ("Course AI Translation" feature flag) across 10 languages.',
    ),
    data: [
      {
        blockTitle: I18n.t('Model & Data'),
        segmentData: [
          {
            description: I18n.t(
              'The foundational AI on which further training and customizations are built.',
            ),
            segmentTitle: I18n.t('Base Model'),
            value: I18n.t('Haiku 3'),
            valueDescription: I18n.t(
              "Anthropic Claude models are provided via Instructure's in-house AI Platform.",
            ),
          },
          {
            description: I18n.t(
              'Indicates the AI model has been given customer data in order to improve its results.',
            ),
            segmentTitle: I18n.t('Trained with User Data'),
            value: I18n.t('No'),
          },
          {
            description: I18n.t(
              'Indicates which training or operational content was given to the model.',
            ),
            segmentTitle: I18n.t('Data Shared with Model'),
            value: I18n.t('Course'),
            valueDescription: I18n.t('Discussion prompts and replies'),
          },
        ],
      },
      {
        blockTitle: I18n.t('Privacy & Compliance'),
        segmentData: [
          {
            description: I18n.t('How long the model stores customer data.'),
            segmentTitle: I18n.t('Data Retention'),
            valueDescription: I18n.t('Data is not stored or reused by the model.'),
            value: '',
          },
          {
            description: I18n.t(
              "Recording the AI's performance for auditing, analysis, and improvement.",
            ),
            segmentTitle: I18n.t('Data Logging'),
            value: I18n.t('Does not log data'),
            valueDescription: '',
          },
          {
            description: I18n.t(
              'The locations where the AI model is officially available and supported.',
            ),
            segmentTitle: I18n.t('Regions Supported'),
            value: I18n.t('Global'),
            valueDescription: '',
          },
          {
            description: I18n.t('Sensitive data that can be used to identify an individual.'),
            segmentTitle: I18n.t('PII'),
            value: I18n.t('Not Exposed'),
            valueDescription: I18n.t(
              'PII in discussion replies may be sent to the model, but no PII is intentionally sent to the model.',
            ),
          },
        ],
      },
      {
        blockTitle: I18n.t('Outputs'),
        segmentData: [
          {
            description: I18n.t('The ability to turn the AI on or off within the product.'),
            segmentTitle: I18n.t('AI Settings Control'),
            value: I18n.t('Yes'),
          },
          {
            description: I18n.t("Indicates if a human is involved in the AI's process or output."),
            segmentTitle: I18n.t('Human in the Loop'),
            value: I18n.t('Yes'),
            valueDescription: I18n.t(
              'Untranslated content is available to review translations against',
            ),
          },
          {
            description: I18n.t(
              'Preventative safety mechanisms or limitations built into the AI model.',
            ),
            segmentTitle: I18n.t('Guardrails'),
            valueDescription: '',
            value: '',
          },
          {
            description: I18n.t('Any risks the model may pose to the user.'),
            segmentTitle: I18n.t('Expected Risks'),
            valueDescription: I18n.t(
              'Machine translation may not fully capture the meaning of the original message.',
            ),
            value: '',
          },
          {
            description: I18n.t('The specific results the AI model is meant to achieve.'),
            segmentTitle: I18n.t('Intended Outcomes'),
            valueDescription: I18n.t(
              'Improve participation for students who do not natively speak the language of instruction or other replies.',
            ),
            value: '',
          },
        ],
      },
    ],
  },
  dataPermissionLevels: [
    {
      description: I18n.t(
        'We leverage anonymized aggregate data for detailed analytics to inform model development and product improvements. No AI models are used at this level.',
      ),
      name: I18n.t('Level 1'),
      title: I18n.t('Descriptive Analytics and Research'),
      level: 'Level 1',
    },
    {
      description: I18n.t(
        'We utilize off-the-shelf AI models and customer data as input to provide AI-powered features. No data is used for training this model.',
      ),
      name: I18n.t('Level 2'),
      title: I18n.t('AI-Powered Features Without Data Retention'),
      highlighted: true,
      level: 'Level 2',
    },
    {
      description: I18n.t(
        "We customize AI solutions tailored to the unique needs and resources of educational institutions. We use customer data to fine-tune data and train AI models that only serve your institution. Your institution's data only serves them through trained models.",
      ),
      name: I18n.t('Level 3'),
      title: I18n.t('AI Customization for Individual Institutions'),
      level: 'Level 3',
    },
    {
      description: I18n.t(
        'We established a consortium with educational institutions that shares anonymized data, best practices, and research findings. This fosters collaboration and accelerates the responsible development of AI in education. Specialized AI models are created for better outcomes in education, cost savings, and more.',
      ),
      name: I18n.t('Level 4'),
      title: I18n.t('Collaborative AI Consortium'),
      level: 'Level 4',
    },
  ],
  AiInformation: {
    featureName: I18n.t('Discussions Translation'),
    permissionLevelText: I18n.t('Permission Level'),
    permissionLevel: I18n.t('LEVEL 2'),
    description: I18n.t(
      'We utilize off-the-shelf AI models and customer data as input to provide AI-powered features. No data is used for training this model.',
    ),
    permissionLevelsModalTriggerText: I18n.t('Permission Levels'),
    modelNameText: I18n.t('Base Model'),
    modelName: I18n.t('Haiku 3'),
    nutritionFactsModalTriggerText: I18n.t('AI Nutrition Facts'),
  },
}
