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

declare module '@instructure.ai/aiinfo' {
  export interface AiInformation {
    data: Array<{
      featureName: string
      permissionLevel: string
      modelName: string
      description: string
      permissionLevelText: string
      modelNameText: string
      permissionLevelsModalTriggerText: string
      nutritionFactsModalTriggerText: string
    }>
  }

  export interface DataPermissionLevel {
    data: Array<{
      level: string
      title: string
      description: string
      highlighted?: boolean
    }>
  }

  export interface NutritionFact {
    featureName: string
    data: Array<{
      blockTitle: string
      segmentData: Array<{
        segmentTitle: string
        value: string
        description: string
        valueDescription?: string
      }>
    }>
  }

  export interface FeatureInfo {
    aiInformation: AiInformation
    dataPermissionLevels: DataPermissionLevel
    nutritionFacts: NutritionFact
  }

  export const AiInfo: {
    [feature: string]: FeatureInfo
  }
}
