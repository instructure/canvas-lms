require 'spec_helper'

describe Quizzes::QuizExtensionSerializer do

  let :context do
    Course.new.tap do |course|
      course.id = 1
      course.save!
    end
  end

  let(:user) { User.new }
  let(:session) { stub }
  let(:host_name) { 'example.com' }

  let :controller do
    options = {
      accepts_jsonapi: true,
      stringify_json_ids: false
    }

    ActiveModel::FakeController.new(options).tap do |controller|
      controller.stubs(:session).returns session
      controller.stubs(:context).returns context
    end
  end

  let :quiz_extension do
    qs = Quizzes::QuizSubmission.new
    qs.user_id = 123
    qs.quiz_id = 234
    qs.extra_attempts = 2
    qs.extra_time = 20
    qs.manually_unlocked = true
    qs.end_at = Time.now
    Quizzes::QuizExtension.new(qs, {})
  end

  let :serializer do
    Quizzes::QuizExtensionSerializer.new(quiz_extension,
      controller: controller,
      scope: user,
      session: session
    )
  end

  before do
    @json = serializer.as_json[:quiz_extension].stringify_keys
  end

  %w[
    user_id quiz_id user_id extra_attempts extra_time manually_unlocked end_at
  ].each do |attr|
    it "serializes #{attr}" do
      expect(@json).to have_key(attr)
    end
  end
end
