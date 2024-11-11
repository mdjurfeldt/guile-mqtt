GUILE_WARNINGS = -W2
moddir=$(prefix)/share/guile/site/$(GUILE_EFFECTIVE_VERSION)
godir=$(libdir)/guile/$(GUILE_EFFECTIVE_VERSION)/site-ccache

COPIED_SOURCES =				\
  mosquitto/foreign/arch-info.scm		\
  mosquitto/foreign/cdata.scm

SCM_SOURCES =					\
  $(COPIED_SOURCES)				\
  ffi/mosquitto.scm				\
  mosquitto/client.scm

SOURCES =					\
  ffi/mosquitto.ffi				\
  $(SCM_SOURCES)

SUFFIXES = .scm .go
GOBJECTS = $(SCM_SOURCES:%.scm=%.go)
CLEANFILES = $(GOBJECTS)
EXTRA_DIST = $(SOURCES)
nobase_mod_DATA = $(SOURCES)
nobase_go_DATA = $(GOBJECTS)

# Make sure source files are installed first, so that the mtime of
# installed compiled files is greater than that of installed source
# files.  See
# <http://lists.gnu.org/archive/html/guile-devel/2010-07/msg00125.html>
# for details.
guile_install_go_files = install-nobase_goDATA
$(guile_install_go_files): install-nobase_modDATA

.scm.go:
	$(AM_V_GEN)$(top_builddir)/pre-inst-env $(GUILE_TOOLS) compile $(GUILE_WARNINGS) -o "$@" "$(srcdir)/$<"

ffi/mosquitto.scm: ffi/mosquitto.ffi
	$(AM_V_GEN)$(top_builddir)/pre-inst-env $(GUILE_TOOLS) compile-ffi -o "$(srcdir)/$@" "$<"

$(COPIED_SOURCES):
	src=`basename $@`; \
	sed -e 's/(nyacc/(mosquitto/' \
	< "`$(AM_V_GEN)$(top_builddir)/pre-inst-env $(GUILE) \
	  -c "(display (search-path %load-path \\"nyacc/foreign/$$src\\"))"`" \
	> "$(srcdir)/$@"
