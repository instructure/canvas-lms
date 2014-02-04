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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')

describe PolymorphicTypeOverride do

  describe '.override_polymorphic_types' do
    it 'overrides a single old polymorphic type with a new one' do
      class ContentTag
        include PolymorphicTypeOverride
        override_polymorphic_types [type: 'content_type', from: 'OldClassInDatabase', to: 'Quizzes::Quiz']
      end

      fizz_buzz = ContentTag.create! content: quiz_model, context: course_model
      fizz_buzz.content_type.should == 'Quizzes::Quiz'

      fizz_buzz.content_type = 'OldClassInDatabase'
      fizz_buzz.send(:save_without_callbacks)

      updated_fizz_buzz = ContentTag.first
      updated_fizz_buzz.content_type.should == 'Quizzes::Quiz'
      updated_fizz_buzz.content_id.should_not == 'Quizzes::Quiz'
    end

    it 'overrides multiple old polymorphic types with a new one' do
      class ContentTag
        extend PolymorphicTypeOverride
        override_polymorphic_types [{type: 'content_type', from: 'OldClassInDatabase', to: 'Quizzes::Quiz'},
                                    {type: 'context_type', from: 'AnotherOldClassInDatabase', to: 'Quizzes::Quiz'}]
      end

      fizz_buzz = ContentTag.create! content: quiz_model, context: quiz_model
      fizz_buzz.content_type.should == 'Quizzes::Quiz'
      fizz_buzz.context_type.should == 'Quizzes::Quiz'

      fizz_buzz.content_type = 'OldClassInDatabase'
      fizz_buzz.context_type = 'AnotherOldClassInDatabase'
      fizz_buzz.send(:save_without_callbacks)

      updated_fizz_buzz = ContentTag.first

      updated_fizz_buzz.content_type.should == 'Quizzes::Quiz'
      updated_fizz_buzz.content_id.should_not == 'Quizzes::Quiz'

      updated_fizz_buzz.context_type.should == 'Quizzes::Quiz'
      updated_fizz_buzz.context_id.should_not == 'Quizzes::Quiz'
    end
  end
end
