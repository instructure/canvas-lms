/* Global variables (colors, typography, spacing, etc.) are defined in lib/themes */

export default function generator ({ colors, typography }) {
  return {
    fontSize: typography.fontSizeMedium,
    fontFamily: typography.fontFamily,
    fontWeight: typography.fontWeightNormal,

    color: colors.oxford,
    background: colors.white
  };
}
