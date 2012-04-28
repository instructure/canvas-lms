shared_examples_for "calendar2 selenium tests" do
  it_should_behave_like "in-process server selenium tests"

  before (:each) do
    Account.default.tap { |a| a.settings[:enable_scheduler] = true; a.save }
  end

  def create_appointment_group(params={})
    tomorrow = (Date.today + 1).to_s
    default_params = {
        :title => "new appointment group",
        :context => @course,
        :new_appointments => [
            [tomorrow + ' 12:00:00', tomorrow + ' 13:00:00'],
        ]
    }
    ag = @course.appointment_groups.create!(default_params.merge(params))
    ag.publish!
    ag.title
  end

  def open_edit_event_dialog
    f('.fc-event').click
    f('.edit_event_link').click
  end
end
