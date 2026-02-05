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
  Plugin,
  ActiveElement,
  ChartEvent,
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
  borderRadius?: {
    topLeft?: number
    topRight?: number
    bottomLeft?: number
    bottomRight?: number
  }
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
  maintainAspectRatio?: boolean
  plugins?: Plugin<'bar'>[]
  padding?: {
    left?: number
    right?: number
    top?: number
    bottom?: number
  }
  onClick: (event: ChartEvent, elements: ActiveElement[]) => void
}

export const BarChart: React.FC<BarChartProps> = ({
  labels,
  values,
  width = '100%',
  height = 400,
  backgroundColor,
  borderColor,
  borderWidth = 1,
  borderRadius = {topLeft: 3, topRight: 3, bottomLeft: 0, bottomRight: 0},
  datasetLabel = 'Data',
  title,
  xAxisLabel,
  yAxisLabel,
  indexAxis = 'x',
  showLegend = true,
  showXAxisGrid = false,
  showYAxisGrid = false,
  showXAxisTicks = false,
  showYAxisTicks = false,
  gridColor = 'rgba(0, 0, 0, 0.1)',
  maintainAspectRatio = false,
  plugins = [],
  padding,
  onClick,
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
        labels,
        datasets: [
          {
            label: datasetLabel,
            data: values,
            backgroundColor,
            borderColor,
            borderWidth,
            categoryPercentage: 1.0,
            barPercentage: 0.85,
            borderRadius,
          },
        ],
      },
      options: {
        indexAxis,
        responsive: true,
        maintainAspectRatio,
        layout: {
          padding,
        },
        plugins: {
          legend: {
            display: showLegend,
            position: 'top',
          },
          title: {
            display: !!title,
            text: title || '',
          },
        },
        scales: {
          x: {
            grid: {
              display: showXAxisGrid,
              drawBorder: false,
              offset: true,
              color: gridColor,
            },
            title: {
              display: !!xAxisLabel,
              text: xAxisLabel || '',
            },
            ticks: {
              display: showXAxisTicks,
            },
            offset: true,
          },
          y: {
            grid: {
              display: showYAxisGrid,
              drawBorder: false,
              color: gridColor,
            },
            title: {
              display: false,
              text: yAxisLabel || '',
            },
            ticks: {
              display: showYAxisTicks,
            },
            beginAtZero: true,
          },
        },
        onClick: onClick,
      },
      plugins,
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
    borderRadius,
    datasetLabel,
    title,
    xAxisLabel,
    yAxisLabel,
    indexAxis,
    showLegend,
    showXAxisGrid,
    showYAxisGrid,
    showXAxisTicks,
    showYAxisTicks,
    gridColor,
    maintainAspectRatio,
    plugins,
    padding,
    onClick,
  ])

  return (
    <div style={{width, height}}>
      <canvas ref={canvasRef} />
    </div>
  )
}
