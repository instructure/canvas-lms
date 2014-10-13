#
# Copyright (C) 2013 Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.
#

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')

describe "safe_yaml" do
  it "should be used by default" do
    yaml = <<-YAML
--- !ruby/object:ActionController::Base 
real_format: 
YAML
    expect { YAML.load yaml }.to raise_error(SafeYAML::UnsafeTagError)
    result = YAML.unsafe_load yaml
    expect(result.class).to eq ActionController::Base
  end

  it "should allow some whitelisted classes" do
    yaml = <<-YAML
---
hwia: !map:HashWithIndifferentAccess
  a: 1
  b: 2
float: !float
  5.1
os: !ruby/object:OpenStruct
  modifiable: true
  table: 
    :a: 1
    :b: 2
    :sub: !ruby/object:OpenStruct
      modifiable: true
      table: 
        :c: 3
str: !str
  hai
mime: !ruby/object:Mime::Type
  string: png
  symbol: 
  synonyms: []
http: !ruby/object:URI::HTTP 
  fragment: 
  host: example.com
  opaque: 
  parser: 
  password: 
  path: /
  port: 80
  query: 
  registry: 
  scheme: http
  user: 
https: !ruby/object:URI::HTTPS 
  fragment: 
  host: example.com
  opaque: 
  parser: 
  password: 
  path: /
  port: 443
  query: 
  registry: 
  scheme: https
  user: 
ab: !ruby/object:Class AcademicBenchmark::Converter
qt: !ruby/object:Class Qti::Converter
verbose_symbol: !ruby/symbol blah
oo: !ruby/object:OpenObject
  table:
    :a: 1
YAML
    result = YAML.load yaml

    def verify(result, key, klass)
      obj = result[key]
      expect(obj.class).to eq klass
      obj
    end

    hwia = verify(result, 'hwia', HashWithIndifferentAccess)
    expect(hwia.values_at(:a, :b)).to eq [1, 2]

    float = verify(result, 'float', Float)
    expect(float).to eq 5.1

    os = verify(result, 'os', OpenStruct)
    expect(os.a).to eq 1
    expect(os.b).to eq 2
    expect(os.sub.class).to eq OpenStruct
    expect(os.sub.c).to eq 3

    str = verify(result, 'str', String)
    expect(str).to eq "hai"

    mime = verify(result, 'mime', Mime::Type)
    expect(mime.to_s).to eq 'png'

    http = verify(result, 'http', URI::HTTP)
    expect(http.host).to eq 'example.com'

    https = verify(result, 'https', URI::HTTPS)
    expect(https.host).to eq 'example.com'

    expect(result['ab']).to eq AcademicBenchmark::Converter
    expect(result['qt']).to eq Qti::Converter

    expect(result['verbose_symbol']).to eq :blah

    oo = verify(result, 'oo', OpenObject)
    expect(oo.a).to eq 1
  end
end
