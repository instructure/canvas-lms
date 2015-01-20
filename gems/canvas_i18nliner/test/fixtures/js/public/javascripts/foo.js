define(["i18n!foo"], function(I18n) {
  I18n.t("#absolute_key", "Absolute key");
  I18n.t("Inferred key");
  define(["i18n!nested"], function(I18n) {
    I18n.t("relative_key", "Relative key in nested scope");
  });
  I18n.t("relative_key", "Relative key");
});

define(["i18n!bar"], function(I18n) {
  I18n.t("relative_key", "Another relative key");
});
