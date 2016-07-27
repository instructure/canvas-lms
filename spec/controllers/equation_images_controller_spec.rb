require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe EquationImagesController do

  it 'should redirect image requests to codecogs' do
    get 'show', :id => 'foo'
    expect(response).to redirect_to('http://latex.codecogs.com/gif.latex?foo')
  end

  it 'encodes `+` signs properly' do
    latex = '5%5E5%5C%3A+%5C%3A%5Csqrt%7B9%7D'
    get :show, id: latex
    expect(response).to redirect_to(/\%2B/)
  end
end
