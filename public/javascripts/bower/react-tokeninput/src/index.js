export Combobox from './combobox';
export Option from './option';
export Token from './token';
import main from './main';

/**
 * You can't do an import and then immediately export it :(
 * And `export default TokenInput from './main'` doesn't seem to
 * work either :(
 * So this little variable swapping stuff gets it to work.
 */
const TokenInput = main;
export default TokenInput;
