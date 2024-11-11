AC_INIT([guile-mqtt], [0.1.1])
AM_INIT_AUTOMAKE()

changequote(<, >)
PACKAGE_MAJOR_VERSION=`echo "$PACKAGE_VERSION" | sed -e 's/\([0-9]\+\)\..*/\1/'`
PACKAGE_MIDDLE_VERSION=`echo "$PACKAGE_VERSION" | sed -e 's/[0-9]\+\.\([0-9]\+\)\..*/\1/'`
PACKAGE_MINOR_VERSION=`echo "$PACKAGE_VERSION" | sed -e 's/.*\.\([0-9]\+\)/\1/'`
changequote([, ])
AC_SUBST(PACKAGE_MAJOR_VERSION)
AC_SUBST(PACKAGE_MIDDLE_VERSION)
AC_SUBST(PACKAGE_MINOR_VERSION)

# Check for Guile
GUILE_PKG
GUILE_PROGS

# Check for Nyacc
AC_MSG_CHECKING([for nyacc])
have_nyacc=""
NYACC_VERSION=`$GUILE -c '(display (@ (nyacc version) *nyacc-version*))'`
if test $? = 1; then
  if test ! -e $srcdir/module/mosquitto/foreign/cdata.scm; then
    AC_MSG_ERROR([Nyacc is required but was not found. Please install Nyacc >= 2.01.3 and try again.])
  fi
  AC_MSG_RESULT(no)
else
  have_nyacc=1
  AC_MSG_RESULT(yes)
fi

if test -n "$have_nyacc"; then
AC_MSG_CHECKING([for nyacc version >= 2.01.3])
if test "$NYACC_VERSION" \< "2.01.3" -a ! -e $srcdir/module/mosquitto/foreign/cdata.scm; then
  AC_MSG_ERROR([The installed version of Nyacc is too old. Please install Nyacc >= 2.01.3.])
fi
AC_MSG_RESULT(yes)
fi

# Check for pkg-config
PKG_PROG_PKG_CONFIG

# Ensure pkg-config is available
if test -z "$PKG_CONFIG"; then
  AC_MSG_ERROR([pkg-config is required but was not found. Please install pkg-config and try again.])
fi

PKG_CHECK_MODULES([MOSQUITTO], [libmosquitto >= 1.5], ,
  [AC_MSG_ERROR([libmosquitto not found. Install libmosquitto and try again.])]
)

AC_CONFIG_FILES([Makefile module/Makefile module/mosquitto/version.scm])
AC_CONFIG_FILES([pre-inst-env], [chmod +x pre-inst-env])

AC_OUTPUT
