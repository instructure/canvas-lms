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
import {Link} from '@instructure/ui-link'
import {View} from '@instructure/ui-view'
import {Flex} from '@instructure/ui-flex'
import {useEffect} from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'

// Declare google as a global variable
declare global {
  const google: any
}

const I18n = createI18nScope('accounts.statistics')

export default function OverTimeGraph({
  data,
  name,
  url,
}: {
  data: Array<[number, number]>
  name: string
  url: string
}) {
  function updateChartAriaLabels(label: string) {
    const chartContainerElements = document.querySelectorAll(
      '#over_time_AnnotationChart_chartContainer > div > div > div, #over_time_AnnotationChart_chartContainer svg, #over_time_AnnotationChart_rangeControlContainer > div > div > div, #over_time_AnnotationChart_rangeControlContainer svg',
    )
    chartContainerElements.forEach(element => {
      element.removeAttribute('aria-label')
    })

    const chart = document.querySelector(
      '#over_time_AnnotationChart_chartContainer > div > div > div > div',
    )
    if (chart) {
      chart.setAttribute('aria-label', label)
    }
  }

  useEffect(() => {
    if (data === undefined || data === null) return
    // google dependencies declared in views/acccounts/statistics since google.load uses document.write :(
    /* global google */
    const gData = new google.visualization.DataTable()
    gData.addColumn('date', I18n.t('Date'))
    gData.addColumn('number', name || I18n.t('Value'))
    gData.addColumn('string', 'title1')
    gData.addColumn('string', 'text1')

    const rows: Array<[Date, number, undefined, undefined]> = []
    data.forEach((point: [number, number]) => {
      const date = new Date()
      date.setTime(point[0])
      rows.push(
        // this ends up being [(a date), (the number of pageViews on that date), "an annotation tile, (if any)", ""]
        [date, point[1], undefined, undefined],
      )
    })
    gData.addRows(rows)

    const chart = new google.visualization.AnnotatedTimeLine(document.getElementById('over_time'))
    chart.draw(gData, {displayAnnotations: false})

    const checkInterval = setInterval(function () {
      const chart = document.querySelectorAll('#over_time_AnnotationChart_chartContainer')

      // Check if the chart has been drawn
      if (chart.length) {
        const label = I18n.t('Graph of %{data_point} Over Time', {data_point: name})
        updateChartAriaLabels(label)

        clearInterval(checkInterval)
      }
    }, 100)
    // only re-render when data is received; url and name are already set when data is fetched
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [data])

  return (
    <Flex
      margin="auto"
      textAlign="center"
      as="div"
      width="100%"
      height="100%"
      gap="modalElements"
      direction="column"
    >
      <View id="over_time" width="600px" height="240px" as="div"></View>
      <Flex.Item align="end" padding="space8">
        <Link href={`${url}.csv`}>{I18n.t('Download CSV')}</Link>
      </Flex.Item>
    </Flex>
  )
}
