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

import React from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import {View} from '@instructure/ui-view'
import {Text} from '@instructure/ui-text'
import {Heading, HeadingProps} from '@instructure/ui-heading'
import {List} from '@instructure/ui-list'
import type {Diff as DiffType} from '../differ'

const I18n = createI18nScope('lti_registrations')

/**
 * See the `lti_registrations.scss` file for where some of these classes are defined.
 */

export const TwoColumnLayout: React.FC<{
  removalsColumn: React.ReactNode
  additionsColumn: React.ReactNode
}> = ({removalsColumn, additionsColumn}) => {
  return (
    <div className="diff-two-column-layout">
      <pre>{removalsColumn}</pre>
      <pre>{additionsColumn}</pre>
    </div>
  )
}

const RemovalNoChange = () => {
  return <del className="no-change">{I18n.t('None')}</del>
}

const AdditionNoChange = () => {
  return <ins className="no-change">{I18n.t('None')}</ins>
}

/**
 * Display a single value change (old → new)
 */
export const Diff = <T,>({
  label,
  diff,
  formatter = String,
  labelSize = 'h4',
}: {
  label: string
  diff: DiffType<T>
  formatter?: (value: NonNullable<T>) => string
  labelSize?: HeadingProps['level'] | 'text'
}): React.ReactElement | null => {
  if (diff === null) return null

  return (
    <View as="div" margin="small 0">
      {labelSize === 'text' ? (
        <View margin="0 0 x-small 0">
          <Text>{label}</Text>
        </View>
      ) : (
        <Heading level={labelSize} margin="0 0 x-small 0">
          {label}
        </Heading>
      )}
      <TwoColumnLayout
        removalsColumn={
          diff.oldValue ? (
            <del>
              <code>[-] {formatter(diff.oldValue)}</code>
            </del>
          ) : (
            <RemovalNoChange />
          )
        }
        additionsColumn={
          diff.newValue ? (
            <ins>
              <code>[+] {formatter(diff.newValue)}</code>
            </ins>
          ) : (
            <AdditionNoChange />
          )
        }
      />
    </View>
  )
}

/**
 * Display array changes (additions/removals)
 */
export const DiffList = <T extends NonNullable<unknown>>({
  label,
  labelSize = 'h4',
  additions = [],
  removals = [],
  formatter = String,
}: {
  label: string
  labelSize?: HeadingProps['level']
  additions?: T[]
  removals?: T[]
  formatter?: (item: NonNullable<T>) => string
}): React.ReactElement | null => {
  if (additions.length === 0 && removals.length === 0) {
    return null
  }

  return (
    <View as="div" margin="small 0">
      <Heading level={labelSize} margin="0 0 x-small 0">
        {label}
      </Heading>
      <div className="diff-two-column-layout">
        <pre>
          {removals.length > 0 ? (
            <List isUnstyled={true} margin="none" itemSpacing="none">
              {removals.map((item, idx) => (
                <List.Item key={idx} margin="none">
                  <del>
                    <code>[-] {formatter(item)}</code>
                  </del>
                </List.Item>
              ))}
            </List>
          ) : (
            <RemovalNoChange />
          )}
        </pre>
        <pre>
          {additions.length > 0 ? (
            <List itemSpacing="x-small" isUnstyled={true} margin="none">
              {additions.map((item, idx) => (
                <List.Item key={idx} margin="none">
                  <ins>
                    <code>[+] {formatter(item)}</code>
                  </ins>
                </List.Item>
              ))}
            </List>
          ) : (
            <AdditionNoChange />
          )}
        </pre>
      </div>
    </View>
  )
}

/**
 * Display record/object changes (additions/removals with key-value pairs)
 */
export const DiffRecord = ({
  label,
  additions = {},
  removals = {},
  keyFormatter = String,
  valueFormatter = String,
}: {
  label: string
  additions?: Record<string, string>
  removals?: Record<string, string>
  keyFormatter?: (key: string) => string
  valueFormatter?: (value: string) => string
}): React.ReactElement | null => {
  const removalEntries = Object.entries(removals)
  const additionEntries = Object.entries(additions)

  if (removalEntries.length === 0 && additionEntries.length === 0) {
    return null
  }

  return (
    <View as="div" margin="small 0">
      <Heading level="h4" margin="0 0 x-small 0">
        {label}
      </Heading>
      <TwoColumnLayout
        removalsColumn={
          removalEntries.length > 0 ? (
            <List itemSpacing="small" isUnstyled={true} margin="none">
              {removalEntries.map(([key, value], idx) => (
                <List.Item key={idx} margin="none">
                  <del>
                    <code>
                      [-] {keyFormatter(key)}: {valueFormatter(value)}
                    </code>
                  </del>
                </List.Item>
              ))}
            </List>
          ) : (
            <RemovalNoChange />
          )
        }
        additionsColumn={
          additionEntries.length > 0 ? (
            <List itemSpacing="small" isUnstyled={true} margin="none">
              {additionEntries.map(([key, value], idx) => (
                <List.Item key={idx} margin="none">
                  <ins>
                    <code>
                      [+] {keyFormatter(key)}: {valueFormatter(value)}
                    </code>
                  </ins>
                </List.Item>
              ))}
            </List>
          ) : (
            <AdditionNoChange />
          )
        }
      />
    </View>
  )
}
