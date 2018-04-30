#
# Copyright (C) 2018 - present Instructure, Inc.
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

require_relative '../../spec_helper.rb'

describe 'Gradebook Export User-level Feature Flags' do
  describe 'use_semi_colon_field_separators_in_gradebook_exports' do
    before :each do
      teacher_in_course
    end

    context 'when the autodetect_field_separators_for_gradebook_exports feature is disabled' do
      before :each do
        @teacher.disable_feature!(:autodetect_field_separators_for_gradebook_exports)
        @feature = @teacher.lookup_feature_flag(:use_semi_colon_field_separators_in_gradebook_exports)
        @transitions = Feature.transitions(
          :use_semi_colon_field_separators_in_gradebook_exports,
          @teacher, @teacher, @feature.state
        )
      end

      it 'can be enabled' do
        expect(@transitions['on']['locked']).to be_falsey
      end

      it 'can be disabled' do
        expect(@transitions['off']['locked']).to be_falsey
      end
    end

    context 'when the autodetect_field_separators_for_gradebook_exports feature is enabled' do
      before :each do
        @teacher.enable_feature!(:autodetect_field_separators_for_gradebook_exports)
        @feature = @teacher.lookup_feature_flag(:use_semi_colon_field_separators_in_gradebook_exports)
        @transitions = Feature.transitions(
          :use_semi_colon_field_separators_in_gradebook_exports,
          @teacher, @teacher, @feature.state
        )
      end

      it 'is locked in the disabled state' do
        expect(@teacher.feature_enabled?(:use_semi_colon_field_separators_in_gradebook_exports)).to be_falsey
      end

      it 'cannot be enabled' do
        expect(@transitions['on']['locked']).to be_truthy
      end

      it 'can be disabled' do
        expect(@transitions['off']['locked']).to be_falsey
      end
    end
  end

  describe 'autodetect_field_separators_for_gradebook_exports' do
    before :each do
      teacher_in_course
    end

    context 'when the use_semi_colon_field_separators_in_gradebook_exports feature is disabled' do
      before :each do
        @teacher.disable_feature!(:use_semi_colon_field_separators_in_gradebook_exports)
        @feature = @teacher.lookup_feature_flag(:autodetect_field_separators_for_gradebook_exports)
        @transitions = Feature.transitions(
          :autodetect_field_separators_for_gradebook_exports,
          @teacher, @teacher, @feature.state
        )
      end

      it 'can be enabled' do
        expect(@transitions['on']['locked']).to be_falsey
      end

      it 'can be disabled' do
        expect(@transitions['off']['locked']).to be_falsey
      end
    end

    context 'when the use_semi_colon_field_separators_in_gradebook_exports feature is enabled' do
      before :each do
        @teacher.enable_feature!(:use_semi_colon_field_separators_in_gradebook_exports)
        @feature = @teacher.lookup_feature_flag(:autodetect_field_separators_for_gradebook_exports)
        @transitions = Feature.transitions(
          :autodetect_field_separators_for_gradebook_exports,
          @teacher, @teacher, @feature.state
        )
      end

      it 'is locked in the disabled state' do
        expect(@teacher.feature_enabled?(:autodetect_field_separators_for_gradebook_exports)).to be_falsey
      end

      it 'cannot be enabled' do
        expect(@transitions['on']['locked']).to be_truthy
      end

      it 'can be disabled' do
        expect(@transitions['off']['locked']).to be_falsey
      end
    end
  end
end
