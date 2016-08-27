require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe EquationImagesController do

  describe '#show' do
    it 'encodes `+` signs properly' do
      latex = '5%5E5%5C%3A+%5C%3A%5Csqrt%7B9%7D'
      get :show, id: latex
      expect(assigns(:latex)).to match(/\%2B/)
    end

    it 'should redirect image requests to codecogs' do
      get 'show', :id => 'foo'
      expect(response).to redirect_to('http://latex.codecogs.com/gif.latex?foo')
    end

    context 'when using MathMan' do
      let(:service_url) { 'http://get.mml.com' }
      before do
        MathMan.expects(
          url_for: service_url,
          use_for_svg?: true
        ).at_least_once
      end

      it 'redirects to service_url' do
        get :show, id: '5'
        expect(response).to redirect_to(/#{service_url}/)
      end
    end
  end
end
