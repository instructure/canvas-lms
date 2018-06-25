/*
 * Copyright (C) 2017 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that they will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */
import {flipAll} from './flip-message';
import ar from '../../config/locales/ar.json';
import bg from '../../config/locales/bg.json';
import cs from '../../config/locales/cs.json';
import da from '../../config/locales/da.json';
import de from '../../config/locales/de.json';
import el from '../../config/locales/el.json';
import enAU from '../../config/locales/en_AU.json';
import enGB from '../../config/locales/en_GB.json';
import en from '../../config/locales/en.json';
import es from '../../config/locales/es.json';
import faIR from '../../config/locales/fa_IR.json';
import frCA from '../../config/locales/fr_CA.json';
import fr from '../../config/locales/fr.json';
import he from '../../config/locales/he.json';
import ht from '../../config/locales/ht.json';
import hu from '../../config/locales/hu.json';
import hy from '../../config/locales/hy.json';
import it from '../../config/locales/it.json';
import ja from '../../config/locales/ja.json';
import ko from '../../config/locales/ko.json';
import mi from '../../config/locales/mi.json';
import nl from '../../config/locales/nl.json';
import nn from '../../config/locales/nn.json';
import nb from '../../config/locales/no.json';
import pl from '../../config/locales/pl.json';
import ptBR from '../../config/locales/pt_BR.json';
import pt from '../../config/locales/pt.json';
import ro from '../../config/locales/ro.json';
import ru from '../../config/locales/ru.json';
import sq from '../../config/locales/sq.json';
import sr from '../../config/locales/sr.json';
import sv from '../../config/locales/sv.json';
import tr from '../../config/locales/tr.json';
import ukUA from '../../config/locales/uk_UA.json';
import vi from '../../config/locales/vi.json';
import zhHans from '../../config/locales/zh.json';
import zhHant from '../../config/locales/zh_HK.json';

export default {
  enflip: flipAll(en), ar, bg, cs, da, de, el, 'en-AU': enAU, 'en-GB': enGB, en,
  es, 'fa-IR': faIR, 'fr-CA': frCA, fr, he, ht, hu, hy, it, ja, ko, mi, nl, nn,
  nb, pl, 'pt-BR': ptBR, pt, ro, ru, sq, sr, sv, tr, 'uk-UA': ukUA, vi,
  'zh-Hans': zhHans, 'zh-Hant': zhHant,
};
