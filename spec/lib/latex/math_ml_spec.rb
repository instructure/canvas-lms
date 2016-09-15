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
  let(:service_url) { 'http://get.mml.com' }
  let(:request_id)  { '0c0dad8c-7857-4447-ba1f-9f33a2f1debf' }
  let(:request_id_signature)  { Canvas::Security.sign_hmac_sha512(request_id) }

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
          url_for: service_url,
          use_for_mml?: true
        ).at_least_once
        RequestContextGenerator.expects(
          request_id: request_id
        ).at_least_once
        Canvas::Security.expects(
          services_signing_secret: 'wooper'
        ).at_least_once
      end

      it 'calls `CanvasHttp.get` with full url' do
        CanvasHttp.expects(:get).
          with(service_url, {
            'X-Request-Context-Id' => Canvas::Security.base64_encode(request_id),
            'X-Request-Context-Signature' => Canvas::Security.base64_encode(request_id_signature)
          }).
          returns(
            OpenStruct.new(
              status: '200',
              body: mml_doc
            )
          )

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
