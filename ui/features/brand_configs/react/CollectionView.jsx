/*
 * Copyright (C) 2016 - present Instructure, Inc.
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

import {useScope as useI18nScope} from '@canvas/i18n'
import React, {useState} from 'react'
import {find, flatten, groupBy, map, sortBy} from 'lodash'
import {arrayOf, func, shape, string} from 'prop-types'
import customTypes from '@canvas/theme-editor/react/PropTypes'
import {submitHtmlForm} from '@canvas/theme-editor/submitHtmlForm'
import ThemeCard from './ThemeCard'
import doFetchApi from '@canvas/do-fetch-api-effect'
import {Button} from '@instructure/ui-buttons'
import {Grid} from '@instructure/ui-grid'
import {Link} from '@instructure/ui-link'
import {Menu} from '@instructure/ui-menu'
import {IconAddSolid, IconQuestionLine} from '@instructure/ui-icons'
import {Popover} from '@instructure/ui-popover'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {View} from '@instructure/ui-view'

const I18n = useI18nScope('theme_collection_view')

function NewTheme({onNewTheme, bases}) {
  return (
    <Menu
      trigger={
        <Button renderIcon={IconAddSolid} color="primary" data-testid="new-theme-button">
          {I18n.t('Theme')}
        </Button>
      }
    >
      <Menu.Group label={I18n.t('Create theme based on') + ' \u22EF'} onSelect={onNewTheme}>
        {bases.map(base => (
          <Menu.Item key={base.md5} value={base.md5} data-testid="new-theme-menu-item">
            {base.label}
          </Menu.Item>
        ))}
      </Menu.Group>
    </Menu>
  )
}

NewTheme.propTypes = {
  onNewTheme: func.isRequired,
  bases: arrayOf(
    shape({
      md5: string.isRequired,
      label: string.isRequired,
    })
  ),
}

const blankConfig = {
  name: I18n.t('Default Template'),
  brand_config: {
    md5: '',
    variables: {},
  },
}

const isSystemTheme = sharedBrandConfig => !sharedBrandConfig.account_id

export default function CollectionView(props) {
  const {
    sharedBrandConfigs,
    activeBrandConfig,
    accountID,
    brandableVariableDefaults,
    baseBrandableVariables,
  } = props
  const [brandConfigBeingDeleted, setBrandConfigBeingDeleted] = useState(null)

  function brandVariableValue(config, name) {
    const explicitValue = config?.variables[name]
    if (explicitValue) return explicitValue

    const variableInfo = brandableVariableDefaults[name]
    const _default = variableInfo?.default
    if (_default && _default[0] === '$') {
      return brandVariableValue(config, _default.substring(1))
    }
    return baseBrandableVariables[name]
  }

  function startEditing({md5ToActivate, sharedBrandConfigToStartEditing}) {
    if (md5ToActivate === activeBrandConfig?.md5) md5ToActivate = undefined
    if (sharedBrandConfigToStartEditing) {
      sessionStorage.setItem(
        'sharedBrandConfigBeingEdited',
        JSON.stringify(sharedBrandConfigToStartEditing)
      )
    } else {
      sessionStorage.removeItem('sharedBrandConfigBeingEdited')
    }
    submitHtmlForm(
      `/accounts/${accountID}/brand_configs/save_to_user_session`,
      'POST',
      md5ToActivate
    )
  }

  async function deleteSharedBrandConfig(id) {
    await doFetchApi({
      path: `/api/v1/shared_brand_configs/${id}`,
      method: 'DELETE',
    })
    window.location.reload()
  }

  function isActiveBrandConfig(config) {
    if (activeBrandConfig) {
      return config.md5 === activeBrandConfig.md5
    } else {
      return config === blankConfig.brand_config
    }
  }

  function isActiveEditableTheme(config) {
    return !isSystemTheme(config) && activeBrandConfig?.md5 === config.brand_config.md5
  }

  function multipleThemesReflectActiveOne() {
    return sharedBrandConfigs.filter(isActiveEditableTheme).length > 1
  }

  function isDeletable(config) {
    // Globally-shared themes and the active theme (if there is only one
    // active) are not deletable.
    return (
      !isSystemTheme(config) &&
      (!isActiveBrandConfig(config.brand_config) || multipleThemesReflectActiveOne())
    )
  }

  function thingsToShow() {
    const showableCards = [blankConfig].concat(sharedBrandConfigs)
    const isActive = config => isActiveBrandConfig(config.brand_config)

    // Add in a tile for the active theme if it is otherwise not present in the shared ones
    if (activeBrandConfig && !find(sharedBrandConfigs, isActive)) {
      const cardForActiveBrandConfig = {
        brand_config: activeBrandConfig,
        name: activeBrandConfig.name,
        account_id: accountID,
      }
      showableCards.unshift(cardForActiveBrandConfig)
    }

    // Make sure the active theme shows up first
    const sortedCards = sortBy(showableCards, card => !isActive(card))

    // Split the globally shared themes and the ones that people in this account
    // have shared apart
    return groupBy(sortedCards, sbc =>
      isSystemTheme(sbc) ? 'globalThemes' : 'accountSpecificThemes'
    )
  }

  function renderCard(config) {
    function onClick() {
      const isReadOnly = isSystemTheme(config)
      startEditing({
        md5ToActivate: config.brand_config.md5,
        sharedBrandConfigToStartEditing: !isReadOnly && config,
      })
    }

    // Even if this theme's md5 is active, don't mark it as active if it is a
    // system theme and there is an account-shared theme that also matches the
    // active md5
    const active =
      isActiveBrandConfig(config.brand_config) &&
      (!isSystemTheme(config) || !sharedBrandConfigs.some(isActiveEditableTheme))

    return (
      <ThemeCard
        key={config.id + config.brand_config.md5}
        name={config.name}
        isActiveBrandConfig={active}
        showMultipleCurrentThemesMessage={active && multipleThemesReflectActiveOne()}
        getVariable={v => brandVariableValue(config.brand_config, v)}
        open={onClick}
        isDeletable={isDeletable(config)}
        isBeingDeleted={brandConfigBeingDeleted === config}
        startDeleting={() => setBrandConfigBeingDeleted(config)}
        cancelDeleting={() => setBrandConfigBeingDeleted(null)}
        onDelete={e => {
          e.preventDefault()
          deleteSharedBrandConfig(config.id)
        }}
      />
    )
  }

  function onNewTheme(_e, value) {
    let md5 = value
    // massage the callback value from InstUI Menu component (see INSTUI-2429)
    if (md5 instanceof Array) md5 = md5[0]
    if (md5 === 0) md5 = ''
    startEditing({md5ToActivate: md5})
  }

  const cards = thingsToShow()
  const bases = flatten(
    map(['globalThemes', 'accountSpecificThemes'], coll =>
      map(cards[coll], config => ({md5: config.brand_config.md5, label: config.name}))
    )
  )
  const explainerText = I18n.t(
    'Default templates are used as starting points for new themes and cannot be deleted.'
  )

  return (
    <>
      <Grid>
        <Grid.Row vAlign="middle" colSpacing="none">
          <Grid.Col>
            <h1>{I18n.t('Themes')}</h1>
          </Grid.Col>
          <Grid.Col width="auto">
            <NewTheme onNewTheme={onNewTheme} bases={bases} />
          </Grid.Col>
        </Grid.Row>
      </Grid>

      {cards.globalThemes && (
        <div className="ic-ThemeCard-container" data-testid="container-templates-section">
          <h2 className="ic-ThemeCard-container__Heading">
            <span className="ic-ThemeCard-container__Heading-text">
              {I18n.t('Templates')}
              <Popover
                renderTrigger={
                  <Link size="small" renderIcon={IconQuestionLine}>
                    <ScreenReaderContent>{explainerText}</ScreenReaderContent>
                  </Link>
                }
                placement="top center"
              >
                <View display="block" padding="small" maxWidth="15rem">
                  {explainerText}
                </View>
              </Popover>
            </span>
          </h2>

          <div className="ic-ThemeCard-container__Main">{cards.globalThemes.map(renderCard)}</div>
        </div>
      )}

      {cards.accountSpecificThemes && (
        <div className="ic-ThemeCard-container" data-testid="container-mythemes-section">
          <h2 className="ic-ThemeCard-container__Heading">
            <span className="ic-ThemeCard-container__Heading-text">{I18n.t('My Themes')}</span>
          </h2>
          <div className="ic-ThemeCard-container__Main">
            {cards.accountSpecificThemes.map(renderCard)}
          </div>
        </div>
      )}
    </>
  )
}

CollectionView.propTypes = {
  sharedBrandConfigs: arrayOf(customTypes.sharedBrandConfig).isRequired,
  activeBrandConfig: customTypes.brandConfig.isRequired,
  accountID: string.isRequired,
  brandableVariableDefaults: customTypes.brandableVariableDefaults,
  baseBrandableVariables: customTypes.variables,
}
