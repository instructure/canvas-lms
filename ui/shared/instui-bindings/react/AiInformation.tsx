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
import {AiInformation} from '@instructure/ui-instructure'

const I18n = createI18nScope('canvas_ai_information')

interface Props {
  featureName: string
  modelName: string
  modelDescription?: string
  isTrainedWithUserData: boolean
  dataRetention: string
  dataLogging: string
  dataSharedWithModel: string
  dataSharedWithModelDescription?: string
  regionsSupported: string
  isPIIExposed: boolean
  isPIIExposedDescription?: string
  isFeatureBehindSetting: boolean
  isHumanInTheLoop: boolean
  guardrails?: string
  expectedRisks: string
  intendedOutcomes: string
  permissionsLevel: number
  triggerButton: React.ReactNode
}

// a template for AI nutrition facts
// includes text that is similar across all iterations of AiInformation
// ex. labels, permission levels, etc.
// feel free to make as strict/flexible as needed
export default function CanvasAiInformation(props: Props) {
  // descriptions for all permission levels
  const dataPermissionLevelsData = [
    {
      level: I18n.t('LEVEL 1'),
      title: I18n.t('Descriptive Analytics and Research'),
      description: I18n.t(
        'We leverage anonymized aggregate data for detailed analytics to inform model development and product improvements. No AI models are used at this level.',
      ),
      highlighted: props.permissionsLevel === 1,
    },
    {
      level: I18n.t('LEVEL 2'),
      title: I18n.t('AI-Powered Features Without Data Training'),
      description: I18n.t(
        'We utilize off-the-shelf AI models and customer data as input to provide AI-powered features. No data is used for training this model.',
      ),
      highlighted: props.permissionsLevel === 2,
    },
    {
      level: I18n.t('LEVEL 3'),
      title: I18n.t('AI Customization for Individual Institutions'),
      description: I18n.t(
        'We customize AI solutions tailored to the unique needs and resources of educational institutions. We use customer data to fine-tune data and train AI models that only serve your institution. Your institution’s data only serves them through trained models.',
      ),
      highlighted: props.permissionsLevel === 3,
    },
    {
      level: I18n.t('LEVEL 4'),
      title: I18n.t('Collaborative AI Consortium'),
      description: I18n.t(
        'We established a consortium with educational institutions that shares anonymized data, best practices, and research findings. This fosters collaboration and accelerates the responsible development of AI in education. Specialized AI models are created for better outcomes in education, cost savings, and more.',
      ),
      highlighted: props.permissionsLevel === 4,
    },
  ]

  let permissionLevel
  switch (props.permissionsLevel) {
    case 1:
      permissionLevel = dataPermissionLevelsData[0]
      break
    case 2:
      permissionLevel = dataPermissionLevelsData[1]
      break
    case 3:
      permissionLevel = dataPermissionLevelsData[2]
      break
    case 4:
      permissionLevel = dataPermissionLevelsData[3]
      break
    default:
      throw new Error('permissionsLevel must be an integer between 1 and 4')
  }
  // initial landing page data with links to nutrition facts and permission levels
  const data = [
    {
      featureName: props.featureName,
      permissionLevelText: I18n.t('Permission Level'),
      permissionLevel: permissionLevel.level,
      description: permissionLevel.description,
      permissionLevelsModalTriggerText: I18n.t('Permission Levels'),
      modelNameText: I18n.t('Base Model'),
      modelName: props.modelName,
      nutritionFactsModalTriggerText: I18n.t('AI Nutrition Facts'),
    },
  ]

  // nutrition fields (props supply value of each field)
  const nutritionFactsData = [
    {
      blockTitle: I18n.t('Model & Data'),
      segmentData: [
        {
          segmentTitle: I18n.t('Base Model'),
          description: I18n.t(
            'The foundational AI on which further training and customizations are built.',
          ),
          value: props.modelName,
          ...(props.modelDescription && {valueDescription: props.modelDescription}),
        },
        {
          segmentTitle: I18n.t('Trained with User Data'),
          description: I18n.t(
            'Indicates the AI model has been given customer data in order to improve its results.',
          ),
          value: props.isTrainedWithUserData ? I18n.t('Yes') : I18n.t('No'),
        },
        {
          segmentTitle: I18n.t('Data Shared with Model'),
          description: I18n.t(
            'Indicates which training or operational content was given to the model.',
          ),
          value: props.dataSharedWithModel,
          ...(props.dataSharedWithModelDescription && {
            valueDescription: props.dataSharedWithModelDescription,
          }),
        },
      ],
    },
    {
      blockTitle: I18n.t('Privacy & Compliance'),
      segmentData: [
        {
          segmentTitle: I18n.t('Data Retention'),
          description: I18n.t('How long the model stores customer data.'),
          value: props.dataRetention,
        },
        {
          segmentTitle: I18n.t('Data Logging'),
          description: I18n.t(
            "Recording the AI's performance for auditing, analysis, and improvement.",
          ),
          value: props.dataLogging,
        },
        {
          segmentTitle: I18n.t('Regions Supported'),
          description: I18n.t(
            'The locations where the AI model is officially available and supported.',
          ),
          value: props.regionsSupported,
        },
        {
          segmentTitle: I18n.t('PII'),
          description: I18n.t('Sensitive data that can be used to identify an individual.'),
          value: props.isPIIExposed ? I18n.t('Exposed') : I18n.t('Not Exposed'),
          ...(props.isPIIExposedDescription && {valueDescription: props.isPIIExposedDescription}),
        },
      ],
    },
    {
      blockTitle: I18n.t('Outputs'),
      segmentData: [
        {
          segmentTitle: I18n.t('AI Settings Control'),
          description: I18n.t('The ability to turn the AI on or off within the product.'),
          value: props.isFeatureBehindSetting ? I18n.t('Yes') : I18n.t('No'),
        },
        {
          segmentTitle: I18n.t('Human in the Loop'),
          description: I18n.t("Indicates if a human is involved in the AI's process or output."),
          value: props.isHumanInTheLoop ? I18n.t('Yes') : I18n.t('No'),
        },
        {
          segmentTitle: I18n.t('Guardrails'),
          description: I18n.t(
            'Preventative safety mechanisms or limitations built into the AI model.',
          ),
          value: props.guardrails ?? '',
        },
        {
          segmentTitle: I18n.t('Expected Risks'),
          description: I18n.t('Any risks the model may pose to the user.'),
          value: props.expectedRisks,
        },
        {
          segmentTitle: I18n.t('Intended Outcomes'),
          description: I18n.t('The specific results the AI model is meant to achieve.'),
          value: props.intendedOutcomes,
        },
      ],
    },
  ]

  const closeText = I18n.t('Close')
  return (
    <AiInformation
      title={I18n.t('About this AI Feature')}
      data={data}
      trigger={props.triggerButton}
      dataPermissionLevelsTitle={I18n.t('Data Permission Levels')}
      dataPermissionLevelsCurrentFeatureText={I18n.t('Current Feature:')}
      dataPermissionLevelsCurrentFeature={props.featureName}
      dataPermissionLevelsCloseIconButtonScreenReaderLabel={closeText}
      dataPermissionLevelsCloseButtonText={closeText}
      dataPermissionLevelsModalLabel={I18n.t('This is a Data Permission Levels modal')}
      nutritionFactsModalLabel={I18n.t('Information about this AI feature')}
      nutritionFactsTitle={I18n.t('Nutrition Facts')}
      nutritionFactsFeatureName={props.featureName}
      nutritionFactsCloseButtonText={closeText}
      nutritionFactsCloseIconButtonScreenReaderLabel={closeText}
      dataPermissionLevelsData={dataPermissionLevelsData}
      nutritionFactsData={nutritionFactsData}
    />
  )
}
