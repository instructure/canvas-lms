module Api
  module V1

    require File.expand_path(File.dirname(__FILE__) + '../../../../lib/api/v1/course_json')

    describe Api::V1::CourseJson do
      let(:includes) { [] }
      let(:course) { stub(:course) }
      let(:user) { stub(:user) }
      let(:course_json) { CourseJson.new( course, nil, includes, [] ) }

      describe '#include_description' do
        let(:predicate){ course_json.include_description }

        it 'affirms when the public_description key is in the includes array' do
          includes << 'public_description'
          predicate.should be_true
        end

        it 'affirms when the public_description key is a symbol' do
          includes << :public_description
          predicate.should be_true
        end

        it 'negates when the public_description key is missing' do
          predicate.should be_false
        end
      end


      describe '#include_total_scores' do
        let(:predicate) { course_json.include_total_scores }
        let(:course_settings) { Hash.new }
        let(:course) { stub( course_settings ) }

        describe 'when total scores key is set' do
          before { includes << :total_scores }

          it 'is false if the final grade is hidden' do
            course_settings[:hide_final_grades?] = true
            predicate.should be_false
          end

          it 'is true if the course allows the grade to be seen' do
            course_settings[:hide_final_grades?] = false
            predicate.should be_true
          end
        end

        describe 'when total scores key is not set' do
          before { includes.clear }

          it 'is false if the final grade is hidden' do
            course_settings[:hide_final_grades?] = true
            predicate.should be_false
          end

          it 'is false even even if the final grade is NOT hidden' do
            course_settings[:hide_final_grades?] = false
            predicate.should be_false
          end
        end
      end


      describe '#allowed_attributes' do
        it 'just returns the base attributes when there are no includes' do
          includes.clear
          course_json.allowed_attributes.should == CourseJson::BASE_ATTRIBUTES
        end

        it 'tacks on any includes' do
          includes << :some << :other << :keys
          course_json.allowed_attributes.should == ( CourseJson::BASE_ATTRIBUTES + [:some, :other, :keys] )
        end
      end


      describe '#methods_to_send' do
        it 'includes the end_at field' do
          course_json.methods_to_send.should include('end_at')
        end

        it 'includes the public_syllabus field' do
          course_json.methods_to_send.should include('public_syllabus')
        end

        it 'includes the storage_quota_mb field' do
          course_json.methods_to_send.should include('storage_quota_mb')
        end

        it 'includes the hide_final_grades method if its in the includes array' do
          includes << :hide_final_grades
          course_json.methods_to_send.should include('hide_final_grades')
        end
      end


      describe '#clear_unneeded_fields' do
        let(:hash){ Hash.new }

        describe 'with an optional field' do
          before { hash['enrollments'] = [] }

          it 'kicks the key-value pair out if the value is nil' do
            hash['enrollments'] = nil
            course_json.clear_unneeded_fields(hash).should == { }
          end

          it 'keeps the key-value pair if the value is not nil' do
            course_json.clear_unneeded_fields(hash).should == {'enrollments' => [] }
          end
        end

        describe 'with any other field' do
          before { hash['some_other_key'] = 'some_value' }

          it 'keeps the key-value pair even if the value is nil' do
            hash['some_other_key'] = nil
            course_json.clear_unneeded_fields(hash).should == { 'some_other_key' => nil }
          end

          it 'keeps the key-value pair if the value is not nil' do
            course_json.clear_unneeded_fields(hash).should == {'some_other_key' => 'some_value' }
          end
        end

      end

      describe '#description' do
        let(:course) { stub(:public_description => 'an eloquent anecdote' ) }

        it 'returns the description when its configured for inclusion' do
          includes << :public_description
          course_json.include_description.should be_true
          course_json.description(course).should == 'an eloquent anecdote'
        end

        it 'is nil when configured not to be included' do
          includes.clear
          course_json.description(course).should be_nil
        end
      end

      describe '#initialization' do
        let(:enrollments) { stub(:enrollments) }
        let(:hash) { {:a => '1', :b => '2'} }
        let(:includes) { ['these', 'three', 'keys' ] }

        before(:each) do
          @json = CourseJson.new(course, user, includes, enrollments){ hash }
        end

        subject{ @json }

        its(:course) { should == course }
        its(:user) { should == user }
        its(:includes) { should == [:these, :three, :keys] }
        its(:enrollments) { should == enrollments }
        its(:hash) { should == hash }
      end

      describe '#set_sis_course_id' do
        let(:sis_course) { stub(:root_account => stub( :grants_any_right? => @has_right ), :sis_source_id => @sis_id ) }
        let(:hash) { Hash.new }

        before do
          @sis_id = 1357
          @has_right = false
        end

        describe 'when appropriate rights are granted' do
          before { @has_right = true }

          it 'adds sis the key-value pair to the hash' do
            course_json.set_sis_course_id( hash, sis_course, user )
            hash['sis_course_id'].should == 1357
          end

          describe 'with a nil sis_id' do
            before do
              @sis_id = nil
              course_json.set_sis_course_id( hash, sis_course, user )
            end

            it 'allows the nil value to go into the has' do
              hash['sis_course_id'].should == nil
            end

            it 'does not get cleared out before translation to json' do
              course_json.clear_unneeded_fields( hash ).should == { 'sis_course_id' => nil }
            end
          end
        end

        it 'doesnt add the sis_course_id key at all if the rights are NOT present' do
          course_json.set_sis_course_id( hash, sis_course, user)
          hash.should == {}
        end
      end

      describe '#permissions' do
        let(:course) { stub(:public_description => 'an eloquent anecdote' ) }

        it 'returns the permissions when its configured for inclusion' do
          includes << :permissions
          course_json.include_permissions.should be_true
          course_json.permissions_to_include.should == [ :create_discussion_topic ]
        end

        it 'is nil when configured not to be included' do
          includes.clear
          course_json.permissions_to_include.should be_nil
        end
      end
    end
  end
end
