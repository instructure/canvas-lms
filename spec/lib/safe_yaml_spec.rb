#
# Copyright (C) 2013 - present Instructure, Inc.
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
  let(:test_yaml) {
    yaml = <<-YAML
---
hwia: !map:HashWithIndifferentAccess
  a: 1
  b: 2
float: !float
  5.1
float_with_exp: -1.7763568394002505e-15
float_inf: .inf
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
  }

  it "should be used by default" do
    yaml = <<-YAML
--- !ruby/object:ActionController::Base
real_format:
YAML
    expect { YAML.load yaml }.to raise_error("Unknown YAML tag '!ruby/object:ActionController::Base'")
    result = YAML.unsafe_load yaml
    expect(result.class).to eq ActionController::Base
  end

  it "doesn't allow deserialization of arbitrary classes" do
    expect { YAML.load(YAML.dump(ActionController::Base)) }.to raise_error("YAML deserialization of constant not allowed: ActionController::Base")
  end

  it "allows deserialization of arbitrary classes when unsafe_loading" do
    expect(YAML.unsafe_load(YAML.dump(ActionController::Base))).to eq ActionController::Base
  end

  it "should allow some whitelisted classes" do
    result = YAML.load(test_yaml)

    def verify(result, key, klass)
      obj = result[key]
      expect(obj.class).to eq klass
      obj
    end

    hwia = verify(result, 'hwia', HashWithIndifferentAccess)
    expect(hwia.values_at(:a, :b)).to eq [1, 2]

    float = verify(result, 'float', Float)
    expect(float).to eq 5.1

    float_with_exp = verify(result, 'float_with_exp', Float)
    expect(float_with_exp).to eq(-1.7763568394002505e-15)

    float_inf = verify(result, 'float_inf', Float)
    expect(float_inf).to eq(Float::INFINITY)

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

  it "should allow some whitelisted classes through psych" do
    old_result = YAML.load(test_yaml)
    psych_yaml = YAML.dump(old_result)
    expect(Psych.load(psych_yaml)).to eq old_result
    expect(YAML.load(psych_yaml)).to eq old_result
  end

  it "should work with aliases" do
    hash = {:a => 1}.with_indifferent_access
    obj = {:blah => hash, :bloop => hash}.with_indifferent_access
    yaml = Psych.dump(obj)
    expect(YAML.load(yaml)).to eq obj
  end

  it "should dump whole floats correctly" do
    expect(YAML.dump(1.0)).to include("1.0")
  end

  it "should dump freaky floaty-looking strings" do
    str = "1.E+01"
    expect(YAML.load(YAML.dump(str))).to eq str
  end

  it "should dump html-safe strings correctly" do
    hash = {:blah => "42".html_safe}
    expect(YAML.load(YAML.dump(hash))).to eq hash
  end

  it "should dump strings with underscores followed by an integer" do
    # the ride never ends -_-
    hash = {:blah => "_42"}
    expect(YAML.load(YAML.dump(hash))).to eq hash
  end

  it "should also dump floaat looking strings followed by an underscore" do
    hash = {:blah => "42._"}
    expect(YAML.load(YAML.dump(hash))).to eq hash
  end

  it "should dump whatever this is too" do
    hash = {:blah => "4,2:0."}
    expect(YAML.load(YAML.dump(hash))).to eq hash
  end

  it "should be able to dump and load Canvas:Plugin classes" do
    plugin = Canvas::Plugin.find('canvas_cartridge_importer')
    expect(YAML.unsafe_load(YAML.dump(plugin))).to eq plugin
  end

  it "should be able to dump and load BigDecimals" do
    hash = {blah: BigDecimal.new("1.2")}
    expect(YAML.load(YAML.dump(hash))).to eq hash
  end

  it "should be able to dump and load these strings in stuff" do
    hash = {:blah => "<<"}
    expect(YAML.load(YAML.dump(hash))).to eq hash
  end

  it "dumps and loads singletons" do
    expect(YAML.load(YAML.dump(Mime::NullType.instance))).to eq Mime::NullType.instance
  end
end
