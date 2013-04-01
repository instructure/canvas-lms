require File.expand_path(File.dirname(__FILE__) + '/../common')

shared_examples_for "calendar2 selenium tests" do
  it_should_behave_like "in-process server selenium tests"

  before (:each) do
    Account.default.tap do |a|
      a.settings[:enable_scheduler] = true
      a.settings[:show_scheduler] = true
      a.save!
    end
  end

  def create_appointment_group(params={})
    tomorrow = Date.today.to_s
    default_params = {
        :title => "new appointment group",
        :contexts => [@course],
        :new_appointments => [
            [tomorrow + ' 12:00:00', tomorrow + ' 13:00:00'],
        ]
    }
    ag = AppointmentGroup.create!(default_params.merge(params))
    ag.publish!
    ag.title
  end

  def create_appointment_group_early(params={})
    tomorrow = Date.today.to_s
    default_params = {
        :title => "new appointment group",
        :contexts => [@course],
        :new_appointments => [
            [tomorrow + ' 7:00', tomorrow + ' 11:00:00'],
        ]
    }
    ag = AppointmentGroup.create!(default_params.merge(params))
    ag.publish!
    ag.title
  end

  def open_edit_event_dialog
    f('.fc-event').click
    keep_trying_until { f('.edit_event_link').should be_displayed }
    driver.execute_script("$('.edit_event_link').trigger('click')")
    wait_for_ajaximations
  end
end
