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
          expect(predicate).to be_truthy
        end

        it 'affirms when the public_description key is a symbol' do
          includes << :public_description
          expect(predicate).to be_truthy
        end

        it 'negates when the public_description key is missing' do
          expect(predicate).to be_falsey
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
            expect(predicate).to be_falsey
          end

          it 'is true if the course allows the grade to be seen' do
            course_settings[:hide_final_grades?] = false
            expect(predicate).to be_truthy
          end
        end

        describe 'when total scores key is not set' do
          before { includes.clear }

          it 'is false if the final grade is hidden' do
            course_settings[:hide_final_grades?] = true
            expect(predicate).to be_falsey
          end

          it 'is false even even if the final grade is NOT hidden' do
            course_settings[:hide_final_grades?] = false
            expect(predicate).to be_falsey
          end
        end
      end


      describe '#allowed_attributes' do
        it 'just returns the base attributes when there are no includes' do
          includes.clear
          expect(course_json.allowed_attributes).to eq CourseJson::BASE_ATTRIBUTES
        end

        it 'tacks on any includes' do
          includes << :some << :other << :keys
          expect(course_json.allowed_attributes).to eq( CourseJson::BASE_ATTRIBUTES + [:some, :other, :keys] )
        end
      end


      describe '#methods_to_send' do
        it 'includes the end_at field' do
          expect(course_json.methods_to_send).to include('end_at')
        end

        it 'includes the public_syllabus field' do
          expect(course_json.methods_to_send).to include('public_syllabus')
        end

        it 'includes the storage_quota_mb field' do
          expect(course_json.methods_to_send).to include('storage_quota_mb')
        end

        it 'includes the hide_final_grades method if its in the includes array' do
          includes << :hide_final_grades
          expect(course_json.methods_to_send).to include('hide_final_grades')
        end
      end


      describe '#clear_unneeded_fields' do
        let(:hash){ Hash.new }

        describe 'with an optional field' do
          before { hash['enrollments'] = [] }

          it 'kicks the key-value pair out if the value is nil' do
            hash['enrollments'] = nil
            expect(course_json.clear_unneeded_fields(hash)).to eq({ })
          end

          it 'keeps the key-value pair if the value is not nil' do
            expect(course_json.clear_unneeded_fields(hash)).to eq({'enrollments' => [] })
          end
        end

        describe 'with any other field' do
          before { hash['some_other_key'] = 'some_value' }

          it 'keeps the key-value pair even if the value is nil' do
            hash['some_other_key'] = nil
            expect(course_json.clear_unneeded_fields(hash)).to eq({ 'some_other_key' => nil })
          end

          it 'keeps the key-value pair if the value is not nil' do
            expect(course_json.clear_unneeded_fields(hash)).to eq({'some_other_key' => 'some_value' })
          end
        end

      end

      describe '#description' do
        let(:course) { stub(:public_description => 'an eloquent anecdote' ) }

        it 'returns the description when its configured for inclusion' do
          includes << :public_description
          expect(course_json.include_description).to be_truthy
          expect(course_json.description(course)).to eq 'an eloquent anecdote'
        end

        it 'is nil when configured not to be included' do
          includes.clear
          expect(course_json.description(course)).to be_nil
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

        describe '#course' do
          subject { super().course }
          it { is_expected.to eq course }
        end

        describe '#user' do
          subject { super().user }
          it { is_expected.to eq user }
        end

        describe '#includes' do
          subject { super().includes }
          it { is_expected.to eq [:these, :three, :keys] }
        end

        describe '#enrollments' do
          subject { super().enrollments }
          it { is_expected.to eq enrollments }
        end

        describe '#hash' do
          subject { super().hash }
          it { is_expected.to eq hash }
        end
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
            expect(hash['sis_course_id']).to eq 1357
          end

          describe 'with a nil sis_id' do
            before do
              @sis_id = nil
              course_json.set_sis_course_id( hash, sis_course, user )
            end

            it 'allows the nil value to go into the has' do
              expect(hash['sis_course_id']).to eq nil
            end

            it 'does not get cleared out before translation to json' do
              expect(course_json.clear_unneeded_fields( hash )).to eq({ 'sis_course_id' => nil })
            end
          end
        end

        it 'doesnt add the sis_course_id key at all if the rights are NOT present' do
          course_json.set_sis_course_id( hash, sis_course, user)
          expect(hash).to eq({})
        end
      end

      describe '#permissions' do
        let(:course) { stub(:public_description => 'an eloquent anecdote' ) }

        it 'returns the permissions when its configured for inclusion' do
          includes << :permissions
          expect(course_json.include_permissions).to be_truthy
          expect(course_json.permissions_to_include).to eq [ :create_discussion_topic, :create_announcement ]
        end

        it 'is nil when configured not to be included' do
          includes.clear
          expect(course_json.permissions_to_include).to be_nil
        end
      end
    end
  end
end
