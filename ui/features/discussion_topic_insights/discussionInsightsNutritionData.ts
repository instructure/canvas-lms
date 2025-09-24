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

export const DISCUSSION_INSIGHT_NUTRITION_DATA: NutritionFactsExternalRoot = {
  id: 'discussioninsights',
  name: I18n.t('Discussion Insights'),
  sha256: '2340cc40bb84de62148b49451b0868b9c7bfe525b8fb36158694d7cacd9221e5',
  lastUpdated: '1758643492',
  nutritionFacts: {
    name: I18n.t('Discussion Insights'),
    description: I18n.t(
      'Discussion Insights uses AI to evaluate student discussion replies, highlight relevant contributions, and flag those that may need instructor review.',
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
              'Anthropic Claude models are provided via Amazon Bedrock Foundation Models (FMs).',
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
            valueDescription: I18n.t('Discussion topic, prompt, and student replies are used.'),
          },
        ],
      },
      {
        blockTitle: I18n.t('Privacy & Compliance'),
        segmentData: [
          {
            description: I18n.t('How long the model stores customer data.'),
            segmentTitle: I18n.t('Data Retention'),
            value: '',
            valueDescription: I18n.t('No user data is stored or reused by the model.'),
          },
          {
            description: I18n.t(
              "Recording the AI's performance for auditing, analysis, and improvement.",
            ),
            segmentTitle: I18n.t('Data Logging'),
            value: I18n.t('Logs data'),
            valueDescription: I18n.t(
              'Model evaluations and reply labels are logged for debugging and troubleshooting purposes.',
            ),
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
            value: I18n.t('Exposed'),
            valueDescription: I18n.t(
              'Known PII is masked before being sent to the model, though any PII present in the discussion reply is not and may be shared with the model.',
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
              'Instructors may review AI-generated evaluations or review posts directly.',
            ),
          },
          {
            description: I18n.t(
              'Preventative safety mechanisms or limitations built into the AI model.',
            ),
            segmentTitle: I18n.t('Guardrails'),
            value: '',
            valueDescription: I18n.t(
              'Model responses are logged for quality assurance, and responses with low confidence are flagged "Needs Review" to encourage human intervention.',
            ),
          },
          {
            description: I18n.t('Any risks the model may pose to the user.'),
            segmentTitle: I18n.t('Expected Risks'),
            valueDescription: I18n.t('The model may misclassify some nuanced replies.'),
            value: '',
          },
          {
            description: I18n.t('The specific results the AI model is meant to achieve.'),
            segmentTitle: I18n.t('Intended Outcomes'),
            valueDescription: I18n.t(
              'Instructors are able to quickly assess the quality of student replies, identify low-effor or off-topic contributions, and focus their attention to where it is needed most.',
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
      level: '1',
    },
    {
      description: I18n.t(
        'We utilize off-the-shelf AI models and customer data as input to provide AI-powered features. No data is used for training this model.',
      ),
      name: I18n.t('Level 2'),
      title: I18n.t('AI-Powered Features Without Data Retention'),
      highlighted: true,
      level: '2',
    },
    {
      description: I18n.t(
        "We customize AI solutions tailored to the unique needs and resources of educational institutions. We use customer data to fine-tune data and train AI models that only serve your institution. Your institution's data only serves them through trained models.",
      ),
      name: I18n.t('Level 3'),
      title: I18n.t('AI Customization for Individual Institutions'),
      level: '3',
    },
    {
      description: I18n.t(
        'We established a consortium with educational institutions that shares anonymized data, best practices, and research findings. This fosters collaboration and accelerates the responsible development of AI in education. Specialized AI models are created for better outcomes in education, cost savings, and more.',
      ),
      name: I18n.t('Level 4'),
      title: I18n.t('Collaborative AI Consortium'),
      level: '4',
    },
  ],
  AiInformation: {
    featureName: I18n.t('Discussion Insights'),
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
