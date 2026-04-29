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
import React, {useEffect, useRef, useState} from 'react'
import {Modal} from '@instructure/ui-modal'
import {Heading} from '@instructure/ui-heading'
import {Text} from '@instructure/ui-text'
import {Grid} from '@instructure/ui-grid'
import {Flex} from '@instructure/ui-flex'
import {View} from '@instructure/ui-view'
import {colors} from '@instructure/canvas-theme'
import {Button, CloseButton, IconButton} from '@instructure/ui-buttons'
import {IconQuestionLine} from '@instructure/ui-icons'

const I18n = createI18nScope('license_help')

const PREFERENCE_MAP: Record<string, string[]> = {
  private: [],
  cc_by: ['attribution'],
  cc_by_sa: ['attribution', 'share_alike'],
  cc_by_nc: ['attribution', 'non_commercial'],
  cc_by_nd: ['attribution', 'no_derivative_works'],
  cc_by_nc_sa: ['attribution', 'non_commercial', 'share_alike'],
  cc_by_nc_nd: ['attribution', 'non_commercial', 'no_derivative_works'],
}

type LicenseTypes =
  | 'private'
  | 'cc_by'
  | 'cc_by_nc'
  | 'cc_by_nd'
  | 'cc_by_sa'
  | 'cc_by_nc_sa'
  | 'cc_by_nc_nd'

export default function LicenseHelpIcon() {
  const licenseSelect = useRef<HTMLSelectElement | null>(null)
  const [preferences, setPreferences] = useState<string[]>([])
  const [isOpen, setIsOpen] = useState(false)

  const highlightedColor = colors.contrasts.green1212
  const borderColor = colors.contrasts.grey125125
  const viewTheme = {
    backgroundSecondary: highlightedColor,
    borderColorSecondary: borderColor,
    borderColorPrimary: borderColor,
  }

  useEffect(() => {
    licenseSelect.current = document.getElementById('course_license') as HTMLSelectElement
    if (licenseSelect.current) {
      setPreferences(PREFERENCE_MAP[licenseSelect.current.value || 'private'] || [])

      licenseSelect.current.addEventListener('change', function (this: HTMLSelectElement) {
        const selectedLicense = this.value || 'private'
        setPreferences(PREFERENCE_MAP[selectedLicense] || [])
      })
    }
  }, [])

  const calculateRecommendedLicense = (): LicenseTypes => {
    const prefLength = preferences.length
    if (prefLength === 0) {
      return 'private'
    } else if (prefLength === 1) {
      return 'cc_by'
    } else if (prefLength === 2) {
      if (preferences.includes('non_commercial')) {
        return 'cc_by_nc'
      } else if (preferences.includes('no_derivative_works')) {
        return 'cc_by_nd'
      } else {
        return 'cc_by_sa'
      }
    } else {
      if (preferences.includes('share_alike')) {
        return 'cc_by_nc_sa'
      } else {
        return 'cc_by_nc_nd'
      }
    }
  }

  const updatePreferences = (selectedPreference: string) => {
    let updatedPreferences: string[] = []
    if (preferences.includes(selectedPreference) && selectedPreference === 'attribution') {
      // if attribution is unselected, remove all preferences
      updatedPreferences = []
    } else if (preferences.includes(selectedPreference)) {
      // remove the preference if it already exists
      updatedPreferences = preferences.filter(pref => pref !== selectedPreference)
    } else if (
      preferences.includes('share_alike') &&
      selectedPreference === 'no_derivative_works'
    ) {
      // share_alike and no_derivative_works are mutually exclusive
      updatedPreferences = preferences.filter(pref => pref !== 'share_alike')
      updatedPreferences = [...updatedPreferences, selectedPreference]
    } else if (
      preferences.includes('no_derivative_works') &&
      selectedPreference === 'share_alike'
    ) {
      // share_alike and no_derivative_works are mutually exclusive
      updatedPreferences = preferences.filter(pref => pref !== 'no_derivative_works')
      updatedPreferences = [...updatedPreferences, selectedPreference]
    } else if (!preferences.includes('attribution') && selectedPreference !== 'attribution') {
      // if attribution is not selected, we need to add it
      updatedPreferences = ['attribution', ...preferences, selectedPreference]
    } else {
      // add the new preference
      updatedPreferences = [...preferences, selectedPreference]
    }
    setPreferences(updatedPreferences)
  }

  const renderRecommendedLicense = () => {
    const recommendedLicense = calculateRecommendedLicense()
    if (recommendedLicense === 'private') {
      return (
        <>
          <img src="/images/cc/copyright.png" alt="" />
          <Text>{I18n.t('Private (Copyrighted)')}</Text>
        </>
      )
    } else if (recommendedLicense === 'cc_by') {
      return (
        <>
          <img src="/images/cc/cc_by.png" alt="" />
          <Text>{I18n.t('CC Attribution')}</Text>
        </>
      )
    } else if (recommendedLicense === 'cc_by_nc') {
      return (
        <>
          <img src="/images/cc/cc_by_nc.png" alt="" />
          <Text>{I18n.t('CC Attribution Non-Commercial')}</Text>
        </>
      )
    } else if (recommendedLicense === 'cc_by_nd') {
      return (
        <>
          <img src="/images/cc/cc_by_nd.png" alt="" />
          <Text>{I18n.t('CC Attribution No Derivatives')}</Text>
        </>
      )
    } else if (recommendedLicense === 'cc_by_sa') {
      return (
        <>
          <img src="/images/cc/cc_by_sa.png" alt="" />
          <Text>{I18n.t('CC Attribution Share Alike')}</Text>
        </>
      )
    } else if (recommendedLicense === 'cc_by_nc_sa') {
      return (
        <>
          <img src="/images/cc/cc_by_nc_sa.png" alt="" />
          <Text>{I18n.t('CC Attribution Non-Commercial Share Alike')}</Text>
        </>
      )
    } else {
      return (
        <>
          <img src="/images/cc/cc_by_nc_nd.png" alt="" />
          <Text>{I18n.t('CC Attribution Non-Commercial No Derivatives')}</Text>
        </>
      )
    }
  }

  const renderPreference = (preference: string, readablePref: string) => {
    const isSelected = preferences.includes(preference)
    return (
      <View
        data-testid={`${isSelected ? 'selected_' : ''}${preference}`}
        padding="space8"
        borderRadius="medium"
        as="button"
        borderWidth="medium"
        onClick={() => updatePreferences(preference)}
        background={isSelected ? 'secondary' : 'primary'}
        themeOverride={viewTheme}
      >
        <Flex gap="space8">
          <img src={`/images/cc/${preference}.gif`} alt="" />
          <Text>{readablePref}</Text>
        </Flex>
      </View>
    )
  }

  return (
    <>
      <IconButton
        className="license_help_link"
        data-testid="license_help_link"
        color="primary"
        onClick={() => setIsOpen(true)}
        withBackground={false}
        withBorder={false}
        screenReaderLabel={I18n.t('Help with content licensing')}
      >
        <IconQuestionLine size="x-small" />
      </IconButton>
      <Modal
        label={I18n.t('Content Licensing Help')}
        open={isOpen}
        onDismiss={() => {
          setIsOpen(false)
        }}
        size="medium"
      >
        <Modal.Header>
          <Flex justifyItems="space-between">
            <Heading>{I18n.t('Content Licensing Help')}</Heading>
            <CloseButton
              onClick={() => {
                setIsOpen(false)
              }}
              screenReaderLabel={I18n.t('Close')}
            />
          </Flex>
        </Modal.Header>
        <Modal.Body>
          <Flex gap="modalElements" direction="column">
            <Text>
              {I18n.t(
                "Canvas can track the default license for content inside of your course. By default all content is considered copyrighted, but you can also release your content to the public domain or choose a Creative Commons license. Creative Commons provides a number of different licenses, which can be confusing. However, the licenses are all based on four conditions, so we can help you choose a license. Select which of the conditions you want to apply and we'll show you the correct license for those conditions.",
              )}
            </Text>
            <Grid>
              <Grid.Row>
                <Grid.Col>
                  <Flex direction="column" gap="space4">
                    {renderPreference('attribution', I18n.t('Attribution'))}
                    <Text>
                      {I18n.t(
                        'You let others copy, distribute, display, and perform your copyrighted work -- and derivative works based upon it -- but only if they give credit the way you request.',
                      )}
                    </Text>
                  </Flex>
                </Grid.Col>
                <Grid.Col>
                  <Flex direction="column" gap="space4">
                    {renderPreference('share_alike', I18n.t('Share Alike'))}
                    <Text>
                      {I18n.t(
                        'You allow others to distribute derivative works only under a license identical to the license that governs your work.',
                      )}
                    </Text>
                  </Flex>
                </Grid.Col>
              </Grid.Row>
              <Grid.Row>
                <Grid.Col>
                  <Flex direction="column" gap="space4">
                    {renderPreference('non_commercial', I18n.t('Non-Commercial'))}
                    <Text>
                      {I18n.t(
                        'You let others copy, distribute, display, and perform your work -- and derivative works based upon it -- but for non-commercial purposes only.',
                      )}
                    </Text>
                  </Flex>
                </Grid.Col>
                <Grid.Col>
                  <Flex direction="column" gap="space4">
                    {renderPreference('no_derivative_works', I18n.t('No Derivatives'))}
                    <Text>
                      {I18n.t(
                        'You let others copy, distribute, display, and perform only verbatim copies of your work, not derivative works based upon it.',
                      )}
                    </Text>
                  </Flex>
                </Grid.Col>
              </Grid.Row>
            </Grid>
            <Flex.Item textAlign="center" align="center">
              <Flex gap="space8" padding="space8">
                <Button
                  data-testid="use_this_license"
                  onClick={() => {
                    if (licenseSelect.current) {
                      licenseSelect.current.value = calculateRecommendedLicense()
                      setIsOpen(false)
                    }
                  }}
                >
                  {I18n.t('Use This License')}
                </Button>
                <Flex gap="space4">{renderRecommendedLicense()}</Flex>
              </Flex>
            </Flex.Item>
          </Flex>
        </Modal.Body>
      </Modal>
    </>
  )
}
