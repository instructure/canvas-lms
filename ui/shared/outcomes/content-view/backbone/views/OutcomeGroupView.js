//
// Copyright (C) 2012 - present Instructure, Inc.
//
// This file is part of Canvas.
//
// Canvas is free software: you can redistribute it and/or modify it under
// the terms of the GNU Affero General Public License as published by the Free
// Software Foundation, version 3 of the License.
//
// Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
// A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
// details.
//
// You should have received a copy of the GNU Affero General Public License along
// with this program. If not, see <http://www.gnu.org/licenses/>.

import {extend} from 'lodash'
import OutcomeContentBase from './OutcomeContentBase'
import outcomeGroupTemplate from '../../jst/outcomeGroup.handlebars'
import outcomeGroupFormTemplate from '../../jst/outcomeGroupForm.handlebars'
import {createRoot} from 'react-dom/client'
import {createElement} from 'react'
import {Text} from '@instructure/ui-text'
import {TextInput} from '@instructure/ui-text-input'
import {View} from '@instructure/ui-view'
import {useScope as createI18nScope} from '@canvas/i18n'

const I18n = createI18nScope('OutcomeContentBase')

// For outcome groups
export default class OutcomeGroupView extends OutcomeContentBase {
  render() {
    const data = this.model.toJSON()
    switch (this.state) {
      case 'edit':
      case 'add':
        this.$el.html(outcomeGroupFormTemplate(data))
        this.readyForm()
        break
      case 'loading':
        this.$el.empty()
        break
      default: {
        // show
        const canManage = !this.readOnly() && this.model.get('can_edit')
        this.$el.html(outcomeGroupTemplate(extend(data, {canManage})))
      }
    }

    this.instUIInputs = {
      title: {
        root: (() => {
          const el = this.$('#outcome_group_title_container')[0]
          if (!el) return null
          return {rootElement: createRoot(el), initialValue: el.dataset.initialValue}
        })(),
        render: errorMessages => {
          this.instUIInputs.title.root?.rootElement.render(
            createElement(
              View,
              {as: 'div', margin: 'none none small none'},
              createElement(TextInput, {
                name: 'title',
                id: 'outcome_group_title',
                isRequired: true,
                defaultValue: this.instUIInputs.title.root?.initialValue,
                width: '30ch',
                placeholder: I18n.t('New Outcome Group'),
                renderLabel: () =>
                  createElement(
                    Text,
                    {weight: 'normal', size: 'small'},
                    I18n.t('title', 'Name this group'),
                  ),
                messages: errorMessages?.map(m => ({text: m.message, type: 'newError'})),
                'data-testid': 'outcome-group-title-input',
              }),
            ),
          )
        },
        inputElement: () => this.$('#outcome_group_title')[0],
      },
    }

    this.instUIInputs.title.render()

    this.$('input:first').focus()
    return this
  }

  showErrors(errors) {
    Object.keys(errors).forEach(key => {
      this.instUIInputs[key]?.render(errors[key])
    })

    for (const key in this.instUIInputs) {
      if (errors[key]) {
        this.instUIInputs[key]?.inputElement()?.focus()
        break
      }
    }
  }
}
