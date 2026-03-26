/*
 * Copyright (C) 2026 - present Instructure, Inc.
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
import React, {lazy, Suspense} from 'react'
import extensions from '@canvas/bundles/extensions'

export interface BarChartProps {
  labels: string[]
  values: number[]
  width?: number | string
  height?: number | string
  backgroundColor?: string | string[]
  borderColor?: string | string[]
  borderWidth?: number
  borderRadius?: number
  datasetLabel?: string
  title?: string
  xAxisLabel?: string
  yAxisLabel?: string
  indexAxis?: 'x' | 'y'
  showLegend?: boolean
  showXAxisGrid?: boolean
  showYAxisGrid?: boolean
  showXAxisTicks?: boolean
  showYAxisTicks?: boolean
  gridColor?: string
  padding?: {
    left?: number
    right?: number
    top?: number
    bottom?: number
  }
  onClick?: (index: number) => void
  xAxisImages?: (string | null)[]
  description?: string
  pointDescriptions?: string[]
  barFocusColor?: string
  xAxisLineColor?: string
}

const EXTENSION_KEY = 'ui/features/learning_mastery_v2/react/components/charts/HighchartsBarChart'

const HighchartsBarChart = lazy(async () => {
  const EmptyComponent = () => <></>
  try {
    const extension = (
      extensions as Record<string, () => Promise<{default: React.ComponentType<BarChartProps>}>>
    )[EXTENSION_KEY]

    if (extension) {
      return await extension()
    } else {
      return {default: EmptyComponent}
    }
  } catch {
    return {default: EmptyComponent}
  }
})

export const BarChart: React.FC<BarChartProps> = props => (
  <Suspense>
    <HighchartsBarChart {...props} />
  </Suspense>
)

export default BarChart
