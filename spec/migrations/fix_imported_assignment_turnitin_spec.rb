require_relative '../spec_helper'

describe DataFixup::FixImportedAssignmentTurnitin do
  it 'should fix turnitin_settings for imported assignments (that have no submissions)' do
    a1 = assignment_model
    a2 = assignment_model
    u = user(:active_all => true)
    a2.context.enroll_student(u)
    a3 = assignment_model

    a1.migration_id = "burp"
    a1.save!

    a2.migration_id = "durp"
    a2.save!
    a2.submit_homework(u, :submission_type => "online_text_entry")

    [a1, a2, a3].each do |a|
      a.turnitin_enabled = true
      s = a.turnitin_settings
      s[:created] = true
      a.turnitin_settings = s
      a.save!
    end

    DataFixup::FixImportedAssignmentTurnitin.run

    [a1, a2, a3].each(&:reload)
    expect(a1.turnitin_settings[:created]).to be_falsey
    expect(a2.turnitin_settings[:created]).to be_truthy # has a submission
    expect(a3.turnitin_settings[:created]).to be_truthy # has no migration_id
  end
end
