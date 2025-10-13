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

interface AiPermissions {
  name: string
  title: string
  description: string
  highlighted?: boolean
  level: string
}

interface NutritionFactsSegment {
  description: string
  segmentTitle: string
  value: string
  valueDescription?: string
}

interface NutritionFactsBlock {
  blockTitle: string
  segmentData: NutritionFactsSegment[]
}

interface NutritionFacts {
  name: string
  description?: string
  data: NutritionFactsBlock[]
}

interface AiInformation {
  featureName: string
  permissionLevelText: string
  permissionLevel: string
  description: string
  permissionLevelsModalTriggerText: string
  modelNameText: string
  modelName: string
  nutritionFactsModalTriggerText: string
}

export interface NutritionFactsExternalRoot {
  id: string
  sha256: string
  lastUpdated: string
  name: string
  nutritionFacts: NutritionFacts
  dataPermissionLevels: AiPermissions[]
  AiInformation: AiInformation
}
