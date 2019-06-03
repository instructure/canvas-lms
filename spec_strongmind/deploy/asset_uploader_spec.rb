require_relative '../rails_helper'

# Interface for Canvas::Cdn::S3Uploader
# module Canvas
#   module Cdn
#     def self.config
#     end

#     class S3Uploader
#       def upload!
#       end
#     end
#   end
# end

RSpec.describe CanvasShimAssetUploader, skip: 'This is invalid, should be deleted.  Rewritten in tasks/asset_uploader_spec.rb' do
  let(:instance) { Canvas::Cdn::S3Uploader.new }
  before do
    allow(Canvas::Cdn::S3Uploader).to receive(:new).and_return( instance )
  end

  subject do
    described_class.new
  end

  it 'calls the canvas upload method' do
    expect(instance).to receive(:upload!)
    subject.upload!
  end
end
