require File.expand_path('../../../spec_helper', __FILE__)

module CC
  describe Schema do
    describe ".for_version" do
      it 'will not tolerate names of files not in the folder at all' do
        filename = Schema.for_version("../../../spec/fixtures/test")
        expect(filename).to be_falsey
      end

      it 'returns the full filepath for valid file names' do
        expect(Schema.for_version('cccv1p0').to_s).to match /lib\/cc\/xsd\/cccv1p0\.xsd/
      end
    end
  end
end
