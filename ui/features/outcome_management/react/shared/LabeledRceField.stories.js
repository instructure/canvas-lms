/*
 * Copyright (C) 2020 - present Instructure, Inc.
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

import {Button} from '@instructure/ui-buttons'
import React from 'react'
import {Form} from 'react-final-form'
import LabeledRceField from './LabeledRceField'
import {requiredValidator} from '@canvas/outcomes/react/validators/finalFormValidators'

export default {
  title: 'Examples/Outcomes/LabeledRceField',
  component: LabeledRceField,
}

const withForm = (children, opts = {}) => {
  return (
    <Form
      // eslint-disable-next-line no-console
      onSubmit={values => console.log(values)}
      initialValues={opts.initialValues}
      render={({handleSubmit}) => (
        <>
          {children}

          <Button color="primary" onClick={handleSubmit}>
            Submit
          </Button>
        </>
      )}
    />
  )
}

const Template = () => withForm(<LabeledRceField name="field" label="Normal Field" />)

export const withRequiredValidator = () =>
  withForm(
    <LabeledRceField name="field" label="With Required Validator" validate={requiredValidator} />
  )

export const withInitialValues = () =>
  withForm(<LabeledRceField name="field" label="With Initial Values" />, {
    initialValues: {
      field: '<p>initial html</p>',
    },
  })

export const Default = Template.bind({})
