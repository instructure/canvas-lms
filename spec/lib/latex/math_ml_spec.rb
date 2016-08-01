require 'spec_helper'

describe Latex::MathMl do
  let(:latex) do
    '\sqrt{25}+12^{12}'
  end
  let(:mml_doc) do
    <<-DOC
      <math xmlns="http://www.w3.org/1998/Math/MathML" display="inline">
        <msqrt>
          <mrow>
            <mn>25</mn>\
          </mrow>
        </msqrt>
        <mo>+</mo>
        <msup>
          <mn>12</mn>
          <mrow>
            <mn>12</mn>
          </mrow>
        </msup>
      </math>
    DOC
  end

  subject(:math_ml) do
    Latex::MathMl.new(latex: latex)
  end

  describe '#parse' do
    it 'delegates to Ritex::Parser' do
      Ritex::Parser.any_instance.expects(:parse).once
      math_ml.parse
    end

    context 'when using mathman' do
      before do
        MathMan.expects(
          url_for: 'http://get.mml.com',
          use_for_mml?: true
        ).at_least_once
      end

      it 'calls `CanvasHttp.get` with full url' do
        CanvasHttp.expects(get: OpenStruct.new(
          status: '200',
          body: mml_doc
        ))
        math_ml.parse
      end

      context 'when response status is not 200' do
        it 'returns an empty string' do
          CanvasHttp.expects(get: OpenStruct.new(
            status: '500',
            body: mml_doc
          ))
          expect(math_ml.parse).to be_empty
        end
      end
    end
  end
end
