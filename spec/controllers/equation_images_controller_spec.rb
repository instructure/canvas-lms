require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe EquationImagesController do

  it 'should redirect image requests to codecogs' do
    get 'show', :id => 'foo'
    response.should redirect_to('http://latex.codecogs.com/gif.latex?foo')
  end

end
