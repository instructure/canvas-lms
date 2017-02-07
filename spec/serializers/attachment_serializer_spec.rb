require 'spec_helper'

describe AttachmentSerializer do
  let :context do
    Course.new.tap do |course|
      course.id = 1
      course.save!
    end
  end

  let :quiz do
    context.quizzes.build(title: 'banana split').tap do |quiz|
      quiz.id = 2
      quiz.save!
    end
  end

  let :attachment do
    stats = quiz.current_statistics_for('student_analysis')
    stats.generate_csv
    stats.reload
    stats.csv_attachment
  end

  let(:host_name) { 'example.com' }

  let :controller do
    options = {
      accepts_jsonapi: false,
      stringify_json_ids: false
    }

    ActiveModel::FakeController.new(options).tap do |controller|
      controller.stubs(:session).returns Object.new
      controller.stubs(:context).returns context
    end
  end

  subject do
    AttachmentSerializer.new(attachment, {
      controller: controller,
      scope: User.new
    })
  end

  let :json do
    @json ||= subject.as_json[:attachment].stringify_keys
  end

  it "includes the output of the legacy serializer" do
    expected_keys = %w[
      id content-type display_name filename url size created_at updated_at
      unlock_at locked hidden lock_at hidden_for_user thumbnail_url
    ]

    expect(json.keys.map(&:to_s) & expected_keys).to match_array expected_keys
  end
end
