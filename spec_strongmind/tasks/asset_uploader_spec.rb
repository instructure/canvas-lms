require_relative '../rails_helper'

RSpec.describe 'rake strongmind:upload_assets', type: :task do
  it 'instantiates a CanvasShimAssetUploader' do
    uploader = double(CanvasShimAssetUploader, upload!: true)

    expect(CanvasShimAssetUploader).to receive(:new).and_return(uploader)

    task.execute
  end

  it 'calls the CanvasShimAssetUploader upload! method' do
    uploader = double(CanvasShimAssetUploader, upload!: true)
    expect(uploader).to receive(:upload!)

    expect(CanvasShimAssetUploader).to receive(:new).and_return(uploader)

    task.execute
  end
end
