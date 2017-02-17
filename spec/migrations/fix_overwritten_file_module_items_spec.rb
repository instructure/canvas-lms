require_relative "../spec_helper"

describe DataFixup::FixOverwrittenFileModuleItems do
  it "sets could_be_locked on the replacement attachments" do
    course_factory
    att1 = attachment_with_context(@course, :display_name => "a")
    att2 = attachment_with_context(@course)
    att2.display_name = "a"
    att2.handle_duplicates(:overwrite)

    att1.reload
    expect(att1.file_state).to eq 'deleted'
    expect(att1.replacement_attachment_id).to eq att2.id
    att1.could_be_locked = true
    att1.save!

    DataFixup::FixOverwrittenFileModuleItems.run

    att2.reload
    expect(att2.could_be_locked).to eq true
  end
end
