#
# Copyright (C) 2014 Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.
#

require 'spec_helper'

describe LtiOutbound::VariableSubstitutor do
  class TestLtiModel < LtiOutbound::LTIModel
    attr_accessor :field, :new_field
    add_variable_mapping '$Custom.mapper', :field
    add_variable_mapping '$Custom.newField', :new_field
  end

  let(:lti_model) do
    TestLtiModel.new.tap do |model|
      model.field = 'blah'
    end
  end

  describe '#substitute!' do
    it 'substitutes variable' do
      params = {'field' => '$Custom.mapper'}
      subject.substitute!(params, lti_model)
      expect(params).to eq({'field' => 'blah'})
    end

    it 'does not replace invalid mappings' do
      params = {'field' => '$Custom.mapper.wrong'}
      subject.substitute!(params, lti_model)
      expect(params).to eq({'field' => '$Custom.mapper.wrong'})
    end

    it 'does not replace nil mappings' do
      lti_model.field = nil
      params = {'field' => '$Custom.mapper'}
      subject.substitute!(params, lti_model)
      expect(params).to eq({'field' => '$Custom.mapper'})
    end
  end

  describe '#substitute_all!' do
    it 'substitutes any number of LTIModels' do
      model1 = lti_model
      model2 = TestLtiModel.new.tap do |model|
        model.new_field = 'new stuff'
      end

      params =  {'field' => '$Custom.mapper', 'new_field' => '$Custom.newField' }
      subject.substitute_all!(params, model1, model2)

      expect(params).to eq({'field' => 'blah', 'new_field' => 'new stuff' })
    end

    it 'substitutes variable mappings for objects in order' do
      model1 = lti_model
      model2 = TestLtiModel.new.tap do |model|
        model.field = 'blahblah'
        model.new_field = 'new stuff'
      end

      params =  {'field' => '$Custom.mapper', 'new_field' => '$Custom.newField' }
      subject.substitute_all!(params, model1, model2)

      expect(params).to eq({'field' => 'blah', 'new_field' => 'new stuff' })
    end

    it 'can handle nil objects' do
      model1 = lti_model
      model2 = nil

      params =  {'field' => '$Custom.mapper', 'new_field' => '$Custom.newField' }
      subject.substitute_all!(params, model1, model2)

      expect(params).to eq({'field' => 'blah', 'new_field' => '$Custom.newField' })
    end
  end
end