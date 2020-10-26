# frozen_string_literal: true

# Copyright (C) 2011 - present Instructure, Inc.
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

require "spec_helper"

describe "Unidecoder" do
  # Silly phrases courtesy of Frank da Cruz
  # http://www.columbia.edu/kermit/utf8.html
  DONT_CONVERT = [
    "Vitrum edere possum; mihi non nocet.", # Latin
    "Je puis mangier del voirre. Ne me nuit.", # Old French
    "Kristala jan dezaket, ez dit minik ematen.", # Basque
    "Kaya kong kumain nang bubog at hindi ako masaktan.", # Tagalog
    "Ich kann Glas essen, ohne mir weh zu tun.", # German
    "I can eat glass and it doesn't hurt me.", # English
  ]
  CONVERT_PAIRS = {
    "Je peux manger du verre, ça ne me fait pas de mal." => # French
      "Je peux manger du verre, ca ne me fait pas de mal.",
    "Pot să mănânc sticlă și ea nu mă rănește." => # Romanian
      "Pot sa mananc sticla si ea nu ma raneste.",
    "Ég get etið gler án þess að meiða mig." => # Icelandic
      "Eg get etid gler an thess ad meida mig.",
    "Unë mund të ha qelq dhe nuk më gjen gjë." => # Albanian
      "Une mund te ha qelq dhe nuk me gjen gje.",
    "Mogę jeść szkło i mi nie szkodzi." => # Polish
      "Moge jesc szklo i mi nie szkodzi.",
    "Я могу есть стекло, оно мне не вредит." => # Russian
      "Ia moghu iest' stieklo, ono mnie nie vriedit.",
    "Мога да ям стъкло, то не ми вреди." => # Bulgarian
      "Mogha da iam stklo, to nie mi vriedi.",
    "ᛁᚳ᛫ᛗᚨᚷ᛫ᚷᛚᚨᛋ᛫ᛖᚩᛏᚪᚾ᛫ᚩᚾᛞ᛫ᚻᛁᛏ᛫ᚾᛖ᛫ᚻᛖᚪᚱᛗᛁᚪᚧ᛫ᛗᛖ᛬" => # Anglo-Saxon
      "ic.mag.glas.eotacn.ond.hit.ne.heacrmiacth.me:",
    "ὕαλον ϕαγεῖν δύναμαι· τοῦτο οὔ με βλάπτει" => # Classical Greek
      "ualon phagein dunamai; touto ou me blaptei",
    "मैं काँच खा सकता हूँ और मुझे उससे कोई चोट नहीं पहुंचती" => # Hindi
      "maiN kaaNc khaa sktaa huuN aur mujhe usse koii cott nhiiN phuNctii",
    "من می توانم بدونِ احساس درد شيشه بخورم" => # Persian
      "mn my twnm bdwni Hss drd shyshh bkhwrm",
    "أنا قادر على أكل الزجاج و هذا لا يؤلمن" => # Arabic
      "'n qdr `l~ 'kl lzjj w hdh l yw'lmn",
    "אני יכול לאכול זכוכית וזה לא מזיק לי" => # Hebrew
      "ny ykvl lkvl zkvkyt vzh l mzyq ly",
    "ฉันกินกระจกได้ แต่มันไม่ทำให้ฉันเจ็บ" => # Thai
      "chankinkracchkaid aetmanaimthamaihchanecchb",
    "我能吞下玻璃而不伤身体。" => # Chinese
      "Wo Neng Tun Xia Bo Li Er Bu Shang Shen Ti . ",
    "私はガラスを食べられます。それは私を傷つけません。" => # Japanese
      "Si hagarasuwoShi beraremasu. sorehaSi woShang tukemasen. "
  }
  
  it "unidecoder_decode" do
    DONT_CONVERT.each do |ascii|
      expect(ascii).to eq LuckySneaks::Unidecoder.decode(ascii)
    end
    CONVERT_PAIRS.each do |unicode, ascii|
      expect(ascii).to eq LuckySneaks::Unidecoder.decode(unicode)
    end
  end
  
  it "to_ascii" do
    DONT_CONVERT.each do |ascii|
      expect(ascii).to eq ascii.to_ascii
    end
    CONVERT_PAIRS.each do |unicode, ascii|
      expect(ascii).to eq unicode.to_ascii
    end
  end
  
  it "unidecoder_encode" do
    {
      # Strings
      "0041" => "A",
      "00e6" => "æ",
      "042f" => "Я"
    }.each do |codepoint, unicode|
      expect(unicode).to eq LuckySneaks::Unidecoder.encode(codepoint)
    end
  end
  
  it "unidecoder_in_json_file" do
    {
      "A" => "x00.json (line 67)",
      "π" => "x03.json (line 194)",
      "Я" => "x04.json (line 49)"
    }.each do |character, output|
      expect(output).to eq LuckySneaks::Unidecoder.in_json_file(character)
    end
  end
end
