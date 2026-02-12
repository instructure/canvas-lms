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
import {Heading} from '@instructure/ui-heading'
import {View} from '@instructure/ui-view'
import {
  Chart as ChartJS,
  CategoryScale,
  LinearScale,
  BarElement,
  BarController,
  Title,
  Tooltip,
  Legend,
  ChartOptions,
  ChartConfiguration,
} from 'chart.js'
import {colors} from '@instructure/canvas-theme'

ChartJS.register(CategoryScale, LinearScale, BarElement, BarController, Title, Tooltip, Legend)

const colorMapping: Record<BarChartDataItemColor, string> = {
  red: colors.ui.surfaceError,
  green: colors.ui.surfaceSuccess,
}

export type BarChartDataItemColor = 'red' | 'green'

export type BarChartDataItem = {
  label: string
  value: number
  color: BarChartDataItemColor
  emphasized?: boolean
}

export type BarChartProps = {
  title: string
  data: BarChartDataItem[]
  barThickness?: number
}

export const BarChart = (props: BarChartProps) => {
  const canvasRef = useRef<HTMLCanvasElement>(null)
  const chartRef = useRef<ChartJS<'bar'> | null>(null)

  useEffect(() => {
    if (!canvasRef.current) return

    const chartData = {
      labels: props.data.map(item => item.label),
      datasets: [
        {
          data: props.data.map(item => item.value),
          backgroundColor: props.data.map(item => colorMapping[item.color]),
          borderWidth: 0,
          borderRadius: {topRight: 4, bottomRight: 4, topLeft: 0, bottomLeft: 0},
          borderSkipped: false,
          ...(props.barThickness && {barThickness: props.barThickness}),
        },
      ],
    }

    const options: ChartOptions<'bar'> = {
      indexAxis: 'y',
      responsive: true,
      maintainAspectRatio: false,
      layout: {
        padding: 0,
      },
      plugins: {
        legend: {
          display: false,
        },
        tooltip: {
          enabled: true,
        },
      },
      scales: {
        x: {
          display: false,
          grid: {
            display: false,
            drawBorder: false,
          },
        },
        y: {
          display: true,
          grid: {
            display: false,
            drawBorder: false,
          },
          ticks: {
            font: context => {
              const index = context.index
              const item = props.data[index]
              return {
                size: 16,
                weight: item?.emphasized ? '700' : '400',
                color: colors.ui.textBody,
              }
            },
          },
        },
      },
    }

    const config: ChartConfiguration<'bar'> = {
      type: 'bar',
      data: chartData,
      options,
    }

    if (chartRef.current) {
      chartRef.current.destroy()
    }

    chartRef.current = new ChartJS(canvasRef.current, config)

    return () => {
      if (chartRef.current) {
        chartRef.current.destroy()
      }
    }
  }, [props.data, props.title])

  return (
    <View
      display="block"
      padding="medium"
      borderRadius="medium"
      borderWidth="small"
      width={'100%'}
      height={'100%'}
    >
      <Heading level="h3" variant="titleCardRegular">
        {props.title}
      </Heading>
      <View display="block">
        <canvas ref={canvasRef} />
      </View>
    </View>
  )
}
