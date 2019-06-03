require_relative '../rails_helper'

RSpec.describe ContextModuleProgression do
  include_context 'stubbed_network'

  before do
    student_in_course(:active_all => 1)

    @module = @course.context_modules.create!(:name => "some module")

    setup_modules
  end

  def setup_modules
    @assignment                     = @course.assignments.create!(:title => "some assignment")
    @tag                            = @module.add_item({:id => @assignment.id, :type => 'assignment'})
    @module.completion_requirements = {@tag.id => {:type => 'must_view'}}
    @module.publish
    @module.save!

    @mp = @user.context_module_progressions.create!(:context_module => @module)
    @mp.workflow_state = 'locked'
    @mp.save!
  end

  context '#prerequisites_satisfied?' do
    context 'when enrollment present' do
      context 'when sequence_control turned off' do
        it 'overrides calling instructures prereqs check' do
          allow(SettingsService).to receive(:get_enrollment_settings).and_return({"sequence_control"=>false})

          expect(ContextModuleProgression).to_not receive(:prerequisites_satisfied?)

          @mp.prerequisites_satisfied?
        end
      end

      context 'when sequence_control turned on' do
        it 'calls instructures prereqs check' do
          allow(SettingsService).to receive(:get_enrollment_settings).and_return({"sequence_control"=>true})

          expect(ContextModuleProgression).to receive(:prerequisites_satisfied?).and_call_original

          expect(@mp.prerequisites_satisfied?).to be true
        end
      end

      context 'when sequence_control not set (defaults to true)' do
        it 'calls instructures prereqs check' do
          allow(SettingsService).to receive(:get_enrollment_settings).and_return({})

          expect(ContextModuleProgression).to receive(:prerequisites_satisfied?)

          @mp.prerequisites_satisfied?
        end
      end
    end

    context 'when enrollment not present' do
      before do
        Enrollment.destroy_all
        allow(Enrollment).to receive(:where).with(anything).and_return([])
      end

      context 'there is no sequence_control setting' do
        it 'calls instructures prereqs check' do
          expect(SettingsService).to_not receive(:get_enrollment_settings)

          expect(ContextModuleProgression).to receive(:prerequisites_satisfied?)

          @mp.prerequisites_satisfied?
        end
      end
    end
  end
end
