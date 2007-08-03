# Makefile.am for add-on-creator/src

yncludedir = @yncludedir@/add-on-creator

client_DATA =			\
	add-on-creator.ycp	\
	add-on-creator_auto.ycp

ynclude_DATA =			\
	helps.ycp		\
	wizards.ycp		\
	dialogs.ycp		\
	complex.ycp		\
	patterns.ycp

desktop_DATA =			\
	add-on-creator.desktop

module_DATA =			\
	AddOnCreator.ycp	\
	PackagesDescr.pm

# create a symlink for local build, #145327
add-on-creator:
	ln -sf . $@
ycpchook = add-on-creator

EXTRA_DIST = $(client_DATA) $(ynclude_DATA) $(module_DATA) $(desktop_DATA)

include $(top_srcdir)/Makefile.am.common
