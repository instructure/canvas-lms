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
import React, {useEffect, useRef} from 'react'
import {
  Chart as ChartJS,
  CategoryScale,
  LinearScale,
  BarElement,
  BarController,
  Title,
  Tooltip,
  Legend,
  ChartConfiguration,
} from 'chart.js'

ChartJS.register(CategoryScale, LinearScale, BarElement, BarController, Title, Tooltip, Legend)

export interface BarChartProps {
  labels: string[]
  values: number[]
  width?: number | string
  height?: number | string
  backgroundColor?: string | string[]
  borderColor?: string | string[]
  borderWidth?: number
  datasetLabel?: string
  title?: string
  xAxisLabel?: string
  yAxisLabel?: string
  indexAxis?: 'x' | 'y'
  showLegend?: boolean
  showGrid?: boolean
  maintainAspectRatio?: boolean
  isPreview?: boolean
  padding?: {
    left?: number
    right?: number
    top?: number
    bottom?: number
  }
}

export const BarChart: React.FC<BarChartProps> = ({
  labels,
  values,
  width = '100%',
  height = 400,
  backgroundColor,
  borderColor,
  borderWidth = 1,
  datasetLabel = 'Data',
  title,
  xAxisLabel,
  yAxisLabel,
  indexAxis = 'x',
  showLegend = true,
  showGrid = true,
  maintainAspectRatio = false,
  isPreview = false,
  padding = {left: 28, right: 30, top: 12, bottom: 12},
}) => {
  const canvasRef = useRef<HTMLCanvasElement>(null)
  const chartRef = useRef<ChartJS<'bar'> | null>(null)

  useEffect(() => {
    if (!canvasRef.current) return

    const ctx = canvasRef.current.getContext('2d')
    if (!ctx) return

    if (chartRef.current) {
      chartRef.current.destroy()
    }

    const config: ChartConfiguration<'bar'> = {
      type: 'bar',
      data: {
        labels: isPreview ? labels.map(() => '') : labels,
        datasets: [
          {
            label: isPreview ? '' : datasetLabel,
            data: values,
            backgroundColor,
            borderColor,
            borderWidth,
            categoryPercentage: 1.0,
            barPercentage: 0.9,
            borderRadius: {
              topLeft: 1,
              topRight: 1,
              bottomLeft: 0,
              bottomRight: 0,
            },
          },
        ],
      },
      options: {
        indexAxis,
        responsive: true,
        maintainAspectRatio,
        layout: {
          padding: {
            left: padding.left ?? 6,
            right: padding.right ?? 8,
            top: padding.top ?? 12,
            bottom: padding.bottom ?? 12,
          },
        },
        plugins: {
          legend: {
            display: isPreview ? false : showLegend,
            position: 'top',
          },
          title: {
            display: isPreview ? false : !!title,
            text: title || '',
          },
        },
        scales: {
          x: {
            grid: {
              display: isPreview ? false : showGrid,
              drawBorder: false,
              offset: true,
            },
            title: {
              display: isPreview ? false : !!xAxisLabel,
              text: xAxisLabel || '',
            },
            ticks: {
              display: isPreview ? false : !!xAxisLabel,
            },
            offset: true,
          },
          y: {
            grid: {
              display: isPreview ? false : showGrid,
              drawBorder: false,
            },
            title: {
              display: false,
              text: yAxisLabel || '',
            },
            ticks: {
              display: isPreview ? false : !!yAxisLabel,
            },
            beginAtZero: true,
          },
        },
      },
    }

    chartRef.current = new ChartJS(ctx, config)

    return () => {
      if (chartRef.current) {
        chartRef.current.destroy()
        chartRef.current = null
      }
    }
  }, [
    labels,
    values,
    backgroundColor,
    borderColor,
    borderWidth,
    datasetLabel,
    title,
    xAxisLabel,
    yAxisLabel,
    indexAxis,
    showLegend,
    showGrid,
    maintainAspectRatio,
    isPreview,
    padding,
  ])

  return (
    <div style={{width, height}}>
      <canvas ref={canvasRef} />
    </div>
  )
}
