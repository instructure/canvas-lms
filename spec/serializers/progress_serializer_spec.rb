require 'spec_helper'

describe ProgressSerializer do
  let(:context) { Account.default }

  let :progress do
    p = context.progresses.build
    p.id = 1
    p.completion = 10
    p.workflow_state = 'running'
    p.save
    p
  end

  let(:host_name) { 'example.com' }

  let :controller do
    options = {
      accepts_jsonapi: true,
      stringify_json_ids: true
    }

    ActiveModel::FakeController.new(options).tap do |controller|
      controller.stubs(:session).returns Object.new
      controller.stubs(:context).returns Object.new
    end
  end

  subject do
    ProgressSerializer.new(progress, {
      controller: controller,
      scope: User.new
    })
  end

  let :json do
    @json ||= subject.as_json[:progress].stringify_keys
  end

  [
    :context_type, :user_id, :tag, :completion, :workflow_state, :created_at,
    :updated_at, :message
  ].map(&:to_s).each do |key|
    it "serializes #{key}" do
      expect(json[key]).to eq progress.send(key)
    end
  end

  it 'serializes id' do
    expect(json['id']).to eq "1"
  end

  it 'serializes url' do
    expect(json['url']).to eq 'http://example.com/api/v1/progress/1'
  end
end
