# Sources for add-on-creator

module_DATA = \
  modules/AddOnCreator.rb \
  modules/PackagesDescr.pm

client_DATA = \
  clients/add-on-creator.rb

yncludedir = @yncludedir@/add-on-creator
ynclude_DATA = \
  include/add-on-creator/wizards.rb \
  include/add-on-creator/patterns.rb \
  include/add-on-creator/dialogs.rb \
  include/add-on-creator/complex.rb \
  include/add-on-creator/helps.rb

scrconf_DATA = \
  scrconf/cfg_add-on-creator.scr \
  scrconf/packages_descr.scr \
  scrconf/pattern.scr

agent_SCRIPTS = \
  servers_non_y2/ag_pattern \
  servers_non_y2/ag_packages_descr

desktop_DATA = \
  desktop/add-on-creator.desktop

fillup_DATA = \
  fillup/sysconfig.add-on-creator

EXTRA_DIST = $(module_DATA) $(client_DATA) $(ynclude_DATA) $(scrconf_DATA) $(agent_SCRIPTS) $(desktop_DATA) $(fillup_DATA)

include $(top_srcdir)/Makefile.am.common