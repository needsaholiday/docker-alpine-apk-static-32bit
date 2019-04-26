#!/bin/sh
# shellcheck disable=SC2030,SC2031
# SC2030: Modification of WINE is local (to subshell caused by (..) group).
# SC2031: WINE was modified in a subshell. That change might be lost
# This has to be right after the shebang, see: https://github.com/koalaman/shellcheck/issues/779

# Name of this version of winetricks (YYYYMMDD)
# (This doesn't change often, use the sha256sum of the file when reporting problems)
WINETRICKS_VERSION=20190310-next

# This is a UTF-8 file
# You should see an o with two dots over it here [ö]
# You should see a micro (u with a tail) here [µ]
# You should see a trademark symbol here [™]

#--------------------------------------------------------------------
#
# Winetricks is a package manager for Win32 dlls and applications on POSIX.
# Features:
# - Consists of a single shell script - no installation required
# - Downloads packages automatically from original trusted sources
# - Points out and works around known wine bugs automatically
# - Both command-line and GUI operation
# - Can install many packages in silent (unattended) mode
# - Multiplatform; written for Linux, but supports OS X and Cygwin too
#
# Uses the following non-POSIX system tools:
# - wine is used to execute Win32 apps except on Cygwin.
# - ar, cabextract, unrar, unzip, and 7z are needed by some verbs.
# - aria2c, wget, curl, or fetch is needed for downloading.
# - sha256sum, sha256, or shasum (OSX 10.5 does not support these, 10.6+ is required):
#   note: some legacy verbs may still use sha1sum, sha1, or shasum, but this is
#   deprecated and will be removed in a future release.
# - zenity is needed by the GUI, though it can limp along somewhat with kdialog/xmessage.
# - xdg-open (if present) or open (for OS X) is used to open download pages
#   for the user when downloads cannot be fully automated.
# - pkexec, sudo, or kdesu (gksu/gksudo/kdesudo are deprecated upstream but also still supported)
#   are used to mount .iso images if the user cached them with -k option.
# - fuseiso, archivemount (Linux), or hdiutil (macOS) is used to mount .iso images.
# - perl is used to munge steam config files.
# - torify is used with option "--torify" if sites are blocked in single countries.
# On Ubuntu, the following lines can be used to install all the prerequisites:
#    sudo add-apt-repository ppa:ubuntu-wine/ppa
#    sudo apt-get update
#    sudo apt-get install binutils cabextract p7zip-full unrar unzip wget wine zenity
# On Fedora, these commands can be used (RPM Fusion is used to install unrar):
#    sudo dnf install https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
#    sudo dnf install binutils cabextract p7zip-plugins unrar unzip wget wine zenity
#
# See https://github.com/Winetricks/winetricks for documentation and tutorials,
# including how to contribute changes to winetricks.
#
#--------------------------------------------------------------------
#
# Copyright:
#   Copyright (C) 2007-2014 Dan Kegel <dank!kegel.com>
#   Copyright (C) 2008-2019 Austin English <austinenglish!gmail.com>
#   Copyright (C) 2010-2011 Phil Blankenship <phillip.e.blankenship!gmail.com>
#   Copyright (C) 2010-2015 Shannon VanWagner <shannon.vanwagner!gmail.com>
#   Copyright (C) 2010 Belhorma Bendebiche <amro256!gmail.com>
#   Copyright (C) 2010 Eleazar Galano <eg.galano!gmail.com>
#   Copyright (C) 2010 Travis Athougies <iammisc!gmail.com>
#   Copyright (C) 2010 Andrew Nguyen
#   Copyright (C) 2010 Detlef Riekenberg
#   Copyright (C) 2010 Maarten Lankhorst
#   Copyright (C) 2010 Rico Schüller
#   Copyright (C) 2011 Scott Jackson <sjackson2!gmx.com>
#   Copyright (C) 2011 Trevor Johnson
#   Copyright (C) 2011 Franco Junio
#   Copyright (C) 2011 Craig Sanders
#   Copyright (C) 2011 Matthew Bauer <mjbauer95>
#   Copyright (C) 2011 Giuseppe Dia
#   Copyright (C) 2011 Łukasz Wojniłowicz
#   Copyright (C) 2011 Matthew Bozarth
#   Copyright (C) 2013-2017 Andrey Gusev <andrey.goosev!gmail.com>
#   Copyright (C) 2013-2017 Hillwood Yang <hillwood!opensuse.org>
#   Copyright (C) 2013,2016 André Hentschel <nerv!dawncrow.de>
#
# License:
#   This program is free software; you can redistribute it and/or
#   modify it under the terms of the GNU Lesser General Public
#   License as published by the Free Software Foundation; either
#   version 2.1 of the License, or (at your option) any later
#   version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU Lesser General Public License for more details.
#
#   You should have received a copy of the GNU Lesser General Public
#   License along with this program.  If not, see
#   <https://www.gnu.org/licenses/>.
#
#--------------------------------------------------------------------
# Coding standards:
#
# Portability:
# - Portability matters, as this script is run on many operating systems
# - No bash, zsh, or csh extensions; only use features from
#   the POSIX standard shell and utilities; see
#   https://pubs.opengroup.org/onlinepubs/009695399/utilities/xcu_chap02.html
# - 'checkbashisms -p -x winetricks' should show no warnings (per Debian policy)
# - Prefer classic sh idioms as described in e.g.
#   "Portable Shell Programming" by Bruce Blinn, ISBN: 0-13-451494-7
# - If there is no universally available program for a needed function,
#   support the two most frequently available programs.
#   e.g. fall back to wget if curl is not available; likewise, support
#   both sha256sum and sha256.
# - When using Unix commands like cp, put options before filenames so it will
#   work on systems like OS X.  e.g. "rm -f foo.dat", not "rm foo.dat -f"
#
# Formatting:
# - Your terminal and editor must be configured for UTF-8
#   If you do not see an o with two dots over it here [ö], stop!
# - Do not use tabs in this file or any verbs.
# - Indent 4 spaces.
# - Try to keep line length below 80 (makes printing easier)
# - Open curly braces ('{'),
#   then should go on the same line as 'if/elif'
#   close curlies ('}') and 'fi' should line up with the matching { or if,
#   cases indented 4 spaces from 'case' and 'esac'.  For instance,
#
#      if test "$FOO" = "bar"; then
#         echo "FOO is bar"
#      fi
#
#      case "$FOO" in
#          bar) echo "FOO is still bar" ;;
#      esac
#
# Commenting:
# - Comments should explain intent in English
# - Keep functions short and well named to reduce need for comments
#
# Naming:
# Public things defined by this script, for use by verbs:
# - Variables have uppercase names starting with W_
# - Functions have lowercase names starting with w_
#
# Private things internal to this script, not for use by verbs:
# - Local variables have lowercase names starting with uppercase _W_
#   (and should not use the local declaration, as it is not POSIX)
# - Global variables have uppercase names starting with WINETRICKS_
# - Functions have lowercase names starting with winetricks_
# FIXME: A few verbs still use winetricks-private functions or variables.
#
# Internationalization / localization:
# - Important or frequently used message should be internationalized
#   so translations can be easily added.  For example:
#     case $LANG in
#         de*) echo "Das ist die deutsche Meldung" ;;
#         *)   echo "This is the English message" ;;
#     esac
#
# Support:
# - Winetricks is maintained by Austin English <austinenglish!$gmail.com>.
# - If winetricks has helped you out, then please consider donating to the FSF/EFF as a thank you:
#   * EFF - https://supporters.eff.org/donate/button
#   * FSF - https://my.fsf.org/donate
# - Donations towards electricity bill and developer beer fund can be sent via Bitcoin to 18euSAZztpZ9wcN6xZS3vtNnE1azf8niDk
# - I try to actively respond to bugs and pull requests on GitHub:
# - Bugs: https://github.com/Winetricks/winetricks/issues/new
# - Pull Requests: https://github.com/Winetricks/winetricks/pulls
#--------------------------------------------------------------------

# FIXME: XDG_CACHE_HOME is defined twice, clean this up
XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"

W_COUNTRY=""
W_PREFIXES_ROOT="${WINE_PREFIXES:-$XDG_DATA_HOME/wineprefixes}"

# For temp files before $WINEPREFIX is available:
if [ -x "$(command -v mktemp 2>/dev/null)" ] ; then
    W_TMP_EARLY="$(mktemp -d "${TMPDIR:-/tmp}/winetricks.XXXXXXXX")"
elif [ -w "$TMPDIR" ] ; then
    W_TMP_EARLY="$TMPDIR"
else
    W_TMP_EARLY="/tmp"
fi

#---- Public Functions ----

# Ask permission to continue
w_askpermission()
{
    echo "------------------------------------------------------"
    echo "$@"
    echo "------------------------------------------------------"

    if test "$W_OPT_UNATTENDED"; then
        _W_timeout="--timeout 5"
    fi

    case $WINETRICKS_GUI in
        zenity) $WINETRICKS_GUI "$_W_timeout" --question --title=winetricks --text="$(echo "$@" | sed 's,\\\\,\\\\\\\\,g')" --no-wrap;;
        kdialog) $WINETRICKS_GUI --title winetricks --warningcontinuecancel "$@" ;;
        none)
            if [ -n "$_W_timeout" ]; then
                # -t / TMOUT don't seem to be portable, so just assume yes in unattended mode
                w_info "Unattended mode, not prompting for confirmation"
            else
                printf %s "Press Y or N, then Enter: "
                read -r response
                test "$response" = Y || test "$response" = y
            fi
    esac

    if test $? -ne 0; then
        case $LANG in
            uk*) w_die "Операція скасована." ;;
            pl*) w_die "Anulowano operację, opuszczanie." ;;
            *) w_die "Operation cancelled, quitting." ;;
        esac
        exec false
    fi

    unset _W_timeout
}

# Display info message.  Time out quickly if user doesn't click.
w_info()
{
    # If $WINETRICKS_SUPER_QUIET is set, w_info is a no-op:
    if [ -z "$WINETRICKS_SUPER_QUIET" ] ; then
        echo "------------------------------------------------------"
        echo "$@"
        echo "------------------------------------------------------"
    fi

    _W_timeout="--timeout 3"

    case $WINETRICKS_GUI in
        zenity) $WINETRICKS_GUI "$_W_timeout" --info --title=winetricks --text="$(echo "$@" | sed 's,\\\\,\\\\\\\\,g')" --no-wrap;;
        kdialog) $WINETRICKS_GUI --title winetricks --msgbox "$@" ;;
        none) ;;
    esac

    unset _W_timeout
}

# Display warning message to stderr (since it is called inside redirected code)
w_warn()
{
    # If $WINETRICKS_SUPER_QUIET is set, w_info is a no-op:
    if [ -z "$WINETRICKS_SUPER_QUIET" ] ; then
        echo "------------------------------------------------------"
        echo "$@"
        echo "------------------------------------------------------"
    fi

    if test "$W_OPT_UNATTENDED"; then
        _W_timeout="--timeout 5"
    fi

    case $WINETRICKS_GUI in
        zenity) $WINETRICKS_GUI "$_W_timeout" --error --title=winetricks --text="$(echo "$@" | sed 's,\\\\,\\\\\\\\,g')";;
        kdialog) $WINETRICKS_GUI --title winetricks --error "$@" ;;
        none) ;;
    esac

    unset _W_timeout
}

# Display warning message to stderr (since it is called inside redirected code)
# And give gui user option to cancel (for when used in a loop)
# If user cancels, exit status is 1
w_warn_cancel()
{
    echo "------------------------------------------------------" >&2
    echo "$@" >&2
    echo "------------------------------------------------------" >&2

    if test "$W_OPT_UNATTENDED"; then
        _W_timeout="--timeout 5"
    fi

    # Zenity has no cancel button, but will set status to 1 if you click the go-away X
    case $WINETRICKS_GUI in
        zenity) $WINETRICKS_GUI "$_W_timeout" --error --title=winetricks --text="$(echo "$@" | sed 's,\\\\,\\\\\\\\,g')";;
        kdialog) $WINETRICKS_GUI --title winetricks --warningcontinuecancel "$@" ;;
        none) ;;
    esac

    # can't unset, it clears status
}

# Display fatal error message and terminate script
w_die()
{
    w_warn "$@"

    exit 1
}

# Kill all instances of a process in a safe way (Solaris killall kills _everything_)
w_killall()
{
    # shellcheck disable=SC2046,SC2086
    kill -s KILL $(pgrep $1)
}

# Some packages don't support win32, die with an appropriate message
# Returns 64 (for tests/winetricks-test)
w_package_unsupported_win32()
{
    if [ "$W_ARCH" = "win32" ] ; then
        w_warn "This package ($W_PACKAGE) does not work on a 32-bit installation. You must use a prefix made with WINEARCH=win64."
        exit 64
    fi
}

# Warn user if package is broken. Optionally provide a link to the bug report.
w_package_broken_win64()
{
    # Optional:
    bug_link="$1"

    if [ "$W_ARCH" = "win64" ] ; then
        if [ -n "$1" ] ; then
            w_die "This package ($W_PACKAGE) is broken on 64-bit Wine. Using a prefix made with WINEARCH=win32 to work around this. See: ${bug_link}"
        else
            w_die "This package ($W_PACKAGE) is broken on 64-bit Wine. Using a prefix made with WINEARCH=win32 to work around this."
        fi
    fi
}

# Some packages don't support win64, die with an appropriate message
# Note: this is for packages that natively don't support win64, not packages that are broken on wine64, for that, use w_package_broken_win64()
# Returns 32 (for tests/winetricks-test)
w_package_unsupported_win64()
{
    if [ "$W_ARCH" = "win64" ] ; then
        case $LANG in
            pl*) w_warn "Ten pakiet ($W_PACKAGE) nie działa z 64-bitową instalacją. Musisz użyć prefiksu utworzonego z WINEARCH=win32." ;;
            ru*) w_warn "Данный пакет не работает в 64-битном окружении. Используйте префикс, созданный с помощью WINEARCH=win32." ;;
            *) w_warn "This package ($W_PACKAGE) does not work on a 64-bit installation. You must use a prefix made with WINEARCH=win32." ;;
        esac
        exit 32
    fi
}

# For packages that are not well tested or have some known issues on win64, but aren't broken
w_package_warn_win64()
{
    if [ "$W_ARCH" = "win64" ] ; then
        case $LANG in
            pl*) w_warn "Ten pakiet ($W_PACKAGE) może nie działać poprawnie z 64-bitową instalacją. Prefiks 32-bitowy może działąć lepiej." ;;
            ru*) w_warn "Данный пакет может работать не полностью в 64-битном окружении. 32-битные префиксы могут работать лучше." ;;
            *) w_warn "This package ($W_PACKAGE) may not fully work on a 64-bit installation. 32-bit prefixes may work better." ;;
        esac
    fi
}

### w_try and w_try wrappers ###

# Execute with error checking
# Put this in front of any command that might fail
w_try()
{
    # "VAR=foo w_try cmd" fails to put VAR in the environment
    # with some versions of bash if w_try is a shell function?!
    # This is a problem when trying to pass environment variables to e.g. wine.
    # Adding an explicit export here works around it, so add any we use.
    export WINEDLLOVERRIDES
    printf '%s\n' "Executing $*"

    # On Vista, we need to jump through a few hoops to run commands in Cygwin.
    # First, .exe's need to have the executable bit set.
    # Second, only cmd can run setup programs (presumably for security).
    # If $1 ends in .exe, we know we're running on real Windows, otherwise
    # $1 would be 'wine'.
    case "$1" in
        *.exe)
            chmod +x "$1" || true # don't care if it fails
            cmd /c "$@"
            ;;
        *)
            "$@"
            ;;
    esac
    status=$?
    if test $status -ne 0; then
        case $LANG in
            pl*) w_die "Informacja: poelcenie $* zwróciło status $status. Przerywam." ;;
            ru*) w_die "Важно: команда $* вернула статус $status. Прерывание." ;;
            *) w_die "Note: command $* returned status $status. Aborting." ;;
        esac
    fi
}

w_try_7z()
{
    # $1 - directory to extract to
    # $2 - file to extract
    # $3 .. $n - files to extract from the archive

    destdir="$1"
    filename="$2"
    shift 2

    # Not always installed, use Windows 7-Zip as a fallback:
    if test -x "$(command -v 7z 2>/dev/null)"; then
        w_try 7z x "$filename" -o"$destdir" "$@"
    else
        w_warn "Cannot find 7z.  Using Windows 7-Zip instead. (You can avoid this by installing 7z, e.g. 'sudo apt-get install p7zip-full' or 'sudo yum install p7zip-plugins')."
        WINETRICKS_OPT_SHAREDPREFIX=1 w_call 7zip
        # errors out if there is a space between -o and path
        w_try "$WINE" "$W_PROGRAMS_X86_WIN\\7-Zip\\7z.exe" x "$(w_pathconv -w "$filename")" -o"$(w_pathconv -w "$destdir")" "$@"
    fi
}

w_try_ar()
{
    # $1 - ar file (.deb) to extract (keeping internal paths, in cwd)
    # $2 - file to extract (optional)

    # Not always installed, use Windows 7-zip as a fallback:
    if test -x "$(command -v ar 2>/dev/null)"; then
        w_try ar x "$@"
    else
        w_warn "Cannot find ar.  Using Windows 7-zip instead. (You can avoid this by installing binutils, e.g. 'sudo apt-get install binutils' or 'sudo yum install binutils')."
        WINETRICKS_OPT_SHAREDPREFIX=1 w_call 7zip

        # -t* prevents 7-zip from decompressing .tar.xz to .tar, see
        # https://sourceforge.net/p/sevenzip/discussion/45798/thread/8cd16946/?limit=25
        w_try "$WINE" "$W_PROGRAMS_X86_WIN\\7-Zip\\7z.exe" -t* x "$(w_pathconv -w "$1")"
    fi
}

w_try_cabextract()
{
    # Not always installed, but shouldn't be fatal unless it's being used
    if test ! -x "$(command -v cabextract 2>/dev/null)"; then
        w_die "Cannot find cabextract.  Please install it (e.g. 'sudo apt-get install cabextract' or 'sudo yum install cabextract')."
    fi

    w_try cabextract -q "$@"
}

w_try_cd()
{
    w_try cd "$@"
}

# Copy font files matching a glob pattern from source directory to destination directory.
# Also remove any file in the destination directory that has the same name as
# any of the files that we're trying to copy, but with different case letters.
# Note: it converts font file names to lower case to avoid inconsistencies due to paths
#       being case-insensitive under Wine.
w_try_cp_font_files()
{
    # $1 - source directory
    # $2 - destination directory
    # $3 - optional font file glob pattern (default: "*.ttf")

    _W_src_dir="$1"
    _W_dest_dir="$2"
    _W_pattern="$3"
    shift 2

    if test ! -d "$_W_src_dir"; then
        w_die "bug: missing source dir"
    fi

    if test ! -d "$_W_dest_dir"; then
        w_die "bug: missing destination dir"
    fi

    if test -z "$_W_pattern"; then
        _W_pattern="*.ttf"
    fi

# POSIX sh doesn't have a good way to handle this, but putting into a separate script
# and running with sh avoids it.
#
# See https://github.com/Winetricks/winetricks/issues/995 for details

cat > "$WINETRICKS_WORKDIR/cp_font_files.sh" <<_EOF_
#!/bin/sh
    _W_src_file="\$@"

    # Extract the file name and lower case it
    _W_file_name="\$(basename "\$_W_src_file" | tr "[:upper:]" "[:lower:]")"

    # Remove any existing font files that might have the same name, but with different case characters
    find "$_W_dest_dir" -maxdepth 1 -type f -iname "\$_W_file_name" -exec rm '{}' ';'

    # FIXME: w_try() isn't available, need some better error handling:
    cp -f "\$_W_src_file" "$_W_dest_dir/\$_W_file_name"
_EOF_
    chmod +x "$WINETRICKS_WORKDIR/cp_font_files.sh"

    find "$_W_src_dir" -maxdepth 1 -type f -iname "$_W_pattern" -exec "$WINETRICKS_WORKDIR/cp_font_files.sh" {} \;

    # Wait for Wine to add the new font to the registry under HKCU\Software\Wine\Fonts\Cache
    w_wineserver -w

    unset _W_dest_dir
}

w_try_msiexec64()
{
    if test "$W_ARCH" != "win64"; then
        w_die "bug: 64-bit msiexec called from a $W_ARCH prefix."
    fi

    # shellcheck disable=SC2086
    w_try "$WINE" start /wait "$W_SYSTEM64_DLLS_WIN32/msiexec.exe" $W_UNATTENDED_SLASH_Q "$@"
}

w_try_regedit()
{
    # If on wow64, run under both wine and wine64 (otherwise they only go in the 32-bit registry afaict)

    # shellcheck disable=SC2086
    if [ "$W_ARCH" = "win32" ]; then
        w_try_regedit32 "$@"
    elif [ "$W_ARCH" = "win64" ]; then
        w_try_regedit32 "$@"
        w_try_regedit64 "$@"
    fi
}

# fixme: cleanup. For wow64 registries, some/all entries need to be duplicated.
# Not sure of the best way yet, but thinking running wine/wine64 regedit for each?
w_try_regedit32()
{
    # on windows, doesn't work without cmd /c
    case "$W_PLATFORM" in
        windows_cmd|wine_cmd) cmdc="cmd /c";;
        *) unset cmdc ;;
    esac

    # shellcheck disable=SC2086
    w_try "$WINE_MULTI" $cmdc regedit $W_UNATTENDED_SLASH_S "$@"
}

w_try_regedit64()
{
    # on windows, doesn't work without cmd /c
    case "$W_PLATFORM" in
        windows_cmd|wine_cmd) cmdc="cmd /c";;
        *) unset cmdc ;;
    esac

    # shellcheck disable=SC2086
    w_try "$WINE64" $cmdc regedit $W_UNATTENDED_SLASH_S "$@"
}

w_try_regsvr()
{
    # shellcheck disable=SC2086
    w_try "$WINE" regsvr32 $W_UNATTENDED_SLASH_S "$@"
}

w_try_regsvr64()
{
    # shellcheck disable=SC2086
    w_try "$WINE64" regsvr32 $W_UNATTENDED_SLASH_S "$@"
}

w_try_unrar()
{
    # $1 - zipfile to extract (keeping internal paths, in cwd)

    # Not always installed, use Windows 7-Zip as a fallback:
    if test -x "$(command -v unrar 2>/dev/null)"; then
        w_try unrar x "$@"
    else
        w_warn "Cannot find unrar.  Using Windows 7-Zip instead. (You can avoid this by installing unrar, e.g. 'sudo apt-get install unrar' or 'sudo yum install unrar')."
        WINETRICKS_OPT_SHAREDPREFIX=1 w_call 7zip
        w_try "$WINE" "$W_PROGRAMS_X86_WIN\\7-Zip\\7z.exe" x "$(w_pathconv -w "$1")"
    fi
}

w_try_unzip()
{
    # $1 - directory to extract to
    # $2 - zipfile to extract
    # $3 .. $n - files to extract from the archive

    destdir="$1"
    zipfile="$2"
    shift 2

    # Not always installed, use Windows 7-Zip as a fallback:
    if test -x "$(command -v unzip 2>/dev/null)"; then
        # FreeBSD ships unzip, but it doesn't support self-compressed executables
        # If it fails, fall back to 7-Zip:
        unzip -o -q -d"$destdir" "$zipfile" "$@"
        ret=$?
        case $ret in
            0) return ;;
            1|*) w_warn "Unzip failed, trying Windows 7-Zip instead." ;;
        esac
    else
        w_warn "Cannot find unzip.  Using Windows 7-Zip instead. (You can avoid this by installing unzip, e.g. 'sudo apt-get install unzip' or 'sudo yum install unzip')."
    fi

    WINETRICKS_OPT_SHAREDPREFIX=1 w_call 7zip
    # errors out if there is a space between -o and path
    w_try "$WINE" "$W_PROGRAMS_X86_WIN\\7-Zip\\7z.exe" x "$(w_pathconv -w "$zipfile")" -o"$(w_pathconv -w "$destdir")" "$@"
}

### End of w_try ###

w_read_key()
{
    if test ! "$W_OPT_UNATTENDED"; then
        W_KEY=dummy_to_make_autohotkey_happy
        return 0
    fi

    mkdir -p "$W_CACHE/$W_PACKAGE"

    # backwards compatible location
    # Auth doesn't belong in cache, since restoring it requires user input
    _W_keyfile="$W_CACHE/$W_PACKAGE/key.txt"
    if ! test -f "$_W_keyfile"; then
        _W_keyfile="$WINETRICKS_AUTH/$W_PACKAGE/key.txt"
    fi
    if ! test -f "$_W_keyfile"; then
        # read key from user
        case $LANG in
            da*) _W_keymsg="Angiv venligst registrerings-nøglen for pakken '$W_PACKAGE'"
                _W_nokeymsg="Ingen nøgle angivet"
                ;;
            de*) _W_keymsg="Bitte einen Key für Paket '$W_PACKAGE' eingeben"
                _W_nokeymsg="Keinen Key eingegeben?"
                ;;
            pl*) _W_keymsg="Proszę podać klucz dla programu '$W_PACKAGE'"
                _W_nokeymsg="Nie podano klucza"
                ;;
            ru*) _W_keymsg="Пожалуйста, введите ключ для приложения '$W_PACKAGE'"
                _W_nokeymsg="Ключ не введён"
                ;;
            uk*) _W_keymsg="Будь ласка, введіть ключ для додатка '$W_PACKAGE'"
                _W_nokeymsg="Ключ не надано"
                ;;
            zh_CN*)  _W_keymsg="按任意键为 '$W_PACKAGE'"
                _W_nokeymsg="No key given"
                ;;
            zh_TW*|zh_HK*)  _W_keymsg="按任意鍵為 '$W_PACKAGE'"
                _W_nokeymsg="No key given"
                ;;
            *)  _W_keymsg="Please enter the key for app '$W_PACKAGE'"
                _W_nokeymsg="No key given"
                ;;
        esac

        case $WINETRICKS_GUI in
            *zenity) W_KEY=$(zenity --entry --text "$_W_keymsg") ;;
            *kdialog) W_KEY=$(kdialog --inputbox "$_W_keymsg") ;;
            *xmessage) w_die "sorry, can't read key from GUI with xmessage" ;;
            none) printf %s "$_W_keymsg": ; read -r W_KEY ;;
        esac

        if test "$W_KEY" = ""; then
            w_die "$_W_nokeymsg"
        fi
        echo "$W_KEY" > "$_W_keyfile"
    fi
    W_RAW_KEY=$(cat "$_W_keyfile")
    W_KEY=$(echo "$W_RAW_KEY" | tr -d '[:blank:][=-=]')
    unset _W_keyfile _W_keymsg _W_nokeymsg
}

w_verify_cabextract_available()
{
    # If verb_a requires verb_b, then verba will fail when the dependency for verb_b is installed
    # This should be called by verb_a, to give a proper warning

    w_try_cabextract -q -v
}

# Convert a Windows path to a Unix path quickly.
# $1 is an absolute Windows path starting with c:\ or C:/
# with no funny business, so we can use the simplest possible
# algorithm.
winetricks_wintounix()
{
    _W_winp_="$1"
    # Remove drive letter and colon
    _W_winp="${_W_winp_#??}"
    # Prepend the location of drive c
    printf %s "$WINEPREFIX"/dosdevices/c:
    # Change backslashes to slashes
    echo "$_W_winp" | sed 's,\\,/,g'
}

# Convert between Unix path and Windows path
# Usage is lowest common denominator of cygpath/winepath
# so -u to convert to Unix, and -w to convert to Windows
w_pathconv()
{
    case "$W_PLATFORM" in
        windows_cmd)
            # for some reason, cygpath turns some spaces into newlines?!
            cygpath "$@" | tr '\012' '\040' | sed 's/ $//'
            ;;
        *)
            case "$@" in
                -u?c:\\*|-u?C:\\*|-u?c:/*|-u?C:/*) winetricks_wintounix "$2" ;;
                *) winetricks_early_wine winepath "$@" ;;
            esac
        ;;
    esac
}

# Expand an environment variable and print it to stdout
w_expand_env()
{
    winetricks_early_wine cmd.exe /c echo "%$1%"
}

# get sha1sum string and set $_W_gotsha1um to it
w_get_sha1sum()
{
    _W_sha1_file="$1"

    # See https://github.com/Winetricks/winetricks/issues/645
    # User is running winetricks from /dev/stdin
    if [ -f "$_W_sha1_file" ] || [ -h "$_W_sha1_file" ] ; then
        _W_gotsha1sum=$($WINETRICKS_SHA1SUM < "$_W_sha1_file" | sed 's/(stdin)= //;s/ .*//')
        w_get_sha256sum "$_W_sha1_file"
    else
        w_warn "$_W_sha1_file is not a regular file, not checking sha1sum"
        return
    fi

    w_warn "sha1sum is considered deprecated and should no longer be used. This package (${W_PACKAGE}) still uses it. This is a bug."
    w_warn "See https://github.com/Winetricks/winetricks/issues/737 and https://shattered.io/"
    w_warn "Please report the following to https://github.com/Winetricks/winetricks/: file:${_W_sha1_file} sha1: ${_W_gotsha1sum} sha256:${_W_gotsha256sum}"
}

# get sha256sum string and set $_W_gotsha256sum to it
w_get_sha256sum()
{
    _W_sha256_file="$1"

    # See https://github.com/Winetricks/winetricks/issues/645
    # User is running winetricks from /dev/stdin
    if [ -f "$_W_sha256_file" ] || [ -h "$_W_sha256_file" ] ; then
        _W_gotsha256sum=$($WINETRICKS_SHA256SUM < "$_W_sha256_file" | sed 's/(stdin)= //;s/ .*//')
    else
        w_warn "$_W_sha256_file is not a regular file, not checking sha256sum"
        return
    fi
}

w_get_shatype() {
    _W_sum="$1"

    # tr -d " " is for FreeBSD/OS X/Solaris return a leading space:
    # See https://stackoverflow.com/questions/30927590/wc-on-osx-return-includes-spaces/30927885#30927885
    _W_sum_length="$(echo "$_W_sum" | tr -d "\\n" | wc -c | tr -d " ")"
    case "$_W_sum_length" in
        0) _W_shatype="none" ;;
        40) _W_shatype="sha1" ;;
        64) _W_shatype="sha256" ;;
        # 128) sha512..
        *) w_die "unsupported shasum..bug" ;;
    esac
}

# FIXME: remove 2018/04/01 (or 03/31 or 4/2, to avoid April Fools comments), along with any remaining unfixed verbs
# verify a sha1sum
w_verify_sha1sum()
{
    _W_vs_wantsum=$1
    _W_vs_file=$2

    w_get_sha1sum "$_W_vs_file"
    if [ "$_W_gotsha1sum"x != "$_W_vs_wantsum"x ] ; then
        case $LANG in
            pl*) w_die "Niezgodność sumy sha1sum! Zmień nazwę $_W_vs_file i spróbuj ponownie." ;;
            ru*) w_die "Контрольная сумма sha1sum не совпадает! Переименуйте файл $_W_vs_file и попробуйте еще раз." ;;
            *) w_die "sha1sum mismatch! Rename $_W_vs_file and try again." ;;
        esac
    fi
    unset _W_vs_wantsum _W_vs_file _W_gotsha1sum
}

# verify a sha256sum
w_verify_sha256sum()
{
    _W_vs_wantsum=$1
    _W_vs_file=$2

    w_get_sha256sum "$_W_vs_file"
    if [ "$_W_gotsha256sum"x != "$_W_vs_wantsum"x ] ; then
        case $LANG in
            pl*) w_die "Niezgodność sumy sha256sum! Zmień nazwę $_W_vs_file i spróbuj ponownie." ;;
            ru*) w_die "Контрольная сумма sha256sum не совпадает! Переименуйте файл $_W_vs_file и попробуйте еще раз." ;;
            *) w_die "sha256sum mismatch! Rename $_W_vs_file and try again." ;;
        esac
    fi
    unset _W_vs_wantsum _W_vs_file _W_gotsha256sum
}

# verify any kind of shasum (that winetricks supports ;) ):
w_verify_shasum()
{
    _W_vs_wantsum="$1"
    _W_vs_file="$2"

    w_get_shatype "$_W_vs_wantsum"

    case "$_W_shatype" in
        none) w_warn "No checksum provided, not verifying" ;;
        sha1) w_verify_sha1sum "$_W_sum" "$_W_vs_file" ;;
        sha256) w_verify_sha256sum "$_W_sum" "$_W_vs_file" ;;
        # 128) sha512..
        *) w_die "unsupported shasum..bug" ;;
    esac
}

# wget outputs progress messages that look like this:
#      0K .......... .......... .......... .......... ..........  0%  823K 40s
# This function replaces each such line with the pair of lines
# 0%
# # Downloading... 823K (40s)
# It uses minimal buffering, so each line is output immediately
# and the user can watch progress as it happens.

# wrapper around wineserver, to let users know that it will wait indefinitely/kill stuff
w_wineserver()
{
    case "$@" in
        *-k) w_warn "Running $WINESERVER -k. This will kill all running wine processes in prefix=$WINEPREFIX";;
        *-w) w_warn "Running $WINESERVER -w. This will hang until all wine processes in prefix=$WINEPREFIX terminate";;
        *)   w_warn "Invoking wineserver with '$*'";;
    esac
    # shellcheck disable=SC2068
    "$WINESERVER" $@
}

winetricks_parse_wget_progress()
{
    # Parse a percentage, a size, and a time into $1, $2 and $3
    # then use them to create the output line.
    case $LANG in
        pl*) perl -p -e \
            '$| = 1; s/^.* +([0-9]+%) +([0-9,.]+[GMKB]) +([0-9hms,.]+).*$/\1\n# Pobieranie… \2 (\3)/' ;;
        ru*) perl -p -e \
            '$| = 1; s/^.* +([0-9]+%) +([0-9,.]+[GMKB]) +([0-9hms,.]+).*$/\1\n# Загрузка... \2 (\3)/' ;;
        *) perl -p -e \
            '$| = 1; s/^.* +([0-9]+%) +([0-9,.]+[GMKB]) +([0-9hms,.]+).*$/\1\n# Downloading... \2 (\3)/' ;;
    esac
}

# Execute wget, and if in GUI mode, also show a graphical progress bar
winetricks_wget_progress()
{
    case $WINETRICKS_GUI in
        zenity)
            # Use a subshell so if the user clicks 'Cancel',
            # the --auto-kill kills the subshell, not the current shell
            (
                ${torify} wget "$@" 2>&1 |
                winetricks_parse_wget_progress | \
                $WINETRICKS_GUI --progress --width 400 --title="$_W_file" --auto-kill --auto-close
            )
            err=$?
            if test $err -gt 128; then
                # 129 is 'killed by SIGHUP'
                # Sadly, --auto-kill only applies to parent process,
                # which was the subshell, not all the elements of the pipeline...
                # have to go find and kill the wget.
                # If we ran wget in the background, we could kill it more directly, perhaps...
                if pid=$(pgrep -f ."$_W_file"); then
                    echo User aborted download, killing wget
                    # shellcheck disable=SC2086
                    kill $pid
                fi
            fi
            return $err
            ;;
        *) ${torify} wget "$@" ;;
    esac
}

w_dotnet_verify()
{
    case "$1" in
        dotnet11) version="1.1" ;;
        dotnet11sp1) version="1.1 SP1" ;;
        dotnet20) version="2.0" ;;
        dotnet20sp1) version="2.0 SP1" ;;
        dotnet20sp2) version="2.0 SP2" ;;
        dotnet30) version="3.0" ;;
        dotnet30sp1) version="3.0 SP1" ;;
        dotnet35) version="3.5" ;;
        dotnet35sp1) version="3.5 SP1" ;;
        dotnet40) version="4 Client" ;;
        dotnet45) version="4.5" ;;
        dotnet452) version="4.5.2" ;;
        dotnet46) version="4.6" ;;
        dotnet461) version="4.6.1" ;;
        dotnet462) version="4.6.2" ;;
        dotnet472) version="4.7.2" ;;
        *) echo error ; exit 1 ;;
    esac
            w_call dotnet_verifier

            # FIXME: The logfile may be useful somewhere (or at least print the location)

            # for 'run, netfx_setupverifier.exe /q:a /c:"setupverifier2.exe"' line
            # shellcheck disable=SC2140
            w_ahk_do "
                SetTitleMatchMode, 2
                ; FIXME; this only works the first time? Check if it's already verified somehow..

                run, netfx_setupverifier.exe /q:a /c:"setupverifier2.exe"
                winwait, Verification Utility
                ControlClick, Button1
                Control, ChooseString, NET Framework $version, ComboBox1
                ControlClick, Button1 ; Verify
                loop, 60
                {
                    sleep 1000
                    process, exist, setupverifier2.exe
                    dn_pid=%ErrorLevel%
                    if dn_pid = 0
                    {
                        break
                    }
                    ifWinExist, Verification Utility, Product verification failed
                    {
                        process, close, setupverifier2.exe
                        exit 1
                    }
                    ifWinExist, Verification Utility, Product verification succeeded
                    {
                        process, close, setupverifier2.exe
                        break
                    }
                }
            "
            dn_status="$?"
            w_info ".Net Verifier returned $dn_status"
}

# Checks if the user can run the self-update/rollback commands
winetricks_check_update_availability()
{
    # Prevents the development file overwrite:
    if test -d "../.git"; then
        w_warn "You're running in a dev environment. Please make a copy of the file before running this command."
        exit
    fi

    # Checks read/write permissions on update directories
    if ! { test -r "$0" && test -w "$0" && test -w "${0%/*}" && test -x "${0%/*}"; }; then
        w_warn "You don't have the proper permissions to run this command. Try again with sudo or as root."
        exit
    fi
}

winetricks_selfupdate()
{
    winetricks_check_update_availability

    _W_filename="${0##*/}"
    _W_rollback_file="${0}.bak"
    _W_update_file="${0}.update"

    _W_tmpdir=${TMPDIR:-/tmp}
    _W_tmpdir="$(mktemp -d "$_W_tmpdir/$_W_filename.XXXXXXXX")"

    w_download_to "$_W_tmpdir" https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks

    # 2016/10/26: now file is uncompressed? Handle both cases:
    update_file_type="$(file "$_W_tmpdir/$_W_filename")"
    case "$update_file_type" in
        *"POSIX shell script"*)
            #echo "already decompressed!"
            w_try mv "$_W_tmpdir/$_W_filename" "${_W_update_file}"
            ;;
        *"gzip compressed data"*)
            w_try mv "$_W_tmpdir/$_W_filename" "${_W_update_file}.gz"
            w_try gunzip "${_W_update_file}.gz"
            ;;
        *)
            echo "Unknown file type: $update_file_type"
            exit 1
            ;;
    esac

    w_try rmdir "$_W_tmpdir"

    w_try cp "$0" "$_W_rollback_file"
    w_try chmod -x "$_W_rollback_file"

    w_try mv "$_W_update_file" "$0"
    w_try chmod +x "$0"

    w_warn "Update finished! The current version is $($0 -V). Use 'winetricks --update-rollback' to return to the previous version."

    exit
}

winetricks_selfupdate_rollback()
{
    winetricks_check_update_availability

    _W_rollback_file="${0}.bak"

    if test -f "$_W_rollback_file"; then
        w_try mv "$_W_rollback_file" "$0"
        w_try chmod +x "$0"
        w_warn "Rollback finished! The current version is $($0 -V)."
    else
        w_warn "Nothing to rollback."
    fi
    exit;
}

# Download a file
# Usage: w_download_to (packagename|path to download file) url [shasum [filename [cookie jar]]]
# Caches downloads in winetrickscache/$packagename
w_download_to()
{
    winetricks_download_setup

    _W_packagename="$1" # or path to download file to
    _W_url="$2"
    _W_sum="$3"
    _W_file="$4"
    _W_cookiejar="$5"

    case $_W_packagename in
        .) w_die "bug: please do not download packages to top of cache" ;;
    esac

    if echo "$_W_url" | grep ' ' ; then
        w_die "bug: please use %20 instead of literal spaces in urls, curl rejects spaces, and they make life harder for linkcheck.sh"
    fi
    if [ "$_W_file"x = ""x ] ; then
        _W_file=$(basename "$_W_url")
    fi

    w_get_shatype "$_W_sum"

    if echo "${_W_packagename}" | grep -q -e '\/-' -e '^-'; then
            w_die "Invalid path ${_W_packagename} given"
    else
        if ! echo "${_W_packagename}" | grep -q '^/' ; then
            _W_cache="$W_CACHE/$_W_packagename"
        else
            _W_cache="$_W_packagename"
        fi
    fi

    if test ! -d "$_W_cache" ; then
        w_try mkdir -p "$_W_cache"
    fi

    # Try download twice
    checksum_ok=""
    tries=0
    # Set olddir before entering the loop, otherwise second try will overwrite
    _W_dl_olddir=$(pwd)
    while test $tries -lt 2 ; do
        # Warn on a second try
        test "$tries" -eq 1 && winetricks_dl_warning
        tries=$((tries + 1))

        if test -s "$_W_cache/$_W_file" ; then
            if test "$_W_sum" ; then
                if test $tries = 1 ; then
                    # The cache was full.  If the file is larger than 500 MB,
                    # don't checksum it, that just annoys the user.
                    # shellcheck disable=SC2046
                    if test $(du -k "$_W_cache/$_W_file" | cut -f1) -gt 500000 ; then
                        checksum_ok=1
                        break
                    fi
                fi
                # If checksum matches, declare success and exit loop
                case "$_W_shatype" in
                    none)
                        w_warn "No checksum provided, not verifying"
                        ;;
                    sha1)
                        w_get_sha1sum "$_W_cache/$_W_file"
                        if [ "$_W_gotsha1sum"x = "$_W_sum"x ] ; then
                            checksum_ok=1
                            break
                        fi
                        ;;
                    sha256)
                        w_get_sha256sum "$_W_cache/$_W_file"
                        if [ "$_W_gotsha256sum"x = "$_W_sum"x ] ; then
                            checksum_ok=1
                            break
                        fi
                        ;;
                esac

                if test ! "$WINETRICKS_CONTINUE_DOWNLOAD" ; then
                    case $LANG in
                        pl*) w_warn "Niezgodność sum kontrolnych dla $_W_cache/$_W_file, pobieram ponownie" ;;
                        ru*) w_warn "Контрольная сумма файла $_W_cache/$_W_file не совпадает, попытка повторной загрузки" ;;
                        *) w_warn "Checksum for $_W_cache/$_W_file did not match, retrying download" ;;
                    esac
                    mv -f "$_W_cache/$_W_file" "$_W_cache/$_W_file".bak
                fi
            else
                # file exists, no checksum known, declare success and exit loop
                break
            fi
        elif test -f "$_W_cache/$_W_file" ; then
            # zero-length file, just delete before retrying
            rm "$_W_cache/$_W_file"
        fi

        w_try_cd "$_W_cache"
        # Mac folks tend to have curl rather than wget
        # On Mac, 'which' doesn't return good exit status
        echo "Downloading $_W_url to $_W_cache"

        # For sites that prefer Mozilla in the user-agent header, set W_BROWSERAGENT=1
        case "$W_BROWSERAGENT" in
            1) _W_agent="Mozilla/5.0 (compatible; Konqueror/2.1.1; X11)" ;;
            *) _W_agent="" ;;
        esac

        if [ "${WINETRICKS_DOWNLOADER}" = "aria2c" ] ; then
            # Note: aria2c wants = for most options or silently fails

            # (Slightly fancy) aria2c support
            # See https://github.com/Winetricks/winetricks/issues/612
            # --daemon=false --enable-rpc=false to ensure aria2c doesnt go into the background after starting
            #   and prevent any attempts to rebind on the RPC interface specified in someone's config.
            # --input-file='' if the user config has a input-file specified then aria2 will read it and
            #   attempt to download everything in that input file again.
            # --save-session='' if the user has specified save-session in their config, their session will be
            #   ovewritten by the new aria2 process

            # shellcheck disable=SC2086
            $torify aria2c \
                $aria2c_torify_opts \
                --connect-timeout="${WINETRICKS_DOWNLOADER_TIMEOUT}" \
                --continue \
                --daemon=false \
                --dir="$_W_cache" \
                --enable-rpc=false \
                --input-file='' \
                --max-connection-per-server=5 \
                --max-tries="$WINETRICKS_DOWNLOADER_RETRIES" \
                --out="$_W_file" \
                --save-session='' \
                --stream-piece-selector=geom \
                "$_W_url"
        elif [ "${WINETRICKS_DOWNLOADER}" = "wget" ] ; then
            # Use -nd to insulate ourselves from people who set -x in WGETRC
            # [*] --retry-connrefused works around the broken sf.net mirroring
            # system when downloading corefonts
            # [*] --read-timeout is useful on the adobe server that doesn't
            # close the connection unless you tell it to (control-C or closing
            # the socket)

            # shellcheck disable=SC2086
            winetricks_wget_progress \
                -O "$_W_file" \
                -nd \
                -c\
                --read-timeout 300 \
                --retry-connrefused \
                --timeout "${WINETRICKS_DOWNLOADER_TIMEOUT}" \
                --tries "$WINETRICKS_DOWNLOADER_RETRIES" \
                ${_W_cookiejar:+--load-cookies "$_W_cookiejar"} \
                ${_W_agent:+--user-agent="$_W_agent"} \
                "$_W_url"
        elif [ "${WINETRICKS_DOWNLOADER}" = "curl" ] ; then
            # Note: curl does not accept '=' when passing options
            # curl doesn't get filename from the location given by the server!
            # fortunately, we know it

            # shellcheck disable=SC2086
            $torify curl \
                --connect-timeout "${WINETRICKS_DOWNLOADER_TIMEOUT}" \
                -L \
                -o "$_W_file" \
                -C - \
                --retry "$WINETRICKS_DOWNLOADER_RETRIES" \
                ${_W_cookiejar:+--cookie "$_W_cookiejar"} \
                ${_W_agent:+--user-agent "$_W_agent"} \
                "$_W_url"
        elif [ "${WINETRICKS_DOWNLOADER}" = "fetch" ] ; then
            # Note: fetch does not support configurable retry count

            # shellcheck disable=SC2086
            $torify fetch \
                -T "${WINETRICKS_DOWNLOADER_TIMEOUT}" \
                -o "$_W_file" \
                ${_W_agent:+--user-agent="$_W_agent"} \
                "$_W_url"
        else
            w_die "Here be dragons"
        fi

        if test $? = 0; then
            # Need to decompress .exe's that are compressed, else Cygwin fails
            # Also affects ttf files on github
            # FIXME: gzip hack below may no longer be needed, but need to investigate before removing
            _W_filetype=$(command -v file 2>/dev/null)
            case $_W_filetype-$_W_file in
                /*-*.exe|/*-*.ttf|/*-*.zip)
                    case $(file "$_W_file") in
                        *:*gzip*) mv "$_W_file" "$_W_file.gz"; gunzip < "$_W_file.gz" > "$_W_file";;
                    esac
            esac

            # On Cygwin, .exe's must be marked +x
            case "$_W_file" in
                *.exe) chmod +x "$_W_file" ;;
            esac

            w_try_cd "$_W_dl_olddir"
            unset _W_dl_olddir

            # downloaded successfully, exit from loop
            break
        elif test $tries = 2; then
            test -f "$_W_file" && rm "$_W_file"
            w_die "Downloading $_W_url failed"
        fi
        # Download from the Wayback Machine on second try
        _W_url="https://web.archive.org/web/2000/$_W_url"
    done

    if test "$_W_sum" && test ! "$checksum_ok"; then
        w_verify_shasum "$_W_sum" "$_W_cache/$_W_file"
    fi
}

# Open a folder for the user in the specified directory
# Usage: w_open_folder directory
w_open_folder()
{
    for _W_cmd in xdg-open open cygstart true ; do
        _W_cmdpath=$(command -v $_W_cmd)
        if test -n "$_W_cmdpath" ; then
            break
        fi
    done
    $_W_cmd "$1" &
    unset _W_cmd _W_cmdpath
}

# Open a web browser for the user to the given page
# Usage: w_open_webpage url
w_open_webpage()
{
    # See https://www.dwheeler.com/essays/open-files-urls.html
    for _W_cmd in xdg-open sdtwebclient cygstart open firefox true ; do
        _W_cmdpath=$(command -v $_W_cmd)
        if test -n "$_W_cmdpath" ; then
            break
        fi
    done
    $_W_cmd "$1" &
    unset _W_cmd _W_cmdpath
}

# Download a file
# Usage: w_download url [shasum [filename [cookie jar]]]
# Caches downloads in winetrickscache/$W_PACKAGE
w_download()
{
    w_download_to "$W_PACKAGE" "$@"
}

# Download one or more files via BitTorrent
# Usage: w_download_torrent [foo.torrent]
# Caches downloads in $W_CACHE/$W_PACKAGE, torrent files are assumed to be there
# If no foo.torrent is given, will add ALL .torrent files in $W_CACHE/$W_PACKAGE
w_download_torrent()
{
    # FIXME: figure out how to extract the filename from the .torrent file
    # so callers don't need to check if the files are already downloaded.

    w_call utorrent

    UT_WINPATH="$W_CACHE_WIN\\$W_PACKAGE"
    w_try_cd "$W_CACHE/$W_PACKAGE"

    if [ "$2"x != ""x ] ; then # foo.torrent parameter supplied
        w_try "$WINE" utorrent "/DIRECTORY" "$UT_WINPATH" "$UT_WINPATH\\$2" &
    else # grab all torrents
        for torrent in *.torrent ; do
            w_try "$WINE" utorrent "/DIRECTORY" "$UT_WINPATH" "$UT_WINPATH\\$torrent" &
        done
    fi

    # Start uTorrent, have it wait until all downloads are finished
    w_ahk_do "
        SetTitleMatchMode, 2
        winwait, Torrent
        Loop
        {
            sleep 6000
            ifwinexist, Torrent, default
            {
                ;should uTorrent be the default torrent app?
                controlclick, Button1, Torrent, default  ; yes
                continue
            }
            ifwinexist, Torrent, already
            {
                ;torrent already registered, fine
                controlclick, Button1, Torrent, default  ; yes
                continue
            }
            ifwinexist, Torrent, Bandwidth
            {
                ;Cancels bandwidth test on first run of uTorrent
                controlclick, Button5, Torrent, Bandwidth
                continue
            }
            ifwinexist, Torrent, version
            {
                ;Decline upgrade to newer version
                controlclick, Button3, Torrent, version
                controlclick, Button2, Torrent, version
                continue
            }
            break
        }
        ;Sets parameter to close uTorrent once all downloads are complete
        winactivate, Torrent 2.0
        send !o
        send a{Down}{Enter}
        winwaitclose, Torrent 2.0
    "
}

w_download_manual_to()
{
    _W_packagename="$1"
    _W_url="$2"
    _W_file="$3"
    _W_shasum="$4"

    # shellcheck disable=SC2154
    case "$media" in
        "download") w_info "FAIL: bug: media type is download, but w_download_manual was called.  Programmer, please change verb's media type to manual_download." ;;
    esac

    if ! test -f "$W_CACHE/$_W_packagename/$_W_file"; then
        case $LANG in
            da*) _W_dlmsg="Hent venligst filen $_W_file fra $_W_url og placér den i $W_CACHE/$_W_packagename, kør derefter dette skript.";;
            de*) _W_dlmsg="Bitte laden Sie $_W_file von $_W_url runter, stellen Sie's in $W_CACHE/$_W_packagename, dann wiederholen Sie dieses Kommando.";;
            pl*) _W_dlmsg="Proszę pobrać plik $_W_file z $_W_url, następnie umieścić go w $W_CACHE/$_W_packagename, a na końcu uruchomić ponownie ten skrypt.";;
            ru*) _W_dlmsg="Пожалуйста, скачайте файл $_W_file по адресу $_W_url, и поместите его в $W_CACHE/$_W_packagename, а затем запустите winetricks заново.";;
            uk*) _W_dlmsg="Будь ласка, звантажте $_W_file з $_W_url, розташуйте в $W_CACHE/$_W_packagename, потім запустіть скрипт знову.";;
            zh_CN*) _W_dlmsg="请从 $_W_url 下载 $_W_file，并置放于 $W_CACHE/$_W_packagename, 然后重新运行 winetricks.";;
            zh_TW*|zh_HK*) _W_dlmsg="請從 $_W_url 下載 $_W_file，并置放於 $W_CACHE/$_W_packagename, 然后重新執行 winetricks.";;
            *) _W_dlmsg="Please download $_W_file from $_W_url, place it in $W_CACHE/$_W_packagename, then re-run this script.";;
        esac

        mkdir -p "$W_CACHE/$_W_packagename"
        w_open_folder "$W_CACHE/$_W_packagename"
        w_open_webpage "$_W_url"
        sleep 3   # give some time for web browser to open
        w_die "$_W_dlmsg"
        # FIXME: wait in loop until file is finished?
    fi

    if test "$_W_shasum"; then
        w_verify_shasum "$_W_shasum" "$W_CACHE/$_W_packagename/$_W_file"
    fi

    unset _W_dlmsg _W_file _W_sha1sum _W_sha256sum _W_url
}

w_download_manual()
{
    w_download_manual_to "$W_PACKAGE" "$@"
}

# Turn off news, overlays, and friend interaction in Steam
# Run from inside C:\Program Files\Steam
w_steam_safemode()
{
    cat > "$W_TMP/steamconfig.pl" <<"_EOF_"
#!/usr/bin/env perl
# Parse Steam's localconfig.vcf, add settings to it, and write it out again
# The file is a recursive dictionary
#
# FILE :== CONTAINER
#
# VALUE :== "name" "value" NEWLINE
#
# CONTAINER :== "name" NEWLINE "{" NEWLINE ( VALUE | CONTAINER ) * "}" NEWLINE
#
# We load it into a recursive hash.

use strict;
use warnings;

sub read_into_container{
    my( $pcontainer ) = @_;

    $_ = <FILE> || w_die "Can't read first line of container";
    /{/ || w_die "First line of container was not {";
    while (<FILE>) {
        chomp;
        if (/"([^"]*)"\s*"([^"]*)"$/) {
            ${$pcontainer}{$1} = $2;
        } elsif (/"([^"]*)"$/) {
            my( %newcon, $name );
            $name = $1;
            read_into_container(\%newcon);
            ${$pcontainer}{$name} = \%newcon;
        } elsif (/}/) {
            return;
        } else {
            w_die "huh?";
        }
    }
}

sub dump_container{
    my( $pcontainer, $indent ) = @_;
    foreach (sort(keys(%{$pcontainer}))) {
        my( $val ) = ${$pcontainer}{$_};
        if (ref $val eq 'HASH') {
            print "${indent}\"$_\"\n";
            print "${indent}{\n";
            dump_container($val, "$indent\t");
            print "${indent}}\n";
        } else {
            print "${indent}\"${_}\"\t\t\"$val\"\n";
        }
    }
}

# Disable anything unsafe or annoying
sub disable_notifications{
    my( $pcontainer ) = @_;
    ${$pcontainer}{"friends"}{"PersonaStateDesired"} = "1";
    ${$pcontainer}{"friends"}{"Notifications_ShowIngame"} = "0";
    ${$pcontainer}{"friends"}{"Sounds_PlayIngame"} = "0";
    ${$pcontainer}{"friends"}{"Notifications_ShowOnline"} = "0";
    ${$pcontainer}{"friends"}{"Sounds_PlayOnline"} = "0";
    ${$pcontainer}{"friends"}{"Notifications_ShowMessage"} = "0";
    ${$pcontainer}{"friends"}{"Sounds_PlayMessage"} = "0";
    ${$pcontainer}{"friends"}{"AutoSignIntoFriends"} = "0";
    ${$pcontainer}{"News"}{"NotifyAvailableGames"} = "0";
    ${$pcontainer}{"system"}{"EnableGameOverlay"} = "0";
}

# Read the file
my(%top);
open FILE, $ARGV[0] || w_die "cannot open ".$ARGV[0];
my($line);
$line = <FILE> || w_die "Could not read first line from ".$ARGV[0];
$line =~ /"UserLocalConfigStore"/ || w_die "this is not a localconfig.vdf file";
read_into_container(\%top);

# Modify it
disable_notifications(\%top);

# Write modified file
print "\"UserLocalConfigStore\"\n";
print "{\n";
dump_container(\%top, "\t");
print "}\n";
_EOF_

for file in userdata/*/config/localconfig.vdf ; do
    cp "$file" "$file.old"
    perl "$W_TMP"/steamconfig.pl "$file.old" > "$file"
done
}

w_question()
{
    case $WINETRICKS_GUI in
        *zenity) $WINETRICKS_GUI --entry --text "$1" ;;
        *kdialog) $WINETRICKS_GUI --inputbox "$1" ;;
        *xmessage) w_die "sorry, can't ask question with xmessage" ;;
        none)
            # Using printf instead of echo because we don't want a newline
            printf "%s" "$1" >&2 ;
            read -r W_ANSWER ;
            echo "$W_ANSWER";
            unset W_ANSWER;;
    esac
}

# Reads steam username and password from environment, cache, or user
# If had to ask user, cache answer.
w_steam_getid()
{
    #TODO: Translate
    _W_steamidmsg="Please enter your Steam login ID (not email)"
    _W_steampasswordmsg="Please enter your Steam password"

    if test ! "$W_STEAM_ID"; then
        if test -f "$W_CACHE"/steam_userid.txt; then
            W_STEAM_ID=$(cat "$W_CACHE"/steam_userid.txt)
        else
            W_STEAM_ID=$(w_question "$_W_steamidmsg")
            echo "$W_STEAM_ID" > "$W_CACHE"/steam_userid.txt
            chmod 600 "$W_CACHE"/steam_userid.txt
        fi
    fi
    if test ! "$W_STEAM_PASSWORD"; then
        if test -f "$W_CACHE"/steam_password.txt; then
            W_STEAM_PASSWORD=$(cat "$W_CACHE"/steam_password.txt)
        else
            W_STEAM_PASSWORD=$(w_question "$_W_steampasswordmsg")
            echo "$W_STEAM_PASSWORD" > "$W_CACHE"/steam_password.txt
            chmod 600 "$W_CACHE"/steam_password.txt
        fi
    fi
}

# Usage:
# w_steam_install_game steamidnum windowtitle
w_steam_install_game()
{
    _W_steamid=$1
    _W_steamtitle="$2"

    w_steam_getid

    # Install the steam runtime
    WINETRICKS_OPT_SHAREDPREFIX=1 w_call steam

    # Steam puts up a bunch of windows.  Here's the sequence:
    # "Steam - Updating" - wait for it to close.  May appear twice in a row.
    # "Steam - Login" - wait for it to close (credentials already given on cmdline)
    # "Steam" (small window) - connecting, wait for it to close
    # "Steam" (large window) - the main window
    # "Steam - Updates News" - close it forcefully
    # "Install - $title" - send enter, click a couple checkboxes, send enter again
    # "Updating $title" - small download progress dialog
    # "Steam - Ready" game install done.  (Only comes up if main window not up.)

    w_try_cd "$W_PROGRAMS_X86_UNIX/Steam"
    w_ahk_do "
        SetTitleMatchMode 2
        SetWinDelay 500
        ; Run steam once until it finishes its initial update.
        ; For me, this exits at 26%.
        run steam.exe -applaunch $_W_steamid -login $W_STEAM_ID $W_STEAM_PASSWORD
        Loop
        {
            ifWinExist, Steam - Updating
            {
                winwaitclose, Steam
                process close, Steam.exe
                sleep 1000
                ; Run a second time; let it finish updating, then kill it.
                run steam.exe
                winwait Steam - Updating
                winwaitclose
                process close, Steam.exe
                ; Run a third time, have it log in, wait until it has finished connecting
                run steam.exe -applaunch $_W_steamid -login $W_STEAM_ID $W_STEAM_PASSWORD
            }
            ifWinExist, Steam Login
            {
                break
            }
            sleep 500
        }
        ; wait for login window to close
        winwaitclose

        winwait Steam  ; wait for small <<connecting>> window
        winwaitclose
    "

if [ "$STEAM_DVD" = "TRUE" ]
then
    w_ahk_do "
        ; Run a fourth time, have it install the app.
        run steam.exe -install ${W_ISO_MOUNT_LETTER}:\\
    "
else
    w_ahk_do "
        ; Run a fourth time, have it install the app.
        run steam.exe -applaunch $_W_steamid
    "
fi

    w_ahk_do "
        winwait Install - $_W_steamtitle
        if ( w_opt_unattended > 0 ) {
            send {enter}          ; next (for 1st of 3 pages of install dialog)
            sleep 1000
            click 32, 91          ; uncheck create menu item?
            click 32, 119         ; check create desktop icon?
            send {enter}          ; next (for 2nd of 3 pages of install dialog)
            ; dismiss any news dialogs, and click 'next' on third page of install dialog
            loop
            {
                sleep 1000
                ifwinexist Steam - Updates News
                {
                    winclose
                    continue
                }
                ifwinexist Install - $_W_steamtitle
                {
                    winactivate
                    send {enter}      ; next (for 3rd of 3 pages of install dialog)
                }
                ifwinnotexist Install - $_W_steamtitle
                {
                    sleep 1000
                    ifwinnotexist Install - $_W_steamtitle
                        break
                }
            }
        }
    "

if [ "$STEAM_DVD" = "TRUE" ]
then
    # Wait for install to finish
    while true
    do
        grep "SetHasAllLocalContent(true) called for $_W_steamid" "$W_PROGRAMS_X86_UNIX/Steam/logs/download_log.txt" && break
        sleep 5
    done
fi

    w_ahk_do "
        ; For DVD's: theoretically, it should be installed now, but most games want to download updates. Do that now.
        ; For regular downloads: relaunch to coax steam into showing its nice small download progress dialog
        process close, Steam.exe
        run steam.exe -login $W_STEAM_ID $W_STEAM_PASSWORD -applaunch $_W_steamid
        winwait Ready -
        process close, Steam.exe
    "

    # Not all users need this disabled, but let's play it safe for now
    if w_workaround_wine_bug 22053 "Disabling in-game notifications to prevent game crashes on some machines."; then
        w_steam_safemode
    fi

    unset _W_steamid _W_steamtitle
}

#----------------------------------------------------------------

# Generic GOG.com installer
# Usage: game_id game_title [other_files,size [reader_control [run_command [download_id [install_dir [installer_size_and_sha1]]]]]]
# game_id
#     Used for main installer name and download url.
# game_title
#     Used for AutoHotKey and installation path in bat script.
# other_files
#     Extra installer files, in one string, space-separated.
# reader_control
#     If set, the control id of the configuration panel checkbox controlling
#     Adobe Reader installation.
#     Some games don't have it, some games do with different ids.
# run_command
#     Used for bat script, relative to installation path.
# download_id
#     For games which download url doesn't match their game_id
# install_dir
#     If different from game_title
# installer_size_and_sha1
#     exe file SHA1.
winetricks_load_gog()
{
    game_id="$1"
    game_title="$2"
    other_files="$3"
    reader_control="$4"
    # FIXME: actually unused, but not sure how it should be used
    # shellcheck disable=SC2034
    run_command="$5"
    download_id="$6"
    install_dir="$7"
    installer_size_and_sha1="$8"

    if [ "$download_id"x = ""x ]; then
        download_id="$game_id"
    fi
    if [ "$install_dir"x = ""x ]; then
        install_dir="$game_title"
    fi

    installer_path="$W_CACHE/$W_PACKAGE"
    mkdir -p "$installer_path"
    installer="setup_$game_id.exe"

    if test "$installer_size_and_sha1"x = ""x; then
        files="$installer $other_files"
    else
        files="$installer,$installer_size_and_sha1 $other_files"
    fi

    file_id=0
    for file_and_size_and_sha1 in $files
    do
        case "$file_and_size_and_sha1" in
            *,*,*)
                sha1sum=$(echo "$file_and_size_and_sha1" | sed "s/.*,//")
                minsize=$(echo "$file_and_size_and_sha1" | sed 's/[^,]*,\([^,]*\),.*/\1/')
                file=$(echo "$file_and_size_and_sha1" | sed 's/,.*//')
                ;;
            *,*)
                sha1sum=""
                minsize=$(echo "$file_and_size_and_sha1" | sed 's/.*,//')
                file=$(echo "$file_and_size_and_sha1" | sed 's/,.*//')
                ;;
            *)
                sha1sum=""
                minsize=1
                file=$file_and_size_and_sha1
                ;;
        esac
        file_path="$installer_path/$file"
        # shellcheck disable=SC2046
        if ! test -s "$file_path" || test $(stat -Lc%s "$file_path") -lt $minsize; then
            # FIXME: bring back automated download
            w_info "You have to be logged in to GOG, and you have to own the game, for the following URL to work.  Otherwise it gets a 404."
            w_download_manual "https://www.gog.com/en/download/game/$download_id/$file_id" "$file"
            check_sha1=1
            filesize=$(stat -Lc%s "$file_path")
            if test $minsize -gt 1 && test "$filesize" -ne $minsize; then
                check_sha1=""
                w_warn "Expected file size $minsize, please report new size $filesize."
            fi
            if test "$check_sha1" != "" && test "$sha1sum"x != ""x; then
                w_verify_sha1sum "$sha1sum" "$file_path"
            fi
        fi
        file_id=$((file_id + 1))
    done

    w_try_cd "$installer_path"
    w_ahk_do "
        run $installer
        WinWait, Setup - $game_title, Start installation
        ControlGet, checkbox_state, Checked,, TCheckBox1 ; EULA
        if (checkbox_state != 1) {
            ControlClick, TCheckBox1
        }
        if (\"$reader_control\") {
            ControlClick, TMCoPShadowButton1 ; Options
            Loop, 10
            {
                ControlGet, visible, Visible,, $reader_control
                if (visible)
                {
                    break
                }
                Sleep, 1000
            }
            ControlGet, checkbox_state, Checked,, $reader_control ; Unckeck Adobe/Foxit Reader
            if (checkbox_state != 0) {
                ControlClick, $reader_control
            }
        }
        ControlClick, TMCoPShadowButton2 ; Start Installation
        WinWait, Setup - $game_title, Exit Installer
        ControlClick, TMCoPShadowButton1 ; Exit Installer
        "
}

#----------------------------------------------------------------


# Usage: w_mount "volume name" [filename-to-check [discnum]]
# Some games have two volumes with identical volume names.
# For these, please specify discnum 1 for first disc, discnum 2 for 2nd, etc.,
# else caching can't work.
# FIXME: should take mount option 'unhide' for poorly mastered discs
w_mount()
{
    if test "$3"; then
        WINETRICKS_IMG="$W_CACHE/$W_PACKAGE/$1-$3.iso"
    else
        WINETRICKS_IMG="$W_CACHE/$W_PACKAGE/$1.iso"
    fi
    mkdir -p "$W_CACHE/$W_PACKAGE"

    if test -f "$WINETRICKS_IMG"; then
        winetricks_mount_cached_iso
    else
        if test "$WINETRICKS_OPT_KEEPISOS" = 0 || test "$2"; then
            while true
            do
                winetricks_mount_real_volume "$1"
                if test "$2" = "" || test -f "$W_ISO_MOUNT_ROOT/$2"; then
                    break
                else
                    w_warn "Wrong disc inserted, $2 not found."
                fi
            done
        fi

        case "$WINETRICKS_OPT_KEEPISOS" in
            1)
                winetricks_cache_iso "$1"
                winetricks_mount_cached_iso
                ;;
        esac
    fi
}

w_umount()
{
    if test "$WINE" = ""; then
        # Windows
        winetricks_load_vcdmount
        w_try_cd "$VCD_DIR"
        w_try vcdmount.exe /u
    else
        if test "$W_USE_USERMOUNT"; then
            # FUSE-based tools or hdiutil
            if test -d "$W_ISO_USER_MOUNT_ROOT"; then
                "$WINE" eject "${W_ISO_MOUNT_LETTER}:"
                cat > "$W_TMP"/unset_type_cdrom.reg <<_EOF_
REGEDIT4

[HKEY_LOCAL_MACHINE\\Software\\Wine\\Drives]
"${W_ISO_MOUNT_LETTER}:"=-
_EOF_
                w_try_regedit "$W_TMP"/unset_type_cdrom.reg
                rm -f "$WINEPREFIX/dosdevices/${W_ISO_MOUNT_LETTER}:"
                rm -f "$WINEPREFIX/dosdevices/${W_ISO_MOUNT_LETTER}::"

                case "$WINETRICKS_ISO_MOUNT" in
                    hdiutil)
                        "$WINETRICKS_ISO_MOUNT" detach "$W_ISO_USER_MOUNT_ROOT"
                        ;;
                    *)
                        # -uz lazy unmount in case executable still running
                        fusermount -uz "$W_ISO_USER_MOUNT_ROOT"
                        ;;
                esac
                w_try rmdir "$W_ISO_USER_MOUNT_ROOT"
            fi
            W_ISO_MOUNT_ROOT=/mnt/winetricks
        else
            # sudo + umount
            echo "Running $WINETRICKS_SUDO umount $W_ISO_MOUNT_ROOT"

            case "$WINETRICKS_SUDO" in
                gksu*|kdesudo)
                    # -l lazy unmount in case executable still running
                    "$WINETRICKS_SUDO" "umount -l $W_ISO_MOUNT_ROOT"
                    w_try "$WINETRICKS_SUDO" "rm -rf $W_ISO_MOUNT_ROOT"
                    ;;
                kdesu)
                    "$WINETRICKS_SUDO" -c "umount -l $W_ISO_MOUNT_ROOT"
                    w_try "$WINETRICKS_SUDO" -c "rm -rf $W_ISO_MOUNT_ROOT"
                    ;;
                *)
                    "$WINETRICKS_SUDO" umount -l "$W_ISO_MOUNT_ROOT"
                    w_try "$WINETRICKS_SUDO" rm -rf "$W_ISO_MOUNT_ROOT"
                    ;;
            esac

            "$WINE" eject "${W_ISO_MOUNT_LETTER}:"
            rm -f "$WINEPREFIX/dosdevices/${W_ISO_MOUNT_LETTER}:"
            rm -f "$WINEPREFIX/dosdevices/${W_ISO_MOUNT_LETTER}::"
        fi
    fi
}

w_ahk_do()
{
    if ! test -f "$W_CACHE/ahk/AutoHotkey.exe"; then
        w_download_to ahk https://github.com/AutoHotkey/AutoHotkey/releases/download/v1.0.48.05/AutoHotkey104805_Install.exe 4311c3e7c29ed2d67f415138360210bc2f55ff78758b20b003b91d775ee207b9
        w_try_7z "$W_CACHE/ahk" "$W_CACHE/ahk/AutoHotkey104805_Install.exe" AutoHotkey.exe AU3_Spy.exe
        chmod +x "$W_CACHE/ahk/AutoHotkey.exe"
    fi

    # Previously this used printf + sed, but that was broken with BSD sed (FreeBSD/OS X):
    # https://github.com/Winetricks/winetricks/issues/697
    # So now using trying awk instead (next, perl):
    cat <<_EOF_ | awk 'sub("$", "\r")' > "$W_TMP"/tmp.ahk
w_opt_unattended = ${W_OPT_UNATTENDED:-0}
$@
_EOF_
    w_try "$WINE" "$W_CACHE_WIN\\ahk\\AutoHotkey.exe" "$W_TMP_WIN"\\tmp.ahk
}

# Function to protect Wine-specific sections of code.
# Outputs a message to console explaining what's being skipped.
# Usage:
#   if w_skip_windows name-of-operation; then
#      return
#   fi
#   ... do something that doesn't make sense on Windows ...

w_skip_windows()
{
    case "$W_PLATFORM" in
        windows_cmd)
            echo "Skipping operation '$1' on Windows"
            return 0
            ;;
    esac
    return 1
}

# for common code in w_override_dlls and w_override_app_dlls
w_common_override_dll()
{
    _W_mode="$1"
    module="$2"

    # Remove wine's builtin manifest, if present. Use:
    # wineboot ; find "$WINEPREFIX"/drive_c/windows/winsxs/ -iname \*deadbeef.manifest | sort
    case "$W_PACKAGE" in
        comctl32)
            w_try rm -rf "$W_WINDIR_UNIX"/winsxs/manifests/amd64_microsoft.windows.common-controls_6595b64144ccf1df_6.0.2600.2982_none_deadbeef.manifest
            w_try rm -rf "$W_WINDIR_UNIX"/winsxs/manifests/x86_microsoft.windows.common-controls_6595b64144ccf1df_6.0.2600.2982_none_deadbeef.manifest
            ;;
        vcrun2005)
            w_try rm -rf "$W_WINDIR_UNIX"/winsxs/manifests/amd64_microsoft.vc80.atl_1fc8b3b9a1e18e3b_8.0.50727.4053_none_deadbeef.manifest
            w_try rm -rf "$W_WINDIR_UNIX"/winsxs/manifests/amd64_microsoft.vc80.crt_1fc8b3b9a1e18e3b_8.0.50727.4053_none_deadbeef.manifest
            w_try rm -rf "$W_WINDIR_UNIX"/winsxs/manifests/x86_microsoft.vc80.atl_1fc8b3b9a1e18e3b_8.0.50727.4053_none_deadbeef.manifest
            w_try rm -rf "$W_WINDIR_UNIX"/winsxs/manifests/x86_microsoft.vc80.crt_1fc8b3b9a1e18e3b_8.0.50727.4053_none_deadbeef.manifest

            # These are 32-bit only?
            w_try rm -rf "$W_WINDIR_UNIX"/winsxs/manifests/x86_microsoft.vc80.mfc_1fc8b3b9a1e18e3b_8.0.50727.6195_none_deadbeef.manifest
            w_try rm -rf "$W_WINDIR_UNIX"/winsxs/manifests/x86_microsoft.vc80.mfcloc_1fc8b3b9a1e18e3b_8.0.50727.6195_none_deadbeef.manifest
            w_try rm -rf "$W_WINDIR_UNIX"/winsxs/manifests/x86_microsoft.vc80.openmp_1fc8b3b9a1e18e3b_8.0.50727.6195_none_deadbeef.manifest
            ;;
        vcrun2008)
            w_try rm -rf "$W_WINDIR_UNIX"/winsxs/manifests/amd64_microsoft.vc90.atl_1fc8b3b9a1e18e3b_9.0.30729.6161_none_deadbeef.manifest
            w_try rm -rf "$W_WINDIR_UNIX"/winsxs/manifests/amd64_microsoft.vc90.crt_1fc8b3b9a1e18e3b_9.0.30729.6161_none_deadbeef.manifest
            w_try rm -rf "$W_WINDIR_UNIX"/winsxs/manifests/x86_microsoft.vc90.atl_1fc8b3b9a1e18e3b_9.0.30729.6161_none_deadbeef.manifest
            w_try rm -rf "$W_WINDIR_UNIX"/winsxs/manifests/x86_microsoft.vc90.crt_1fc8b3b9a1e18e3b_9.0.30729.6161_none_deadbeef.manifest

            # These are 32-bit only?
            w_try rm -rf "$W_WINDIR_UNIX"/winsxs/manifests/x86_microsoft.vc90.mfc_1fc8b3b9a1e18e3b_9.0.30729.6161_none_deadbeef.manifest
            w_try rm -rf "$W_WINDIR_UNIX"/winsxs/manifests/x86_microsoft.vc90.mfcloc_1fc8b3b9a1e18e3b_9.0.30729.6161_none_deadbeef.manifest
            w_try rm -rf "$W_WINDIR_UNIX"/winsxs/manifests/x86_microsoft.vc90.openmp_1fc8b3b9a1e18e3b_9.0.30729.6161_none_deadbeef.manifest
            ;;
    esac

    if [ "$_W_mode" = default ] ; then
        # To delete a registry key, give an unquoted dash as value
        echo "\"*$module\"=-" >> "$W_TMP"/override-dll.reg
    else
        # Note: if you want to override even DLLs loaded with an absolute
        # path, you need to add an asterisk:
        echo "\"*$module\"=\"$_W_mode\"" >> "$W_TMP"/override-dll.reg
    fi
}

w_override_dlls()
{
    w_skip_windows w_override_dlls && return

    _W_mode=$1
    case $_W_mode in
        *=*)
            w_die "w_override_dlls: unknown mode $_W_mode.
Usage: 'w_override_dlls mode[,mode] dll ...'." ;;
        disabled)
            _W_mode="" ;;
    esac

    shift

    echo "Using $_W_mode override for following DLLs: $*"
    cat > "$W_TMP"/override-dll.reg <<_EOF_
REGEDIT4

[HKEY_CURRENT_USER\\Software\\Wine\\DllOverrides]
_EOF_
    while test "$1" != ""
    do
        w_common_override_dll "$_W_mode" "$1"
        shift
    done

    w_try_regedit "$W_TMP_WIN"\\override-dll.reg

    unset _W_mode
}

w_override_no_dlls()
{
    w_skip_windows override && return

    "$WINE" regedit /d 'HKEY_CURRENT_USER\\Software\\Wine\\DllOverrides'
}

w_override_all_dlls()
{
    # Disable all known native Microsoft DLLs in favor of Wine's built-in ones
    # Generated with:
    # find ./dlls -maxdepth 1 -type d ! -iname "*.dll16" ! -iname "*.drv*" ! -iname "*.ds" ! -iname "*.exe*" ! -iname "*.tlb" ! -iname "*.vxd" -print | sed \
    #   -e '/^.*\/adsiid$/ d' \
    #   -e '/^.*\/advapi32$/ d' \
    #   -e '/^.*\/capi2032$/ d' \
    #   -e '/^.*\/dbghelp$/ d' \
    #   -e '/^.*\/ddraw$/ d' \
    #   -e '/^.*\/dlls$/ d' \
    #   -e '/^.*\/dmoguids$/ d' \
    #   -e '/^.*\/dxerr8$/ d' \
    #   -e '/^.*\/dxerr9$/ d' \
    #   -e '/^.*\/dxguid$/ d' \
    #   -e '/^.*\/gdi32$/ d' \
    #   -e '/^.*\/glu32$/ d' \
    #   -e '/^.*\/icmp$/ d' \
    #   -e '/^.*\/iphlpapi$/ d' \
    #   -e '/^.*\/kernel32$/ d' \
    #   -e '/^.*\/l3codeca.acm$/ d' \
    #   -e '/^.*\/mfuuid$/ d' \
    #   -e '/^.*\/mountmgr.sys$/ d' \
    #   -e '/^.*\/mswsock$/ d' \
    #   -e '/^.*\/ntdll$/ d' \
    #   -e '/^.*\/opengl32$/ d' \
    #   -e '/^.*\/secur32$/ d' \
    #   -e '/^.*\/strmbase$/ d' \
    #   -e '/^.*\/strmiids$/ d' \
    #   -e '/^.*\/twain_32$/ d' \
    #   -e '/^.*\/unicows$/ d' \
    #   -e '/^.*\/user32$/ d' \
    #   -e '/^.*\/uuid$/ d' \
    #   -e '/^.*\/vdmdbg$/ d' \
    #   -e '/^.*\/w32skrnl$/ d' \
    #   -e '/^.*\/winecrt0$/ d' \
    #   -e '/^.*\/wined3d$/ d' \
    #   -e '/^.*\/winemp3.acm$/ d' \
    #   -e '/^.*\/wineqtdecoder$/ d' \
    #   -e '/^.*\/winmm$/ d' \
    #   -e '/^.*\/wintab32$/ d' \
    #   -e '/^.*\/wmcodecdspuuid$/ d' \
    #   -e '/^.*\/wnaspi32$/ d' \
    #   -e '/^.*\/wow32$/ d' \
    #   -e '/^.*\/ws2_32$/ d' \
    #   -e '/^.*\/wsock32$/ d' \
    #   -e 's,.*/,        ,' | sort | fmt -63 | sed 's/$/ \\/'
    #
    # 2018-12-10: Last list update (wine-4.0-rc1)
    w_override_dlls builtin \
        acledit aclui activeds actxprxy adsldp adsldpc advpack \
        amstream api-ms-win-appmodel-identity-l1-1-0 \
        api-ms-win-appmodel-runtime-l1-1-1 \
        api-ms-win-appmodel-runtime-l1-1-2 \
        api-ms-win-core-apiquery-l1-1-0 \
        api-ms-win-core-appcompat-l1-1-1 \
        api-ms-win-core-appinit-l1-1-0 \
        api-ms-win-core-atoms-l1-1-0 \
        api-ms-win-core-bem-l1-1-0 api-ms-win-core-com-l1-1-0 \
        api-ms-win-core-com-l1-1-1 api-ms-win-core-comm-l1-1-0 \
        api-ms-win-core-com-private-l1-1-0 \
        api-ms-win-core-console-l1-1-0 \
        api-ms-win-core-console-l2-1-0 \
        api-ms-win-core-crt-l1-1-0 api-ms-win-core-crt-l2-1-0 \
        api-ms-win-core-datetime-l1-1-0 \
        api-ms-win-core-datetime-l1-1-1 \
        api-ms-win-core-debug-l1-1-0 \
        api-ms-win-core-debug-l1-1-1 \
        api-ms-win-core-delayload-l1-1-0 \
        api-ms-win-core-delayload-l1-1-1 \
        api-ms-win-core-errorhandling-l1-1-0 \
        api-ms-win-core-errorhandling-l1-1-1 \
        api-ms-win-core-errorhandling-l1-1-2 \
        api-ms-win-core-errorhandling-l1-1-3 \
        api-ms-win-core-fibers-l1-1-0 \
        api-ms-win-core-fibers-l1-1-1 \
        api-ms-win-core-file-l1-1-0 \
        api-ms-win-core-file-l1-2-0 \
        api-ms-win-core-file-l1-2-1 \
        api-ms-win-core-file-l1-2-2 \
        api-ms-win-core-file-l2-1-0 \
        api-ms-win-core-file-l2-1-1 \
        api-ms-win-core-file-l2-1-2 \
        api-ms-win-core-handle-l1-1-0 \
        api-ms-win-core-heap-l1-1-0 \
        api-ms-win-core-heap-l1-2-0 \
        api-ms-win-core-heap-l2-1-0 \
        api-ms-win-core-heap-obsolete-l1-1-0 \
        api-ms-win-core-interlocked-l1-1-0 \
        api-ms-win-core-interlocked-l1-2-0 \
        api-ms-win-core-io-l1-1-0 api-ms-win-core-io-l1-1-1 \
        api-ms-win-core-job-l1-1-0 api-ms-win-core-job-l2-1-0 \
        api-ms-win-core-kernel32-legacy-l1-1-0 \
        api-ms-win-core-kernel32-legacy-l1-1-1 \
        api-ms-win-core-kernel32-private-l1-1-1 \
        api-ms-win-core-largeinteger-l1-1-0 \
        api-ms-win-core-libraryloader-l1-1-0 \
        api-ms-win-core-libraryloader-l1-1-1 \
        api-ms-win-core-libraryloader-l1-2-0 \
        api-ms-win-core-libraryloader-l1-2-1 \
        api-ms-win-core-libraryloader-l1-2-2 \
        api-ms-win-core-localization-l1-1-0 \
        api-ms-win-core-localization-l1-2-0 \
        api-ms-win-core-localization-l1-2-1 \
        api-ms-win-core-localization-l2-1-0 \
        api-ms-win-core-localization-obsolete-l1-1-0 \
        api-ms-win-core-localization-obsolete-l1-2-0 \
        api-ms-win-core-localization-obsolete-l1-3-0 \
        api-ms-win-core-localization-private-l1-1-0 \
        api-ms-win-core-localregistry-l1-1-0 \
        api-ms-win-core-memory-l1-1-0 \
        api-ms-win-core-memory-l1-1-1 \
        api-ms-win-core-memory-l1-1-2 \
        api-ms-win-core-misc-l1-1-0 \
        api-ms-win-core-namedpipe-l1-1-0 \
        api-ms-win-core-namedpipe-l1-2-0 \
        api-ms-win-core-namespace-l1-1-0 \
        api-ms-win-core-normalization-l1-1-0 \
        api-ms-win-core-path-l1-1-0 \
        api-ms-win-core-privateprofile-l1-1-1 \
        api-ms-win-core-processenvironment-l1-1-0 \
        api-ms-win-core-processenvironment-l1-2-0 \
        api-ms-win-core-processthreads-l1-1-0 \
        api-ms-win-core-processthreads-l1-1-1 \
        api-ms-win-core-processthreads-l1-1-2 \
        api-ms-win-core-processthreads-l1-1-3 \
        api-ms-win-core-processtopology-obsolete-l1-1-0 \
        api-ms-win-core-profile-l1-1-0 \
        api-ms-win-core-psapi-ansi-l1-1-0 \
        api-ms-win-core-psapi-l1-1-0 \
        api-ms-win-core-psapi-obsolete-l1-1-0 \
        api-ms-win-core-quirks-l1-1-0 \
        api-ms-win-core-realtime-l1-1-0 \
        api-ms-win-core-registry-l1-1-0 \
        api-ms-win-core-registry-l2-1-0 \
        api-ms-win-core-registryuserspecific-l1-1-0 \
        api-ms-win-core-rtlsupport-l1-1-0 \
        api-ms-win-core-rtlsupport-l1-2-0 \
        api-ms-win-core-shlwapi-legacy-l1-1-0 \
        api-ms-win-core-shlwapi-obsolete-l1-1-0 \
        api-ms-win-core-shlwapi-obsolete-l1-2-0 \
        api-ms-win-core-shutdown-l1-1-0 \
        api-ms-win-core-sidebyside-l1-1-0 \
        api-ms-win-core-stringansi-l1-1-0 \
        api-ms-win-core-string-l1-1-0 \
        api-ms-win-core-string-l2-1-0 \
        api-ms-win-core-stringloader-l1-1-1 \
        api-ms-win-core-string-obsolete-l1-1-0 \
        api-ms-win-core-synch-ansi-l1-1-0 \
        api-ms-win-core-synch-l1-1-0 \
        api-ms-win-core-synch-l1-2-0 \
        api-ms-win-core-synch-l1-2-1 \
        api-ms-win-core-sysinfo-l1-1-0 \
        api-ms-win-core-sysinfo-l1-2-0 \
        api-ms-win-core-sysinfo-l1-2-1 \
        api-ms-win-core-threadpool-l1-1-0 \
        api-ms-win-core-threadpool-l1-2-0 \
        api-ms-win-core-threadpool-legacy-l1-1-0 \
        api-ms-win-core-threadpool-private-l1-1-0 \
        api-ms-win-core-timezone-l1-1-0 \
        api-ms-win-core-toolhelp-l1-1-0 \
        api-ms-win-core-url-l1-1-0 api-ms-win-core-util-l1-1-0 \
        api-ms-win-core-versionansi-l1-1-0 \
        api-ms-win-core-version-l1-1-0 \
        api-ms-win-core-version-l1-1-1 \
        api-ms-win-core-version-private-l1-1-0 \
        api-ms-win-core-windowserrorreporting-l1-1-0 \
        api-ms-win-core-winrt-error-l1-1-0 \
        api-ms-win-core-winrt-error-l1-1-1 \
        api-ms-win-core-winrt-errorprivate-l1-1-1 \
        api-ms-win-core-winrt-l1-1-0 \
        api-ms-win-core-winrt-registration-l1-1-0 \
        api-ms-win-core-winrt-roparameterizediid-l1-1-0 \
        api-ms-win-core-winrt-string-l1-1-0 \
        api-ms-win-core-winrt-string-l1-1-1 \
        api-ms-win-core-wow64-l1-1-0 \
        api-ms-win-core-wow64-l1-1-1 \
        api-ms-win-core-xstate-l1-1-0 \
        api-ms-win-core-xstate-l2-1-0 \
        api-ms-win-crt-conio-l1-1-0 \
        api-ms-win-crt-convert-l1-1-0 \
        api-ms-win-crt-environment-l1-1-0 \
        api-ms-win-crt-filesystem-l1-1-0 \
        api-ms-win-crt-heap-l1-1-0 \
        api-ms-win-crt-locale-l1-1-0 \
        api-ms-win-crt-math-l1-1-0 \
        api-ms-win-crt-multibyte-l1-1-0 \
        api-ms-win-crt-private-l1-1-0 \
        api-ms-win-crt-process-l1-1-0 \
        api-ms-win-crt-runtime-l1-1-0 \
        api-ms-win-crt-stdio-l1-1-0 \
        api-ms-win-crt-string-l1-1-0 \
        api-ms-win-crt-time-l1-1-0 \
        api-ms-win-crt-utility-l1-1-0 \
        api-ms-win-devices-config-l1-1-0 \
        api-ms-win-devices-config-l1-1-1 \
        api-ms-win-devices-query-l1-1-1 \
        api-ms-win-downlevel-advapi32-l1-1-0 \
        api-ms-win-downlevel-advapi32-l2-1-0 \
        api-ms-win-downlevel-normaliz-l1-1-0 \
        api-ms-win-downlevel-ole32-l1-1-0 \
        api-ms-win-downlevel-shell32-l1-1-0 \
        api-ms-win-downlevel-shlwapi-l1-1-0 \
        api-ms-win-downlevel-shlwapi-l2-1-0 \
        api-ms-win-downlevel-user32-l1-1-0 \
        api-ms-win-downlevel-version-l1-1-0 \
        api-ms-win-dx-d3dkmt-l1-1-0 \
        api-ms-win-eventing-classicprovider-l1-1-0 \
        api-ms-win-eventing-consumer-l1-1-0 \
        api-ms-win-eventing-controller-l1-1-0 \
        api-ms-win-eventing-legacy-l1-1-0 \
        api-ms-win-eventing-provider-l1-1-0 \
        api-ms-win-eventlog-legacy-l1-1-0 \
        api-ms-win-gdi-dpiinfo-l1-1-0 \
        api-ms-win-mm-joystick-l1-1-0 \
        api-ms-win-mm-misc-l1-1-1 api-ms-win-mm-mme-l1-1-0 \
        api-ms-win-mm-time-l1-1-0 \
        api-ms-win-ntuser-dc-access-l1-1-0 \
        api-ms-win-ntuser-rectangle-l1-1-0 \
        api-ms-win-ntuser-sysparams-l1-1-0 \
        api-ms-win-perf-legacy-l1-1-0 \
        api-ms-win-power-base-l1-1-0 \
        api-ms-win-power-setting-l1-1-0 \
        api-ms-win-rtcore-ntuser-draw-l1-1-0 \
        api-ms-win-rtcore-ntuser-private-l1-1-0 \
        api-ms-win-rtcore-ntuser-private-l1-1-4 \
        api-ms-win-rtcore-ntuser-window-l1-1-0 \
        api-ms-win-rtcore-ntuser-winevent-l1-1-0 \
        api-ms-win-rtcore-ntuser-wmpointer-l1-1-0 \
        api-ms-win-rtcore-ntuser-wmpointer-l1-1-3 \
        api-ms-win-security-activedirectoryclient-l1-1-0 \
        api-ms-win-security-audit-l1-1-1 \
        api-ms-win-security-base-l1-1-0 \
        api-ms-win-security-base-l1-2-0 \
        api-ms-win-security-base-private-l1-1-1 \
        api-ms-win-security-credentials-l1-1-0 \
        api-ms-win-security-cryptoapi-l1-1-0 \
        api-ms-win-security-grouppolicy-l1-1-0 \
        api-ms-win-security-lsalookup-l1-1-0 \
        api-ms-win-security-lsalookup-l1-1-1 \
        api-ms-win-security-lsalookup-l2-1-0 \
        api-ms-win-security-lsalookup-l2-1-1 \
        api-ms-win-security-lsapolicy-l1-1-0 \
        api-ms-win-security-provider-l1-1-0 \
        api-ms-win-security-sddl-l1-1-0 \
        api-ms-win-security-systemfunctions-l1-1-0 \
        api-ms-win-service-core-l1-1-0 \
        api-ms-win-service-core-l1-1-1 \
        api-ms-win-service-management-l1-1-0 \
        api-ms-win-service-management-l2-1-0 \
        api-ms-win-service-private-l1-1-1 \
        api-ms-win-service-winsvc-l1-1-0 \
        api-ms-win-service-winsvc-l1-2-0 \
        api-ms-win-shcore-obsolete-l1-1-0 \
        api-ms-win-shcore-scaling-l1-1-1 \
        api-ms-win-shcore-stream-l1-1-0 \
        api-ms-win-shcore-thread-l1-1-0 \
        api-ms-win-shell-shellcom-l1-1-0 \
        api-ms-win-shell-shellfolders-l1-1-0 apphelp \
        appwiz.cpl atl atl100 atl110 atl80 atl90 atmlib \
        authz avicap32 avifil32 avrt bcrypt bluetoothapis \
        browseui bthprops.cpl cabinet cards cdosys cfgmgr32 \
        clusapi combase comcat comctl32 comdlg32 compstui \
        comsvcs concrt140 connect credui crtdll crypt32 \
        cryptdlg cryptdll cryptext cryptnet cryptui ctapi32 \
        ctl3d32 d2d1 d3d10 d3d10_1 d3d10core d3d11 d3d12 d3d8 \
        d3d9 d3dcompiler_33 d3dcompiler_34 d3dcompiler_35 \
        d3dcompiler_36 d3dcompiler_37 d3dcompiler_38 \
        d3dcompiler_39 d3dcompiler_40 d3dcompiler_41 \
        d3dcompiler_42 d3dcompiler_43 d3dcompiler_46 \
        d3dcompiler_47 d3dim d3drm d3dx10_33 d3dx10_34 \
        d3dx10_35 d3dx10_36 d3dx10_37 d3dx10_38 d3dx10_39 \
        d3dx10_40 d3dx10_41 d3dx10_42 d3dx10_43 d3dx11_42 \
        d3dx11_43 d3dx9_24 d3dx9_25 d3dx9_26 d3dx9_27 \
        d3dx9_28 d3dx9_29 d3dx9_30 d3dx9_31 d3dx9_32 d3dx9_33 \
        d3dx9_34 d3dx9_35 d3dx9_36 d3dx9_37 d3dx9_38 d3dx9_39 \
        d3dx9_40 d3dx9_41 d3dx9_42 d3dx9_43 d3dxof davclnt \
        dbgeng dciman32 ddrawex devenum dhcpcsvc dhtmled.ocx \
        difxapi dinput dinput8 dispex dmband dmcompos dmime \
        dmloader dmscript dmstyle dmsynth dmusic dmusic32 \
        dnsapi dplay dplayx dpnaddr dpnet dpnhpast dpnlobby \
        dpvoice dpwsockx drmclien dsound dsquery dssenh \
        dswave dwmapi dwrite dx8vb dxdiagn dxgi dxva2 esent \
        evr explorerframe ext-ms-win-authz-context-l1-1-0 \
        ext-ms-win-domainjoin-netjoin-l1-1-0 \
        ext-ms-win-dwmapi-ext-l1-1-0 \
        ext-ms-win-gdi-dc-create-l1-1-1 \
        ext-ms-win-gdi-dc-l1-2-0 ext-ms-win-gdi-devcaps-l1-1-0 \
        ext-ms-win-gdi-draw-l1-1-1 \
        ext-ms-win-gdi-render-l1-1-0 \
        ext-ms-win-kernel32-package-current-l1-1-0 \
        ext-ms-win-kernel32-package-l1-1-1 \
        ext-ms-win-ntuser-draw-l1-1-0 \
        ext-ms-win-ntuser-gui-l1-3-0 \
        ext-ms-win-ntuser-keyboard-l1-3-0 \
        ext-ms-win-ntuser-message-l1-1-1 \
        ext-ms-win-ntuser-misc-l1-2-0 \
        ext-ms-win-ntuser-misc-l1-5-1 \
        ext-ms-win-ntuser-mouse-l1-1-0 \
        ext-ms-win-ntuser-private-l1-1-1 \
        ext-ms-win-ntuser-private-l1-3-1 \
        ext-ms-win-ntuser-rectangle-ext-l1-1-0 \
        ext-ms-win-ntuser-uicontext-ext-l1-1-0 \
        ext-ms-win-ntuser-windowclass-l1-1-1 \
        ext-ms-win-ntuser-window-l1-1-1 \
        ext-ms-win-ntuser-window-l1-1-4 \
        ext-ms-win-oleacc-l1-1-0 \
        ext-ms-win-ras-rasapi32-l1-1-0 \
        ext-ms-win-rtcore-gdi-devcaps-l1-1-0 \
        ext-ms-win-rtcore-gdi-object-l1-1-0 \
        ext-ms-win-rtcore-gdi-rgn-l1-1-0 \
        ext-ms-win-rtcore-ntuser-cursor-l1-1-0 \
        ext-ms-win-rtcore-ntuser-dc-access-l1-1-0 \
        ext-ms-win-rtcore-ntuser-dpi-l1-1-0 \
        ext-ms-win-rtcore-ntuser-dpi-l1-2-0 \
        ext-ms-win-rtcore-ntuser-rawinput-l1-1-0 \
        ext-ms-win-rtcore-ntuser-syscolors-l1-1-0 \
        ext-ms-win-rtcore-ntuser-sysparams-l1-1-0 \
        ext-ms-win-security-credui-l1-1-0 \
        ext-ms-win-security-cryptui-l1-1-0 \
        ext-ms-win-uxtheme-themes-l1-1-0 faultrep feclient \
        fltlib fltmgr.sys fntcache fontsub fusion fwpuclnt \
        gameux gdiplus gpkcsp hal hhctrl.ocx hid hidclass.sys \
        hlink hnetcfg httpapi iccvid ieframe ieproxy \
        imaadp32.acm imagehlp imm32 inetcomm inetcpl.cpl \
        inetmib1 infosoft initpki inkobj inseng iprop \
        irprops.cpl itircl itss joy.cpl jscript jsproxy \
        kerberos kernelbase ksuser ktmw32 loadperf localspl \
        localui lz32 mapi32 mapistub mciavi32 mcicda mciqtz32 \
        mciseq mciwave mf mf3216 mfplat mfreadwrite mgmtapi \
        midimap mlang mmcndmgr mmdevapi mp3dmod mpr mprapi \
        msacm32 msadp32.acm msasn1 mscat32 mscms mscoree \
        msctf msctfp msdaps msdelta msdmo msdrm msftedit \
        msg711.acm msgsm32.acm mshtml msi msident msimg32 \
        msimsg msimtf msisip msisys.ocx msls31 msnet32 \
        mspatcha msports msrle32 msscript.ocx mssign32 \
        mssip32 mstask msvcirt msvcm80 msvcm90 msvcp100 \
        msvcp110 msvcp120 msvcp120_app msvcp140 msvcp60 \
        msvcp70 msvcp71 msvcp80 msvcp90 msvcr100 msvcr110 \
        msvcr120 msvcr120_app msvcr70 msvcr71 msvcr80 \
        msvcr90 msvcrt msvcrt20 msvcrt40 msvcrtd msvfw32 \
        msvidc32 msxml msxml2 msxml3 msxml4 msxml6 mtxdm \
        ncrypt nddeapi ndis.sys netapi32 netcfgx netprofm \
        newdev ninput normaliz npmshtml npptools ntdsapi \
        ntprint objsel odbc32 odbccp32 odbccu32 ole32 oleacc \
        oleaut32 olecli32 oledb32 oledlg olepro32 olesvr32 \
        olethk32 opcservices openal32 opencl packager pdh \
        photometadatahandler pidgen powrprof printui prntvpt \
        propsys psapi pstorec qcap qedit qmgr qmgrprxy \
        quartz query qwave rasapi32 rasdlg regapi resutils \
        riched20 riched32 rpcrt4 rsabase rsaenh rstrtmgr \
        rtutils samlib sapi sas scarddlg sccbase schannel \
        schedsvc scrobj scrrun scsiport.sys security sensapi \
        serialui setupapi sfc sfc_os shcore shdoclc shdocvw \
        shell32 shfolder shlwapi slbcsp slc snmpapi softpub \
        spoolss srclient sspicli sti strmdll svrapi sxs \
        t2embed tapi32 taskschd tdh tdi.sys traffic tzres \
        ucrtbase uiautomationcore uiribbon updspapi url \
        urlmon usbd.sys userenv usp10 uxtheme vbscript \
        vcomp vcomp100 vcomp110 vcomp120 vcomp140 vcomp90 \
        vcruntime140 version virtdisk vssapi vulkan-1 wbemdisp \
        wbemprox wdscore webservices wer wevtapi wiaservc \
        wimgapi windowscodecs windowscodecsext winebus.sys \
        winegstreamer winehid.sys winemapi winevulkan wing32 \
        winhttp wininet winnls32 winscard winsta wintrust \
        winusb wlanapi wldap32 wmasf wmi wmiutils wmp wmphoto \
        wmvcore wpc wpcap wsdapi wshom.ocx wsnmp32 wtsapi32 \
        wuapi wuaueng x3daudio1_0 x3daudio1_1 x3daudio1_2 \
        x3daudio1_3 x3daudio1_4 x3daudio1_5 x3daudio1_6 \
        x3daudio1_7 xapofx1_1 xapofx1_2 xapofx1_3 xapofx1_4 \
        xapofx1_5 xaudio2_0 xaudio2_1 xaudio2_2 xaudio2_3 \
        xaudio2_4 xaudio2_5 xaudio2_6 xaudio2_7 xaudio2_8 \
        xaudio2_9 xinput1_1 xinput1_2 xinput1_3 xinput1_4 \
        xinput9_1_0 xmllite xolehlp xpsprint xpssvcs \

        # blank line so you don't have to remove the extra trailing \
}

w_override_app_dlls()
{
    w_skip_windows w_override_app_dlls && return

    _W_app=$1
    shift
    _W_mode=$1
    shift

    # Fixme: handle comma-separated list of modes
    case $_W_mode in
        b|builtin) _W_mode=builtin ;;
        n|native) _W_mode=native ;;
        default) _W_mode=default ;;
        d|disabled) _W_mode="" ;;
        *)
        w_die "w_override_app_dlls: unknown mode $_W_mode.  (want native, builtin, default, or disabled)
Usage: 'w_override_app_dlls app mode dll ...'." ;;
    esac

    echo "Using $_W_mode override for following DLLs when running $_W_app: $*"
    (
        echo REGEDIT4
        echo ""
        echo "[HKEY_CURRENT_USER\\Software\\Wine\\AppDefaults\\$_W_app\\DllOverrides]"
    ) > "$W_TMP"/override-dll.reg

    while test "$1" != ""
    do
        w_common_override_dll "$_W_mode" "$1"
        shift
    done

    w_try_regedit "$W_TMP_WIN"\\override-dll.reg
    w_try rm "$W_TMP"/override-dll.reg
    unset _W_app _W_mode
}

# Has to be set in a few places...
w_set_winver()
{
    w_skip_windows w_set_winver && return
    # FIXME: This should really be done with winecfg, but it has no CLI options.
    # Wine-Bug: https://bugs.winehq.org/show_bug.cgi?id=45616

    # First, delete any lingering version info, otherwise it may conflict:
    (
    "$WINE" reg delete "HKLM\\Software\\Microsoft\\Windows\\CurrentVersion" /v SubVersionNumber /f || true
    "$WINE" reg delete "HKLM\\Software\\Microsoft\\Windows\\CurrentVersion" /v VersionNumber /f || true
    "$WINE" reg delete "HKLM\\Software\\Microsoft\\Windows NT\\CurrentVersion" /v CSDVersion /f || true
    "$WINE" reg delete "HKLM\\Software\\Microsoft\\Windows NT\\CurrentVersion" /v CurrentBuildNumber /f || true
    "$WINE" reg delete "HKLM\\Software\\Microsoft\\Windows NT\\CurrentVersion" /v CurrentVersion /f || true
    "$WINE" reg delete "HKLM\\System\\CurrentControlSet\\Control\\ProductOptions" /v ProductType /f || true
    "$WINE" reg delete "HKLM\\System\\CurrentControlSet\\Control\\ServiceCurrent" /v OS /f || true
    "$WINE" reg delete "HKLM\\System\\CurrentControlSet\\Control\\Windows" /v CSDVersion /f || true
    "$WINE" reg delete "HKCU\\Software\\Wine" /v Version /f || true
    "$WINE" reg delete "HKLM\\System\\CurrentControlSet\\Control\\ProductOptions" /v ProductType /f || true
    ) > /dev/null 2>&1

    case "$1" in
        win31)
            echo "Setting Windows version to $1"
            cat > "$W_TMP"/set-winver.reg <<_EOF_
REGEDIT4

[HKEY_USERS\\S-1-5-4\\Software\\Wine]
"Version"="win31"

_EOF_
            w_try_regedit "$W_TMP_WIN"\\set-winver.reg
            return
            ;;
        win95)
            # This key is only used for Windows 95/98:

            echo "Setting Windows version to $1"
            cat > "$W_TMP"/set-winver.reg <<_EOF_
REGEDIT4

[HKEY_LOCAL_MACHINE\\Software\\Microsoft\\Windows\\CurrentVersion]
"ProductName"="Microsoft Windows 95"
"SubVersionNumber"=""
"VersionNumber"="4.0.950"

_EOF_
            w_try_regedit "$W_TMP_WIN"\\set-winver.reg
            return
            ;;
        win98)
            # This key is only used for Windows 95/98:

            echo "Setting Windows version to $1"
            cat > "$W_TMP"/set-winver.reg <<_EOF_
REGEDIT4

[HKEY_LOCAL_MACHINE\\Software\\Microsoft\\Windows\\CurrentVersion]
"ProductName"="Microsoft Windows 98"
"SubVersionNumber"=" A "
"VersionNumber"="4.10.2222"

_EOF_
            w_try_regedit "$W_TMP_WIN"\\set-winver.reg
            return
            ;;
        nt40)
            # Similar to modern version, but sets two extra keys:

            echo "Setting Windows version to $1"
            cat > "$W_TMP"/set-winver.reg <<_EOF_
REGEDIT4

[HKEY_LOCAL_MACHINE\\Software\\Microsoft\\Windows NT\\CurrentVersion]
"CSDVersion"="Service Pack 6a"
"CurrentBuildNumber"="1381"
"CurrentVersion"="4.0"

[HKEY_LOCAL_MACHINE\\System\\CurrentControlSet\\Control\\ProductOptions]
"ProductType"="WinNT"

[HKEY_LOCAL_MACHINE\\System\\CurrentControlSet\\Control\\ServiceCurrent]
"OS"="Windows_NT"

[HKEY_LOCAL_MACHINE\\System\\CurrentControlSet\\Control\\Windows]
"CSDVersion"=dword:00000600

_EOF_
            w_try_regedit "$W_TMP_WIN"\\set-winver.reg
            return
            ;;
        win2k)
            csdversion="Service Pack 4"
            currentbuildnumber="2195"
            currentversion="5.0"
            csdversion_hex=dword:00000400
            ;;
        winxp)
            # Special case, afaik it's the only Windows version that has different version numbers for 32/64-bit
            # So ensure we set the arch appropriate version:
            if [ "$W_ARCH" = "win32" ]; then
                csdversion="Service Pack 3"
                currentbuildnumber="2600"
                currentversion="5.1"
                csdversion_hex=dword:00000300
            elif [ "$W_ARCH" = "win64" ]; then
                csdversion="Service Pack 2"
                currentbuildnumber="3790"
                currentversion="5.2"
                csdversion_hex=dword:00000200
                "$WINE" reg add "HKLM\\System\\CurrentControlSet\\Control\\ProductOptions" /v ProductType /d "WinNT" /f
            else
                w_die "Invalid W_ARCH $W_ARCH"
            fi
            ;;
        win2k3)
            csdversion="Service Pack 2"
            currentbuildnumber="3790"
            currentversion="5.2"
            csdversion_hex=dword:00000200
            "$WINE" reg add "HKLM\\System\\CurrentControlSet\\Control\\ProductOptions" /v ProductType /d "ServerNT" /f
            ;;
        vista)
            csdversion="Service Pack 2"
            currentbuildnumber="6002"
            currentversion="6.0"
            csdversion_hex=dword:00000200
            "$WINE" reg add "HKLM\\System\\CurrentControlSet\\Control\\ProductOptions" /v ProductType /d "WinNT" /f
            ;;
        win7)
            csdversion="Service Pack 1"
            currentbuildnumber="7601"
            currentversion="6.1"
            csdversion_hex=dword:00000100
            "$WINE" reg add "HKLM\\System\\CurrentControlSet\\Control\\ProductOptions" /v ProductType /d "WinNT" /f
            ;;
        win2k8)
            csdversion="Service Pack 1"
            currentbuildnumber="7601"
            currentversion="6.1"
            csdversion_hex=dword:00000100
            "$WINE" reg add "HKLM\\System\\CurrentControlSet\\Control\\ProductOptions" /v ProductType /d "ServerNT" /f
            ;;
        win8)
            csdversion=""
            currentbuildnumber="9200"
            currentversion="6.2"
            csdversion_hex=dword:00000000
            "$WINE" reg add "HKLM\\System\\CurrentControlSet\\Control\\ProductOptions" /v ProductType /d "WinNT" /f
            ;;
        win81)
            csdversion=""
            currentbuildnumber="9600"
            currentversion="6.3"
            csdversion_hex=dword:00000000
            "$WINE" reg add "HKLM\\System\\CurrentControlSet\\Control\\ProductOptions" /v ProductType /d "WinNT" /f
            ;;
        win10)
            csdversion=""
            currentbuildnumber="10240"
            currentversion="10.0"
            csdversion_hex=dword:00000000
            "$WINE" reg add "HKLM\\System\\CurrentControlSet\\Control\\ProductOptions" /v ProductType /d "WinNT" /f
            ;;
        *)
            w_die "Invalid Windows version given."
            ;;
    esac

    echo "Setting Windows version to $1"
    cat > "$W_TMP"/set-winver.reg <<_EOF_
REGEDIT4

[HKEY_LOCAL_MACHINE\\Software\\Microsoft\\Windows NT\\CurrentVersion]
"CSDVersion"="$csdversion"
"CurrentBuildNumber"="$currentbuildnumber"
"CurrentVersion"="$currentversion"

[HKEY_LOCAL_MACHINE\\System\\CurrentControlSet\\Control\\Windows]
"CSDVersion"=$csdversion_hex

_EOF_
    w_try_regedit "$W_TMP_WIN"\\set-winver.reg

    # Prevent a race when calling from another verb
    w_wineserver -w
}

w_unset_winver()
{
    w_set_winver winxp
}

# Present app $1 with the Windows personality $2
w_set_app_winver()
{
    w_skip_windows w_set_app_winver && return

    _W_app="$1"
    _W_version="$2"
    echo "Setting $_W_app to $_W_version mode"
    (
    echo REGEDIT4
    echo ""
    echo "[HKEY_CURRENT_USER\\Software\\Wine\\AppDefaults\\$_W_app]"
    echo "\"Version\"=\"$_W_version\""
    ) > "$W_TMP"/set-winver.reg

    w_try_regedit "$W_TMP_WIN"\\set-winver.reg
    rm "$W_TMP"/set-winver.reg
    unset _W_app
}

# Usage: w_compare_wine_version OP VALUE
# Note: currently only -ge and -le are supported,
#       as well as the special case -bn (between)
# Example:
#  if w_compare_wine_version -gt 2.5 ; then
#      ...
#  fi
w_compare_wine_version()
{
    comparison="$1"
    known_wine_val1="$2"
    known_wine_val2="$3"

    case "$comparison" in
        # expected value if the comparison is true
        -bn) _expected_pos_current_wine="2";;
        -ge) _expected_pos_current_wine="2";;
        -le) _expected_pos_current_wine="1";;
        *) w_die "Unsupported comparison. Only -ge and -le are supported" ;;
    esac

    _pos_current_wine="$(printf "%s\\n%s\\n%s" "${known_wine_val1}" "${_wine_version_stripped}" "${known_wine_val2}" | sort -t. -k 1,1n -k 2,2n -k 3,3n | grep -n "^${_wine_version_stripped}\$" | cut -d : -f1)"
    if [ "$_pos_current_wine" = "$_expected_pos_current_wine" ] ; then
        #echo "true: known_wine_version=$2, comparison=$1, stripped wine=$_wine_version_stripped, expected_pos=$_expected_pos_known, pos_known=$_pos_known_wine"
        #echo "Wine version comparison is true"
        return 1
    else
        #echo "false: known_wine_version=$2, comparison=$1, stripped wine=$_wine_version_stripped, expected_pos=$_expected_pos_known, pos_known=$_pos_known_wine"
        #echo "Wine version comparison is false"
        return 0
    fi
}

# Usage: w_wine_version_in range ...
# True if wine version in any of the given ranges
# 'range' can be
#    val1,   (for >= val1)
#    ,val2   (for <= val2)
#    val1,val2 (for >= val1 && <= val2)
w_wine_version_in()
{
    for _W_range
    do
        _W_val1=$(echo "$_W_range" | sed 's/,.*//')
        _W_val2=$(echo "$_W_range" | sed 's/.*,//')
        # If in this range, return true
        case $_W_range in
            ,*) w_compare_wine_version -le "$_W_val2"            && unset _W_range _W_val1 _W_val2 && return 0;;
            *,) w_compare_wine_version -ge "$_W_val1"            && unset _W_range _W_val1 _W_val2 && return 0;;
            *)  w_compare_wine_version -bn "$_W_val1" "$_W_val2" && unset _W_range _W_val1 _W_val2 && return 0;;
        esac
    done
    unset _W_range _W_val1 _W_val2
    return 1
}

# Usage: workaround_wine_bug bugnumber [message] [good-wine-version-range ...]
# Returns true and outputs given msg if the workaround needs to be applied.
# For debugging: if you want to skip a bug's workaround, put the bug number in
# the environment variable WINETRICKS_BLACKLIST to disable it.
w_workaround_wine_bug()
{
    if test "$WINE" = ""; then
        echo "No need to work around wine bug $1 on Windows"
        return 1
    fi
    case "$2" in
        [0-9]*) w_die "bug: want message in w_workaround_wine_bug arg 2, got $2" ;;
        "") _W_msg="";;
        *)  _W_msg="-- $2";;
    esac

    # shellcheck disable=SC2086
    if test "$3" && w_wine_version_in $3 $4 $5 $6; then
        echo "Current Wine does not have Wine bug $1, so not applying workaround"
        return 1
    fi

    case "$1" in
        "$WINETRICKS_BLACKLIST")
            echo "Wine bug $1 workaround blacklisted, skipping"
            return 1
            ;;
    esac

    case $LANG in
        da*) w_warn "Arbejder uden om wine-fejl ${1} $_W_msg" ;;
        de*) w_warn "Wine-Fehler ${1} wird umgegangen $_W_msg" ;;
        pl*) w_warn "Obchodzenie błędu w wine ${1} $_W_msg" ;;
        ru*) w_warn "Обход ошибки ${1} $_W_msg" ;;
        uk*) w_warn "Обхід помилки ${1} $_W_msg" ;;
        zh_CN*)   w_warn "绕过 wine bug ${1} $_W_msg" ;;
        zh_TW*|zh_HK*)   w_warn "繞過 wine bug ${1} $_W_msg" ;;
        *)   w_warn "Working around wine bug ${1} $_W_msg" ;;
    esac

    winetricks_stats_log_command "w_workaround_wine_bug-$1"
    return 0
}

# Function for verbs to register themselves so they show up in the menu.
# Example:
# w_metadata wog games \
#   title="World of Goo Demo" \
#   pub="2D Boy" \
#   year="2008" \
#   media="download" \
#   file1="WorldOfGooDemo.1.0.exe"

w_metadata()
{
    case $WINETRICKS_OPT_VERBOSE in
        2) set -x ;;
        *) set +x ;;
    esac

    # shellcheck disable=SC2154
    if test "$installed_exe1" || test "$installed_file1" || test "$publisher" || test "$year"; then
        w_die "bug: stray metadata tags set: somebody forgot a backslash in a w_metadata somewhere.  Run with sh -x to see where."
    fi
    if winetricks_metadata_exists "$1"; then
        w_die "bug: a verb named $1 already exists."
    fi

    _W_md_cmd="$1"
    _W_category="$2"
    file="$WINETRICKS_METADATA/$_W_category/$1.vars"
    shift
    shift
    # Echo arguments to file, with double quotes around the values.
    # Used to use Perl here, but that was too slow on Cygwin.
    for arg
    do
        case "$arg" in
            installed_exe1=/*) w_die "bug: w_metadata $_W_md_cmd has a unix path for installed_exe1, should be a windows path";;
            installed_file1=/*) w_die "bug: w_metadata $_W_md_cmd has a unix path for installed_file1, should be a windows path";;
            media=download_manual) w_die "bug: verb $_W_md_cmd has media=download_manual, should be manual_download" ;;
        esac
        # Use longest match when stripping value,
        # and shortest match when stripping name,
        # so descriptions can have embedded equals signs
        # FIXME: backslashes get interpreted here.  This screws up
        # installed_file1 fairly often.  Fortunately, we can use forward
        # slashes in that variable instead of backslashes.
        echo "${arg%%=*}"=\""${arg#*=}"\"
    done > "$file"
    echo category='"'"$_W_category"'"' >> "$file"
    # If the problem described above happens, you'd see errors like this:
    # /tmp/w.dank.4650/metadata/dlls/comctl32.vars: 6: Syntax error: Unterminated quoted string
    # so check for lines that aren't properly quoted.

    # Do sanity check unless running on Cygwin, where it's way too slow.
    case "$W_PLATFORM" in
        windows_cmd)
            ;;
        *)
            if grep '[^"]$' "$file"; then
                w_die "bug: w_metadata $_W_md_cmd corrupt, might need forward slashes?"
            fi
            ;;
    esac
    unset _W_md_cmd

    # Restore verbosity:
    case $WINETRICKS_OPT_VERBOSE in
        1|2) set -x ;;
        *) set +x ;;
    esac
}

# Function for verbs to register their main executable [or, if name is given, other executables]
# Deprecated. No-op for backwards compatibility
w_declare_exe()
{
    w_warn "w_declare_exe is deprecated, now a noop"
}

# Checks that a conflicting verb is not already installed in the prefix
# Usage: w_conflicts verb_to_install conflicting_verbs
w_conflicts()
{
    verb="$1"
    conflicting_verbs="$2"

    for x in $conflicting_verbs
    do
        if grep -qw "$x" "$WINEPREFIX/winetricks.log" 2>/dev/null; then
            w_die "error: $verb conflicts with $x, which is already installed. You can run \`$0 --force $verb\` to ignore this check and attempt installation."
        fi
    done
}

# Call a verb, don't let it affect environment
# Hope that subshell passes through exit status
# Usage: w_do_call foo [bar]       (calls load_foo bar)
# Or: w_do_call foo=bar            (also calls load_foo bar)
# Or: w_do_call foo                (calls load_foo)
w_do_call()
{
    (
        # Hack..
        if test "$cmd" = vd; then
            load_vd "$arg"
            _W_status=$?
            test "$W_OPT_NOCLEAN" = 1 || rm -rf "$W_TMP"
            mkdir -p "$W_TMP"
            return $_W_status
        fi

        case "$1" in
            *=*) arg=$(echo "$1" | sed 's/.*=//'); cmd=$(echo "$1" | sed 's/=.*//');;
            *) cmd=$1; arg=$2 ;;
        esac

        # Kludge: use Temp instead of temp to avoid \t expansion in w_try
        # but use temp in Unix path because that's what Wine creates, and having both temp and Temp
        # causes confusion (e.g. makes vc2005trial fail)
        # FIXME: W_TMP is also set in winetricks_set_wineprefix, can we avoid the duplication?
        W_TMP="$W_DRIVE_C/windows/temp/_$1"
        W_TMP_WIN="C:\\windows\\Temp\\_$1"
        test "$W_OPT_NOCLEAN" = 1 || rm -rf "$W_TMP"
        mkdir -p "$W_TMP"

        # Unset all known used metadata values, in case this is a nested call
        unset conflicts installed_file1 installed_exe1

        if winetricks_metadata_exists "$1"; then
            # shellcheck disable=SC1090
            . "$WINETRICKS_METADATA"/*/"${1}.vars"
        elif winetricks_metadata_exists "$cmd"; then
            # shellcheck disable=SC1090
            . "$WINETRICKS_METADATA"/*/"${cmd}.vars"
        elif test "$cmd" = native || test "$cmd" = disabled || test "$cmd" = builtin || test "$cmd" = default; then
            # ugly special case - can't have metadata for these verbs until we allow arbitrary parameters
            w_override_dlls "$cmd" "$arg"
            _W_status=$?
            test "$W_OPT_NOCLEAN" = 1 || rm -rf "$W_TMP"
            mkdir -p "$W_TMP"
            return $_W_status
        else
            w_die "No such verb $1"
        fi

        # If needed, set the app's wineprefix
        case "$W_PLATFORM" in
            windows_cmd|wine_cmd) ;;
            *)
                # shellcheck disable=SC2154
                case "${category}-${WINETRICKS_OPT_SHAREDPREFIX}" in
                    apps-0|benchmarks-0|games-0)
                        winetricks_set_wineprefix "$cmd"
                        # If it's a new wineprefix, give it metadata
                        if test ! -f "$WINEPREFIX"/wrapper.cfg; then
                            echo ww_name=\""$title"\" > "$WINEPREFIX"/wrapper.cfg
                        fi
                        ;;
                esac
            ;;
        esac

        test "$W_OPT_NOCLEAN" = 1 || rm -rf "$W_TMP"
        mkdir -p "$W_TMP"

        # Don't install if a conflicting verb is already installed:
        # shellcheck disable=SC2154
        if test "$WINETRICKS_FORCE" != 1 && test "$conflicts" && test -f "$WINEPREFIX/winetricks.log"; then
            for x in $conflicts
            do
                w_conflicts "$1" "$x"
            done
        fi

        # Don't install if already installed
        if test "$WINETRICKS_FORCE" != 1 && winetricks_is_installed "$1"; then
            echo "$1 already installed, skipping"
            return 0
        fi

        # We'd like to get rid of W_PACKAGE, but for now, just set it as late as possible.
        W_PACKAGE=$1
        w_try "load_$cmd" "$arg"
        winetricks_stats_log_command "$@"

        # User-specific postinstall hook.
        # Source it so the script can call w_download() if needed.
        postfile="$WINETRICKS_POST/$1/$1-postinstall.sh"
        if test -f "$postfile"; then
            chmod +x "$postfile"
            # shellcheck disable=SC1090
            . "$postfile"
        fi

        # Verify install
        if test "$installed_exe1" || test "$installed_file1"; then
            if ! winetricks_is_installed "$1"; then
                w_die "$1 install completed, but installed file $_W_file_unix not found"
            fi
        fi

        # If the user specified --verify, also run GUI tests:
        if test "$WINETRICKS_VERIFY" = 1; then
            # command -v isn't POSIX :(
            "verify_$cmd" 2>/dev/null
            verify_status=$?
            case $verify_status in
                0) w_warn "verify_$cmd succeeded!" ;;
                127) echo "verify_$cmd not found, not verifying $cmd" ;;
                *) w_die "verify_$cmd failed!" ;;
            esac
        fi

        # Clean up after this verb
        test "$W_OPT_NOCLEAN" = 1 || rm -rf "$W_TMP"
        mkdir -p "$W_TMP"

        # Reset whether use of user mount tool
        unset W_USE_USERMOUNT

        # Calling subshell must explicitly propagate error code with exit $?
    ) || exit $?
}

# If you want to check exit status yourself, use w_do_call
w_call()
{
    w_try w_do_call "$@"
}

w_backup_reg_file()
{
    W_reg_file=$1

    w_get_sha256sum "$W_reg_file"

    w_try cp "$W_reg_file" "$W_TMP_EARLY/_reg_$(echo "$_W_gotsha256sum" | cut -c1-8)"_$$.reg

    unset W_reg_file _W_gotsha256sum
}

w_register_font()
{
    W_file=$1
    shift
    W_font=$1

    case $(echo "$W_file" | tr "[:upper:]" "[:lower:]") in
        *.ttf|*.ttc) W_font="$W_font (TrueType)";;
    esac

    # Kludge: use _r to avoid \r expansion in w_try
    cat > "$W_TMP"/_register-font.reg <<_EOF_
REGEDIT4

[HKEY_LOCAL_MACHINE\\Software\\Microsoft\\Windows NT\\CurrentVersion\\Fonts]
"$W_font"="$W_file"
_EOF_
    # too verbose
    w_try_regedit "$W_TMP_WIN"\\_register-font.reg
    w_backup_reg_file "$W_TMP"/_register-font.reg

    # Wine also updates the win9x fonts key, so let's do that, too
    cat > "$W_TMP"/_register-font.reg <<_EOF_
REGEDIT4

[HKEY_LOCAL_MACHINE\\Software\\Microsoft\\Windows\\CurrentVersion\\Fonts]
"$W_font"="$W_file"
_EOF_
    w_try_regedit "$W_TMP_WIN"\\_register-font.reg
    w_backup_reg_file "$W_TMP"/_register-font.reg

    unset W_file W_font
}

w_register_font_replacement()
{
    _W_alias=$1
    shift
    _W_font=$1
    # Kludge: use _r to avoid \r expansion in w_try
    cat > "$W_TMP"/_register-font-replacements.reg <<_EOF_
REGEDIT4

[HKEY_CURRENT_USER\\Software\\Wine\\Fonts\\Replacements]
"$_W_alias"="$_W_font"
_EOF_
    w_try_regedit "$W_TMP_WIN"\\_register-font-replacements.reg

    w_backup_reg_file "$W_TMP"/_register-font-replacements.reg

    unset _W_alias _W_font
}

w_append_path()
{
    # Prepend $1 to the Windows path in the registry.
    # Use printf %s to avoid interpreting backslashes.
    # 2/4 backslashes, not 4/8, see https://github.com/Winetricks/winetricks/issues/932
    _W_NEW_PATH="$(printf %s "$1" | sed 's,\\,\\\\,g')"
    _W_WIN_PATH="$(w_expand_env PATH | sed 's,\\,\\\\,g')"

    # FIXME: OS X? https://github.com/Winetricks/winetricks/issues/697
    sed 's/$/\r/' > "$W_TMP"/path.reg <<_EOF_
REGEDIT4

[HKEY_LOCAL_MACHINE\\System\\CurrentControlSet\\Control\\Session Manager\\Environment]
"PATH"="$_W_NEW_PATH;$_W_WIN_PATH"
_EOF_

    w_try_regedit "$W_TMP_WIN"\\path.reg
    rm -f "$W_TMP"/path.reg
    unset _W_NEW_PATH _W_WIN_PATH
}

#---- Private Functions ----

# Determines downloader to use, etc.
# I.e., things common to w_download_to(), winetricks_download_to_stdout(), and winetricks_stats_report())
winetricks_download_setup()
{
    # shellcheck disable=SC2104
    case "${WINETRICKS_DOWNLOADER}" in
        aria2c|curl|wget|fetch) : ;;
        "") if [ -x "$(command -v aria2c 2>/dev/null)" ] ; then
                WINETRICKS_DOWNLOADER="aria2c"
            elif [ -x "$(command -v wget 2>/dev/null)" ] ; then
                WINETRICKS_DOWNLOADER="wget"
            elif [ -x "$(command -v curl 2>/dev/null)" ] ; then
                WINETRICKS_DOWNLOADER="curl"
            elif [ -x "$(command -v fetch 2>/dev/null)" ] ; then
                WINETRICKS_DOWNLOADER="fetch"
            else
                w_die "Please install wget or aria2c (or, if those aren't available, curl)"
            fi
            ;;
        *) w_die "Invalid value ${WINETRICKS_DOWNLOADER} given for WINETRICKS_DOWNLOADER. Possible values: aria2c, curl, wget, fetch"
    esac

    # Common values for aria2c/curl/fetch/wget
    # Number of retry attempts (not supported by fetch):
    WINETRICKS_DOWNLOADER_RETRIES=${WINETRICKS_DOWNLOADER_RETRIES:-3}
    # Connection timeout time (in seconds):
    WINETRICKS_DOWNLOADER_TIMEOUT=${WINETRICKS_DOWNLOADER_TIMEOUT:-15}

    case "$WINETRICKS_OPT_TORIFY" in
        1) torify=torify
            # torify needs --async-dns=false, see https://github.com/tatsuhiro-t/aria2/issues/613
            aria2c_torify_opts="--async-dns=false"
            if [ ! -x "$(command -v torify 2>/dev/null)" ]; then
                w_die "--torify was used, but torify is not installed, please install it." ; exit 1
            fi ;;
        *) torify=
            aria2c_torify_opts="" ;;
    esac
}


winetricks_dl_url_to_stdout()
{
    winetricks_download_setup

    # Not using w_try here as it adds extra output, breaking things.
    # FIXME: add a w_try_quiet() wrapper around w_try() that doesn't print the
    # Executing ... stuff, but still does error checking
    if [ "${WINETRICKS_DOWNLOADER}" = "wget" ] ; then
        $torify wget -q -O - --timeout "${WINETRICKS_DOWNLOADER_TIMEOUT}" \
            --tries "$WINETRICKS_DOWNLOADER_RETRIES" "$1"
    elif [ "${WINETRICKS_DOWNLOADER}" = "curl" ] ; then
        $torify curl -s --connect-timeout "${WINETRICKS_DOWNLOADER_TIMEOUT}" \
               --retry "$WINETRICKS_DOWNLOADER_RETRIES" "$1"
    elif [ "${WINETRICKS_DOWNLOADER}" = "aria2c" ] ; then
        # aria2c doesn't have support downloading to stdout:
        # https://github.com/aria2/aria2/issues/190
        # So instead, download to a temporary directory and cat the file:
        stdout_tmpfile="${W_TMP_EARLY}/stdout.tmp"

        if [ -e "${stdout_tmpfile}" ] ; then
            rm "${stdout_tmpfile}"
        fi
                $torify aria2c \
                $aria2c_torify_opts \
                --continue \
                --daemon=false \
                --dir="${W_TMP_EARLY}" \
                --enable-rpc=false \
                --input-file='' \
                --max-connection-per-server=5 \
                --out="stdout.tmp" \
                --save-session='' \
                --stream-piece-selector=geom \
                --connect-timeout="${WINETRICKS_DOWNLOADER_TIMEOUT}" \
                --max-tries="$WINETRICKS_DOWNLOADER_RETRIES" \
                "$1" > /dev/null
        cat "${stdout_tmpfile}"
        rm "${stdout_tmpfile}"
    elif [ "${WINETRICKS_DOWNLOADER}" = "fetch" ] ; then
        # fetch does not support retry count
        $torify fetch -o - -T "${WINETRICKS_DOWNLOADER_TIMEOUT}" "$1" 2>/dev/null
    else
        w_die "Please install aria2c, curl, or wget"
    fi
}

winetricks_dl_warning() {
    case $LANG in
        ru*) _W_countrymsg="Скрипт определил, что ваш IP-адрес принадлежит России. Если во время загрузки файлов вы увидите ошибки несоответствия сертификата, перезапустите скрипт с опцией '--torify' или скачайте файлы вручную, например, используя VPN." ;;
        pl*) _W_countrymsg="Wykryto, że twój adres IP należy do Rosji. W wypadku problemów z pobieraniem, uruchom z parametrem '--torify' lub pobierz plik manualnie, np. z użyciem VPN." ;;
        *)  _W_countrymsg="Your IP address has been determined to belong to Russia. If you encounter a certificate error while downloading, please relaunch with the '--torify' option, or download files manually, for instance using VPN." ;;
    esac

    # Lookup own country via IP address only once (i.e. don't run this function for every download invocation)
    if [ -z "$W_COUNTRY" ] ; then
        W_COUNTRY="$(winetricks_dl_url_to_stdout "https://ipinfo.io/$(winetricks_dl_url_to_stdout "https://ipinfo.io/ip")" | awk -F '"' '/country/{print $4}')"
        export W_COUNTRY

        if [ -z "$W_COUNTRY" ] ; then
            export W_COUNTRY="unknown"
        fi
    fi

    # TODO: Resolve a full country name via https://github.com/umpirsky/country-list/tree/master/data
    case "$W_COUNTRY" in
        "RU") w_warn "$_W_countrymsg" ;;
        *) : ;;
    esac
}

winetricks_get_sha1sum_prog() {
    # Linux/Solaris:
    if [ -x "$(command -v sha1sum 2>/dev/null)" ] ; then
        WINETRICKS_SHA1SUM="sha1sum"
    # FreeBSD/NetBSD:
    elif [ -x "$(command -v sha1 2>/dev/null)" ] ; then
        WINETRICKS_SHA1SUM="sha1"
    # OSX 10.6+:
    elif [ -x "$(command -v shasum 2>/dev/null)" ] ; then
        WINETRICKS_SHA1SUM="shasum -a 1"
    # OSX 10.5:
    elif [ -x "$(command -v openssl 2>/dev/null)" ] ; then
        WINETRICKS_SHA1SUM="openssl dgst -sha1"
    else
        w_die "No sha1sum utility available."
    fi
}

winetricks_get_sha256sum_prog() {
    # Linux/Solaris:
    if [ -x "$(command -v sha256sum 2>/dev/null)" ] ; then
        WINETRICKS_SHA256SUM="sha256sum"
    # FreeBSD/NetBSD:
    elif [ -x "$(command -v sha256 2>/dev/null)" ] ; then
        WINETRICKS_SHA256SUM="sha256"
    # OSX (10.6+), 10.5 doesn't support at all: https://stackoverflow.com/questions/7500691/rvm-sha256sum-nor-shasum-found
    elif [ -x "$(command -v shasum 2>/dev/null)" ] ; then
        WINETRICKS_SHA256SUM="shasum -a 256"
    else
        w_die "No sha256um utility available."
    fi
}

winetricks_get_platform()
{
    if [ "${OS}" = "Windows_NT" ]; then
        if [ ! -v "${WINELOADERNOEXEC}" ]; then
            export W_PLATFORM="windows_cmd"
        else
            export W_PLATFORM="wine_cmd"
        fi
    else
        export W_PLATFORM="wine"
    fi
}

winetricks_latest_version_check()
{
    if [ "$WINETRICKS_LATEST_VERSION_CHECK" = 'disabled' ] || [ -f "${WINETRICKS_CONFIG}/disable-latest-version-check" ] ; then
        w_info "winetricks latest version check update disabled"
        return
    # Used by ./src/release.sh, not for end users. Silently disables update check, without using $WINETRICKS_SUPER_QUIET
    elif [ "$WINETRICKS_LATEST_VERSION_CHECK" = 'development' ] ; then
        return
    fi

    latest_version="$(winetricks_dl_url_to_stdout https://raw.githubusercontent.com/Winetricks/winetricks/master/files/LATEST)"

    # Check that $latest_version is an actual number in case github is down
    if ! echo "${latest_version}" | grep -q -E "[0-9]{8}" || [ -z "${latest_version}" ] ; then
        case $LANG in
            pl*) w_warn "GitHub nie działa? Wersja '${latest_version}' nie wydaje się być prawdiłową wersją" ;;
            ru*) w_warn "Отсутствует подключение к Github? версия '${latest_version}' может быть неактуальной" ;;
            *) w_warn "Github down? version '${latest_version}' doesn't appear to be a valid version" ;;
        esac

        # If we can't get the latest version, no reason to go further:
        return
    fi

    if [ ! "$WINETRICKS_VERSION" = "${latest_version}" ] && [ ! "$WINETRICKS_VERSION" = "${latest_version}-next" ]; then
        if [ -f "${WINETRICKS_CONFIG}/enable-auto-update" ] ; then
            w_info "You are running winetricks-${WINETRICKS_VERSION}."
            w_info "New upstream release winetricks-${latest_version} is available."
            w_info "auto-update enabled: running winetricks_selfupdate"
            winetricks_selfupdate
        else
            case $LANG in
                pl*)
                    w_warn "Korzystasz z winetricks-${WINETRICKS_VERSION}, a najnowszą wersją winetricks-${latest_version}!"
                    w_warn "Zalecana jest aktualizacja z użyciem menedżera pakietów Twojej dystrybucji, --self-update lub ręczna aktualizacja."
                    ;;
                ru*)
                    w_warn "Запущен winetricks-${WINETRICKS_VERSION}, последняя версия winetricks-${latest_version}!"
                    w_warn "Вы можете ее обновить с помощью менеджера пакетов, --self-update или вручную."
                    ;;
                *)
                    w_warn "You are running winetricks-${WINETRICKS_VERSION}, latest upstream is winetricks-${latest_version}!"
                    w_warn "You should update using your distribution's package manager, --self-update, or manually."
                    ;;
            esac
        fi
    fi
}

winetricks_print_version()
{
    # Normally done by winetricks_init, but we don't want to set up the WINEPREFIX
    # just to get the winetricks version:

    winetricks_get_sha256sum_prog

    w_get_sha256sum "$0"
    echo "$WINETRICKS_VERSION - sha256sum: $_W_gotsha256sum"
}

# Run a small wine command for internal use
# Handy place to put small workarounds
winetricks_early_wine()
{
    # The sed works around https://bugs.winehq.org/show_bug.cgi?id=25838
    # which unfortunately got released in wine-1.3.12
    # We would like to use DISPLAY= to prevent virtual desktops from
    # popping up, but that causes AutoHotKey's tray icon to not show up.
    # We used to use WINEDLLOVERRIDES=mshtml= here to suppress the Gecko
    # autoinstall, but that yielded wineprefixes that *never* autoinstalled
    # Gecko (winezeug bug 223).
    # The tr removes carriage returns so expanded variables don't have crud on the end
    # The grep works around using new wineprefixes with old wine
    WINEDEBUG=-all "$WINE" "$@" 2> "$W_TMP_EARLY"/early_wine.err.txt | ( sed 's/.*1h.=//' | tr -d '\r' | grep -v -e "Module not found" -e "Could not load wine-gecko" || true)
}

winetricks_detect_gui()
{
    if test -x "$(command -v zenity 2>/dev/null)"; then
        WINETRICKS_GUI=zenity
        WINETRICKS_GUI_VERSION="$(zenity --version)"
        WINETRICKS_MENU_HEIGHT=500
        WINETRICKS_MENU_WIDTH=1010
    elif test -x "$(command -v kdialog 2>/dev/null)"; then
        echo "Zenity not found!  Using kdialog as poor substitute."
        WINETRICKS_GUI=kdialog
        WINETRICKS_GUI_VERSION="$(kdialog --version)"
    else
        echo "No arguments given, so tried to start GUI, but zenity not found."
        echo "Please install zenity if you want a graphical interface, or "
        echo "run with --help for more options."
        exit 1
    fi

    # Print zenity/dialog version info for debugging:
    if [ -z "$WINETRICKS_SUPER_QUIET" ] ; then
       echo "winetricks GUI enabled, using $WINETRICKS_GUI $WINETRICKS_GUI_VERSION"
    fi
}

# Detect which sudo to use
winetricks_detect_sudo()
{
    WINETRICKS_SUDO=sudo
    if test "$WINETRICKS_GUI" = "none"; then
        return
    fi

    if test x"$DISPLAY" != x""; then
        # This should be the default option because some of GUI sudo programs are unmaintained
        # See https://github.com/Winetricks/winetricks/issues/912
        if test -x "$(command -v pkexec 2>/dev/null)"; then
            # Maintained and recommended, part of Polkit, desktop-independent
            # Usage: pkexec command ...
            WINETRICKS_SUDO=pkexec
        # Austin said "gksu*/kdesu* should stay (at least for a while)" in Feb 2018
        # See https://github.com/Winetricks/winetricks/pull/915#issuecomment-362984379
        elif test -x "$(command -v gksudo 2>/dev/null)"; then
            # Unmaintained [2009], part of gksu
            # Usage: gksudo "command ..."
            WINETRICKS_SUDO=gksudo
        elif test -x "$(command -v kdesudo 2>/dev/null)"; then
            # Unmaintained [2015] (latest is for KDE4, no KF5 version available)
            # https://cgit.kde.org/kdesudo.git/
            # Usage: kdesudo "command ..."
            WINETRICKS_SUDO=kdesudo
        # fall back to the su versions if sudo isn't available (Fedora, etc.):
        elif test -x "$(command -v gksu 2>/dev/null)"; then
            # Unmaintained [2009]
            # Usage: gksu "command ..."
            WINETRICKS_SUDO=gksu
        elif test -x "$(command -v kdesu 2>/dev/null)"; then
            # Maintained, KF5 version available
            # https://cgit.kde.org/kdesu.git/
            # Usage: kdesu -c "command ..."
            WINETRICKS_SUDO=kdesu
        fi
    fi
}

# Detect which iso mount tool to use
winetricks_detect_iso_mount()
{
    if test -x "$(command -v fuseiso 2>/dev/null)"; then
        # File/dir names are converted to lowercase
        WINETRICKS_ISO_MOUNT=fuseiso
    elif test -x "$(command -v archivemount 2>/dev/null)"; then
        # File/dir names may be uppercase and we may need
        # case-insensitive operations
        #   e.g. w_try "$WINE" cmd /c "copy $W_ISO_MOUNT_LETTER:\\DOC.PDF C:\\doc.pdf"
        # This tool had path issue in 0.8.8 or older versions
        #   e.g. office2013pro works in 0.8.9 or later but doesn't work in 0.8.8
        WINETRICKS_ISO_MOUNT=archivemount
    elif test -x "$(command -v hdiutil 2>/dev/null)"; then
        # File/dir names may be uppercase (same as archivemount)
        WINETRICKS_ISO_MOUNT=hdiutil
    else
        WINETRICKS_ISO_MOUNT=none
    fi
    # Notes about other tools:
    #   fuseiso9660: may append ";1" to filenames
    #   unar: the drive icon is not "optical drive + disc" in Wine Explorer
    #         and "wine eject" command fails
}

winetricks_get_prefix_var()
{
    (
        # shellcheck disable=SC1090
        . "$W_PREFIXES_ROOT/$p/wrapper.cfg"

        # The cryptic sed is there to turn ' into '\''
        # shellcheck disable=SC1117
        eval echo \$ww_"$1" | sed "s/'/'\\\''/"
    )
}

# Display prefix menu, get which wineprefix the user wants to work with
winetricks_prefixmenu()
{
    case $LANG in
        ru*) _W_msg_title="Winetricks - выберите путь wine (wineprefix)"
             _W_msg_body='Что вы хотите сделать?'
             _W_msg_apps='Установить программу'
             _W_msg_games='Установить игру'
             _W_msg_benchmarks='Установить приложение для оценки производительности'
             _W_msg_default="Выберите путь для wine по умолчанию"
             _W_msg_mkprefix="Создать новый путь wine"
             _W_msg_unattended0="Отключить автоматическую установку"
             _W_msg_unattended1="Включить автоматическую установку"
             _W_msg_help="Просмотр справки (в веб-браузере)"
             ;;
        uk*) _W_msg_title="Winetricks - виберіть wineprefix"
             _W_msg_body='Що Ви хочете зробити?'
             _W_msg_apps='Встановити додаток'
             _W_msg_games='Встановити гру'
             _W_msg_benchmarks='Встановити benchmark'
             _W_msg_default="Вибрати wineprefix за замовчуванням"
             _W_msg_mkprefix="створити новий wineprefix"
             _W_msg_unattended0="Вимкнути автоматичне встановлення"
             _W_msg_unattended1="Увімкнути автоматичне встановлення"
             _W_msg_help="Переглянути довідку"
             ;;
        zh_CN*)   _W_msg_title="Winetricks - 选择一个 Wine 容器"
             _W_msg_body='您想要做什么？'
             _W_msg_apps='安装一个 Windows 应用'
             _W_msg_games='安装一个游戏'
             _W_msg_benchmarks='安装一个基准测试软件'
             _W_msg_default="选择默认的 Wine 容器"
             _W_msg_mkprefix="创建新的 Wine 容器"
             _W_msg_unattended0="禁用静默安装"
             _W_msg_unattended1="启用静默安装"
             _W_msg_help="查看帮助"
             ;;
        zh_TW*|zh_HK*)   _W_msg_title="Winetricks - 選取一個 Wine 容器"
             _W_msg_body='您想要做什麼？'
             _W_msg_apps='安裝一個 Windows 應用'
             _W_msg_games='安裝一個遊戲'
             _W_msg_benchmarks='安裝一個基准測試軟體'
             _W_msg_default="選取預設的 Wine 容器"
             _W_msg_mkprefix="建立新的 Wine 容器"
             _W_msg_unattended0="禁用靜默安裝"
             _W_msg_unattended1="啟用靜默安裝"
             _W_msg_help="檢視輔助說明"
             ;;
        de*) _W_msg_title="Winetricks - wineprefix auswählen"
             _W_msg_body='Was möchten Sie tun?'
             _W_msg_apps='Ein Programm installieren'
             _W_msg_games='Ein Spiel installieren'
             _W_msg_benchmarks='Einen Benchmark-Test installieren'
             _W_msg_default="Standard wineprefix auswählen"
             _W_msg_mkprefix="Neuen wineprefix erstellen"
             _W_msg_unattended0="Automatische Installation deaktivieren"
             _W_msg_unattended1="Automatische Installation aktivieren"
             _W_msg_help="Hilfe anzeigen"
             ;;
        pl*) _W_msg_title="Winetricks - wybierz prefiks Wine"
             _W_msg_body='Co chcesz zrobić?'
             _W_msg_apps='Zainstalować aplikację'
             _W_msg_games='Zainstalować grę'
             _W_msg_benchmarks='Zainstalować program sprawdzający wydajność komputera'
             _W_msg_default="Wybrać domyślny prefiks Wine"
             _W_msg_mkprefix="Stwórz nowy prefiks Wine"
             _W_msg_unattended0="Wyłącz cichą instalację"
             _W_msg_unattended1="Włącz cichą instalację"
             _W_msg_help="Wyświetl pomoc"
             ;;
        *)   _W_msg_title="Winetricks - choose a wineprefix"
             _W_msg_body='What do you want to do?'
             _W_msg_apps='Install an application'
             _W_msg_games='Install a game'
             _W_msg_benchmarks='Install a benchmark'
             _W_msg_default="Select the default wineprefix"
             _W_msg_mkprefix="Create new wineprefix"
             _W_msg_unattended0="Disable silent install"
             _W_msg_unattended1="Enable silent install"
             _W_msg_help="View help"
             ;;
    esac
    case "$W_OPT_UNATTENDED" in
        1) _W_cmd_unattended=attended; _W_msg_unattended="$_W_msg_unattended0" ;;
        *) _W_cmd_unattended=unattended; _W_msg_unattended="$_W_msg_unattended1" ;;
    esac

    case $WINETRICKS_GUI in
        zenity)
            printf %s "zenity \
                --title '$_W_msg_title' \
                --text '$_W_msg_body' \
                --list \
                --radiolist \
                --column '' \
                --column '' \
                --column '' \
                --height $WINETRICKS_MENU_HEIGHT \
                --width $WINETRICKS_MENU_WIDTH \
                --hide-column 2 \
                FALSE help       '$_W_msg_help' \
                FALSE apps       '$_W_msg_apps' \
                FALSE benchmarks '$_W_msg_benchmarks' \
                FALSE games      '$_W_msg_games' \
                TRUE  main       '$_W_msg_default' \
                FALSE mkprefix   '$_W_msg_mkprefix' \
                " \
                > "$WINETRICKS_WORKDIR"/zenity.sh

            if ls -d "$W_PREFIXES_ROOT"/*/dosdevices > /dev/null 2>&1; then
                for prefix in "$W_PREFIXES_ROOT"/*/dosdevices
                do
                    q="${prefix%%/dosdevices}"
                    p="${q##*/}"
                    if test -f "$W_PREFIXES_ROOT/$p/wrapper.cfg"; then
                        _W_msg_name="$p ($(winetricks_get_prefix_var name))"
                    else
                        _W_msg_name="$p"
                    fi
                case $LANG in
                    zh_CN*) printf %s " FALSE prefix='$p' '选择管理 $_W_msg_name' " ;;
                    zh_TW*|zh_HK*) printf %s " FALSE prefix='$p' '選擇管理 $_W_msg_name' " ;;
                    de*) printf %s " FALSE prefix='$p' '$_W_msg_name auswählen' " ;;
                    pl*) printf %s " FALSE prefix='$p' 'Wybierz $_W_msg_name' " ;;
                    *) printf %s " FALSE prefix='$p' 'Select $_W_msg_name' " ;;
                esac
                done >> "$WINETRICKS_WORKDIR"/zenity.sh
            fi
            printf %s " FALSE $_W_cmd_unattended '$_W_msg_unattended'" >> "$WINETRICKS_WORKDIR"/zenity.sh

            sh "$WINETRICKS_WORKDIR"/zenity.sh | tr '|' ' '
            ;;

        kdialog)
            (
            printf %s "kdialog \
                --geometry 600x400+100+100 \
                --title '$_W_msg_title' \
                --separate-output \
                --radiolist '$_W_msg_body' \
                help       '$_W_msg_help'       off \
                games      '$_W_msg_games'      off \
                benchmarks '$_W_msg_benchmarks' off \
                apps       '$_W_msg_apps'       off \
                main       '$_W_msg_default'    on  \
                mkprefix   '$_W_msg_mkprefix'   off \
                "
            if ls -d "$W_PREFIXES_ROOT"/*/dosdevices > /dev/null 2>&1; then
                for prefix in "$W_PREFIXES_ROOT"/*/dosdevices
                do
                    q="${prefix%%/dosdevices}"
                    p="${q##*/}"
                    if test -f "$W_PREFIXES_ROOT/$p/wrapper.cfg"; then
                        _W_msg_name="$p ($(winetricks_get_prefix_var name))"
                    else
                        _W_msg_name="$p"
                    fi
                    printf %s "prefix='$p' 'Select $_W_msg_name' off "
                done
            fi
            printf %s " $_W_cmd_unattended '$_W_msg_unattended' off"
            ) > "$WINETRICKS_WORKDIR"/kdialog.sh
            sh "$WINETRICKS_WORKDIR"/kdialog.sh
            ;;
    esac
    unset _W_msg_help _W_msg_body _W_msg_title _W_msg_new _W_msg_default _W_msg_name
}

# Graphically create new custom wineprefix.
# This returns two verbs: arch and prefix, e.g. "arch=32 prefix=test".
winetricks_mkprefixmenu()
{
    case $LANG in
        # TODO: translate to other languages
        de)  _W_msg_title="Winetricks - Neues Wineprefix erstellen"
             _W_msg_name="Name"
             _W_msg_arch="Architektur"
             ;;
        *)   _W_msg_title="Winetricks - create new wineprefix"
             _W_msg_name="Name"
             _W_msg_arch="Architecture"
             ;;
    esac

    case $WINETRICKS_GUI in
        zenity)
            $WINETRICKS_GUI --forms --text="" --title "$_W_msg_title" \
                --add-combo="$_W_msg_arch" --combo-values=32\|64 \
                --add-entry="$_W_msg_name" \
                | sed -e 's/^\s*|/64|/' -e 's/^/arch=/' -e 's/|/ prefix=/'
            ;;
        kdialog)
            $WINETRICKS_GUI --title="$_W_msg_title" \
                --radiolist="$_W_msg_arch" 32 32bit off 64 64bit on \
                | sed -e 's/^$/64/' -e 's/^/arch=/'
            $WINETRICKS_GUI --title="$_W_msg_title" --inputbox="$_W_msg_name" \
                | sed -e 's/^/prefix=/'
            ;;
    esac

    unset _W_msg_title _W_msg_name _W_msg_arch
}

# Display main menu, get which submenu the user wants
winetricks_mainmenu()
{
    case $LANG in
        da*) _W_msg_title="Vælg en pakke-kategori - Nuværende præfiks er \"$WINEPREFIX\""
             _W_msg_body='Hvad ønsker du at gøre?'
             _W_msg_dlls="Install a Windows DLL"
             _W_msg_fonts='Install a font'
             _W_msg_settings='Change Wine settings'
             _W_msg_winecfg='Run winecfg'
             _W_msg_regedit='Run regedit'
             _W_msg_taskmgr='Run taskmgr'
             _W_msg_explorer='Run explorer'
             _W_msg_uninstaller='Run uninstaller'
             _W_msg_shell='Run a commandline shell (for debugging)'
             _W_msg_folder='Browse files'
             _W_msg_annihilate="Delete ALL DATA AND APPLICATIONS INSIDE THIS WINEPREFIX"
             ;;
        de*) _W_msg_title="Pakettyp auswählen - Aktueller Präfix ist \"$WINEPREFIX\""
             _W_msg_body='Was möchten Sie tun?'
             _W_msg_dlls="Windows-DLL installieren"
             _W_msg_fonts='Schriftart installieren'
             _W_msg_settings='Wine Einstellungen ändern'
             _W_msg_winecfg='winecfg starten'
             _W_msg_regedit='regedit starten'
             _W_msg_taskmgr='taskmgr starten'
             _W_msg_explorer='explorer starten'
             _W_msg_uninstaller='uninstaller starten'
             _W_msg_shell='Eine Kommandozeile zum debuggen starten'
             _W_msg_folder='Ordner durchsuchen'
             _W_msg_annihilate="ALLE DATEIEN UND PROGRAMME IN DIESEM WINEPREFIX Löschen"
             ;;
        pl*) _W_msg_title="Winetricks - obecny prefiks to \"$WINEPREFIX\""
             _W_msg_body='Co chcesz zrobić w tym prefiksie?'
             _W_msg_dlls="Zainstalować windowsową bibliotekę DLL lub komponent"
             _W_msg_fonts='Zainstalować czcionkę'
             _W_msg_settings='Zmienić ustawienia'
             _W_msg_winecfg='Uruchomić winecfg'
             _W_msg_regedit='Uruchomić edytor rejestru'
             _W_msg_taskmgr='Uruchomić menedżer zadań'
             _W_msg_explorer='Uruchomić explorer'
             _W_msg_uninstaller='Uruchomić program odinstalowujący'
             _W_msg_shell='Uruchomić powłokę wiersza poleceń (dla debugowania)'
             _W_msg_folder='Przeglądać pliki'
             _W_msg_annihilate="Usuńąć WSZYSTKIE DANE I APLIKACJE WEWNĄTRZ TEGO PREFIKSU WINE"
             ;;
        ru*) _W_msg_title="Winetricks - текущий путь для wine (wineprefix) \"$WINEPREFIX\""
             _W_msg_body='Что вы хотите сделать с этим wineprefix?'
             _W_msg_dlls="Установить библиотеку DLL или компонент Windows"
             _W_msg_fonts='Установить шрифт'
             _W_msg_settings='Поменять настройки'
             _W_msg_winecfg='Запустить winecfg (редактор настроек wine)'
             _W_msg_regedit='Запустить regedit (редактор реестра)'
             _W_msg_taskmgr='Запустить taskmgr (менеджер задач)'
             _W_msg_explorer='Запустить explorer'
             _W_msg_uninstaller='Запустить uninstaller (деинсталлятор)'
             _W_msg_shell='Запустить графический терминал (для отладки)'
             _W_msg_folder='Проводник файлов'
             _W_msg_annihilate="Удалить ВСЕ ДАННЫЕ И ПРИЛОЖЕНИЯ В ЭТОМ WINEPREFIX"
             ;;
        uk*) _W_msg_title="Winetricks - поточний prefix \"$WINEPREFIX\""
             _W_msg_body='Що Ви хочете зробити для цього wineprefix?'
             _W_msg_dlls="Встановити Windows DLL чи компонент(и)"
             _W_msg_fonts='Встановити шрифт'
             _W_msg_settings='Змінити налаштування'
             _W_msg_winecfg='Запустити winecfg'
             _W_msg_regedit='Запустити regedit'
             _W_msg_taskmgr='Запустити taskmgr'
             _W_msg_explorer='Запустити explorer'
             _W_msg_uninstaller='Встановлення/видалення програм'
             _W_msg_shell='Запуск командної оболонки (для налагодження)'
             _W_msg_folder='Перегляд файлів'
             _W_msg_annihilate="Видалити УСІ ДАНІ ТА ПРОГРАМИ З ЦЬОГО WINEPREFIX"
             ;;
        zh_CN*)   _W_msg_title="Winetricks - 当前容器路径是 \"$WINEPREFIX\""
             _W_msg_body='管理当前容器'
             _W_msg_dlls="安装 Windows DLL 或组件"
             _W_msg_fonts='安装字体'
             _W_msg_settings='修改设置'
             _W_msg_winecfg='运行 Wine 配置程序'
             _W_msg_regedit='运行注册表'
             _W_msg_taskmgr='运行任务管理器'
             _W_msg_explorer='运行资源管理器'
             _W_msg_uninstaller='运行卸载程序'
             _W_msg_shell='运行命令提示窗口 (作为调试)'
             _W_msg_folder='浏览容器中的文件'
             _W_msg_annihilate="删除容器中所有数据和应用程序"
             ;;
        zh_TW*|zh_HK*)   _W_msg_title="Winetricks - 目前容器路徑是 \"$WINEPREFIX\""
             _W_msg_body='管理目前容器'
             _W_msg_dlls="安裝 Windows DLL 或套件"
             _W_msg_fonts='安裝字型'
             _W_msg_settings='修改設定'
             _W_msg_winecfg='執行 Wine 設定程式'
             _W_msg_regedit='執行登錄編輯程式'
             _W_msg_taskmgr='執行工作管理員'
             _W_msg_explorer='執行檔案總管'
             _W_msg_uninstaller='執行解除安裝程式'
             _W_msg_shell='執行命令提示視窗 (作為偵錯)'
             _W_msg_folder='瀏覽容器中的檔案'
             _W_msg_annihilate="刪除容器中所有資料和應用程式"
             ;;
        *)   _W_msg_title="Winetricks - current prefix is \"$WINEPREFIX\""
             _W_msg_body='What would you like to do to this wineprefix?'
             _W_msg_dlls="Install a Windows DLL or component"
             _W_msg_fonts='Install a font'
             _W_msg_settings='Change settings'
             _W_msg_winecfg='Run winecfg'
             _W_msg_regedit='Run regedit'
             _W_msg_taskmgr='Run taskmgr'
             _W_msg_explorer='Run explorer'
             _W_msg_uninstaller='Run uninstaller'
             _W_msg_shell='Run a commandline shell (for debugging)'
             _W_msg_folder='Browse files'
             _W_msg_annihilate="Delete ALL DATA AND APPLICATIONS INSIDE THIS WINEPREFIX"
             ;;
    esac

    case $WINETRICKS_GUI in
        zenity)
            (
                printf %s "zenity \
                    --title '$_W_msg_title' \
                    --text '$_W_msg_body' \
                    --list \
                    --radiolist \
                    --column '' \
                    --column '' \
                    --column '' \
                    --height $WINETRICKS_MENU_HEIGHT \
                    --width $WINETRICKS_MENU_WIDTH \
                    --hide-column 2 \
                    FALSE dlls        '$_W_msg_dlls' \
                    FALSE fonts       '$_W_msg_fonts' \
                    FALSE settings    '$_W_msg_settings' \
                    FALSE winecfg     '$_W_msg_winecfg' \
                    FALSE regedit     '$_W_msg_regedit' \
                    FALSE taskmgr     '$_W_msg_taskmgr' \
                    FALSE explorer    '$_W_msg_explorer' \
                    FALSE uninstaller '$_W_msg_uninstaller' \
                    FALSE shell       '$_W_msg_shell' \
                    FALSE folder      '$_W_msg_folder' \
                    FALSE annihilate  '$_W_msg_annihilate' \
                 "
            ) > "$WINETRICKS_WORKDIR"/zenity.sh

            sh "$WINETRICKS_WORKDIR"/zenity.sh | tr '|' ' '
            ;;

        kdialog)
            $WINETRICKS_GUI --geometry 600x400+100+100 \
                    --title "$_W_msg_title" \
                    --separate-output \
                    --radiolist \
                    "$_W_msg_body"\
                    dlls        "$_W_msg_dlls" off \
                    fonts       "$_W_msg_fonts" off \
                    settings    "$_W_msg_settings" off \
                    winecfg     "$_W_msg_winecfg" off \
                    regedit     "$_W_msg_regedit" off \
                    taskmgr     "$_W_msg_taskmgr" off \
                    explorer    "$_W_msg_explorer" off \
                    uninstaller "$_W_msg_uninstaller" off \
                    shell       "$_W_msg_shell" off \
                    folder      "$_W_msg_folder" off \
                    annihilate  "$_W_msg_annihilate" off \
                    $_W_cmd_unattended "$_W_msg_unattended" off \

            ;;
    esac
    unset _W_msg_body _W_msg_title _W_msg_apps _W_msg_benchmarks _W_msg_dlls _W_msg_games _W_msg_settings
}

winetricks_settings_menu()
{
    # FIXME: these translations should really be centralized/reused:
    case $LANG in
        da*) _W_msg_title="Vælg en pakke - Nuværende præfiks er \"$WINEPREFIX\""
             _W_msg_body='Which settings would you like to change?'
             ;;
        de*) _W_msg_title="Winetricks - Aktueller Präfix ist \"$WINEPREFIX\""
             _W_msg_body='Welche Einstellungen möchten Sie ändern?'
             ;;
        pl*) _W_msg_title="Winetricks - obecny prefiks to \"$WINEPREFIX\""
             _W_msg_body='Jakie ustawienia chcesz zmienić?'
             ;;
        ru*) _W_msg_title="Winetricks - текущий путь wine (wineprefix) \"$WINEPREFIX\""
             _W_msg_body='Какие настройки вы хотите изменить?'
             ;;
        uk*) _W_msg_title="Winetricks - поточний prefix \"$WINEPREFIX\""
             _W_msg_body='Які налаштування Ви хочете змінити?'
             ;;
        zh_CN*)   _W_msg_title="Winetricks - 当前容器路径是 \"$WINEPREFIX\""
             _W_msg_body='您想要更改哪项设置？'
             ;;
        zh_TW*|zh_HK*)   _W_msg_title="Winetricks - 目前容器路徑是 \"$WINEPREFIX\""
             _W_msg_body='您想要變更哪項設定？'
             ;;
        *)   _W_msg_title="Winetricks - current prefix is \"$WINEPREFIX\""
             _W_msg_body='Which settings would you like to change?'
             ;;
    esac

    case $WINETRICKS_GUI in
        zenity)
            case $LANG in
                da*) printf %s "zenity \
                        --title '$_W_msg_title' \
                        --text '$_W_msg_body' \
                        --list \
                        --checklist \
                        --column '' \
                        --column Pakke \
                        --column Navn \
                        --height $WINETRICKS_MENU_HEIGHT \
                        --width $WINETRICKS_MENU_WIDTH \
                        "
                    ;;
                de*) printf %s "zenity \
                        --title '$_W_msg_title' \
                        --text '$_W_msg_body' \
                        --list \
                        --checklist \
                        --column '' \
                        --column Einstellung \
                        --column Name \
                        --height $WINETRICKS_MENU_HEIGHT \
                        --width $WINETRICKS_MENU_WIDTH \
                        "
                    ;;
                pl*) printf %s "zenity \
                        --title '$_W_msg_title' \
                        --text '$_W_msg_body' \
                        --list \
                        --checklist \
                        --column '' \
                        --column Ustawienie \
                        --column Nazwa \
                        --height $WINETRICKS_MENU_HEIGHT \
                        --width $WINETRICKS_MENU_WIDTH \
                        "
                    ;;
                ru*) printf %s "zenity \
                        --title '$_W_msg_title' \
                        --text '$_W_msg_body' \
                        --list \
                        --checklist \
                        --column '' \
                        --column Установка \
                        --column Имя \
                        --height $WINETRICKS_MENU_HEIGHT \
                        --width $WINETRICKS_MENU_WIDTH \
                        "
                    ;;
                uk*) printf %s "zenity \
                        --title '$_W_msg_title' \
                        --text '$_W_msg_body' \
                        --list \
                        --checklist \
                        --column '' \
                        --column Установка \
                        --column Назва \
                        --height $WINETRICKS_MENU_HEIGHT \
                        --width $WINETRICKS_MENU_WIDTH \
                        "
                    ;;
                zh_CN*) printf %s "zenity \
                        --title '$_W_msg_title' \
                        --text '$_W_msg_body' \
                        --list \
                        --checklist \
                        --column '' \
                        --column 设置 \
                        --column 标题 \
                        --height $WINETRICKS_MENU_HEIGHT \
                        --width $WINETRICKS_MENU_WIDTH \
                        "
                    ;;
                zh_TW*|zh_HK*) printf %s "zenity \
                        --title '$_W_msg_title' \
                        --text '$_W_msg_body' \
                        --list \
                        --checklist \
                        --column '' \
                        --column 設定 \
                        --column 標題 \
                        --height $WINETRICKS_MENU_HEIGHT \
                        --width $WINETRICKS_MENU_WIDTH \
                        "
                    ;;
                *) printf %s "zenity \
                        --title '$_W_msg_title' \
                        --text '$_W_msg_body' \
                        --list \
                        --checklist \
                        --column '' \
                        --column Setting \
                        --column Title \
                        --height $WINETRICKS_MENU_HEIGHT \
                        --width $WINETRICKS_MENU_WIDTH \
                        "
                    ;;
            esac > "$WINETRICKS_WORKDIR"/zenity.sh

            for metadatafile in "$WINETRICKS_METADATA/$WINETRICKS_CURMENU"/*.vars
            do
                code=$(winetricks_metadata_basename "$metadatafile")
                (
                    title='?'
                    # shellcheck disable=SC1090
                    . "$metadatafile"

                    # Begin 'title' strings localization code
                    # shellcheck disable=SC2154
                    case $LANG in
                    uk*)
                        case "$title_uk" in
                            "") ;;
                            *) title="$title_uk";;
                        esac
                    esac

                    # End of code
                    printf "%s %s %s %s" " " FALSE \
                            "$code" \
                            "\"$title\""
                )
            done >> "$WINETRICKS_WORKDIR"/zenity.sh

            sh "$WINETRICKS_WORKDIR"/zenity.sh | tr '|' ' '
            ;;

        kdialog)
            (
                printf %s "kdialog --geometry 600x400+100+100 --title '$_W_msg_title' --separate-output --checklist '$_W_msg_body' "
                winetricks_list_all | sed 's/\([^ ]*\)  *\(.*\)/\1 "\1 - \2" off /' | tr '\012' ' '
            ) > "$WINETRICKS_WORKDIR"/kdialog.sh

            sh "$WINETRICKS_WORKDIR"/kdialog.sh
            ;;
    esac

    unset _W_msg_body _W_msg_title
}

# Display the current menu, output list of verbs to execute to stdout
winetricks_showmenu()
{
    case $LANG in
        da*) _W_msg_title='Vælg en pakke'
             _W_msg_body='Vilken pakke vil du installere?'
             _W_cached="cached"
             ;;
        de*) _W_msg_title="Winetricks - Aktueller Prefix ist \"$WINEPREFIX\""
             _W_msg_body='Welche Paket(e) möchten Sie installieren?'
             _W_cached="gecached"
             ;;
        pl*) _W_msg_title="Winetricks - obecny prefiks to \"$WINEPREFIX\""
             _W_msg_body='Które paczki chesz zainstalować?'
             _W_cached="zarchiwizowane"
             ;;
        ru*) _W_msg_title="Winetricks - текущий путь wine (wineprefix) \"$WINEPREFIX\""
             _W_msg_body='Какое приложение(я) вы хотите установить?'
             _W_cached="в кэше"
             ;;
        uk*) _W_msg_title="Winetricks - поточний prefix \"$WINEPREFIX\""
             _W_msg_body='Які пакунки Ви хочете встановити?'
             _W_cached="кешовано"
             ;;
        zh_CN*)   _W_msg_title="Winetricks - 当前容器路径是 \"$WINEPREFIX\""
             _W_msg_body='您想要安装什么应用程序？'
             _W_cached="已缓存"
             ;;
        zh_TW*|zh_HK*)   _W_msg_title="Winetricks - 目前容器路徑是 \"$WINEPREFIX\""
             _W_msg_body='您想要安裝什麼應用程式？'
             _W_cached="已緩存"
             ;;
        *)   _W_msg_title="Winetricks - current prefix is \"$WINEPREFIX\""
             _W_msg_body='Which package(s) would you like to install?'
             _W_cached="cached"
             ;;
    esac


    case $WINETRICKS_GUI in
        zenity)
            case $LANG in
                da*) printf %s "zenity \
                        --title '$_W_msg_title' \
                        --text '$_W_msg_body' \
                        --list \
                        --checklist \
                        --column '' \
                        --column Pakke \
                        --column Navn \
                        --column Udgiver \
                        --column År \
                        --column Medie \
                        --column Status \
                        --height $WINETRICKS_MENU_HEIGHT \
                        --width $WINETRICKS_MENU_WIDTH \
                        "
                    ;;
                de*) printf %s "zenity \
                        --title '$_W_msg_title' \
                        --text '$_W_msg_body' \
                        --list \
                        --checklist \
                        --column '' \
                        --column Paket \
                        --column Name \
                        --column Herausgeber \
                        --column Jahr \
                        --column Media \
                        --column Status \
                        --height $WINETRICKS_MENU_HEIGHT \
                        --width $WINETRICKS_MENU_WIDTH \
                        "
                     ;;
                pl*) printf %s "zenity \
                        --title '$_W_msg_title' \
                        --text '$_W_msg_body' \
                        --list \
                        --checklist \
                        --column '' \
                        --column Pakiet \
                        --column Nazwa \
                        --column Wydawca \
                        --column Rok \
                        --column Media \
                        --column Status \
                        --height $WINETRICKS_MENU_HEIGHT \
                        --width $WINETRICKS_MENU_WIDTH \
                        "
                     ;;
                ru*) printf %s "zenity \
                        --title '$_W_msg_title' \
                        --text '$_W_msg_body' \
                        --list \
                        --checklist \
                        --column '' \
                        --column Пакет \
                        --column Название \
                        --column Издатель \
                        --column Год \
                        --column Источник \
                        --column Статус \
                        --height $WINETRICKS_MENU_HEIGHT \
                        --width $WINETRICKS_MENU_WIDTH \
                        "
                     ;;
                uk*) printf %s "zenity \
                        --title '$_W_msg_title' \
                        --text '$_W_msg_body' \
                        --list \
                        --checklist \
                        --column '' \
                        --column Пакунок \
                        --column Назва \
                        --column Видавець \
                        --column Рік \
                        --column Медіа \
                        --column Статус \
                        --height $WINETRICKS_MENU_HEIGHT \
                        --width $WINETRICKS_MENU_WIDTH \
                        "
                     ;;
                zh_CN*) printf %s "zenity \
                        --title '$_W_msg_title' \
                        --text '$_W_msg_body' \
                        --list \
                        --checklist \
                        --column '' \
                        --column 包名 \
                        --column 软件名 \
                        --column 发行商 \
                        --column 发行年 \
                        --column 媒介 \
                        --column 状态 \
                        --height $WINETRICKS_MENU_HEIGHT \
                        --width $WINETRICKS_MENU_WIDTH \
                        "
                     ;;
                zh_TW*|zh_HK*) printf %s "zenity \
                        --title '$_W_msg_title' \
                        --text '$_W_msg_body' \
                        --list \
                        --checklist \
                        --column '' \
                        --column 包名 \
                        --column 軟體名 \
                        --column 發行商 \
                        --column 發行年 \
                        --column 媒介 \
                        --column 狀態 \
                        --height $WINETRICKS_MENU_HEIGHT \
                        --width $WINETRICKS_MENU_WIDTH \
                        "
                     ;;
                *) printf %s "zenity \
                        --title '$_W_msg_title' \
                        --text '$_W_msg_body' \
                        --list \
                        --checklist \
                        --column '' \
                        --column Package \
                        --column Title \
                        --column Publisher \
                        --column Year \
                        --column Media \
                        --column Status \
                        --height $WINETRICKS_MENU_HEIGHT \
                        --width $WINETRICKS_MENU_WIDTH \
                        "
                     ;;
            esac > "$WINETRICKS_WORKDIR"/zenity.sh

            true > "$WINETRICKS_WORKDIR"/installed.txt

            for metadatafile in "$WINETRICKS_METADATA/$WINETRICKS_CURMENU"/*.vars
            do
                code=$(winetricks_metadata_basename "$metadatafile")
                (
                    title='?'
                    # shellcheck disable=SC1090
                    . "$metadatafile"
                    # Compute cached and downloadable flags
                    flags=""
                    winetricks_is_cached "$code" && flags="$_W_cached"
                    installed=FALSE
                    if winetricks_is_installed "$code"; then
                        installed=TRUE
                        echo "$code" >> "$WINETRICKS_WORKDIR"/installed.txt
                    fi
                    printf %s " $installed \
                        $code \
                        \"$title\" \
                        \"$publisher\" \
                        \"$year\" \
                        \"$media\" \
                        \"$flags\" \
                    "
                )
            done >> "$WINETRICKS_WORKDIR"/zenity.sh

            # Filter out any verb that's already installed
            sh "$WINETRICKS_WORKDIR"/zenity.sh |
                tr '|' '\012' |
                grep -F -v -x -f "$WINETRICKS_WORKDIR"/installed.txt |
                tr '\012' ' '
            ;;

        kdialog)
            (
                printf %s "kdialog --geometry 600x400+100+100 --title '$_W_msg_title' --separate-output --checklist '$_W_msg_body' "
                winetricks_list_all | sed 's/\([^ ]*\)  *\(.*\)/\1 "\1 - \2" off /' | tr '\012' ' '
            ) > "$WINETRICKS_WORKDIR"/kdialog.sh

            sh "$WINETRICKS_WORKDIR"/kdialog.sh
            ;;
    esac

    unset _W_msg_body _W_msg_title
}

# Converts a metadata absolute path to its app code
winetricks_metadata_basename()
{
    # Classic, but too slow on cygwin
    #basename $1 .vars

    # first, remove suffix .vars
    _W_mb_tmp="${1%.vars}"
    # second, remove any directory prefix
    echo "${_W_mb_tmp##*/}"
    unset _W_mb_tmp
}

# Returns true if given verb has been registered
winetricks_metadata_exists()
{
    test -f "$WINETRICKS_METADATA"/*/"${1}.vars"
}

# Returns true if given verb has been cached
# You must have already loaded its metadata before calling
winetricks_is_cached()
{
    # FIXME: also check file2... if given
    # https://github.com/Winetricks/winetricks/issues/989
    # shellcheck disable=SC2154
    _W_path="$W_CACHE/$1/$file1"
    case "$_W_path" in
        *..*)
            # Remove /foo/.. so verbs that don't have their own cache directories
            # can refer to siblings
            _W_path="$(echo "$_W_path" | sed 's,/[^/]*/\.\.,,')"
            ;;
    esac

    if test -f "$_W_path"; then
        unset _W_path
        return 0
    fi

    unset _W_path
    return 1
}

# Returns true if given verb has been installed
# You must have already loaded its metadata before calling
winetricks_is_installed()
{
    unset _W_file _W_file_unix
    if test "$installed_exe1"; then
        _W_file="$installed_exe1"
    elif test "$installed_file1"; then
        _W_file="$installed_file1"
    else
        return 1  # not installed
    fi

    # Test if the verb has been executed before
    if ! grep -qw "$1" "$WINEPREFIX/winetricks.log" 2>/dev/null; then
        unset _W_file
        return 1  # not installed
    fi

    case "$W_PLATFORM" in
        windows_cmd|wine_cmd)
            # On Windows, there's no wineprefix, just check if file's there
            _W_file_unix="$(w_pathconv -u "$_W_file")"
            if test -f "$_W_file_unix"; then
                unset _W_file _W_file_unix _W_prefix
                return 0  # installed
            fi
            ;;
        *)
            # Compute wineprefix for this app
            case "${category}-${WINETRICKS_OPT_SHAREDPREFIX}" in
                apps-0|benchmarks-0|games-0)
                    _W_prefix="$W_PREFIXES_ROOT/$1"
                    ;;
                *)
                    _W_prefix="$WINEPREFIX"
                    ;;
            esac
            if test -d "$_W_prefix/dosdevices"; then
              # 'win7 vcrun2005' creates different file than 'winxp vcrun2005'
              # so let it specify multiple, separated by |
              _W_IFS="$IFS"
              IFS='|'
              for _W_file_ in $_W_file
              do
                _W_file_unix="$(WINEPREFIX="$_W_prefix" w_pathconv -u "$_W_file_")"
                if test -f "$_W_file_unix" && ! grep -q "Wine placeholder DLL" "$_W_file_unix"; then
                    IFS="$_W_IFS"
                    unset _W_file _W_file_ _W_file_unix _W_prefix _W_IFS
                    return 0  # installed
                fi
              done
             IFS="$_W_IFS"
            fi
            ;;
    esac
    unset _W_file _W_prefix _W_IFS  # leak _W_file_unix for caller. Is this wise?
    return 1  # not installed
}

# List verbs which are already fully cached locally
winetricks_list_cached()
{
    for _W_metadatafile in "$WINETRICKS_METADATA"/*/*.vars
    do
        # Use a subshell to avoid putting metadata in global space
        # If this is too slow, we can unset known metadata by hand
        (
        code=$(winetricks_metadata_basename "$_W_metadatafile")
        # shellcheck disable=SC1090
        . "$_W_metadatafile"
        if winetricks_is_cached "$code"; then
            echo "$code"
        fi
        )
    done | sort
    unset _W_metadatafile
}

# List verbs which are automatically downloadable, regardless of whether they're cached yet
winetricks_list_download()
{
    # Piping output of w_try_cd to /dev/null since winetricks-test parses it:
    w_try_cd "$WINETRICKS_METADATA" >/dev/null
    grep -l 'media=.download' ./*/*.vars | sed 's,.*/,,;s/\.vars//' | sort -u
}

# List verbs which are downloadable with user intervention, regardless of whether they're cached yet
winetricks_list_manual_download()
{
    # Piping output of w_try_cd to /dev/null since winetricks-test parses it:
    w_try_cd "$WINETRICKS_METADATA" >/dev/null
    grep -l 'media=.manual_download' ./*/*.vars | sed 's,.*/,,;s/\.vars//' | sort -u
}

winetricks_list_installed()
{
    # Rather than check individual metadata/files (which is slow/brittle, and also breaks settings and metaverbs)
    # just show winetricks.log (if it exists), which lists verbs in the order they were installed
    if [ -f "$WINEPREFIX/winetricks.log" ]; then
        cat "$WINEPREFIX/winetricks.log"
    else
        echo "warning: $WINEPREFIX/winetricks.log not found; winetricks has not installed anything in this prefix."
    fi
}

# Helper for adding a string to a list of flags
winetricks_append_to_flags()
{
    if test "$flags"; then
        flags="$flags,"
    fi
    flags="${flags}$1"
}

# List all verbs in category WINETRICKS_CURMENU verbosely
# Format is "verb  title  (publisher, year) [flags]"
winetricks_list_all()
{
    # Note: doh123 relies on 'winetricks list' to list main menu categories
    case $WINETRICKS_CURMENU in
        prefix|main|mkprefix) echo "$WINETRICKS_CATEGORIES" | sed 's/ mkprefix//' | tr ' ' '\012' ; return;;
    esac

    case $LANG in
        da*) _W_cached="cached"   ; _W_download="kan hentes"    ;;
        de*) _W_cached="gecached" ; _W_download="herunterladbar";;
        pl*) _W_cached="zarchiwizowane"   ; _W_download="do pobrania"  ;;
        ru*) _W_cached="в кэше"   ; _W_download="доступно для скачивания"  ;;
        uk*) _W_cached="кешовано"   ; _W_download="завантажуване"  ;;
        zh_CN*)   _W_cached="已缓存"   ; _W_download="可下载"  ;;
        zh_TW*|zh_HK*)   _W_cached="已緩存"   ; _W_download="可下載"  ;;
        *)   _W_cached="cached"   ; _W_download="downloadable"  ;;
    esac

    for _W_metadatafile in "$WINETRICKS_METADATA/$WINETRICKS_CURMENU"/*.vars
    do
        # Use a subshell to avoid putting metadata in global space
        # If this is too slow, we can unset known metadata by hand
        (
        code=$(winetricks_metadata_basename "$_W_metadatafile")
        # shellcheck disable=SC1090
        . "$_W_metadatafile"

        # Compute cached and downloadable flags
        flags=""
        test "$media" = "download" && winetricks_append_to_flags "$_W_download"
        winetricks_is_cached "$code" && winetricks_append_to_flags "$_W_cached"
        test "$flags" && flags="[$flags]"

        if ! test "$year" && ! test "$publisher"; then
            printf "%-24s %s %s\\n" "$code" "$title" "$flags"
        else
            printf "%-24s %s (%s, %s) %s\\n" "$code" "$title" "$publisher" "$year" "$flags"
        fi
        )
    done
    unset _W_cached _W_metadatafile
}

# Abort if user doesn't own the given directory (or its parent, if it doesn't exist yet)
winetricks_die_if_user_not_dirowner()
{
    if test -d "$1"; then
        _W_checkdir="$1"
    else
        # fixme: quoting problem?
        _W_checkdir=$(dirname "$1")
    fi
    _W_nuser=$(id -u)
    _W_nowner=$(stat -c '%u' "$_W_checkdir")
    if test x"$_W_nuser" != x"$_W_nowner"; then
        w_die "You ($(id -un)) don't own $_W_checkdir.  Don't run this tool as another user!"
    fi
}

# See
# https://www.ecma-international.org/publications/files/ECMA-ST/Ecma-119.pdf (iso9660)
# https://www.ecma-international.org/publications/files/ECMA-ST/Ecma-167.pdf
# http://www.osta.org/specs/pdf/udf102.pdf
# https://www.ecma-international.org/publications/techreports/E-TR-071.htm

# Usage: read_bytes offset count device
winetricks_read_bytes()
{
    dd status=noxfer if="$3" bs=1 skip="$1" count="$2" 2>/dev/null
}

# Usage: read_hex offset count device
winetricks_read_hex()
{
    od -j "$1" -N "$2" -t x1 "$3"     | # offset $1, count $2, single byte hex format, file $3
        sed 's/^[^ ]* //'             | # remove address
        sed '$d'                        # remove final line which is just final offset
}

# Usage: read_decimal offset device
# Reads single four byte word, outputs in decimal.
# Uses default endianness.
# udf uses little endian words, so this only works on little endian machines.
winetricks_read_decimal()
{
    od -j "$1" -N 4  -t u4 "$2"          | # offset $1, byte count 4, four byte decimal format, file $2
        sed 's/^[^ ]* //'             | # remove address
        sed '$d'                        # remove final line which is just final offset
}

winetricks_read_udf_volume_name()
{
    # "Anchor volume descriptor pointer" starts at sector 256

    # AVDP Layout (ECMA-167 3/10.2):
    # size   offset   contents
    # 16     0        descriptor tag (id = 2)
    # 16     8        main (primary?) volume descriptor sequence extent
    # ...

    # descriptor tag layout (ECMA-167 3/7.2):
    # size   offset   contents
    # 2      0        TagIdentifier
    # ...

    # extent layout (ECMA-167 3/7.1):
    # size   offset   contents
    # 4      0        length (in bytes)
    # 8      4        location (in 2k sectors)

    # primary volume descriptor layout (ECMA-167 3/10.1):
    # size   offset   contents
    # 16     0        descriptor tag (id = 1)
    # ...
    # 32     24       volume identifier (dstring)

    # 1. check the 16 bit TagIdentifier of the descriptor tag, make sure it's 2
    tagid=$(winetricks_read_hex 524288 2 "$1")
    : echo "tagid is $tagid"
    case "$tagid" in
        "02 00") : echo "Found AVDP" ;;
        *) echo "Did not find AVDP (tagid was $tagid)"; exit 1;;
    esac

    # 2. read the location of the main volume descriptor:
    offset=$(winetricks_read_decimal 524308 "$1")
    : echo "MVD is at sector $offset"
    offset=$((offset * 2048))
    : echo "MVD is at byte $offset"

    # 3. check the TagIdentifier of the MVD's descriptor tag, make sure it's 1
    tagid=$(winetricks_read_hex $offset 2 "$1")
    : echo "tagid is $tagid"
    case "$tagid" in
        "01 00") : echo Found MVD ;;
        *) echo Did not find MVD; exit 1;;
    esac

    # 4. Read whether the name is in 8 or 16 bit chars
    offset=$((offset + 24))
    width=$(winetricks_read_hex $offset 1 "$1")

    offset=$((offset + 1))

    # 5. Profit!
    case $width in
        08)   winetricks_read_bytes $offset 30 "$1" | sed 's/  *$//' ;;
        10)  winetricks_read_bytes $offset 30 "$1" | tr -d '\000' | sed 's/  *$//' ;;
        *) echo "Unhandled dvd volname character width '$width'"; exit 1;;
    esac

    echo ""
}

winetricks_read_iso9660_volume_name()
{
    winetricks_read_bytes 32808 30 "$1" | sed 's/  *$//'
}

winetricks_read_volume_name()
{
    # ECMA-119 says that CD-ROMs have sector size 2k, and at sector 16 have:
    # size  offset contents
    #  1    0      Volume descriptor type (1 for primary volume descriptor)
    #  5    1      Standard identifier ("CD001" for iso9660)
    # ECMA-167, section 9.1.2, has a table of standard identifiers:
    # "BEA01": ecma-167 9.2, Beginning Extended Area Descriptor
    # "CD001": ecma-119
    # "CDW02": ecma-168

    std_id=$(winetricks_read_bytes 32769 5 "$1")
    : echo "std_id is $std_id"

    case $std_id in
        CD001) winetricks_read_iso9660_volume_name "$1" ;;
        BEA01) winetricks_read_udf_volume_name "$1" ;;
        *) echo "Unrecognized disk type $std_id"; exit 1 ;;
    esac
}

winetricks_volname()
{
    x=$(volname "$1" 2> /dev/null| sed 's/  *$//')
    if test "x$x" = "x"; then
        # UDF?  See https://bugs.launchpad.net/bugs/678419
        x=$(winetricks_read_volume_name "$1")
    fi
    echo "$x"
}

# Really, should take a volume name as argument, and use 'mount' to get
# mount point if system automounted it.
winetricks_detect_optical_drive()
{
    case "$WINETRICKS_DEV" in
        "") ;;
        *) return ;;
    esac

    for WINETRICKS_DEV in /dev/cdrom /dev/dvd /dev/sr0
    do
        test -b $WINETRICKS_DEV && break
    done

    case "$WINETRICKS_DEV" in
        "x") w_die "can't find cd/dvd drive" ;;
    esac
}

winetricks_cache_iso()
{
    # WINETRICKS_IMG has already been set by w_mount
    _W_expected_volname="$1"

    winetricks_die_if_user_not_dirowner "$W_CACHE"
    winetricks_detect_optical_drive

    # Horrible hack for Gentoo - make sure we can read from the drive
    if ! test -r $WINETRICKS_DEV; then
        case "$WINETRICKS_SUDO" in
            gksu*|kdesudo) $WINETRICKS_SUDO "chmod 666 $WINETRICKS_DEV" ;;
            kdesu) $WINETRICKS_SUDO -c "chmod 666 $WINETRICKS_DEV" ;;
            *) $WINETRICKS_SUDO chmod 666 $WINETRICKS_DEV ;;
        esac
    fi

    while true
    do
        # Wait for user to insert disc.
        # Sleep long to make it less likely to close the drive during insertion.
        while ! dd if=$WINETRICKS_DEV of=/dev/null count=1
        do
            sleep 5
        done

        # Some distributions automount discs in /media, take advantage of that
        if test -d "/media/_W_expected_volname"; then
            break
        fi
        # Otherwise try and read it straight from unmounted volume
        _W_volname=$(winetricks_volname $WINETRICKS_DEV)
        if test "$_W_expected_volname" != "$_W_volname"; then
            case $LANG in
                da*)  w_warn "Forkert disk [$_W_volname] indsat. Indsæt venligst disken [$_W_expected_volname]" ;;
                de*)  w_warn "Falsche Disk [$_W_volname] eingelegt. Bitte legen Sie Disk [$_W_expected_volname] ein!" ;;
                pl*)  w_warn "Umieszczono zły dysk [$_W_volname]. Proszę włożyć dysk [$_W_expected_volname]" ;;
                ru*)  w_warn "Неверный диск [$_W_volname]. Пожалуйста, вставьте диск [$_W_expected_volname]" ;;
                uk*)  w_warn "Неправильний диск [$_W_volname]. Будь ласка, вставте диск [$_W_expected_volname]" ;;
                zh_CN*)    w_warn " [$_W_volname] 光盘插入错误，请插入光盘 [$_W_expected_volname]" ;;
                zh_TW*|zh_HK*)    w_warn " [$_W_volname] 光碟插入錯誤，請插入光碟 [$_W_expected_volname]" ;;
                *)    w_warn "Wrong disc [$_W_volname] inserted.  Please insert disc [$_W_expected_volname]" ;;
            esac

            sleep 10
        else
            break
        fi
    done

    # Copy disc to .iso file, display progress every 5 seconds
    # Use conv=noerror,sync to replace unreadable blocks with zeroes
    case $WINETRICKS_OPT_DD in
        dd)
          $WINETRICKS_OPT_DD if=$WINETRICKS_DEV of="$W_CACHE"/temp.iso bs=2048 conv=noerror,sync &
          WINETRICKS_DD_PID=$!
          ;;
        ddrescue)
          if [ ! -x "$(command -v ddrescue)" ]; then
              w_die "Please install ddrescue first."
          fi
          $WINETRICKS_OPT_DD -v -b 2048 $WINETRICKS_DEV "$W_CACHE"/temp.iso &
          WINETRICKS_DD_PID=$!
          ;;
    esac

    echo "$WINETRICKS_DD_PID" > "$WINETRICKS_WORKDIR"/dd-pid

    # Note: if user presses ^C, winetricks_cleanup will call winetricks_iso_cleanup
    # FIXME: add progress bar for kde, too
    case $WINETRICKS_GUI in
        none|kdialog)
            while ps -p "$WINETRICKS_DD_PID" > /dev/null 2>&1
            do
                sleep 5
                ls -l "$W_CACHE"/temp.iso
            done
            ;;
        zenity)
            while ps -p "$WINETRICKS_DD_PID" > /dev/null 2>&1
            do
                echo 1
                sleep 2
            done | $WINETRICKS_GUI --title "Copying to $_W_expected_volname.iso" --progress --pulsate --auto-kill
            ;;
    esac
    rm "$WINETRICKS_WORKDIR"/dd-pid

    mv "$W_CACHE"/temp.iso "$WINETRICKS_IMG"

    eject $WINETRICKS_DEV || true    # punt if eject not found (as on cygwin)
}

winetricks_load_vcdmount()
{
    if test "$WINE" != ""; then
        return
    fi

    # Call only on real Windows.
    # Sets VCD_DIR and W_ISO_MOUNT_ROOT

    # The only free mount tool I know for Windows Vista is Virtual CloneDrive,
    # which can be downloaded at
    # http://www.slysoft.com/en/virtual-clonedrive.html
    # FIXME: actually install it here

    # Locate vcdmount.exe.
    VCD_DIR="Elaborate Bytes/VirtualCloneDrive"
    if test ! -x "$W_PROGRAMS_UNIX/$VCD_DIR/vcdmount.exe" && test ! -x "$W_PROGRAMS_X86_UNIX/$VCD_DIR/vcdmount.exe"; then
        w_warn "Installing Virtual CloneDrive"
        w_download_to vcd http://static.slysoft.com/SetupVirtualCloneDrive.exe
        # have to use cmd else vista won't let cygwin run .exe's?
        chmod +x "$W_CACHE"/vcd/SetupVirtualCloneDrive.exe
        w_try_cd "$W_CACHE/vcd"
        cmd /c SetupVirtualCloneDrive.exe
    fi
    if test -x "$W_PROGRAMS_UNIX/$VCD_DIR/vcdmount.exe"; then
        VCD_DIR="$W_PROGRAMS_UNIX/$VCD_DIR"
    elif test -x "$W_PROGRAMS_X86_UNIX/$VCD_DIR/vcdmount.exe"; then
        VCD_DIR="$W_PROGRAMS_X86_UNIX/$VCD_DIR"
    else
        w_die "can't find Virtual CloneDrive?"
    fi
    # FIXME: Use WMI to locate the drive named
    # "ELBY CLONEDRIVE..." using WMI as described in
    # https://delphihaven.wordpress.com/2009/07/05/using-wmi-to-get-a-drive-friendly-name/
}

winetricks_mount_cached_iso()
{
    # On entry, WINETRICKS_IMG is already set
    w_umount

    if test "$WINE" = ""; then
        winetricks_load_vcdmount
        my_img_win="$(w_pathconv -w "$WINETRICKS_IMG" | tr '\012' ' ' | sed 's/ $//')"
        w_try_cd "$VCD_DIR"
        w_try vcdmount.exe /l="$letter" "$my_img_win"

        tries=0
        while test $tries -lt 20
        do
            for W_ISO_MOUNT_LETTER in e f g h i j k
            do
                # let user blacklist drive letters
                echo "$WINETRICKS_MOUNT_LETTER_IGNORE" | grep -q "$W_ISO_MOUNT_LETTER" && continue
                W_ISO_MOUNT_ROOT=/cygdrive/$W_ISO_MOUNT_LETTER
                if find $W_ISO_MOUNT_ROOT -iname 'setup*' -o -iname '*.exe' -o -iname '*.msi'; then
                    break 2
                fi
            done
            tries=$((tries + 1))
            echo "Waiting for mount to finish mounting"
            sleep 1
        done
    else
        if test "$W_USE_USERMOUNT"; then
            # Linux (FUSE-based tools), macOS (hdiutil)
            if test "$WINETRICKS_ISO_MOUNT" = "none"; then
                # If no tools found, fall back to sudo + mount
                w_warn "No user mount tools detected, using sudo + mount"
                unset W_USE_USERMOUNT
                winetricks_mount_cached_iso
                return
            fi
            echo "Running mkdir -p $W_ISO_USER_MOUNT_ROOT"
            mkdir -p "$W_ISO_USER_MOUNT_ROOT"
            if test $? -ne 0; then
                w_warn "mkdir -p $W_ISO_USER_MOUNT_ROOT failed, falling back to sudo + mount"
                unset W_USE_USERMOUNT
                winetricks_mount_cached_iso
                return
            fi
            case "$WINETRICKS_ISO_MOUNT" in
                fuseiso)
                    echo "Running $WINETRICKS_ISO_MOUNT $WINETRICKS_IMG $W_ISO_USER_MOUNT_ROOT"
                    $WINETRICKS_ISO_MOUNT "$WINETRICKS_IMG" "$W_ISO_USER_MOUNT_ROOT"
                    ;;
                archivemount)
                    echo "Running $WINETRICKS_ISO_MOUNT $WINETRICKS_IMG $W_ISO_USER_MOUNT_ROOT -o readonly"
                    $WINETRICKS_ISO_MOUNT "$WINETRICKS_IMG" "$W_ISO_USER_MOUNT_ROOT" -o readonly
                    ;;
                hdiutil)
                    echo "Running $WINETRICKS_ISO_MOUNT attach -mountpoint $W_ISO_USER_MOUNT_ROOT $WINETRICKS_IMG"
                    $WINETRICKS_ISO_MOUNT attach -mountpoint "$W_ISO_USER_MOUNT_ROOT" "$WINETRICKS_IMG"
                    ;;
                *)
                    w_warn "Unknown ISO mount tool $WINETRICKS_ISO_MOUNT, using sudo + mount"
                    unset W_USE_USERMOUNT
                    winetricks_mount_cached_iso
                    return
                    ;;
            esac
            if test $? -ne 0; then
                w_warn "$WINETRICKS_ISO_MOUNT failed, falling back to sudo + mount"
                unset W_USE_USERMOUNT
                winetricks_mount_cached_iso
                return
            fi

            echo "Mounting as drive ${W_ISO_MOUNT_LETTER}:"
            # Gotta provide a symlink to the raw disc, else installers that check volume names will fail
            rm -f "$WINEPREFIX/dosdevices/${W_ISO_MOUNT_LETTER}:"*
            ln -sf "$WINETRICKS_IMG" "$WINEPREFIX/dosdevices/${W_ISO_MOUNT_LETTER}::"
            ln -sf "$W_ISO_USER_MOUNT_ROOT" "$WINEPREFIX/dosdevices/${W_ISO_MOUNT_LETTER}:"
            # Gotta set the type to "cdrom", else "wine eject" will fail
            cat > "$W_TMP"/set_type_cdrom.reg <<_EOF_
REGEDIT4

[HKEY_LOCAL_MACHINE\\Software\\Wine\\Drives]
"${W_ISO_MOUNT_LETTER}:"="cdrom"
_EOF_
            w_try_regedit "$W_TMP"/set_type_cdrom.reg
            # The new drive is not recognized without waiting
            # FIXME: not sure if the duration is appropriate
            sleep 5

            W_ISO_MOUNT_ROOT="$W_ISO_USER_MOUNT_ROOT"
        else
            # Linux (sudo + mount)
            _W_USERID=$(id -u)
            # WINETRICKS_IMG may contain spaces and needs to be quoted
            case "$WINETRICKS_SUDO" in
                gksu*|kdesudo)
                    w_try $WINETRICKS_SUDO "mkdir -p $W_ISO_MOUNT_ROOT"
                    w_try $WINETRICKS_SUDO "mount -o ro,loop,uid=$_W_USERID,unhide '$WINETRICKS_IMG' $W_ISO_MOUNT_ROOT"
                    ;;
                kdesu)
                    w_try $WINETRICKS_SUDO -c "mkdir -p $W_ISO_MOUNT_ROOT"
                    w_try $WINETRICKS_SUDO -c "mount -o ro,loop,uid=$_W_USERID,unhide '$WINETRICKS_IMG' $W_ISO_MOUNT_ROOT"
                    ;;
                *)
                    w_try $WINETRICKS_SUDO mkdir -p "$W_ISO_MOUNT_ROOT"
                    w_try $WINETRICKS_SUDO mount -o ro,loop,uid="$_W_USERID",unhide "$WINETRICKS_IMG" "$W_ISO_MOUNT_ROOT"
                    ;;
            esac

            echo "Mounting as drive ${W_ISO_MOUNT_LETTER}:"
            # Gotta provide a symlink to the raw disc, else installers that check volume names will fail
            rm -f "$WINEPREFIX/dosdevices/${W_ISO_MOUNT_LETTER}:"*
            ln -sf "$WINETRICKS_IMG" "$WINEPREFIX/dosdevices/${W_ISO_MOUNT_LETTER}::"
            ln -sf "$W_ISO_MOUNT_ROOT" "$WINEPREFIX/dosdevices/${W_ISO_MOUNT_LETTER}:"
            unset _W_USERID
        fi
    fi
}

# List the currently mounted UDF or iso9660 filesystems that match the given pattern
# Output format:
#   dev mountpoint
#   dev mountpoint
#   ...
# Mount points may contain spaces.

winetricks_list_mounts()
{
    mount | grep -E 'udf|iso9660' | sed 's,^\([^ ]*\) on \(.*\) type .*,\1 \2,'| grep "$1\$"
}

# Return success and set _W_dev _W_mountpoint if volume $1 is mounted
# Note: setting variables as a way of returning results from a
# shell function exposed several bugs in most shells (except ksh!)
# related to implicit subshells.  It would be better to output
# one string to stdout instead.
winetricks_is_mounted()
{
    # First, check for matching mountpoint
    _W_tmp="$(winetricks_list_mounts "$1")"
    if test "$_W_tmp"; then
        _W_dev=$(echo "$_W_tmp" | sed 's/ .*//')
        _W_mountpoint="$(echo "$_W_tmp" | sed 's/^[^ ]* //')"
        # Volume found!
        return 0
    fi

    # If that fails, read volume name the hard way for each volume
    # Have to use file to return results from implicit subshell
    rm -f "$W_TMP_EARLY/_W_tmp.$LOGNAME"
    winetricks_list_mounts . | while true
    do
        IFS= read -r _W_tmp

        _W_dev=$(echo "$_W_tmp" | sed 's/ .*//')
        test "$_W_dev" || break
        _W_mountpoint="$(echo "$_W_tmp" | sed 's/^[^ ]* //')"
        _W_volname=$(winetricks_volname "$_W_dev")
        if test "$1" = "$_W_volname"; then
            # Volume found!  Want to return from function here, but can't
            echo "$_W_tmp" > "$W_TMP_EARLY/_W_tmp.$LOGNAME"
            break
        fi
    done

    if test -f "$W_TMP_EARLY/_W_tmp.$LOGNAME"; then
        # Volume found!  Return from function.
        _W_dev=$(sed 's/ .*//' "$W_TMP_EARLY/_W_tmp.$LOGNAME")
        _W_mountpoint="$(sed 's/^[^ ]* //' "$W_TMP_EARLY/_W_tmp.$LOGNAME")"
        rm -f "$W_TMP_EARLY/_W_tmp.$LOGNAME"
        return 0
    fi

    # Volume not found
    unset _W_dev _W_mountpoint _W_volname
    return 1
}

winetricks_mount_real_volume()
{
    _W_expected_volname="$1"

    # Wait for user to insert disc.

    case $LANG in
        da*)_W_mountmsg="Indsæt venligst disken '$_W_expected_volname' (krævet af pakken '$W_PACKAGE')" ;;
        de*)_W_mountmsg="Bitte Disk '$_W_expected_volname' einlegen (für Paket '$W_PACKAGE')" ;;
        pl*)  _W_mountmsg="Proszę włożyć dysk '$_W_expected_volname' (potrzebny paczce '$W_PACKAGE')" ;;
        ru*)  _W_mountmsg="Пожалуйста, вставьте том '$_W_expected_volname' (требуется для пакета '$W_PACKAGE')" ;;
        uk*)  _W_mountmsg="Будь ласка, вставте том '$_W_expected_volname' (потрібний для пакунка '$W_PACKAGE')" ;;
        zh_CN*)  _W_mountmsg="请插入卷 '$_W_expected_volname' (为包 '$W_PACKAGE 所需')" ;;
        zh_TW*|zh_HK*)  _W_mountmsg="請插入卷 '$_W_expected_volname' (為包 '$W_PACKAGE 所需')" ;;
        *)  _W_mountmsg="Please insert volume '$_W_expected_volname' (needed for package '$W_PACKAGE')" ;;
    esac

    if test "$WINE" = ""; then
        # Assume already mounted, just get drive letter
        W_ISO_MOUNT_LETTER=$(awk '/iso/ {print $1}' < /proc/mounts | tr -d :)
        W_ISO_MOUNT_ROOT=$(awk '/iso/ {print $2}' < /proc/mounts)
    else
        while ! winetricks_is_mounted "$_W_expected_volname"
        do
            w_try w_warn_cancel "$_W_mountmsg"
            # In non-gui case, give user two seconds to futz with disc drive before spamming him again
            sleep 2
        done
        WINETRICKS_DEV=$_W_dev
        W_ISO_MOUNT_ROOT="$_W_mountpoint"

        # Gotta provide a symlink to the raw disc, else installers that check volume names will fail
        rm -f "$WINEPREFIX/dosdevices/${W_ISO_MOUNT_LETTER}:"*
        ln -sf "$WINETRICKS_DEV" "$WINEPREFIX/dosdevices/${W_ISO_MOUNT_LETTER}::"
        ln -sf "$W_ISO_MOUNT_ROOT" "$WINEPREFIX/dosdevices/${W_ISO_MOUNT_LETTER}:"
    fi

    # FIXME: need to remount some discs with unhide option,
    # add that as option to w_mount

    unset _W_mountmsg
}

winetricks_cleanup()
{
    # We don't want to run this multiple times, so unfortunately we have to run it here:
    if test "$W_NGEN_CMD"; then
        "$W_NGEN_CMD"
    fi

    set +e
    if test -f "$WINETRICKS_WORKDIR/dd-pid"; then
        # shellcheck disable=SC2046
        kill $(cat "$WINETRICKS_WORKDIR/dd-pid")
    fi
    test "$WINETRICKS_CACHE_SYMLINK" && rm -f "$WINETRICKS_CACHE_SYMLINK"
    test "$W_OPT_NOCLEAN" = 1 || rm -rf "$WINETRICKS_WORKDIR"
    # if $W_TMP_EARLY was created by mktemp, remove it (but not if W_OPT_NOCLEAN is set to 1):
    test "$W_OPT_NOCLEAN" = 1 || rm -rf "$W_TMP_EARLY"
}

winetricks_set_unattended()
{
    # We shouldn't use all these extra variables.  Instead, we should
    # use ${foo:+bar} to jam in commandline options for silent install
    # only if W_OPT_UNATTENDED is nonempty.  See
    # https://pubs.opengroup.org/onlinepubs/9699919799/utilities/V3_chap02.html#tag_18_06_02
    # So in attended mode, W_OPT_UNATTENDED should be empty.

    case "$1" in
        1)
            W_OPT_UNATTENDED=1
            # Might want to trim our stable of variables here a bit...
            W_UNATTENDED_SLASH_Q="/q"
            W_UNATTENDED_SLASH_QB="/qb"
            W_UNATTENDED_SLASH_QN="/qn"
            W_UNATTENDED_SLASH_QNT="/qnt"
            W_UNATTENDED_SLASH_QT="/qt"
            W_UNATTENDED_SLASH_QUIET="/quiet"
            W_UNATTENDED_SLASH_S="/S"
            W_UNATTENDED_DASH_SILENT="-silent"
            W_UNATTENDED_SLASH_SILENT="/silent"
            ;;
        *)
            W_OPT_UNATTENDED=""
            W_UNATTENDED_SLASH_Q=""
            W_UNATTENDED_SLASH_QB=""
            W_UNATTENDED_SLASH_QN=""
            W_UNATTENDED_SLASH_QNT=""
            W_UNATTENDED_SLASH_QT=""
            W_UNATTENDED_SLASH_QUIET=""
            W_UNATTENDED_SLASH_S=""
            W_UNATTENDED_DASH_SILENT=""
            W_UNATTENDED_SLASH_SILENT=""
            ;;
    esac
}

# Usage: winetricks_print_wineprefix_info
# Print some useful info about $WINEPREFIX if things fail in winetricks_set_wineprefix()
winetricks_print_wineprefix_info()
{
    printf "WINEPREFIX INFO:\\n"
    printf "Drive C: %s\\n\\n" "$(ls -al1 "${WINEPREFIX}/drive_c")"
    printf "Registry info:\\n"
    for regfile in "${WINEPREFIX}"/*.reg; do
        printf "%s:%s\\n" "${regfile}" "$(grep '#arch=' "${regfile}")"
    done
}

# Force creation of 32 or 64bit wineprefix on 64 bit systems.
# On 32bit systems, trying to create a 64bit wineprefix will fail.
# This must be called prior to winetricks_set_wineprefix()
winetricks_set_winearch()
{
    if [ "$1" = "32" ] || [ "$1" = "win32" ]; then
        export WINEARCH=win32
    elif [ "$1" = "64" ] || [ "$1" = "win64" ]; then
        export WINEARCH=win64
    else
        w_die "arch: Invalid architecture: $1"
    fi
}

# Usage: winetricks_set_wineprefix [bottlename]
# Bottlename must not contain spaces, slashes, or other special characters
# If bottlename is omitted, the default bottle (~/.wine) is used.
winetricks_set_wineprefix()
{
    if ! test "$1"; then
        WINEPREFIX="$WINETRICKS_ORIGINAL_WINEPREFIX"
    else
        WINEPREFIX="$W_PREFIXES_ROOT/$1"
    fi

    export WINEPREFIX
    #echo "WINEPREFIX is now $WINEPREFIX" >&2
    mkdir -p "$(dirname "$WINEPREFIX")"

    # Run wine here to force creation of the wineprefix so it's there when we want to make the cache symlink a bit later.
    # The folder-name is localized!
    W_PROGRAMS_WIN="$(w_expand_env ProgramFiles)"
    case "$W_PROGRAMS_WIN" in
        "") w_info "$(winetricks_print_wineprefix_info)" ; w_die "$WINE cmd.exe /c echo '%ProgramFiles%' returned empty string, error message \"$(cat $W_TMP_EARLY/early_wine.err.txt)\" ";;
        %*) w_info "$(winetricks_print_wineprefix_info)" ; w_die "$WINE cmd.exe /c echo '%ProgramFiles%' returned unexpanded string '$W_PROGRAMS_WIN' ... this can be caused by a corrupt wineprefix (\`wineboot -u\` may help), by an old wine, or by not owning $WINEPREFIX" ;;
        *unknown*) w_info "$(winetricks_print_wineprefix_info)" ; w_die "$WINE cmd.exe /c echo '%ProgramFiles%' returned a string containing the word 'unknown', as if a voice had cried out in terror, and was suddenly silenced." ;;
    esac

    case "$W_PLATFORM" in
        windows_cmd)
            W_DRIVE_C="/cygdrive/c" ;;
        *)
            W_DRIVE_C="$WINEPREFIX/dosdevices/c:" ;;
    esac

    # Kludge: use Temp instead of temp to avoid \t expansion in w_try
    # but use temp in Unix path because that's what Wine creates, and having both temp and Temp
    # causes confusion (e.g. makes vc2005trial fail)
    if ! test "$1"; then
        W_TMP="$W_DRIVE_C/windows/temp"
        W_TMP_WIN="C:\\windows\\Temp"
    else
        # Verbs can rely on W_TMP being empty at entry, deleted after return, and a subdir of C:
        W_TMP="$W_DRIVE_C/windows/temp/_$1"
        W_TMP_WIN="C:\\windows\\Temp\\_$1"
    fi

    case "$W_PLATFORM" in
        "windows_cmd|wine_cmd") W_CACHE_WIN="$(w_pathconv -w "$W_CACHE")" ;;
        *)
            # For case where Z: doesn't exist or / is writable (!),
            # make a drive letter for W_CACHE.  Clean it up on exit.
            test "$WINETRICKS_CACHE_SYMLINK" && rm -f "$WINETRICKS_CACHE_SYMLINK"
            for letter in y x w v u t s r q p o n m
            do
                if ! test -d "$WINEPREFIX"/dosdevices/${letter}:; then
                    mkdir -p "$WINEPREFIX"/dosdevices
                    WINETRICKS_CACHE_SYMLINK="$WINEPREFIX"/dosdevices/${letter}:
                    ln -sf "$W_CACHE" "$WINETRICKS_CACHE_SYMLINK"
                    break
                fi
            done
            W_CACHE_WIN="${letter}:"
            ;;
    esac

    W_COMMONFILES_X86_WIN="$(w_expand_env CommonProgramFiles)"
    W_COMMONFILES_WIN="$(w_expand_env CommonProgramW6432)"

    # CommonProgramW6432 is only defined on win64, not win32 arches
    # win32: %CommonProgramW6432%
    # win64: 'C:\Program Files\Common Files'
    if [ -z "$W_COMMONFILES_WIN" ] || [ "$W_COMMONFILES_WIN" = "%CommonProgramW6432%" ] ; then
        W_COMMONFILES_WIN="$W_COMMONFILES_X86_WIN"
    fi

    W_COMMONFILES_X86="$(w_pathconv -u "$W_COMMONFILES_X86_WIN")"
    #W_COMMONFILES="$(w_pathconv -u "$W_COMMONFILES_WIN")"

    W_PROGRAMS_UNIX="$(w_pathconv -u "$W_PROGRAMS_WIN")"
    W_WINDIR_UNIX="$W_DRIVE_C/windows"

    # 64-bit Windows has a second directory for program files
    W_PROGRAMS_X86_WIN="${W_PROGRAMS_WIN} (x86)"
    W_PROGRAMS_X86_UNIX="${W_PROGRAMS_UNIX} (x86)"
    if ! test -d "$W_PROGRAMS_X86_UNIX"; then
        W_PROGRAMS_X86_WIN="${W_PROGRAMS_WIN}"
        W_PROGRAMS_X86_UNIX="${W_PROGRAMS_UNIX}"
    fi

    W_APPDATA_WIN="$(w_expand_env AppData)"
    # shellcheck disable=SC2034
    W_APPDATA_UNIX="$(w_pathconv -u "$W_APPDATA_WIN")"

    # FIXME: get fonts path from SHGetFolderPath
    # See also https://blogs.msdn.microsoft.com/oldnewthing/20031103-00/?p=41973/
    W_FONTSDIR_WIN="c:\\windows\\Fonts"

    # FIXME: just convert path from Windows to Unix?
    # Did the user rename Fonts to fonts?
    if test ! -d "$W_WINDIR_UNIX"/Fonts && test -d "$W_WINDIR_UNIX"/fonts; then
        W_FONTSDIR_UNIX="$W_WINDIR_UNIX"/fonts
    else
        W_FONTSDIR_UNIX="$W_WINDIR_UNIX"/Fonts
    fi
    mkdir -p "${W_FONTSDIR_UNIX}"

    # Win(e) 32/64?
    # Using the variable W_SYSTEM32_DLLS instead of SYSTEM32 because some stuff does go under system32 for both arch's
    # e.g., spool/drivers/color
    if test -d "$W_DRIVE_C/windows/syswow64"; then
        W_ARCH=win64
        W_SYSTEM32_DLLS="$W_WINDIR_UNIX/syswow64"
        W_SYSTEM32_DLLS_WIN="C:\\windows\\syswow64"
        W_SYSTEM64_DLLS="$W_WINDIR_UNIX/system32"
        # shellcheck disable=SC2034
        W_SYSTEM64_DLLS_WIN32="C:\\windows\\sysnative" # path to access 64-bit dlls from 32-bit apps
        # shellcheck disable=SC2034
        W_SYSTEM64_DLLS_WIN64="C:\\windows\\system32"  # path to access 64-bit dlls from 64-bit apps
        # Common variable for 32-bit dlls on win32/win64:
        W_32BIT_DLLS="$W_WINDIR_UNIX/syswow64"

        # Probably need fancier handling/checking, but for a basic start:
        # Note 'wine' may be named 'wine-stable'/'wine-staging'/etc.):
        # WINE64 = wine64, available on 64-bit prefixes
        # WINE_ARCH = the native wine for the prefix (wine for 32-bit, wine64 for 64-bit)
        # WINE_MULTI = generic wine, new name
        if [ "${WINE%??}64" = "$WINE" ]; then
            WINE64="${WINE}"
        elif command -v "${WINE}64" >/dev/null 2>&1; then
            WINE64="${WINE}64"
        else
            # Handle case where wine binaries (or binary wrappers) have a suffix
            WINE64="$(dirname "$WINE")/"
            [ "$WINE64" = "./" ] && WINE64=""
            WINE64="${WINE64}$(basename "$WINE" | sed 's/^wine/wine64/')"
        fi
        WINE_ARCH="${WINE64}"
        WINE_MULTI="${WINE}"

        # 64-bit prefixes still have plenty of issues:
        case $LANG in
            ru*) w_warn "Вы используете 64-битный WINEPREFIX. Важно: многие ветки устанавливают только 32-битные версии пакетов. Если у вас возникли проблемы, пожалуйста, проверьте еще раз на чистом 32-битном WINEPREFIX до отправки отчета об ошибке." ;;
            *) w_warn "You are using a 64-bit WINEPREFIX. Note that many verbs only install 32-bit versions of packages. If you encounter problems, please retest in a clean 32-bit WINEPREFIX before reporting a bug." ;;
        esac
    else
        W_ARCH=win32
        W_SYSTEM32_DLLS="$W_WINDIR_UNIX/system32"
        W_SYSTEM32_DLLS_WIN="C:\\windows\\system32"
        # Common variable for 32-bit dlls on win32/win64:
        W_32BIT_DLLS="$W_WINDIR_UNIX/system32"

        WINE64="false"
        WINE_ARCH="${WINE}"
        WINE_MULTI="${WINE}"
    fi

    # Unset WINEARCH which might be set from winetricks_set_winearch().
    # It is no longer necessary after the new wineprefix was created
    # and even may cause trouble when using 64bit wineprefixes afterwards.
    unset WINEARCH
}

winetricks_annihilate_wineprefix()
{
    w_skip_windows "No wineprefix to delete on windows" && return

    case $LANG in
        uk*) w_askpermission "Бажаєте видалити '$WINEPREFIX'?" ;;
        pl*) w_askpermission "Czy na pewno chcesz usunąć prefiks $WINEPREFIX i wszystkie jego elementy?" ;;
        *) w_askpermission "Delete $WINEPREFIX, its apps, icons, and menu items?" ;;
    esac

    rm -rf "$WINEPREFIX"

    # Also remove menu items.
    find "$XDG_DATA_HOME/applications/wine" -type f -name '*.desktop' -exec grep -q -l "$WINEPREFIX" '{}' ';' -exec rm '{}' ';'

    # Also remove desktop items.
    # Desktop might be synonym for home directory, so only go one level
    # deep to avoid extreme slowdown if user has lots of files
    (
    if ! test "$XDG_DESKTOP_DIR" && test -f "$XDG_CONFIG_HOME/user-dirs.dirs"; then
        # shellcheck disable=SC1090
        . "$XDG_CONFIG_HOME/user-dirs.dirs"
    fi
    find "$XDG_DESKTOP_DIR" -maxdepth 1 -type f -name '*.desktop' -exec grep -q -l "$WINEPREFIX" '{}' ';' -exec rm '{}' ';'
    )

    # FIXME: recover more nicely.  At moment, have to restart to avoid trouble.
    exit 0
}

winetricks_init()
{
    #---- Private Variables ----

    if ! test "$USERNAME"; then
        # Posix only requires LOGNAME to be defined, and sure enough, when
        # logging in via console and startx in Ubuntu 11.04, USERNAME isn't set!
        # And even normal logins in Ubuntu 13.04 doesn't set it.
        # I tried using only LOGNAME in this script, but it's so easy to slip
        # and use USERNAME, so define it here if needed.
        USERNAME="$LOGNAME"
    fi

    # Running Wine as root is (generally) bad, mmkay?
    if [ "$(id -u)" = 0 ]; then
        w_warn "Running Wine/winetricks as root is highly discouraged. See https://wiki.winehq.org/FAQ#Should_I_run_Wine_as_root.3F"
    fi

    # Ephemeral files for this run
    WINETRICKS_WORKDIR="$W_TMP_EARLY/w.$LOGNAME.$$"
    test "$W_OPT_NOCLEAN" = 1 || rm -rf "$WINETRICKS_WORKDIR"

    # Registering a verb creates a file in WINETRICKS_METADATA
    WINETRICKS_METADATA="$WINETRICKS_WORKDIR/metadata"

    # The list of categories is also hardcoded in winetricks_mainmenu() :-(
    WINETRICKS_CATEGORIES="apps benchmarks dlls fonts games settings mkprefix"
    for _W_cat in $WINETRICKS_CATEGORIES
    do
        mkdir -p "$WINETRICKS_METADATA/$_W_cat"
    done

    # Which subdirectory of WINETRICKS_METADATA is currently active (or main, if none)
    WINETRICKS_CURMENU=prefix

    # Delete work directory after each run, on exit either graceful or abrupt
    trap winetricks_cleanup EXIT HUP INT QUIT ABRT

    # Whether to always cache cached iso's (1) or only use cache if present (0)
    # Can be inherited from environment or set via -k, defaults to off
    WINETRICKS_OPT_KEEPISOS=${WINETRICKS_OPT_KEEPISOS:-0}

    # what program to use to make disc image (dd or ddrescue)
    WINETRICKS_OPT_DD=${WINETRICKS_OPT_DD:-dd}

    # whether to use shared wineprefix (1) or unique wineprefix for each app (0)
    WINETRICKS_OPT_SHAREDPREFIX=${WINETRICKS_OPT_SHAREDPREFIX:-0}

    WINETRICKS_SOURCEFORGE=https://downloads.sourceforge.net

    winetricks_get_sha1sum_prog
    winetricks_get_sha256sum_prog

    winetricks_get_platform

    #---- Public Variables ----

    # Where application installers are cached
    # See https://standards.freedesktop.org/basedir-spec/latest/ar01s03.html
    # OSX: https://developer.apple.com/library/content/documentation/FileManagement/Conceptual/FileSystemProgrammingGuide/MacOSXDirectories/MacOSXDirectories.html

    if test -d "$HOME/Library"; then
        # OS X
        XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/Library/Caches}"
        XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/Library/Preferences}"
    else
        XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
        XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
    fi

    # shellcheck disable=SC2153
    if test "$WINETRICKS_DIR"; then
        # For backwards compatibility
        W_CACHE="${W_CACHE:-$WINETRICKS_DIR/cache}"
        WINETRICKS_POST="${WINETRICKS_POST:-$WINETRICKS_DIR/postinstall}"
    else
        W_CACHE="${W_CACHE:-$XDG_CACHE_HOME/winetricks}"
        WINETRICKS_POST="${WINETRICKS_POST:-$XDG_DATA_HOME/winetricks/postinstall}"
    fi

    WINETRICKS_AUTH="${WINETRICKS_AUTH:-$XDG_DATA_HOME/winetricks/auth}"

    # Config options are currently opt-in and not required, so not creating the config
    # directory unless there's demand:
    WINETRICKS_CONFIG="${XDG_CONFIG_HOME}/winetricks"
    #test -d "$WINETRICKS_CONFIG" || mkdir -p "$WINETRICKS_CONFIG"

    # Load country code from config file only when "--country=" option is not specified
    if test -z "$W_COUNTRY" -a -f "${WINETRICKS_CONFIG}"/country; then
        W_COUNTRY="$(cat "${WINETRICKS_CONFIG}"/country)"
    fi

    # Pin a task to a single cpu. Helps prevent race conditions.
    #
    # Linux/FreeBSD: supported
    # OSX: doesn't have a utility for this
    # Solaris: no access, PR welcome

    if [ -x "$(command -v taskset 2>/dev/null)" ]; then
        W_TASKSET="taskset -c 0"
    elif [ -x "$(command -v cpuset 2>/dev/null)" ]; then
        W_TASKSET="cpuset -l 0"
    else
        # not using w_warn so we don't annoy everyone running via GUI, but still printed to terminal:
        echo "warning: taskset/cpuset not available on your platform!"
        W_TASKSET=""
    fi

    # System-specific variables
    case "$W_PLATFORM" in
        windows_cmd)
            WINE=""
            WINE64=""
            WINE_ARCH=""
            WINE_MULTI=""
            WINESERVER=""
            W_DRIVE_C="C:/"
            ;;
        *)
            WINE="${WINE:-wine}"
            # Find wineserver.
            # Some distributions (Debian before wine 1.8-2) don't have it on the path.
            for x in \
                "$WINESERVER" \
                "${WINE}server" \
                "$(command -v wineserver 2> /dev/null)" \
                "$(dirname $WINE)/server/wineserver" \
                /usr/bin/wineserver-development \
                /usr/lib/wine/wineserver \
                /usr/lib/i386-kfreebsd-gnu/wine/wineserver \
                /usr/lib/i386-linux-gnu/wine/wineserver \
                /usr/lib/powerpc-linux-gnu/wine/wineserver \
                /usr/lib/i386-kfreebsd-gnu/wine/bin/wineserver \
                /usr/lib/i386-linux-gnu/wine/bin/wineserver \
                /usr/lib/powerpc-linux-gnu/wine/bin/wineserver \
                /usr/lib/x86_64-linux-gnu/wine/bin/wineserver \
                /usr/lib/i386-kfreebsd-gnu/wine-development/wineserver \
                /usr/lib/i386-linux-gnu/wine-development/wineserver \
                /usr/lib/powerpc-linux-gnu/wine-development/wineserver \
                /usr/lib/x86_64-linux-gnu/wine-development/wineserver \
                file-not-found
            do
                if test -x "$x"; then
                    case "$x" in
                        /usr/lib/*/wine-development/wineserver|/usr/bin/wineserver-development)
                            if test -x /usr/bin/wine-development; then
                                WINE="/usr/bin/wine-development"
                            fi
                            ;;
                    esac
                    break
                fi
            done

                case "$x" in
                    file-not-found) w_die "wineserver not found!" ;;
                    *) WINESERVER="$x" ;;
                esac

                if test "$WINEPREFIX"; then
                    WINETRICKS_ORIGINAL_WINEPREFIX="$WINEPREFIX"
                else
                    WINETRICKS_ORIGINAL_WINEPREFIX="$HOME/.wine"
                fi
                _abswine="$(command -v "$WINE" 2>/dev/null)"
                if ! test -x "$_abswine" || ! test -f "$_abswine"; then
                    w_die "WINE is $WINE, which is neither on the path nor an executable file"
                fi
                unset _abswine
                ;;
    esac

    winetricks_set_wineprefix "$1"

    # Whether to automate installs (0=no, 1=yes)
    winetricks_set_unattended ${W_OPT_UNATTENDED:-0}

    # Overridden for windows
    W_ISO_MOUNT_ROOT=/mnt/winetricks
    W_ISO_USER_MOUNT_ROOT="$HOME"/winetricks-iso
    W_ISO_MOUNT_LETTER=i

    WINETRICKS_WINE_VERSION=${WINETRICKS_WINE_VERSION:-$(winetricks_early_wine --version | sed 's/.*wine/wine/')}
    WINETRICKS_ORIG_WINE_VERSION="${WINETRICKS_WINE_VERSION}"

    # Need to account for lots of variations:
    # wine-1.9.22
    # wine-1.9.22 (Debian 1.9.22-1)
    # wine-1.9.22 (Staging)
    # wine-2.0 (Debian 2.0-1)
    # wine-2.0-rc1
    # wine-2.8
    _wine_version_stripped="$(echo "$WINETRICKS_WINE_VERSION" | cut -d ' ' -f1 | sed -e 's/wine-//' -e 's/-rc.*//')"

    # If WINE is < 4.0, warn user:
    # 4.0 doesn't do what I thought it would
    if w_wine_version_in 3.99, ; then
        w_warn "Your version of wine $_wine_version_stripped is no longer supported upstream. You should upgrade to 4.x"
    fi

    if [ -z "$WINETRICKS_SUPER_QUIET" ] ; then
        echo "Using winetricks $(winetricks_print_version) with ${WINETRICKS_ORIG_WINE_VERSION} and WINEARCH=${W_ARCH}"
    fi

    winetricks_latest_version_check
}

winetricks_usage()
{
    case $LANG in
        da*)
            cat <<_EOF_
Brug: $0 [tilvalg] [verbum|sti-til-verbum] ...
Kører de angivne verber.  Hvert verbum installerer et program eller ændrer en indstilling.
Tilvalg:
-k|--keep_isos: lagr iso'er lokalt (muliggør senere installation uden disk)
-q|--unattended: stil ingen spørgsmål, installér bare automatisk
-r|--ddrescue: brug alternativ disk-tilgangsmetode (hjælper i tilfælde af en ridset disk)
-t|--torify: Run downloads under torify, if available
-v|--verbose: vis alle kommandoer som de bliver udført
-V|--version: vis programversionen og afslut
-h|--help: vis denne besked og afslut
Diverse verber:
list: vis en liste over alle verber
list-cached: vis en liste over verber for allerede-hentede installationsprogrammer
list-download: vis en liste over verber for programmer der kan hentes
list-manual-download: list applications which can be downloaded with some help from the user
list-installed: list already-installed applications
annihilate            Delete ALL DATA AND APPLICATIONS INSIDE THIS WINEPREFIX
_EOF_
            ;;
        de*)
            cat <<_EOF_
Benutzung: $0 [options] [Kommando|Verb|Pfad-zu-Verb] ...
Angegebene Verben ausführen.
Jedes Verb installiert eine Anwendung oder ändert eine Einstellung.

Optionen:
    --force           Nicht prüfen ob Pakete bereits installiert wurden
    --gui             GUI Diagnosen anzeigen, auch wenn von der Kommandozeile gestartet
    --isolate         Jedes Programm oder Spiel in eigener Bottle (WINEPREFIX) installieren
-k, --keep_isos       ISOs local speichern (erlaubt spätere Installation ohne Disk)
    --no-clean        Temp Verzeichnisse nicht löschen (nützlich beim debuggen)
-q, --unattended      Keine Fragen stellen, alles automatisch installieren
-r, --ddrescue        Alternativer Zugriffsmodus (hilft bei zerkratzten Disks)
-t  --torify          Run downloads under torify, if available
    --verify          Wenn Möglisch automatische GUI Tests für Verben starten
-v, --verbose         Alle ausgeführten Kommandos anzeigen
-h, --help            Diese Hilfemeldung anzeigen
-V, --version         Programmversion anzeigen und Beenden

Kommandos:
list                  Kategorien auflisten
list-all              Alle Kategorien und deren Verben auflisten
apps list             Verben der Kategorie 'Anwendungen' auflisten
benchmarks list       Verben der Kategorie 'Benchmarks' auflisten
dlls list             Verben der Kategorie 'DLLs' auflisten
games list            Verben der Kategorie 'Spiele' auflisten
settings list         Verben der Kategorie 'Einstellungen' auflisten
list-cached           Verben für bereits gecachte Installers auflisten
list-download         Verben für automatisch herunterladbare Anwendungen auflisten
list-manual-download  Verben für vom Benutzer herunterladbare Anwendungen auflisten
list-installed        Bereits installierte Verben auflisten
arch=32|64            Neues wineprefix mit 32 oder 64 bit erstellen, diese Option
                      muss vor prefix=foobar angegeben werden und funktioniert
                      nicht im Falle des Standard Wineprefix.
prefix=foobar         WINEPREFIX=$W_PREFIXES_ROOT/foobar auswählen
annihilate            ALLE DATEIEN UND PROGRAMME IN DIESEM WINEPREFIX Löschen
_EOF_
            ;;
        *)
            cat <<_EOF_
Usage: $0 [options] [command|verb|path-to-verb] ...
Executes given verbs.  Each verb installs an application or changes a setting.

Options:
    --country=CC      Set country code to CC and don't detect your IP address
    --force           Don't check whether packages were already installed
    --gui             Show gui diagnostics even when driven by commandline
    --isolate         Install each app or game in its own bottle (WINEPREFIX)
    --self-update     Update this application to the last version
    --update-rollback Rollback the last self update
-k, --keep_isos       Cache isos (allows later installation without disc)
    --no-clean        Don't delete temp directories (useful during debugging)
-q, --unattended      Don't ask any questions, just install automatically
-r, --ddrescue        Retry hard when caching scratched discs
-t  --torify          Run downloads under torify, if available
    --verify          Run (automated) GUI tests for verbs, if available
-v, --verbose         Echo all commands as they are executed
-h, --help            Display this message and exit
-V, --version         Display version and exit

Commands:
list                  list categories
list-all              list all categories and their verbs
apps list             list verbs in category 'applications'
benchmarks list       list verbs in category 'benchmarks'
dlls list             list verbs in category 'dlls'
games list            list verbs in category 'games'
settings list         list verbs in category 'settings'
list-cached           list cached-and-ready-to-install verbs
list-download         list verbs which download automatically
list-manual-download  list verbs which download with some help from the user
list-installed        list already-installed verbs
arch=32|64            create wineprefix with 32 or 64 bit, this option must be
                      given before prefix=foobar and will not work in case of
                      the default wineprefix.
prefix=foobar         select WINEPREFIX=$W_PREFIXES_ROOT/foobar
annihilate            Delete ALL DATA AND APPLICATIONS INSIDE THIS WINEPREFIX
_EOF_
            ;;
    esac
}

winetricks_handle_option()
{
    case "$1" in
        --country=*) W_COUNTRY="${1##--country=}" ;;
        --force) WINETRICKS_FORCE=1;;
        --gui) winetricks_detect_gui;;
        -h|--help) winetricks_usage ; exit 0 ;;
        --isolate) WINETRICKS_OPT_SHAREDPREFIX=0 ;;
        -k|--keep_isos) WINETRICKS_OPT_KEEPISOS=1 ;;
        --no-clean) W_OPT_NOCLEAN=1 ;;
        --no-isolate) WINETRICKS_OPT_SHAREDPREFIX=1 ;;
        --optin) WINETRICKS_STATS_REPORT=1;;
        --optout) WINETRICKS_STATS_REPORT=0;;
        -q|--unattended) winetricks_set_unattended 1 ;;
        -r|--ddrescue) WINETRICKS_OPT_DD=ddrescue ;;
        --self-update) winetricks_selfupdate;;
        -t|--torify)  WINETRICKS_OPT_TORIFY=1 ;;
        --update-rollback) winetricks_selfupdate_rollback;;
        -v|--verbose) WINETRICKS_OPT_VERBOSE=1 ; set -x;;
        -V|--version) winetricks_print_version ; exit 0;;
        --verify) WINETRICKS_VERIFY=1 ;;
        -vv|--really-verbose) WINETRICKS_OPT_VERBOSE=2 ; set -x ;;
        -*) w_die "unknown option $1" ;;
        *) return 1 ;;
    esac
    return 0
}

# Test whether temporary directory is valid - before initialising script
[ -d "$W_TMP_EARLY" ] || w_die "temporary directory: '$W_TMP_EARLY' ; does not exist"
[ -w "$W_TMP_EARLY" ] || w_die "temporary directory: '$W_TMP_EARLY' ; is not user writeable"

# Must initialize variables before calling w_metadata
if ! test "$WINETRICKS_LIB"
then
    WINETRICKS_SRCDIR=$(dirname "$0")
    WINETRICKS_SRCDIR=$(w_try_cd "$WINETRICKS_SRCDIR"; pwd)

    # Which GUI helper to use (none/zenity/kdialog).  See winetricks_detect_gui.
    WINETRICKS_GUI=none
    # Default to a shared prefix:
    WINETRICKS_OPT_SHAREDPREFIX=${WINETRICKS_OPT_SHAREDPREFIX:-1}

    # Handle options before init, to avoid starting wine for --help or --version
    while winetricks_handle_option "$1"
    do
        shift
    done

    # Workaround for https://github.com/Winetricks/winetricks/issues/599
    # If --isolate is used, pass verb to winetricks_init, so it can set the wineprefix using winetricks_set_wineprefix()
    # Otherwise, an arch mismatch between ${WINEPREFIX:-$HOME/.wine} and the prefix to be made for the isolated app would cause it to fail
    case $WINETRICKS_OPT_SHAREDPREFIX in
        0) winetricks_init "$1" ;;
        *) winetricks_init ;;
    esac
fi

winetricks_install_app()
{
    case $LANG in
        da*) fail_msg="Installationen af pakken $1 fejlede" ;;
        de*) fail_msg="Installieren von Paket $1 gescheitert" ;;
        pl*) fail_msg="Niepowodzenie przy instalacji paczki $1" ;;
        ru*) fail_msg="Ошибка установки пакета $1" ;;
        uk*) fail_msg="Помилка встановлення пакунка $1" ;;
        zh_CN*)   fail_msg="$1 安装失败" ;;
        zh_TW*|zh_HK*)   fail_msg="$1 安裝失敗" ;;
        *)   fail_msg="Failed to install package $1" ;;
    esac

    # FIXME: initialize a new wineprefix for this app, set lots of global variables
    if ! w_do_call "$1" "$2"; then
        w_die "$fail_msg"
    fi
}

#---- Builtin Verbs ----

#----------------------------------------------------------------
# Runtimes
#----------------------------------------------------------------

#----- common download for several verbs
# Note: please put a file list $(cabextract -l $foo) / $(unzip -l $foo) at ./misc/filelists/${helper}.txt

# Filelist at ./misc/filelists/directx-feb2010.txt
helper_directx_dl()
{
    # February 2010 DirectX 9c User Redistributable
    # https://www.microsoft.com/en-us/download/details.aspx?id=9033
    # FIXME: none of the verbs that use this will show download status right
    # until file1 metadata is extended to handle common cache dir
    w_download_to directx9 https://download.microsoft.com/download/E/E/1/EE17FF74-6C45-4575-9CF4-7FC2597ACD18/directx_feb2010_redist.exe f6d191e89a963d7cca34f169d30f49eab99c1ed3bb92da73ec43617caaa1e93f

    DIRECTX_NAME=directx_feb2010_redist.exe
}

# Filelist at ./misc/filelists/directx-jun2010.txt
helper_directx_Jun2010()
{
    # June 2010 DirectX 9c User Redistributable
    # https://www.microsoft.com/en-us/download/details.aspx?id=8109
    w_download_to directx9 https://download.microsoft.com/download/8/4/A/84A35BF1-DAFE-4AE8-82AF-AD2AE20B6B14/directx_Jun2010_redist.exe

    DIRECTX_NAME=directx_Jun2010_redist.exe
}

# Filelist at ./misc/filelists/directx-jun2010.txt
helper_d3dx9_xx()
{
    dllname=d3dx9_$1

    helper_directx_Jun2010

    # Even kinder, less invasive directx - only extract and override d3dx9_xx.dll
    w_try_cabextract -d "$W_TMP" -L -F "*$dllname*x86*" "$W_CACHE"/directx9/$DIRECTX_NAME

    for x in "$W_TMP"/*.cab
    do
      w_try_cabextract -d "$W_SYSTEM32_DLLS" -L -F "$dllname.dll" "$x"
    done

    if test "$W_ARCH" = "win64"; then
        w_try_cabextract -d "$W_TMP" -L -F "*$dllname*x64*" "$W_CACHE"/directx9/$DIRECTX_NAME

        for x in "$W_TMP"/*x64.cab
        do
            w_try_cabextract -d "$W_SYSTEM64_DLLS" -L -F "$dllname.dll" "$x"
        done
    fi

    w_override_dlls native "$dllname"
}

# Filelist at ./misc/filelists/vb6sp6.txt
helper_vb6sp6()
{
    # $1 - directory to extract to
    # $2 .. $n - files to extract from the archive

    destdir="$1"
    shift

    w_download_to vb6sp6 https://download.microsoft.com/download/5/6/3/5635D6A9-885E-4C80-A2E7-8A7F4488FBF1/VB60SP6-KB2708437-x86-ENU.msi 350602b2e084b39c97d1394c8594b18e41ef622315d4a9635c5e8ea6aa977b5e
    w_try_7z "$destdir" "$W_CACHE"/vb6sp6/VB60SP6-KB2708437-x86-ENU.msi "$@"
}

# Filelist at ./misc/filelists/win2ksp4.txt
helper_win2ksp4()
{
    filename=$1

    # Originally at https://www.microsoft.com/en-us/download/details.aspx?id=4127
    # Mirror list at http://www.filewatcher.com/m/w2ksp4_en.exe.135477136-0.html
    # This URL doesn't need rename from w2ksp4_en.exe to W2KSP4_EN.EXE
    # to avoid users having to redownload for a file rename
    w_download_to win2ksp4 https://ftp.gnome.org/mirror/archive/ftp.sunet.se/pub/security/vendor/microsoft/win2000/Service_Packs/usa/W2KSP4_EN.EXE 167bb78d4adc957cc39fb4902517e1f32b1e62092353be5f8fb9ee647642de7e
    w_try_cabextract -d "$W_TMP" -L -F "$filename" "$W_CACHE"/win2ksp4/W2KSP4_EN.EXE
}

# Filelist at ./misc/filelists/winxpsp3.txt
helper_winxpsp3()
{
    filename=$1

    # 2017/03/15: helper was renamed from winxpsp3 to winxpsp3, to match win2k/win7 service pack helpers
    # To minimize user impact, renaming directory automagically.
    # This could be removed after a transition period (1 year or so):
    if [ -d "$W_CACHE/xpsp3" ] ; then
        w_try mv "$W_CACHE/xpsp3" "$W_CACHE/winxpsp3"
    fi

    # Formerly at:
    # https://www.microsoft.com/en-us/download/details.aspx?id=24
    # https://download.microsoft.com/download/d/3/0/d30e32d8-418a-469d-b600-f32ce3edf42d/WindowsXP-KB936929-SP3-x86-ENU.exe
    # Mirror list: http://www.filewatcher.com/m/WindowsXP-KB936929-SP3-x86-ENU.exe.331805736-0.html
    # 2018/04/04: http://www.download.windowsupdate.com/msdownload/update/software/dflt/2008/04/windowsxp-kb936929-sp3-x86-enu_c81472f7eeea2eca421e116cd4c03e2300ebfde4.exe
    w_download_to winxpsp3 https://ftp.gnome.org/mirror/archive/ftp.sunet.se/pub/security/vendor/microsoft/winxp/Service_Packs/WindowsXP-KB936929-SP3-x86-ENU.exe 62e524a552db9f6fd22d469010ea4d7e28ee06fa615a1c34362129f808916654

    w_try_cabextract -d "$W_TMP" -L -F "$filename" "$W_CACHE"/winxpsp3/WindowsXP-KB936929-SP3-x86-ENU.exe
}

# Filelist at ./misc/filelists/win7sp1.txt
helper_win7sp1()
{
    filename=$1

    # https://www.microsoft.com/en-us/download/details.aspx?id=5842
    w_download_to win7sp1 https://download.microsoft.com/download/0/A/F/0AFB5316-3062-494A-AB78-7FB0D4461357/windows6.1-KB976932-X86.exe e5449839955a22fc4dd596291aff1433b998f9797e1c784232226aba1f8abd97

    w_try_cabextract -d "$W_TMP" -L -F "$filename" "$W_CACHE"/win7sp1/windows6.1-KB976932-X86.exe
}

# Filelist at ./misc/filelists/win7sp1_x64.txt
helper_win7sp1_x64()
{
    filename=$1

    # https://www.microsoft.com/en-us/download/details.aspx?id=5842
    w_download_to win7sp1 https://download.microsoft.com/download/0/A/F/0AFB5316-3062-494A-AB78-7FB0D4461357/windows6.1-KB976932-X64.exe f4d1d418d91b1619688a482680ee032ffd2b65e420c6d2eaecf8aa3762aa64c8

    w_try_cabextract -d "$W_TMP" -L -F "$filename" "$W_CACHE"/win7sp1/windows6.1-KB976932-X64.exe
}

#######################
# dlls
#######################

#---------------------------------------------------------

w_metadata adobeair dlls \
    title="Adobe AIR" \
    publisher="Adobe" \
    year="2018" \
    media="download" \
    file1="AdobeAIRInstaller.exe" \
    installed_file1="$W_COMMONFILES_X86_WIN/Adobe AIR/Versions/1.0/Adobe AIR.dll" \
    homepage="https://www.adobe.com/products/air/"

load_adobeair()
{
    # 2017/03/14: 20.0.0.260 (strings 'Adobe AIR.dll' | grep 20\\. ) sha256sum 318770b9a18e59ca4a721a1f5c2b0235cffdbe77a043e99cb2af32074d61de45
    # 2018/01/30: 28.0.0.127 (strings 'Adobe AIR.dll' | grep 28\\. ) sha256sum 9076489e273652089a4a53a1d38c6631e8b7477e39426a843e0273f25bfb109f
    # 2018/03/16: 29.0.0.112 (strings 'Adobe AIR.dll' | grep -E "^29\..+\..+" ) sha256sum 5186b54682644a30f2be61c9b510de9a9a76e301bc1b42f0f1bc50bd809a3625
    # 2018/06/08: 30.0.0.107 (strings 'Adobe AIR.dll' | grep -E "^30\..+\..+" ) sha256sum bcc36174f6f70baba27e5ed1c0df67e55c306ac7bc86b1d280eff4db8c314985
    # 2018/09/12: 31.0.0.96 (strings 'Adobe AIR.dll' | grep -E "^31\..+\..+" ) sha256sum dc82421f135627802b21619bdb7e4b9b0ec16d351120485c575aa6c16cd2737e
    # 2018/12/22: 32.0.0.89 (strings 'Adobe AIR.dll' | grep -E "^32\..+\..+" ) sha256sum 24532d41ef2588c0daac4b6f8b7f863ee3c1a1b1e90b2d8d8b3eb4faa657e5e3
    w_download https://airdownload.adobe.com/air/win/download/latest/AdobeAIRInstaller.exe 24532d41ef2588c0daac4b6f8b7f863ee3c1a1b1e90b2d8d8b3eb4faa657e5e3
    w_try_cd "$W_CACHE/$W_PACKAGE"

    # See https://bugs.winehq.org/show_bug.cgi?id=43506
    # and https://github.com/Winetricks/winetricks/issues/821
    if w_workaround_wine_bug 43506 "Forcing quiet install"; then
        w_try "$WINE" AdobeAIRInstaller.exe -silent
    else
        w_try "$WINE" AdobeAIRInstaller.exe $W_UNATTENDED_DASH_SILENT
    fi
}

#----------------------------------------------------------------

w_metadata amstream dlls \
    title="MS amstream.dll" \
    publisher="Microsoft" \
    year="2011" \
    media="download" \
    file1="../win7sp1/windows6.1-KB976932-X86.exe" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/amstream.dll"

load_amstream()
{
    helper_win7sp1 x86_microsoft-windows-directshow-other_31bf3856ad364e35_6.1.7601.17514_none_0f58f1e53efca91e/amstream.dll
    w_try cp "$W_TMP/x86_microsoft-windows-directshow-other_31bf3856ad364e35_6.1.7601.17514_none_0f58f1e53efca91e/amstream.dll" "$W_SYSTEM32_DLLS/amstream.dll"

    w_override_dlls native,builtin amstream

    w_try_regsvr amstream.dll

    if [ "$W_ARCH" = "win64" ]; then
        helper_win7sp1_x64 amd64_microsoft-windows-directshow-other_31bf3856ad364e35_6.1.7601.17514_none_6b778d68f75a1a54/amstream.dll
        w_try cp "$W_TMP/amd64_microsoft-windows-directshow-other_31bf3856ad364e35_6.1.7601.17514_none_6b778d68f75a1a54/amstream.dll" "$W_SYSTEM64_DLLS/amstream.dll"
        w_try_regsvr64 amstream.dll
    fi
}

#----------------------------------------------------------------

w_metadata art2kmin dlls \
    title="MS Access 2007 runtime" \
    publisher="Microsoft" \
    year="2007" \
    media="download" \
    file1="AccessRuntime.exe" \
    installed_file1="$W_COMMONFILES_X86_WIN/Microsoft Shared/OFFICE12/ACEES.DLL"

load_art2kmin()
{
    # See https://www.microsoft.com/en-us/download/details.aspx?id=4438
    w_download https://download.microsoft.com/download/D/2/A/D2A2FC8B-0447-491C-A5EF-E8AA3A74FB98/AccessRuntime.exe a00a92fdc4ddc0dcf5d1964214a8d7e4c61bb036908a4b43b3700063eda9f4fb
    w_try_cd "$W_CACHE/$W_PACKAGE"
    w_try "$WINE" AccessRuntime.exe $W_UNATTENDED_SLASH_Q
}

#----------------------------------------------------------------

w_metadata atmlib dlls \
    title="Adobe Type Manager" \
    publisher="Adobe" \
    year="2009" \
    media="download" \
    file1="../win2ksp4/W2KSP4_EN.EXE" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/atmlib.dll"

load_atmlib()
{
    helper_win2ksp4 i386/atmlib.dl_
    w_try_cabextract --directory="$W_SYSTEM32_DLLS" "$W_TMP"/i386/atmlib.dl_
}

#----------------------------------------------------------------

w_metadata avifil32 dlls \
    title="MS avifil32" \
    publisher="Microsoft" \
    year="2004" \
    media="download" \
    file1="../winxpsp3/WindowsXP-KB936929-SP3-x86-ENU.exe" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/avifil32.dll"

load_avifil32()
{
    helper_winxpsp3 i386/avifil32.dl_
    w_try_cabextract --directory="$W_SYSTEM32_DLLS" "$W_TMP"/i386/avifil32.dl_

    w_override_dlls native avifil32
}

#----------------------------------------------------------------

w_metadata cabinet dlls \
    title="Microsoft cabinet.dll" \
    publisher="Microsoft" \
    year="2002" \
    media="download" \
    file1="MDAC_TYP.EXE" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/cabinet.dll"

load_cabinet()
{
    # https://www.microsoft.com/downloads/en/details.aspx?FamilyId=9AD000F2-CAE7-493D-B0F3-AE36C570ADE8&displaylang=en
    # Originally at: https://download.microsoft.com/download/3/b/f/3bf74b01-16ba-472d-9a8c-42b2b4fa0d76/mdac_typ.exe
    # Mirror list: http://www.filewatcher.com/m/MDAC_TYP.EXE.5389224-0.html (5.14 MB MDAC_TYP.EXE)
    # 2018/08/09: ftp.gunadarma.ac.id is dead, moved to archive.org
    w_download https://web.archive.org/web/20060718123742/http://ftp.gunadarma.ac.id/pub/driver/itegno/USB%20Software/MDAC/MDAC_TYP.EXE 36d2a3099e6286ae3fab181a502a95fbd825fa5ddb30bf09b345abc7f1f620b4

    w_try_cabextract --directory="${W_TMP}" "${W_CACHE}/${W_PACKAGE}/${file1}"
    w_try cp "${W_TMP}/cabinet.dll" "${W_SYSTEM32_DLLS}/cabinet.dll"

    w_override_dlls native,builtin cabinet
}

#----------------------------------------------------------------

w_metadata cmd dlls \
    title="MS cmd.exe" \
    publisher="Microsoft" \
    year="2004" \
    media="download" \
    file1="Q811493_W2K_SP4_X86_EN.exe" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/cmd.exe"

load_cmd()
{
    # Originally at: https://download.microsoft.com/download/8/d/c/8dc79965-dfbc-4b25-9546-e23bc4b791c6/Q811493_W2K_SP4_X86_EN.exe
    # Mirror list: http://www.filewatcher.com/_/?q=Q811493_W2K_SP4_X86_EN.exe
    w_download https://ftp.gnome.org/mirror/archive/ftp.sunet.se/pub/security/vendor/microsoft/win2000/Security_Bulletins/Q811493_W2K_SP4_X86_EN.exe b5574b3516a724c2cba0d864162a3d1d684db1cf30de8db4b0e0ea6a1f6f1480
    w_try_cabextract --directory="$W_SYSTEM32_DLLS" "$W_CACHE/$W_PACKAGE/$file1" -F cmd.exe

    w_override_dlls native,builtin cmd.exe
}

#----------------------------------------------------------------

w_metadata cnc_ddraw dlls \
    title="Reimplentation of ddraw for CnC games" \
    homepage="https://github.com/CnCNet/cnc-ddraw" \
    publisher="CnCNet" \
    year="2018" \
    media="download" \
    file1="cnc-ddraw.zip" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/Shaders/readme.txt"

load_cnc_ddraw()
{
    # Note: only works if ddraw.ini contains settings for the executable
    w_download https://github.com/CnCNet/cnc-ddraw/releases/download/1.3.4.0/cnc-ddraw.zip c1f85053223ab04a573cc482b43b93a58077e928a401f3364c9dc5542ad090ae
    w_try_unzip "$W_SYSTEM32_DLLS" "$W_CACHE/$W_PACKAGE/$file1"

    w_override_dlls native,builtin ddraw
}

#----------------------------------------------------------------

w_metadata comctl32 dlls \
    title="MS common controls 5.80" \
    publisher="Microsoft" \
    year="2001" \
    media="download" \
    file1="cc32inst.exe" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/comctl32.dll"

load_comctl32()
{
    # Microsoft has removed. Mirrors can be found at http://www.filewatcher.com/m/CC32inst.exe.587496-0.html
    # 2011/01/17: https://www.microsoft.com/en-us/download/details.aspx?id=14672
    # 2012/08/11: w_download https://download.microsoft.com/download/platformsdk/redist/5.80.2614.3600/w9xnt4/en-us/cc32inst.exe d68c0cca721870aed39f5f2efd80dfb74f3db66d5f9a49e7578b18279edfa4a7
    # 2016/01/07: w_download ftp://ftp.ie.debian.org/disk1/download.sourceforge.net/pub/sourceforge/p/po/pocmin/Win%2095_98%20Controls/Win%2095_98%20Controls/CC32inst.exe
    # 2017/03/12: w_download $WINETRICKS_SOURCEFORGE/project/pocmin/Win%2095_98%20Controls/Win%2095_98%20Controls/CC32inst.exe

    w_download $WINETRICKS_SOURCEFORGE/project/pocmin/Win%2095_98%20Controls/Win%2095_98%20Controls/CC32inst.exe d68c0cca721870aed39f5f2efd80dfb74f3db66d5f9a49e7578b18279edfa4a7

    w_try "$WINE" "$W_CACHE"/comctl32/cc32inst.exe "/T:$W_TMP_WIN" /c $W_UNATTENDED_SLASH_Q
    w_try_unzip "$W_TMP" "$W_TMP"/comctl32.exe
    w_try "$WINE" "$W_TMP"/x86/50ComUpd.Exe "/T:$W_TMP_WIN" /c $W_UNATTENDED_SLASH_Q
    w_try cp "$W_TMP"/comcnt.dll "$W_SYSTEM32_DLLS"/comctl32.dll

    w_override_dlls native,builtin comctl32

    # some builtin apps don't like native comctl32
    w_override_app_dlls winecfg.exe builtin comctl32
    w_override_app_dlls explorer.exe builtin comctl32
    w_override_app_dlls iexplore.exe builtin comctl32
}

#----------------------------------------------------------------

w_metadata comctl32ocx dlls \
    title="MS comctl32.ocx and mscomctl.ocx, comctl32 wrappers for VB6" \
    publisher="Microsoft" \
    year="2012" \
    media="download" \
    file1="../vb6sp6/VB60SP6-KB2708437-x86-ENU.msi" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/mscomctl.ocx"

load_comctl32ocx()
{
    helper_vb6sp6 "$W_SYSTEM32_DLLS" comctl32.ocx mscomctl.ocx mscomct2.ocx

    w_try_regsvr comctl32.ocx
    w_try_regsvr mscomctl.ocx
    w_try_regsvr mscomct2.ocx
}

#----------------------------------------------------------------

w_metadata comdlg32ocx dlls \
    title="Common Dialog ActiveX Control for VB6" \
    publisher="Microsoft" \
    year="2012" \
    media="download" \
    file1="../vb6sp6/VB60SP6-KB2708437-x86-ENU.msi" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/comdlg32.ocx"

load_comdlg32ocx()
{
    helper_vb6sp6 "$W_TMP" ComDlg32.ocx
    w_try mv "$W_TMP/ComDlg32.ocx" "$W_SYSTEM32_DLLS/comdlg32.ocx"
    w_try_regsvr comdlg32.ocx
}

#----------------------------------------------------------------

w_metadata crypt32 dlls \
    title="MS crypt32" \
    publisher="Microsoft" \
    year="2004" \
    media="download" \
    file1="../winxpsp3/WindowsXP-KB936929-SP3-x86-ENU.exe" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/crypt32.dll"

load_crypt32()
{
    w_call msasn1

    helper_winxpsp3 i386/crypt32.dl_
    w_try_cabextract --directory="$W_SYSTEM32_DLLS" "$W_TMP"/i386/crypt32.dl_

    w_override_dlls native crypt32
}

#----------------------------------------------------------------

w_metadata binkw32 dlls \
    title="RAD Game Tools binkw32.dll" \
    publisher="RAD Game Tools, Inc." \
    year="2000" \
    media="download" \
    file1="__32-binkw32.dll3.0.0.0.zip" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/binkw32.dll"

load_binkw32()
{
    # Mirror: https://www.dlldump.com/download-dll-files_new.php/dllfiles/B/binkw32.dll/1.0q/download.html
    # sha256sum of the decompressed file: 1fd7ef7873c8a3be7e2f127b306d0d24d7d88e20cf9188894eff87b5af0d495f
    #
    # Zip sha256sum:
    # 2015/12/27: 1d5efda8e4af796319b94034ba67b453cbbfddd81eb7d94fd059b40e237fa75d

    w_download http://www.down-dll.com/dll/b/__32-binkw32.dll3.0.0.0.zip 1d5efda8e4af796319b94034ba67b453cbbfddd81eb7d94fd059b40e237fa75d

    w_try_unzip "$W_TMP" "$W_CACHE"/binkw32/__32-binkw32.dll3.0.0.0.zip
    w_try cp "$W_TMP"/binkw32.dll "$W_SYSTEM32_DLLS"/binkw32.dll

    w_override_dlls native binkw32
}

#----------------------------------------------------------------

w_metadata d3dcompiler_43 dlls \
    title="MS d3dcompiler_43.dll" \
    publisher="Microsoft" \
    year="2010" \
    media="download" \
    file1="../directx9/directx_Jun2010_redist.exe" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/d3dcompiler_43.dll"

load_d3dcompiler_43()
{
    if w_workaround_wine_bug 24013; then
        w_warn "Native d3dcompiler_43 may cause some d3d10 apps to crash, see https://bugs.winehq.org/show_bug.cgi?id=24013"
    fi

    dllname=d3dcompiler_43

    helper_directx_Jun2010

    w_try_cabextract -d "$W_TMP" -L -F "*$dllname*x86*" "$W_CACHE"/directx9/$DIRECTX_NAME
    for x in "$W_TMP"/*.cab
    do
      w_try_cabextract -d "$W_SYSTEM32_DLLS" -L -F "$dllname.dll" "$x"
    done
    if test "$W_ARCH" = "win64"; then
        w_try_cabextract -d "$W_TMP" -L -F "*$dllname*x64*" "$W_CACHE"/directx9/$DIRECTX_NAME
        for x in "$W_TMP"/*x64.cab
        do
            w_try_cabextract -d "$W_SYSTEM64_DLLS" -L -F "$dllname.dll" "$x"
        done
    fi

    w_override_dlls native $dllname
}

#----------------------------------------------------------------

w_metadata d3dcompiler_47 dlls \
    title="MS d3dcompiler_47.dll" \
    publisher="Microsoft" \
    year="FIXME" \
    media="download" \
    file1="FirefoxSetup62.0.3-win32.exe" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/d3dcompiler_47.dll"

load_d3dcompiler_47()
{
    # FIXME: would be awesome to find a small download that has both 32/64bit dlls, but this works for now:

    w_download https://download-installer.cdn.mozilla.net/pub/firefox/releases/62.0.3/win32/ach/Firefox%20Setup%2062.0.3.exe "d6edb4ff0a713f417ebd19baedfe07527c6e45e84a6c73ed8c66a33377cc0aca" "FirefoxSetup62.0.3-win32.exe"
    w_try_7z "$W_TMP/win32" "$W_CACHE/d3dcompiler_47/FirefoxSetup62.0.3-win32.exe" "core/d3dcompiler_47.dll"
    w_try cp "$W_TMP/win32/core/d3dcompiler_47.dll" "$W_SYSTEM32_DLLS/d3dcompiler_47.dll"

    if [ "$W_ARCH" = "win64" ]; then
        w_download https://download-installer.cdn.mozilla.net/pub/firefox/releases/62.0.3/win64/ach/Firefox%20Setup%2062.0.3.exe "721977f36c008af2b637aedd3f1b529f3cfed6feb10f68ebe17469acb1934986" "FirefoxSetup62.0.3-win64.exe"
        w_try_7z "$W_TMP/win64" "$W_CACHE/d3dcompiler_47/FirefoxSetup62.0.3-win64.exe" "core/d3dcompiler_47.dll"
        w_try cp "$W_TMP/win64/core/d3dcompiler_47.dll" "$W_SYSTEM64_DLLS/d3dcompiler_47.dll"
    fi

    w_override_dlls native d3dcompiler_47
}

#----------------------------------------------------------------

w_metadata d3drm dlls \
    title="MS d3drm.dll" \
    publisher="Microsoft" \
    year="2010" \
    media="download" \
    file1="../directx9/directx_feb2010_redist.exe" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/d3drm.dll"

load_d3drm()
{
    helper_directx_dl

    w_try_cabextract -d "$W_TMP" -L -F "dxnt.cab" "$W_CACHE"/directx9/$DIRECTX_NAME
    w_try_cabextract -d "$W_SYSTEM32_DLLS" -L -F "d3drm.dll" "$W_TMP/dxnt.cab"

    w_override_dlls native d3drm
}

#----------------------------------------------------------------

w_metadata d3dx9 dlls \
    title="MS d3dx9_??.dll from DirectX 9 redistributable" \
    publisher="Microsoft" \
    year="2010" \
    media="download" \
    file1="../directx9/directx_Jun2010_redist.exe" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/d3dx9_43.dll"

load_d3dx9()
{
    helper_directx_Jun2010

    # Kinder, less invasive directx - only extract and override d3dx9_??.dll
    w_try_cabextract -d "$W_TMP" -L -F '*d3dx9*x86*' "$W_CACHE"/directx9/$DIRECTX_NAME
    for x in "$W_TMP"/*.cab
    do
      w_try_cabextract -d "$W_SYSTEM32_DLLS" -L -F 'd3dx9*.dll' "$x"
    done
    if test "$W_ARCH" = "win64"; then
        w_try_cabextract -d "$W_TMP" -L -F '*d3dx9*x64*' "$W_CACHE"/directx9/$DIRECTX_NAME
        for x in "$W_TMP"/*x64.cab
        do
            w_try_cabextract -d "$W_SYSTEM64_DLLS" -L -F 'd3dx9*.dll' "$x"
        done
    fi

    # For now, not needed, but when Wine starts preferring our builtin dll over native it will be.
    w_override_dlls native d3dx9_24 d3dx9_25 d3dx9_26 d3dx9_27 d3dx9_28 d3dx9_29 d3dx9_30
    w_override_dlls native d3dx9_31 d3dx9_32 d3dx9_33 d3dx9_34 d3dx9_35 d3dx9_36 d3dx9_37
    w_override_dlls native d3dx9_38 d3dx9_39 d3dx9_40 d3dx9_41 d3dx9_42 d3dx9_43
}

#----------------------------------------------------------------

w_metadata d3dx9_24 dlls \
    title="MS d3dx9_24.dll" \
    publisher="Microsoft" \
    year="2010" \
    media="download" \
    file1="../directx9/directx_feb2010_redist.exe" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/d3dx9_24.dll"

load_d3dx9_24()
{
    helper_d3dx9_xx 24
}

#----------------------------------------------------------------

w_metadata d3dx9_25 dlls \
    title="MS d3dx9_25.dll" \
    publisher="Microsoft" \
    year="2010" \
    media="download" \
    file1="../directx9/directx_Jun2010_redist.exe" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/d3dx9_25.dll"

load_d3dx9_25()
{
    helper_d3dx9_xx 25
}

#----------------------------------------------------------------

w_metadata d3dx9_26 dlls \
    title="MS d3dx9_26.dll" \
    publisher="Microsoft" \
    year="2010" \
    media="download" \
    file1="../directx9/directx_Jun2010_redist.exe" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/d3dx9_26.dll"

load_d3dx9_26()
{
    helper_d3dx9_xx 26
}

#----------------------------------------------------------------

w_metadata d3dx9_27 dlls \
    title="MS d3dx9_27.dll" \
    publisher="Microsoft" \
    year="2010" \
    media="download" \
    file1="../directx9/directx_Jun2010_redist.exe" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/d3dx9_27.dll"

load_d3dx9_27()
{
    helper_d3dx9_xx 27
}

#----------------------------------------------------------------

w_metadata d3dx9_28 dlls \
    title="MS d3dx9_28.dll" \
    publisher="Microsoft" \
    year="2010" \
    media="download" \
    file1="../directx9/directx_Jun2010_redist.exe" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/d3dx9_28.dll"

load_d3dx9_28()
{
    helper_d3dx9_xx 28
}

#----------------------------------------------------------------

w_metadata d3dx9_29 dlls \
    title="MS d3dx9_29.dll" \
    publisher="Microsoft" \
    year="2010" \
    media="download" \
    file1="../directx9/directx_Jun2010_redist.exe" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/d3dx9_29.dll"

load_d3dx9_29()
{
    helper_d3dx9_xx 29
}

#----------------------------------------------------------------

w_metadata d3dx9_30 dlls \
    title="MS d3dx9_30.dll" \
    publisher="Microsoft" \
    year="2010" \
    media="download" \
    file1="../directx9/directx_Jun2010_redist.exe" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/d3dx9_30.dll"

load_d3dx9_30()
{
    helper_d3dx9_xx 30
}

#----------------------------------------------------------------

w_metadata d3dx9_31 dlls \
    title="MS d3dx9_31.dll" \
    publisher="Microsoft" \
    year="2010" \
    media="download" \
    file1="../directx9/directx_Jun2010_redist.exe" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/d3dx9_31.dll"

load_d3dx9_31()
{
    helper_d3dx9_xx 31
}

#----------------------------------------------------------------

w_metadata d3dx9_32 dlls \
    title="MS d3dx9_32.dll" \
    publisher="Microsoft" \
    year="2010" \
    media="download" \
    file1="../directx9/directx_Jun2010_redist.exe" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/d3dx9_32.dll"

load_d3dx9_32()
{
    helper_d3dx9_xx 32
}

#----------------------------------------------------------------

w_metadata d3dx9_33 dlls \
    title="MS d3dx9_33.dll" \
    publisher="Microsoft" \
    year="2010" \
    media="download" \
    file1="../directx9/directx_Jun2010_redist.exe" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/d3dx9_33.dll"

load_d3dx9_33()
{
    helper_d3dx9_xx 33
}

#----------------------------------------------------------------

w_metadata d3dx9_34 dlls \
    title="MS d3dx9_34.dll" \
    publisher="Microsoft" \
    year="2010" \
    media="download" \
    file1="../directx9/directx_Jun2010_redist.exe" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/d3dx9_34.dll"

load_d3dx9_34()
{
    helper_d3dx9_xx 34
}

#----------------------------------------------------------------

w_metadata d3dx9_35 dlls \
    title="MS d3dx9_35.dll" \
    publisher="Microsoft" \
    year="2010" \
    media="download" \
    file1="../directx9/directx_Jun2010_redist.exe" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/d3dx9_35.dll"

load_d3dx9_35()
{
    helper_d3dx9_xx 35
}

#----------------------------------------------------------------

w_metadata d3dx9_36 dlls \
    title="MS d3dx9_36.dll" \
    publisher="Microsoft" \
    year="2010" \
    media="download" \
    file1="../directx9/directx_Jun2010_redist.exe" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/d3dx9_36.dll"

load_d3dx9_36()
{
    helper_d3dx9_xx 36
}

#----------------------------------------------------------------

w_metadata d3dx9_37 dlls \
    title="MS d3dx9_37.dll" \
    publisher="Microsoft" \
    year="2010" \
    media="download" \
    file1="../directx9/directx_Jun2010_redist.exe" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/d3dx9_37.dll"

load_d3dx9_37()
{
    helper_d3dx9_xx 37
}

#----------------------------------------------------------------

w_metadata d3dx9_38 dlls \
    title="MS d3dx9_38.dll" \
    publisher="Microsoft" \
    year="2010" \
    media="download" \
    file1="../directx9/directx_Jun2010_redist.exe" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/d3dx9_38.dll"

load_d3dx9_38()
{
    helper_d3dx9_xx 38
}

#----------------------------------------------------------------

w_metadata d3dx9_39 dlls \
    title="MS d3dx9_39.dll" \
    publisher="Microsoft" \
    year="2010" \
    media="download" \
    file1="../directx9/directx_Jun2010_redist.exe" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/d3dx9_39.dll"

load_d3dx9_39()
{
    helper_d3dx9_xx 39
}

#----------------------------------------------------------------

w_metadata d3dx9_40 dlls \
    title="MS d3dx9_40.dll" \
    publisher="Microsoft" \
    year="2010" \
    media="download" \
    file1="../directx9/directx_Jun2010_redist.exe" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/d3dx9_40.dll"

load_d3dx9_40()
{
    helper_d3dx9_xx 40
}

#----------------------------------------------------------------

w_metadata d3dx9_41 dlls \
    title="MS d3dx9_41.dll" \
    publisher="Microsoft" \
    year="2010" \
    media="download" \
    file1="../directx9/directx_Jun2010_redist.exe" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/d3dx9_41.dll"

load_d3dx9_41()
{
    helper_d3dx9_xx 41
}

#----------------------------------------------------------------

w_metadata d3dx9_42 dlls \
    title="MS d3dx9_42.dll" \
    publisher="Microsoft" \
    year="2010" \
    media="download" \
    file1="../directx9/directx_Jun2010_redist.exe" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/d3dx9_42.dll"

load_d3dx9_42()
{
    helper_d3dx9_xx 42
}

#----------------------------------------------------------------

w_metadata d3dx9_43 dlls \
    title="MS d3dx9_43.dll" \
    publisher="Microsoft" \
    year="2010" \
    media="download" \
    file1="../directx9/directx_Jun2010_redist.exe" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/d3dx9_43.dll"

load_d3dx9_43()
{
    helper_d3dx9_xx 43
}

#----------------------------------------------------------------

w_metadata d3dx11_42 dlls \
    title="MS d3dx11_42.dll" \
    publisher="Microsoft" \
    year="2010" \
    media="download" \
    file1="../directx9/directx_Jun2010_redist.exe" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/d3dx11_42.dll"

load_d3dx11_42()
{
    dllname=d3dx11_42

    helper_directx_Jun2010

    w_try_cabextract -d "$W_TMP" -L -F "*$dllname*x86*" "$W_CACHE"/directx9/$DIRECTX_NAME
    for x in "$W_TMP"/*.cab
    do
      w_try_cabextract -d "$W_SYSTEM32_DLLS" -L -F "$dllname.dll" "$x"
    done
    if test "$W_ARCH" = "win64"; then
        w_try_cabextract -d "$W_TMP" -L -F "*$dllname*x64*" "$W_CACHE"/directx9/$DIRECTX_NAME
        for x in "$W_TMP"/*x64.cab
        do
            w_try_cabextract -d "$W_SYSTEM64_DLLS" -L -F "$dllname.dll" "$x"
        done
    fi

    w_override_dlls native $dllname
}

#----------------------------------------------------------------

w_metadata d3dx11_43 dlls \
    title="MS d3dx11_43.dll" \
    publisher="Microsoft" \
    year="2010" \
    media="download" \
    file1="../directx9/directx_Jun2010_redist.exe" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/d3dx11_43.dll"

load_d3dx11_43()
{
    dllname=d3dx11_43

    helper_directx_Jun2010

    w_try_cabextract -d "$W_TMP" -L -F "*$dllname*x86*" "$W_CACHE"/directx9/$DIRECTX_NAME
    for x in "$W_TMP"/*.cab
    do
      w_try_cabextract -d "$W_SYSTEM32_DLLS" -L -F "$dllname.dll" "$x"
    done
    if test "$W_ARCH" = "win64"; then
        w_try_cabextract -d "$W_TMP" -L -F "*$dllname*x64*" "$W_CACHE"/directx9/$DIRECTX_NAME
        for x in "$W_TMP"/*x64.cab
        do
            w_try_cabextract -d "$W_SYSTEM64_DLLS" -L -F "$dllname.dll" "$x"
        done
    fi

    w_override_dlls native $dllname
}

#----------------------------------------------------------------

w_metadata d3dx10 dlls \
    title="MS d3dx10_??.dll from DirectX user redistributable" \
    publisher="Microsoft" \
    year="2010" \
    media="download" \
    file1="../directx9/directx_Jun2010_redist.exe" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/d3dx10_33.dll"

load_d3dx10()
{
    helper_directx_Jun2010

    # Kinder, less invasive directx10 - only extract and override d3dx10_??.dll
    w_try_cabextract -d "$W_TMP" -L -F '*d3dx10*x86*' "$W_CACHE"/directx9/$DIRECTX_NAME
    for x in "$W_TMP"/*.cab
    do
      w_try_cabextract -d "$W_SYSTEM32_DLLS" -L -F 'd3dx10*.dll' "$x"
    done
    if test "$W_ARCH" = "win64"; then
        w_try_cabextract -d "$W_TMP" -L -F '*d3dx10*x64*' "$W_CACHE"/directx9/$DIRECTX_NAME
        for x in "$W_TMP"/*x64.cab
        do
            w_try_cabextract -d "$W_SYSTEM64_DLLS" -L -F 'd3dx10*.dll' "$x"
        done
    fi

    # For now, not needed, but when Wine starts preferring our built-in DLL over native it will be.
    w_override_dlls native d3dx10_33 d3dx10_34 d3dx10_35 d3dx10_36 d3dx10_37
    w_override_dlls native d3dx10_38 d3dx10_39 d3dx10_40 d3dx10_41 d3dx10_42 d3dx10_43
}

#----------------------------------------------------------------

w_metadata d3dx10_43 dlls \
    title="MS d3dx10_43.dll" \
    publisher="Microsoft" \
    year="2010" \
    media="download" \
    file1="../directx9/directx_Jun2010_redist.exe" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/d3dx10_43.dll"

load_d3dx10_43()
{
    dllname=d3dx10_43

    helper_directx_Jun2010

    w_try_cabextract -d "$W_TMP" -L -F "*$dllname*x86*" "$W_CACHE"/directx9/$DIRECTX_NAME
    for x in "$W_TMP"/*.cab
    do
      w_try_cabextract -d "$W_SYSTEM32_DLLS" -L -F "$dllname.dll" "$x"
    done
    if test "$W_ARCH" = "win64"; then
        w_try_cabextract -d "$W_TMP" -L -F "*$dllname*x64*" "$W_CACHE"/directx9/$DIRECTX_NAME
        for x in "$W_TMP"/*x64.cab
        do
            w_try_cabextract -d "$W_SYSTEM64_DLLS" -L -F "$dllname.dll" "$x"
        done
    fi

    w_override_dlls native $dllname
}

#----------------------------------------------------------------

w_metadata d3dxof dlls \
    title="MS d3dxof.dll from DirectX user redistributable" \
    publisher="Microsoft" \
    year="2010" \
    media="download" \
    file1="../directx9/directx_feb2010_redist.exe" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/d3dxof.dll"

load_d3dxof()
{
    helper_directx_dl

    w_try_cabextract -d "$W_TMP" -L -F 'dxnt.cab' "$W_CACHE"/directx9/$DIRECTX_NAME
    w_try_cabextract -d "$W_SYSTEM32_DLLS" -L -F 'd3dxof.dll' "$W_TMP/dxnt.cab"

    w_override_dlls native d3dxof
}

#----------------------------------------------------------------

w_metadata dbghelp dlls \
    title="MS dbghelp" \
    publisher="Microsoft" \
    year="2008" \
    media="download" \
    file1="../winxpsp3/WindowsXP-KB936929-SP3-x86-ENU.exe" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/dbghelp.dll"

load_dbghelp()
{
    helper_winxpsp3 i386/dbghelp.dll

    w_try cp -f "$W_TMP"/i386/dbghelp.dll "$W_SYSTEM32_DLLS"

    w_override_dlls native dbghelp
}

#----------------------------------------------------------------

w_metadata devenum dlls \
    title="MS devenum.dll from DirectX user redistributable" \
    publisher="Microsoft" \
    year="2010" \
    media="download" \
    file1="../directx9/directx_feb2010_redist.exe" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/devenum.dll"

load_devenum()
{
    helper_directx_dl

    w_try_cabextract -d "$W_TMP" -L -F 'dxnt.cab' "$W_CACHE/directx9/$DIRECTX_NAME"
    w_try_cabextract -d "$W_SYSTEM32_DLLS" -L -F 'devenum.dll' "$W_TMP/dxnt.cab"
    w_override_dlls native devenum
    w_try_regsvr devenum.dll
}

#----------------------------------------------------------------

w_metadata dinput dlls \
    title="MS dinput.dll; breaks mouse, use only on Rayman 2 etc." \
    publisher="Microsoft" \
    year="2010" \
    media="download" \
    file1="../directx9/directx_feb2010_redist.exe" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/dinput.dll"

load_dinput()
{
    helper_directx_dl

    w_try_cabextract -d "$W_TMP" -L -F 'dxnt.cab' "$W_CACHE"/directx9/$DIRECTX_NAME
    w_try_cabextract -d "$W_SYSTEM32_DLLS" -L -F 'dinput.dll' "$W_TMP/dxnt.cab"
    w_override_dlls native dinput
    w_try_regsvr dinput
}

#----------------------------------------------------------------

w_metadata dinput8 dlls \
    title="MS DirectInput 8 from DirectX user redistributable" \
    publisher="Microsoft" \
    year="2010" \
    media="download" \
    file1="../directx9/directx_feb2010_redist.exe" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/dinput8.dll"

load_dinput8()
{
    helper_directx_dl

    w_try_cabextract -d "$W_TMP" -L -F 'dxnt.cab' "$W_CACHE"/directx9/$DIRECTX_NAME
    w_try_cabextract -d "$W_SYSTEM32_DLLS" -L -F 'dinput8.dll' "$W_TMP/dxnt.cab"
    w_override_dlls native dinput8
    w_try_regsvr dinput8
}

#----------------------------------------------------------------

w_metadata directmusic dlls \
    title="MS DirectMusic from DirectX user redistributable" \
    publisher="Microsoft" \
    year="2010" \
    media="download" \
    file1="../directx9/directx_feb2010_redist.exe"

load_directmusic()
{
# Untested. Based off https://bugs.winehq.org/show_bug.cgi?id=4805 and https://bugs.winehq.org/show_bug.cgi?id=24911

    w_warn "You can specify individual DirectMusic verbs instead. e.g. 'winetricks dmsynth dmusic'"

    w_call devenum
    w_call dmband
    w_call dmcompos
    w_call dmime
    w_call dmloader
    w_call dmscript
    w_call dmstyle
    w_call dmsynth
    w_call dmusic
    w_call dmusic32
    w_call dsound
    w_call dswave
    w_call quartz

    # FIXME: dxnt.cab doesn't contain this DLL. Is this really needed?
    w_override_dlls native streamci
}

#----------------------------------------------------------------

w_metadata directshow dlls \
    title="DirectShow runtime DLLs (amstream, qasf, qcap, qdvd, qedit, quartz)" \
    publisher="Microsoft" \
    year="2011" \
    media="download" \
    file1="../win7sp1/windows6.1-KB976932-X86.exe"

load_directshow()
{
    w_warn "You can specify individual DirectShow verbs instead. e.g. 'winetricks quartz'"

    w_call amstream
    w_call qasf
    w_call qcap
    w_call qdvd
    w_call qedit
    w_call quartz
}

#----------------------------------------------------------------

w_metadata directplay dlls \
    title="MS DirectPlay from DirectX user redistributable" \
    publisher="Microsoft" \
    year="2010" \
    media="download" \
    file1="../directx9/directx_feb2010_redist.exe" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/dplayx.dll"

load_directplay()
{
    helper_directx_dl

    w_try_cabextract -d "$W_TMP" -L -F dxnt.cab "$W_CACHE"/directx9/$DIRECTX_NAME
    w_try_cabextract -d "$W_SYSTEM32_DLLS" -L -F 'dplaysvr.exe' "$W_TMP/dxnt.cab"
    w_try_cabextract -d "$W_SYSTEM32_DLLS" -L -F 'dplayx.dll' "$W_TMP/dxnt.cab"
    w_try_cabextract -d "$W_SYSTEM32_DLLS" -L -F 'dpnet.dll' "$W_TMP/dxnt.cab"
    w_try_cabextract -d "$W_SYSTEM32_DLLS" -L -F 'dpnhpast.dll' "$W_TMP/dxnt.cab"
    w_try_cabextract -d "$W_SYSTEM32_DLLS" -L -F 'dpnsvr.exe' "$W_TMP/dxnt.cab"
    w_try_cabextract -d "$W_SYSTEM32_DLLS" -L -F 'dpwsockx.dll' "$W_TMP/dxnt.cab"

    w_override_dlls native dplayx dpnet dpnhpast dpnsvr.exe dpwsockx

    w_try_regsvr dplayx.dll
    w_try_regsvr dpnet.dll
    w_try_regsvr dpnhpast.dll
}

#----------------------------------------------------------------

w_metadata directx9 dlls \
    title="MS DirectX 9 (Usually overkill.  Try d3dx9_36 first)" \
    publisher="Microsoft" \
    year="2010" \
    media="download" \
    file1="directx_feb2010_redist.exe" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/d3dx10_33.dll"

load_directx9()
{
    helper_directx_dl

    w_warn "You probably shouldn't be using this.  d3dx9 or, better, d3dx9_36 usually suffice."

    # Stefan suggested that, when installing, one should override as follows:
    # 1) use built-in wintrust (we don't run native properly somehow?)
    # 2) disable mscoree (else if it's present some module misbehaves?)
    # 3) override native any DirectX DLL whose Wine version doesn't register itself well yet
    # For #3, I have no idea which DLLs don't register themselves well yet,
    # so I'm just listing a few of the basic ones.  Let's whittle that
    # list down as soon as we can.

    # Setting Windows version to win2k apparently crashes the installer on OS X.
    # FIXME: seems this didn't get migrated to Github?
    # See https://code.google.com/p/winezeug/issues/detail?id=71
    w_set_winver winxp

    w_try_cd "$W_CACHE/$W_PACKAGE"
    WINEDLLOVERRIDES="wintrust=b,mscoree=,ddraw,d3d8,d3d9,dsound,dinput=n" \
        w_try "$WINE" $DIRECTX_NAME /t:"$W_TMP_WIN" $W_UNATTENDED_SLASH_Q

    # How many of these do we really need?
    # We should probably remove most of these...?
    w_call devenum
    w_call directshow

    w_try_cabextract -d "$W_TMP" -L -F dxnt.cab "$W_CACHE"/directx9/$DIRECTX_NAME
    w_try_cabextract -d "$W_SYSTEM32_DLLS" -L -F "msdmo.dll" "$W_TMP/dxnt.cab"

    w_override_dlls native d3dim d3drm d3dx8 d3dx9_24 d3dx9_25 d3dx9_26 d3dx9_27 d3dx9_28 d3dx9_29
    w_override_dlls native d3dx9_30 d3dx9_31 d3dx9_32 d3dx9_33 d3dx9_34 d3dx9_35 d3dx9_36 d3dx9_37
    w_override_dlls native d3dx9_38 d3dx9_39 d3dx9_40 d3dx9_41 d3dx9_42 d3dx9_43 d3dxof
    w_override_dlls native dciman32 ddrawex dmband dmcompos dmime dmloader dmscript dmstyle
    w_override_dlls native dmsynth dmusic dmusic32 dplay dplayx dpnaddr dpnet dpnhpast dpnlobby
    w_override_dlls native dswave dxdiagn msdmo streamci
    w_override_dlls native dxdiag.exe
    w_override_dlls builtin d3d8 d3d9 dinput dinput8 dsound

    w_try "$WINE" "$W_TMP_WIN"\\DXSETUP.exe $W_UNATTENDED_SLASH_SILENT
}

#----------------------------------------------------------------

w_metadata dpvoice dlls \
    title="Microsoft dpvoice dpvvox dpvacm Audio dlls" \
    publisher="Microsoft" \
    year="2002" \
    media="download" \
    file1="../directx9/directx_feb2010_redist.exe" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/dpvoice.dll" \
    installed_file2="$W_SYSTEM32_DLLS_WIN/dpvvox.dll" \
    installed_file2="$W_SYSTEM32_DLLS_WIN/dpvacm.dll"

load_dpvoice()
{
    helper_directx_dl

    w_try_cabextract -d "$W_TMP" -L -F 'dxnt.cab' "$W_CACHE"/directx9/$DIRECTX_NAME
    for x in "$W_TMP"/*.cab
    do
      w_try_cabextract -d "$W_SYSTEM32_DLLS" -L -F 'dpvoice.dll' "$x"
      w_try_cabextract -d "$W_SYSTEM32_DLLS" -L -F 'dpvvox.dll' "$x"
      w_try_cabextract -d "$W_SYSTEM32_DLLS" -L -F 'dpvacm.dll' "$x"
    done
    w_override_dlls native dpvoice dpvvox dpvacm
    w_try_regsvr dpvoice.dll
    w_try_regsvr dpvvox.dll
    w_try_regsvr dpvacm.dll
}

#----------------------------------------------------------------

w_metadata dsdmo dlls \
    title="MS dsdmo.dll" \
    publisher="Microsoft" \
    year="2010" \
    media="download" \
    file1="../directx9/directx_feb2010_redist.exe" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/dsdmo.dll"

load_dsdmo()
{
    helper_directx_dl
    mkdir "$W_CACHE"/dsdmo   # kludge so test -f $file1 works

    w_try_cabextract -d "$W_TMP" -L -F dxnt.cab "$W_CACHE"/directx9/$DIRECTX_NAME
    w_try_cabextract -d "$W_SYSTEM32_DLLS" -L -F 'dsdmo.dll' "$W_TMP/dxnt.cab"
    w_try_cabextract -d "$W_SYSTEM32_DLLS" -L -F 'dsdmoprp.dll' "$W_TMP/dxnt.cab"
    w_try_regsvr dsdmo.dll
    w_try_regsvr dsdmoprp.dll
}

#----------------------------------------------------------------

w_metadata dxsdk_nov2006 dlls \
    title="MS DirectX SDK, November 2006 (developers only)" \
    publisher="Microsoft" \
    year="2006" \
    media="download" \
    file1="dxsdk_aug2006.exe" \
    installed_file1="$W_PROGRAMS_X86_WIN/Microsoft DirectX SDK (August 2006)/Lib/x86/d3d10.lib"

load_dxsdk_nov2006()
{
    w_download https://download.microsoft.com/download/9/e/5/9e5bfc66-a621-4e0d-8bfe-6688058c3f00/dxsdk_aug2006.exe ab8d7d895089a88108d4148ef0f7e214b7a23c1ee9ba720feca78c7d4ca16c00

    # dxview.dll uses mfc42u while registering
    w_call mfc42

    w_try_cabextract "$W_CACHE"/dxsdk_nov2006/dxsdk_aug2006.exe
    w_try_unzip "$W_TMP" dxsdk.exe
    w_try_cd "$W_TMP"
    w_try "$WINE" msiexec /i Microsoft_DirectX_SDK.msi $W_UNATTENDED_SLASH_Q
}

#----------------------------------------------------------------

w_metadata dxsdk_jun2010 dlls \
    title="MS DirectX SDK, June 2010 (developers only)" \
    publisher="Microsoft" \
    year="2010" \
    media="download" \
    file1="DXSDK_Jun10.exe" \
    installed_file1="$W_PROGRAMS_X86_WIN/Microsoft DirectX SDK (June 2010)/Lib/x86/d3d11.lib"

load_dxsdk_jun2010()
{
    w_download https://download.microsoft.com/download/A/E/7/AE743F1F-632B-4809-87A9-AA1BB3458E31/DXSDK_Jun10.exe 9f818a977c32b254af5d649a4cec269ed8762f8a49ae67a9f01101a7237ae61a

    # Without dotnet20, install aborts halfway through
    w_call dotnet20

    w_try_cd "$W_TMP"
    w_try "$WINE" "$W_CACHE"/dxsdk_jun2010/DXSDK_Jun10.exe ${W_OPT_UNATTENDED:+/U}
}

#----------------------------------------------------------------

# $1 - dxvk archive name (required)
# $2 - dxvk d3d10_enabled / d3d10_disabled (required)
# $3 - minimum Wine version (optional)
# $4 - minimum Vulkan API version (optional, requires $3 be set)
helper_dxvk()
{
    _W_dxvk_archive="${1}"
    _W_dxvk_d3d10="${2}"
    _W_min_wine_version="${3}"
    _W_min_vulkan_version="${4}"

    case $_W_dxvk_d3d10 in
        d3d10_enabled) _W_dll_overrides="d3d10 d3d10_1 d3d10core d3d11 dxgi";;
        d3d10_disabled) _W_dll_overrides="d3d11 dxgi";;
        *) w_die "parameter unsupported: $_W_dxvk_d3d10 ; supported parameters: d3d10_enabled d3d10_disabled"
    esac

    _W_dxvk_dir="${_W_dxvk_archive%.tar.gz}"
    _W_dxvk_version="${_W_dxvk_dir#*-}"

    w_warn "Please refer to dxvk version ${_W_dxvk_version} release notes... See: https://github.com/doitsujin/dxvk/releases/tag/v${_W_dxvk_version}"
    if [ -n "$_W_min_wine_version" ] && ! w_wine_version_in ",${_W_min_wine_version}" ; then
        [ -z "$_W_min_vulkan_version" ] || _W_vulkan_info=" The base requirement is Vulkan $_W_min_vulkan_version API support."
        w_warn "dxvk ${_W_dxvk_version} does not support wine version ${_wine_version_stripped}. dxvk ${_W_dxvk_version} requires wine version ${_W_min_wine_version} (or newer).${_W_vulkan_info}"
        unset _W_vulkan_info
    fi
    w_warn "Please refer to current dxvk base graphics driver requirements... See: https://github.com/doitsujin/dxvk/wiki/Driver-support"

    w_try_cd "$W_TMP"
    w_try tar -zxf "$W_CACHE/$W_PACKAGE/$_W_dxvk_archive"
    for _W_dll in $_W_dll_overrides; do
        w_try mv "$W_TMP/$_W_dxvk_dir/x32/$_W_dll.dll" "$W_SYSTEM32_DLLS/"
    done
    if test "$W_ARCH" = "win64"; then
        for _W_dll in $_W_dll_overrides; do
            w_try mv "$W_TMP/$_W_dxvk_dir/x64/$_W_dll.dll" "$W_SYSTEM64_DLLS/"
        done
    fi
    # shellcheck disable=SC2086
    w_override_dlls native $_W_dll_overrides

    unset _W_dll _W_dll_overrides _W_dxvk_archive _W_dxvk_d3d10 _W_dxvk_dir _W_dxvk_version _W_min_vulkan_version _W_min_wine_version
}

#----------------------------------------------------------------

w_metadata dxvk54 dlls \
    title="Vulkan-based D3D11 implementation for Linux / Wine (0.54)" \
    publisher="Philip Rebohle" \
    year="2018" \
    media="download" \
    file1="dxvk-0.54.tar.gz" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/d3d11.dll" \
    installed_file2="$W_SYSTEM32_DLLS_WIN/dxgi.dll"

load_dxvk54()
{
    # https://github.com/doitsujin/dxvk
    w_download "https://github.com/doitsujin/dxvk/releases/download/v0.54/dxvk-0.54.tar.gz" 1c2f186baaa01d2de7b832f6f05021bdd29eccb65fc197c8b15adfd4e08f9640
    helper_dxvk "$file1" "d3d10_disabled" "3.6"
}

#----------------------------------------------------------------

w_metadata dxvk60 dlls \
    title="Vulkan-based D3D11 implementation for Linux / Wine (0.60)" \
    publisher="Philip Rebohle" \
    year="2018" \
    media="download" \
    file1="dxvk-0.60.tar.gz" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/d3d11.dll" \
    installed_file2="$W_SYSTEM32_DLLS_WIN/dxgi.dll"

load_dxvk60()
{
    # https://github.com/doitsujin/dxvk
    w_download "https://github.com/doitsujin/dxvk/releases/download/v0.60/dxvk-0.60.tar.gz" 27d6f700241d3ec3b6c002c3d739bb0e3f210ec916ecb5a62d9204e9e50f2c4a
    helper_dxvk "$file1" "d3d10_disabled" "3.10" "1.0.76"
}

#----------------------------------------------------------------

w_metadata dxvk61 dlls \
    title="Vulkan-based D3D11 implementation for Linux / Wine (0.61)" \
    publisher="Philip Rebohle" \
    year="2018" \
    media="download" \
    file1="dxvk-0.61.tar.gz" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/d3d11.dll" \
    installed_file2="$W_SYSTEM32_DLLS_WIN/dxgi.dll"

load_dxvk61()
{
    # https://github.com/doitsujin/dxvk
    w_download "https://github.com/doitsujin/dxvk/releases/download/v0.61/dxvk-0.61.tar.gz" d04388f026dc0d8b276b08f7db74fb3556cbbc8f762401eb5ef52629ee39ded1
    helper_dxvk "$file1" "d3d10_disabled" "3.10" "1.0.76"
}

#----------------------------------------------------------------

w_metadata dxvk62 dlls \
    title="Vulkan-based D3D11 implementation for Linux / Wine (0.62)" \
    publisher="Philip Rebohle" \
    year="2018" \
    media="download" \
    file1="dxvk-0.62.tar.gz" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/d3d11.dll" \
    installed_file2="$W_SYSTEM32_DLLS_WIN/dxgi.dll"

load_dxvk62()
{
    # https://github.com/doitsujin/dxvk
    w_download "https://github.com/doitsujin/dxvk/releases/download/v0.62/dxvk-0.62.tar.gz" b9dbb57908e24b094b68f665ad729b6ee277eecc8ba04a6e6e4f8a4d2dfd94e3
    helper_dxvk "$file1" "d3d10_disabled" "3.10" "1.0.76"
}

w_metadata dxvk63 dlls \
    title="Vulkan-based D3D11 implementation for Linux / Wine (0.63)" \
    publisher="Philip Rebohle" \
    year="2018" \
    media="download" \
    file1="dxvk-0.63.tar.gz" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/d3d11.dll" \
    installed_file2="$W_SYSTEM32_DLLS_WIN/dxgi.dll"

load_dxvk63()
{
    # https://github.com/doitsujin/dxvk
    w_download "https://github.com/doitsujin/dxvk/releases/download/v0.63/dxvk-0.63.tar.gz" 696df816bd9640770dee14f932bc641a16261fccf76be7c28d812a64ca6040fa
    helper_dxvk "$file1" "d3d10_disabled" "3.10" "1.0.76"
}

w_metadata dxvk64 dlls \
    title="Vulkan-based D3D11 implementation for Linux / Wine (0.64)" \
    publisher="Philip Rebohle" \
    year="2018" \
    media="download" \
    file1="dxvk-0.64.tar.gz" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/d3d11.dll" \
    installed_file2="$W_SYSTEM32_DLLS_WIN/dxgi.dll"

load_dxvk64()
{
    # https://github.com/doitsujin/dxvk
    w_download "https://github.com/doitsujin/dxvk/releases/download/v0.64/dxvk-0.64.tar.gz" 2e03e40ff0a9d36f96a06137f3fa9110ebaea230d0bf6c22cf6399e16e97fb9c
    helper_dxvk "$file1" "d3d10_disabled" "3.10" "1.0.76"
}

w_metadata dxvk65 dlls \
    title="Vulkan-based D3D11 implementation for Linux / Wine (0.65)" \
    publisher="Philip Rebohle" \
    year="2018" \
    media="download" \
    file1="dxvk-0.65.tar.gz" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/d3d11.dll" \
    installed_file2="$W_SYSTEM32_DLLS_WIN/dxgi.dll"

load_dxvk65()
{
    # https://github.com/doitsujin/dxvk
    w_download "https://github.com/doitsujin/dxvk/releases/download/v0.65/dxvk-0.65.tar.gz" 7b4eb42e693f925d0aff90bae261b20c50428602382ee94a3e3860b2ad1ebad0
    helper_dxvk "$file1" "d3d10_disabled" "3.10" "1.0.76"
}

w_metadata dxvk70 dlls \
    title="Vulkan-based D3D10/D3D11 implementation for Linux / Wine (0.70)" \
    publisher="Philip Rebohle" \
    year="2018" \
    media="download" \
    file1="dxvk-0.70.tar.gz" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/d3d10.dll" \
    installed_file2="$W_SYSTEM32_DLLS_WIN/d3d10_1.dll" \
    installed_file3="$W_SYSTEM32_DLLS_WIN/d3d10core.dll" \
    installed_file4="$W_SYSTEM32_DLLS_WIN/d3d11.dll" \
    installed_file5="$W_SYSTEM32_DLLS_WIN/dxgi.dll"

load_dxvk70()
{
    # https://github.com/doitsujin/dxvk
    w_download "https://github.com/doitsujin/dxvk/releases/download/v0.70/dxvk-0.70.tar.gz" 310546d530be494a35cae49b707fef4b073269d811aac25bdf72899ed1df4e9f
    helper_dxvk "$file1" "d3d10_enabled" "3.10" "1.0.76"
}

w_metadata dxvk71 dlls \
    title="Vulkan-based D3D10/D3D11 implementation for Linux / Wine (0.71)" \
    publisher="Philip Rebohle" \
    year="2018" \
    media="download" \
    file1="dxvk-0.71.tar.gz" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/d3d10.dll" \
    installed_file2="$W_SYSTEM32_DLLS_WIN/d3d10_1.dll" \
    installed_file3="$W_SYSTEM32_DLLS_WIN/d3d10core.dll" \
    installed_file4="$W_SYSTEM32_DLLS_WIN/d3d11.dll" \
    installed_file5="$W_SYSTEM32_DLLS_WIN/dxgi.dll"

load_dxvk71()
{
    # https://github.com/doitsujin/dxvk
    w_download "https://github.com/doitsujin/dxvk/releases/download/v0.71/dxvk-0.71.tar.gz" fbe66337d1450f366961a7699253cd7a96c12a88c2fcda64b79be1cbb13d37d5
    helper_dxvk "$file1" "d3d10_enabled" "3.10" "1.0.76"
}

w_metadata dxvk72 dlls \
    title="Vulkan-based D3D10/D3D11 implementation for Linux / Wine (0.72)" \
    publisher="Philip Rebohle" \
    year="2018" \
    media="download" \
    file1="dxvk-0.72.tar.gz" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/d3d10.dll" \
    installed_file2="$W_SYSTEM32_DLLS_WIN/d3d10_1.dll" \
    installed_file3="$W_SYSTEM32_DLLS_WIN/d3d10core.dll" \
    installed_file4="$W_SYSTEM32_DLLS_WIN/d3d11.dll" \
    installed_file5="$W_SYSTEM32_DLLS_WIN/dxgi.dll"

load_dxvk72()
{
    # https://github.com/doitsujin/dxvk
    w_download "https://github.com/doitsujin/dxvk/releases/download/v0.72/dxvk-0.72.tar.gz" bc84f48f99cf5add3c8919a43d7a9c0bf208c994dc58326a636b56b8db650c52
    helper_dxvk "$file1" "d3d10_enabled" "3.10" "1.0.76"
}

w_metadata dxvk80 dlls \
    title="Vulkan-based D3D10/D3D11 implementation for Linux / Wine (0.80)" \
    publisher="Philip Rebohle" \
    year="2018" \
    media="download" \
    file1="dxvk-0.80.tar.gz" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/d3d10.dll" \
    installed_file2="$W_SYSTEM32_DLLS_WIN/d3d10_1.dll" \
    installed_file3="$W_SYSTEM32_DLLS_WIN/d3d10core.dll" \
    installed_file4="$W_SYSTEM32_DLLS_WIN/d3d11.dll" \
    installed_file5="$W_SYSTEM32_DLLS_WIN/dxgi.dll"

load_dxvk80()
{
    # https://github.com/doitsujin/dxvk
    # 2018/09/23: f9e736cdbf1e83e45ca748652a94a3a189fc5accde1eac549b2ba5af8f7acacb
    # 2018/11/17: 7058a834bb006cad5462933110449b434df561e67d83f68d3965ecc74e2e1cbc
    # See: https://github.com/doitsujin/dxvk/issues/773
    w_download "https://github.com/doitsujin/dxvk/releases/download/v0.80/dxvk-0.80.tar.gz" 7058a834bb006cad5462933110449b434df561e67d83f68d3965ecc74e2e1cbc
    helper_dxvk "$file1" "d3d10_enabled" "3.10" "1.0.76"
}

w_metadata dxvk81 dlls \
    title="Vulkan-based D3D10/D3D11 implementation for Linux / Wine (0.81)" \
    publisher="Philip Rebohle" \
    year="2018" \
    media="download" \
    file1="dxvk-0.81.tar.gz" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/d3d10.dll" \
    installed_file2="$W_SYSTEM32_DLLS_WIN/d3d10_1.dll" \
    installed_file3="$W_SYSTEM32_DLLS_WIN/d3d10core.dll" \
    installed_file4="$W_SYSTEM32_DLLS_WIN/d3d11.dll" \
    installed_file5="$W_SYSTEM32_DLLS_WIN/dxgi.dll"

load_dxvk81()
{
    # https://github.com/doitsujin/dxvk
    w_download "https://github.com/doitsujin/dxvk/releases/download/v0.81/dxvk-0.81.tar.gz" 9bf6eda9ae4ee74b509e07dfe9cc003dfa4bba192b519dacdd542a57f6a43869
    helper_dxvk "$file1" "d3d10_enabled" "3.10" "1.0.76"
}

w_metadata dxvk90 dlls \
    title="Vulkan-based D3D10/D3D11 implementation for Linux / Wine (0.90)" \
    publisher="Philip Rebohle" \
    year="2018" \
    media="download" \
    file1="dxvk-0.90.tar.gz" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/d3d10.dll" \
    installed_file2="$W_SYSTEM32_DLLS_WIN/d3d10_1.dll" \
    installed_file3="$W_SYSTEM32_DLLS_WIN/d3d10core.dll" \
    installed_file4="$W_SYSTEM32_DLLS_WIN/d3d11.dll" \
    installed_file5="$W_SYSTEM32_DLLS_WIN/dxgi.dll"

load_dxvk90()
{
    # https://github.com/doitsujin/dxvk
    w_download "https://github.com/doitsujin/dxvk/releases/download/v0.90/dxvk-0.90.tar.gz" 15bce7b282065054ff9233b33738bf1d2c74b16829361cbd6843bc2f5dfe4509
    helper_dxvk "$file1" "d3d10_enabled" "3.19" "1.1.88"
}

w_metadata dxvk91 dlls \
    title="Vulkan-based D3D10/D3D11 implementation for Linux / Wine (0.91)" \
    publisher="Philip Rebohle" \
    year="2018" \
    media="download" \
    file1="dxvk-0.91.tar.gz" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/d3d10.dll" \
    installed_file2="$W_SYSTEM32_DLLS_WIN/d3d10_1.dll" \
    installed_file3="$W_SYSTEM32_DLLS_WIN/d3d10core.dll" \
    installed_file4="$W_SYSTEM32_DLLS_WIN/d3d11.dll" \
    installed_file5="$W_SYSTEM32_DLLS_WIN/dxgi.dll"

load_dxvk91()
{
    # https://github.com/doitsujin/dxvk
    w_download "https://github.com/doitsujin/dxvk/releases/download/v0.91/dxvk-0.91.tar.gz" 5296106ac3a8c631d7f26fa46dbff4be1332cda14fa493fd89ccf97e050c4855
    helper_dxvk "$file1" "d3d10_enabled" "3.19" "1.1.88"
}

w_metadata dxvk92 dlls \
    title="Vulkan-based D3D10/D3D11 implementation for Linux / Wine (0.92)" \
    publisher="Philip Rebohle" \
    year="2018" \
    media="download" \
    file1="dxvk-0.92.tar.gz" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/d3d10.dll" \
    installed_file2="$W_SYSTEM32_DLLS_WIN/d3d10_1.dll" \
    installed_file3="$W_SYSTEM32_DLLS_WIN/d3d10core.dll" \
    installed_file4="$W_SYSTEM32_DLLS_WIN/d3d11.dll" \
    installed_file5="$W_SYSTEM32_DLLS_WIN/dxgi.dll"

load_dxvk92()
{
    # https://github.com/doitsujin/dxvk
    w_download "https://github.com/doitsujin/dxvk/releases/download/v0.92/dxvk-0.92.tar.gz" e22c0ae4693aac88562c7a9a97b3316e086b9048c9f8f9e128923ac1611a5c49
    helper_dxvk "$file1" "d3d10_enabled" "3.19" "1.1.88"
}

w_metadata dxvk93 dlls \
    title="Vulkan-based D3D10/D3D11 implementation for Linux / Wine (0.93)" \
    publisher="Philip Rebohle" \
    year="2018" \
    media="download" \
    file1="dxvk-0.93.tar.gz" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/d3d10.dll" \
    installed_file2="$W_SYSTEM32_DLLS_WIN/d3d10_1.dll" \
    installed_file3="$W_SYSTEM32_DLLS_WIN/d3d10core.dll" \
    installed_file4="$W_SYSTEM32_DLLS_WIN/d3d11.dll" \
    installed_file5="$W_SYSTEM32_DLLS_WIN/dxgi.dll"

load_dxvk93()
{
    # https://github.com/doitsujin/dxvk
    w_download "https://github.com/doitsujin/dxvk/releases/download/v0.93/dxvk-0.93.tar.gz" 4d964e4e10e67ba7705312496e472ae9859520a78d8742d6d377886318c95e53
    helper_dxvk "$file1" "d3d10_enabled" "3.19" "1.1.88"
}

w_metadata dxvk94 dlls \
    title="Vulkan-based D3D10/D3D11 implementation for Linux / Wine (0.94)" \
    publisher="Philip Rebohle" \
    year="2018" \
    media="download" \
    file1="dxvk-0.94.tar.gz" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/d3d10.dll" \
    installed_file2="$W_SYSTEM32_DLLS_WIN/d3d10_1.dll" \
    installed_file3="$W_SYSTEM32_DLLS_WIN/d3d10core.dll" \
    installed_file4="$W_SYSTEM32_DLLS_WIN/d3d11.dll" \
    installed_file5="$W_SYSTEM32_DLLS_WIN/dxgi.dll"

load_dxvk94()
{
    # https://github.com/doitsujin/dxvk
    w_download "https://github.com/doitsujin/dxvk/releases/download/v0.94/dxvk-0.94.tar.gz" 1f06bfac5b435b62b972806fb3bbd86f7ccae2399b4451e85ae414e03d3712a3
    helper_dxvk "$file1" "d3d10_enabled" "3.19" "1.1.88"
}

w_metadata dxvk95 dlls \
    title="Vulkan-based D3D10/D3D11 implementation for Linux / Wine (0.95)" \
    publisher="Philip Rebohle" \
    year="2018" \
    media="download" \
    file1="dxvk-0.95.tar.gz" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/d3d10.dll" \
    installed_file2="$W_SYSTEM32_DLLS_WIN/d3d10_1.dll" \
    installed_file3="$W_SYSTEM32_DLLS_WIN/d3d10core.dll" \
    installed_file4="$W_SYSTEM32_DLLS_WIN/d3d11.dll" \
    installed_file5="$W_SYSTEM32_DLLS_WIN/dxgi.dll"

load_dxvk95()
{
    # https://github.com/doitsujin/dxvk
    w_download "https://github.com/doitsujin/dxvk/releases/download/v0.95/dxvk-0.95.tar.gz" 1eea48149f6e94c3c74ecddd92df4f9daa67ab28d0fca548bde5cd40f0e486bf
    helper_dxvk "$file1" "d3d10_enabled" "3.19" "1.1.88"
}

w_metadata dxvk96 dlls \
    title="Vulkan-based D3D10/D3D11 implementation for Linux / Wine (0.96)" \
    publisher="Philip Rebohle" \
    year="2018" \
    media="download" \
    file1="dxvk-0.96.tar.gz" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/d3d10.dll" \
    installed_file2="$W_SYSTEM32_DLLS_WIN/d3d10_1.dll" \
    installed_file3="$W_SYSTEM32_DLLS_WIN/d3d10core.dll" \
    installed_file4="$W_SYSTEM32_DLLS_WIN/d3d11.dll" \
    installed_file5="$W_SYSTEM32_DLLS_WIN/dxgi.dll"

load_dxvk96()
{
    # https://github.com/doitsujin/dxvk
    w_download "https://github.com/doitsujin/dxvk/releases/download/v0.96/dxvk-0.96.tar.gz" 9d054c1e7a4f59825c651b14d3cfbf0d8c724763f485b3d59c89f1d7194b2206
    helper_dxvk "$file1" "d3d10_enabled" "3.19" "1.1.88"
}

w_metadata dxvk100 dlls \
    title="Vulkan-based D3D10/D3D11 implementation for Linux / Wine (1.0)" \
    publisher="Philip Rebohle" \
    year="2018" \
    media="download" \
    file1="dxvk-1.0.tar.gz" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/d3d10.dll" \
    installed_file2="$W_SYSTEM32_DLLS_WIN/d3d10_1.dll" \
    installed_file3="$W_SYSTEM32_DLLS_WIN/d3d10core.dll" \
    installed_file4="$W_SYSTEM32_DLLS_WIN/d3d11.dll" \
    installed_file5="$W_SYSTEM32_DLLS_WIN/dxgi.dll"

load_dxvk100()
{
    # https://github.com/doitsujin/dxvk
    w_download "https://github.com/doitsujin/dxvk/releases/download/v1.0/dxvk-1.0.tar.gz" 8c8d26544609532201c10e6f5309bf5e913b5ca5b985932928ef9ab238de6dc2
    helper_dxvk "$file1" "d3d10_enabled" "3.19" "1.1.88"
}

w_metadata dxvk101 dlls \
    title="Vulkan-based D3D10/D3D11 implementation for Linux / Wine (1.0.1)" \
    publisher="Philip Rebohle" \
    year="2018" \
    media="download" \
    file1="dxvk-1.0.1.tar.gz" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/d3d10.dll" \
    installed_file2="$W_SYSTEM32_DLLS_WIN/d3d10_1.dll" \
    installed_file3="$W_SYSTEM32_DLLS_WIN/d3d10core.dll" \
    installed_file4="$W_SYSTEM32_DLLS_WIN/d3d11.dll" \
    installed_file5="$W_SYSTEM32_DLLS_WIN/dxgi.dll"

load_dxvk101()
{
    # https://github.com/doitsujin/dxvk
    w_download "https://github.com/doitsujin/dxvk/releases/download/v1.0.1/dxvk-1.0.1.tar.gz" 739847cdd14b302dac600c66bc6617d7814945df6d4d7b6c91fecfa910e3b1b1
    helper_dxvk "$file1" "d3d10_enabled" "3.19" "1.1.88"
}

w_metadata dxvk102 dlls \
    title="Vulkan-based D3D10/D3D11 implementation for Linux / Wine (1.0.2)" \
    publisher="Philip Rebohle" \
    year="2018" \
    media="download" \
    file1="dxvk-1.0.2.tar.gz" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/d3d10.dll" \
    installed_file2="$W_SYSTEM32_DLLS_WIN/d3d10_1.dll" \
    installed_file3="$W_SYSTEM32_DLLS_WIN/d3d10core.dll" \
    installed_file4="$W_SYSTEM32_DLLS_WIN/d3d11.dll" \
    installed_file5="$W_SYSTEM32_DLLS_WIN/dxgi.dll"

load_dxvk102()
{
    # https://github.com/doitsujin/dxvk
    w_download "https://github.com/doitsujin/dxvk/releases/download/v1.0.2/dxvk-1.0.2.tar.gz" f9504b188488d1102cba7e82c28681708f39e151af1c1ef7ebeac82d729c01ac
    helper_dxvk "$file1" "d3d10_enabled" "3.19" "1.1.88"
}

w_metadata dxvk103 dlls \
    title="Vulkan-based D3D10/D3D11 implementation for Linux / Wine (1.0.3)" \
    publisher="Philip Rebohle" \
    year="2018" \
    media="download" \
    file1="dxvk-1.0.3.tar.gz" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/d3d10.dll" \
    installed_file2="$W_SYSTEM32_DLLS_WIN/d3d10_1.dll" \
    installed_file3="$W_SYSTEM32_DLLS_WIN/d3d10core.dll" \
    installed_file4="$W_SYSTEM32_DLLS_WIN/d3d11.dll" \
    installed_file5="$W_SYSTEM32_DLLS_WIN/dxgi.dll"

load_dxvk103()
{
    # https://github.com/doitsujin/dxvk
    w_download "https://github.com/doitsujin/dxvk/releases/download/v1.0.3/dxvk-1.0.3.tar.gz" 984d28ab3a112be207d6339da19113d1117e56731ed413d0e202e6fd1391a6ae
    helper_dxvk "$file1" "d3d10_enabled" "3.19" "1.1.88"
}


#----------------------------------------------------------------

w_metadata dxvk dlls \
    title="Vulkan-based D3D10/D3D11 implementation for Linux / Wine (latest)" \
    publisher="Philip Rebohle" \
    year="2018" \
    media="download" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/d3d10.dll" \
    installed_file2="$W_SYSTEM32_DLLS_WIN/d3d10_1.dll" \
    installed_file3="$W_SYSTEM32_DLLS_WIN/d3d10core.dll" \
    installed_file4="$W_SYSTEM32_DLLS_WIN/d3d11.dll" \
    installed_file5="$W_SYSTEM32_DLLS_WIN/dxgi.dll"

load_dxvk()
{
    # https://github.com/doitsujin/dxvk
    # There's no stable exe URL, but they do provide a RELEASE file that lets us build one:
    w_download_to "${W_TMP_EARLY}" "https://raw.githubusercontent.com/doitsujin/dxvk/latest-release/RELEASE"
    dxvk_version="$(cat "${W_TMP_EARLY}/RELEASE")"
    w_linkcheck_ignore=1 w_download "https://github.com/doitsujin/dxvk/releases/download/v${dxvk_version}/dxvk-${dxvk_version}.tar.gz"
    helper_dxvk "dxvk-${dxvk_version}.tar.gz" "d3d10_enabled" "3.19" "1.1.88"
    unset dxvk_version
}

#----------------------------------------------------------------

w_metadata dmusic32 dlls \
    title="MS dmusic32.dll from DirectX user redistributable" \
    publisher="Microsoft" \
    year="2006" \
    media="download" \
    file1="../directx9/directx_apr2006_redist.exe" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/dmusic32.dll"

load_dmusic32()
{
    w_download_to directx9 https://download.microsoft.com/download/3/9/7/3972f80c-5711-4e14-9483-959d48a2d03b/directx_apr2006_redist.exe dd8c3d401efe4561b67bd88475201b2f62f43cd23e4acc947bb34a659fa74952

    w_try_cabextract -d "$W_TMP" -F DirectX.cab "$W_CACHE"/directx9/directx_apr2006_redist.exe
    w_try_cabextract -d "$W_SYSTEM32_DLLS" -L -F dmusic32.dll "$W_TMP"/DirectX.cab

    w_override_dlls native dmusic32
}

#----------------------------------------------------------------

w_metadata dmband dlls \
    title="MS dmband.dll from DirectX user redistributable" \
    publisher="Microsoft" \
    year="2010" \
    media="download" \
    file1="../directx9/directx_feb2010_redist.exe" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/dmband.dll"

load_dmband()
{
    helper_directx_dl

    w_try_cabextract -d "$W_TMP" -L -F dxnt.cab "$W_CACHE"/directx9/$DIRECTX_NAME
    w_try_cabextract -d "$W_SYSTEM32_DLLS" -L -F 'dmband.dll' "$W_TMP/dxnt.cab"

    w_override_dlls native dmband
    w_try_regsvr dmband.dll
}

#----------------------------------------------------------------

w_metadata dmcompos dlls \
    title="MS dmcompos.dll from DirectX user redistributable" \
    publisher="Microsoft" \
    year="2010" \
    media="download" \
    file1="../directx9/directx_feb2010_redist.exe" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/dmcompos.dll"

load_dmcompos()
{
    helper_directx_dl

    w_try_cabextract -d "$W_TMP" -L -F dxnt.cab "$W_CACHE"/directx9/$DIRECTX_NAME
    w_try_cabextract -d "$W_SYSTEM32_DLLS" -L -F 'dmcompos.dll' "$W_TMP/dxnt.cab"

    w_override_dlls native dmcompos
    w_try_regsvr dmcompos.dll
}

#----------------------------------------------------------------

w_metadata dmime dlls \
    title="MS dmime.dll from DirectX user redistributable" \
    publisher="Microsoft" \
    year="2010" \
    media="download" \
    file1="../directx9/directx_feb2010_redist.exe" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/dmime.dll"

load_dmime()
{
    helper_directx_dl

    w_try_cabextract -d "$W_TMP" -L -F dxnt.cab "$W_CACHE"/directx9/$DIRECTX_NAME
    w_try_cabextract -d "$W_SYSTEM32_DLLS" -L -F 'dmime.dll' "$W_TMP/dxnt.cab"

    w_override_dlls native dmime
    w_try_regsvr dmime.dll
}

#----------------------------------------------------------------

w_metadata dmloader dlls \
    title="MS dmloader.dll from DirectX user redistributable" \
    publisher="Microsoft" \
    year="2010" \
    media="download" \
    file1="../directx9/directx_feb2010_redist.exe" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/dmloader.dll"

load_dmloader()
{
    helper_directx_dl

    w_try_cabextract -d "$W_TMP" -L -F dxnt.cab "$W_CACHE"/directx9/$DIRECTX_NAME
    w_try_cabextract -d "$W_SYSTEM32_DLLS" -L -F 'dmloader.dll' "$W_TMP/dxnt.cab"

    w_override_dlls native dmloader
    w_try_regsvr dmloader.dll
}

#----------------------------------------------------------------

w_metadata dmscript dlls \
    title="MS dmscript.dll from DirectX user redistributable" \
    publisher="Microsoft" \
    year="2010" \
    media="download" \
    file1="../directx9/directx_feb2010_redist.exe" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/dmscript.dll"

load_dmscript()
{
    helper_directx_dl

    w_try_cabextract -d "$W_TMP" -L -F dxnt.cab "$W_CACHE"/directx9/$DIRECTX_NAME
    w_try_cabextract -d "$W_SYSTEM32_DLLS" -L -F 'dmscript.dll' "$W_TMP/dxnt.cab"

    w_override_dlls native dmscript
    w_try_regsvr dmscript.dll
}

#----------------------------------------------------------------

w_metadata dmstyle dlls \
    title="MS dmstyle.dll from DirectX user redistributable" \
    publisher="Microsoft" \
    year="2010" \
    media="download" \
    file1="../directx9/directx_feb2010_redist.exe" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/dmstyle.dll"

load_dmstyle()
{
    helper_directx_dl

    w_try_cabextract -d "$W_TMP" -L -F dxnt.cab "$W_CACHE"/directx9/$DIRECTX_NAME
    w_try_cabextract -d "$W_SYSTEM32_DLLS" -L -F 'dmstyle.dll' "$W_TMP/dxnt.cab"

    w_override_dlls native dmstyle
    w_try_regsvr dmstyle.dll
}

#----------------------------------------------------------------

w_metadata dmsynth dlls \
    title="MS dmsynth.dll from DirectX user redistributable" \
    publisher="Microsoft" \
    year="2010" \
    media="download" \
    file1="../directx9/directx_feb2010_redist.exe" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/dmsynth.dll"

load_dmsynth()
{
    helper_directx_dl

    w_try_cabextract -d "$W_TMP" -L -F dxnt.cab "$W_CACHE"/directx9/$DIRECTX_NAME
    w_try_cabextract -d "$W_SYSTEM32_DLLS" -L -F 'dmsynth.dll' "$W_TMP/dxnt.cab"

    w_override_dlls native dmsynth
    w_try_regsvr dmsynth.dll
}

#----------------------------------------------------------------

w_metadata dmusic dlls \
    title="MS dmusic.dll from DirectX user redistributable" \
    publisher="Microsoft" \
    year="2010" \
    media="download" \
    file1="../directx9/directx_feb2010_redist.exe" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/dmusic.dll"

load_dmusic()
{
    helper_directx_dl

    w_try_cabextract -d "$W_TMP" -L -F dxnt.cab "$W_CACHE"/directx9/$DIRECTX_NAME
    w_try_cabextract -d "$W_SYSTEM32_DLLS" -L -F 'dmusic.dll' "$W_TMP/dxnt.cab"

    w_override_dlls native dmusic
    w_try_regsvr dmusic.dll
}

#----------------------------------------------------------------

w_metadata dswave dlls \
    title="MS dswave.dll from DirectX user redistributable" \
    publisher="Microsoft" \
    year="2010" \
    media="download" \
    file1="../directx9/directx_feb2010_redist.exe" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/dswave.dll"

load_dswave()
{
    helper_directx_dl

    w_try_cabextract -d "$W_TMP" -L -F dxnt.cab "$W_CACHE"/directx9/$DIRECTX_NAME
    w_try_cabextract -d "$W_SYSTEM32_DLLS" -L -F 'dswave.dll' "$W_TMP/dxnt.cab"

    w_override_dlls native dswave
    w_try_regsvr dswave.dll
}

#----------------------------------------------------------------

w_metadata dotnet11 dlls \
    title="MS .NET 1.1" \
    publisher="Microsoft" \
    year="2003" \
    media="download" \
    conflicts="dotnet20 dotnet20sdk dotnet20sp1 dotnet20sp2 dotnet30 dotnet30sp1 dotnet35 dotnet35sp1 vjrun20" \
    file1="dotnetfx.exe" \
    installed_file1="c:/windows/Microsoft.NET/Framework/v1.1.4322/ndpsetup.ico"

load_dotnet11()
{
    # The installer itself doesn't support 64-bit
    w_package_unsupported_win64

    # https://www.microsoft.com/en-us/download/details.aspx?id=26
    w_download https://download.microsoft.com/download/a/a/c/aac39226-8825-44ce-90e3-bf8203e74006/dotnetfx.exe ba0e58ec93f2ffd54fc7c627eeca9502e11ab3c6fc85dcbeff113bd61d995bce

    w_call remove_mono
    w_call corefonts
    w_call fontfix

    w_try w_try_cd "$W_CACHE/$W_PACKAGE"
    # Use builtin regsvcs.exe to work around https://bugs.winehq.org/show_bug.cgi?id=25120
    if test $W_OPT_UNATTENDED; then
        WINEDLLOVERRIDES="regsvcs.exe=b" w_ahk_do "
            SetTitleMatchMode, 2
            run, dotnetfx.exe /q /C:\"install /q\"

            Loop
            {
                sleep 1000
                ifwinexist, Fatal error, Failed to delay load library
                {
                    WinClose, Fatal error, Failed to delay load library
                    continue
                }
                Process, exist, dotnetfx.exe
                dotnet_pid = %ErrorLevel%  ; Save the value immediately since ErrorLevel is often changed.
                if dotnet_pid = 0
                {
                    break
                }
            }
        "
    else
        WINEDLLOVERRIDES="regsvcs.exe=b" w_try "$WINE" dotnetfx.exe
    fi

    W_NGEN_CMD="w_try $WINE $W_DRIVE_C/windows/Microsoft.NET/Framework/v1.1.4322/ngen.exe executequeueditems"
}

verify_dotnet11()
{
    w_dotnet_verify dotnet11
}

#----------------------------------------------------------------

w_metadata dotnet11sp1 dlls \
    title="MS .NET 1.1 SP1" \
    publisher="Microsoft" \
    year="2004" \
    media="download" \
    file1="NDP1.1sp1-KB867460-X86.exe" \
    installed_file1="c:/windows/Microsoft.NET/Framework/v1.1.4322/CONFIG/web_hightrust.config.default"

load_dotnet11sp1()
{
    # The installer itself doesn't support 64-bit
    w_package_unsupported_win64

    w_download https://download.microsoft.com/download/8/b/4/8b4addd8-e957-4dea-bdb8-c4e00af5b94b/NDP1.1sp1-KB867460-X86.exe 2c0a35409ff0873cfa28b70b8224e9aca2362241c1f0ed6f622fef8d4722fd9a

    w_call remove_mono
    w_call dotnet11

    w_try w_try_cd "$W_CACHE/$W_PACKAGE"
    # Use builtin regsvcs.exe to work around https://bugs.winehq.org/show_bug.cgi?id=25120
    if test $W_OPT_UNATTENDED; then
        WINEDLLOVERRIDES="regsvcs.exe=b" w_ahk_do "
            SetTitleMatchMode, 2
            run, NDP1.1sp1-KB867460-X86.exe /q /C:"install /q"

            Loop
            {
                sleep 1000
                ifwinexist, Fatal error, Failed to delay load library
                {
                    WinClose, Fatal error, Failed to delay load library
                    continue
                }
                Process, exist, dotnetfx.exe
                dotnet_pid = %ErrorLevel%  ; Save the value immediately since ErrorLevel is often changed.
                if dotnet_pid = 0
                {
                    break
                }
            }
        "
    else
        WINEDLLOVERRIDES="regsvcs.exe=b" w_try "$WINE" "$W_CACHE"/dotnet11sp1/NDP1.1sp1-KB867460-X86.exe
    fi

    W_NGEN_CMD="w_try $WINE $W_DRIVE_C/windows/Microsoft.NET/Framework/v1.1.4322/ngen.exe executequeueditems"
}

verify_dotnet11sp1()
{
    w_dotnet_verify dotnet11sp1
}

#----------------------------------------------------------------

w_metadata dotnet20 dlls \
    title="MS .NET 2.0" \
    publisher="Microsoft" \
    year="2006" \
    media="download" \
    conflicts="dotnet11" \
    file1="dotnetfx.exe" \
    installed_file1="c:/windows/Microsoft.NET/Framework/v2.0.50727/MSBuild.exe"

load_dotnet20()
{
    w_call remove_mono
    w_call fontfix

    if [ "$W_ARCH" = "win32" ]; then
        # https://www.microsoft.com/en-us/download/details.aspx?id=19
        w_download https://download.lenovo.com/ibmdl/pub/pc/pccbbs/thinkvantage_en/dotnetfx.exe 46693d9b74d12454d117cc61ff2e9481cabb100b4d74eb5367d3cf88b89a0e71

        # Needed for https://bugs.winehq.org/show_bug.cgi?id=12401
        w_set_winver win2k

        w_try_cd "$W_CACHE"/"$W_PACKAGE"
        w_try "$WINE" dotnetfx.exe ${W_OPT_UNATTENDED:+/q /c:"install.exe /q"}
        w_unset_winver

        # We can't stop installing dotnet20 in win2k mode until Wine supports
        # reparse/junction points
        # (see https://bugs.winehq.org/show_bug.cgi?id=10467#c57 )
        # so for now just remove the bogus msvc*80.dll files it installs.
        # See also https://bugs.winehq.org/show_bug.cgi?id=16577
        # This affects Victoria 2 demo, see https://forum.paradoxplaza.com/forum/showthread.php?p=11523967
        rm -f "$W_SYSTEM32_DLLS"/msvc?80.dll
    elif [ "$W_ARCH" = "win64" ]; then
        w_download https://download.microsoft.com/download/a/3/f/a3f1bf98-18f3-4036-9b68-8e6de530ce0a/NetFx64.exe 7ea86dca8eeaedcaa4a17370547ca2cea9e9b6774972b8e03d2cb1fb0e798669

        # validates successfully in win7 mode wine-3.19, so not setting winversion
        w_try_cd "$W_CACHE"/"$W_PACKAGE"
        w_try "$WINE" NetFx64.exe ${W_OPT_UNATTENDED:+/q /c:"install.exe /q"}
    fi

    W_NGEN_CMD="w_try $WINE $W_DRIVE_C/windows/Microsoft.NET/Framework/v2.0.50727/ngen.exe executequeueditems"
}

verify_dotnet20()
{
    w_dotnet_verify dotnet20
}

#----------------------------------------------------------------

w_metadata dotnet20sdk dlls \
    title="MS .NET 2.0 SDK" \
    publisher="Microsoft" \
    year="2006" \
    media="download" \
    conflicts="dotnet11 dotnet20sp1 dotnet20sp2 dotnet30 dotnet40" \
    file1="setup.exe" \
    installed_file1="$W_PROGRAMS_X86_WIN/Microsoft.NET/SDK/v2.0/Bin/cordbg.exe"

load_dotnet20sdk()
{
    w_package_unsupported_win64

    # https://www.microsoft.com/en-us/download/details.aspx?id=19988
    w_download https://download.microsoft.com/download/c/4/b/c4b15d7d-6f37-4d5a-b9c6-8f07e7d46635/setup.exe 1d7337bfbb2c65f43c82d188688ce152af403bcb67a2cc2a3cc68a580ecd8200

    w_call remove_mono

    w_call dotnet20

    w_try_cd "$W_CACHE/$W_PACKAGE"
    w_ahk_do "
        SetTitleMatchMode, 2
        run, setup.exe ${W_OPT_UNATTENDED:+/q /c:"install.exe /q"}

        Loop
        {
            sleep 1000
            ifwinexist, Microsoft Document Explorer, Application Data folder
            {
                WinClose, Microsoft Document Explorer, Application Data folder
                continue
            }
            ifwinexist, Microsoft CLR Debugger, Application Data folder
            {
                WinClose, Microsoft CLR Debugger, Application Data folder
                continue
            }
            ; FIXME: only appears if dotnet30sp1 is run first?
            ifwinexist, Microsoft .NET Framework 2.0 SDK Setup, This wizard will guide
            {
                ControlClick, Button22, Microsoft .NET Framework 2.0 SDK Setup
                Winwait, Microsoft .NET Framework 2.0 SDK Setup, By clicking
                sleep 100
                ControlClick, Button21
                sleep 100
                ControlClick, Button18
                WinWait, Microsoft .NET Framework 2.0 SDK Setup, Select from
                sleep 100
                ControlClick, Button12
                WinWait, Microsoft .NET Framework 2.0 SDK Setup, Type the path
                sleep 100
                ControlClick, Button8
                WinWait, Microsoft .NET Framework 2.0 SDK Setup, successfully installed
                sleep 100
                ControlClick, Button2
                sleep 100
            }
            Process, exist, setup.exe
            dotnet_pid = %ErrorLevel%
            if dotnet_pid = 0
            {
                break
            }
        }
    "

}

#----------------------------------------------------------------

w_metadata dotnet20sp1 dlls \
    title="MS .NET 2.0 SP1 (experimental)" \
    publisher="Microsoft" \
    year="2008" \
    media="download" \
    conflicts="dotnet11 dotnet20sp2 dotnet35sp1" \
    file1="NetFx20SP1_x86.exe" \
    installed_file1="c:/windows/winsxs/manifests/x86_Microsoft.VC80.CRT_1fc8b3b9a1e18e3b_8.0.50727.1433_x-ww_5cf844d2.cat"

load_dotnet20sp1()
{
    w_call remove_mono

    WINEDLLOVERRIDES=ngen.exe,regsvcs.exe,mscorsvw.exe=b
    export WINEDLLOVERRIDES

    if [ "$W_ARCH" = "win32" ]; then
        # https://www.microsoft.com/en-us/download/details.aspx?id=16614
        w_download https://download.microsoft.com/download/0/8/c/08c19fa4-4c4f-4ffb-9d6c-150906578c9e/NetFx20SP1_x86.exe c36c3a1d074de32d53f371c665243196a7608652a2fc6be9520312d5ce560871
        exe="NetFx20SP1_x86.exe"

        w_warn "Setting windows version so installer works"
        w_set_winver win2k
    elif [ "$W_ARCH" = "win64" ]; then
        # https://www.microsoft.com/en-us/download/details.aspx?id=6041
        w_download https://download.microsoft.com/download/9/8/6/98610406-c2b7-45a4-bdc3-9db1b1c5f7e2/NetFx20SP1_x64.exe 1731e53de5f48baae0963677257660df1329549e81c48b4d7db7f7f3f2329aab
        exe="NetFx20SP1_x64.exe"

        w_warn "Setting windows version so installer works"
        w_set_winver winxp
    fi

    w_try_cd "$W_CACHE/$W_PACKAGE"
    "$WINE" "$exe" ${W_OPT_UNATTENDED:+/q}
    status=$?

    case $status in
        0) ;;
        105) echo "exit status $status - normal, user selected 'restart now'" ;;
        194) echo "exit status $status - normal, user selected 'restart later'" ;;
        *) w_die "exit status $status - $W_PACKAGE installation failed" ;;
    esac

    if [ "$W_ARCH" = "win32" ]; then
        # We can't stop installing dotnet20sp1 in win2k mode until Wine supports
        # reparse/junction points
        # (see https://bugs.winehq.org/show_bug.cgi?id=10467#c57 )
        # so for now just remove the bogus msvc*80.dll files it installs.
        # See also https://bugs.winehq.org/show_bug.cgi?id=16577
        # This affects Victoria 2 demo, see https://forum.paradoxplaza.com/forum/showthread.php?p=11523967
        rm -f "$W_SYSTEM32_DLLS"/msvc?80.dll

    fi

    w_unset_winver

    W_NGEN_CMD="w_try $WINE $W_DRIVE_C/windows/Microsoft.NET/Framework/v2.0.50727/ngen.exe executequeueditems"
}

verify_dotnet20sp1()
{
    w_dotnet_verify dotnet20sp1
}

#----------------------------------------------------------------

w_metadata dotnet20sp2 dlls \
    title="MS .NET 2.0 SP2 (experimental)" \
    publisher="Microsoft" \
    year="2009" \
    media="download" \
    conflicts="dotnet11" \
    file1="NetFx20SP2_x86.exe" \
    installed_file1="c:/windows/winsxs/manifests/x86_Microsoft.VC80.CRT_1fc8b3b9a1e18e3b_8.0.50727.3053_x-ww_b80fa8ca.cat"

load_dotnet20sp2()
{
    w_call remove_mono

    WINEDLLOVERRIDES=ngen.exe,regsvcs.exe,mscorsvw.exe=b
    export WINEDLLOVERRIDES

    w_warn "Setting windows version so installer works"
    w_set_winver winxp

    if [ "$W_ARCH" = "win32" ]; then
        # https://www.microsoft.com/en-us/download/details.aspx?id=1639
        w_download https://download.microsoft.com/download/c/6/e/c6e88215-0178-4c6c-b5f3-158ff77b1f38/NetFx20SP2_x86.exe 6e3f363366e7d0219b7cb269625a75d410a5c80d763cc3d73cf20841084e851f
        exe="NetFx20SP2_x86.exe"
    elif [ "$W_ARCH" = "win64" ]; then
        # https://www.microsoft.com/en-us/download/details.aspx?id=1639
        w_download https://download.microsoft.com/download/c/6/e/c6e88215-0178-4c6c-b5f3-158ff77b1f38/NetFx20SP2_x64.exe
        exe="NetFx20SP2_x64.exe"
    fi

    w_try_cd "$W_CACHE/$W_PACKAGE"
    "$WINE" "$exe" ${W_OPT_UNATTENDED:+ /q /c:"install.exe /q"}
    status=$?

    case $status in
        0) ;;
        105) echo "exit status $status - normal, user selected 'restart now'" ;;
        194) echo "exit status $status - normal, user selected 'restart later'" ;;
        *) w_die "exit status $status - $W_PACKAGE installation failed" ;;
    esac

    if [ "$W_ARCH" = "win32" ]; then
        # We can't stop installing dotnet20sp1 in win2k mode until Wine supports
        # reparse/junction points
        # (see https://bugs.winehq.org/show_bug.cgi?id=10467#c57 )
        # so for now just remove the bogus msvc*80.dll files it installs.
        # See also https://bugs.winehq.org/show_bug.cgi?id=16577
        # This affects Victoria 2 demo, see https://forum.paradoxplaza.com/forum/showthread.php?p=11523967
        rm -f "$W_SYSTEM32_DLLS"/msvc?80.dll
    fi

    w_unset_winver

    W_NGEN_CMD="w_try $WINE $W_DRIVE_C/windows/Microsoft.NET/Framework/v2.0.50727/ngen.exe executequeueditems"
}

verify_dotnet20sp2()
{
    w_dotnet_verify dotnet20sp2
}

#----------------------------------------------------------------

w_metadata dotnet30 dlls \
    title="MS .NET 3.0" \
    publisher="Microsoft" \
    year="2006" \
    media="download" \
    conflicts="dotnet11 dotnet20sp1 dotnet20sp2 dotnet30sp1 dotnet35 dotnet35sp1 dotnet45 dotnet452" \
    file1="dotnetfx3.exe" \
    installed_file1="c:/windows/Microsoft.NET/Framework/v3.0/Microsoft .NET Framework 3.0/logo.bmp"

load_dotnet30()
{
    # I can't find a 64-bit installer anywhere
    w_package_unsupported_win64

    # Originally at https://msdn.microsoft.com/en-us/netframework/bb264589.aspx
    # No longer on microsoft.com, and archive.org is unreliablel. Choose amongst the oldest/most reliable looking from
    # http://www.filewatcher.com/m/dotnetfx3.exe.52770576-0.html
    # (and verify sha256sum, of course ;))
    w_download http://descargas.udenar.edu.co/Framework.net/dotnetfx3.exe 6cf8921e00f52bbd888aa7a520a7bac47e818e2a850bcc44494c64d6cbfafdac

    w_call remove_mono

    if test -f /proc/sys/kernel/yama/ptrace_scope; then
        case $(cat /proc/sys/kernel/yama/ptrace_scope) in
            0) ;;
            *) w_warn "If install fails, set /proc/sys/kernel/yama/ptrace_scope to 0.  See https://bugs.winehq.org/show_bug.cgi?id=30410" ;;
        esac
    fi

    case "$W_PLATFORM" in
        windows_cmd)
            osver=$(cmd /c ver)
            case "$osver" in
                *Version?6*) w_die "Vista and up bundle .NET 3.0, so you can't install it like this" ;;
            esac
            ;;
    esac

    # AF's workaround to avoid long pause
    LANGPACKS_BASE_PATH="${W_WINDIR_UNIX}/SYSMSICache/Framework/v3.0"
    test -d "${LANGPACKS_BASE_PATH}" || mkdir -p "${LANGPACKS_BASE_PATH}"
    # shellcheck disable=SC1010
    for lang in ar cs da de el es fi fr he it jp ko nb nl pl pt-BR pt-PT ru \
                sv tr zh-CHS zh-CHT
    do
        ln -sf "${W_SYSTEM32_DLLS}/spupdsvc.exe" "${LANGPACKS_BASE_PATH}/dotnetfx3langpack${lang}.exe"
    done

    w_set_winver winxp

    # Delete FontCache 3.0 service, it's in Wine for Mono, breaks native .NET
    # OK if this fails, that just means you have an older Wine.
    "$WINE" sc delete "FontCache3.0.0.0"

    WINEDLLOVERRIDES="ngen.exe,mscorsvw.exe=b;$WINEDLLOVERRIDES"

    w_try_cd "$W_CACHE/$W_PACKAGE"
    w_warn "Installing .NET 3.0 runtime silently, as otherwise it gets hidden behind taskbar. Installation usually takes about 3 minutes."
    w_try "$WINE" "$file1" /q /c:"install.exe /q"

    # Doesn't install any ngen.exe
    # W_NGEN_CMD=""
}

verify_dotnet30()
{
    w_dotnet_verify dotnet30
}

#----------------------------------------------------------------

w_metadata dotnet30sp1 dlls \
    title="MS .NET 3.0 SP1" \
    publisher="Microsoft" \
    year="2007" \
    media="download" \
    conflicts="dotnet11 dotnet20sdk dotnet20sp1 dotnet20sp2" \
    file1="NetFx30SP1_x86.exe" \
    installed_file1="c:/windows/system32/XpsFilt.dll"    # we're cheating a bit here

load_dotnet30sp1()
{
    # I can't find a 64-bit installer anywhere
    w_package_unsupported_win64

    # FIXME: URL?
    w_download https://download.microsoft.com/download/8/F/E/8FEEE89D-9E4F-4BA3-993E-0FFEA8E21E1B/NetFx30SP1_x86.exe 3100df4d4db3965ead9520c887a534115cf6fc7ba100abde45226958b865695b
    # Recipe from https://bugs.winehq.org/show_bug.cgi?id=25060#c10
    w_download https://download.microsoft.com/download/2/5/2/2526f55d-32bc-410f-be18-164ba67ae07d/XPSEP%20XP%20and%20Server%202003%2032%20bit.msi 630c86a202c40cbcd430701977d4f1fefa6151624ef9a4870040dff45e547dea "XPSEP XP and Server 2003 32 bit.msi"

    w_call remove_mono
    w_call dotnet30
    w_wineserver -w
    w_call dotnet20sp1
    w_wineserver -w

    w_try_cd "$W_CACHE/$W_PACKAGE"

    "$WINE" reg add "HKLM\\Software\\Microsoft\\Net Framework Setup\\NDP\\v3.0" /v Version /t REG_SZ /d "3.0" /f
    "$WINE" reg add "HKLM\\Software\\Microsoft-\\Net Framework Setup\\NDP\\v3.0" /v SP /t REG_DWORD /d 0001 /f

    w_try "$WINE" msiexec /i "XPSEP XP and Server 2003 32 bit.msi" ${W_UNATTENDED_SLASH_QB}
    "$WINE" sc delete FontCache3.0.0.0

    "$WINE" "$file1" ${W_OPT_UNATTENDED:+/q}
    status=$?
    w_info "$file1 exited with status $status"

    # Doesn't install any ngen.exe
    # W_NGEN_CMD=""
}

verify_dotnet30sp1()
{
    w_dotnet_verify dotnet30sp1
}

#----------------------------------------------------------------

w_metadata dotnet35 dlls \
    title="MS .NET 3.5" \
    publisher="Microsoft" \
    year="2007" \
    media="download" \
    conflicts="dotnet11 dotnet20 dotnet20sdk dotnet20sp1 dotnet20sp2" \
    file1="dotnetfx35.exe" \
    installed_file1="c:/windows/Microsoft.NET/Framework/v3.5/MSBuild.exe"

load_dotnet35()
{
    if [ "$W_ARCH" = "win64" ] && w_workaround_wine_bug 45680 "Upgrade to 3.18 for win64 support" ,3.18 ; then
        w_package_unsupported_win64
    fi

    case "$W_PLATFORM" in
        windows_cmd) ;;
        *) w_warn "dotnet35 does not yet fully work or install on wine.  Caveat emptor." ;;
    esac

    w_verify_cabextract_available

    # https://www.microsoft.com/en-us/download/details.aspx?id=21
    w_download https://download.microsoft.com/download/6/0/f/60fc5854-3cb8-4892-b6db-bd4f42510f28/dotnetfx35.exe 3e3a4104bad9a0c270ed5cbe8abb986de9afaf0281a98998bdbdc8eaab85c3b6

    w_call remove_mono

    w_set_winver winxp

    w_override_dlls native mscoree
    w_wineserver -w

    w_try_cd "$W_CACHE/$W_PACKAGE"
    "$WINE" "${file1}" /lang:ENU $W_UNATTENDED_SLASH_Q

    # Doesn't install any ngen.exe
    # W_NGEN_CMD=""
}

verify_dotnet35()
{
    w_dotnet_verify dotnet35
}

#----------------------------------------------------------------

w_metadata dotnet35sp1 dlls \
    title="MS .NET 3.5 SP1" \
    publisher="Microsoft" \
    year="2008" \
    media="download" \
    conflicts="dotnet11 dotnet20sp1 dotnet20sp2" \
    file1="dotnetfx35.exe" \
    installed_file1="c:/windows/Microsoft.NET/Framework/v3.5/msbuild.exe.config"

load_dotnet35sp1()
{
    if [ "$W_ARCH" = "win64" ] && w_workaround_wine_bug 46168 "Doesn't install prior to wine-4.0-rc1" ,4.0; then
        w_package_unsupported_win64
    fi

    case "$W_PLATFORM" in
        windows_cmd) ;;
        *) w_warn "dotnet35sp1 does not yet fully work or install on wine.  Caveat emptor." ;;
    esac

    w_verify_cabextract_available

    # https://www.microsoft.com/en-us/download/details.aspx?id=25150
    w_download https://download.microsoft.com/download/2/0/e/20e90413-712f-438c-988e-fdaa79a8ac3d/dotnetfx35.exe 0582515bde321e072f8673e829e175ed2e7a53e803127c50253af76528e66bc1

    w_call remove_mono

    w_set_winver winxp

    w_try_cd "$W_CACHE/$W_PACKAGE"
    "$WINE" dotnetfx35.exe /lang:ENU $W_UNATTENDED_SLASH_Q

    # Doesn't install any ngen.exe
    # W_NGEN_CMD=""
}

verify_dotnet35sp1()
{
    w_dotnet_verify dotnet35sp1
}

#----------------------------------------------------------------

w_metadata dotnet40 dlls \
    title="MS .NET 4.0" \
    publisher="Microsoft" \
    year="2011" \
    media="download" \
    conflicts="dotnet20sdk" \
    file1="dotNetFx40_Full_x86_x64.exe" \
    installed_file1="c:/windows/Microsoft.NET/Framework/v4.0.30319/ngen.exe"

load_dotnet40()
{
    w_package_warn_win64

    case "$W_PLATFORM" in
        windows_cmd) ;;
        *) w_warn "dotnet40 does not yet fully work or install on wine.  Caveat emptor." ;;
    esac

    if [ "$W_ARCH" = "win64" ] && w_workaround_wine_bug 42701; then
        w_warn "On 64-bit, you'll run into https://bugs.winehq.org/show_bug.cgi?id=42701 (missing api-ms-win-core-winrt-roparameterizediid-l1-1-0.dll.RoGetParameterizedTypeInstanceIID"
    fi

    # https://www.microsoft.com/en-us/download/details.aspx?id=17718
    w_download https://download.microsoft.com/download/9/5/A/95A9616B-7A37-4AF6-BC36-D6EA96C8DAAE/dotNetFx40_Full_x86_x64.exe 65e064258f2e418816b304f646ff9e87af101e4c9552ab064bb74d281c38659f

    w_call remove_mono

    w_call winxp

    w_try_cd "$W_CACHE/$W_PACKAGE"

    WINEDLLOVERRIDES=fusion=b "$WINE" dotNetFx40_Full_x86_x64.exe ${W_OPT_UNATTENDED:+/q /c:"install.exe /q"} || true

    w_override_dlls native mscoree

    "$WINE" reg add "HKLM\\Software\\Microsoft\\NET Framework Setup\\NDP\\v4\\Full" /v Install /t REG_DWORD /d 0001 /f
    "$WINE" reg add "HKLM\\Software\\Microsoft\\NET Framework Setup\\NDP\\v4\\Full" /v Version /t REG_SZ /d "4.0.30319" /f

    W_NGEN_CMD="$WINE $WINEPREFIX/drive_c/windows/Microsoft.NET/Framework/v4.0.30319/ngen.exe executequeueditems"

    w_unset_winver
}

verify_dotnet40()
{
    w_dotnet_verify dotnet40
}

#----------------------------------------------------------------

w_metadata dotnet45 dlls \
    title="MS .NET 4.5" \
    publisher="Microsoft" \
    year="2012" \
    media="download" \
    conflicts="dotnet20 dotnet20sdk dotnet20sp1 dotnet20sp2 dotnet35sp1 vjrun20" \
    file1="dotnetfx45_full_x86_x64.exe" \
    installed_file1="c:/windows/Microsoft.NET/Framework/v4.0.30319/Microsoft.Windows.ApplicationServer.Applications.45.man"

load_dotnet45()
{
    w_package_warn_win64

    w_verify_cabextract_available

    # https://www.microsoft.com/en-us/download/details.aspx?id=17718
    w_download https://download.microsoft.com/download/b/a/4/ba4a7e71-2906-4b2d-a0e1-80cf16844f5f/dotnetfx45_full_x86_x64.exe a04d40e217b97326d46117d961ec4eda455e087b90637cb33dd6cc4a2c228d83

    w_call remove_mono

    # See https://appdb.winehq.org/objectManager.php?sClass=version&iId=25478 for Focht's recipe

    # Seems unneeded in wine-2.0
    # w_call dotnet35
    w_call dotnet40
    w_set_winver win7

    w_try_cd "$W_CACHE/$W_PACKAGE"

    WINEDLLOVERRIDES=fusion=b "$WINE" dotnetfx45_full_x86_x64.exe ${W_OPT_UNATTENDED:+/q /c:"install.exe /q"}
    status=$?

    case $status in
        0) ;;
        105) echo "exit status $status - normal, user selected 'restart now'" ;;
        194) echo "exit status $status - normal, user selected 'restart later'" ;;
        *) w_die "exit status $status - $W_PACKAGE installation failed" ;;
    esac

    w_override_dlls native mscoree

    w_warn "Setting Windows version to 2003, otherwise applications using .NET 4.5 will subtly fail"
    w_set_winver win2k3
}

verify_dotnet45()
{
    w_dotnet_verify dotnet45
}

#----------------------------------------------------------------

w_metadata dotnet452 dlls \
    title="MS .NET 4.5.2" \
    publisher="Microsoft" \
    year="2012" \
    media="download" \
    conflicts="dotnet20 dotnet20sdk dotnet20sp1 dotnet20sp2 dotnet35sp1 dotnet40 dotnet45 vjrun20" \
    file1="dotnetfx45_full_x86_x64.exe" \
    installed_file1="c:/windows/Microsoft.NET/Framework/v4.0.30319/Microsoft.Windows.ApplicationServer.Applications.45.man"

load_dotnet452()
{
    w_package_warn_win64

    w_verify_cabextract_available

    # https://www.microsoft.com/en-us/download/details.aspx?id=17718
    w_download https://download.microsoft.com/download/E/2/1/E21644B5-2DF2-47C2-91BD-63C560427900/NDP452-KB2901907-x86-x64-AllOS-ENU.exe 6c2c589132e830a185c5f40f82042bee3022e721a216680bd9b3995ba86f3781

    w_call remove_mono

    # See https://appdb.winehq.org/objectManager.php?sClass=version&iId=25478 for Focht's recipe

    # Seems unneeded in wine-2.0
    # w_call dotnet35
    w_call dotnet40
    w_set_winver win7

    w_try_cd "$W_CACHE/$W_PACKAGE"

    WINEDLLOVERRIDES=fusion=b "$WINE" NDP452-KB2901907-x86-x64-AllOS-ENU.exe ${W_OPT_UNATTENDED:+/q /c:"install.exe /q"}
    status=$?

    case $status in
        0) ;;
        105) echo "exit status $status - normal, user selected 'restart now'" ;;
        194) echo "exit status $status - normal, user selected 'restart later'" ;;
        *) w_die "exit status $status - $W_PACKAGE installation failed" ;;
    esac

    w_override_dlls native mscoree

    w_warn "Setting Windows version to 2003, otherwise applications using .NET 4.5 will subtly fail"
    w_set_winver win2k3
}

verify_dotnet452()
{
    w_dotnet_verify dotnet452
}

#----------------------------------------------------------------

w_metadata dotnet46 dlls \
    title="MS .NET 4.6" \
    publisher="Microsoft" \
    year="2015" \
    media="download" \
    file1="NDP46-KB3045557-x86-x64-AllOS-ENU.exe" \
    conflicts="dotnet20 dotnet20sdk dotnet20sp1 dotnet20sp2 dotnet35sp1 vjrun20" \
    installed_file1="c:/windows/Migration/WTR/netfx45_upgradecleanup.inf"

load_dotnet46()
{
    w_package_warn_win64

    # https://support.microsoft.com/kb/3045560
    w_download https://download.microsoft.com/download/C/3/A/C3A5200B-D33C-47E9-9D70-2F7C65DAAD94/NDP46-KB3045557-x86-x64-AllOS-ENU.exe b21d33135e67e3486b154b11f7961d8e1cfd7a603267fb60febb4a6feab5cf87

    w_call remove_mono

    w_call dotnet45
    w_set_winver win7

    w_try_cd "$W_CACHE/$W_PACKAGE"

    if w_workaround_wine_bug 42470 "$W_PACKAGE may experience heap timeouts" ,3.14; then
        w_warn "If you see heap timeouts like: 'err:ntdll:RtlpWaitForCriticalSection section 0x110060 \"heap.c: main process heap section\" wait timed out in thread 0064, blocked by 0000, retrying (60 sec)', try the patch from https://bugs.winehq.org/show_bug.cgi?id=42470"
    fi

    if w_workaround_wine_bug 38959 ; then
        echo "This installer will fail unless run in quiet mode."
        echo "See: https://bugs.winehq.org/show_bug.cgi?id=38959"

        WINEDLLOVERRIDES=fusion=b "$WINE" "$file1" /q /c:"install.exe /q"
        # Once bug is fixed, use:
        #WINEDLLOVERRIDES=fusion=b "$WINE" "$file1" ${W_OPT_UNATTENDED:+/q /c:"install.exe /q"}
        status=$?
    fi

    case $status in
        0) ;;
        105) echo "exit status $status - normal, user selected 'restart now'" ;;
        194) echo "exit status $status - normal, user selected 'restart later'" ;;
        *) w_die "exit status $status - $W_PACKAGE installation failed" ;;
    esac

    w_override_dlls native mscoree
}

verify_dotnet46()
{
    w_dotnet_verify dotnet46
}

#----------------------------------------------------------------

w_metadata dotnet461 dlls \
    title="MS .NET 4.6.1" \
    publisher="Microsoft" \
    year="2015" \
    media="download" \
    file1="NDP461-KB3102436-x86-x64-AllOS-ENU.exe" \
    conflicts="dotnet20 dotnet20sdk dotnet20sp1 dotnet20sp2 dotnet35sp1 dotnet46 vjrun20" \
    installed_file1="c:/windows/dotnet461.installed.workaround"

load_dotnet461()
{
    w_package_warn_win64

    # https://www.microsoft.com/en-us/download/details.aspx?id=49982
    w_download https://download.microsoft.com/download/E/4/1/E4173890-A24A-4936-9FC9-AF930FE3FA40/NDP461-KB3102436-x86-x64-AllOS-ENU.exe beaa901e07347d056efe04e8961d5546c7518fab9246892178505a7ba631c301

    w_call remove_mono

    w_call dotnet46
    w_set_winver win7

    w_try_cd "$W_CACHE/$W_PACKAGE"

    WINEDLLOVERRIDES=fusion=b "$WINE" "$file1" /sfxlang:1027 ${W_OPT_UNATTENDED:+/q /norestart}
    status=$?

    echo "exit status: $status"

    case $status in
        0) ;;
        105) echo "exit status $status - normal, user selected 'restart now'" ;;
        194) echo "exit status $status - normal, user selected 'restart later'" ;;
        *) w_die "exit status $status - $W_PACKAGE installation failed" ;;
    esac

    w_override_dlls native mscoree

    # Do not rely on temporary files. As a workaround, touch a file instead so that we know it's been installed for list-installed
    w_try touch "${W_WINDIR_UNIX}/dotnet461.installed.workaround"
}

verify_dotnet461()
{
    w_dotnet_verify dotnet461
}

#----------------------------------------------------------------

w_metadata dotnet462 dlls \
    title="MS .NET 4.6.2" \
    publisher="Microsoft" \
    year="2016" \
    media="download" \
    conflicts="dotnet20sdk dotnet20sp1 dotnet20sp2 dotnet35sp1 dotnet46 dotnet461 vjrun20" \
    installed_file1="c:/windows/dotnet462.installed.workaround"

load_dotnet462()
{
    w_package_warn_win64

    # Official version. See https://www.microsoft.com/en-us/download/details.aspx?id=53344
    w_download https://download.microsoft.com/download/F/9/4/F942F07D-F26F-4F30-B4E3-EBD54FABA377/NDP462-KB3151800-x86-x64-AllOS-ENU.exe 28886593e3b32f018241a4c0b745e564526dbb3295cb2635944e3a393f4278d4
    file_package="NDP462-KB3151800-x86-x64-AllOS-ENU.exe"
    unattended_args="/sfxlang:1027 /q /norestart"

    w_call remove_mono

    w_call dotnet461
    w_set_winver win7

    w_try_cd "$W_CACHE/$W_PACKAGE"

    WINEDLLOVERRIDES=fusion=b "$WINE" "$file_package" ${W_OPT_UNATTENDED:+$unattended_args}
    status=$?

    echo "exit status: $status"

    case $status in
        0) ;;
        105) echo "exit status $status - normal, user selected 'restart now'" ;;
        194) echo "exit status $status - normal, user selected 'restart later'" ;;
        5) w_die "exit status $status - user selected 'Cancel'" ;;
        *) w_die "exit status $status - $W_PACKAGE installation failed" ;;
    esac

    w_override_dlls native mscoree

    # Unfortunately, dotnet462 install the same files that dotnet461 does, but with different checksums
    # The only unique files are temporary ones. As a workaround, touch a file instead so that we know it's been installed for list-installed
    w_try touch "${W_WINDIR_UNIX}/dotnet462.installed.workaround"
}

verify_dotnet462()
{
    w_dotnet_verify dotnet462
}


#----------------------------------------------------------------

w_metadata dotnet472 dlls \
    title="MS .NET 4.7.2" \
    publisher="Microsoft" \
    year="2018" \
    media="download" \
    conflicts="dotnet20 dotnet20sdk dotnet20sp1 dotnet20sp2 dotnet35sp1 dotnet40 dotnet46 dotnet461 dotnet462 vjrun20" \
    installed_file1="c:/windows/dotnet472.installed.workaround"

load_dotnet472()
{
    w_package_warn_win64

    if w_workaround_wine_bug 42170 "Running un-official repacked .NET 4.7.2 setup until the official version is fixed."; then
        # Un-official slim version. See https://repacks.net/forum/viewtopic.php?t=7
        file_package="dotNetFx472_Full_x86_x64_Slim.exe"
        w_download "https://drive.google.com/uc?export=download&id=1aLBCH0Yt2-6ROpWRBxZ01kqGMyhc_8hM&confirm" a36da041b8f46079f8e16647312d642953cde520f4a600ad5b3f4f90a23495a7 $file_package
        unattended_args="/ai /gm2"
    else
        # Official version. See https://www.microsoft.com/en-us/download/details.aspx?id=53344
        w_download https://download.microsoft.com/download/6/E/4/6E48E8AB-DC00-419E-9704-06DD46E5F81D/NDP472-KB4054530-x86-x64-AllOS-ENU.exe c908f0a5bea4be282e35acba307d0061b71b8b66ca9894943d3cbb53cad019bc
        file_package="NDP472-KB4054530-x86-x64-AllOS-ENU.exe"
        unattended_args="/sfxlang:1027 /q /norestart"
    fi

    w_call remove_mono

    w_call dotnet462
    w_set_winver win7

    w_try_cd "$W_CACHE/$W_PACKAGE"

    WINEDLLOVERRIDES=fusion=b "$WINE" "$file_package" ${W_OPT_UNATTENDED:+$unattended_args}
    status=$?

    echo "exit status: $status"

    case $status in
        0) ;;
        105) echo "exit status $status - normal, user selected 'restart now'" ;;
        194) echo "exit status $status - normal, user selected 'restart later'" ;;
        5) w_die "exit status $status - user selected 'Cancel'" ;;
        *) w_die "exit status $status - $W_PACKAGE installation failed" ;;
    esac

    w_override_dlls native mscoree

    # Do not rely on temporary files. As a workaround, touch a file instead so that we know it's been installed for list-installed
    w_try touch "${W_WINDIR_UNIX}/dotnet472.installed.workaround"
}

verify_dotnet472()
{
    w_dotnet_verify dotnet472
}

#----------------------------------------------------------------

w_metadata dotnet_verifier dlls \
    title="MS .NET Verifier" \
    publisher="Microsoft" \
    year="2016" \
    media="download" \
    file1="netfx_setupverifier_new.zip" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/netfx_setupverifier.exe"

load_dotnet_verifier()
{
    # https://blogs.msdn.microsoft.com/astebner/2008/10/13/net-framework-setup-verification-tool-users-guide/
    # 2016/10/26: sha256sum 1daf4b1b27669b65f613e17814da3c8342d3bfa9520a65a880c58d6a2a6e32b5, adds .NET Framework 4.6.{1,2} support
    # 2017/06/12: sha256sum 310a0341fbe68f5b8601f2d8deef5d05ca6bce50df03912df391bc843794ef60, adds .NET Framework 4.7 support
    # 2018/06/03: sha256sum 13fd683fd604f9de09a9e649df303100b81e6797f868024d55e5c2f3c14aa9a6, adds .NET Framework 4.7.{1,2} support

    w_download https://msdnshared.blob.core.windows.net/media/2018/05/netfx_setupverifier_new.zip 13fd683fd604f9de09a9e649df303100b81e6797f868024d55e5c2f3c14aa9a6

    w_try_cd "$W_CACHE/$W_PACKAGE"
    w_try_unzip "$W_SYSTEM32_DLLS" netfx_setupverifier_new.zip netfx_setupverifier.exe

    w_warn "You can run the .NET Verifier with \"${WINE} netfx_setupverifier.exe\""
}

#----------------------------------------------------------------

w_metadata dx8vb dlls \
    title="MS dx8vb.dll from DirectX 8.1 runtime" \
    publisher="Microsoft" \
    year="2001" \
    media="download" \
    file1="DX81NTger.exe" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/dx8vb.dll"

load_dx8vb()
{
    # https://www.microsoft.com/de-de/download/details.aspx?id=10968
    w_download https://download.microsoft.com/download/win2000pro/dx/8.1/NT5/DE/DX81NTger.exe 31513966a29dc100165072891d21b5c5e0dd2632abf3409a843cefb3a9886f13

    w_try_cabextract -d "$W_SYSTEM32_DLLS" -F dx8vb.dll "$W_CACHE/$W_PACKAGE"/DX81NTger.exe

    w_override_dlls native dx8vb
}

#----------------------------------------------------------------

w_metadata dxdiagn dlls \
    title="DirectX Diagnostic Library" \
    publisher="Microsoft" \
    year="2011" \
    media="download" \
    conflicts="dxdiagn_feb2010" \
    file1="../win7sp1/windows6.1-KB976932-X86.exe" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/dxdiagn.dll"

load_dxdiagn()
{
    helper_win7sp1 x86_microsoft-windows-d..x-directxdiagnostic_31bf3856ad364e35_6.1.7601.17514_none_25cb021dbc0611db/dxdiagn.dll
    w_try cp "$W_TMP/x86_microsoft-windows-d..x-directxdiagnostic_31bf3856ad364e35_6.1.7601.17514_none_25cb021dbc0611db/dxdiagn.dll" "$W_SYSTEM32_DLLS/dxdiagn.dll"
    w_override_dlls native,builtin dxdiagn
    w_try_regsvr dxdiagn.dll

    if [ "$W_ARCH" = "win64" ]; then
        helper_win7sp1_x64 amd64_microsoft-windows-d..x-directxdiagnostic_31bf3856ad364e35_6.1.7601.17514_none_81e99da174638311/dxdiagn.dll
        w_try cp "$W_TMP/amd64_microsoft-windows-d..x-directxdiagnostic_31bf3856ad364e35_6.1.7601.17514_none_81e99da174638311/dxdiagn.dll" "$W_SYSTEM64_DLLS/dxdiagn.dll"
        w_try_regsvr64 dxdiagn.dll
    fi
}

#----------------------------------------------------------------

w_metadata dxdiagn_feb2010 dlls \
    title="DirectX Diagnostic Library (February 2010)" \
    publisher="Microsoft" \
    year="2010" \
    media="download" \
    conflicts="dxdiagn" \
    file1="../directx9/directx_feb2010_redist.exe" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/dxdiagn.dll"

load_dxdiagn_feb2010()
{
    helper_directx_dl

    w_try_cabextract -d "$W_TMP" -L -F dxnt.cab "$W_CACHE"/directx9/$DIRECTX_NAME
    w_try_cabextract -d "$W_SYSTEM32_DLLS" -L -F 'dxdiagn.dll' "$W_TMP/dxnt.cab"
    w_override_dlls native dxdiagn
    w_try_regsvr dxdiagn.dll
}

#----------------------------------------------------------------

w_metadata dsound dlls \
    title="MS DirectSound from DirectX user redistributable" \
    publisher="Microsoft" \
    year="2010" \
    media="download" \
    file1="../directx9/directx_feb2010_redist.exe" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/dsound.dll"

load_dsound()
{
    helper_directx_dl

    w_try_cabextract -d "$W_TMP" -L -F dxnt.cab "$W_CACHE"/directx9/$DIRECTX_NAME
    w_try_cabextract -d "$W_SYSTEM32_DLLS" -L -F 'dsound.dll' "$W_TMP/dxnt.cab"

    w_override_dlls native dsound
    w_try_regsvr dsound.dll
}

#----------------------------------------------------------------

w_metadata esent dlls \
    title="MS Extensible Storage Engine" \
    publisher="Microsoft" \
    year="2011" \
    media="download" \
    file1="../win7sp1/windows6.1-KB976932-X86.exe" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/esent.dll"

load_esent()
{
    helper_win7sp1 x86_microsoft-windows-e..estorageengine-isam_31bf3856ad364e35_6.1.7601.17514_none_f3ebb0cc8a4dd814/esent.dll
    w_try cp "$W_TMP/x86_microsoft-windows-e..estorageengine-isam_31bf3856ad364e35_6.1.7601.17514_none_f3ebb0cc8a4dd814/esent.dll" "$W_SYSTEM32_DLLS/esent.dll"

    if [ "$W_ARCH" = "win64" ]; then
        helper_win7sp1_x64 amd64_microsoft-windows-e..estorageengine-isam_31bf3856ad364e35_6.1.7601.17514_none_500a4c5042ab494a/esent.dll
        w_try cp "$W_TMP/amd64_microsoft-windows-e..estorageengine-isam_31bf3856ad364e35_6.1.7601.17514_none_500a4c5042ab494a/esent.dll" "$W_SYSTEM64_DLLS/esent.dll"
    fi

    w_override_dlls native,builtin esent
}

#----------------------------------------------------------------

# $1 - faudio archive name (required)
helper_faudio()
{
    faudio_archive="$1"
    faudio_version="$(basename "${faudio_archive}" .tar.xz)"

    w_try_cd "$W_TMP"
    w_try tar -Jxf "${W_CACHE}/${W_PACKAGE}/${faudio_archive}"

    # They ship an installation script, but it's bash (and we have all needed functionality already)
    # Unless they add something more complex, this should suffice:
    for dll in "${faudio_version}/x32/"*.dll; do
        shortdll="$(basename "${dll}" .dll)"
        w_try cp "${dll}" "$W_SYSTEM32_DLLS"
        w_override_dlls native "$shortdll"
    done

    if [ "$W_ARCH" = "win64" ]; then
        for dll in "${faudio_version}/x64/"*.dll; do
            # Note: 'libgcc_s_sjlj-1.dll' is not included in the 64-bit build
            shortdll="$(basename "${dll}" .dll)"
            w_try cp "${dll}" "$W_SYSTEM64_DLLS"
            w_override_dlls native "$shortdll"
        done
    fi
}

#----------------------------------------------------------------

w_metadata faudio1901 dlls \
    title="FAudio (xaudio reimplementation, with xna support) builds for win32 (19.01)" \
    publisher="Kron4ek" \
    year="2019" \
    media="download" \
    file1="faudio-19.01.tar.xz" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/FAudio.dll"

load_faudio1901()
{
    w_download https://github.com/Kron4ek/FAudio-Builds/releases/download/19.01/faudio-19.01.tar.xz f3439090ba36061ee47ebda93e409ae4b2d8886c780c86a197c66ff08b9b573f
    helper_faudio "$file1"
}

#----------------------------------------------------------------

w_metadata faudio1902 dlls \
    title="FAudio (xaudio reimplementation, with xna support) builds for win32 (19.02)" \
    publisher="Kron4ek" \
    year="2019" \
    media="download" \
    file1="faudio-19.02.tar.xz" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/FAudio.dll"

load_faudio1902()
{
    w_download https://github.com/Kron4ek/FAudio-Builds/releases/download/19.02/faudio-19.02.tar.xz 849fec35482748a2b441d8dd7e9a171c7c5c2207d1037c7ffd0265e65f2a4b2b
    helper_faudio "$file1"
}

#----------------------------------------------------------------

w_metadata faudio1903 dlls \
    title="FAudio (xaudio reimplementation, with xna support) builds for win32 (19.03)" \
    publisher="Kron4ek" \
    year="2019" \
    media="download" \
    file1="faudio-19.03.tar.xz" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/FAudio.dll"

load_faudio1903()
{
    w_download https://github.com/Kron4ek/FAudio-Builds/releases/download/19.03/faudio-19.03.tar.xz d5c62437fd5b185e82f464f6a82334af5d666cb506aba218358ea7a3697fdf63
    helper_faudio "$file1"
}

#----------------------------------------------------------------

w_metadata faudio1904 dlls \
    title="FAudio (xaudio reimplementation, with xna support) builds for win32 (19.04)" \
    publisher="Kron4ek" \
    year="2019" \
    media="download" \
    file1="faudio-19.04.tar.xz" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/FAudio.dll"

load_faudio1904()
{
    w_download https://github.com/Kron4ek/FAudio-Builds/releases/download/19.04/faudio-19.04.tar.xz c364db1a18bfb6f6c0f375c641672ca40140b8e5db69dc2c8c9b41d79d0fc56f
    helper_faudio "$file1"
}

#----------------------------------------------------------------

w_metadata faudio dlls \
    title="FAudio (xaudio reimplementation, with xna support) builds for win32 (latest)" \
    publisher="Kron4ek" \
    year="2019" \
    media="download" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/FAudio.dll"

load_faudio()
{
    set -x
    w_download_to "${W_TMP_EARLY}" "https://raw.githubusercontent.com/Kron4ek/FAudio-Builds/master/LATEST"
    faudio_version="$(cat "${W_TMP_EARLY}/LATEST")"
    w_linkcheck_ignore=1 w_download "https://github.com/Kron4ek/FAudio-Builds/releases/download/${faudio_version}/faudio-${faudio_version}.tar.xz"
    helper_faudio "faudio-${faudio_version}.tar.xz"
}

#----------------------------------------------------------------

# FIXME: update winetricks_is_installed to look at installed_file2..n
# https://github.com/Winetricks/winetricks/issues/988
w_metadata flash dlls \
    title="Flash Player 29" \
    publisher="Adobe" \
    year="2018" \
    media="download" \
    file1="fp_29.0.0.171_archive.zip" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/Macromed/Flash/FlashUtil32_29_0_0_171_Plugin.exe" \
    installed_file2="$W_SYSTEM32_DLLS_WIN/Macromed/Flash/FlashUtil32_29_0_0_171_ActiveX.exe" \
    installed_file3="$W_SYSTEM32_DLLS_WIN/Macromed/Flash/flashplayer29_0r0_171_win_sa.exe" \
    homepage="https://www.adobe.com/products/flashplayer/"

load_flash()
{
    _W_ver_major=29
    _W_ver_minor=0
    _W_ver_rel=0
    _W_ver_build=171
    _W_dirname="${_W_ver_major}_${_W_ver_minor}_r${_W_ver_rel}_${_W_ver_build}"
    _W_archive="fp_${_W_ver_major}.${_W_ver_minor}.${_W_ver_rel}.${_W_ver_build}_archive.zip"
    _W_fileprefix="flashplayer${_W_ver_major}_${_W_ver_minor}r${_W_ver_rel}_${_W_ver_build}"

    # 2013/07/09: Adobe Flash 10 is no longer supported.
    # 2013/06/24: Adobe Flash 10.3 won't even install for me, it tells you to go get a newer version!
    # See
    # https://blogs.adobe.com/psirt/
    # https://get.adobe.com/de/flashplayer/otherversions/
    # Now, we install older versions by using zipfiles at
    # https://helpx.adobe.com/flash-player/kb/archived-flash-player-versions.html

    # 2018/06/24: d4b6f9a5e42cc9f2c7cbd1fd72059d4c1bead91b076afa2ca042d28f0fd7bedb
    w_download "https://fpdownload.macromedia.com/pub/flashplayer/installers/archive/$_W_archive" d4b6f9a5e42cc9f2c7cbd1fd72059d4c1bead91b076afa2ca042d28f0fd7bedb

    # If OS version is Vista or newer:
    #   1. NPAPI plugin doesn't work
    #   2. In win64 prefix, "File not found." dialog appears when installing:
    #      'wine: cannot find L"C:\\windows\\system32\\Macromed\\Temp\\{XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX}\\InstallFlashPlayer.exe"'
    w_set_winver winxp

    # ActiveX plugin
    # 2014/10/02: 3958827058648cfe05fc6ee510685e8d93f995d3428c3eedbd6814704765672a
    w_try_unzip "$W_TMP" "$W_CACHE/flash/$_W_archive" "$_W_dirname/${_W_fileprefix}_winax.exe"
    w_try_cd "$W_TMP/$_W_dirname"
    w_try "$WINE" "${_W_fileprefix}_winax.exe" ${W_OPT_UNATTENDED:+ /install}

    # Mozilla / Firefox (NPAPI) plugin
    # 2014/10/02: 17496fd3c863c180aead953d7d4499dd36f997a9570abc2b92f55e4ea1d55d73
    w_try_unzip "$W_TMP" "$W_CACHE/flash/$_W_archive" "$_W_dirname/${_W_fileprefix}_win.exe"
    w_try "$WINE" "${_W_fileprefix}_win.exe" ${W_OPT_UNATTENDED:+ /install}

    # Projector (standalone player)
    # 2015/07/06: 8640c42e73dc44125045e17abd32412c48f3808a8393c94fc8281cf4b0d87bdc
    w_try_unzip "$W_TMP" "$W_CACHE/flash/$_W_archive" "$_W_dirname/${_W_fileprefix}_win_sa.exe"
    w_try mv "${_W_fileprefix}_win_sa.exe" "$W_SYSTEM32_DLLS/Macromed/Flash"

    # After updating the above, you should carry the following steps out by
    # hand to verify that plugin works.

    #    rm -rf ~/.cache/winetricks/flash
    #    w_try_cd ~/winetricks/src
    #    rm -rf ~/.wine
    #    sh winetricks -q flash ie7
    #    cd "~/.wine/drive_c/Program Files/Internet Explorer"
    #    wine iexplore.exe https://www.adobe.com/software/flash/about
    # Verify that the version of Flash shows up and that you're not prompted
    # to install Flash again
    #
    #    w_try_cd ~/winetricks/src
    #    rm -rf ~/.wine
    #    sh winetricks -q flash firefox
    #    cd "~/.wine/drive_c/Program Files/Mozilla Firefox"
    #    wine firefox.exe https://www.adobe.com/software/flash/about
    # Verify that the version of Flash shows up and that you're not prompted
    # to install Flash again

    unset _W_ver_major _W_ver_minor _W_ver_rel _W_ver_build _W_dirname _W_archive _W_fileprefix
}

#----------------------------------------------------------------

# $1 - gallium nine standalone archive name (required)
helper_galliumnine()
{
    _W_galliumnine_archive="${1}"
    _W_galliumnine_tmp="$W_TMP/galliumnine"

    w_try rm -rf "$_W_galliumnine_tmp"
    w_try mkdir -p "$_W_galliumnine_tmp"
    w_try tar -C "$_W_galliumnine_tmp" --strip-components=1 -zxf "$W_CACHE/$W_PACKAGE/$_W_galliumnine_archive"
    w_try mv "$_W_galliumnine_tmp/lib32/d3d9-nine.dll.so" "$W_SYSTEM32_DLLS/d3d9-nine.dll"
    w_try mv "$_W_galliumnine_tmp/bin32/ninewinecfg.exe.so" "$W_SYSTEM32_DLLS/ninewinecfg.exe"
    if test "$W_ARCH" = "win64"; then
        w_try mv "$_W_galliumnine_tmp/lib64/d3d9-nine.dll.so" "$W_SYSTEM64_DLLS/d3d9-nine.dll"
        w_try mv "$_W_galliumnine_tmp/bin64/ninewinecfg.exe.so" "$W_SYSTEM64_DLLS/ninewinecfg.exe"
    fi
    w_try rm -rf "$_W_galliumnine_tmp"
    # use ninewinecfg to enable gallium nine
    WINEDEBUG=-all w_try "$WINE_MULTI" ninewinecfg -e

    unset _W_galliumnine_tmp _W_galliumnine_archive
}

w_metadata galliumnine02 dlls \
    title="Gallium Nine Standalone (v0.2)" \
    publisher="Gallium Nine Team" \
    year="2019" \
    media="download" \
    file1="gallium-nine-standalone-v0.2.tar.gz" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/d3d9-nine.dll" \
    installed_file2="$W_SYSTEM32_DLLS_WIN/ninewinecfg.exe" \
    homepage="https://github.com/iXit/wine-nine-standalone"

load_galliumnine02()
{
    w_download "https://github.com/iXit/wine-nine-standalone/releases/download/v0.2/gallium-nine-standalone-v0.2.tar.gz" 6818fe890e343aa32d3d53179bfeb63df40977797bd7b6263e85e2bb57559313
    helper_galliumnine "$file1"
}

w_metadata galliumnine03 dlls \
    title="Gallium Nine Standalone (v0.3)" \
    publisher="Gallium Nine Team" \
    year="2019" \
    media="download" \
    file1="gallium-nine-standalone-v0.3.tar.gz" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/d3d9-nine.dll" \
    installed_file2="$W_SYSTEM32_DLLS_WIN/ninewinecfg.exe" \
    homepage="https://github.com/iXit/wine-nine-standalone"

load_galliumnine03()
{
    w_download "https://github.com/iXit/wine-nine-standalone/releases/download/v0.3/gallium-nine-standalone-v0.3.tar.gz" 8bb564073ab2198e5b9b870f7b8cac8d9bc20bc6accf66c4c798e4b450ec0c91
    helper_galliumnine "$file1"
}

w_metadata galliumnine dlls \
    title="Gallium Nine Standalone (latest)" \
    publisher="Gallium Nine Team" \
    year="2019" \
    media="download" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/d3d9-nine.dll" \
    installed_file2="$W_SYSTEM32_DLLS_WIN/ninewinecfg.exe" \
    homepage="https://github.com/iXit/wine-nine-standalone"

load_galliumnine()
{
    w_download_to "${W_TMP_EARLY}" "https://api.github.com/repos/iXit/wine-nine-standalone/releases/latest" "" "release.json"
    _W_galliumnine_version="$(grep -w tag_name ${W_TMP_EARLY}/release.json | cut -d '"' -f 4)"
    w_linkcheck_ignore=1 w_download "https://github.com/iXit/wine-nine-standalone/releases/download/${_W_galliumnine_version}/gallium-nine-standalone-${_W_galliumnine_version}.tar.gz"
    helper_galliumnine "gallium-nine-standalone-${_W_galliumnine_version}.tar.gz"
    unset _W_galliumnine_version
}

#----------------------------------------------------------------

w_metadata gdiplus dlls \
    title="MS GDI+" \
    publisher="Microsoft" \
    year="2011" \
    media="download" \
    file1="../win7sp1/windows6.1-KB976932-X86.exe" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/gdiplus.dll"

load_gdiplus()
{
    # gdiplus has changed in win7. See https://bugs.winehq.org/show_bug.cgi?id=32163#c3
    helper_win7sp1 x86_microsoft.windows.gdiplus_6595b64144ccf1df_1.1.7601.17514_none_72d18a4386696c80/gdiplus.dll
    w_try cp "$W_TMP/x86_microsoft.windows.gdiplus_6595b64144ccf1df_1.1.7601.17514_none_72d18a4386696c80/gdiplus.dll" "$W_SYSTEM32_DLLS/gdiplus.dll"

    if [ "$W_ARCH" = "win64" ]; then
        helper_win7sp1_x64 amd64_microsoft.windows.gdiplus_6595b64144ccf1df_1.1.7601.17514_none_2b24536c71ed437a/gdiplus.dll
        w_try cp "$W_TMP/amd64_microsoft.windows.gdiplus_6595b64144ccf1df_1.1.7601.17514_none_2b24536c71ed437a/gdiplus.dll" "$W_SYSTEM64_DLLS/gdiplus.dll"
    fi

    # For some reason, native, builtin isn't good enough...?
    w_override_dlls native gdiplus
}

#----------------------------------------------------------------

w_metadata gdiplus_winxp dlls \
    title="MS GDI+" \
    publisher="Microsoft" \
    year="2004" \
    media="manual_download" \
    file1="NDP1.0sp2-KB830348-X86-Enu.exe" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/gdiplus.dll"

load_gdiplus_winxp()
{
    # https://www.microsoft.com/en-us/download/details.aspx?id=5339
    w_download https://download.microsoft.com/download/1/4/6/1467c2ba-4d1f-43ad-8d9b-3e8bc1c6ac3d/NDP1.0sp2-KB830348-X86-Enu.exe 3c6c7eed4a0ccd2ea2ce0446359b8c752dd2a3b82332663f655e803ce0b05335
    w_try_cd "$W_CACHE/$W_PACKAGE"
    w_try_cabextract -d "$W_TMP" -F FL_gdiplus_dll_____X86.3643236F_FC70_11D3_A536_0090278A1BB8 "$W_CACHE/${W_PACKAGE}/$file1"
    w_try cp "$W_TMP/FL_gdiplus_dll_____X86.3643236F_FC70_11D3_A536_0090278A1BB8" "$W_SYSTEM32_DLLS/gdiplus.dll"

    # For some reason, native, builtin isn't good enough...?
    w_override_dlls native gdiplus
}

#----------------------------------------------------------------

w_metadata glidewrapper dlls \
    title="GlideWrapper" \
    publisher="Rolf Neuberger" \
    year="2005" \
    media="download" \
    file1="GlideWrapper084c.exe" \
    installed_file1="c:/windows/glide3x.dll"

load_glidewrapper()
{
    w_download http://www.zeckensack.de/glide/archive/GlideWrapper084c.exe 3c4185bd7eac9bd50e0727a7b5165ec8273230455480cf94358e1bbd35921b69
    w_try_cd "$W_CACHE/$W_PACKAGE"

    # The installer opens its README in a web browser, really annoying when doing make check/test:
    # FIXME: maybe we should back up this key first?
    if test ${W_OPT_UNATTENDED}; then
        cat > "$W_TMP"/disable-browser.reg <<_EOF_
REGEDIT4

[HKEY_CURRENT_USER\\Software\\Wine\\WineBrowser]
"Browsers"=""

_EOF_
        w_try_regedit "$W_TMP_WIN"\\disable-browser.reg

    fi

    # NSIS installer
    w_try "$WINE" "$file1" ${W_OPT_UNATTENDED:+ /S}

    if test ${W_OPT_UNATTENDED}; then
        "$WINE" reg delete "HKEY_CURRENT_USER\\Software\\Wine\\WineBrowser" /v Browsers /f || true
    fi
}

#----------------------------------------------------------------

w_metadata gfw dlls \
    title="MS Games For Windows Live (xlive.dll)" \
    publisher="Microsoft" \
    year="2008" \
    media="download" \
    file1="gfwlivesetupmin.exe" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/xlive.dll"

load_gfw()
{
    # https://www.microsoft.com/games/en-us/live/pages/livejoin.aspx
    # http://www.next-gen.biz/features/should-games-for-windows-live-die
    w_download https://download.microsoft.com/download/5/5/8/55846E20-4A46-4EF8-B272-7F988BC9090A/gfwlivesetupmin.exe b14609508e2f8dba0886ded84e2817ad532ebfa31f8a6d4be2e6a5a03a9d7c23

    # FIXME: Depends on .NET 20, but is it really needed? For now, skip it.
    w_try_cd "$W_CACHE/$W_PACKAGE"
    w_try "$WINE" gfwlivesetupmin.exe /nodotnet $W_UNATTENDED_SLASH_Q

    w_call msasn1
}

#----------------------------------------------------------------

w_metadata glut dlls \
    title="The glut utility library for OpenGL" \
    publisher="Mark J. Kilgard" \
    year="2001" \
    media="download" \
    file1="glut-3.7.6-bin.zip" \
    installed_file1="c:/glut-3.7.6-bin/glut32.lib"

load_glut()
{
    w_download https://press.liacs.nl/researchdownloads/glut.win32/glut-3.7.6-bin.zip 788e97653bfd527afbdc69e1b7c6bcf9cb45f33d13ddf9d676dc070da92f80d4
    # FreeBSD unzip rm -rf's inside the target directory before extracting:
    w_try_unzip "$W_TMP" "$W_CACHE"/glut/glut-3.7.6-bin.zip
    w_try mv "$W_TMP/glut-3.7.6-bin" "$W_DRIVE_C"
    w_try cp "$W_DRIVE_C"/glut-3.7.6-bin/glut32.dll "$W_SYSTEM32_DLLS"
    w_warn "If you want to compile glut programs, add c:/glut-3.7.6-bin to LIB and INCLUDE"
}

#----------------------------------------------------------------

w_metadata gmdls dlls \
    title="General MIDI DLS Collection" \
    publisher="Microsoft / Roland" \
    year="1999" \
    media="download" \
    file1="../directx9/directx_apr2006_redist.exe" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/drivers/gm.dls"

load_gmdls()
{
    w_download_to directx9 https://download.microsoft.com/download/3/9/7/3972f80c-5711-4e14-9483-959d48a2d03b/directx_apr2006_redist.exe dd8c3d401efe4561b67bd88475201b2f62f43cd23e4acc947bb34a659fa74952

    w_try_cabextract -d "$W_TMP" -F DirectX.cab "$W_CACHE"/directx9/directx_apr2006_redist.exe
    w_try_cabextract -d "$W_TMP" -F gm16.dls "$W_TMP"/DirectX.cab
    w_try mv "$W_TMP"/gm16.dls "$W_SYSTEM32_DLLS"/drivers/gm.dls
    if test "$W_ARCH" = "win64"; then
        w_try_cd "$W_SYSTEM64_DLLS"/drivers
        w_try ln -s ../../syswow64/drivers/gm.dls
    fi
}

#----------------------------------------------------------------
# um, codecs are kind of clustered here.  They probably deserve their own real category.

w_metadata allcodecs dlls \
    title="All codecs (dirac, ffdshow, icodecs, cinepak, l3codecx, xvid) except wmp" \
    publisher="various" \
    year="1995-2009" \
    media="download"

load_allcodecs()
{
    w_call dirac
    w_call l3codecx
    w_call ffdshow
    w_call icodecs
    w_call cinepak
    w_call xvid
}

#----------------------------------------------------------------

w_metadata dirac dlls \
    title="The Dirac directshow filter v1.0.2" \
    publisher="Dirac" \
    year="2009" \
    media="download" \
    file1="DiracDirectShowFilter-1.0.2.exe" \
    installed_file1="$W_PROGRAMS_X86_WIN/Dirac/DiracDecoder.dll"

load_dirac()
{
    w_download $WINETRICKS_SOURCEFORGE/dirac/DiracDirectShowFilter-1.0.2.exe 7257de4be940405637bb5d11c1179f7db86f165f21fc0ba24f42a9ecbc55fe20

    # Avoid mfc90 not found error.  (DiracSplitter-libschroedinger.ax needs mfc90 to register itself, I think.)
    w_call vcrun2008

    w_try_cd "$W_CACHE/$W_PACKAGE"
    w_ahk_do "
        SetTitleMatchMode, 2
        run DiracDirectShowFilter-1.0.2.exe
        WinWait, Dirac, Welcome
        if ( w_opt_unattended > 0 ) {
            ControlClick, Button2
            WinWait, Dirac, License
            Sleep 1000
            ControlClick, Button2
            WinWait, Dirac, Location
            Sleep 1000
            ControlClick, Button2
            WinWait, Dirac, Components
            Sleep 1000
            ControlClick, Button2
            WinWait, Dirac, environment
            Sleep 1000
            ControlCLick, Button1
            WinWait, Dirac, installed
            Sleep 1000
            ControlClick, Button2
        }
        WinWaitClose
    "
}

#----------------------------------------------------------------

w_metadata ffdshow dlls \
    title="ffdshow video codecs" \
    publisher="doom9 folks" \
    year="2010" \
    media="download" \
    file1="ffdshow_beta7_rev3154_20091209.exe" \
    installed_file1="$W_PROGRAMS_X86_WIN/ffdshow/ff_liba52.dll" \
    homepage="https://ffdshow-tryout.sourceforge.io/"

load_ffdshow()
{
    w_download $WINETRICKS_SOURCEFORGE/ffdshow-tryout/ffdshow_beta7_rev3154_20091209.exe 86fb22e9a79a1c83340a99fd5722974a4d03948109d404a383c4334fab8f8860
    w_try_cd "$W_CACHE/$W_PACKAGE"
    w_try "$WINE" ffdshow_beta7_rev3154_20091209.exe $W_UNATTENDED_SLASH_SILENT
}

#----------------------------------------------------------------

w_metadata hid dlls \
    title="MS hid" \
    publisher="Microsoft" \
    year="2003" \
    media="download" \
    file1="../win2ksp4/W2KSP4_EN.EXE" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/hid.dll"

load_hid()
{
    helper_win2ksp4 i386/hid.dl_
    w_try_cabextract --directory="$W_SYSTEM32_DLLS" "$W_TMP"/i386/hid.dl_

    w_override_dlls native hid
}

#----------------------------------------------------------------

w_metadata icodecs dlls \
    title="Indeo codecs" \
    publisher="Intel" \
    year="1998" \
    media="download" \
    file1="codinstl.exe" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/ir50_32.dll"

load_icodecs()
{
    # Note: this codec is insecure, see
    # https://support.microsoft.com/kb/954157
    # Original source, ftp://download.intel.com/support/createshare/camerapack/codinstl.exe, had same checksum
    # 2010/11/14: http://codec.alshow.co.kr/Down/codinstl.exe
    # 2014/04/11: http://www.cucusoft.com/codecdownload/codinstl.exe (linked from http://www.cucusoft.com/codec.asp)
    w_download "http://www.cucusoft.com/codecdownload/codinstl.exe" 0979d43568111cadf0b3bf43cd8d746ac3de505759c14f381592b4f8439f6c95

    w_try_cd "$W_CACHE/$W_PACKAGE"

    w_ahk_do "
        SetTitleMatchMode, 2
        run codinstl.exe
        winwait, Welcome
        if ( w_opt_unattended > 0 ) {
            sleep 1000
            controlclick, Button1  ; Next
            winwait, Software License Agreement
            sleep 1000
            controlclick, Button2  ; Yes
        }
        winwait, Setup Complete
        if ( w_opt_unattended > 0 ) {
            sleep 1000
            controlclick, Button4  ; Finish
        }
        winwaitclose
    "

    # Work around bug in codec's installer?
    # https://support.britannica.com/other/touchthesky/win/issues/TSTUw_150.htm
    # https://appdb.winehq.org/objectManager.php?sClass=version&iId=7091
    w_try_regsvr ir50_32.dll

    # Apparently some codecs are missing, see https://github.com/Winetricks/winetricks/issues/302
    # Download at https://www.moviecodec.com/download-codec-packs/indeo-codecs-legacy-package-31/
    w_download https://s3.amazonaws.com/moviecodec/files/iv5setup.exe 51bec25488b5b94eb3ce49b0a117618c9526161fd0753817a7a724ce25ff0cad

    w_ahk_do "
        SetTitleMatchMode, 2
        run iv5setup.exe
        winwait, InstallShield Wizard
        if ( w_opt_unattended > 0 ) {
            sleep 1000
            controlclick, Button2  ; Next
            winwait, Welcome
            controlclick, Button1  ; Next
            winwait, Software License Agreement
            sleep 1000
            controlclick, Button2  ; Yes
            winwait, Choose Destination
            sleep 1000
            controlclick, Button1  ; Next
            winwait, Setup Type
            sleep 1000
            controlclick, ListBox1  ; Next
            sleep 1000
            Send C ; Custom
            sleep 1000
            controlclick, Button2  ; Next
            winwait, Select Components
            controlclick, ISAVIEWCMPTCLASS1 ; Component Selection
            Send {Home}
            Send {Down}  ;
            Send {Down}  ; IV5 Directshow plugin (gives error about missing Ivfsrc.ax)
            Send {Space} ; Disable it (directshow plugin)
            Send {End}   ; Web browser (Netscape) plugin
            sleep 1000
            Send {Space} ; Disable it (web plugin)
            sleep 1000
            controlclick, Button3  ; Next
            winwait, Question
            sleep 1000
            controlclick, Button2  ; No
            winwait, Start Copying Files
            sleep 1000
            controlclick, Button1  ; No
        }
        winwait, Setup Complete
        if ( w_opt_unattended > 0 ) {
            sleep 1000
            controlclick, Button4  ; Finish
        }
        winwaitclose
    "
        # Note, this leaves a dangling explorer window. The window name changed at some point
        # because of a fixed wine bug that I'm too lazy to find. Since AHK doesn't make command line
        # arguments easily accessible, we'd have to just kill all explorer.exe processes.
        #
        # So instead, use system kill
        inode_pid="$(pgrep -f "explorer.exe.*Indeo")"
        kill -HUP "$inode_pid"
}

#----------------------------------------------------------------

w_metadata itircl dlls \
    title="MS itircl.dll" \
    publisher="Microsoft" \
    year="1999" \
    media="download" \
    file1="../hhw/htmlhelp.exe" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/itircl.dll"

load_itircl()
{
    # https://msdn.microsoft.com/en-us/library/windows/desktop/ms669985(v=vs.85).aspx
    w_download_to hhw https://download.microsoft.com/download/0/A/9/0A939EF6-E31C-430F-A3DF-DFAE7960D564/htmlhelp.exe b2b3140d42a818870c1ab13c1c7b8d4536f22bd994fa90aade89729a6009a3ae

    w_try_cabextract -d "$W_TMP" -F hhupd.exe "$W_CACHE"/hhw/htmlhelp.exe
    w_try_cabextract -d "$W_SYSTEM32_DLLS" -F itircl.dll "$W_TMP"/hhupd.exe
    w_override_dlls native itircl
    w_try_regsvr itircl.dll
}

#----------------------------------------------------------------

w_metadata itss dlls \
    title="MS itss.dll" \
    publisher="Microsoft" \
    year="1999" \
    media="download" \
    file1="../hhw/htmlhelp.exe" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/itss.dll"

load_itss()
{
    # https://msdn.microsoft.com/en-us/library/windows/desktop/ms669985(v=vs.85).aspx
    w_download_to hhw https://download.microsoft.com/download/0/A/9/0A939EF6-E31C-430F-A3DF-DFAE7960D564/htmlhelp.exe b2b3140d42a818870c1ab13c1c7b8d4536f22bd994fa90aade89729a6009a3ae

    w_try_cabextract -d "$W_TMP" -F hhupd.exe "$W_CACHE"/hhw/htmlhelp.exe
    w_try_cabextract -d "$W_SYSTEM32_DLLS" -F itss.dll "$W_TMP"/hhupd.exe
    w_override_dlls native itss
    w_try_regsvr itss.dll
}

#----------------------------------------------------------------

w_metadata cinepak dlls \
    title="Cinepak Codec" \
    publisher="Radius" \
    year="1995" \
    media="download" \
    file1="cvid32.zip" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/iccvid.dll" \
    homepage="http://www.probo.com/cinepak.php"

load_cinepak()
{
    w_download "http://www.probo.com/pub/cinepak/cvid32.zip" a41984a954fe77557f228fa8a95cdc05db22bf9ff5429fe4307fd6fc51e11969

    if [ -f "$W_SYSTEM32_DLLS/iccvid.dll" ]; then
        w_try rm -f "$W_SYSTEM32_DLLS/iccvid.dll"
    fi

    w_try_unzip "$W_SYSTEM32_DLLS" "${W_CACHE}/${W_PACKAGE}/${file1}" ICCVID.DLL

    w_try mv -f "$W_SYSTEM32_DLLS/ICCVID.DLL" "$W_SYSTEM32_DLLS/iccvid.dll"

    w_override_dlls native iccvid
}

#----------------------------------------------------------------

w_metadata jet40 dlls \
    title="MS Jet 4.0 Service Pack 8" \
    publisher="Microsoft" \
    year="2003" \
    media="download" \
    file1="jet40sp8_9xnt.exe" \
    installed_file1="$W_COMMONFILES_WIN/Microsoft Shared/dao/dao360.dll"

load_jet40()
{
    # mdac27 is 32-bit only, so use mdac28 for win64:
    if [ "$W_ARCH" = "win64" ] ; then
        w_call mdac28
    else
        w_call mdac27
    fi
    w_call wsh57

    # https://support.microsoft.com/kb/239114
    # See also https://bugs.winehq.org/show_bug.cgi?id=6085
    # FIXME: "failed with error 2"
    w_download https://download.microsoft.com/download/4/3/9/4393c9ac-e69e-458d-9f6d-2fe191c51469/jet40sp8_9xnt.exe b060246cd499085a31f15873689d5fa7df817e407c8261a5c71fa6b9f7042560

    w_try_cd "$W_CACHE/$W_PACKAGE"
    w_try "$WINE" jet40sp8_9xnt.exe $W_UNATTENDED_SLASH_Q
}

# FIXME: verify_jet40()
# See https://github.com/Winetricks/winetricks/issues/327,
# https://en.wikibooks.org/wiki/JET_Database/Creating_and_connecting, and
# https://msdn.microsoft.com/en-us/library/ms677200%28v=vs.85%29.aspx

#----------------------------------------------------------------

w_metadata ie8_kb2936068 dlls \
    title="Cumulative Security Update for Internet Explorer 8" \
    publisher="Microsoft" \
    year="2014" \
    media="download" \
    file1="IE8-WindowsXP-KB2936068-x86-ENU.exe" \
    installed_file1="c:/windows/KB2936068-IE8.log"

load_ie8_kb2936068()
{
    # If we really need win64 support, should check if there's an x64 version of the hotfix
    w_package_unsupported_win64

    w_call ie8

    w_download https://download.microsoft.com/download/3/8/C/38CE0ABB-01FD-4C0A-A569-BC5E82C34A17/IE8-WindowsXP-KB2936068-x86-ENU.exe 8bda23c78cdcd9d01c364a01c6d639dfb2d11550a5521b8a81c808c1a2b1824e

    if [ -n "$W_UNATTENDED_SLASH_Q" ]; then
        quiet="$W_UNATTENDED_SLASH_QUIET /forcerestart"
    else
        quiet=""
    fi

    w_try_cd "$W_CACHE/$W_PACKAGE"
    "$WINE" IE8-WindowsXP-KB2936068-x86-ENU.exe $quiet
    status=$?
    case $status in
        0|194) ;;
        *) w_die "$W_PACKAGE installation failed"
    esac
}

#----------------------------------------------------------------

w_metadata l3codecx dlls \
    title="MPEG Layer-3 Audio Codec for Microsoft DirectShow" \
    publisher="Microsoft" \
    year="2010" \
    media="download" \
    file1="../directx9/directx_feb2010_redist.exe" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/l3codecx.ax"

load_l3codecx()
{
    helper_directx_dl

    w_try_cabextract -d "$W_TMP" -L -F dxnt.cab "$W_CACHE"/directx9/$DIRECTX_NAME
    w_try_cabextract -d "$W_SYSTEM32_DLLS" -L -F 'l3codecx.ax' "$W_TMP/dxnt.cab"

    w_try_regsvr l3codecx.ax
}

#----------------------------------------------------------------

# FIXME: installed location is
# $W_PROGRAMS_X86_WIN/Gemeinsame Dateien/System/ADO/msado26.tlb
# in German... need a variable W_COMMONFILES or something like that

w_metadata mdac27 dlls \
    title="Microsoft Data Access Components 2.7 sp1" \
    publisher="Microsoft" \
    year="2006" \
    media="download" \
    file1="MDAC_TYP.EXE" \
    installed_file1="$W_COMMONFILES_X86_WIN/System/ADO/msado26.tlb"

load_mdac27()
{
    w_package_unsupported_win64

    # https://www.microsoft.com/downloads/en/details.aspx?FamilyId=9AD000F2-CAE7-493D-B0F3-AE36C570ADE8&displaylang=en
    # Originally at: https://download.microsoft.com/download/3/b/f/3bf74b01-16ba-472d-9a8c-42b2b4fa0d76/mdac_typ.exe
    # Mirror list: http://www.filewatcher.com/m/MDAC_TYP.EXE.5389224-0.html (5.14 MB MDAC_TYP.EXE)
    # 2018/08/09: ftp.gunadarma.ac.id is dead, moved to archive.org
    w_download https://web.archive.org/web/20060718123742/http://ftp.gunadarma.ac.id/pub/driver/itegno/USB%20Software/MDAC/MDAC_TYP.EXE 36d2a3099e6286ae3fab181a502a95fbd825fa5ddb30bf09b345abc7f1f620b4

    load_native_mdac
    w_set_winver nt40
    w_try_cd "${W_CACHE}/${W_PACKAGE}"
    w_try "$WINE" "${file1}" ${W_OPT_UNATTENDED:+ /q /C:"setup $W_UNATTENDED_SLASH_QNT"}
    w_unset_winver
}

#----------------------------------------------------------------

w_metadata mdac28 dlls \
    title="Microsoft Data Access Components 2.8 sp1" \
    publisher="Microsoft" \
    year="2005" \
    media="download" \
    file1="MDAC_TYP.EXE" \
    installed_file1="$W_COMMONFILES_X86_WIN/System/ADO/msado27.tlb"

load_mdac28()
{
    # Not a blocker, depends on gcc version
    if w_workaround_wine_bug 45627 "Depending on your compiler, you may see crashes before wine-3.21. See https://bugs.winehq.org/show_bug.cgi?id=45627" ,3.21; then
        true
    fi

    # https://www.microsoft.com/en-us/download/details.aspx?id=5793
    w_download https://download.microsoft.com/download/4/a/a/4aafff19-9d21-4d35-ae81-02c48dcbbbff/MDAC_TYP.EXE 157ebae46932cb9047b58aa849ac1885e8cbd2f218810cb83e57613b49c679d6
    load_native_mdac
    w_set_winver nt40
    w_try_cd "$W_CACHE"/"$W_PACKAGE"
    w_try "$WINE" mdac_typ.exe ${W_OPT_UNATTENDED:+ /q /C:"setup $W_UNATTENDED_SLASH_QNT"}
    w_unset_winver
}

#----------------------------------------------------------------

w_metadata mdx dlls \
    title="Managed DirectX" \
    publisher="Microsoft" \
    year="2006" \
    media="download" \
    file1="../directx9/directx_feb2010_redist.exe" \
    installed_file1="C:/windows/assembly/GAC/microsoft.directx/1.0.2902.0__31bf3856ad364e35/microsoft.directx.dll"

load_mdx()
{
    helper_directx_Jun2010

    w_try_cd "$W_TMP"

    w_try_cabextract -F "*MDX*" "$W_CACHE"/directx9/$DIRECTX_NAME
    w_try_cabextract -F "*.cab" ./*Archive.cab

    # Install assemblies
    w_try_cabextract -d "$W_WINDIR_UNIX/Microsoft.NET/DirectX for Managed Code/1.0.2902.0" -F "microsoft.directx*" ./*MDX1_x86.cab
    for file in mdx_*.cab
    do
        ver="${file%%_x86.cab}"
        ver="${ver##mdx_}"
        w_try_cabextract -d "$W_WINDIR_UNIX/Microsoft.NET/DirectX for Managed Code/$ver" -F "microsoft.directx*" "$file"
    done
    w_try_cabextract -d "$W_WINDIR_UNIX/Microsoft.NET/DirectX for Managed Code/1.0.2911.0" -F "microsoft.directx.direct3dx*" ./*MDX1_x86.cab

    # Add them to GAC
    w_try_cd "$W_WINDIR_UNIX/Microsoft.NET/DirectX for Managed Code"
    for ver in *
    do
        (
            w_try_cd "$ver"
            for asm in *.dll
            do
                name="${asm%%.dll}"
                w_try mkdir -p "$W_WINDIR_UNIX/assembly/GAC/$name/${ver}__31bf3856ad364e35"
                w_try cp "$asm" "$W_WINDIR_UNIX/assembly/GAC/$name/${ver}__31bf3856ad364e35"
            done
        )
    done

    # AssemblyFolders
    cat > "$W_TMP"/asmfolders.reg <<_EOF_
REGEDIT4

[HKEY_LOCAL_MACHINE\\Software\\Microsoft\\.NETFramework\\AssemblyFolders\\DX_1.0.2902.0]
@="C:\\\\windows\\\\Microsoft.NET\\\\DirectX for Managed Code\\\\1.0.2902.0\\\\"

[HKEY_LOCAL_MACHINE\\Software\\Microsoft\\.NETFramework\\AssemblyFolders\\DX_1.0.2903.0]
@="C:\\\\windows\\\\Microsoft.NET\\\\DirectX for Managed Code\\\\1.0.2903.0\\\\"

[HKEY_LOCAL_MACHINE\\Software\\Microsoft\\.NETFramework\\AssemblyFolders\\DX_1.0.2904.0]
@="C:\\\\windows\\\\Microsoft.NET\\\\DirectX for Managed Code\\\\1.0.2904.0\\\\"

[HKEY_LOCAL_MACHINE\\Software\\Microsoft\\.NETFramework\\AssemblyFolders\\DX_1.0.2905.0]
@="C:\\\\windows\\\\Microsoft.NET\\\\DirectX for Managed Code\\\\1.0.2905.0\\\\"

[HKEY_LOCAL_MACHINE\\Software\\Microsoft\\.NETFramework\\AssemblyFolders\\DX_1.0.2906.0]
@="C:\\\\windows\\\\Microsoft.NET\\\\DirectX for Managed Code\\\\1.0.2906.0\\\\"

[HKEY_LOCAL_MACHINE\\Software\\Microsoft\\.NETFramework\\AssemblyFolders\\DX_1.0.2907.0]
@="C:\\\\windows\\\\Microsoft.NET\\\\DirectX for Managed Code\\\\1.0.2907.0\\\\"

[HKEY_LOCAL_MACHINE\\Software\\Microsoft\\.NETFramework\\AssemblyFolders\\DX_1.0.2908.0]
@="C:\\\\windows\\\\Microsoft.NET\\\\DirectX for Managed Code\\\\1.0.2908.0\\\\"

[HKEY_LOCAL_MACHINE\\Software\\Microsoft\\.NETFramework\\AssemblyFolders\\DX_1.0.2909.0]
@="C:\\\\windows\\\\Microsoft.NET\\\\DirectX for Managed Code\\\\1.0.2909.0\\\\"

[HKEY_LOCAL_MACHINE\\Software\\Microsoft\\.NETFramework\\AssemblyFolders\\DX_1.0.2910.0]
@="C:\\\\windows\\\\Microsoft.NET\\\\DirectX for Managed Code\\\\1.0.2910.0\\\\"

[HKEY_LOCAL_MACHINE\\Software\\Microsoft\\.NETFramework\\AssemblyFolders\\DX_1.0.2911.0]
@="C:\\\\windows\\\\Microsoft.NET\\\\DirectX for Managed Code\\\\1.0.2911.0\\\\"
_EOF_
    w_try_regedit "$W_TMP_WIN"\\asmfolders.reg
}

#----------------------------------------------------------------

w_metadata mf dlls \
    title="MS Media Foundation" \
    publisher="Microsoft" \
    year="2011" \
    media="download" \
    file1="../win7sp1/windows6.1-KB976932-X86.exe" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/mf.dll"

load_mf()
{
    helper_win7sp1 x86_microsoft-windows-mediafoundation_31bf3856ad364e35_6.1.7601.17514_none_9e6699276b03c38e/mf.dll
    w_try cp "$W_TMP/x86_microsoft-windows-mediafoundation_31bf3856ad364e35_6.1.7601.17514_none_9e6699276b03c38e/mf.dll" "$W_SYSTEM32_DLLS/mf.dll"

    if [ "$W_ARCH" = "win64" ]; then
        helper_win7sp1_x64 amd64_microsoft-windows-mediafoundation_31bf3856ad364e35_6.1.7601.17514_none_fa8534ab236134c4/mf.dll
        w_try cp "$W_TMP/amd64_microsoft-windows-mediafoundation_31bf3856ad364e35_6.1.7601.17514_none_fa8534ab236134c4/mf.dll" "$W_SYSTEM64_DLLS/mf.dll"
    fi

    w_override_dlls native,builtin mf
}

#----------------------------------------------------------------

w_metadata mfc40 dlls \
    title="MS mfc40 (Microsoft Foundation Classes from win7sp1)" \
    publisher="Microsoft" \
    year="1999" \
    media="download" \
    file1="../win7sp1/windows6.1-KB976932-X86.exe" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/mfc40.dll"

load_mfc40()
{
    w_warn "mfc40 no longer installs msvcrt40.dll, only mfc40.dll/mfc40u.dll. Please file a bug if you have an application that needs native msvcrt40.dll."

    helper_win7sp1 x86_microsoft-windows-mfc40_31bf3856ad364e35_6.1.7601.17514_none_5c06580240091047/mfc40.dll
    w_try cp "$W_TMP/x86_microsoft-windows-mfc40_31bf3856ad364e35_6.1.7601.17514_none_5c06580240091047/mfc40.dll" "$W_SYSTEM32_DLLS/mfc40.dll"

    helper_win7sp1 x86_microsoft-windows-mfc40u_31bf3856ad364e35_6.1.7601.17514_none_f51a7bf0b3d25294/mfc40u.dll
    w_try cp "$W_TMP/x86_microsoft-windows-mfc40u_31bf3856ad364e35_6.1.7601.17514_none_f51a7bf0b3d25294/mfc40u.dll" "$W_SYSTEM32_DLLS/mfc40u.dll"
}

#----------------------------------------------------------------

w_metadata msacm32 dlls \
    title="MS ACM32" \
    publisher="Microsoft" \
    year="2003" \
    media="download" \
    file1="../winxpsp3/WindowsXP-KB936929-SP3-x86-ENU.exe" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/msacm32.dll"

load_msacm32()
{
    helper_winxpsp3 i386/msacm32.dl_
    w_try_cabextract --directory="$W_SYSTEM32_DLLS" "$W_TMP"/i386/msacm32.dl_
    w_override_dlls native,builtin msacm32
}

#----------------------------------------------------------------

w_metadata msasn1 dlls \
    title="MS ASN1" \
    publisher="Microsoft" \
    year="2003" \
    media="download" \
    file1="../win2ksp4/W2KSP4_EN.EXE" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/msasn1.dll"

load_msasn1()
{
    helper_win2ksp4 i386/msasn1.dl_
    w_try_cabextract --directory="$W_SYSTEM32_DLLS" "$W_TMP"/i386/msasn1.dl_
}

#----------------------------------------------------------------

w_metadata msctf dlls \
    title="MS Text Service Module" \
    publisher="Microsoft" \
    year="2003" \
    media="download" \
    file1="../winxpsp3/WindowsXP-KB936929-SP3-x86-ENU.exe" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/msctf.dll"

load_msctf()
{
    helper_winxpsp3 i386/msctf.dl_
    w_try_cabextract --directory="$W_SYSTEM32_DLLS" "$W_TMP"/i386/msctf.dl_
    w_override_dlls native,builtin msctf
}

#----------------------------------------------------------------

w_metadata msdxmocx dlls \
    title="MS Windows Media Player 2 ActiveX control for VB6" \
    publisher="Microsoft" \
    year="1999" \
    media="download" \
    file1="mpfull.exe" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/msdxm.ocx"

load_msdxmocx()
{
    # Previously at https://www.oldapps.com/windows_media_player.php?old_windows_media_player=3?download
    # 2015/12/01: Iceweasel gave a security warning (!), but clamscan and virustotal.com report it as clean
    #
    # 2016/02/18: Since then, oldapps.com removed it. It's on a Finnish mirror, where it's been since 2001/10/20
    # Found using http://www.filewatcher.com/m/mpfull.exe.3593680-0.html
    # The sha256sum is different. Perhaps Iceweasel was right. This one is also clean according to clamscan/virustotal.com

    # 2017/09/28: define.fi is down, these sites have mpfull.exe with the original sha256:
    # http://hell.pl/agnus/windows95/
    # http://zerosky.oldos.org/win9x.html
    # https://sdfox7.com/win95/

    w_download http://hell.pl/agnus/windows95/mpfull.exe a39b2b9735cedd513fcb78f8634695d35073e9d7e865e536a0da6db38c7225e4

    w_try_cabextract --directory="$W_SYSTEM32_DLLS" "$W_CACHE/$W_PACKAGE/${file1}"
    w_try_regsvr msdxm.ocx
}

#----------------------------------------------------------------

w_metadata msflxgrd dlls \
    title="MS FlexGrid Control (msflxgrd.ocx)" \
    publisher="Microsoft" \
    year="2012" \
    media="download" \
    file1="../vb6sp6/VB60SP6-KB2708437-x86-ENU.msi" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/msflxgrd.ocx"

load_msflxgrd()
{
    helper_vb6sp6 "$W_TMP" MSFlxGrd.ocx
    w_try mv "${W_TMP}/MSFlxGrd.ocx" "$W_SYSTEM32_DLLS/msflxgrd.ocx"
    w_try_regsvr msflxgrd.ocx
}

#----------------------------------------------------------------

w_metadata mshflxgd dlls \
    title="MS Hierarchical FlexGrid Control (mshflxgd.ocx)" \
    publisher="Microsoft" \
    year="2012" \
    media="download" \
    file1="../vb6sp6/VB60SP6-KB2708437-x86-ENU.msi" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/mshflxgd.ocx"

load_mshflxgd()
{
    helper_vb6sp6 "$W_TMP" MShflxgd.ocx
    w_try mv "${W_TMP}/MShflxgd.ocx" "$W_SYSTEM32_DLLS/mshflxgd.ocx"
    w_try_regsvr mshflxgd.ocx
}

#----------------------------------------------------------------

w_metadata mspatcha dlls \
    title="MS mspatcha" \
    publisher="Microsoft" \
    year="2004" \
    media="download" \
    file1="../win2ksp4/W2KSP4_EN.EXE" \
    installed_exe1="$W_SYSTEM32_DLLS_WIN/mspatcha.dll"

load_mspatcha()
{
    helper_win2ksp4 i386/mspatcha.dl_
    w_try_cabextract --directory="$W_SYSTEM32_DLLS" "$W_TMP"/i386/mspatcha.dl_

    w_override_dlls native,builtin mspatcha
}

#----------------------------------------------------------------

w_metadata msscript dlls \
    title="MS Windows Script Control" \
    publisher="Microsoft" \
    year="2004" \
    media="download" \
    file1="../winxpsp3/WindowsXP-KB936929-SP3-x86-ENU.exe" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/msscript.ocx"

load_msscript()
{
    helper_winxpsp3 i386/msscript.oc_
    w_try_cabextract --directory="$W_SYSTEM32_DLLS" "$W_TMP"/i386/msscript.oc_
    w_override_dlls native,builtin i386/msscript.ocx
}

#----------------------------------------------------------------

w_metadata msls31 dlls \
    title="MS Line Services" \
    publisher="Microsoft" \
    year="2001" \
    media="download" \
    file1="InstMsiW.exe" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/msls31.dll"

load_msls31()
{
    # Needed by native RichEdit and Internet Explorer
    # Originally at https://download.microsoft.com/download/WindowsInstaller/Install/2.0/NT45/EN-US/InstMsiW.exe
    # Mirror list at http://www.filewatcher.com/m/InstMsiW.exe.1822848-0.html
    w_download https://ftp.hp.com/pub/softlib/software/msi/InstMsiW.exe 4c3516c0b5c2b76b88209b22e3bf1cb82d8e2de7116125e97e128952372eed6b InstMsiW.exe

    w_try_cabextract --directory="$W_TMP" "$W_CACHE"/msls31/InstMsiW.exe
    w_try cp -f "$W_TMP"/msls31.dll "$W_SYSTEM32_DLLS"
}

#----------------------------------------------------------------

w_metadata msmask dlls \
    title="MS Masked Edit Control" \
    publisher="Microsoft" \
    year="2009" \
    media="download" \
    file1="../vb6sp6/VB60SP6-KB2708437-x86-ENU.msi" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/msmask32.ocx"

load_msmask()
{
    helper_vb6sp6 "$W_TMP" msmask32.ocx
    w_try mv "${W_TMP}/msmask32.ocx" "$W_SYSTEM32_DLLS/msmask32.ocx"
    w_try_regsvr msmask32.ocx
}

 #----------------------------------------------------------------

w_metadata msftedit dlls \
    title="Microsoft RichEdit Control" \
    publisher="Microsoft" \
    year="2011" \
    media="download" \
    file1="../win7sp1/windows6.1-KB976932-X86.exe" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/msftedit.dll"

load_msftedit()
{
    helper_win7sp1 x86_microsoft-windows-msftedit_31bf3856ad364e35_6.1.7601.17514_none_d7d862f19573a5ff/msftedit.dll
    w_try cp "$W_TMP/x86_microsoft-windows-msftedit_31bf3856ad364e35_6.1.7601.17514_none_d7d862f19573a5ff/msftedit.dll" "$W_SYSTEM32_DLLS/msftedit.dll"

    if [ "$W_ARCH" = "win64" ]; then
        helper_win7sp1_x64 amd64_microsoft-windows-msftedit_31bf3856ad364e35_6.1.7601.17514_none_33f6fe754dd11735/msftedit.dll
        w_try cp "$W_TMP/amd64_microsoft-windows-msftedit_31bf3856ad364e35_6.1.7601.17514_none_33f6fe754dd11735/msftedit.dll" "$W_SYSTEM64_DLLS/msftedit.dll"
    fi

    w_override_dlls native,builtin msftedit
}

#----------------------------------------------------------------

w_metadata msxml3 dlls \
    title="MS XML Core Services 3.0" \
    publisher="Microsoft" \
    year="2005" \
    media="download" \
    file1="msxml3.msi" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/msxml3.dll"

load_msxml3()
{
    # Service Pack 7
    # Originally at https://download.microsoft.com/download/8/8/8/888f34b7-4f54-4f06-8dac-fa29b19f33dd/msxml3.msi
    # Mirror list: http://www.filewatcher.com/m/msxml3.msi.1070592-0.html
    # Known bad sites (2017/06/11):
    # ftp://support.danbit.dk/D/DVD-RW-USB2B/Driver/Installation/Data/Redist/msxml3.msi
    # ftp://94.79.56.169/common/Client/MSXML%204.0%20Service%20Pack%202/msxml3.msi
    w_download https://media.codeweavers.com/pub/other/msxml3.msi f9c678f8217e9d4f9647e8a1f6d89a7c26a57b9e9e00d39f7487493dd7b4e36c

    # It won't install on top of Wine's msxml3, which has a pretty high version number, so delete Wine's fake DLL
    rm "$W_SYSTEM32_DLLS"/msxml3.dll
    w_override_dlls native msxml3
    w_try_cd "$W_CACHE/$W_PACKAGE"

    # See https://github.com/Winetricks/winetricks/issues/1086
    # and https://bugs.winehq.org/show_bug.cgi?id=26925
    if w_workaround_wine_bug 26925 "Forcing quiet install"; then
        w_try "$WINE" msiexec /i msxml3.msi /q
    else
        w_try "$WINE" msiexec /i msxml3.msi $W_UNATTENDED_SLASH_Q
    fi
}

#----------------------------------------------------------------

w_metadata msxml4 dlls \
    title="MS XML Core Services 4.0" \
    publisher="Microsoft" \
    year="2009" \
    media="download" \
    file1="msxml.msi" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/msxml4.dll"

load_msxml4()
{
    # MS06-071: https://www.microsoft.com/en-us/download/details.aspx?id=11125
    # w_download https://download.microsoft.com/download/e/2/e/e2e92e52-210b-4774-8cd9-3a7a0130141d/msxml4-KB927978-enu.exe 7602c2a6d2a46ef2b4028438d2cce67fe437a9bfb569249ea38141b4756b4e03
    # MS07-042: https://www.microsoft.com/en-us/download/details.aspx?id=2386
    # w_download https://download.microsoft.com/download/9/4/2/9422e6b6-08ee-49cb-9f05-6c6ee755389e/msxml4-KB936181-enu.exe 1ce9ff868816cfc9bf33e93fdf1552afce5b491443892babb521e74c05e45242
    # SP3 (2009): https://www.microsoft.com/en-us/download/details.aspx?id=15697
    w_download https://download.microsoft.com/download/A/2/D/A2D8587D-0027-4217-9DAD-38AFDB0A177E/msxml.msi 47c2ae679c37815da9267c81fc3777de900ad2551c11c19c2840938b346d70bb
    w_override_dlls native,builtin msxml4
    w_try_cd "$W_CACHE/$W_PACKAGE"
    w_try "$WINE" msiexec /i msxml.msi $W_UNATTENDED_SLASH_Q
}

#----------------------------------------------------------------

w_metadata msxml6 dlls \
    title="MS XML Core Services 6.0 sp1" \
    publisher="Microsoft" \
    year="2007" \
    media="download" \
    file1="msxml6_x86.msi" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/msxml6.dll"

load_msxml6()
{
    # Service Pack 1
    # https://www.microsoft.com/en-us/download/details.aspx?id=6276
    if [ $W_ARCH = win64 ]; then
        w_download https://download.microsoft.com/download/e/a/f/eafb8ee7-667d-4e30-bb39-4694b5b3006f/msxml6_x64.msi 945d8c535758d5178d4de9063cfcba7dfa96987eaa478e0c03ba646cc7ca772f
    else
        w_download https://download.microsoft.com/download/e/a/f/eafb8ee7-667d-4e30-bb39-4694b5b3006f/msxml6_x86.msi efa48f8cab5a89b8e667ed3e10dfb71bddc02923d0f3757bd93ffabe6fb6c598
    fi
    w_override_dlls native,builtin msxml6
    rm -f "$W_SYSTEM32_DLLS/msxml6.dll"
    if [ $W_ARCH = win64 ]; then
        rm -f "$W_SYSTEM64_DLLS/msxml6.dll"
        w_try_msiexec64 /i "$W_CACHE"/msxml6/msxml6_x64.msi
    else
        w_try "$WINE" msiexec /i "$W_CACHE"/msxml6/msxml6_x86.msi $W_UNATTENDED_SLASH_Q
    fi
}

#----------------------------------------------------------------

w_metadata nuget dlls \
    title="NuGet Package manager" \
    publisher="Outercurve Foundation" \
    year="2013" \
    media="download" \
    file1="nuget.exe" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/nuget.exe" \
    homepage="https://nuget.org"

load_nuget()
{
    w_call dotnet40
    # Changes too rapidly to check shasum
    w_download https://nuget.org/nuget.exe
    w_try cp "$W_CACHE/$W_PACKAGE"/nuget.exe "$W_SYSTEM32_DLLS"
    w_warn "To run NuGet, use the command line \"$WINE nuget\"."
}

#----------------------------------------------------------------

w_metadata ogg dlls \
    title="OpenCodecs 0.85: FLAC, Speex, Theora, Vorbis, WebM" \
    publisher="Xiph.Org Foundation" \
    year="2011" \
    media="download" \
    file1="opencodecs_0.85.17777.exe" \
    installed_file1="$W_PROGRAMS_X86_WIN/Xiph.Org/Open Codecs/AxPlayer.dll" \
    homepage="https://xiph.org/dshow"

load_ogg()
{
    w_download https://downloads.xiph.org/releases/oggdsf/opencodecs_0.85.17777.exe fcec3cea637e806501aff447d902de3b5bfef226b629e43ab67e46dbb23f13e7
    w_try_cd "$W_CACHE/$W_PACKAGE"
    w_try "$WINE" "$file1" $W_UNATTENDED_SLASH_S
}


#----------------------------------------------------------------

w_metadata ole32 dlls \
    title="MS ole32 Module (ole32.dll)" \
    publisher="Microsoft" \
    year="2004" \
    media="download" \
    file1="../winxpsp3/WindowsXP-KB936929-SP3-x86-ENU.exe" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/ole32.dll"

load_ole32()
{
    # Some applications need this, for example Wechat.
    helper_winxpsp3 i386/ole32.dl_
    w_try_cabextract --directory="$W_SYSTEM32_DLLS" "$W_TMP"/i386/ole32.dl_
    w_override_dlls native,builtin ole32
}

#----------------------------------------------------------------

w_metadata pdh dlls \
    title="MS pdh.dll (Performance Data Helper)" \
    publisher="Microsoft" \
    year="2011" \
    media="download" \
    file1="../win7sp1/windows6.1-KB976932-X86.exe" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/pdh.dll"

load_pdh()
{
    helper_win7sp1 x86_microsoft-windows-p..rastructureconsumer_31bf3856ad364e35_6.1.7601.17514_none_b5e3f88a8eb425e8/pdh.dll
    w_try cp "$W_TMP/x86_microsoft-windows-p..rastructureconsumer_31bf3856ad364e35_6.1.7601.17514_none_b5e3f88a8eb425e8/pdh.dll" "$W_SYSTEM32_DLLS/pdh.dll"

    if [ "$W_ARCH" = "win64" ]; then
        helper_win7sp1_x64 amd64_microsoft-windows-p..rastructureconsumer_31bf3856ad364e35_6.1.7601.17514_none_1202940e4711971e/pdh.dll
        w_try cp "$W_TMP/amd64_microsoft-windows-p..rastructureconsumer_31bf3856ad364e35_6.1.7601.17514_none_1202940e4711971e/pdh.dll" "$W_SYSTEM64_DLLS/pdh.dll"
    fi

    w_override_dlls native,builtin pdh
}

#----------------------------------------------------------------

w_metadata peverify dlls \
    title="MS peverify (from .NET 2.0 SDK)" \
    publisher="Microsoft" \
    year="2006" \
    media="download" \
    file1="../dotnet20sdk/setup.exe" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/peverify.exe"

load_peverify()
{
    w_download_to dotnet20sdk https://download.microsoft.com/download/c/4/b/c4b15d7d-6f37-4d5a-b9c6-8f07e7d46635/setup.exe 1d7337bfbb2c65f43c82d188688ce152af403bcb67a2cc2a3cc68a580ecd8200

    # Seems to require dotnet20; at least doesn't work if dotnet40 is installed instead
    w_call dotnet20

    w_try_cabextract --directory="${W_TMP}" "${W_CACHE}/dotnet20sdk/setup.exe" -F netfxsd1.cab
    w_try_cabextract --directory="${W_TMP}" "${W_TMP}/netfxsd1.cab" -F FL_PEVerify_exe_____X86.3643236F_FC70_11D3_A536_0090278A1BB8
    w_try mv "${W_TMP}/FL_PEVerify_exe_____X86.3643236F_FC70_11D3_A536_0090278A1BB8" "${W_SYSTEM32_DLLS}/peverify.exe"
}

#----------------------------------------------------------------

w_metadata physx dlls \
    title="PhysX" \
    publisher="Nvidia" \
    year="2014" \
    media="download" \
    file1="PhysX-9.14.0702-SystemSoftware.msi" \
    installed_file1="$W_PROGRAMS_WIN/NVIDIA Corporation/PhysX/Engine/v2.8.3/PhysXCore.dll"

load_physx()
{
    w_download https://uk.download.nvidia.com/Windows/9.14.0702/PhysX-9.14.0702-SystemSoftware.msi 0a022e28accf5851be9d6577487cdcd3d3a3e2a8a21a64456b72b415c217f03c
    w_try_cd "$W_CACHE/$W_PACKAGE"
    w_try "$WINE" msiexec /i PhysX-9.14.0702-SystemSoftware.msi $W_UNATTENDED_SLASH_Q
}

#----------------------------------------------------------------

w_metadata pngfilt dlls \
    title="pngfilt.dll (from winxp)" \
    publisher="Microsoft" \
    year="2004" \
    media="download" \
    file1="../winxpsp3/WindowsXP-KB936929-SP3-x86-ENU.exe" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/pngfilt.dll"

load_pngfilt()
{
    # Previously used https://www.microsoft.com/en-us/download/details.aspx?id=3907
    # Now using winxp's dll

    helper_winxpsp3 i386/pngfilt.dl_
    w_try_cabextract --directory="$W_SYSTEM32_DLLS" "$W_TMP"/i386/pngfilt.dl_
    w_try_regsvr pngfilt.dll
}

#----------------------------------------------------------------

w_metadata python26 dlls \
    title="Python interpreter 2.6.2" \
    publisher="Python Software Foundaton" \
    year="2009" \
    media="download" \
    file1="python-2.6.2.msi" \
    installed_exe1="c:/Python26/python.exe"

load_python26()
{
    w_download https://www.python.org/ftp/python/2.6.2/python-2.6.2.msi c2276b398864b822c25a7c240cb12ddb178962afd2e12d602f1a961e31ad52ff
    w_download $WINETRICKS_SOURCEFORGE/project/pywin32/pywin32/Build%20214/pywin32-214.win32-py2.6.exe dc311bbdc5868e3dd139dfc46136221b7f55c5613a98a5a48fa725a6c681cd40

    w_try_cd "$W_CACHE/$W_PACKAGE"
    w_try "$WINE" msiexec /i python-2.6.2.msi ALLUSERS=1 $W_UNATTENDED_SLASH_Q

    w_ahk_do "
        SetTitleMatchMode, 2
        run pywin32-214.win32-py2.6.exe
        WinWait, Setup, Wizard will install pywin32
        if ( w_opt_unattended > 0 ) {
             ControlClick Button2   ; next
             WinWait, Setup, Python 2.6 is required
             ControlClick Button3   ; next
             WinWait, Setup, Click Next to begin
             ControlClick Button3   ; next
             WinWait, Setup, finished
             ControlClick Button4   ; Finish
        }
        WinWaitClose
        "
}

#----------------------------------------------------------------

w_metadata qasf dlls \
    title="qasf.dll" \
    publisher="Microsoft" \
    year="2011" \
    media="download" \
    file1="../win7sp1/windows6.1-KB976932-X86.exe" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/qasf.dll"

load_qasf()
{
    helper_win7sp1 x86_microsoft-windows-directshow-asf_31bf3856ad364e35_6.1.7601.17514_none_1cc4e9c15ccc8ae8/qasf.dll
    w_try cp "$W_TMP/x86_microsoft-windows-directshow-asf_31bf3856ad364e35_6.1.7601.17514_none_1cc4e9c15ccc8ae8/qasf.dll" "$W_SYSTEM32_DLLS/qasf.dll"

    w_override_dlls native,builtin qasf
    w_try_regsvr qasf.dll

    if [ "$W_ARCH" = "win64" ]; then
        helper_win7sp1_x64 amd64_microsoft-windows-directshow-asf_31bf3856ad364e35_6.1.7601.17514_none_78e385451529fc1e/qasf.dll
        w_try cp "$W_TMP/amd64_microsoft-windows-directshow-asf_31bf3856ad364e35_6.1.7601.17514_none_78e385451529fc1e/qasf.dll" "$W_SYSTEM64_DLLS/qasf.dll"
        w_try_regsvr64 qasf.dll
    fi
}

#----------------------------------------------------------------

w_metadata qcap dlls \
    title="qcap.dll" \
    publisher="Microsoft" \
    year="2011" \
    media="download" \
    file1="../win7sp1/windows6.1-KB976932-X86.exe" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/qcap.dll"

load_qcap()
{
    helper_win7sp1 x86_microsoft-windows-directshow-capture_31bf3856ad364e35_6.1.7601.17514_none_bae08d1e7dcccf2a/qcap.dll
    w_try cp "$W_TMP/x86_microsoft-windows-directshow-capture_31bf3856ad364e35_6.1.7601.17514_none_bae08d1e7dcccf2a/qcap.dll" "$W_SYSTEM32_DLLS/qcap.dll"
    w_override_dlls native,builtin qcap
    w_try_regsvr qcap.dll

    if [ "$W_ARCH" = "win64" ]; then
        helper_win7sp1_x64 amd64_microsoft-windows-directshow-capture_31bf3856ad364e35_6.1.7601.17514_none_16ff28a2362a4060/qcap.dll
        w_try cp "$W_TMP/amd64_microsoft-windows-directshow-capture_31bf3856ad364e35_6.1.7601.17514_none_16ff28a2362a4060/qcap.dll" "$W_SYSTEM64_DLLS/qcap.dll"
        w_try_regsvr64 qcap.dll
    fi
}

#----------------------------------------------------------------

w_metadata qdvd dlls \
    title="qdvd.dll" \
    publisher="Microsoft" \
    year="2011" \
    media="download" \
    file1="../win7sp1/windows6.1-KB976932-X86.exe" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/qdvd.dll"

load_qdvd()
{
    helper_win7sp1 x86_microsoft-windows-directshow-dvdsupport_31bf3856ad364e35_6.1.7601.17514_none_562994bd321aac67/qdvd.dll
    w_try cp "$W_TMP/x86_microsoft-windows-directshow-dvdsupport_31bf3856ad364e35_6.1.7601.17514_none_562994bd321aac67/qdvd.dll" "$W_SYSTEM32_DLLS/qdvd.dll"

    if [ "$W_ARCH" = "win64" ]; then
        helper_win7sp1_x64 amd64_microsoft-windows-directshow-dvdsupport_31bf3856ad364e35_6.1.7601.17514_none_b2483040ea781d9d/qdvd.dll
        w_try cp "$W_TMP/amd64_microsoft-windows-directshow-dvdsupport_31bf3856ad364e35_6.1.7601.17514_none_b2483040ea781d9d/qdvd.dll" "$W_SYSTEM64_DLLS/qdvd.dll"
    fi

    w_override_dlls native,builtin qdvd
}

#----------------------------------------------------------------

w_metadata qedit dlls \
    title="qedit.dll" \
    publisher="Microsoft" \
    year="2011" \
    media="download" \
    file1="../win7sp1/windows6.1-KB976932-X86.exe" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/qedit.dll"

load_qedit()
{
    helper_win7sp1 x86_microsoft-windows-qedit_31bf3856ad364e35_6.1.7601.17514_none_5ca34698a5a970d2/qedit.dll
    w_try cp "$W_TMP/x86_microsoft-windows-qedit_31bf3856ad364e35_6.1.7601.17514_none_5ca34698a5a970d2/qedit.dll" "$W_SYSTEM32_DLLS/qedit.dll"
    w_override_dlls native,builtin qedit
    w_try_regsvr qedit.dll

    if [ "$W_ARCH" = "win64" ]; then
        helper_win7sp1_x64 amd64_microsoft-windows-qedit_31bf3856ad364e35_6.1.7601.17514_none_b8c1e21c5e06e208/qedit.dll
        w_try cp "$W_TMP/amd64_microsoft-windows-qedit_31bf3856ad364e35_6.1.7601.17514_none_b8c1e21c5e06e208/qedit.dll" "$W_SYSTEM64_DLLS/qedit.dll"
        w_try_regsvr64 qedit.dll
    fi
}

#----------------------------------------------------------------

w_metadata quartz dlls \
    title="quartz.dll" \
    publisher="Microsoft" \
    year="2011" \
    media="download" \
    file1="../win7sp1/windows6.1-KB976932-X86.exe" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/quartz.dll"

load_quartz()
{
    helper_win7sp1 x86_microsoft-windows-directshow-core_31bf3856ad364e35_6.1.7601.17514_none_a877a1cc4c284497/quartz.dll
    w_try cp "$W_TMP/x86_microsoft-windows-directshow-core_31bf3856ad364e35_6.1.7601.17514_none_a877a1cc4c284497/quartz.dll" "$W_SYSTEM32_DLLS/quartz.dll"
    w_override_dlls native,builtin quartz
    w_try_regsvr quartz.dll

    if [ "$W_ARCH" = "win64" ]; then
        helper_win7sp1_x64 amd64_microsoft-windows-directshow-core_31bf3856ad364e35_6.1.7601.17514_none_04963d500485b5cd/quartz.dll
        w_try cp "$W_TMP/amd64_microsoft-windows-directshow-core_31bf3856ad364e35_6.1.7601.17514_none_04963d500485b5cd/quartz.dll" "$W_SYSTEM64_DLLS/quartz.dll"
        w_try_regsvr64 quartz.dll
    fi
}

#----------------------------------------------------------------

w_metadata quicktime72 dlls \
    title="Apple QuickTime 7.2" \
    publisher="Apple" \
    year="2010" \
    media="download" \
    file1="QuickTimeInstaller.exe" \
    installed_file1="c:/windows/Installer/{95A890AA-B3B1-44B6-9C18-A8F7AB3EE7FC}/QTPlayer.ico"

load_quicktime72()
{
    # https://support.apple.com/kb/DL837
    w_download http://appldnld.apple.com.edgesuite.net/content.info.apple.com/QuickTime/061-2915.20070710.pO94c/QuickTimeInstaller.exe a42b93531910bdf1539cc5ae3199ade5a1ca63fd4ac971df74c345d8e1ee6593

    w_try_cd "$W_CACHE"/"$W_PACKAGE"
    w_try "$WINE" "$file1" ALLUSERS=1 DESKTOP_SHORTCUTS=0 QTTaskRunFlags=0 QTINFO.BISQTPRO=1 SCHEDULE_ASUW=0 REBOOT_REQUIRED=No $W_UNATTENDED_SLASH_QN > /dev/null 2>&1

    if w_workaround_wine_bug 11681; then
        # Following advice verified with test movies from
        # https://support.apple.com/kb/HT1425
        # in QuickTimePlayer.

        case $LANG in
            ru*) w_warn "В настройках Quicktime включите Дополнительно / Безопасный режим (только gdi), иначе видеофайлы не будут воспроизводиться." ;;
            *) w_warn "In Quicktime preferences, check Advanced / Safe Mode (gdi), or movies won't play." ;;
        esac
        if test "$W_UNATTENDED_SLASH_Q" = ""; then
            w_try "$WINE" control "$W_PROGRAMS_WIN\\QuickTime\\QTSystem\\QuickTime.cpl"
        else
            # FIXME: script the control panel with AutoHotKey?
            # We could probably also overwrite QuickTime.qtp but
            # the format isn't known, so we'd have to override all other settings, too.
            :
        fi
    fi
}

#----------------------------------------------------------------

w_metadata quicktime76 dlls \
    title="Apple QuickTime 7.6" \
    publisher="Apple" \
    year="2010" \
    media="download" \
    file1="QuickTimeInstaller.exe" \
    installed_file1="c:/windows/Installer/{57752979-A1C9-4C02-856B-FBB27AC4E02C}/QTPlayer.ico"

load_quicktime76()
{
    # https://support.apple.com/kb/DL837
    w_download http://appldnld.apple.com/QuickTime/041-0025.20101207.Ptrqt/QuickTimeInstaller.exe c2dcda76ed55428e406ad7e6acdc84e804d30752a1380c313394c09bb3e27f56

    w_try_cd "$W_CACHE"/"$W_PACKAGE"
    w_try "$WINE" QuickTimeInstaller.exe ALLUSERS=1 DESKTOP_SHORTCUTS=0 QTTaskRunFlags=0 QTINFO.BISQTPRO=1 SCHEDULE_ASUW=0 REBOOT_REQUIRED=No $W_UNATTENDED_SLASH_QN > /dev/null 2>&1

    if w_workaround_wine_bug 11681; then
        # Following advice verified with test movies from
        # https://support.apple.com/kb/HT1425
        # in QuickTimePlayer.

        case $LANG in
            ru*) w_warn "В настройках Quicktime включите Дополнительно / Безопасный режим (только gdi), иначе видеофайлы не будут воспроизводиться." ;;
            *) w_warn "In Quicktime preferences, check Advanced / Safe Mode (gdi), or movies won't play." ;;
        esac
        if test "$W_UNATTENDED_SLASH_Q" = ""; then
            w_try "$WINE" control "$W_PROGRAMS_WIN\\QuickTime\\QTSystem\\QuickTime.cpl"
        else
            # FIXME: script the control panel with AutoHotKey?
            # We could probably also overwrite QuickTime.qtp but
            # the format isn't known, so we'd have to override all other settings, too.
            :
        fi
    fi
}

#----------------------------------------------------------------

w_metadata riched20 dlls \
    title="MS RichEdit Control 2.0 (riched20.dll)" \
    publisher="Microsoft" \
    year="2004" \
    media="download" \
    file1="../win2ksp4/W2KSP4_EN.EXE" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/riched20.dll"

load_riched20()
{
    # FIXME: this verb used to also install riched32.  Does anyone need that?
    helper_win2ksp4 i386/riched20.dl_
    w_try_cabextract --directory="$W_SYSTEM32_DLLS" "$W_TMP"/i386/riched20.dl_
    w_override_dlls native,builtin riched20

    # https://github.com/Winetricks/winetricks/issues/292
    w_call msls31
}

#----------------------------------------------------------------

# Problem - riched20 and riched30 both install riched20.dll!
# We may need a better way to distinguish between installed files.

w_metadata riched30 dlls \
    title="MS RichEdit Control 3.0 (riched20.dll, msls31.dll)" \
    publisher="Microsoft" \
    year="2001" \
    media="download" \
    file1="InstMsiA.exe" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/riched20.dll" \
    installed_file2="$W_SYSTEM32_DLLS_WIN/msls31.dll"

load_riched30()
{
    # http://www.novell.com/documentation/nm1/readmeen_web/readmeen_web.html#Akx3j64
    # claims that Groupwise Messenger's View / Text Size command
    # only works with riched30, and recommends getting it by installing
    # msi 2, which just happens to come with riched30 version of riched20
    # (though not with a corresponding riched32, which might be a problem)

    # https://www.microsoft.com/en-us/download/details.aspx?id=21990
    # Originally at https://download.microsoft.com/download/WindowsInstaller/Install/2.0/W9XMe/EN-US/InstMsiA.exe
    # with sha256sum 536e4c8385d7d250fd5702a6868d1ed004692136eefad22252d0dac15f02563a
    # Mirror list at http://www.filewatcher.com/m/InstMsiA.Exe.1707856-0.html
    # But they all have a different sha256sum, 5ab8b82f578f09dbccf797754155e531b5996b532c1f19c531596ec07cc4b46d
    w_download http://ftp.tw.vim.org/cpatch/msupdate/msi/source/instmsia.exe 5ab8b82f578f09dbccf797754155e531b5996b532c1f19c531596ec07cc4b46d InstMsiA.exe

    w_try_cabextract --directory="$W_TMP" "$W_CACHE"/riched30/InstMsiA.exe
    w_try cp -f "$W_TMP"/riched20.dll "$W_SYSTEM32_DLLS"
    w_try cp -f "$W_TMP"/msls31.dll "$W_SYSTEM32_DLLS"
    w_override_dlls native,builtin riched20
}

#----------------------------------------------------------------

w_metadata richtx32 dlls \
    title="MS Rich TextBox Control 6.0" \
    publisher="Microsoft" \
    year="2012" \
    media="download" \
    file1="../vb6sp6/VB60SP6-KB2708437-x86-ENU.msi" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/richtx32.ocx"

load_richtx32()
{
    helper_vb6sp6 "$W_SYSTEM32_DLLS" richtx32.ocx
    w_try_regsvr richtx32.ocx
}

#----------------------------------------------------------------

w_metadata sdl dlls \
    title="Simple DirectMedia Layer" \
    publisher="Sam Lantinga" \
    year="2009" \
    media="download" \
    file1="SDL-1.2.14-win32.zip" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/SDL.dll"

load_sdl()
{
    # https://www.libsdl.org/download-1.2.php
    w_download https://www.libsdl.org/release/SDL-1.2.14-win32.zip ce77838902891bf2e4378d4a910afef88aaaae4f833a49cfc9bb8dde11ff89a7
    w_try_unzip "$W_SYSTEM32_DLLS" "$W_CACHE"/sdl/SDL-1.2.14-win32.zip SDL.dll
}

#----------------------------------------------------------------

w_metadata secur32 dlls \
    title="MS Security Support Provider Interface" \
    publisher="Microsoft" \
    year="2011" \
    media="download" \
    file1="../win7sp1/windows6.1-KB976932-X86.exe" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/secur32.dll"

load_secur32()
{
    w_warn "Installing native secur32 may lead to stack overflow crashes, see https://bugs.winehq.org/show_bug.cgi?id=45344"

    helper_win7sp1 x86_microsoft-windows-lsa_31bf3856ad364e35_6.1.7601.17514_none_a851f4adbb0d5141/secur32.dll
    w_try cp "$W_TMP/x86_microsoft-windows-lsa_31bf3856ad364e35_6.1.7601.17514_none_a851f4adbb0d5141/secur32.dll" "$W_SYSTEM32_DLLS/secur32.dll"

    if [ "$W_ARCH" = "win64" ]; then
        helper_win7sp1_x64 amd64_microsoft-windows-lsa_31bf3856ad364e35_6.1.7601.17514_none_04709031736ac277/secur32.dll
        w_try cp "$W_TMP/amd64_microsoft-windows-lsa_31bf3856ad364e35_6.1.7601.17514_none_04709031736ac277/secur32.dll" "$W_SYSTEM64_DLLS/secur32.dll"
    fi

    w_override_dlls native,builtin secur32
}

#----------------------------------------------------------------

w_metadata setupapi dlls \
    title="MS Setup API" \
    publisher="Microsoft" \
    year="2004" \
    media="download" \
    file1="../winxpsp3/WindowsXP-KB936929-SP3-x86-ENU.exe" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/setupapi.dll"

load_setupapi()
{
    helper_winxpsp3 i386/setupapi.dl_
    w_try_cabextract --directory="$W_SYSTEM32_DLLS" "$W_TMP"/i386/setupapi.dl_

    w_override_dlls native,builtin setupapi
}

#----------------------------------------------------------------

w_metadata shockwave dlls \
    title="Shockwave" \
    publisher="Adobe" \
    year="2018" \
    media="download" \
    file1="sw_lic_full_installer.msi" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/Adobe/Shockwave 12/shockwave_Projector_Loader.dcr"

load_shockwave() {
    # 2017/03/12: 39715a84b1d85347066fbf89a3af9f5e612b59402093b055cd423bd30a7f637d
    # 2017/03/15: 58f2152bf726d52f08fb41f904c62ff00fdf748c8ce413e8c8547da3a21922ba
    # 2017/08/03: bebebaef1644a994179a2e491ce3f55599d768f7c6019729f21e7029b1845b9c
    # 2017/12/12: 0a9813ac55a8718440518dc2f5f410a3a065b422fe0618c073bfc631b9abf12c
    # 2018/03/16: 4d7b408cf5b65a522b071d7d9ddbc5f6964911a7d55c418e31f393e6055cf796
    # 2018/05/24: 2b03fa11ff6f31b3fef9313264f0ef356ee11d5bc3642c30a2482b4ac5dd0084
    # 2018/06/14: a37f6c47b74fa3c96906e01b9b41d63c08d212fa3e357e354db1b5a93eb92c2f
    # 2019/04/02: 8e414c1a218157d2b83877fb0b6a5002c2e9bff4dc2a3095bae774a13e3e9dbf
    w_download https://fpdownload.macromedia.com/get/shockwave/default/english/win95nt/latest/sw_lic_full_installer.msi 8e414c1a218157d2b83877fb0b6a5002c2e9bff4dc2a3095bae774a13e3e9dbf

    w_try_cd "$W_CACHE/$W_PACKAGE"
    w_try "$WINE" msiexec /i sw_lic_full_installer.msi $W_UNATTENDED_SLASH_Q
}

#----------------------------------------------------------------

w_metadata speechsdk dlls \
    title="MS Speech SDK 5.1" \
    publisher="Microsoft" \
    year="2009" \
    media="download" \
    file1="SpeechSDK51.exe" \
    installed_file1="$W_PROGRAMS_X86_WIN/Microsoft Speech SDK 5.1/Bin/SAPI51SampleApp.exe"

load_speechsdk()
{
    # https://www.microsoft.com/en-us/download/details.aspx?id=10121
    w_download https://download.microsoft.com/download/B/4/3/B4314928-7B71-4336-9DE7-6FA4CF00B7B3/SpeechSDK51.exe 520aa5d1a72dc6f41dc9b8b88603228ffd5d5d6f696224fc237ec4828fe7f6e0

    w_try_unzip "$W_TMP" "$W_CACHE"/speechsdk/SpeechSDK51.exe

    # Otherwise it only installs the SDK and not the redistributable:
    w_set_winver win2k

    # Only added in wine-2.18
    for stub in "$W_SYSTEM32_DLLS/Speech/Common/sapi.dll" "$W_SYSTEM64_DLLS/Speech/Common/sapi.dll"; do
        if [ -f "$stub" ]; then
            w_try rm "$stub"
        fi
    done

    w_try_cd "$W_TMP"
    w_try "$WINE" msiexec /i "Microsoft Speech SDK 5.1.msi" $W_UNATTENDED_SLASH_Q

    # If sapi.dll isn't in original location, applications won't start, see
    # e.g., https://bugs.winehq.org/show_bug.cgi?id=43841
    w_try ln -s "$W_COMMONFILES_X86/Microsoft Shared/Speech/sapi.dll" "$W_32BIT_DLLS/Speech/Common"

    w_override_dlls native sapi

    w_unset_winver
}

#----------------------------------------------------------------

w_metadata tabctl32 dlls \
    title="Microsoft Tabbed Dialog Control 6.0 (tabctl32.ocx)" \
    publisher="Microsoft" \
    year="2012" \
    media="download" \
    file1="../vb6sp6/VB60SP6-KB2708437-x86-ENU.msi" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/tabctl32.ocx"

load_tabctl32()
{
    helper_vb6sp6 "$W_TMP" TabCtl32.ocx
    w_try mv "${W_TMP}/TabCtl32.ocx" "$W_SYSTEM32_DLLS/tabctl32.ocx"
    w_try_regsvr tabctl32.ocx
}

#----------------------------------------------------------------

w_metadata updspapi dlls \
    title="Windows Update Service API" \
    publisher="Microsoft" \
    year="2004" \
    media="download" \
    file1="../winxpsp3/WindowsXP-KB936929-SP3-x86-ENU.exe" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/updspapi.dll"

load_updspapi()
{
    helper_winxpsp3 i386/update/updspapi.dll
    w_try cp -f "$W_TMP"/i386/update/updspapi.dll "$W_SYSTEM32_DLLS"

    w_override_dlls native,builtin updspapi
}

#----------------------------------------------------------------

w_metadata usp10 dlls \
    title="Uniscribe" \
    publisher="Microsoft" \
    year="2011" \
    media="download" \
    file1="../win7sp1/windows6.1-KB976932-X86.exe" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/usp10.dll"

load_usp10()
{
    helper_win7sp1 x86_microsoft-windows-usp_31bf3856ad364e35_6.1.7601.17514_none_af01e2f9b6be7939/usp10.dll
    w_try cp "$W_TMP/x86_microsoft-windows-usp_31bf3856ad364e35_6.1.7601.17514_none_af01e2f9b6be7939/usp10.dll" "$W_SYSTEM32_DLLS/usp10.dll"

    if [ "$W_ARCH" = "win64" ]; then
        helper_win7sp1_x64 amd64_microsoft-windows-usp_31bf3856ad364e35_6.1.7601.17514_none_0b207e7d6f1bea6f/usp10.dll
        w_try cp "$W_TMP/amd64_microsoft-windows-usp_31bf3856ad364e35_6.1.7601.17514_none_0b207e7d6f1bea6f/usp10.dll" "$W_SYSTEM64_DLLS/usp10.dll"
    fi

    w_override_dlls native,builtin usp10
}

#----------------------------------------------------------------

w_metadata vb2run dlls \
    title="MS Visual Basic 2 runtime" \
    publisher="Microsoft" \
    year="1993" \
    media="download" \
    file1="VBRUN200.EXE" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/VBRUN200.DLL"

load_vb2run()
{
    # Not referenced on MS web anymore, but the old Microsoft Software Library FTP still has it.
    # See ftp://ftp.microsoft.com/Softlib/index.txt
    # 2014/05/31: Microsoft FTP is down ftp://$ftp_microsoft_com/Softlib/MSLFILES/VBRUN200.EXE
    # 2015/08/10: chatnfiles is down, conradshome.com is up (and has a LOT of old MS installers archived!)
    # 2018/11/15: now conradshome is down ,but quaddicted.com also has it (and a lot more)
    w_download https://www.quaddicted.com/files/mirrors/ftp.planetquake.com/aoe/downloads/VBRUN200.EXE 4b0811d8fdcac1fd9411786c9119dc8d98d0540948211bdbc1ac682fbe5c0228
    w_try_unzip "$W_TMP" "$W_CACHE"/vb2run/VBRUN200.EXE
    w_try cp -f "$W_TMP/VBRUN200.DLL" "$W_SYSTEM32_DLLS"
}

#----------------------------------------------------------------

w_metadata vb3run dlls \
    title="MS Visual Basic 3 runtime" \
    publisher="Microsoft" \
    year="1998" \
    media="download" \
    file1="vb3run.exe" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/Vbrun300.dll"

load_vb3run()
{
    # See https://support.microsoft.com/kb/196285
    w_download https://download.microsoft.com/download/vb30/utility/1/w9xnt4/en-us/vb3run.exe 3ca3ad6332f83b5c2b86e4758afa400150f07ae66ce8b850d8f9d6bcd47ad4cd
    w_try_unzip "$W_TMP" "$W_CACHE"/vb3run/vb3run.exe
    w_try cp -f "$W_TMP/Vbrun300.dll" "$W_SYSTEM32_DLLS"
}

#----------------------------------------------------------------

w_metadata vb4run dlls \
    title="MS Visual Basic 4 runtime" \
    publisher="Microsoft" \
    year="1998" \
    media="download" \
    file1="vb4run.exe" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/Vb40032.dll"

load_vb4run()
{
    # See https://support.microsoft.com/kb/196286
    w_download https://download.microsoft.com/download/vb40ent/sample27/1/w9xnt4/en-us/vb4run.exe 40931308b5a137f9ce3e9da9b43f4ca6688e18b523687cfea8be6cdffa3153fb
    w_try_unzip "$W_TMP" "$W_CACHE"/vb4run/vb4run.exe
    w_try cp -f "$W_TMP/Vb40032.dll" "$W_SYSTEM32_DLLS"
    w_try cp -f "$W_TMP/Vb40016.dll" "$W_SYSTEM32_DLLS"
}

#----------------------------------------------------------------

w_metadata vb5run dlls \
    title="MS Visual Basic 5 runtime" \
    publisher="Microsoft" \
    year="2001" \
    media="download" \
    file1="msvbvm50.exe" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/msvbvm50.dll"

load_vb5run()
{
    w_download https://download.microsoft.com/download/vb50pro/utility/1/win98/en-us/msvbvm50.exe b5f8ea5b9d8b30822a2be2cdcb89cda99ec0149832659ad81f45360daa6e6965
    w_try_cd "$W_CACHE/$W_PACKAGE"
    w_try "$WINE" msvbvm50.exe $W_UNATTENDED_SLASH_Q
}

#----------------------------------------------------------------

w_metadata vb6run dlls \
    title="MS Visual Basic 6 runtime sp6" \
    publisher="Microsoft" \
    year="2004" \
    media="download" \
    file1="vbrun60sp6.exe" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/MSVBVM60.DLL"

load_vb6run()
{
    # https://support.microsoft.com/kb/290887
    if test ! -f "$W_CACHE"/vb6run/vbrun60sp6.exe; then
        w_download https://download.microsoft.com/download/5/a/d/5ad868a0-8ecd-4bb0-a882-fe53eb7ef348/VB6.0-KB290887-X86.exe 467b5a10c369865f2021d379fc0933cb382146b702bbca4bcb703fc86f4322bb

        w_try "$WINE" "$W_CACHE"/vb6run/VB6.0-KB290887-X86.exe "/T:$W_TMP_WIN" /c $W_UNATTENDED_SLASH_Q
        if test ! -f "$W_TMP"/vbrun60sp6.exe; then
            w_die vbrun60sp6.exe not found
        fi
        w_try mv "$W_TMP"/vbrun60sp6.exe "$W_CACHE"/vb6run
    fi

    # Delete some fake DLLs to ensure that the installer overwrites them.
    rm -f "$W_SYSTEM32_DLLS"/comcat.dll
    rm -f "$W_SYSTEM32_DLLS"/oleaut32.dll
    rm -f "$W_SYSTEM32_DLLS"/olepro32.dll
    rm -f "$W_SYSTEM32_DLLS"/stdole2.tlb

    w_try_cd "$W_CACHE/$W_PACKAGE"
    # Exits with status 43 for some reason?
    "$WINE" vbrun60sp6.exe $W_UNATTENDED_SLASH_Q

    status=$?
    case $status in
        0|43) ;;
        *) w_die "$W_PACKAGE installation failed"
    esac
}

#----------------------------------------------------------------

winetricks_vcrun6_helper() {
    if test ! -f "$W_CACHE"/vcrun6/vcredist.exe; then
        w_download_to vcrun6 https://download.microsoft.com/download/vc60pro/Update/2/W9XNT4/EN-US/VC6RedistSetup_deu.exe c2eb91d9c4448d50e46a32fecbcc3b418706d002beab9b5f4981de552098cee7

        w_try "$WINE" "$W_CACHE"/vcrun6/vc6redistsetup_deu.exe "/T:$W_TMP_WIN" /c $W_UNATTENDED_SLASH_Q
        if test ! -f "$W_TMP"/vcredist.exe; then
            w_die vcredist.exe not found
        fi
        mv "$W_TMP"/vcredist.exe "$W_CACHE"/vcrun6
    fi
}

w_metadata vcrun6 dlls \
    title="Visual C++ 6 SP4 libraries (mfc42, msvcp60, msvcirt)" \
    publisher="Microsoft" \
    year="2000" \
    media="download" \
    file1="vc6redistsetup_deu.exe" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/mfc42.dll"

load_vcrun6()
{
    # Load the Visual C++ 6 runtime libraries, including the elusive mfc42u.dll
    winetricks_vcrun6_helper

    # Delete some fake DLLs to avoid vcredist installer warnings
    rm -f "$W_SYSTEM32_DLLS"/comcat.dll
    rm -f "$W_SYSTEM32_DLLS"/msvcrt.dll
    rm -f "$W_SYSTEM32_DLLS"/oleaut32.dll
    rm -f "$W_SYSTEM32_DLLS"/olepro32.dll
    rm -f "$W_SYSTEM32_DLLS"/stdole2.tlb
    "$WINE" "$W_CACHE"/vcrun6/vcredist.exe

    status=$?
    case $status in
        0|43) ;;
        *) w_die vcrun6 installation failed
    esac

    # And then some apps need mfc42u.dll, dunno what the right way
    # is to get it, vcredist doesn't seem to install it by default?
    load_mfc42
}

w_metadata mfc42 dlls \
    title="Visual C++ 6 SP4 mfc42 library; part of vcrun6" \
    publisher="Microsoft" \
    year="2000" \
    media="download" \
    file1="../vcrun6/vc6redistsetup_deu.exe" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/mfc42u.dll"

load_mfc42()
{
    winetricks_vcrun6_helper

    w_try_cabextract "$W_CACHE"/vcrun6/vcredist.exe -d "$W_SYSTEM32_DLLS" -F "mfc42*.dll"
}

w_metadata msvcirt dlls \
    title="Visual C++ 6 SP4 msvcirt library; part of vcrun6" \
    publisher="Microsoft" \
    year="2000" \
    media="download" \
    file1="../vcrun6/vc6redistsetup_deu.exe" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/msvcirt.dll"

load_msvcirt()
{
    winetricks_vcrun6_helper

    w_try_cabextract "$W_CACHE"/vcrun6/vcredist.exe -d "$W_SYSTEM32_DLLS" -F msvcirt.dll
}

#----------------------------------------------------------------

# FIXME: we don't currently have an install check that can distinguish
# between SP4 and SP6, it would have to check size or version of a file,
# or maybe a registry key.

w_metadata vcrun6sp6 dlls \
    title="Visual C++ 6 SP6 libraries (with fixes in ATL and MFC)" \
    publisher="Microsoft" \
    year="2004" \
    media="download" \
    file1="Vs6sp6.exe" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/mfc42.dll"

load_vcrun6sp6()
{
    w_download https://download.microsoft.com/download/1/9/f/19fe4660-5792-4683-99e0-8d48c22eed74/Vs6sp6.exe 7fa1d1778824b55a5fceb02f45c399b5d4e4dce7403661e67e587b5f455edbf3

    # No EULA is presented when passing command-line extraction arguments,
    # so we'll simplify extraction with cabextract.
    w_try_cabextract "$W_CACHE"/vcrun6sp6/Vs6sp6.exe -d "$W_TMP" -F vcredist.exe
    w_try_cd "$W_TMP"

    # Delete some fake DLLs to avoid vcredist installer warnings
    w_try rm -f "$W_SYSTEM32_DLLS"/comcat.dll
    w_try rm -f "$W_SYSTEM32_DLLS"/msvcrt.dll
    w_try rm -f "$W_SYSTEM32_DLLS"/oleaut32.dll
    w_try rm -f "$W_SYSTEM32_DLLS"/olepro32.dll
    w_try rm -f "$W_SYSTEM32_DLLS"/stdole2.tlb
    # vcredist still exits with status 43.  Anyone know why?
    "$WINE" vcredist.exe

    status=$?
    case $status in
        0|43) ;;
        *) w_die "$W_PACKAGE installation failed"
    esac

    # And then some apps need mfc42u.dll, dont know what right way
    # is to get it, vcredist doesn't install it by default?
    w_try_cabextract vcredist.exe -d "$W_SYSTEM32_DLLS" -F mfc42u.dll
    # Should the mfc42 verb install this one instead?
}

#----------------------------------------------------------------

w_metadata vcrun2003 dlls \
    title="Visual C++ 2003 libraries (mfc71,msvcp71,msvcr71)" \
    publisher="Microsoft" \
    year="2003" \
    media="download" \
    file1="BZEditW32_1.6.5.exe" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/msvcp71.dll"

load_vcrun2003()
{
    # Load the Visual C++ 2003 runtime libraries
    # Sadly, I know of no Microsoft URL for these
    echo "Installing BZFlag (which comes with the Visual C++ 2003 runtimes)"
    # winetricks-test can't handle ${file1} in url since it does a raw parsing :/
    w_download https://sourceforge.net/projects/bzflag/files/bzedit%20win32/1.6.5/BZEditW32_1.6.5.exe 84d1bda5dbf814742898a2e1c0e4bc793e9bc1fba4b7a93d59a7ef12bd0fd802
    w_try "$WINE" "$W_CACHE/vcrun2003/${file1}" $W_UNATTENDED_SLASH_S
    w_try cp "$W_PROGRAMS_X86_UNIX/BZEdit1.6.5"/m*71* "$W_SYSTEM32_DLLS"
}

#----------------------------------------------------------------

# Temporary fix for bug 169
# The | symbol in installed_file1 means "or".
# (Adding an installed_file2 would mean 'and'.)
# Perhaps we should test for one if winxp mode, and the other if win7 mode;
# if that becomes important to get right, we'll do something like
# "if installed_file1 is just the single char @, call test_installed_$verb"
# and then define that function here.
w_metadata vcrun2005 dlls \
    title="Visual C++ 2005 libraries (mfc80,msvcp80,msvcr80)" \
    publisher="Microsoft" \
    year="2011" \
    media="download" \
    file1="vcredist_x86.EXE" \
    installed_file1="c:/windows/winsxs/x86_Microsoft.VC80.MFC_1fc8b3b9a1e18e3b_8.0.50727.6195_x-ww_150c9e8b/mfc80.dll|c:/windows/winsxs/x86_microsoft.vc80.mfc_1fc8b3b9a1e18e3b_8.0.50727.6195_none_deadbeef/mfc80.dll"

load_vcrun2005()
{
    # 2011/06: Security update, see
    # https://technet.microsoft.com/library/security/ms11-025 or
    # https://support.microsoft.com/kb/2538242
    w_download https://download.microsoft.com/download/8/B/4/8B42259F-5D70-43F4-AC2E-4B208FD8D66A/vcredist_x86.EXE 4ee4da0fe62d5fa1b5e80c6e6d88a4a2f8b3b140c35da51053d0d7b72a381d29

    # For native to be used, msvc* dlls must either be set to native only, OR
    # set to native, builtin and remove wine's builtin manifest. Setting to native only breaks several apps,
    # e.g., Dirac Codec and Ragnarok Online.
    # For more info, see:
    # https://bugs.winehq.org/show_bug.cgi?id=28225
    # https://bugs.winehq.org/show_bug.cgi?id=33604
    # https://bugs.winehq.org/show_bug.cgi?id=42859
    w_override_dlls native,builtin atl80 msvcm80 msvcp80 msvcr80 vcomp

    w_try_cd "$W_CACHE/$W_PACKAGE"
    w_try "$WINE" "$file1" $W_UNATTENDED_SLASH_Q

    if [ $W_ARCH = win64 ] ;then
        w_download https://download.microsoft.com/download/9/1/4/914851c6-9141-443b-bdb4-8bad3a57bea9/vcredist_x64.exe bb9e8606e26c2b76984252182f7db0d6e9108b204b81d2a7b036c9b618c1f9f1

        if w_workaround_wine_bug 30713 "Manually extracting the 64-bit dlls"; then
            rm -f "$W_TMP"/*  # Avoid permission error
            w_try_cabextract --directory="$W_TMP" vcredist_x64.exe
            w_try_cabextract --directory="$W_TMP" "$W_TMP/VCREDI~2.EXE"
            w_try_cabextract --directory="$W_TMP" "$W_TMP/vcredist.msi"

            w_try cp "$W_TMP/ATL80.dll.837BF1EB_D770_94EB_FF1F_C8B3B9A1E18E" "$W_SYSTEM64_DLLS/atl80.dll"
            w_try cp "$W_TMP/mfc80.dll.8731EA9C_B0D8_8F16_FF1F_C8B3B9A1E18E" "$W_SYSTEM64_DLLS/mfc80.dll"
            w_try cp "$W_TMP/mfc80u.dll.8731EA9C_B0D8_8F16_FF1F_C8B3B9A1E18E" "$W_SYSTEM64_DLLS/mfc80u.dll"
            w_try cp "$W_TMP/mfcm80.dll.8731EA9C_B0D8_8F16_FF1F_C8B3B9A1E18E" "$W_SYSTEM64_DLLS/mfcm80.dll"
            w_try cp "$W_TMP/mfcm80u.dll.8731EA9C_B0D8_8F16_FF1F_C8B3B9A1E18E" "$W_SYSTEM64_DLLS/mfcm80u.dll"

            w_try cp "$W_TMP/msvcm80.dll.844EFBA7_1C24_93B2_FF1F_C8B3B9A1E18E" "$W_SYSTEM64_DLLS/msvcm80.dll"
            w_try cp "$W_TMP/msvcp80.dll.844EFBA7_1C24_93B2_FF1F_C8B3B9A1E18E" "$W_SYSTEM64_DLLS/msvcp80.dll"
            w_try cp "$W_TMP/msvcr80.dll.844EFBA7_1C24_93B2_FF1F_C8B3B9A1E18E" "$W_SYSTEM64_DLLS/msvcr80.dll"
            w_try cp "$W_TMP/vcomp.dll.09D44781_D142_FE32_FF1F_C8B3B9A1E18E" "$W_SYSTEM64_DLLS/vcomp80.dll"
        else
            w_try "$WINE" vcredist_x64.exe $W_UNATTENDED_SLASH_Q
        fi
    fi
}

#----------------------------------------------------------------

w_metadata vcrun2008 dlls \
    title="Visual C++ 2008 libraries (mfc90,msvcp90,msvcr90)" \
    publisher="Microsoft" \
    year="2011" \
    media="download" \
    file1="vcredist_x86.exe" \
    installed_file1="$W_PROGRAMS_X86_WIN/Common Files/Microsoft Shared/VC/msdia90.dll"

load_vcrun2008()
{
    # June 2011 security update, see
    # https://technet.microsoft.com/library/security/ms11-025 or
    # https://support.microsoft.com/kb/2538242
    w_download https://download.microsoft.com/download/5/D/8/5D8C65CB-C849-4025-8E95-C3966CAFD8AE/vcredist_x86.exe 6b3e4c51c6c0e5f68c8a72b497445af3dbf976394cbb62aa23569065c28deeb6

    # For native to be used, msvc* dlls must either be set to native only, OR
    # set to native, builtin and remove wine's builtin manifest. Setting to native only breaks several apps,
    # e.g., Dirac Codec and Ragnarok Online.
    # For more info, see:
    # https://bugs.winehq.org/show_bug.cgi?id=28225
    # https://bugs.winehq.org/show_bug.cgi?id=33604
    # https://bugs.winehq.org/show_bug.cgi?id=42859
    # https://bugs.winehq.org/show_bug.cgi?id=28225
    # https://bugs.winehq.org/show_bug.cgi?id=33604
    # https://bugs.winehq.org/show_bug.cgi?id=42859
    w_override_dlls native,builtin atl90 msvcm90 msvcp90 msvcr90 vcomp90

    w_try_cd "$W_CACHE/$W_PACKAGE"
    w_try "$WINE" "$file1" $W_UNATTENDED_SLASH_Q

    case "$W_ARCH" in
        win64)
            # Also install the 64-bit version
            # 2016/11/15: b811f2c047a3e828517c234bd4aa4883e1ec591d88fad21289ae68a6915a6665
            w_download https://download.microsoft.com/download/5/D/8/5D8C65CB-C849-4025-8E95-C3966CAFD8AE/vcredist_x64.exe b811f2c047a3e828517c234bd4aa4883e1ec591d88fad21289ae68a6915a6665
            if w_workaround_wine_bug 30713 "Manually extracting the 64-bit dlls"; then
                rm -f "$W_TMP"/*  # Avoid permission error
                w_try_cabextract --directory="$W_TMP" vcredist_x64.exe
                w_try_cabextract --directory="$W_TMP" "$W_TMP/vc_red.cab"

                w_try cp "$W_TMP"/atl90.dll.30729.6161.Microsoft_VC90_ATL_x64.QFE "$W_SYSTEM64_DLLS"/atl90.dll
                w_try cp "$W_TMP"/mfc90.dll.30729.6161.Microsoft_VC90_MFC_x64.QFE "$W_SYSTEM64_DLLS"/mfc90.dll
                w_try cp "$W_TMP"/mfcm90.dll.30729.6161.Microsoft_VC90_MFC_x64.QFE "$W_SYSTEM64_DLLS"/mfcm90.dll
                w_try cp "$W_TMP"/msvcm90.dll.30729.6161.Microsoft_VC90_CRT_x64.QFE "$W_SYSTEM64_DLLS"/msvcm90.dll
                w_try cp "$W_TMP"/msvcp90.dll.30729.6161.Microsoft_VC90_CRT_x64.QFE "$W_SYSTEM64_DLLS"/msvcp90.dll
                w_try cp "$W_TMP"/msvcr90.dll.30729.6161.Microsoft_VC90_CRT_x64.QFE "$W_SYSTEM64_DLLS"/msvcr90.dll
                w_try cp "$W_TMP"/vcomp90.dll.30729.6161.Microsoft_VC90_OpenMP_x64.QFE "$W_SYSTEM64_DLLS"/vcomp90.dll
            else
                w_try "$WINE" vcredist_x64.exe $W_UNATTENDED_SLASH_Q
            fi
            ;;
    esac
}

#----------------------------------------------------------------

w_metadata vcrun2010 dlls \
    title="Visual C++ 2010 libraries (mfc100,msvcp100,msvcr100)" \
    publisher="Microsoft" \
    year="2010" \
    media="download" \
    file1="vcredist_x86.exe" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/mfc100.dll"

load_vcrun2010()
{
    # See https://www.microsoft.com/en-us/download/details.aspx?id=5555
    w_download https://download.microsoft.com/download/5/B/C/5BC5DBB3-652D-4DCE-B14A-475AB85EEF6E/vcredist_x86.exe 8162b2d665ca52884507ede19549e99939ce4ea4a638c537fa653539819138c8

    w_override_dlls native,builtin msvcp100 msvcr100 vcomp100 atl100
    w_try_cd "$W_CACHE/$W_PACKAGE"
    w_try "$WINE" vcredist_x86.exe $W_UNATTENDED_SLASH_Q

    case "$W_ARCH" in
        win64)
            # Also install the 64-bit version
            # https://www.microsoft.com/en-us/download/details.aspx?id=13523
            w_download https://download.microsoft.com/download/A/8/0/A80747C3-41BD-45DF-B505-E9710D2744E0/vcredist_x64.exe c6cd2d3f0b11dc2a604ffdc4dd97861a83b77e21709ba71b962a47759c93f4c8
            if w_workaround_wine_bug 30713 "Manually extracting the 64-bit dlls"; then
                w_try_cabextract --directory="$W_TMP" vcredist_x64.exe -F '*.cab'
                w_try_cabextract --directory="$W_TMP" "$W_TMP"/vc_red.cab
                cp "$W_TMP"/F_CENTRAL_mfc100_x64 "$W_SYSTEM64_DLLS"/mfc100.dll
                cp "$W_TMP"/F_CENTRAL_mfc100u_x64 "$W_SYSTEM64_DLLS"/mfc100u.dll
                cp "$W_TMP"/F_CENTRAL_msvcr100_x64 "$W_SYSTEM64_DLLS"/msvcr100.dll
                cp "$W_TMP"/F_CENTRAL_msvcp100_x64 "$W_SYSTEM64_DLLS"/msvcp100.dll
                cp "$W_TMP"/F_CENTRAL_vcomp100_x64 "$W_SYSTEM64_DLLS"/vcomp100.dll
                cp "$W_TMP"/F_CENTRAL_atl100_x64 "$W_SYSTEM64_DLLS"/atl100.dll
            else
                w_try "$WINE" vcredist_x64.exe $W_UNATTENDED_SLASH_Q
            fi
            ;;
    esac
}

#----------------------------------------------------------------

w_metadata vcrun2012 dlls \
    title="Visual C++ 2012 libraries (atl110,mfc110,mfc110u,msvcp110,msvcr110,vcomp110)" \
    publisher="Microsoft" \
    year="2012" \
    media="download" \
    file1="vcredist_x86.exe" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/mfc110.dll"

load_vcrun2012()
{
    # https://www.microsoft.com/en-us/download/details.aspx?id=30679
    w_download https://download.microsoft.com/download/1/6/B/16B06F60-3B20-4FF2-B699-5E9B7962F9AE/VSU_4/vcredist_x86.exe b924ad8062eaf4e70437c8be50fa612162795ff0839479546ce907ffa8d6e386

    w_override_dlls native,builtin atl110 msvcp110 msvcr110 vcomp110
    w_try_cd "$W_CACHE"/"$W_PACKAGE"
    w_try "$WINE" vcredist_x86.exe $W_UNATTENDED_SLASH_Q

    case "$W_ARCH" in
        win64)
            # Also install the 64-bit version
            # 2015/10/19: 681be3e5ba9fd3da02c09d7e565adfa078640ed66a0d58583efad2c1e3cc4064
            w_download https://download.microsoft.com/download/1/6/B/16B06F60-3B20-4FF2-B699-5E9B7962F9AE/VSU_4/vcredist_x64.exe 681be3e5ba9fd3da02c09d7e565adfa078640ed66a0d58583efad2c1e3cc4064
            if w_workaround_wine_bug 30713 "Manually extracting the 64-bit dlls"; then
                rm -f "$W_TMP"/*  # Avoid permission error
                w_try_cabextract --directory="$W_TMP" vcredist_x64.exe
                w_try_cabextract --directory="$W_TMP" "$W_TMP/a2"
                w_try_cabextract --directory="$W_TMP" "$W_TMP/a3"
                cp "$W_TMP"/F_CENTRAL_atl110_x64 "$W_SYSTEM64_DLLS"/atl110.dll
                cp "$W_TMP"/F_CENTRAL_mfc110_x64 "$W_SYSTEM64_DLLS"/mfc110.dll
                cp "$W_TMP"/F_CENTRAL_mfc110u_x64 "$W_SYSTEM64_DLLS"/mfc110u.dll
                cp "$W_TMP"/F_CENTRAL_msvcp110_x64 "$W_SYSTEM64_DLLS"/msvcp110.dll
                cp "$W_TMP"/F_CENTRAL_msvcr110_x64 "$W_SYSTEM64_DLLS"/msvcr110.dll
                cp "$W_TMP"/F_CENTRAL_vcomp110_x64 "$W_SYSTEM64_DLLS"/vcomp110.dll
            else
                w_try "$WINE" vcredist_x64.exe $W_UNATTENDED_SLASH_Q
            fi
            ;;
    esac
}

#----------------------------------------------------------------

w_metadata vcrun2013 dlls \
    title="Visual C++ 2013 libraries (mfc120,mfc120u,msvcp120,msvcr120,vcomp120)" \
    publisher="Microsoft" \
    year="2013" \
    media="download" \
    file1="vcredist_x86.exe" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/mfc120.dll"

load_vcrun2013()
{
    # https://support.microsoft.com/en-gb/help/3179560/update-for-visual-c-2013-and-visual-c-redistributable-package
    # 2015/01/14: a22895e55b26202eae166838edbe2ea6aad00d7ea600c11f8a31ede5cbce2048
    # 2019/03/24: 89f4e593ea5541d1c53f983923124f9fd061a1c0c967339109e375c661573c17
    w_download https://download.microsoft.com/download/0/5/6/056dcda9-d667-4e27-8001-8a0c6971d6b1/vcredist_x86.exe 89f4e593ea5541d1c53f983923124f9fd061a1c0c967339109e375c661573c17

    w_override_dlls native,builtin atl120 msvcp120 msvcr120 vcomp120
    w_try_cd "$W_CACHE"/"$W_PACKAGE"
    w_try "$WINE" vcredist_x86.exe $W_UNATTENDED_SLASH_Q

    case "$W_ARCH" in
        win64)
            # Also install the 64-bit version
            # 2015/10/19: e554425243e3e8ca1cd5fe550db41e6fa58a007c74fad400274b128452f38fb8
            # 2019/03/24: 20e2645b7cd5873b1fa3462b99a665ac8d6e14aae83ded9d875fea35ffdd7d7e
            w_download https://download.microsoft.com/download/0/5/6/056dcda9-d667-4e27-8001-8a0c6971d6b1/vcredist_x64.exe 20e2645b7cd5873b1fa3462b99a665ac8d6e14aae83ded9d875fea35ffdd7d7e
            if w_workaround_wine_bug 30713 "Manually extracting the 64-bit dlls"; then
                rm -f "$W_TMP"/*  # Avoid permission error
                w_try_cabextract --directory="$W_TMP" vcredist_x64.exe
                w_try_cabextract --directory="$W_TMP" "$W_TMP/a2"
                w_try_cabextract --directory="$W_TMP" "$W_TMP/a3"
                cp "$W_TMP"/F_CENTRAL_mfc120_x64 "$W_SYSTEM64_DLLS"/mfc120.dll
                cp "$W_TMP"/F_CENTRAL_mfc120u_x64 "$W_SYSTEM64_DLLS"/mfc120u.dll
                cp "$W_TMP"/F_CENTRAL_msvcp120_x64 "$W_SYSTEM64_DLLS"/msvcp120.dll
                cp "$W_TMP"/F_CENTRAL_msvcr120_x64 "$W_SYSTEM64_DLLS"/msvcr120.dll
                cp "$W_TMP"/F_CENTRAL_vcomp120_x64 "$W_SYSTEM64_DLLS"/vcomp120.dll
            else
                w_try "$WINE" vcredist_x64.exe $W_UNATTENDED_SLASH_Q
            fi
            ;;
    esac
}

#----------------------------------------------------------------

w_metadata vcrun2015 dlls \
    title="Visual C++ 2015 libraries (concrt140.dll,mfc140.dll,mfc140u.dll,mfcm140.dll,mfcm140u.dll,msvcp140.dll,vcamp140.dll,vccorlib140.dll,vcomp140.dll,vcruntime140.dll)" \
    publisher="Microsoft" \
    year="2015" \
    media="download" \
    conflicts="vcrun2017" \
    file1="vc_redist.x86.exe" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/mfc140.dll"

load_vcrun2015()
{
    # https://www.microsoft.com/en-us/download/details.aspx?id=48145
    # 2015/10/12: fdd1e1f0dcae2d0aa0720895eff33b927d13076e64464bb7c7e5843b7667cd14
    w_download https://download.microsoft.com/download/9/3/F/93FCF1E7-E6A4-478B-96E7-D4B285925B00/vc_redist.x86.exe fdd1e1f0dcae2d0aa0720895eff33b927d13076e64464bb7c7e5843b7667cd14

    if w_workaround_wine_bug 37781; then
        w_warn "This may fail in non-XP mode, see https://bugs.winehq.org/show_bug.cgi?id=37781"
    fi

    w_override_dlls native,builtin api-ms-win-crt-conio-l1-1-0 api-ms-win-crt-heap-l1-1-0 api-ms-win-crt-locale-l1-1-0 api-ms-win-crt-math-l1-1-0 api-ms-win-crt-runtime-l1-1-0 api-ms-win-crt-stdio-l1-1-0 api-ms-win-crt-time-l1-1-0 atl140 concrt140 msvcp140 msvcr140 ucrtbase vcomp140 vcruntime140

    w_set_winver winxp

    w_try_cd "$W_CACHE"/"$W_PACKAGE"
    w_try "$WINE" vc_redist.x86.exe $W_UNATTENDED_SLASH_Q

    case "$W_ARCH" in
        win64)
            # Also install the 64-bit version
            # 2015/10/12: 5eea714e1f22f1875c1cb7b1738b0c0b1f02aec5ecb95f0fdb1c5171c6cd93a3
            w_download https://download.microsoft.com/download/9/3/F/93FCF1E7-E6A4-478B-96E7-D4B285925B00/vc_redist.x64.exe 5eea714e1f22f1875c1cb7b1738b0c0b1f02aec5ecb95f0fdb1c5171c6cd93a3
            if w_workaround_wine_bug 30713 "Manually extracting the 64-bit dlls"; then
                rm -f "$W_TMP"/*  # Avoid permission error
                w_try_cabextract --directory="$W_TMP" vc_redist.x64.exe
                w_try_cabextract --directory="$W_TMP" "$W_TMP/a10"
                w_try_cabextract --directory="$W_TMP" "$W_TMP/a11"
                cp "$W_TMP"/concrt140.dll "$W_SYSTEM64_DLLS"/concrt140.dll
                cp "$W_TMP"/mfc140.dll "$W_SYSTEM64_DLLS"/mfc140.dll
                cp "$W_TMP"/mfc140u.dll "$W_SYSTEM64_DLLS"/mfc140u.dll
                cp "$W_TMP"/mfcm140.dll "$W_SYSTEM64_DLLS"/mfcm140.dll
                cp "$W_TMP"/mfcm140u.dll "$W_SYSTEM64_DLLS"/mfcm140u.dll
                cp "$W_TMP"/msvcp140.dll "$W_SYSTEM64_DLLS"/msvcp140.dll
                cp "$W_TMP"/vcamp140.dll "$W_SYSTEM64_DLLS"/vcamp140.dll
                cp "$W_TMP"/vccorlib140.dll "$W_SYSTEM64_DLLS"/vccorlib140.dll
                cp "$W_TMP"/vcomp140.dll "$W_SYSTEM64_DLLS"/vcomp140.dll
                cp "$W_TMP"/vcruntime140.dll "$W_SYSTEM64_DLLS"/vcruntime140.dll

                cp "$W_TMP"/api_ms_win_crt_conio_l1_1_0.dll "$W_SYSTEM64_DLLS"/api-ms-win-crt-conio-l1-1-0.dll
                cp "$W_TMP"/api_ms_win_crt_heap_l1_1_0.dll "$W_SYSTEM64_DLLS"/api-ms-win-crt-heap-l1-1-0.dll
                cp "$W_TMP"/api_ms_win_crt_locale_l1_1_0.dll "$W_SYSTEM64_DLLS"/api-ms-win-crt-locale-l1-1-0.dll
                cp "$W_TMP"/api_ms_win_crt_math_l1_1_0.dll "$W_SYSTEM64_DLLS"/api-ms-win-crt-math-l1-1-0.dll
                cp "$W_TMP"/api_ms_win_crt_runtime_l1_1_0.dll "$W_SYSTEM64_DLLS"/api-ms-win-crt-runtime-l1-1-0.dll
                cp "$W_TMP"/api_ms_win_crt_stdio_l1_1_0.dll "$W_SYSTEM64_DLLS"/api-ms-win-crt-stdio-l1-1-0.dll
                cp "$W_TMP"/ucrtbase.dll "$W_SYSTEM64_DLLS"/ucrtbase.dll
            else
                w_try "$WINE" vc_redist.x64.exe $W_UNATTENDED_SLASH_Q
            fi
            ;;
    esac
}

#----------------------------------------------------------------

w_metadata vcrun2017 dlls \
    title="Visual C++ 2017 libraries (concrt140.dll,mfc140.dll,mfc140u.dll,mfcm140.dll,mfcm140u.dll,msvcp140.dll,vcamp140.dll,vccorlib140.dll,vcomp140.dll,vcruntime140.dll)" \
    publisher="Microsoft" \
    year="2017" \
    media="download" \
    conflicts="vcrun2015" \
    file1="vc_redist.x86.exe" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/mfc140.dll"

# FIXME: There's a conflict with vcrun2015 because the dll's version number for 2017 and 2015 are the same. Correct behavior should be compared to native Windows.
load_vcrun2017()
{
    # https://support.microsoft.com/en-gb/help/2977003/the-latest-supported-visual-c-downloads
    # 2017/10/02: 2da11e22a276be85970eaed255daf3d92af84e94142ec04252326a882e57303e
    # 2019/03/17: 7355962b95d6a5441c304cd2b86baf37bc206f63349f4a02289bcfb69ef142d3
    w_download https://aka.ms/vs/15/release/vc_redist.x86.exe 7355962b95d6a5441c304cd2b86baf37bc206f63349f4a02289bcfb69ef142d3

    if w_workaround_wine_bug 37781; then
        w_warn "This may fail in non-XP mode, see https://bugs.winehq.org/show_bug.cgi?id=37781"
    fi

    w_override_dlls native,builtin api-ms-win-crt-conio-l1-1-0 api-ms-win-crt-heap-l1-1-0 api-ms-win-crt-locale-l1-1-0 api-ms-win-crt-math-l1-1-0 api-ms-win-crt-runtime-l1-1-0 api-ms-win-crt-stdio-l1-1-0 api-ms-win-crt-time-l1-1-0 atl140 concrt140 msvcp140 msvcr140 ucrtbase vcomp140 vcruntime140

    w_set_winver winxp

    w_try_cd "$W_CACHE/$W_PACKAGE"
    w_try "$WINE" vc_redist.x86.exe $W_UNATTENDED_SLASH_Q

    case "$W_ARCH" in
        win64)
            # Also install the 64-bit version
            # https://support.microsoft.com/en-gb/help/2977003/the-latest-supported-visual-c-downloads
            # 2017/10/02: 7434bf559290cccc3dd3624f10c9e6422cce9927d2231d294114b2f929f0e465
            # 2019/03/17: b192e143d55257a0a2f76be42e44ff8ee14014f3b1b196c6e59829b6b3ec453c
            w_download https://aka.ms/vs/15/release/vc_redist.x64.exe b192e143d55257a0a2f76be42e44ff8ee14014f3b1b196c6e59829b6b3ec453c
            if w_workaround_wine_bug 30713 "Manually extracting the 64-bit dlls"; then
                rm -f "$W_TMP"/*  # Avoid permission error
                w_try_cabextract --directory="$W_TMP" vc_redist.x64.exe
                w_try_cabextract --directory="$W_TMP" "$W_TMP/a10"
                w_try_cabextract --directory="$W_TMP" "$W_TMP/a11"
                cp "$W_TMP"/concrt140.dll "$W_SYSTEM64_DLLS"/concrt140.dll
                cp "$W_TMP"/mfc140.dll "$W_SYSTEM64_DLLS"/mfc140.dll
                cp "$W_TMP"/mfc140u.dll "$W_SYSTEM64_DLLS"/mfc140u.dll
                cp "$W_TMP"/mfcm140.dll "$W_SYSTEM64_DLLS"/mfcm140.dll
                cp "$W_TMP"/mfcm140u.dll "$W_SYSTEM64_DLLS"/mfcm140u.dll
                cp "$W_TMP"/msvcp140.dll "$W_SYSTEM64_DLLS"/msvcp140.dll
                cp "$W_TMP"/vcamp140.dll "$W_SYSTEM64_DLLS"/vcamp140.dll
                cp "$W_TMP"/vccorlib140.dll "$W_SYSTEM64_DLLS"/vccorlib140.dll
                cp "$W_TMP"/vcomp140.dll "$W_SYSTEM64_DLLS"/vcomp140.dll
                cp "$W_TMP"/vcruntime140.dll "$W_SYSTEM64_DLLS"/vcruntime140.dll

                cp "$W_TMP"/api_ms_win_crt_conio_l1_1_0.dll "$W_SYSTEM64_DLLS"/api-ms-win-crt-conio-l1-1-0.dll
                cp "$W_TMP"/api_ms_win_crt_heap_l1_1_0.dll "$W_SYSTEM64_DLLS"/api-ms-win-crt-heap-l1-1-0.dll
                cp "$W_TMP"/api_ms_win_crt_locale_l1_1_0.dll "$W_SYSTEM64_DLLS"/api-ms-win-crt-locale-l1-1-0.dll
                cp "$W_TMP"/api_ms_win_crt_math_l1_1_0.dll "$W_SYSTEM64_DLLS"/api-ms-win-crt-math-l1-1-0.dll
                cp "$W_TMP"/api_ms_win_crt_runtime_l1_1_0.dll "$W_SYSTEM64_DLLS"/api-ms-win-crt-runtime-l1-1-0.dll
                cp "$W_TMP"/api_ms_win_crt_stdio_l1_1_0.dll "$W_SYSTEM64_DLLS"/api-ms-win-crt-stdio-l1-1-0.dll
                cp "$W_TMP"/ucrtbase.dll "$W_SYSTEM64_DLLS"/ucrtbase.dll
            else
                w_try "$WINE" vc_redist.x64.exe $W_UNATTENDED_SLASH_Q
            fi
            ;;
    esac
}

#----------------------------------------------------------------

w_metadata vjrun20 dlls \
    title="MS Visual J# 2.0 SE libraries (requires dotnet20)" \
    publisher="Microsoft" \
    year="2007" \
    media="download" \
    conflicts="dotnet11 dotnet20sp1 dotnet20sp2" \
    file1="vjredist.exe" \
    installed_file1="c:/windows/Microsoft.NET/Framework/VJSharp/VJSharpSxS10.dll"

load_vjrun20()
{
    w_package_unsupported_win64

    w_call dotnet20

    # See https://www.microsoft.com/en-us/download/details.aspx?id=18084
    w_download https://download.microsoft.com/download/9/2/3/92338cd0-759f-4815-8981-24b437be74ef/vjredist.exe cf8f3dd4ad41453a302870b74de1c6489e7ed255ad3f652ce4af0b424a933b41
    w_try_cd "$W_CACHE"/"$W_PACKAGE"
    w_try "$WINE" vjredist.exe ${W_OPT_UNATTENDED:+ /q /C:"install $W_UNATTENDED_SLASH_QNT"}
}

#----------------------------------------------------------------

w_metadata vulkanrt dlls \
    title="Vulkan Runtime 1.1.73.0" \
    publisher="LunarG" \
    year="2018" \
    media="download" \
    file1="VulkanRT-1.1.73.0-Installer.exe" \
    installed_exe1="$W_SYSTEM32_DLLS_WIN/vulkaninfo.exe"

load_vulkanrt()
{
    # https://vulkan.lunarg.com/sdk/home
    w_download "https://sdk.lunarg.com/sdk/download/1.1.73.0/windows/VulkanRT-1.1.73.0-Installer.exe?Human=true;u=" cfec461b17aff521cf06b727aa612d654d4e72de8e3c21bd219e77b87f56f20a VulkanRT-1.1.73.0-Installer.exe
    w_try_cd "$W_CACHE/$W_PACKAGE"
    w_try "$WINE" "$file1" $W_UNATTENDED_SLASH_S
}

#----------------------------------------------------------------

w_metadata vulkansdk dlls \
    title="Vulkan SDK 1.1.73.0 (developers only)" \
    publisher="LunarG" \
    year="2018" \
    media="download" \
    file1="VulkanSDK-1.1.73.0-Installer.exe" \
    installed_file1="C:/VulkanSDK/1.1.73.0/Vulkan.ico" \
    installed_file2="C:/windows/winevulkan.json"

load_vulkansdk()
{
    _W_vulkan_version="${file1%-*.exe}"
    _W_vulkan_version="${_W_vulkan_version#*-}"
    # https://vulkan.lunarg.com/sdk/home
    w_download "https://sdk.lunarg.com/sdk/download/1.1.73.0/windows/VulkanSDK-1.1.73.0-Installer.exe?Human=true;u=" a5d193f97db4de97e6b4fdd81f00ff6a603f66bb17dc3cf8ac0fe9aec58497c7 VulkanSDK-1.1.73.0-Installer.exe
    w_try_cd "$W_CACHE/$W_PACKAGE"
    w_try "$WINE" "$file1" $W_UNATTENDED_SLASH_S
    echo "Creating C:\\windows\\winevulkan.json winevulkan json file"
    cat > "$W_WINDIR_UNIX"/winevulkan.json <<_EOF_
{
    "file_format_version": "1.0.0",
    "ICD": {
        "library_path": "c:\\\\windows\\\\system32\\\\winevulkan.dll",
        "api_version": "$_W_vulkan_version"
    }
}
_EOF_
    echo "Creating winevulkan registry settings"
    cat > "$W_TMP"/winevulkan.reg <<_EOF_
REGEDIT4

[HKEY_LOCAL_MACHINE\\SOFTWARE\\Khronos\\Vulkan\\Drivers\\]
"C:\\\\Windows\\\\winevulkan.json"=dword:00000000

_EOF_
    w_try_regedit "$W_TMP_WIN"\\winevulkan.reg
}

#----------------------------------------------------------------

w_metadata webio dlls \
    title="MS Windows Web I/O" \
    publisher="Microsoft" \
    year="2011" \
    media="download" \
    file1="../win7sp1/windows6.1-KB976932-X86.exe" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/webio.dll"

load_webio()
{
    helper_win7sp1 x86_microsoft-windows-webio_31bf3856ad364e35_6.1.7601.17514_none_5ef1a4093cf55387/webio.dll
    w_try cp "$W_TMP/x86_microsoft-windows-webio_31bf3856ad364e35_6.1.7601.17514_none_5ef1a4093cf55387/webio.dll" "$W_SYSTEM32_DLLS/webio.dll"

    if [ "$W_ARCH" = "win64" ]; then
        helper_win7sp1_x64 amd64_microsoft-windows-webio_31bf3856ad364e35_6.1.7601.17514_none_bb103f8cf552c4bd/webio.dll
        w_try cp "$W_TMP/amd64_microsoft-windows-webio_31bf3856ad364e35_6.1.7601.17514_none_bb103f8cf552c4bd/webio.dll" "$W_SYSTEM64_DLLS/webio.dll"
    fi

    w_override_dlls native,builtin webio
}


#----------------------------------------------------------------

w_metadata windowscodecs dlls \
    title="MS Windows Imaging Component" \
    publisher="Microsoft" \
    year="2006" \
    media="download" \
    file1="wic_x86_enu.exe" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/WindowsCodecs.dll"

load_windowscodecs()
{
    # Separate 32/64-bit installers:
    if [ "$W_ARCH" = "win32" ] ; then
        # https://www.microsoft.com/en-us/download/details.aspx?id=32
        w_download https://download.microsoft.com/download/f/f/1/ff178bb1-da91-48ed-89e5-478a99387d4f/wic_x86_enu.exe 196868b09d87ae04e4ab42b4a3e0abbb160500e8ff13deb38e2956ee854868b1
        EXE="wic_x86_enu.exe"
    elif [ "$W_ARCH" = "win64" ] ; then
        # https://www.microsoft.com/en-us/download/details.aspx?id=1385
        w_download https://download.microsoft.com/download/6/4/5/645FED5F-A6E7-44D9-9D10-FE83348796B0/wic_x64_enu.exe 5822fecd69a90c2833965a25e8779000825d69cc8c9250933f0ab70df52171e1
        EXE="wic_x64_enu.exe"
    else
        w_die "Invalid W_ARCH value, $W_ARCH"
    fi

    # Avoid a file existence check.
    w_try rm -f "$W_SYSTEM32_DLLS"/windowscodecs.dll "$W_SYSTEM32_DLLS"/windowscodecsext.dll "$W_SYSTEM32_DLLS"/wmphoto.dll "$W_SYSTEM32_DLLS"/photometadatahandler.dll

    if [ "$W_ARCH" = "win64" ]; then
         w_try rm -f "$W_SYSTEM64_DLLS"/windowscodecs.dll "$W_SYSTEM64_DLLS"/windowscodecsext.dll "$W_SYSTEM64_DLLS"/wmphoto.dll "$W_SYSTEM64_DLLS"/photometadatahandler.dll
    fi

    # AF says in AppDB entry for .NET 3.0 that windowscodecs has to be native only
    w_override_dlls native windowscodecs windowscodecsext

    # Previously this was winxp, but that didn't work for 64-bit, see https://github.com/Winetricks/winetricks/issues/970
    w_set_winver win2k3

    # Always run the WIC installer in passive mode.
    # See https://bugs.winehq.org/show_bug.cgi?id=16876 and
    # https://bugs.winehq.org/show_bug.cgi?id=23232
    w_try_cd "$W_CACHE/$W_PACKAGE"

    if w_workaround_wine_bug 32859 "Working around possibly broken libX11"; then
        w_try $W_TASKSET "$WINE" "$EXE" /passive
    else
        w_try "$WINE" "$EXE" /passive
    fi
}

#----------------------------------------------------------------

w_metadata winhttp dlls \
    title="MS Windows HTTP Services" \
    publisher="Microsoft" \
    year="2005" \
    media="download" \
    file1="../win2ksp4/W2KSP4_EN.EXE" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/winhttp.dll"

load_winhttp()
{
    # 2017/10/12: Can't use win7's version, as that need webio.dll, which wants ntdll.EtwEventActivityIdControl.
    # Should get that into wine{,-stable} so we can use win7 version in the long run
    # See https://github.com/Winetricks/winetricks/issues/831

    helper_win2ksp4 i386/new/winhttp.dl_
    w_try_cabextract --directory="$W_SYSTEM32_DLLS" "$W_TMP"/i386/new/winhttp.dl_
    w_override_dlls native,builtin winhttp
}

#----------------------------------------------------------------

w_metadata wininet dlls \
    title="MS Windows Internet API" \
    publisher="Microsoft" \
    year="2011" \
    media="download" \
    file1="../win7sp1/windows6.1-KB976932-X86.exe" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/wininet.dll"

load_wininet()
{
    helper_win7sp1 x86_microsoft-windows-i..tocolimplementation_31bf3856ad364e35_8.0.7601.17514_none_1eaaa4a07717236e/wininet.dll
    w_try cp "$W_TMP/x86_microsoft-windows-i..tocolimplementation_31bf3856ad364e35_8.0.7601.17514_none_1eaaa4a07717236e/wininet.dll" "$W_SYSTEM32_DLLS/wininet.dll"
    helper_win7sp1 x86_microsoft-windows-ie-runtimeutilities_31bf3856ad364e35_8.0.7601.17514_none_64655b7c61c841cb/iertutil.dll
    w_try cp "$W_TMP/x86_microsoft-windows-ie-runtimeutilities_31bf3856ad364e35_8.0.7601.17514_none_64655b7c61c841cb/iertutil.dll" "$W_SYSTEM32_DLLS/iertutil.dll"

    if [ "$W_ARCH" = "win64" ]; then
        helper_win7sp1_x64 amd64_microsoft-windows-i..tocolimplementation_31bf3856ad364e35_8.0.7601.17514_none_7ac940242f7494a4/wininet.dll
        w_try cp "$W_TMP/amd64_microsoft-windows-i..tocolimplementation_31bf3856ad364e35_8.0.7601.17514_none_7ac940242f7494a4/wininet.dll" "$W_SYSTEM64_DLLS/wininet.dll"
        helper_win7sp1_x64 amd64_microsoft-windows-ie-runtimeutilities_31bf3856ad364e35_8.0.7601.17514_none_c083f7001a25b301/iertutil.dll
        w_try cp "$W_TMP/amd64_microsoft-windows-ie-runtimeutilities_31bf3856ad364e35_8.0.7601.17514_none_c083f7001a25b301/iertutil.dll" "$W_SYSTEM64_DLLS/iertutil.dll"
    fi

    w_override_dlls native,builtin wininet
    w_override_dlls native,builtin iertutil
}

#----------------------------------------------------------------

w_metadata wininet_win2k dlls \
    title="MS Windows Internet API" \
    publisher="Microsoft" \
    year="2008" \
    media="download" \
    file1="../win2ksp4/W2KSP4_EN.EXE" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/wininet.dll"

load_wininet_win2k()
{
    helper_win2ksp4 i386/wininet.dl_
    w_try_cabextract --directory="$W_SYSTEM32_DLLS" "$W_TMP"/i386/wininet.dl_

    w_override_dlls native,builtin wininet
}

#----------------------------------------------------------------

w_metadata wmi dlls \
    title="Windows Management Instrumentation (aka WBEM) Core 1.5" \
    publisher="Microsoft" \
    year="2000" \
    media="download" \
    file1="wmi9x.exe" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/wbem/wbemcore.dll"

load_wmi()
{
    w_package_unsupported_win64

    # WMI for NT4.0 need validation: https://www.microsoft.com/en-us/download/details.aspx?id=7665
    # See also https://www.microsoft.com/en-us/download/details.aspx?id=16510
    # Originally at: https://download.microsoft.com/download/platformsdk/wmi9x/1.5/W9X/EN-US/wmi9x.exe
    # Mirror list: https://filemare.com/en-us/search/wmi9x.exe/761569271
    # 2017/10/14: ftp://59.124.141.94 is dead, using ftp://82.162.138.211
    # 2018/06/03: ftp://82.162.138.211 is dead, moved to ftp://ftp.espe.edu.ec
    w_download http://alesi.com.mx/soporte/Sharpdesk/Redist/Esp/WMI/wmi9x.exe 1d5d94050354b164c6a19531df151e0703d5eb39cebf4357ee2cfc340c2509d0

    w_set_winver win98
    w_override_dlls native,builtin wbemprox wmiutils

    # Note: there is a crash in the background towards the end, doesn't seem to hurt; see https://bugs.winehq.org/show_bug.cgi?id=7920
    w_try_cd "$W_CACHE/$W_PACKAGE"
    w_try "$WINE" wmi9x.exe $W_UNATTENDED_SLASH_S
    w_killall "WinMgmt.exe"

    w_unset_winver
}

#----------------------------------------------------------------

w_metadata wmv9vcm dlls \
    title="MS Windows Media Video 9 Video Compression Manager" \
    publisher="Microsoft" \
    year="2013" \
    media="download" \
    file1="WindowsServer2003-WindowsMedia-KB2845142-x86-ENU.exe" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/wmv9vcm.dll"

load_wmv9vcm()
{
    # https://www.microsoft.com/en-us/download/details.aspx?id=39486
    # See also https://www.microsoft.com/en-us/download/details.aspx?id=6191
    w_download https://download.microsoft.com/download/2/8/D/28DA9C3E-6DA2-456F-BD33-1F937EB6E0FF/WindowsServer2003-WindowsMedia-KB2845142-x86-ENU.exe 51e11691339c1c817b12f92e613145ffcd7b6f7e869d994cc8dbc4591b24f155
    w_try_cabextract --directory="$W_TMP" "$W_CACHE/$W_PACKAGE/$file1"
    w_try cp -f "$W_TMP"/wm64/wmv9vcm.dll "$W_SYSTEM32_DLLS"

    # Register codec:
    cat > "$W_TMP"/tmp.reg <<_EOF_
REGEDIT4
[HKEY_LOCAL_MACHINE\\Software\\Microsoft\\Windows NT\\CurrentVersion\\Drivers32]
"vidc.WMV3"="wmv9vcm.dll"

_EOF_
    w_try_regedit "$W_TMP_WIN"\\tmp.reg
}

#----------------------------------------------------------------

w_metadata wsh57 dlls \
    title="MS Windows Script Host 5.7" \
    publisher="Microsoft" \
    year="2007" \
    media="download" \
    file1="scripten.exe" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/scrrun.dll"

load_wsh57()
{
    # See also https://www.microsoft.com/en-us/download/details.aspx?id=8247
    w_download https://download.microsoft.com/download/4/4/d/44de8a9e-630d-4c10-9f17-b9b34d3f6417/scripten.exe 63c781b9e50bfd55f10700eb70b5c571a9bedfd8d35af29f6a22a77550df5e7b

    w_try_cabextract -d "$W_SYSTEM32_DLLS" "$W_CACHE"/wsh57/scripten.exe

    # Wine doesn't provide the other dll's (yet?)
    w_override_dlls native,builtin jscript scrrun vbscript cscript.exe wscript.exe
    w_try_regsvr dispex.dll jscript.dll scrobj.dll scrrun.dll vbscript.dll wshcon.dll wshext.dll
}

#----------------------------------------------------------------

w_metadata xact dlls \
    title="MS XACT Engine (32-bit only)" \
    publisher="Microsoft" \
    year="2010" \
    media="download" \
    file1="../directx9/directx_Jun2010_redist.exe" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/xactengine2_0.dll"

load_xact()
{
    helper_directx_Jun2010

    # Extract xactengine?_?.dll, X3DAudio?_?.dll, xaudio?_?.dll, xapofx?_?.dll
    w_try_cabextract -d "$W_TMP" -L -F '*_xact_*x86*' "$W_CACHE/directx9/$DIRECTX_NAME"
    w_try_cabextract -d "$W_TMP" -L -F '*_x3daudio_*x86*' "$W_CACHE/directx9/$DIRECTX_NAME"
    w_try_cabextract -d "$W_TMP" -L -F '*_xaudio_*x86*' "$W_CACHE/directx9/$DIRECTX_NAME"

    for x in "$W_TMP"/*.cab ; do
        w_try_cabextract -d "$W_SYSTEM32_DLLS" -L -F 'xactengine*.dll' "$x"
        w_try_cabextract -d "$W_SYSTEM32_DLLS" -L -F 'xaudio*.dll' "$x"
        w_try_cabextract -d "$W_SYSTEM32_DLLS" -L -F 'x3daudio*.dll' "$x"
        w_try_cabextract -d "$W_SYSTEM32_DLLS" -L -F 'xapofx*.dll' "$x"
    done

    # Don't install 64-bit xact DLLs by default. They are broken in Wine, see:
    # https://bugs.winehq.org/show_bug.cgi?id=41618#c5

    w_override_dlls native,builtin xaudio2_0 xaudio2_1 xaudio2_2 xaudio2_3 xaudio2_4 xaudio2_5 xaudio2_6 xaudio2_7
    w_override_dlls native,builtin x3daudio1_0 x3daudio1_1 x3daudio1_2 x3daudio1_3 x3daudio1_4 x3daudio1_5 x3daudio1_6 x3daudio1_7
    w_override_dlls native,builtin xapofx1_1 xapofx1_2 xapofx1_3 xapofx1_4 xapofx1_5

    # Register xactengine?_?.dll
    for x in "$W_SYSTEM32_DLLS"/xactengine* ; do
        w_try_regsvr "$(basename "$x")"
    done

    # and xaudio?_?.dll, but not xaudio2_8 (unsupported)
    for x in 0 1 2 3 4 5 6 7 ; do
        w_try_regsvr "$(basename "$W_SYSTEM32_DLLS/xaudio2_${x}")"
    done
}

#----------------------------------------------------------------

w_metadata xact_x64 dlls \
    title="MS XACT Engine (64-bit only)" \
    publisher="Microsoft" \
    year="2010" \
    media="download" \
    file1="../directx9/directx_Jun2010_redist.exe" \
    installed_file1="${W_SYSTEM64_DLLS_WIN64:-does_not_exist}/xactengine2_0.dll"

load_xact_x64()
{
    w_package_unsupported_win32
    if w_workaround_wine_bug 41618; then
        w_warn "While this helps some games, it completely breaks others. You've been warned."
    fi

    helper_directx_Jun2010

    # Extract xactengine?_?.dll, X3DAudio?_?.dll, xaudio?_?.dll, xapofx?_?.dll
    w_try_cabextract -d "$W_TMP" -L -F '*_xact_*x64*' "$W_CACHE/directx9/$DIRECTX_NAME"
    w_try_cabextract -d "$W_TMP" -L -F '*_x3daudio_*x64*' "$W_CACHE/directx9/$DIRECTX_NAME"
    w_try_cabextract -d "$W_TMP" -L -F '*_xaudio_*x64*' "$W_CACHE/directx9/$DIRECTX_NAME"

    for x in "$W_TMP"/*.cab ; do
        w_try_cabextract -d "$W_SYSTEM64_DLLS" -L -F 'xactengine*.dll' "$x"
        w_try_cabextract -d "$W_SYSTEM64_DLLS" -L -F 'xaudio*.dll' "$x"
        w_try_cabextract -d "$W_SYSTEM64_DLLS" -L -F 'x3daudio*.dll' "$x"
        w_try_cabextract -d "$W_SYSTEM64_DLLS" -L -F 'xapofx*.dll' "$x"
    done

    w_override_dlls native,builtin xaudio2_0 xaudio2_1 xaudio2_2 xaudio2_3 xaudio2_4 xaudio2_5 xaudio2_6 xaudio2_7
    w_override_dlls native,builtin x3daudio1_0 x3daudio1_1 x3daudio1_2 x3daudio1_3 x3daudio1_4 x3daudio1_5 x3daudio1_6 x3daudio1_7
    w_override_dlls native,builtin xapofx1_1 xapofx1_2 xapofx1_3 xapofx1_4 xapofx1_5

    # Register xactengine?_?.dll
    for x in "$W_SYSTEM64_DLLS"/xactengine* ; do
        w_try_regsvr64 "$(basename "$x")"
    done

    # and xaudio?_?.dll, but not xaudio2_8 (unsupported)
    for x in 0 1 2 3 4 5 6 7 ; do
        w_try_regsvr64 "$(basename "$W_SYSTEM64_DLLS/xaudio2_${x}")"
    done
}

#----------------------------------------------------------------

w_metadata xinput dlls \
    title="Microsoft XInput (Xbox controller support)" \
    publisher="Microsoft" \
    year="2010" \
    media="download" \
    file1="../directx9/directx_feb2010_redist.exe" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/xinput1_1.dll"

load_xinput()
{
    helper_directx_Jun2010

    w_try_cabextract -d "$W_TMP" -L -F '*_xinput_*x86*' "$W_CACHE"/directx9/$DIRECTX_NAME
    for x in "$W_TMP"/*.cab
    do
      w_try_cabextract -d "$W_SYSTEM32_DLLS" -L -F 'xinput*.dll' "$x"
    done
    if test "$W_ARCH" = "win64"; then
        w_try_cabextract -d "$W_TMP" -L -F '*_xinput_*x64*' "$W_CACHE"/directx9/$DIRECTX_NAME
        for x in "$W_TMP"/*x64.cab
        do
            w_try_cabextract -d "$W_SYSTEM64_DLLS" -L -F 'xinput*.dll' "$x"
        done
    fi
    w_override_dlls native xinput1_1
    w_override_dlls native xinput1_2
    w_override_dlls native xinput1_3
    w_override_dlls native xinput9_1_0
}

#----------------------------------------------------------------

w_metadata xmllite dlls \
    title="MS xmllite dll" \
    publisher="Microsoft" \
    year="2011" \
    media="download" \
    file1="../win7sp1/windows6.1-KB976932-X86.exe" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/xmllite.dll"

load_xmllite()
{
    helper_win7sp1 x86_microsoft-windows-servicingstack_31bf3856ad364e35_6.1.7601.17514_none_0b66cb34258c936f/xmllite.dll
    w_try cp "$W_TMP/x86_microsoft-windows-servicingstack_31bf3856ad364e35_6.1.7601.17514_none_0b66cb34258c936f/xmllite.dll" "$W_SYSTEM32_DLLS/xmllite.dll"

    if [ "$W_ARCH" = "win64" ]; then
        helper_win7sp1_x64 amd64_microsoft-windows-servicingstack_31bf3856ad364e35_6.1.7601.17514_none_678566b7ddea04a5/xmllite.dll "$W_SYSTEM64_DLLS/xmllite.dll"
        w_try cp "$W_TMP/amd64_microsoft-windows-servicingstack_31bf3856ad364e35_6.1.7601.17514_none_678566b7ddea04a5/xmllite.dll" "$W_SYSTEM64_DLLS/xmllite.dll"
    fi

    w_override_dlls native,builtin xmllite
}

#----------------------------------------------------------------

w_metadata xna31 dlls \
    title="MS XNA Framework Redistributable 3.1" \
    publisher="Microsoft" \
    year="2009" \
    media="download" \
    file1="xnafx31_redist.msi" \
    installed_file1="C:/windows/assembly/GAC_32/Microsoft.Xna.Framework.Game/3.1.0.0__6d5c3888ef60e27d/Microsoft.Xna.Framework.Game.dll"

load_xna31()
{
    w_call dotnet20sp2
    w_download https://download.microsoft.com/download/5/9/1/5912526C-B950-4662-99B6-119A83E60E5C/xnafx31_redist.msi 187e7e6b08fe35428d945612a7d258bfed25fad53cc54882983abdc73fe60f91
    w_try_cd "$W_CACHE/$W_PACKAGE"
    w_try "$WINE" msiexec $W_UNATTENDED_SLASH_QUIET /i "$file1"
}

#----------------------------------------------------------------

w_metadata xna40 dlls \
    title="MS XNA Framework Redistributable 4.0" \
    publisher="Microsoft" \
    year="2010" \
    media="download" \
    file1="xnafx40_redist.msi" \
    installed_file1="$W_PROGRAMS_X86_WIN/Common Files/Microsoft Shared/XNA/Framework/v4.0/XnaNative.dll"

load_xna40()
{
    if w_workaround_wine_bug 30718; then
        w_warn "$W_PACKAGE may not install properly in Wine yet"
    fi

    # See https://bugs.winehq.org/show_bug.cgi?id=30718#c8
    export COMPlus_OnlyUseLatestCLR=1
    w_call dotnet40

    # https://www.microsoft.com/en-us/download/details.aspx?id=20914
    w_download https://download.microsoft.com/download/A/C/2/AC2C903B-E6E8-42C2-9FD7-BEBAC362A930/xnafx40_redist.msi e6c41d692ebcba854dad4b1c52bb7ddd05926bad3105595d6596b8bab01c25e7
    w_try_cd "$W_CACHE/$W_PACKAGE"
    w_try "$WINE" msiexec $W_UNATTENDED_SLASH_QUIET /i "$file1"
}

#----------------------------------------------------------------

w_metadata xvid dlls \
    title="Xvid Video Codec" \
    publisher="xvid.org" \
    year="2009" \
    media="download" \
    file1="Xvid-1.3.2-20110601.exe" \
    installed_file1="$W_PROGRAMS_X86_WIN/Xvid/xvid.ico"

load_xvid()
{
    w_call vcrun6
    w_download http://www.koepi.info/Xvid-1.3.2-20110601.exe 74b23965cebe59e388eab6dba224b6b751ef4519454cc12086ade51c81f0a33c
    w_try_cd "$W_CACHE/$W_PACKAGE"
    w_try "$WINE" "$file1" ${W_OPT_UNATTENDED:+ --mode unattended --decode_divx 1 --decode_3ivx 1 --decode_other 1}
}

#######################
# fonts
#######################

w_metadata baekmuk fonts \
    title="Baekmuk Korean fonts" \
    publisher="Wooderart Inc. / kldp.net" \
    year="1999" \
    media="download" \
    file1="fonts-baekmuk_2.2.orig.tar.gz" \
    installed_file1="$W_FONTSDIR_WIN/batang.ttf"

load_baekmuk()
{
    # See http://kldp.net/projects/baekmuk for project page
    # Need to download from Debian as the project page has unique captcha tokens per visitor
    w_download "https://deb.debian.org/debian/pool/main/f/fonts-baekmuk/fonts-baekmuk_2.2.orig.tar.gz" 08ab7dffb55d5887cc942ce370f5e33b756a55fbb4eaf0b90f244070e8d51882

    w_try_cd "$W_TMP"
    w_try tar -zxf "$W_CACHE/$W_PACKAGE/$file1" baekmuk-ttf-2.2/ttf
    w_try_cp_font_files baekmuk-ttf-2.2/ttf/ "$W_FONTSDIR_UNIX"
    w_register_font batang.ttf "Baekmuk Batang"
    w_register_font gulim.ttf "Baekmuk Gulim"
    w_register_font dotum.ttf "Baekmuk Dotum"
    w_register_font hline.ttf "Baekmuk Headline"
}

#----------------------------------------------------------------

w_metadata cjkfonts fonts \
    title="All Chinese, Japanese, Korean fonts and aliases" \
    publisher="various" \
    date="1999-2010" \
    media="download"

load_cjkfonts()
{
    w_call fakechinese
    w_call fakejapanese
    w_call fakejapanese_vlgothic
    w_call fakekorean
    w_call unifont
}

#----------------------------------------------------------------

w_metadata calibri fonts \
    title="MS Calibri font" \
    publisher="Microsoft" \
    year="2007" \
    media="download" \
    file1="PowerPointViewer.exe" \
    installed_file1="$W_FONTSDIR_WIN/calibri.ttf"

load_calibri()
{
    # https://www.microsoft.com/en-us/download/details.aspx?id=13
    # Originally at https://download.microsoft.com/download/E/6/7/E675FFFC-2A6D-4AB0-B3EB-27C9F8C8F696/PowerPointViewer.exe
    w_download_to PowerPointViewer "http://www.business.uwm.edu/gdrive/Dietenberger_E/PowerPointViewer.exe" 249473568eba7a1e4f95498acba594e0f42e6581add4dead70c1dfb908a09423
    w_try_cabextract -d "$W_TMP" -F "ppviewer.cab" "$W_CACHE/PowerPointViewer/$file1"
    w_try_cabextract -d "$W_TMP" -F "CALIBRI*.TTF" "$W_TMP/ppviewer.cab"
    w_try_cp_font_files "$W_TMP" "$W_FONTSDIR_UNIX" "CALIBRI*.TTF"
    w_register_font calibri.ttf "Calibri"
    w_register_font calibrib.ttf "Calibri Bold"
    w_register_font calibrii.ttf "Calibri Italic"
    w_register_font calibriz.ttf "Calibri Bold Italic"
}

#----------------------------------------------------------------

w_metadata cambria fonts \
    title="MS Cambria font" \
    publisher="Microsoft" \
    year="2009" \
    media="download" \
    file1="PowerPointViewer.exe" \
    installed_file1="$W_FONTSDIR_WIN/cambria.ttc"

load_cambria()
{
    # https://www.microsoft.com/en-us/download/details.aspx?id=13
    # Originally at https://download.microsoft.com/download/E/6/7/E675FFFC-2A6D-4AB0-B3EB-27C9F8C8F696/PowerPointViewer.exe
    w_download_to PowerPointViewer "http://www.business.uwm.edu/gdrive/Dietenberger_E/PowerPointViewer.exe" 249473568eba7a1e4f95498acba594e0f42e6581add4dead70c1dfb908a09423
    w_try_cabextract -d "$W_TMP" -F "ppviewer.cab" "$W_CACHE/PowerPointViewer/$file1"
    w_try_cabextract -d "$W_TMP" -F "CAMBRIA*.TT*" "$W_TMP/ppviewer.cab"
    w_try_cp_font_files "$W_TMP" "$W_FONTSDIR_UNIX" "CAMBRIA*.TT*"
    w_register_font cambria.ttc "Cambria & Cambria Math"
    w_register_font cambriab.ttf "Cambria Bold"
    w_register_font cambriai.ttf "Cambria Italic"
    w_register_font cambriaz.ttf "Cambria Bold Italic"
}

#----------------------------------------------------------------

w_metadata candara fonts \
    title="MS Candara font" \
    publisher="Microsoft" \
    year="2009" \
    media="download" \
    file1="PowerPointViewer.exe" \
    installed_file1="$W_FONTSDIR_WIN/candara.ttf"

load_candara()
{
    # https://www.microsoft.com/en-us/download/details.aspx?id=13
    # Originally at https://download.microsoft.com/download/E/6/7/E675FFFC-2A6D-4AB0-B3EB-27C9F8C8F696/PowerPointViewer.exe
    w_download_to PowerPointViewer "http://www.business.uwm.edu/gdrive/Dietenberger_E/PowerPointViewer.exe" 249473568eba7a1e4f95498acba594e0f42e6581add4dead70c1dfb908a09423
    w_try_cabextract -d "$W_TMP" -F "ppviewer.cab" "$W_CACHE/PowerPointViewer/$file1"
    w_try_cabextract -d "$W_TMP" -F "CANDARA*.TTF" "$W_TMP/ppviewer.cab"
    w_try_cp_font_files "$W_TMP" "$W_FONTSDIR_UNIX" "CANDARA*.TTF"
    w_register_font candara.ttf "Candara"
    w_register_font candarab.ttf "Candara Bold"
    w_register_font candarai.ttf "Candara Italic"
    w_register_font candaraz.ttf "Candara Bold Italic"
}

#----------------------------------------------------------------

w_metadata consolas fonts \
    title="MS Consolas console font" \
    publisher="Microsoft" \
    year="2011" \
    media="download" \
    file1="PowerPointViewer.exe" \
    installed_file1="$W_FONTSDIR_WIN/consola.ttf"

load_consolas()
{
    # https://www.microsoft.com/en-us/download/details.aspx?id=13
    # Originally at https://download.microsoft.com/download/E/6/7/E675FFFC-2A6D-4AB0-B3EB-27C9F8C8F696/PowerPointViewer.exe
    w_download_to PowerPointViewer "http://www.business.uwm.edu/gdrive/Dietenberger_E/PowerPointViewer.exe" 249473568eba7a1e4f95498acba594e0f42e6581add4dead70c1dfb908a09423
    w_try_cabextract -d "$W_TMP" -F "ppviewer.cab" "$W_CACHE/PowerPointViewer/$file1"
    w_try_cabextract -d "$W_TMP" -F "CONSOLA*.TTF" "$W_TMP/ppviewer.cab"
    w_try_cp_font_files "$W_TMP" "$W_FONTSDIR_UNIX" "CONSOLA*.TTF"
    w_register_font consola.ttf "Consolas"
    w_register_font consolab.ttf "Consolas Bold"
    w_register_font consolai.ttf "Consolas Italic"
    w_register_font consolaz.ttf "Consolas Bold Italic"
}

#----------------------------------------------------------------

w_metadata constantia fonts \
    title="MS Constantia font" \
    publisher="Microsoft" \
    year="2009" \
    media="download" \
    file1="PowerPointViewer.exe" \
    installed_file1="$W_FONTSDIR_WIN/constan.ttf"

load_constantia()
{
    # https://www.microsoft.com/en-us/download/details.aspx?id=13
    # Originally at https://download.microsoft.com/download/E/6/7/E675FFFC-2A6D-4AB0-B3EB-27C9F8C8F696/PowerPointViewer.exe
    w_download_to PowerPointViewer "http://www.business.uwm.edu/gdrive/Dietenberger_E/PowerPointViewer.exe" 249473568eba7a1e4f95498acba594e0f42e6581add4dead70c1dfb908a09423
    w_try_cabextract -d "$W_TMP" -F "ppviewer.cab" "$W_CACHE/PowerPointViewer/$file1"
    w_try_cabextract -d "$W_TMP" -F "CONSTAN*.TTF" "$W_TMP/ppviewer.cab"
    w_try_cp_font_files "$W_TMP" "$W_FONTSDIR_UNIX" "CONSTAN*.TTF"
    w_register_font constan.ttf "Constantia"
    w_register_font constanb.ttf "Constantia Bold"
    w_register_font constani.ttf "Constantia Italic"
    w_register_font constanz.ttf "Constantia Bold Italic"
}

#----------------------------------------------------------------

w_metadata corbel fonts \
    title="MS Corbel font" \
    publisher="Microsoft" \
    year="2009" \
    media="download" \
    file1="PowerPointViewer.exe" \
    installed_file1="$W_FONTSDIR_WIN/corbel.ttf"

load_corbel()
{
    # https://www.microsoft.com/en-us/download/details.aspx?id=13
    # Originally at https://download.microsoft.com/download/E/6/7/E675FFFC-2A6D-4AB0-B3EB-27C9F8C8F696/PowerPointViewer.exe
    w_download_to PowerPointViewer "http://www.business.uwm.edu/gdrive/Dietenberger_E/PowerPointViewer.exe" 249473568eba7a1e4f95498acba594e0f42e6581add4dead70c1dfb908a09423
    w_try_cabextract -d "$W_TMP" -F "ppviewer.cab" "$W_CACHE/PowerPointViewer/$file1"
    w_try_cabextract -d "$W_TMP" -F "CORBEL*.TTF" "$W_TMP/ppviewer.cab"
    w_try_cp_font_files "$W_TMP" "$W_FONTSDIR_UNIX" "CORBEL*.TTF"
    w_register_font corbel.ttf "Corbel"
    w_register_font corbelb.ttf "Corbel Bold"
    w_register_font corbeli.ttf "Corbel Italic"
    w_register_font corbelz.ttf "Corbel Bold Italic"
}

#----------------------------------------------------------------

w_metadata meiryo fonts \
    title="MS Meiryo font" \
    publisher="Microsoft" \
    year="2009" \
    media="download" \
    conflicts="fakejapanese_vlgothic" \
    file1="PowerPointViewer.exe" \
    installed_file1="$W_FONTSDIR_WIN/meiryo.ttc"

load_meiryo()
{
    # https://www.microsoft.com/en-us/download/details.aspx?id=13
    # Originally at https://download.microsoft.com/download/E/6/7/E675FFFC-2A6D-4AB0-B3EB-27C9F8C8F696/PowerPointViewer.exe
    w_download_to PowerPointViewer "http://www.business.uwm.edu/gdrive/Dietenberger_E/PowerPointViewer.exe" 249473568eba7a1e4f95498acba594e0f42e6581add4dead70c1dfb908a09423
    w_try_cabextract -d "$W_TMP" -F "ppviewer.cab" "$W_CACHE/PowerPointViewer/$file1"
    w_try_cabextract -d "$W_TMP" -F "MEIRYO*.TTC" "$W_TMP/ppviewer.cab"
    w_try_cp_font_files "$W_TMP" "$W_FONTSDIR_UNIX" "MEIRYO*.TTC"
    w_register_font meiryo.ttc "Meiryo & Meiryo Italic & Meiryo UI & Meiryo UI Italic"
    w_register_font meiryob.ttc "Meiryo Bold & Meiryo Bold Italic & Meiryo UI Bold & Meiryo UI Bold Italic"
}

#----------------------------------------------------------------

w_metadata pptfonts fonts \
    title="All MS PowerPoint Viewer fonts" \
    publisher="various" \
    date="2007-2009" \
    media="download"

load_pptfonts()
{
    w_call calibri
    w_call cambria
    w_call candara
    w_call consolas
    w_call constantia
    w_call corbel
    w_call meiryo
}

#----------------------------------------------------------------

w_metadata andale fonts \
    title="MS Andale Mono font" \
    publisher="Microsoft" \
    year="2008" \
    media="download" \
    file1="andale32.exe" \
    installed_file1="$W_FONTSDIR_WIN/andalemo.ttf"

load_andale()
{
    w_download_to corefonts "https://mirrors.kernel.org/gentoo/distfiles/andale32.exe" 0524fe42951adc3a7eb870e32f0920313c71f170c859b5f770d82b4ee111e970
    w_try_cabextract -d "$W_TMP" "$W_CACHE"/corefonts/andale32.exe
    w_try_cp_font_files "$W_TMP" "$W_FONTSDIR_UNIX" "AndaleMo.TTF"
    w_register_font andalemo.ttf "Andale Mono"
}

#----------------------------------------------------------------

w_metadata arial fonts \
    title="MS Arial / Arial Black fonts" \
    publisher="Microsoft" \
    year="2008" \
    media="download" \
    file1="arial32.exe" \
    installed_file1="$W_FONTSDIR_WIN/arial.ttf"

load_arial()
{
    w_download_to corefonts "https://mirrors.kernel.org/gentoo/distfiles/arial32.exe" 85297a4d146e9c87ac6f74822734bdee5f4b2a722d7eaa584b7f2cbf76f478f6
    w_download_to corefonts "https://mirrors.kernel.org/gentoo/distfiles/arialb32.exe" a425f0ffb6a1a5ede5b979ed6177f4f4f4fdef6ae7c302a7b7720ef332fec0a8

    w_try_cabextract -d "$W_TMP" "$W_CACHE"/corefonts/arial32.exe
    w_try_cp_font_files "$W_TMP" "$W_FONTSDIR_UNIX" "Arial*.TTF"
    w_register_font arialbd.ttf "Arial Bold"
    w_register_font arialbi.ttf "Arial Bold Italic"
    w_register_font ariali.ttf "Arial Italic"
    w_register_font arial.ttf "Arial"

    w_try_cabextract -d "$W_TMP" "$W_CACHE"/corefonts/arialb32.exe
    w_try_cp_font_files "$W_TMP" "$W_FONTSDIR_UNIX" "AriBlk.TTF"
    w_register_font ariblk.ttf "Arial Black"
}

#----------------------------------------------------------------

w_metadata comicsans fonts \
    title="MS Comic Sans fonts" \
    publisher="Microsoft" \
    year="2008" \
    media="download" \
    file1="comic32.exe" \
    installed_file1="$W_FONTSDIR_WIN/comic.ttf"

load_comicsans()
{
    w_download_to corefonts "https://mirrors.kernel.org/gentoo/distfiles/comic32.exe" 9c6df3feefde26d4e41d4a4fe5db2a89f9123a772594d7f59afd062625cd204e
    w_try_cabextract -d "$W_TMP" "$W_CACHE"/corefonts/comic32.exe
    w_try_cp_font_files "$W_TMP" "$W_FONTSDIR_UNIX" "Comic*.TTF"
    w_register_font comicbd.ttf "Comic Sans MS Bold"
    w_register_font comic.ttf "Comic Sans MS"
}

#----------------------------------------------------------------

w_metadata courier fonts \
    title="MS Courier fonts" \
    publisher="Microsoft" \
    year="2008" \
    media="download" \
    file1="courie32.exe" \
    installed_file1="$W_FONTSDIR_WIN/cour.ttf"
load_courier()
{
    w_download_to corefonts "https://mirrors.kernel.org/gentoo/distfiles/courie32.exe" bb511d861655dde879ae552eb86b134d6fae67cb58502e6ff73ec5d9151f3384
    w_try_cabextract -d "$W_TMP" "$W_CACHE"/corefonts/courie32.exe
    w_try_cp_font_files "$W_TMP" "$W_FONTSDIR_UNIX" "cour*.ttf"
    w_register_font courbd.ttf "Courier New Bold"
    w_register_font courbi.ttf "Courier New Bold Italic"
    w_register_font couri.ttf "Courier New Italic"
    w_register_font cour.ttf "Courier New"
}

#----------------------------------------------------------------

w_metadata georgia fonts \
    title="MS Georgia fonts" \
    publisher="Microsoft" \
    year="2008" \
    media="download" \
    file1="georgi32.exe" \
    installed_file1="$W_FONTSDIR_WIN/georgia.ttf"
load_georgia()
{
    w_download_to corefonts "https://mirrors.kernel.org/gentoo/distfiles/georgi32.exe" 2c2c7dcda6606ea5cf08918fb7cd3f3359e9e84338dc690013f20cd42e930301
    w_try_cabextract -d "$W_TMP" "$W_CACHE"/corefonts/georgi32.exe
    w_try_cp_font_files "$W_TMP" "$W_FONTSDIR_UNIX" "Georgia*.TTF"
    w_register_font georgiab.ttf "Georgia Bold"
    w_register_font georgiai.ttf "Georgia Italic"
    w_register_font georgia.ttf "Georgia"
    w_register_font georgiaz.ttf "Georgia Bold Italic"
}

#----------------------------------------------------------------

w_metadata impact fonts \
    title="MS Impact fonts" \
    publisher="Microsoft" \
    year="2008" \
    media="download" \
    file1="impact32.exe" \
    installed_file1="$W_FONTSDIR_WIN/impact.ttf"

load_impact()
{
    w_download_to corefonts "https://mirrors.kernel.org/gentoo/distfiles/impact32.exe" 6061ef3b7401d9642f5dfdb5f2b376aa14663f6275e60a51207ad4facf2fccfb
    w_try_cabextract -d "$W_TMP" "$W_CACHE"/corefonts/impact32.exe
    w_try_cp_font_files "$W_TMP" "$W_FONTSDIR_UNIX" "Impact.TTF"
    w_register_font impact.ttf "Impact"
}

#----------------------------------------------------------------

w_metadata times fonts \
    title="MS Times fonts" \
    publisher="Microsoft" \
    year="2008" \
    media="download" \
    file1="times32.exe" \
    installed_file1="$W_FONTSDIR_WIN/times.ttf"

load_times()
{
    w_download_to corefonts "https://mirrors.kernel.org/gentoo/distfiles/times32.exe" db56595ec6ef5d3de5c24994f001f03b2a13e37cee27bc25c58f6f43e8f807ab
    w_try_cabextract -d "$W_TMP" "$W_CACHE"/corefonts/times32.exe
    w_try_cp_font_files "$W_TMP" "$W_FONTSDIR_UNIX" "Times*.TTF"
    w_register_font timesbd.ttf "Times New Roman Bold"
    w_register_font timesbi.ttf "Times New Roman Bold Italic"
    w_register_font timesi.ttf "Times New Roman Italic"
    w_register_font times.ttf "Times New Roman"
}

#----------------------------------------------------------------

w_metadata trebuchet fonts \
    title="MS Trebuchet fonts" \
    publisher="Microsoft" \
    year="2008" \
    media="download" \
    file1="trebuchet32.exe" \
    installed_file1="$W_FONTSDIR_WIN/trebuc.ttf"

load_trebuchet()
{
    w_download_to corefonts "https://mirrors.kernel.org/gentoo/distfiles/trebuc32.exe" 5a690d9bb8510be1b8b4fe49f1f2319651fe51bbe54775ddddd8ef0bd07fdac9
    w_try_cabextract -d "$W_TMP" "$W_CACHE"/corefonts/trebuc32.exe
    w_try_cp_font_files "$W_TMP" "$W_FONTSDIR_UNIX" "[tT]rebuc*.ttf"
    w_register_font trebucbd.ttf "Trebuchet MS Bold"
    w_register_font trebucbi.ttf "Trebuchet MS Bold Italic"
    w_register_font trebucit.ttf "Trebuchet MS Italic"
    w_register_font trebuc.ttf "Trebuchet MS"
}

#----------------------------------------------------------------

w_metadata verdana fonts \
    title="MS Verdana fonts" \
    publisher="Microsoft" \
    year="2008" \
    media="download" \
    file1="verdan32.exe" \
    installed_file1="$W_FONTSDIR_WIN/verdana.ttf"

load_verdana()
{
    w_download_to corefonts "https://mirrors.kernel.org/gentoo/distfiles/verdan32.exe" c1cb61255e363166794e47664e2f21af8e3a26cb6346eb8d2ae2fa85dd5aad96
    w_try_cabextract -d "$W_TMP" "$W_CACHE"/corefonts/verdan32.exe
    w_try_cp_font_files "$W_TMP" "$W_FONTSDIR_UNIX" "Verdana*.TTF"
    w_register_font verdanab.ttf "Verdana Bold"
    w_register_font verdanai.ttf "Verdana Italic"
    w_register_font verdana.ttf "Verdana"
    w_register_font verdanaz.ttf "Verdana Bold Italic"
}

#----------------------------------------------------------------

w_metadata webdings fonts \
    title="MS Webdings fonts" \
    publisher="Microsoft" \
    year="2008" \
    media="download" \
    file1="webdin32.exe" \
    installed_file1="$W_FONTSDIR_WIN/webdings.ttf"

load_webdings()
{
    w_download_to corefonts "https://mirrors.kernel.org/gentoo/distfiles/webdin32.exe" 64595b5abc1080fba8610c5c34fab5863408e806aafe84653ca8575bed17d75a
    w_try_cabextract -d "$W_TMP" "$W_CACHE"/corefonts/webdin32.exe
    w_try_cp_font_files "$W_TMP" "$W_FONTSDIR_UNIX" "Webdings.TTF"
    w_register_font webdings.ttf "Webdings"
}

#----------------------------------------------------------------

w_metadata corefonts fonts \
    title="MS Arial, Courier, Times fonts" \
    publisher="Microsoft" \
    year="2008" \
    media="download" \
    file1="arial32.exe" \
    installed_file1="$W_FONTSDIR_WIN/corefonts.installed"

load_corefonts()
{
    # Natively installed versions of these fonts will cause the installers
    # to exit silently. Because there are apps out there that depend on the
    # files being present in the Windows font directory we use cabextract
    # to obtain the files and register the fonts by hand.

    w_call andale
    w_call arial
    w_call comicsans
    w_call courier
    w_call georgia
    w_call impact
    w_call times
    w_call trebuchet
    w_call verdana
    w_call webdings

    touch "$W_FONTSDIR_UNIX/corefonts.installed"
}

#----------------------------------------------------------------

w_metadata droid fonts \
    title="Droid fonts" \
    publisher="Ascender Corporation" \
    year="2009" \
    media="download" \
    file1="DroidSans-Bold.ttf" \
    installed_file1="$W_FONTSDIR_WIN/droidsans-bold.ttf"

do_droid() {
    w_download "${_W_droid_url}${1}?raw=true" "$3"  "$1"
    w_try_cp_font_files "$W_CACHE/droid" "$W_FONTSDIR_UNIX" "$1"
    w_register_font "$(echo "$1" | tr "[:upper:]" "[:lower:]")" "$2"
}

load_droid()
{
    # See https://en.wikipedia.org/wiki/Droid_(font)
    # Old URL was http://android.git.kernel.org/?p=platform/frameworks/base.git;a=blob_plain;f=data/fonts/'
    # Then it was https://github.com/android/platform_frameworks_base/blob/master/data/fonts/
    # but the fonts are no longer in master. Using an older commit instead:
    _W_droid_url="https://github.com/android/platform_frameworks_base/blob/feef9887e8f8eb6f64fc1b4552c02efb5755cdc1/data/fonts/"

    do_droid DroidSans-Bold.ttf        "Droid Sans Bold"         2f529a3e60c007979d95d29794c3660694217fb882429fb33919d2245fe969e9
    do_droid DroidSansFallback.ttf     "Droid Sans Fallback"     05d71b179ef97b82cf1bb91cef290c600a510f77f39b4964359e3ef88378c79d
    do_droid DroidSansJapanese.ttf     "Droid Sans Japanese"     935867c21b8484c959170e62879460ae9363eae91f9b35e4519d24080e2eac30
    do_droid DroidSansMono.ttf         "Droid Sans Mono"         12b552de765dc1265d64f9f5566649930dde4dba07da0251d9f92801e70a1047
    do_droid DroidSans.ttf             "Droid Sans"              f51b88945f4c1b236f44b8d55a2d304316869127e95248c435c23f1e4142a7db
    do_droid DroidSerif-BoldItalic.ttf "Droid Serif Bold Italic" 3fdf15b911c04317e5881ae1e4b9faefcdc4bf4cfb60223597d5c9455c3e4156
    do_droid DroidSerif-Bold.ttf       "Droid Serif Bold"        d28533eed8368f047eb5f57a88a91ba2ffc8b69a2dec5e50fe3f0c11ae3f4d8e
    do_droid DroidSerif-Italic.ttf     "Droid Serif Italic"      8a55a4823886234792991dd304dfa1fa120ae99483ec6c2255597d7d913b9a55
    do_droid DroidSerif-Regular.ttf    "Droid Serif"             22aea9471bea5bce1ec3bf7136c84f075b3d11cf09dffdc3dba05e570094cbde

    unset _W_droid_url
}

#----------------------------------------------------------------

w_metadata eufonts fonts \
    title="Updated fonts for Romanian and Bulgarian" \
    publisher="Microsoft" \
    year="2008" \
    media="download" \
    file1="EUupdate.EXE" \
    installed_file1="$W_FONTSDIR_WIN/trebucbd.ttf"

load_eufonts()
{
    # https://www.microsoft.com/en-us/download/details.aspx?id=16083
    w_download "https://download.microsoft.com/download/a/1/8/a180e21e-9c2b-4b54-9c32-bf7fd7429970/EUupdate.EXE" 464dd2cd5f09f489f9ac86ea7790b7b8548fc4e46d9f889b68d2cdce47e09ea8
    w_try_cabextract -d "$W_TMP" "$W_CACHE"/eufonts/EUupdate.EXE
    w_try_cp_font_files "$W_TMP" "$W_FONTSDIR_UNIX"

    w_register_font arialbd.ttf "Arial Bold"
    w_register_font arialbi.ttf "Arial Bold Italic"
    w_register_font ariali.ttf "Arial Italic"
    w_register_font arial.ttf "Arial"
    w_register_font timesbd.ttf "Times New Roman Bold"
    w_register_font timesbi.ttf "Times New Roman Bold Italic"
    w_register_font timesi.ttf "Times New Roman Italic"
    w_register_font times.ttf "Times New Roman"
    w_register_font trebucbd.ttf "Trebuchet MS Bold"
    w_register_font trebucbi.ttf "Trebuchet MS Bold Italic"
    w_register_font trebucit.ttf "Trebuchet MS Italic"
    w_register_font trebuc.ttf "Trebuchet MS"
    w_register_font verdanab.ttf "Verdana Bold"
    w_register_font verdanai.ttf "Verdana Italian"
    w_register_font verdana.ttf "Verdana"
    w_register_font verdanaz.ttf "Verdana Bold Italic"
}

#----------------------------------------------------------------

w_metadata fakechinese fonts \
    title="Creates aliases for Chinese fonts using WenQuanYi fonts" \
    publisher="wenq.org" \
    year="2009"

load_fakechinese()
{
    w_call wenquanyi
    # Loads Wenquanyi fonts and sets aliases for Microsoft Chinese fonts
    # Reference : https://en.wikipedia.org/wiki/List_of_Microsoft_Windows_fonts

    w_register_font_replacement "Microsoft JhengHei" "WenQuanYi Micro Hei"
    w_register_font_replacement "Microsoft YaHei" "WenQuanYi Micro Hei"
    w_register_font_replacement "SimHei" "WenQuanYi Micro Hei"
    w_register_font_replacement "DFKai-SB" "WenQuanYi Micro Hei"
    w_register_font_replacement "FangSong" "WenQuanYi Micro Hei"
    w_register_font_replacement "KaiTi" "WenQuanYi Micro Hei"
    w_register_font_replacement "PMingLiU" "WenQuanYi Micro Hei"
    w_register_font_replacement "MingLiU" "WenQuanYi Micro Hei"
    w_register_font_replacement "NSimSun" "WenQuanYi Micro Hei"
    w_register_font_replacement "SimKai" "WenQuanYi Micro Hei"
    w_register_font_replacement "SimSun" "WenQuanYi Micro Hei"
}

#----------------------------------------------------------------

w_metadata fakejapanese fonts \
    title="Creates aliases for Japanese fonts using Takao fonts" \
    publisher="Jun Kobayashi" \
    year="2010"

load_fakejapanese()
{
    w_call takao
    # Loads Takao fonts and sets aliases for MS Gothic, MS UI Gothic, and MS PGothic, mainly for Japanese language support
    # Aliases to set:
    # MS Gothic --> TakaoGothic
    # MS UI Gothic --> TakaoGothic
    # MS PGothic --> TakaoPGothic
    # MS Mincho --> TakaoMincho
    # MS PMincho --> TakaoPMincho
    # These aliases were taken from what was listed in Ubuntu's fontconfig definitions.

    w_register_font_replacement "MS Gothic" "TakaoGothic"
    w_register_font_replacement "MS UI Gothic" "TakaoGothic"
    w_register_font_replacement "MS PGothic" "TakaoPGothic"
    w_register_font_replacement "MS Mincho" "TakaoMincho"
    w_register_font_replacement "MS PMincho" "TakaoPMincho"
}

#----------------------------------------------------------------

w_metadata fakejapanese_ipamona fonts \
    title="Creates aliases for Japanese fonts using IPAMona fonts" \
    publisher="Jun Kobayashi" \
    year="2008"

load_fakejapanese_ipamona()
{
    w_call ipamona

    # Aliases to set:
    # MS UI Gothic --> IPAMonaUIGothic
    # MS Gothic (ＭＳ ゴシック) --> IPAMonaGothic
    # MS PGothic (ＭＳ Ｐゴシック) --> IPAMonaPGothic
    # MS Mincho (ＭＳ 明朝) --> IPAMonaMincho
    # MS PMincho (ＭＳ Ｐ明朝) --> IPAMonaPMincho

    jpname_msgothic="$(echo "ＭＳ ゴシック" | iconv -f utf8 -t cp932)"
    jpname_mspgothic="$(echo "ＭＳ Ｐゴシック" | iconv -f utf8 -t cp932)"
    jpname_msmincho="$(echo "ＭＳ 明朝" | iconv -f utf8 -t cp932)"
    jpname_mspmincho="$(echo "ＭＳ Ｐ明朝" | iconv -f utf8 -t cp932)"

    w_register_font_replacement "MS UI Gothic" "IPAMonaUIGothic"
    w_register_font_replacement "MS Gothic" "IPAMonaGothic"
    w_register_font_replacement "MS PGothic" "IPAMonaPGothic"
    w_register_font_replacement "MS Mincho" "IPAMonaMincho"
    w_register_font_replacement "MS PMincho" "IPAMonaPMincho"
    w_register_font_replacement "$jpname_msgothic" "IPAMonaGothic"
    w_register_font_replacement "$jpname_mspgothic" "IPAMonaPGothic"
    w_register_font_replacement "$jpname_msmincho" "IPAMonaMincho"
    w_register_font_replacement "$jpname_mspmincho" "IPAMonaPMincho"
}

#----------------------------------------------------------------

w_metadata fakejapanese_vlgothic fonts \
    title="Creates aliases for Japanese Meiryo fonts using VLGothic fonts" \
    publisher="Project Vine / Daisuke Suzuki" \
    conflicts="meiryo" \
    year="2014"

load_fakejapanese_vlgothic()
{
    w_call vlgothic

    # Aliases to set:
    # Meiryo UI --> VL Gothic
    # Meiryo (メイリオ) --> VL Gothic

    jpname_meiryo="$(echo "メイリオ" | iconv -f utf8 -t cp932)"

    w_register_font_replacement "Meiryo UI" "VL Gothic"
    w_register_font_replacement "Meiryo" "VL Gothic"
    w_register_font_replacement "$jpname_meiryo" "VL Gothic"
}

#----------------------------------------------------------------

w_metadata fakekorean fonts \
    title="Creates aliases for Korean fonts using Baekmuk fonts" \
    publisher="Wooderart Inc. / kldp.net" \
    year="1999"

load_fakekorean()
{
    w_call baekmuk
    # Loads Baekmuk fonts and sets as an alias for Gulim, Dotum, and Batang for Korean language support
    # Aliases to set:
    # Gulim --> Baekmuk Gulim
    # GulimChe --> Baekmuk Gulim
    # Batang --> Baekmuk Batang
    # BatangChe --> Baekmuk Batang
    # Dotum --> Baekmuk Dotum
    # DotumChe --> Baekmuk Dotum

    w_register_font_replacement "Gulim" "Baekmuk Gulim"
    w_register_font_replacement "GulimChe" "Baekmuk Gulim"
    w_register_font_replacement "Batang" "Baekmuk Batang"
    w_register_font_replacement "BatangChe" "Baekmuk Batang"
    w_register_font_replacement "Dotum" "Baekmuk Dotum"
    w_register_font_replacement "DotumChe" "Baekmuk Dotum"
}

#----------------------------------------------------------------

w_metadata ipamona fonts \
    title="IPAMona Japanese fonts" \
    publisher="Jun Kobayashi" \
    year="2008" \
    media="download" \
    file1="opfc-ModuleHP-1.1.1_withIPAMonaFonts-1.0.8.tar.gz" \
    installed_file1="$W_FONTSDIR_WIN/ipag-mona.ttf" \
    homepage="http://www.geocities.jp/ipa_mona/"

load_ipamona()
{
    w_download "https://web.archive.org/web/20190309175311/http://www.geocities.jp/ipa_mona/opfc-ModuleHP-1.1.1_withIPAMonaFonts-1.0.8.tar.gz" ab77beea3b051abf606cd8cd3badf6cb24141ef145c60f508fcfef1e3852bb9d

    w_try_cd "$W_TMP"
    w_try tar -zxf "$W_CACHE/$W_PACKAGE/$file1" "${file1%.tar.gz}/fonts"
    w_try_cp_font_files "${file1%.tar.gz}/fonts" "$W_FONTSDIR_UNIX"

    w_register_font ipagui-mona.ttf "IPAMonaUIGothic"
    w_register_font ipag-mona.ttf "IPAMonaGothic"
    w_register_font ipagp-mona.ttf "IPAMonaPGothic"
    w_register_font ipam-mona.ttf "IPAMonaMincho"
    w_register_font ipamp-mona.ttf "IPAMonaPMincho"
}

#----------------------------------------------------------------

w_metadata liberation fonts \
    title="Red Hat Liberation fonts (Mono, Sans, SansNarrow, Serif)" \
    publisher="Red Hat" \
    year="2008" \
    media="download" \
    file1="liberation-fonts-ttf-1.07.4.tar.gz" \
    installed_file1="$W_FONTSDIR_WIN/liberationmono-bolditalic.ttf"

load_liberation()
{
    # https://pagure.io/liberation-fonts
    w_download "https://releases.pagure.org/liberation-fonts/liberation-fonts-ttf-1.07.4.tar.gz" 61a7e2b6742a43c73e8762cdfeaf6dfcf9abdd2cfa0b099a9854d69bc4cfee5c

    w_try_cd "$W_TMP"
    w_try tar -zxf "$W_CACHE/$W_PACKAGE/$file1"
    w_try_cp_font_files "${file1%.tar.gz}" "$W_FONTSDIR_UNIX"

    w_register_font liberationmono-bolditalic.ttf "Liberation Mono Bold Italic"
    w_register_font liberationmono-bold.ttf "Liberation Mono Bold"
    w_register_font liberationmono-italic.ttf "Liberation Mono Italic"
    w_register_font liberationmono-regular.ttf "Liberation Mono"

    w_register_font liberationsans-bolditalic.ttf "Liberation Sans Bold Italic"
    w_register_font liberationsans-bold.ttf "Liberation Sans Bold"
    w_register_font liberationsans-italic.ttf "Liberation Sans Italic"
    w_register_font liberationsans-regular.ttf "Liberation Sans"

    w_register_font liberationsansnarrow-bolditalic.ttf "Liberation Sans Narrow Bold Italic"
    w_register_font liberationsansnarrow-bold.ttf "Liberation Sans Narrow Bold"
    w_register_font liberationsansnarrow-italic.ttf "Liberation Sans Narrow Italic"
    w_register_font liberationsansnarrow-regular.ttf "Liberation Sans Narrow"

    w_register_font liberationserif-bolditalic.ttf "Liberation Serif Bold Italic"
    w_register_font liberationserif-bold.ttf "Liberation Serif Bold"
    w_register_font liberationserif-italic.ttf "Liberation Serif Italic"
    w_register_font liberationserif-regular.ttf "Liberation Serif"
}

#----------------------------------------------------------------

w_metadata lucida fonts \
    title="MS Lucida Console font" \
    publisher="Microsoft" \
    year="1998" \
    media="download" \
    file1="eurofixi.exe" \
    installed_file1="$W_FONTSDIR_WIN/lucon.ttf"

load_lucida()
{
    w_download "https://ftpmirror.your.org/pub/misc/ftp.microsoft.com/bussys/winnt/winnt-public/fixes/usa/NT40TSE/hotfixes-postSP3/Euro-fix/eurofixi.exe" 41f272a33521f6e15f2cce9ff1e049f2badd5ff0dc327fc81b60825766d5b6c7
    w_try_cabextract -d "$W_TMP" -F "lucon.ttf" "$W_CACHE"/lucida/eurofixi.exe
    w_try_cp_font_files "$W_TMP" "$W_FONTSDIR_UNIX"
    w_register_font lucon.ttf "Lucida Console"
}

#----------------------------------------------------------------

w_metadata opensymbol fonts \
    title="OpenSymbol fonts (replacement for Wingdings)" \
    publisher="OpenOffice.org" \
    year="2017" \
    media="download" \
    file1="fonts-opensymbol_102.2+LibO3.5.4+dfsg2-0+deb7u11_all.deb" \
    installed_file1="$W_FONTSDIR_WIN/opens___.ttf"

load_opensymbol()
{
    # The OpenSymbol fonts are a replacement for the Windows Wingdings font from OpenOffice.org.
    # Need to w_download Debian since I can't find a standalone download from OpenOffice
    # Note: The source download package on debian is for _all_ of OpenOffice, which is 266 MB.
    w_download "https://deb.debian.org/debian-security/pool/updates/main/libr/libreoffice/fonts-opensymbol_102.2+LibO3.5.4+dfsg2-0+deb7u11_all.deb" b105ec27c738f92bd9801962f10fd05125c38224c92e702f84b00cbb482dfce7

    w_try_cd "$W_TMP"
    w_try_ar "$W_CACHE/$W_PACKAGE/$file1" data.tar.xz
    w_try tar -Jxf "$W_TMP/data.tar.xz" ./usr/share/fonts/truetype/openoffice/opens___.ttf
    w_try_cp_font_files "usr/share/fonts/truetype/openoffice" "$W_FONTSDIR_UNIX"
    w_register_font opens___.ttf "OpenSymbol"
}

#----------------------------------------------------------------

w_metadata tahoma fonts \
    title="MS Tahoma font (not part of corefonts)" \
    publisher="Microsoft" \
    year="1999" \
    media="download" \
    file1="IELPKTH.CAB" \
    installed_file1="$W_FONTSDIR_WIN/tahoma.ttf"

load_tahoma()
{
    # Formerly at https://download.microsoft.com/download/ie55sp2/Install/5.5_SP2/WIN98Me/EN-US/IELPKTH.CAB
    w_download https://downloads.sourceforge.net/corefonts/OldFiles/IELPKTH.CAB c1be3fb8f0042570be76ec6daa03a99142c88367c1bc810240b85827c715961a

    w_try_cabextract -d "$W_TMP" "$W_CACHE/$W_PACKAGE/$file1"
    w_try_cp_font_files "$W_TMP" "$W_FONTSDIR_UNIX" "*.TTF"

    w_register_font tahoma.ttf "Tahoma"
    w_register_font tahomabd.ttf "Tahoma Bold"
}

#----------------------------------------------------------------

w_metadata takao fonts \
    title="Takao Japanese fonts" \
    publisher="Jun Kobayashi" \
    year="2010" \
    media="download" \
    file1="takao-fonts-ttf-003.02.01.zip" \
    installed_file1="$W_FONTSDIR_WIN/takaogothic.ttf"

load_takao()
{
    # The Takao font provides Japanese glyphs. May also be needed with fakejapanese function above.
    # See https://launchpad.net/takao-fonts for project page
    w_download "https://launchpad.net/takao-fonts/trunk/003.02.01/+download/takao-fonts-ttf-003.02.01.zip" 2f526a16c7931958f560697d494d8304949b3ce0aef246fb0c727fbbcc39089e
    w_try_unzip "$W_TMP" "$W_CACHE"/takao/takao-fonts-ttf-003.02.01.zip
    w_try_cp_font_files "$W_TMP/takao-fonts-ttf-003.02.01" "$W_FONTSDIR_UNIX"

    w_register_font takaogothic.ttf "TakaoGothic"
    w_register_font takaopgothic.ttf "TakaoPGothic"
    w_register_font takaomincho.ttf "TakaoMincho"
    w_register_font takaopmincho.ttf "TakaoPMincho"
    w_register_font takaoexgothic.ttf "TakaoExGothic"
    w_register_font takaoexmincho.ttf "TakaoExMincho"
}

#----------------------------------------------------------------

w_metadata uff fonts \
    title="Ubuntu Font Family" \
    publisher="Ubuntu" \
    year="2010" \
    media="download" \
    file1="ubuntu-font-family-0.83.zip" \
    installed_file1="$W_FONTSDIR_WIN/ubuntu-r.ttf" \
    homepage="https://launchpad.net/ubuntu-font-family"

load_uff()
{
    w_download "https://assets.ubuntu.com/v1/fad7939b-ubuntu-font-family-0.83.zip" 456d7d42797febd0d7d4cf1b782a2e03680bb4a5ee43cc9d06bda172bac05b42 ubuntu-font-family-0.83.zip
    w_try_unzip "$W_TMP" "$W_CACHE/$W_PACKAGE/$file1"

    w_try_cp_font_files "$W_TMP/$(basename "${file1}" .zip)" "$W_FONTSDIR_UNIX"

    w_register_font ubuntu-bi.ttf "Ubuntu Bold Italic"
    w_register_font ubuntu-b.ttf "Ubuntu Bold"
    w_register_font ubuntu-c.ttf "Ubuntu Condensed"
    w_register_font ubuntu-i.ttf "Ubuntu Italic"
    w_register_font ubuntu-li.ttf "Ubuntu Light Italic"
    w_register_font ubuntu-l.ttf "Ubuntu Light"
    w_register_font ubuntu-mi.ttf "Ubuntu Medium Italic"
    w_register_font ubuntumono-bi.ttf "Ubuntu Mono Bold Italic"
    w_register_font ubuntumono-b.ttf "Ubuntu Mono Bold"
    w_register_font ubuntumono-ri.ttf "Ubuntu Mono Italic"
    w_register_font ubuntumono-r.ttf "Ubuntu Mono"
    w_register_font ubuntu-m.ttf "Ubuntu Medium"
    w_register_font ubuntu-ri.ttf "Ubuntu Italic"
    w_register_font ubuntu-r.ttf "Ubuntu"

}

#----------------------------------------------------------------

w_metadata vlgothic fonts \
    title="VLGothic Japanese fonts" \
    publisher="Project Vine / Daisuke Suzuki" \
    year="2014" \
    media="download" \
    file1="VLGothic-20141206.tar.xz" \
    installed_file1="$W_FONTSDIR_WIN/vl-gothic-regular.ttf" \
    homepage="https://ja.osdn.net/projects/vlgothic"

load_vlgothic()
{
    w_download "https://ja.osdn.net/projects/vlgothic/downloads/62375/VLGothic-20141206.tar.xz" 982040db2f9cb73d7c6ab7d9d163f2ed46d1180f330c9ba2fae303649bf8102d

    w_try_cd "$W_TMP"
    w_try tar -Jxf "$W_CACHE/vlgothic/VLGothic-20141206.tar.xz"
    w_try_cp_font_files "$W_TMP/VLGothic" "$W_FONTSDIR_UNIX"

    w_register_font vl-gothic-regular.ttf "VL Gothic"
    w_register_font vl-pgothic-regular.ttf "VL PGothic"
}

#----------------------------------------------------------------

w_metadata wenquanyi fonts \
    title="WenQuanYi CJK font" \
    publisher="wenq.org" \
    year="2009" \
    media="download" \
    file1="wqy-microhei-0.2.0-beta.tar.gz" \
    installed_file1="$W_FONTSDIR_WIN/wqy-microhei.ttc"

load_wenquanyi()
{
    # See http://wenq.org/enindex.cgi
    # Donate at http://wenq.org/enindex.cgi?Download(en)#MicroHei_Beta if you want to help support free CJK font development
    w_download "https://downloads.sourceforge.net/wqy/wqy-microhei-0.2.0-beta.tar.gz" 2802ac8023aa36a66ea6e7445854e3a078d377ffff42169341bd237871f7213e
    w_try_cd "$W_TMP"
    w_try tar -zxf "$W_CACHE/$W_PACKAGE/$file1"
    w_try_cp_font_files "$W_TMP/wqy-microhei" "$W_FONTSDIR_UNIX" "*.ttc"

    w_register_font wqy-microhei.ttc "WenQuanYi Micro Hei"
}

#----------------------------------------------------------------

w_metadata unifont fonts \
    title="Unifont alternative to Arial Unicode MS" \
    publisher="Roman Czyborra / GNU" \
    year="2008" \
    media="download" \
    file1="unifont-5.1.20080907.zip" \
    installed_file1="$W_FONTSDIR_WIN/unifont.ttf"

load_unifont()
{
    # The GNU Unifont provides glyphs for just about everything in common language.  It is intended for multilingual usage.
    # See http://unifoundry.com/unifont.html for project page
    w_download "http://unifoundry.com/unifont-5.1.20080907.zip" 6ec1176f83769072b09de2bc1fff68ec5d802183304756a372e2419236f5b5ba
    w_try_unzip "$W_TMP" "$W_CACHE/$W_PACKAGE/unifont-5.1.20080907.zip"

    w_try mv -f "$W_TMP/unifont-5.1.20080907.ttf" "$W_TMP/unifont.ttf"

    w_try_cp_font_files "$W_TMP" "$W_FONTSDIR_UNIX"

    w_register_font unifont.ttf "Unifont"
    w_register_font_replacement "Arial Unicode MS" "Unifont"
}

#----------------------------------------------------------------

w_metadata allfonts fonts \
    title="All fonts" \
    publisher="various" \
    year="1998-2010" \
    media="download"

load_allfonts()
{
    # This verb uses reflection, should probably do it portably instead, but that would require keeping it up to date
    for file in "$WINETRICKS_METADATA"/fonts/*.vars
    do
        cmd=$(basename "$file" .vars)
        case $cmd in
            # "fake*" verbs need to be skipped because
            # this "allfonts" verb is intended to only install real fonts and
            # adding font replacements at the same time may invalidate the replacements
            # "pptfonts" can be skipped because it only calls other verbs for installing fonts
            # See https://github.com/Winetricks/winetricks/issues/899
            allfonts|cjkfonts|fake*|pptfonts) ;;
            *) w_call "$cmd";;
        esac
    done
}

#######################
# apps
#######################

#----------------------------------------------------------------

w_metadata 3m_library apps \
    title="3M Cloud Library" \
    publisher="3M Company" \
    year="2015" \
    media="download" \
    file1="cloudLibrary-2.1.1702011951-Setup.exe" \
    installed_exe1="$W_PROGRAMS_X86_WIN/cloudLibrary/cloudLibrary.exe" \
    homepage="https://www.yourcloudlibrary.com/"

load_3m_library()
{
    w_download https://usestrwebaccess.blob.core.windows.net/apps/pc/cloudLibrary-2.1.1702011951-Setup.exe bb3d854cc525c065e7298423bf0019309f4b65497c1d8bc6af09460cd6fcb57f
    w_try_cd "$W_CACHE/$W_PACKAGE"
    w_try "$WINE" "${file1}" $W_UNATTENDED_SLASH_S
}

#----------------------------------------------------------------

w_metadata 7zip apps \
    title="7-Zip 16.02" \
    publisher="Igor Pavlov" \
    year="2016" \
    media="download" \
    file1="7z1602.exe" \
    installed_exe1="$W_PROGRAMS_X86_WIN/7-Zip/7zFM.exe"

load_7zip()
{
    w_download https://sourceforge.net/projects/sevenzip/files/7-Zip/16.02/7z1602.exe 629ce3c424bd884e74aed6b7d87d8f0d75274fb87143b8d6360c5eec41d5f865
    w_try_cd "$W_CACHE/$W_PACKAGE"
    w_try "$WINE" "${file1}" $W_UNATTENDED_SLASH_S
}

#----------------------------------------------------------------

w_metadata abiword apps \
    title="AbiWord 2.8.6" \
    publisher="AbiSource" \
    year="2010" \
    media="download" \
    file1="abiword-setup-2.8.6.exe" \
    installed_exe1="$W_PROGRAMS_X86_WIN/AbiWord/bin/AbiWord.exe"

load_abiword()
{
    w_download https://www.abisource.com/downloads/abiword/2.8.6/Windows/abiword-setup-2.8.6.exe f85c7f32044bbb4d31f1672c86951e35319f8e89fbd6c01ab4c19e960efd9ff8
    w_try_cd "$W_CACHE/$W_PACKAGE"
    w_try "$WINE" abiword-setup-2.8.6.exe $W_UNATTENDED_SLASH_S
}

#----------------------------------------------------------------

w_metadata adobe_diged apps \
    title="Adobe Digital Editions 1.7" \
    publisher="Adobe" \
    year="2011" \
    media="download" \
    file1="setup.exe" \
    installed_exe1="$W_PROGRAMS_X86_WIN/Adobe/Adobe Digital Editions/digitaleditions.exe" \
    homepage="https://www.adobe.com/solutions/ebook/digital-editions.html"

load_adobe_diged()
{
    w_download https://kb2.adobe.com/cps/403/kb403051/attachments/setup.exe 4ebe0fcefbe68900ca6bf499432030c9f8eb8828f8cb5a7e1fd1a16c0eba918e
    # NSIS installer
    w_try "$WINE" "$W_CACHE/$W_PACKAGE/setup.exe" ${W_OPT_UNATTENDED:+ /S}
}

#----------------------------------------------------------------

w_metadata adobe_diged4 apps \
    title="Adobe Digital Editions 4.5" \
    publisher="Adobe" \
    year="2015" \
    media="download" \
    file1="ADE_4.5_Installer.exe" \
    installed_exe1="$W_PROGRAMS_X86_WIN/Adobe/Adobe Digital Editions 4.5/DigitalEditions.exe" \
    homepage="https://www.adobe.com/solutions/ebook/digital-editions.html"

load_adobe_diged4()
{
    w_download https://download.adobe.com/pub/adobe/digitaleditions/ADE_4.5_Installer.exe

    if w_workaround_wine_bug 32323; then
        w_call corefonts
    fi

    if [ ! -x "$(command -v winbindd 2>/dev/null)" ]; then
        w_warn "Adobe Digital Editions 4.5 requires winbind (part of Samba) to be installed, but winbind was not detected."
    fi

    w_call dotnet40

    #w_call win7
    w_try_cd "$W_CACHE/$W_PACKAGE"
    if w_workaround_wine_bug 46019 "Installer fails under wine, manually unpacking it instead"; then
        w_try_7z "${W_PROGRAMS_X86_UNIX}/Adobe/Adobe Digital Editions 4.5" "${file1}" -y
    else
        w_ahk_do "
            SetTitleMatchMode, 2
            run, ${file1} ${W_OPT_UNATTENDED:+ /S}
            winwait, Installing Adobe Digital Editions
            ControlClick, Button1 ; Don't install Norton Internet Security
            ControlClick, Static19 ; Next
        "
    fi
}

#----------------------------------------------------------------

w_metadata autohotkey apps \
    title="AutoHotKey" \
    publisher="autohotkey.org" \
    year="2010" \
    media="download" \
    file1="AutoHotkey104805_Install.exe" \
    installed_exe1="$W_PROGRAMS_X86_WIN/AutoHotkey/AutoHotkey.exe"

load_autohotkey()
{
    w_download https://github.com/AutoHotkey/AutoHotkey/releases/download/v1.0.48.05/AutoHotkey104805_Install.exe 4311c3e7c29ed2d67f415138360210bc2f55ff78758b20b003b91d775ee207b9
    w_try_cd "$W_CACHE/$W_PACKAGE"
    w_try "$WINE" AutoHotkey104805_Install.exe $W_UNATTENDED_SLASH_S
}

#----------------------------------------------------------------

w_metadata busybox apps \
    title="BusyBox FRP-2121" \
    publisher="Ron Yorston / Busybox authors" \
    year="2015" \
    media="download" \
    file1="busybox-w32-FRP-2121-ga316078ad.exe" \
    installed_exe1=""

load_busybox()
{
    # Could use https://frippery.org/files/busybox/busybox.exe, but it hasn't updated in last 3 years..
    w_download https://frippery.org/files/busybox/busybox-w32-FRP-2121-ga316078ad.exe 1bab530f2fd2a9d69528bc2b35ba1f9f75481ae053443b47cb23ad2c2740d887

    if test "$W_ARCH" = "win64"; then
        w_download https://frippery.org/files/busybox/busybox-w64-FRP-2121-ga316078ad.exe dcb2faf17f996fda8d273d513bc195aec615ef468e3d55b8b4dc9c089b22e035
        w_try cp "${W_CACHE}/${W_PACKAGE}/${file1}" "$W_SYSTEM32_DLLS/busybox.exe"
        w_try cp "${W_CACHE}/${W_PACKAGE}/busybox-w64-FRP-2121-ga316078ad.exe" "$W_SYSTEM64_DLLS/busybox.exe"
    else
        w_try cp "${W_CACHE}/${W_PACKAGE}/${file1}" "$W_SYSTEM32_DLLS/busybox.exe"
    fi
}

#----------------------------------------------------------------

w_metadata cmake apps \
    title="CMake 2.8" \
    publisher="Kitware" \
    year="2013" \
    media="download" \
    file1="cmake-2.8.11.2-win32-x86.exe" \
    installed_exe1="$W_PROGRAMS_X86_WIN/CMake 2.8/bin/cmake-gui.exe"

load_cmake()
{
    w_download https://www.cmake.org/files/v2.8/cmake-2.8.11.2-win32-x86.exe cb6a7df8fd6f2eca66512279991f3c2349e3f788477c3be8eaa362d46c21dbf0
    w_try_cd "$W_CACHE/$W_PACKAGE"
    w_try "$WINE" cmake-2.8.11.2-win32-x86.exe $W_UNATTENDED_SLASH_S
}

#----------------------------------------------------------------

w_metadata colorprofile apps \
    title="Standard RGB color profile" \
    publisher="Microsoft" \
    year="2005" \
    media="download" \
    file1="ColorProfile.exe" \
    installed_exe1="c:/windows/system32/spool/drivers/color/sRGB Color Space Profile.icm"

load_colorprofile()
{
    w_download https://download.microsoft.com/download/whistler/hwdev1/1.0/wxp/en-us/ColorProfile.exe d04ac910acdd97abd663f559bebc6440d8d68664bf977ec586035247d7b0f728
    w_try_unzip "$W_TMP" "$W_CACHE"/colorprofile/ColorProfile.exe

    # It's in system32 for both win32/win64
    mkdir -p "$W_WINDIR_UNIX"/system32/spool/drivers/color
    w_try cp -f "$W_TMP/sRGB Color Space Profile.icm" "$W_WINDIR_UNIX"/system32/spool/drivers/color
}

#----------------------------------------------------------------

w_metadata controlpad apps \
    title="MS ActiveX Control Pad" \
    publisher="Microsoft" \
    year="1997" \
    media="download" \
    file1="setuppad.exe" \
    installed_exe1="$W_PROGRAMS_X86_WIN/ActiveX Control Pad/PED.EXE"

load_controlpad()
{
    # https://msdn.microsoft.com/en-us/library/ms968493.aspx
    w_call wsh57
    w_download https://download.microsoft.com/download/activexcontrolpad/install/4.0.0.950/win98mexp/en-us/setuppad.exe eab94091ac391f9bbc8e355a1d231e6a08b8dbbb0f6539245b7f0c58d94f420c
    w_try_cabextract --directory="$W_TMP" "$W_CACHE"/controlpad/setuppad.exe

    echo "If setup says 'Unable to start DDE ...', press Ignore"

    w_try_cd "$W_TMP"
    w_try "$WINE" setup $W_UNATTENDED_SLASH_QT

    if ! test -f "$W_SYSTEM32_DLLS"/FM20.DLL; then
        w_die "Install failed.  Please report,  If you just wanted fm20.dll, try installing art2min instead."
    fi
}

#----------------------------------------------------------------

w_metadata controlspy apps \
    title="Control Spy 6 " \
    publisher="Microsoft" \
    year="2005" \
    media="download" \
    file1="ControlSpyV6.exe" \
    installed_exe1="$W_PROGRAMS_X86_WIN/Microsoft/ControlSpy/ControlSpyV6.exe"

load_controlspy()
{
    # Originally at https://download.microsoft.com/download/a/3/1/a315b133-03a8-4845-b428-ec585369b285/ControlSpy.msi
    # 2019/04/11: changed to https://github.com/pywinauto/pywinauto/blob/master/apps/ControlSpy_20/ControlSpyV6.exe
    # Unfortunately that means no V5 of ControlSpy :/
    w_download https://github.com/pywinauto/pywinauto/blob/master/apps/ControlSpy_20/ControlSpyV6.exe
    w_try mkdir -p "${W_PROGRAMS_X86_UNIX}/Microsoft/ControlSpy"
    w_try cp "${W_CACHE}/${W_PACKAGE}/${file1}" "${W_PROGRAMS_X86_UNIX}/Microsoft/ControlSpy"
}

#----------------------------------------------------------------

# dxdiag is a system component that one usually adds to an existing wineprefix,
# so it belongs in 'dlls', not apps.
w_metadata dxdiag dlls \
    title="DirectX Diagnostic Tool" \
    publisher="Microsoft" \
    year="2010" \
    media="download" \
    file1="../directx9/directx_feb2010_redist.exe" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/dxdiag.exe"

load_dxdiag()
{
    helper_directx_dl

    w_call gmdls

    w_try_cabextract -d "$W_TMP" -L -F dxnt.cab "$W_CACHE"/directx9/$DIRECTX_NAME
    w_try_cabextract -d "$W_SYSTEM32_DLLS" -L -F "dxdiag.exe" "$W_TMP/dxnt.cab"
    mkdir -p "$W_WINDIR_UNIX/help"
    w_try_cabextract -d "$W_WINDIR_UNIX/help" -L -F "dxdiag.chm" "$W_TMP/dxnt.cab"
    w_override_dlls native dxdiag.exe

    if w_workaround_wine_bug 1429; then
        w_call dxdiagn_feb2010
    fi
    if w_workaround_wine_bug 9027; then
        w_call dmband
        w_call dmime
        w_call dmstyle
        w_call dmsynth
        w_call dmusic
    fi
}

#----------------------------------------------------------------

w_metadata emu8086 apps \
    title="emu8086" \
    publisher="emu8086.com" \
    year="2015" \
    media="download" \
    file1="emu8086v408r11.zip" \
    installed_exe1="c:/emu8086/emu8086.exe"

load_emu8086()
{
    w_download http://www.emu8086.com/files/emu8086v408r11.zip d56d6e42fe170c52df5abd6002b1e8fef0b840eb8d8807d77819fe1fc2e17afd
    w_try_unzip "$W_TMP" "$W_CACHE/$W_PACKAGE/$file1"
    w_try "$WINE" "$W_TMP/Setup.exe" $W_UNATTENDED_SLASH_SILENT
}

#----------------------------------------------------------------

w_metadata ev3 apps \
    title="Lego Mindstorms EV3 Home Edition" \
    publisher="Lego" \
    year="2014" \
    media="download" \
    file1="LMS-EV3-WIN32-ENUS-01-02-01-full-setup.exe" \
    installed_exe1="$W_PROGRAMS_X86_WIN/LEGO Software/LEGO MINDSTORMS EV3 Home Edition/MindstormsEV3.exe"

load_ev3()
{
    if w_workaround_wine_bug 40192 "Installing vcrun2005 as Wine does not have MFC80.dll"; then
        w_call vcrun2005
    fi

    if w_workaround_wine_bug 40193 "Installing IE8 as built-in Gecko is not sufficient"; then
        w_call ie8
    fi

    w_call dotnet40

    # 2016/03/22: LMS-EV3-WIN32-ENUS-01-02-01-full-setup.exe c47341f08242f0f6f01996530e7c93bda2d666747ada60ab93fa773a55d40a19

    w_download http://esd.lego.com.edgesuite.net/digitaldelivery/mindstorms/6ecda7c2-1189-4816-b2dd-440e22d65814/public/LMS-EV3-WIN32-ENUS-01-02-01-full-setup.exe c47341f08242f0f6f01996530e7c93bda2d666747ada60ab93fa773a55d40a19

    if [ -n "$W_UNATTENDED_SLASH_Q" ]; then
        quiet="$W_UNATTENDED_SLASH_QB /AcceptLicenses yes"
    else
        quiet=""
    fi

    w_try_cd "$W_CACHE"/"$W_PACKAGE"
    w_try "$WINE" "$file1" ${quiet}

    if w_workaround_wine_bug 40729 "Setting override for urlmon.dll to native to avoid crash"; then
        w_override_dlls native urlmon
    fi
}

#----------------------------------------------------------------

w_metadata firefox apps \
    title="Firefox 51.0" \
    publisher="Mozilla" \
    year="2017" \
    media="download" \
    file1="FirefoxSetup51.0.exe" \
    installed_exe1="$W_PROGRAMS_X86_WIN/Mozilla Firefox/firefox.exe"

load_firefox()
{
    w_download "https://download.mozilla.org/?product=firefox-51.0-SSL&os=win&lang=en-US" 05fa9ae012eca560f42d593e75eb37045a54e4978b665b51f6a61e4a2d376eb8 "$file1"
    w_try_cd "$W_CACHE/$W_PACKAGE"
    w_try "$WINE" "$file1" ${W_OPT_UNATTENDED:+ -ms}
}

#----------------------------------------------------------------

w_metadata fontxplorer apps \
    title="Font Xplorer 1.2.2" \
    publisher="Moon Software" \
    year="2001" \
    media="download" \
    file1="Font_Xplorer_122_Free.exe" \
    installed_file1="$W_PROGRAMS_X86_WIN/Font Xplorer/FXplorer.exe" \
    homepage="http://www.moonsoftware.com/fxplorer.asp"

load_fontxplorer()
{
    w_download http://www.moonsoftware.com/files/legacy/Font_Xplorer_122_Free.exe e3a53841c133e2ecfeb75c7ea277e23011317bb031f8caf423b7e9b7f92d85e0

    w_try_cd "$W_CACHE/fontxplorer"
    w_try "$WINE" Font_Xplorer_122_Free.exe $W_UNATTENDED_SLASH_S
    w_killall "explorer.exe"
}

#----------------------------------------------------------------

w_metadata foobar2000 apps \
    title="foobar2000 v1.4" \
    publisher="Peter Pawlowski" \
    year="2018" \
    media="manual_download" \
    file1="foobar2000_v1.4.exe" \
    installed_exe1="$W_PROGRAMS_X86_WIN/foobar2000/foobar2000.exe"

load_foobar2000()
{
    # 2016/12/21: 1.3.14 - 72d024d258c2f3b6cea62dc47fb613848202e7f33f2331f6b2e0a8e61daffcb6
    # 2018/07/25: 1.4    - 7c048faecfec79f9ec2b332b2c68b25e0d0219b47a7c679fe56f2ec05686a96a

    w_download_manual https://www.foobar2000.org/download foobar2000_v1.4.exe 7c048faecfec79f9ec2b332b2c68b25e0d0219b47a7c679fe56f2ec05686a96a
    w_try_cd "$W_CACHE/$W_PACKAGE"
    w_try "$WINE" "$file1" $W_UNATTENDED_SLASH_S
}

#----------------------------------------------------------------

w_metadata hhw apps \
    title="HTML Help Workshop" \
    publisher="Microsoft" \
    year="2000" \
    media="download" \
    file1="htmlhelp.exe" \
    installed_exe1="$W_PROGRAMS_X86_WIN/HTML Help Workshop/hhw.exe"

load_hhw()
{
    w_call mfc40

    # https://msdn.microsoft.com/en-us/library/windows/desktop/ms669985(v=vs.85).aspx
    w_download https://download.microsoft.com/download/0/A/9/0A939EF6-E31C-430F-A3DF-DFAE7960D564/htmlhelp.exe b2b3140d42a818870c1ab13c1c7b8d4536f22bd994fa90aade89729a6009a3ae

    # htmlhelp.exe automatically runs hhupd.exe. It shows a dialog that says
    # "This computer already has a newer version of HTML Help."
    # because of Wine's built-in hhctrl.ocx and it copys files only when
    # Windows version is "Windows 98", "Windows 95", "Windows NT 4.0",
    # or "Windows NT 3.51". 64-bit prefixes can't use any of them.
    #
    # So we need the following steps:
    #   1. Run htmlhelp.exe to unpack its contents
    #   2. Edit htmlhelp.inf not to run hhupd.exe
    #   3. Run setup.exe
    w_try "$WINE" "$W_CACHE/$W_PACKAGE"/htmlhelp.exe /C "/T:$W_TMP_WIN" $W_UNATTENDED_SLASH_Q
    w_try_cd "$W_TMP"
    w_try sed -i "s/RunPostSetupCommands=HHUpdate//" htmlhelp.inf
    w_try "$WINE" setup.exe

    if w_workaround_wine_bug 7517; then
        w_call itircl
        w_call itss
    fi
}

#----------------------------------------------------------------

w_metadata iceweasel apps \
    title="GNU Icecat 31.7.0" \
    publisher="GNU Foundation" \
    year="2015" \
    media="download" \
    file1="icecat-31.7.0.en-US.win32.zip" \
    installed_exe1="$W_PROGRAMS_X86_WIN/icecat/icecat.exe"

load_iceweasel()
{
    w_download https://ftp.gnu.org/gnu/gnuzilla/31.7.0/icecat-31.7.0.en-US.win32.zip 27d10e63ab9ea4e6995c235b92258b379f79433a06a12e4ad16811801cf81e36
    w_try_unzip "${W_PROGRAMS_X86_UNIX}" "${W_CACHE}/${W_PACKAGE}/${file1}"
}


#----------------------------------------------------------------

w_metadata irfanview apps \
    title="Irfanview" \
    publisher="Irfan Skiljan" \
    year="2016" \
    media="download" \
    file1="iview444_setup.exe" \
    installed_file1="$W_PROGRAMS_X86_WIN/IrfanView/i_view32.exe" \
    homepage="https://www.irfanview.com/"

load_irfanview()
{
    w_download http://download.betanews.com/download/967963863-1/iview444_setup.exe 71b44cd3d14376bbb619b2fe8a632d29200385738dd186680e988ce32662b3d6
    if w_workaround_wine_bug 657 "Installing mfc42"; then
        w_call mfc42
    fi

    w_try_cd "$W_CACHE/$W_PACKAGE"
    if test "$W_OPT_UNATTENDED"; then
        w_ahk_do "
            SetWinDelay 200
            SetTitleMatchMode, 2
            run $file1
            winwait, Setup, This program will install
            winactivate, Setup, This program will install
            Sleep 900
            ControlClick, Button7 ; Uncheck All
            Sleep 900
            ControlClick, Button11 ; Next
            Sleep 900
            winwait, Setup, version
            Sleep 900
            ControlClick, Button11 ; Next
            Sleep 900
            winwait, Setup, associate extensions
            Sleep 900
            ControlClick, Button1 ; Images Only associations
            Sleep 900
            ControlClick, Button16 ; Next
            Sleep 1000
            winwait, Setup, INI
            Sleep 1000
            ControlClick, Button21 ; Next
            Sleep 1000
            winwait, Setup, You want to change
            winactivate, Setup, really
            Sleep 900
            ControlClick, Button1 ; Yes
            Sleep 900
            winwait, Setup, successful
            winactivate, Setup, successful
            Sleep 900
            ControlClick, Button1 ; no load webpage
            Sleep 900
            ControlClick, Button2 ; no start irfanview
            Sleep 900
            ControlClick, Button25 ; done
            Sleep 900
            winwaitclose
        "
    else
        w_try "$WINE" "$file1"
    fi
}

#----------------------------------------------------------------

# FIXME: ie6 always installs to C:/Program Files even if LANG is de_DE.utf-8,
# so we have to hard code that, but that breaks on 64-bit Windows.
w_metadata ie6 dlls \
    title="Internet Explorer 6" \
    publisher="Microsoft" \
    year="2002" \
    media="download" \
    file1="ie60.exe" \
    installed_file1="c:/Program Files/Internet Explorer/iedetect.dll"

load_ie6()
{
    w_package_unsupported_win64

    w_download http://cdn.browserarchive.org/ie/win32/6.0/ie60.exe e34e0557d939e7e83185f5354403df99c92a3f3ff80f5ee0c75f6843eaa6efb2

    w_try_cd "$W_TMP"
    "$WINE" "$W_CACHE/$W_PACKAGE/$file1"

    w_call msls31

    # Unregister Wine IE
    if [ ! -f "$W_SYSTEM32_DLLS"/plugin.ocx ]; then
        w_override_dlls builtin iexplore.exe
        w_try "$WINE" iexplore -unregserver
    fi

    # Change the override to the native so we are sure we use and register them
    w_override_dlls native,builtin iexplore.exe inetcpl.cpl itircl itss jscript mlang mshtml msimtf shdoclc shdocvw shlwapi

    # Remove the fake DLLs, if any
    mv "$W_PROGRAMS_UNIX/Internet Explorer/iexplore.exe" "$W_PROGRAMS_UNIX/Internet Explorer/iexplore.exe.bak"
    for dll in itircl itss jscript mlang mshtml msimtf shdoclc shdocvw shlwapi
    do
        test -f "$W_SYSTEM32_DLLS"/$dll.dll &&
        mv "$W_SYSTEM32_DLLS"/$dll.dll "$W_SYSTEM32_DLLS"/$dll.dll.bak
    done

    # The installer doesn't want to install iexplore.exe in XP mode.
    w_set_winver win2k

    # Workaround https://bugs.winehq.org/show_bug.cgi?id=21009
    # FIXME: seems this didn't get migrated to Github?
    # See also https://code.google.com/p/winezeug/issues/detail?id=78
    rm -f "$W_SYSTEM32_DLLS"/browseui.dll "$W_SYSTEM32_DLLS"/inseng.dll

    # Otherwise regsvr32 crashes later
    rm -f "$W_SYSTEM32_DLLS"/inetcpl.cpl

    # Work around https://bugs.winehq.org/show_bug.cgi?id=25432
    w_try_cabextract -F inseng.dll "$W_TMP/IE 6.0 Full/ACTSETUP.CAB"
    mv inseng.dll "$W_SYSTEM32_DLLS"
    w_override_dlls native inseng

    w_try_cd "$W_TMP/IE 6.0 Full"
    if [ -n "$W_UNATTENDED_SLASH_Q" ]; then
        "$WINE" IE6SETUP.EXE /q:a /r:n /c:"ie6wzd /S:""#e"" /q:a /r:n"
    else
        "$WINE" IE6SETUP.EXE
    fi

    # IE6 exits with 194 to signal a reboot
    status=$?
    case $status in
        0|194) ;;
        *) w_die ie6 installation failed;;
    esac

    # Work around DLL registration bug until ierunonce/RunOnce/wineboot is fixed
    # FIXME: whittle down this list
    w_try_cd "$W_SYSTEM32_DLLS"
    for i in actxprxy.dll browseui.dll browsewm.dll cdfview.dll ddraw.dll \
        dispex.dll dsound.dll iedkcs32.dll iepeers.dll iesetup.dll imgutil.dll \
        inetcomm.dll inetcpl.cpl inseng.dll isetup.dll jscript.dll laprxy.dll \
        mlang.dll mshtml.dll mshtmled.dll msi.dll msident.dll \
        msoeacct.dll msrating.dll mstime.dll msxml3.dll occache.dll \
        ole32.dll oleaut32.dll olepro32.dll pngfilt.dll quartz.dll \
        rpcrt4.dll rsabase.dll rsaenh.dll scrobj.dll scrrun.dll \
        shdocvw.dll shell32.dll vbscript.dll webcheck.dll \
        wshcon.dll wshext.dll asctrls.ocx hhctrl.ocx mscomct2.ocx \
        plugin.ocx proctexe.ocx tdc.ocx webcheck.dll wshom.ocx
    do
        "$WINE" regsvr32 /i $i > /dev/null 2>&1
    done

    # Set windows version back to user's default. Leave at win2k for better rendering (is there a bug for that?)
    w_unset_winver

    # the ie6 we use these days lacks pngfilt, so grab that
    w_call pngfilt
}

#----------------------------------------------------------------

w_metadata ie7 dlls \
    title="Internet Explorer 7" \
    publisher="Microsoft" \
    year="2008" \
    media="download" \
    file1="IE7-WindowsXP-x86-enu.exe" \
    installed_file1="c:/windows/ie7.log"

load_ie7()
{
    w_package_unsupported_win64

    # Unregister Wine IE
    if grep -q -i "wine placeholder" "$W_PROGRAMS_X86_UNIX/Internet Explorer/iexplore.exe"; then
        w_override_dlls builtin iexplore.exe
        w_try "$WINE" iexplore -unregserver
    fi

    # Change the override to the native so we are sure we use and register them
    w_override_dlls native,builtin itircl itss jscript mshtml msimtf shdoclc shdocvw shlwapi urlmon wininet xmllite

    # IE7 installer will check the version number of iexplore.exe which causes IE7 installer to fail on wine-1.9.0+
    w_override_dlls native iexplore.exe

    # Bundled updspapi cannot work on Wine
    w_override_dlls builtin updspapi

    # Remove the fake DLLs from the existing WINEPREFIX
    if [ -f "$W_PROGRAMS_X86_UNIX/Internet Explorer/iexplore.exe" ]; then
        mv "$W_PROGRAMS_X86_UNIX/Internet Explorer/iexplore.exe" "$W_PROGRAMS_X86_UNIX/Internet Explorer/iexplore.exe.bak"
    fi
    for dll in itircl itss jscript mshtml msimtf shdoclc shdocvw shlwapi urlmon
    do
        test -f "$W_SYSTEM32_DLLS"/$dll.dll &&
        mv "$W_SYSTEM32_DLLS"/$dll.dll "$W_SYSTEM32_DLLS"/$dll.dll.bak
    done

    # See https://bugs.winehq.org/show_bug.cgi?id=16013
    # Find instructions to create this file in dlls/wintrust/tests/crypt.c
    w_download https://github.com/Winetricks/winetricks/raw/master/files/winetest.cat 5d18ab44fc289100ccf4b51cf614cc2d36f7ca053e557e2ba973811293c97d38

    # Put a dummy catalog file in place
    mkdir -p "$W_SYSTEM32_DLLS"/catroot/\{f750e6c3-38ee-11d1-85e5-00c04fc295ee\}
    w_try cp -f "$W_CACHE"/ie7/winetest.cat "$W_SYSTEM32_DLLS"/catroot/\{f750e6c3-38ee-11d1-85e5-00c04fc295ee\}/oem0.cat

    # KLUDGE: if / is writable (as on OS X?), having a Z: mapping to it
    # causes ie7 to put temporary directories on Z:\
    # so hide it temporarily.  This is not very robust!
    if test -w /; then
        rm -f "$WINEPREFIX/dosdevices/z:.bak_wt"
        mv "$WINEPREFIX/dosdevices/z:" "$WINEPREFIX/dosdevices/z:.bak_wt"
    fi

    # Install
    w_download https://download.microsoft.com/download/3/8/8/38889DC1-848C-4BF2-8335-86C573AD86D9/IE7-WindowsXP-x86-enu.exe bf5c325bbe3f4174869b2a8ff75f92833e7f7debe64777ed0faf293c7725cbef
    w_try_cd "$W_CACHE/$W_PACKAGE"

    # IE7 requies winxp to install:
    w_set_winver winxp

    "$WINE" IE7-WindowsXP-x86-enu.exe $W_UNATTENDED_SLASH_QUIET

    # IE7 exits with 194 to signal a reboot
    status=$?
    case $status in
        0) ;;
        105) echo "exit status $status - normal, user selected 'restart now'" ;;
        194) echo "exit status $status - normal, user selected 'restart later'" ;;
        *) w_die "exit status $status - $W_PACKAGE installation failed" ;;
    esac

    if test -w /; then
        # END KLUDGE: restore Z:, assuming user didn't kill us
        mv "$WINEPREFIX/dosdevices/z:.bak_wt" "$WINEPREFIX/dosdevices/z:"
    fi

    # Work around DLL registration bug until ierunonce/RunOnce/wineboot is fixed
    # FIXME: whittle down this list
    w_try_cd "$W_SYSTEM32_DLLS"
    for i in actxprxy.dll browseui.dll browsewm.dll cdfview.dll ddraw.dll \
        dispex.dll dsound.dll iedkcs32.dll iepeers.dll iesetup.dll \
        imgutil.dll inetcomm.dll inseng.dll isetup.dll jscript.dll laprxy.dll \
        mlang.dll mshtml.dll mshtmled.dll msi.dll msident.dll \
        msoeacct.dll msrating.dll mstime.dll msxml3.dll occache.dll \
        ole32.dll oleaut32.dll olepro32.dll pngfilt.dll quartz.dll \
        rpcrt4.dll rsabase.dll rsaenh.dll scrobj.dll scrrun.dll \
        shdocvw.dll shell32.dll urlmon.dll vbscript.dll webcheck.dll \
        wshcon.dll wshext.dll asctrls.ocx hhctrl.ocx mscomct2.ocx \
        plugin.ocx proctexe.ocx tdc.ocx webcheck.dll wshom.ocx
    do
        "$WINE" regsvr32 /i $i > /dev/null 2>&1
    done

    # Seeing is believing
    case $WINETRICKS_GUI in
        none)
            w_warn "To start ie7, use the command \"$WINE\" '${W_PROGRAMS_WIN}\\\\Internet Explorer\\\\iexplore'"
            ;;
        *)
            w_warn "Starting ie7.  To start it later, use the command \"$WINE\" '${W_PROGRAMS_WIN}\\\\Internet Explorer\\\\iexplore'"
            "$WINE" "${W_PROGRAMS_WIN}\\Internet Explorer\\iexplore" https://www.microsoft.com/windows/internet-explorer/ie7/ > /dev/null 2>&1 &
            ;;
    esac
}

#----------------------------------------------------------------

w_metadata ie8 dlls \
    title="Internet Explorer 8" \
    publisher="Microsoft" \
    year="2009" \
    media="download" \
    file1="IE8-WindowsXP-x86-ENU.exe" \
    installed_file1="c:/windows/ie8_main.log"

load_ie8()
{
    # Installer itself bails out
    w_package_unsupported_win64

    # Bundled in Windows 7, so refuses to install. Works with XP:
    w_set_winver winxp

    # Unregister Wine IE
    #if [ ! -f "$W_SYSTEM32_DLLS"/plugin.ocx ]; then
    if grep -q -i "wine placeholder" "$W_PROGRAMS_X86_UNIX/Internet Explorer/iexplore.exe"; then
        w_override_dlls builtin iexplore.exe
        w_try "$WINE" iexplore -unregserver
    fi

    w_call msls31

    # Change the override to the native so we are sure we use and register them
    w_override_dlls native,builtin ieproxy itircl itss jscript msctf mshtml shdoclc shdocvw shlwapi urlmon wininet xmllite

    # IE8 installer will check the version number of iexplore.exe which causes IE8 installer to fail on wine-1.9.0+
    w_override_dlls native iexplore.exe

    # Bundled updspapi cannot work on Wine
    w_override_dlls builtin updspapi

    # Remove the fake DLLs from the existing WINEPREFIX
    if [ -f "$W_PROGRAMS_X86_UNIX/Internet Explorer/iexplore.exe" ]; then
        mv "$W_PROGRAMS_X86_UNIX/Internet Explorer/iexplore.exe" "$W_PROGRAMS_X86_UNIX/Internet Explorer/iexplore.exe.bak"
    fi
    for dll in browseui inseng itircl itss jscript msctf mshtml shdoclc shdocvw shlwapi urlmon
    do
        test -f "$W_SYSTEM32_DLLS"/$dll.dll &&
        mv "$W_SYSTEM32_DLLS"/$dll.dll "$W_SYSTEM32_DLLS"/$dll.dll.bak
    done

    # See https://bugs.winehq.org/show_bug.cgi?id=16013
    # Find instructions to create this file in dlls/wintrust/tests/crypt.c
    w_download https://github.com/Winetricks/winetricks/raw/master/files/winetest.cat 5d18ab44fc289100ccf4b51cf614cc2d36f7ca053e557e2ba973811293c97d38

    # Put a dummy catalog file in place
    mkdir -p "$W_SYSTEM32_DLLS"/catroot/\{f750e6c3-38ee-11d1-85e5-00c04fc295ee\}
    w_try cp -f "$W_CACHE"/ie8/winetest.cat "$W_SYSTEM32_DLLS"/catroot/\{f750e6c3-38ee-11d1-85e5-00c04fc295ee\}/oem0.cat

    w_download https://download.microsoft.com/download/C/C/0/CC0BD555-33DD-411E-936B-73AC6F95AE11/IE8-WindowsXP-x86-ENU.exe 5a2c6c82774bfe99b175f50a05b05bcd1fac7e9d0e54db2534049209f50cd6ef
    if [ -n "$W_UNATTENDED_SLASH_QUIET" ]; then
        quiet="$W_UNATTENDED_SLASH_QUIET /forcerestart"
    else
        quiet=""
    fi
    w_try_cd "$W_CACHE/$W_PACKAGE"

    # KLUDGE: if / is writable, having a Z: mapping to it causes ie8 to put temporary directories on Z:\
    # so hide it temporarily.  This is not very robust!
    rm -f "$WINEPREFIX/dosdevices/z:.bak_wt"
    mv "$WINEPREFIX/dosdevices/z:" "$WINEPREFIX/dosdevices/z:.bak_wt"

    # FIXME: There's an option for /updates-noupdates to disable checking for updates, but that
    # forces the install to fail on Wine. Not sure if it's an IE8 or Wine bug...
    # FIXME: can't check status, as it always reports failure on wine?
    "$WINE" IE8-WindowsXP-x86-ENU.exe $quiet
    # END KLUDGE: restore Z:, assuming user didn't kill us
    mv "$WINEPREFIX/dosdevices/z:.bak_wt" "$WINEPREFIX/dosdevices/z:"

    # Work around DLL registration bug until ierunonce/RunOnce/wineboot is fixed
    # FIXME: whittle down this list
    w_try_cd "$W_SYSTEM32_DLLS"
    for i in actxprxy.dll browseui.dll browsewm.dll cdfview.dll ddraw.dll \
        dispex.dll dsound.dll iedkcs32.dll iepeers.dll iesetup.dll \
        imgutil.dll inetcomm.dll isetup.dll jscript.dll laprxy.dll \
        mlang.dll msctf.dll mshtml.dll mshtmled.dll msi.dll msimtf.dll msident.dll \
        msoeacct.dll msrating.dll mstime.dll msxml3.dll occache.dll \
        ole32.dll oleaut32.dll olepro32.dll pngfilt.dll quartz.dll \
        rpcrt4.dll rsabase.dll rsaenh.dll scrobj.dll scrrun.dll \
        shdocvw.dll shell32.dll urlmon.dll vbscript.dll webcheck.dll \
        wshcon.dll wshext.dll asctrls.ocx hhctrl.ocx mscomct2.ocx \
        plugin.ocx proctexe.ocx tdc.ocx uxtheme.dll webcheck.dll wshom.ocx
    do
        "$WINE" regsvr32 /i $i > /dev/null 2>&1
    done

    if w_workaround_wine_bug 25648 "Setting TabProcGrowth=0 to avoid hang"; then
        cat > "$W_TMP"/set-tabprocgrowth.reg <<_EOF_
REGEDIT4

[HKEY_CURRENT_USER\\Software\\Microsoft\\Internet Explorer\\Main]
"TabProcGrowth"=dword:00000000

_EOF_
        w_try_regedit "$W_TMP_WIN"\\set-tabprocgrowth.reg
    fi

    # Builtin ieproxy is in system32, but ie8's lives in Program Files. Native
    # CLSID path will get overwritten on prefix update. Setting ieproxy to
    # native doesn't help because setupapi ignores DLL overrides. To work
    # around this problem, copy native ieproxy to system32.
    w_try cp -f "${W_PROGRAMS_X86_UNIX}/Internet Explorer/ieproxy.dll" "$W_SYSTEM32_DLLS"

    # Seeing is believing
    case $WINETRICKS_GUI in
        none)
            w_warn "To start ie8, use the command \"$WINE\" '${W_PROGRAMS_WIN}\\\\Internet Explorer\\\\iexplore'"
            ;;
        *)
            w_warn "Starting ie8.  To start it later, use the command \"$WINE\" '${W_PROGRAMS_WIN}\\\\Internet Explorer\\\\iexplore'"
            "$WINE" "${W_PROGRAMS_WIN}\\Internet Explorer\\iexplore" https://www.microsoft.com/windows/internet-explorer > /dev/null 2>&1 &
            ;;
    esac

    w_unset_winver
}

#----------------------------------------------------------------

w_metadata kde apps \
    title="KDE on Windows" \
    publisher="various" \
    year="2013" \
    media="download" \
    file1="kdewin-installer-gui-1.0.0.exe" \
    installed_exe1="$W_PROGRAMS_WIN/kde/etc/installer.ini" \
    homepage="https://community.kde.org/Windows" \
    unattended="no"

load_kde()
{
    w_download http://mirrors.mit.edu/kde/stable/kdewin/installer/kdewin-installer-gui-1.0.0.exe 6bc5e0cc9e3418c08b6545300f68de0652ac297cbcdc81fd0ebe04f5934006f5
    mkdir -p "$W_PROGRAMS_UNIX/kde"
    w_try cp "$W_CACHE/kde/${file1}" "$W_PROGRAMS_UNIX/kde"
    w_try_cd "$W_PROGRAMS_UNIX/kde"
    # There's no unattended option, probably because there are so many choices,
    # it's like Cygwin
    w_try "$WINE" "${file1}"
}

#----------------------------------------------------------------

w_metadata kindle apps \
    title="Amazon Kindle" \
    publisher="Amazon" \
    year="2017" \
    media="download" \
    file1="KindleForPC-installer-1.16.44025.exe" \
    installed_exe1="$W_PROGRAMS_WIN/Amazon/Kindle/Kindle.exe" \
    homepage="https://www.amazon.com/kindle-dbs/fd/kcp"

load_kindle()
{
    if w_workaround_wine_bug 43508; then
        w_warn "Using an older version of Kindle (1.16.44025) to work around https://bugs.winehq.org/show_bug.cgi?id=43508"
    fi

    # Originally at: https://s3.amazonaws.com/kindleforpc/44025/KindleForPC-installer-1.16.44025.exe
    w_download https://web.archive.org/web/20160817182927/https://s3.amazonaws.com/kindleforpc/44025/KindleForPC-installer-1.16.44025.exe 2655fa8be7b8f4659276c46ef9f3fede847135bf6e5c1de136c9de7af6cac1e2
    w_try_cd "$W_CACHE/$W_PACKAGE"
    w_try "$WINE" "$file1" ${W_OPT_UNATTENDED:+ /S}

    if w_workaround_wine_bug 35041 && [ -n "$W_TASKSET" ] ; then
        w_warn "You may need to run with $W_TASKSET to avoid a libX11 crash."
    fi

    if w_workaround_wine_bug 29045; then
        w_call corefonts
    fi

    w_warn "If kindle does not load for you, try increasing your open file limit"
}

#----------------------------------------------------------------

w_metadata kobo apps \
    title="Kobo e-book reader" \
    publisher="Kobo" \
    year="2011" \
    media="download" \
    file1="KoboSetup.exe" \
    installed_exe1="$W_PROGRAMS_X86_WIN/Kobo/Kobo.exe" \
    homepage="http://www.borders.com/online/store/MediaView_ereaderapps"

load_kobo()
{
    w_download http://download.kobobooks.com/desktop/1/KoboSetup.exe 721e76c06820058422f06420400a0b1286662196d6178d70c4592fd8034704c4
    w_try_cd "$W_CACHE/$W_PACKAGE"
    w_try "$WINE" "$file1" ${W_OPT_UNATTENDED:+ /S}
}

#----------------------------------------------------------------

w_metadata mingw apps \
    title="Minimalist GNU for Windows, including GCC for Windows" \
    publisher="GNU" \
    year="2013" \
    media="download" \
    file1="mingw-get-setup.exe" \
    installed_exe1="c:/MinGW/bin/gcc.exe" \
    homepage="http://mingw.org/wiki/Getting_Started"

load_mingw()
{
    w_download "$WINETRICKS_SOURCEFORGE/mingw/files/mingw-get-setup.exe" aab27bd5547d35dc159288f3b5b8760f21b0cfec86e8f0032b49dd0410f232bc

    if test "$W_OPT_UNATTENDED"; then
        w_info "FYI: Quiet mode will install these mingw packages: 'gcc msys-base'"
    fi

    w_try_cd "$W_CACHE/$W_PACKAGE"
    w_ahk_do "
        run, $file1
        WinWait, MinGW Installation Manager Setup Tool
        if ( w_opt_unattended > 0 ) {
            WinActivate
            Sleep, 1000
            ControlClick, Button1  ; Install
            ; Window title is blank
            WinWait, , Step 1: Specify Installation Preferences
            Sleep, 1000
            ControlClick, Button10  ; Continue
            Sleep, 1000
            WinWait, , Step 2: Download and Set Up MinGW Installation Manager
            ; This takes a while
            WinWait, , Catalogue update completed
            Sleep, 1000
            ControlClick, Button4  ; Continue
            ; This window appears in background, but isn't active because of another popup
            ; We may need to wait for that to disappear first
            WinWait, MinGW Installation Manager
            Sleep, 1000
            WinClose, MinGW Installation Manager
        }
        WinWaitClose, MinGW Installation Manager
    "

    w_append_path 'C:\MinGW\bin'
    w_try "$WINE" mingw-get update
    w_try "$WINE" mingw-get install gcc msys-base
}

#----------------------------------------------------------------

w_metadata mozillabuild apps \
    title="Mozilla build environment" \
    publisher="Mozilla Foundation" \
    year="2015" \
    media="download" \
    file1="MozillaBuildSetup-2.0.0.exe" \
    installed_file1="c:/mozilla-build/moztools/bin/nsinstall.exe" \
    homepage="https://wiki.mozilla.org/MozillaBuild"

load_mozillabuild()
{
    w_download https://ftp.mozilla.org/pub/mozilla.org/mozilla/libraries/win32/MozillaBuildSetup-2.0.0.exe d5ffe52fe634fb7ed02e61041cc183c3af92039ee74e794f7ae83a408e4cf3f5
    w_try_cd "$W_CACHE/$W_PACKAGE"
    w_try "$WINE" MozillaBuildSetup-2.0.0.exe $W_UNATTENDED_SLASH_S
}

#----------------------------------------------------------------

w_metadata mpc apps \
    title="Media Player Classic - Home Cinema" \
    publisher="doom9 folks" \
    year="2014" \
    media="download" \
    file1="MPC-HC.1.7.5.x86.exe" \
    installed_file1="$W_PROGRAMS_X86_WIN/MPC-HC/mpc-hc.exe" \
    homepage="https://mpc-hc.sourceforge.io/"

load_mpc()
{
    w_download $WINETRICKS_SOURCEFORGE/project/mpc-hc/MPC%20HomeCinema%20-%20Win32/MPC-HC_v1.7.5_x86/MPC-HC.1.7.5.x86.exe 1d690da5b330f723aea4a294d478828395d321b59fc680f2b971e8b16b8bd33d
    w_try_cd "$W_CACHE/$W_PACKAGE"
    w_try "$WINE" MPC-HC.1.7.5.x86.exe ${W_OPT_UNATTENDED:+ /VERYSILENT}
}

#----------------------------------------------------------------

w_metadata mspaint apps \
    title="MS Paint" \
    publisher="Microsoft" \
    year="2010" \
    media="download" \
    file1="WindowsXP-KB978706-x86-ENU.exe" \
    installed_file1="c:/windows/mspaint.exe"

load_mspaint()
{
    if w_workaround_wine_bug 657 "Native mspaint.exe from XP requires mfc42.dll"; then
        w_call mfc42
    fi

    # Originally at: https://download.microsoft.com/download/0/A/4/0A40DF5C-2BAE-4C63-802A-84C33B34AC98/WindowsXP-KB978706-x86-ENU.exe
    # Mirror list: http://www.filewatcher.com/_/?q=WindowsXP-KB978706-x86-ENU.exe
    w_download http://download.windowsupdate.com/msdownload/update/software/secu/2010/01/windowsxp-kb978706-x86-enu_f4e076b3867c2f08b6d258316aa0e11d6822b8d7.exe 93ed34ab6c0d01a323ce10992d1c1ca27d1996fef82f0864d83e7f5ac6f9b24b
    w_try $WINE "$W_CACHE"/mspaint/WindowsXP-KB978706-x86-ENU.exe /q /x:"$W_TMP"/WindowsXP-KB978706-x86-ENU
    w_try cp -f "$W_TMP"/WindowsXP-KB978706-x86-ENU/SP3GDR/mspaint.exe "$W_WINDIR_UNIX"/mspaint.exe
}

#----------------------------------------------------------------

w_metadata mt4 apps \
    title="Meta Trader 4" \
    year="2005" \
    media="download" \
    file1="mt4setup.exe"

load_mt4()
{
    w_download https://web.archive.org/web/20160112133258/https://download.mql5.com/cdn/web/metaquotes.software.corp/mt4/mt4setup.exe?utm_campaign=www.metatrader4.com 96c82266e18cc4ada1bbc0cd0ada74c3a31d18914fb1a36626f4596c8bacb6f0 mt4setup.exe

    if w_workaround_wine_bug 7156 "${title} needs wingdings.ttf, installing opensymbol"; then
        w_call opensymbol
    fi

    # Opens a webpage
    WINEDLLOVERRIDES="winebrowser.exe="
    export WINEDLLOVERRIDES

    # No documented silent install option, unfortunately..
    w_try_cd "$W_CACHE/$W_PACKAGE"
    w_ahk_do "
        Run, ${file1}
        WinWait, MetaTrader Setup, license agreement
        ControlClick, Button1
        Sleep 100
        ControlClick, Button3
        WinWait, MetaTrader Setup, Installation successfully completed
        ControlClick, Button4
        Process, Wait, terminal.exe
        Process, Close, terminal.exe
    "
}

#----------------------------------------------------------------

w_metadata njcwp_trial apps \
    title="NJStar Chinese Word Processor trial" \
    publisher="NJStar" \
    year="2015" \
    media="download" \
    file1="njcwp610sw15918.exe" \
    installed_exe1="$W_PROGRAMS_X86_WIN/NJStar Chinese WP6/NJStar.exe" \
    homepage="https://www.njstar.com/cms/njstar-chinese-word-processor"

load_njcwp_trial()
{
    w_download http://ftp.njstar.com/sw/njcwp610sw15918.exe 7afa6dfc431f058d1397ac7100d5650b97347e1f37f81a2e2d2ee5dfdff4660b
    w_try_cd "$W_CACHE/$W_PACKAGE"
    if test "$W_OPT_UNATTENDED"; then
        w_ahk_do "
        SetTitleMatchMode, 2
        run $file1
        WinWait, Setup, Welcome
        ControlClick Button2 ; next
        WinWait, Setup, License
        ControlClick Button2 ; agree
        WinWait, Setup, Install
        ControlClick Button2 ; install
        WinWait, Setup, Completing
        ControlClick Button4 ; do not launch
        ControlClick Button2 ; finish
        WinWaitClose
        "
    else
        w_try "$WINE" "$file1"
    fi
}

#----------------------------------------------------------------

w_metadata njjwp_trial apps \
    title="NJStar Japanese Word Processor trial" \
    publisher="NJStar" \
    year="2009" \
    media="download" \
    file1="njjwp610sw15918.exe" \
    installed_exe1="$W_PROGRAMS_X86_WIN/NJStar Japanese WP6/NJStarJ.exe" \
    homepage="https://www.njstar.com/cms/njstar-japanese-word-processor"

load_njjwp_trial()
{
    w_download http://ftp.njstar.com/sw/njjwp610sw15918.exe 7f36138c3d19539cb73d757cd42a6f7afebdaf9cfed0cf9bc483c33e519e2a26
    w_try_cd "$W_CACHE/$W_PACKAGE"
    if test "$W_OPT_UNATTENDED"; then
        w_ahk_do "
        SetTitleMatchMode, 2
        run $file1
        WinWait, Setup, Welcome
        ControlClick Button2 ; next
        WinWait, Setup, License
        ControlClick Button2 ; agree
        WinWait, Setup, Install
        ControlClick Button2 ; install
        WinWait, Setup, Completing
        ControlClick Button4 ; do not launch
        ControlClick Button2 ; finish
        WinWaitClose
        "
    else
        w_try "$WINE" "$file1"
    fi
}

#----------------------------------------------------------------

w_metadata nook apps \
    title="Nook for PC (e-book reader)" \
    publisher="Barnes & Noble" \
    year="2011" \
    media="download" \
    file1="bndr2_setup_latest.exe" \
    installed_exe1="$W_PROGRAMS_X86_WIN/Barnes & Noble/BNDesktopReader/BNDReader.exe" \
    homepage="https://www.barnesandnoble.com/h/nook/apps"

load_nook()
{
    # Dates from curl --head
    # 2012/03/07: sha256sum 436616d99f0e2351909ab53d910b505c7a3fca248876ebb835fd7bce4aad9720
    w_download http://images.barnesandnoble.com/PResources/download/eReader2/bndr2_setup_latest.exe 436616d99f0e2351909ab53d910b505c7a3fca248876ebb835fd7bce4aad9720
    w_try_cd "$W_CACHE/$W_PACKAGE"

    # Exits with 199 for some reason..
    "$WINE" "$file1" ${W_OPT_UNATTENDED:+ /S}

    status=$?
    case $status in
        0|199) echo "Successfully installed $W_PACKAGE" ;;
        *) w_die "Failed to install $W_PACKAGE" ;;
    esac
}

#----------------------------------------------------------------

w_metadata npp apps \
    title="Notepad++" \
    publisher="Don Ho" \
    year="2015" \
    media="download" \
    file1="npp.6.7.9.2.Installer.exe" \
    installed_exe1="$W_PROGRAMS_X86_WIN/Notepad++/notepad++.exe"

load_npp()
{
    w_download https://notepad-plus-plus.org/repository/6.x/6.7.9.2/npp.6.7.9.2.Installer.exe cecc981d56d759233b804fa77e70ed62e411aaee58dcb1e53b91909c99d29096
    w_try_cd "$W_CACHE/$W_PACKAGE"
    w_try "$WINE" "${file1}" $W_UNATTENDED_SLASH_S
}

#----------------------------------------------------------------

w_metadata office2003pro apps \
    title="Microsoft Office 2003 Professional" \
    publisher="Microsoft" \
    year="2002" \
    media="cd" \
    file1="setup.exe" \
    installed_exe1="$W_PROGRAMS_X86_WIN/Microsoft Office/Office11/WINWORD.EXE"

load_office2003pro()
{
    w_mount OFFICE11
    w_read_key

    w_ahk_do "
        if ( w_opt_unattended > 0 ) {
            run ${W_ISO_MOUNT_LETTER}:setup.exe /EULA_ACCEPT=YES /PIDKEY=$W_KEY
        } else {
            run ${W_ISO_MOUNT_LETTER}:setup.exe
        }
        SetTitleMatchMode, 2
        WinWait,Microsoft Office 2003 Setup, Welcome
        if ( w_opt_unattended > 0 ) {
            Sleep 500
            WinWait,Microsoft Office 2003 Setup,Key
            Sleep 500
            ControlClick Button1 ; Next
            WinWait,Microsoft Office 2003 Setup,Initials
            Sleep 500
            ControlClick Button1 ; Next
            WinWait,Microsoft Office 2003 Setup,End-User
            Sleep 500
            ControlClick Button1 ; I accept
            ControlClick Button2 ; Next
            WinWait,Microsoft Office 2003 Setup,Recommended
            Sleep 500
            ControlClick Button7 ; Next
            WinWait,Microsoft Office 2003 Setup,Summary
            Sleep 500
            ControlClick Button1 ; Install
        }
        WinWait,Microsoft Office 2003 Setup,Completed
        if ( w_opt_unattended > 0 ) {
            Sleep 500
            ControlClick Button2 ; Finish
        }
        WinWaitClose
    "
}

#----------------------------------------------------------------

w_metadata office2007pro apps \
    title="Microsoft Office 2007 Professional" \
    publisher="Microsoft" \
    year="2006" \
    media="cd" \
    file1="setup.exe" \
    installed_file1="$W_PROGRAMS_X86_WIN/Microsoft Office/Office12/WINWORD.EXE"

load_office2007pro()
{
    if w_workaround_wine_bug 14980 "Using native riched20"; then
        w_override_app_dlls winword.exe n riched20
        w_override_app_dlls excel.exe n riched20
        w_override_app_dlls powerpnt.exe n riched20
        w_override_app_dlls msaccess.exe n riched20
        w_override_app_dlls outlook.exe n riched20
        w_override_app_dlls mspub.exe n riched20
        w_override_app_dlls infopath.exe n riched20
    fi

    w_mount OFFICE12
    w_read_key

    if test $W_OPT_UNATTENDED; then
        # See
        # https://blogs.technet.microsoft.com/office_resource_kit/2009/01/29/configure-a-silent-install-of-the-2007-office-system-with-config-xml/
        # https://www.symantec.com/connect/articles/office-2007-silent-installation-lessons-learned
        cat > "$W_TMP"/config.xml <<__EOF__
<Configuration Product="ProPlus">
<Display Level="none" CompletionNotice="no" SuppressModal="yes" AcceptEula="yes" />
<PIDKEY Value="$W_KEY" />
</Configuration>
__EOF__
        "$WINE" ${W_ISO_MOUNT_LETTER}:setup.exe /config "$W_TMP_WIN"\\config.xml

        status=$?
        case $status in
            0|43) ;;
            78)
                w_die "Installing $W_PACKAGE failed, product key $W_KEY \
    might be wrong. Try again without -q, or put correct key in \
    $W_CACHE/$W_PACKAGE/key.txt and rerun."
                ;;
            *)
                w_die "Installing $W_PACKAGE failed."
                ;;
        esac

    else
        w_try "$WINE" ${W_ISO_MOUNT_LETTER}:setup.exe
    fi
}

#----------------------------------------------------------------

w_metadata office2013pro apps \
    title="Microsoft Office 2013 Professional" \
    publisher="Microsoft" \
    year="2013" \
    media="download" \
    file1="setup.exe" \
    installed_file1="$W_PROGRAMS_X86_WIN/Microsoft Office/Office15/WINWORD.EXE"

load_office2013pro()
{
    w_package_unsupported_win64

    if [ ! -x "$(command -v ntlm_auth 2>/dev/null)" ]; then
        w_die "winbind (part of samba) is required for the installation"
    fi

    # link from https://www.askvg.com/direct-download-link-microsoft-office-2013-professional-plus-free-trial/
    w_download http://care.dlservice.microsoft.com/dl/download/2/9/C/29CC45EF-4CDA-4710-9FB3-1489786570A1/OfficeProfessionalPlus_x86_en-us.img 236f8faae3f979ec72592a63784bba2f0d614916350c44631221b88ae9dae206 "OFFICE15.iso"

    w_set_winver win7

    w_call corefonts
    w_call tahoma

    w_call riched20


    if w_workaround_wine_bug 43581 "Wine has problems parsing some regex strings during installation"; then
        w_call msxml6
    fi

    if w_workaround_wine_bug 38648 "DirectX < 11 has problems with black window after installation" ,3.0; then
        cat > "$W_TMP"/MaxVersionGL.reg <<_EOF_
REGEDIT4

[HKEY_CURRENT_USER\\Software\\Wine\\Direct3D]
"MaxVersionGL"=dword:00030002

_EOF_
        w_try_regedit "$W_TMP_WIN"\\MaxVersionGL.reg
    fi

    case "$WINETRICKS_ISO_MOUNT" in
        # archivemount > 0.8.8: works
        # archivemount <= 0.8.8: cannot finish installation due to path issue
        archivemount)
            _W_last_bad_ver=0.8.8
            _W_tool_ver="$(archivemount --version 2>&1 | head -n 1 | cut -d ' ' -f3)"
            _W_pos_am_ver="$(printf "%s\\n%s" "${_W_tool_ver}" "${_W_last_bad_ver}" | sort -t. -k 1,1n -k 2,2n -k 3,3n | grep -n "^${_W_tool_ver}\$" | cut -d : -f1 | head -n 1)"
            if test "$_W_pos_am_ver" = "2"; then
                W_USE_USERMOUNT=1
            else
                w_warn "archivemount <= $_W_last_bad_ver has path issue and cannot be used."
            fi
            unset _W_last_bad_ver _W_tool_ver _W_pos_am_ver
            ;;
        # fuseiso: works
        # hdiutil: partially tested (only mounting/unmounting and copying files)
        *) W_USE_USERMOUNT=1 ;;
    esac
    w_mount OFFICE15

    if test $W_OPT_UNATTENDED; then
        cat > "$W_TMP"/config.xml <<_EOF_
<Configuration Product="ProPlus">
<Display Level="none" CompletionNotice="no" SuppressModal="yes" AcceptEula="yes" />
</Configuration>
_EOF_
        w_try "$WINE" "${W_ISO_MOUNT_LETTER}:${file1}" /config "$W_TMP_WIN"\\config.xml
    else
        w_try "$WINE" "${W_ISO_MOUNT_LETTER}:${file1}"
    fi

    w_wineserver -w
    w_umount

    w_warn "Microsoft Office 2013 is far away from running stable under wine 3.3. It should not be used in a productive environment."
}

#----------------------------------------------------------------

w_metadata ollydbg110 apps \
    title="OllyDbg" \
    publisher="ollydbg.de" \
    year="2004" \
    media="download" \
    file1="odbg110.zip" \
    installed_file1="c:/ollydbg110/OLLYDBG.EXE" \
    homepage="http://ollydbg.de"

load_ollydbg110()
{
    # The GUI is unreadable without having corefonts installed.
    w_call corefonts

    w_download http://www.ollydbg.de/odbg110.zip 73b1770f28893dab22196eb58d45ede8ddf5444009960ccc0107d09881a7cd1e
    w_try_unzip "$W_DRIVE_C/ollydbg110" "$W_CACHE/$W_PACKAGE"/odbg110.zip
}

#----------------------------------------------------------------

w_metadata ollydbg200 apps \
    title="OllyDbg" \
    publisher="ollydbg.de" \
    year="2010" \
    media="download" \
    file1="odbg200.zip" \
    installed_file1="c:/ollydbg200/ollydbg.exe" \
    homepage="http://ollydbg.de"

load_ollydbg200()
{
    # The GUI is unreadable without having corefonts installed.
    w_call corefonts

    w_download http://www.ollydbg.de/odbg200.zip 93dfd6348323db33f2005fc1fb8ff795256ae91d464dd186adc29c4314ed647c
    w_try_unzip "$W_DRIVE_C/ollydbg200" "$W_CACHE/$W_PACKAGE"/odbg200.zip
}

#----------------------------------------------------------------

w_metadata ollydbg201 apps \
    title="OllyDbg" \
    publisher="ollydbg.de" \
    year="2013" \
    media="download" \
    file1="odbg201.zip" \
    installed_file1="c:/ollydbg201/ollydbg.exe" \
    homepage="http://ollydbg.de"

load_ollydbg201()
{
    # The GUI is unreadable without having corefonts installed.
    w_call corefonts

    w_download http://www.ollydbg.de/odbg201.zip 29244e551be31f347db00503c512058086f55b43c93c1ae93729b15ce6e087a5
    w_try_unzip "$W_DRIVE_C/ollydbg201" "$W_CACHE/$W_PACKAGE"/odbg201.zip

    # ollydbg201 is affected by Wine bug 36012 if debug symbols are available.
    # As a workaround native 'dbghelp' can be installed. We don't do this automatically
    # because for some people it might work even without additional workarounds.
    # Older versions of OllyDbg were not affected by this bug.
}

#----------------------------------------------------------------

w_metadata openwatcom apps \
    title="Open Watcom C/C++ compiler (can compile win16 code!)" \
    publisher="Watcom" \
    year="2010" \
    media="download" \
    file1="open-watcom-c-win32-1.9.exe" \
    installed_file1="c:/WATCOM/owsetenv.bat" \
    homepage="http://www.openwatcom.org"

load_openwatcom()
{
    # 2016/03/11: upstream http://www.openwatcom.org appears to be dead (404)
    w_download ftp://ftp.openwatcom.org/install/open-watcom-c-win32-1.9.exe 040c910aba304fdb5f39b8fe508cd3c772b1da1f91a58179fa0895e0b2bf190b

    if [ -n "$W_UNATTENDED_SLASH_Q" ]; then
        # Options documented at http://bugzilla.openwatcom.org/show_bug.cgi?id=898
        # But they don't seem to work on Wine, so jam them into setup.inf
        # Pick smallest installation that supports 16-bit C and C++
        w_try_cd "$W_TMP"
        cp "$W_CACHE"/openwatcom/open-watcom-c-win32-1.9.exe .
        w_try_unzip . open-watcom-c-win32-1.9.exe setup.inf
        sed -i 's/tools16=.*/tools16=true/' setup.inf
        w_try zip -f open-watcom-c-win32-1.9.exe
        w_try "$WINE" open-watcom-c-win32-1.9.exe -s
    else
        w_try_cd "$W_CACHE/$W_PACKAGE"
        w_try "$WINE" open-watcom-c-win32-1.9.exe
    fi

    if test ! -f "$W_DRIVE_C"/WATCOM/binnt/wcc.exe; then
        w_warn "c:/watcom/binnt/wcc.exe not found; you probably didn't select 16-bit tools, and won't be able to build win16test."
    fi
}

#----------------------------------------------------------------

w_metadata protectionid apps \
    title="Protection ID" \
    publisher="CDKiLLER & TippeX" \
    year="2016" \
    media="manual_download" \
    file1="ProtectionId.685.December.2016.rar" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/protection_id.exe"

load_protectionid()
{
    w_download_manual "https://pid.gamecopyworld.com/" ProtectionId.685.December.2016.rar 27a84d740c9fb96cc866438a2b5cd4afc350affc8b7a0122c28c651af3559aea
    w_try_cd "$W_SYSTEM32_DLLS"
    w_try_unrar "${W_CACHE}/${W_PACKAGE}/${file1}"

    # ProtectionId.685.December.2016 has a different executable name than usual, this may need to be disabled on next update:
    w_try mv Protection_ID.eXe protection_id.exe
}

#----------------------------------------------------------------

w_metadata psdk2003 apps \
    title="MS Platform SDK 2003" \
    publisher="Microsoft" \
    year="2003" \
    media="download" \
    file1="5.2.3790.1830.15.PlatformSDK_Svr2003SP1_rtm.img" \
    installed_file1="$W_PROGRAMS_X86_WIN/Microsoft Platform SDK/SetEnv.Cmd"

load_psdk2003()
{
    w_package_unsupported_win64

    w_call mfc42

    # https://www.microsoft.com/en-us/download/details.aspx?id=15656
    w_download https://download.microsoft.com/download/7/5/e/75ec7f04-4c8c-4f38-b582-966e76602643/5.2.3790.1830.15.PlatformSDK_Svr2003SP1_rtm.img 7ef138b07a8ed2e008371d8602900eb68e86ac2a832d16b53f462a9e64f24d53

    # Unpack ISO (how handy that 7z can do this!)
    # Only the windows version of 7z can handle .img files?
    WINETRICKS_OPT_SHAREDPREFIX=1 w_call 7zip
    w_try_cd "$W_PROGRAMS_X86_UNIX"/7-Zip
    w_try "$WINE" 7z.exe x -y -o"$W_TMP_WIN" "$W_CACHE_WIN\\psdk2003\\5.2.3790.1830.15.PlatformSDK_Svr2003SP1_rtm.img"

    w_try_cd "$W_TMP/Setup"

    # Sanity check...
    w_verify_sha256sum d2605ae6f35a7fcc209e1d8dfbdfdb42afcb61e7d173f58fd608ae31db4ab1e7 PSDK-x86.msi

    w_try "$WINE" msiexec /i PSDK-x86.msi ${W_UNATTENDED_SLASH_QB}
}

#----------------------------------------------------------------

w_metadata psdkwin7 apps \
    title="MS Windows 7 SDK" \
    publisher="Microsoft" \
    year="2009" \
    media="download" \
    file1="winsdk_web.exe" \
    installed_exe1="C:/Program Files/Microsoft SDKs/Windows/v7.0/Bin/SetEnv.Cmd"

load_psdkwin7()
{
    # https://www.microsoft.com/en-us/download/details.aspx?id=3138
    w_call dotnet20
    w_call mfc42   # need mfc42u, or setup will abort
    # don't have a working unattended recipe.  Maybe we'll have to
    # do an AutoHotKey script until Microsoft gets its act together:
    # https://social.msdn.microsoft.com/Forums/windowsdesktop/en-US/c053b616-7d5b-405d-9841-ec465a8e21d5/
    w_download https://download.microsoft.com/download/7/A/B/7ABD2203-C472-4036-8BA0-E505528CCCB7/winsdk_web.exe bb0e3b5d8feb750b3164b657a046f76ff086887719e418f57ce88ada5e8990d5
    w_try_cd "$W_CACHE/$W_PACKAGE"
    if w_workaround_wine_bug 21596; then
        w_warn "When given a choice, select only C++ compilers and headers, the other options don't work yet.  See https://bugs.winehq.org/show_bug.cgi?id=21596"
    fi
    w_try "$WINE" winsdk_web.exe

    if w_workaround_wine_bug 21362; then
        # Assume user installed in default location
        cat > "$W_TMP"/set-psdk7.reg <<_EOF_
REGEDIT4

[HKEY_LOCAL_MACHINE\\Software\\Microsoft\\Microsoft SDKs]

[HKEY_LOCAL_MACHINE\\Software\\Microsoft\\Microsoft SDKs\\Windows]
"CurrentVersion"="v7.0"
"CurrentInstallFolder"="C:\\\\Program Files\\\\Microsoft SDKs\\\\Windows\\\\v7.0\\\\"

[HKEY_LOCAL_MACHINE\\Software\\Microsoft\\Microsoft SDKs\\Windows\\v7.0]
"InstallationFolder"="C:\\\\Program Files\\\\Microsoft SDKs\\\\Windows\\\\v7.0\\\\"
"ProductVersion"="7.0.7600.16385.40715"
"ProductName"="Microsoft Windows SDK for Windows 7 (7.0.7600.16385.40715)"
_EOF_
        w_try_regedit "$W_TMP_WIN"\\set-psdk7.reg
    fi
}

#----------------------------------------------------------------

w_metadata psdkwin71 apps \
    title="MS Windows 7.1 SDK" \
    publisher="Microsoft" \
    year="2010" \
    media="download" \
    file1="winsdk_web.exe" \
    installed_exe1="C:/Program Files/Microsoft SDKs/Windows/v7.1/Bin/SetEnv.Cmd"

load_psdkwin71()
{
    w_call dotnet20
    w_call dotnet40
    w_call mfc42   # need mfc42u, or setup will abort
    # https://www.microsoft.com/en-us/download/details.aspx?id=3138
    w_download https://download.microsoft.com/download/A/6/A/A6AC035D-DA3F-4F0C-ADA4-37C8E5D34E3D/winsdk_web.exe 9ea8d82a66a33946e8673df92d784971b35b8f65ade3e0325855be8490e3d51d

    if w_workaround_wine_bug 21596; then
        w_warn "When given a choice, select only C++ compilers and headers, the other options don't work yet.  See https://bugs.winehq.org/show_bug.cgi?id=21596"
    fi

    # don't have a working unattended recipe.  Maybe we'll have to
    # do an AutoHotKey script until Microsoft gets its act together:
    # https://social.msdn.microsoft.com/Forums/windowsdesktop/en-US/c053b616-7d5b-405d-9841-ec465a8e21d5/
    w_try_cd "$W_CACHE/$W_PACKAGE"
    w_try "$WINE" winsdk_web.exe

    if w_workaround_wine_bug 21362; then
        # Assume user installed in default location
        cat > "$W_TMP"/set-psdk71.reg <<_EOF_
REGEDIT4

[HKEY_LOCAL_MACHINE\\Software\\Microsoft\\Microsoft SDKs]

[HKEY_LOCAL_MACHINE\\Software\\Microsoft\\Microsoft SDKs\\Windows]
"CurrentVersion"="v7.1"
"CurrentInstallFolder"="C:\\\\Program Files\\\\Microsoft SDKs\\\\Windows\\\\v7.1\\\\"

[HKEY_LOCAL_MACHINE\\Software\\Microsoft\\Microsoft SDKs\\Windows\\v7.1]
"InstallationFolder"="C:\\\\Program Files\\\\Microsoft SDKs\\\\Windows\\\\v7.1\\\\"
"ProductVersion"="7.0.7600.0.30514"
"ProductName"="Microsoft Windows SDK for Windows 7 (7.0.7600.0.30514)"

[HKEY_LOCAL_MACHINE\\Software\\Microsoft\\Microsoft SDKs\\Windows\\v7.1\\WinSDKBuild]
"ComponentName"="Microsoft Windows SDK Headers and Libraries"
"InstallationFolder"="C:\\\\Program Files\\\\Microsoft SDKs\\\\Windows\\\\v7.1\\\\"
"ProductVersion"="7.0.7600.0.30514"

[HKEY_LOCAL_MACHINE\\Software\\Microsoft\\Microsoft SDKs\\Windows\\v7.1\\WinSDKTools]
"ComponentName"="Microsoft Windows SDK Headers and Libraries"
"InstallationFolder"="C:\\\\Program Files\\\\Microsoft SDKs\\\\Windows\\\\v7.1\\\\bin\\\\"
"ProductVersion"="7.0.7600.0.30514"

[HKEY_LOCAL_MACHINE\\Software\\Microsoft\\Microsoft SDKs\\Windows\\v7.1\\WinSDKWin32Tools]
"ComponentName"="Microsoft Windows SDK Utilities for Win32 Development"
"InstallationFolder"="C:\\\\Program Files\\\\Microsoft SDKs\\\\Windows\\\\v7.1\\\\bin\\\\"
"ProductVersion"="7.0.7600.0.30514"
_EOF_
        w_try_regedit "$W_TMP_WIN"\\set-psdk71.reg
    fi
}

#----------------------------------------------------------------

w_metadata qq apps \
 title="QQ 8.9.1(Chinese chat app)" \
 publisher="Tencent" \
 year="2017" \
 media="download" \
 file1="QQ8.9.1.exe" \
 file2="QQ.tar.gz"\
 installed_exe1="$W_PROGRAMS_X86_WIN/Tencent/QQ/Bin/QQScLauncher.exe" \
 homepage="https://www.qq.com/" \
 unattended="no"

load_qq()
{
    w_download https://dldir1.qq.com/qqfile/qq/QQ8.9.1/20437/QQ8.9.1.exe 8e0d3ff5264da2d77e2fc011c21048edeebcf082f55f68a301f763c3a15c0d3f
    w_download https://hillwoodhome.net/wine/QQ.tar.gz eb5cd6371eb75ec9e2fc0271199df05cbb9f38a60c2e81d5d8ac7daeb40aba62

    if w_workaround_wine_bug 5162 "Installing native riched20 to work around can't input username."; then
        w_call riched20
    fi

    # Make sure chinese fonts are available
    w_call fakechinese

    # uses mfc42u.dll
    w_call mfc42

    if w_workaround_wine_bug 38171 "Installing desktop file to work around bug"; then
        w_try_cd "$W_TMP/"
        tar -zxf "$W_CACHE/qq/QQ.tar.gz"
        mkdir -p "$HOME/.local/share/applications/wine/Programs/腾讯软件/QQ"
        mkdir -p "$HOME/.local/share/icons/hicolor/48x48/apps"
        mkdir -p "$HOME/.local/share/icons/hicolor/256x256/apps"
        w_try mv QQ/腾讯QQ.desktop ~/.local/share/applications/wine/Programs/腾讯软件/QQ
        w_try mv QQ/48x48/QQ.png ~/.local/share/icons/hicolor/48x48/apps
        w_try mv QQ/256x256/QQ.png ~/.local/share/icons/hicolor/256x256/apps
        # shellcheck disable=SC1001
        echo Exec=env WINEPREFIX="$WINEPREFIX" "$WINE" "$W_PROGRAMS_X86_WIN"\/Tencent\/QQ\/bin\/QQScLauncher.exe >> "$HOME/.local/share/applications/wine/Programs/腾讯软件/QQ/腾讯QQ.desktop"
    fi

    if w_workaround_wine_bug 39657 "Disable ntoskrnl.exe to work around can't be started bug"; then
        w_override_dlls disabled ntoskrnl.exe
    fi

    if w_workaround_wine_bug 37680 "Disable txplatform.exe to work around QQ can't be quit cleanly"; then
        w_override_dlls disabled txplatform.exe
    fi

    w_try_cd "$W_CACHE/$W_PACKAGE"
    w_try "$WINE" "$file1"
}

#----------------------------------------------------------------

w_metadata qqintl apps \
    title="QQ International Instant Messenger 2.11" \
    publisher="Tencent" \
    year="2014" \
    media="download" \
    file1="QQIntl2.11.exe" \
    installed_exe1="$W_PROGRAMS_X86_WIN/Tencent/QQIntl/Bin/QQ.exe" \
    homepage="http://www.imqq.com" \
    unattended="no"

load_qqintl()
{
    w_download https://dldir1.qq.com/qqfile/QQIntl/QQi_PC/QQIntl2.11.exe a08e5d8432ad41745cfe92479a9a0c3328a546c27f05486392ca7b77b1cb02a8

    if w_workaround_wine_bug 33086 "Installing native riched20 to allow typing in username"; then
        w_call riched20
    fi

    if w_workaround_wine_bug 37617 "Installing native wininet to work around crash"; then
        w_call wininet
    fi

    if w_workaround_wine_bug 37680 "Disable txplatform.exe to work around QQ can't be quit cleanly"; then
        w_override_dlls disabled txplatform.exe
    fi

    # Make sure chinese fonts are available
    w_call fakechinese

    # wants mfc80u.dll
    w_call vcrun2005

    w_try_cd "$W_CACHE/$W_PACKAGE"
    w_try "$WINE" "$file1"
}

#----------------------------------------------------------------

w_metadata safari apps \
    title="Safari" \
    publisher="Apple" \
    year="2010" \
    media="download" \
    file1="SafariSetup.exe" \
    installed_exe1="$W_PROGRAMS_X86_WIN/Safari/Safari.exe"

load_safari()
{
    w_download http://appldnld.apple.com.edgesuite.net/content.info.apple.com/Safari5/061-7138.20100607.Y7U87/SafariSetup.exe a5b44032fe9cd0ede8571023912c91b1dcca106ad6a65a822be9ebd405510939

    if test $W_OPT_UNATTENDED; then
        w_warn "Safari's silent install is broken under Wine. See https://bugs.winehq.org/show_bug.cgi?id=23493. You should do a regular install if you want to use Safari."
    fi

    w_try_cd "$W_CACHE/$W_PACKAGE"
    w_try "$WINE_MULTI" SafariSetup.exe $W_UNATTENDED_SLASH_QN
}

#----------------------------------------------------------------

w_metadata sketchup apps \
    title="SketchUp 8" \
    publisher="Google" \
    year="2012" \
    media="download" \
    file1="GoogleSketchUpWEN.exe" \
    installed_exe1="$W_PROGRAMS_X86_WIN/Google/Google SketchUp 8/SketchUp.exe"

load_sketchup()
{
    w_download https://dl.google.com/sketchup/GoogleSketchUpWEN.exe e50c1b36131d72437eb32a124a5208fad22dc22b843683cfb520e1ef172b8352

    w_try_cd "$W_CACHE/$W_PACKAGE"
    w_ahk_do "
        SetTitleMatchMode, 2
        run GoogleSketchUpWEN.exe
        WinWait, SketchUp, Welcome
        if ( w_opt_unattended > 0 ) {
            Sleep 4000
            Send {Enter}
            WinWait, SketchUp, License
            Sleep 1000
            ControlClick Button1 ; accept
            Sleep 1000
            ControlClick Button4 ; Next
            WinWait, SketchUp, Destination
            Sleep 1000
            ControlClick Button1 ; Next
            WinWait, SketchUp, Ready
            Sleep 1000
            ControlClick Button1 ; Install
        }
        WinWait, SketchUp, Completed
        if ( w_opt_unattended > 0 ) {
            Sleep 1000
            ControlClick Button1 ; Finish
        }
        WinWaitClose
    "
}

#----------------------------------------------------------------

w_metadata steam apps \
    title="Steam" \
    publisher="Valve" \
    year="2010" \
    media="download" \
    file1="SteamInstall.msi" \
    installed_exe1="$W_PROGRAMS_X86_WIN/Steam/Steam.exe"

load_steam()
{
    # 2016/10/28: 029f918a29b2b311711788e8a477c8de529c11d7dba3caf99cbbde5a983efdad
    # 2018/06/01: 3bc6942fe09f10ed3447bccdcf4a70ed369366fef6b2c7f43b541f1a3c5d1c51
    w_download http://media.steampowered.com/client/installer/SteamSetup.exe 3bc6942fe09f10ed3447bccdcf4a70ed369366fef6b2c7f43b541f1a3c5d1c51
    w_try_cd "$W_CACHE/$W_PACKAGE"

    # Should be fixed in newer steam versions, since 2012. Commenting out for a while before removing in case users need to revert locally
    #
    # Install corefonts first, so if the user doesn't have cabextract/Wine with cab support, we abort before installing Steam.
    # FIXME: support using Wine's cab support
    #if ! test -f "$W_FONTSDIR_UNIX/Times.TTF" && \
    #    w_workaround_wine_bug 22751 "Installing corefonts to prevent a Steam crash"
    #then
    #    w_call corefonts
    #fi

    if test $W_OPT_UNATTENDED; then
            w_ahk_do "
            run, SteamSetup.exe
            SetTitleMatchMode, 2
            WinWait, Steam, Using Steam
            sleep 1000
            ControlClick, Button2
            WinWait, Steam, Select the language
            sleep 1000
            ControlClick, Button2
            WinWait, Steam, Choose the folder
            sleep 1000
            ControlClick, Button2
            WinWait, Steam, Steam has been installed
            sleep 1000
            ControlClick, Button4
            sleep 1000
            ControlClick, Button2
            WinWaitClose
            "
    else
            w_try "$WINE" SteamSetup.exe
    fi

    # Not all users need this disabled, but let's play it safe for now
    if w_workaround_wine_bug 22053 "Disabling gameoverlayrenderer to prevent game crashes on some machines."; then
        w_override_dlls disabled gameoverlayrenderer
    fi
}

#----------------------------------------------------------------

w_metadata uplay apps \
    title="Uplay" \
    publisher="Ubisoft" \
    year="2013" \
    media="download" \
    file1="UplayInstaller.exe" \
    installed_exe1="$W_PROGRAMS_X86_WIN/Ubisoft/Ubisoft Game Launcher/Uplay.exe"

load_uplay()
{
    # Changes too frequently, don't check anymore
    w_download https://static3.cdn.ubi.com/orbit/launcher_installer/UplayInstaller.exe
    w_try_cd "$W_CACHE/$W_PACKAGE"

    # NSIS installer
    w_try "$WINE" UplayInstaller.exe ${W_OPT_UNATTENDED:+ /S}
}

#----------------------------------------------------------------

w_metadata utorrent apps \
    title="µTorrent 2.2.1" \
    publisher="BitTorrent" \
    year="2011" \
    media="manual_download" \
    file1="utorrent_2.2.1.exe" \
    installed_exe1="c:/windows/utorrent.exe"

load_utorrent()
{
    # BitTorrent client supported on Windows, OS X, Linux through Wine
    # 2012/03/07: sha1sum ec2c086ff784b06e4ff05243164ddb768b81ee32096afed6d5e574ff350b619e
    w_download_manual "https://www.oldapps.com/utorrent.php?old_utorrent=38" utorrent_2.2.1.exe ec2c086ff784b06e4ff05243164ddb768b81ee32096afed6d5e574ff350b619e

    w_try cp -f "$W_CACHE/utorrent/$file1" "$W_WINDIR_UNIX"/utorrent.exe
}

#----------------------------------------------------------------

w_metadata utorrent3 apps \
    title="µTorrent 3.4" \
    publisher="BitTorrent" \
    year="2011" \
    media="download" \
    file1="uTorrent.exe" \
    installed_exe1="c:/users/$LOGNAME/Application Data/uTorrent/uTorrent.exe"

load_utorrent3()
{
    # 2017/03/26: sha256sum 482cfc0759f484ad4e6547cc160ef3f08057cb05969242efd75a51525ab9bd92
    w_download https://download-new.utorrent.com/endpoint/utorrent/os/windows/track/stable/ 482cfc0759f484ad4e6547cc160ef3f08057cb05969242efd75a51525ab9bd92 uTorrent.exe

    w_try_cd "$W_CACHE/$W_PACKAGE"
    # If you don't use /PERFORMINSTALL, it just runs µTorrent
    # FIXME: That's no longer a quiet option, though..
    "$WINE" "$file1" /PERFORMINSTALL /NORUN

    # dang installer exits with status 1 on success
    status=$?
    case $status in
        0|1) ;;
        *) w_die "Note: utorrent installer returned status '$status'.  Aborting." ;;
    esac
}

#----------------------------------------------------------------

w_metadata vc2005express apps \
    title="MS Visual C++ 2005 Express" \
    publisher="Microsoft" \
    year="2005" \
    media="download" \
    file1="VC.iso" \
    installed_exe1="$W_PROGRAMS_X86_WIN/Microsoft Visual Studio 8/Common7/IDE/VCExpress.exe"

load_vc2005express()
{
    # Thanks to https://blogs.msdn.microsoft.com/astebner/2006/03/14/how-to-create-an-installable-layout-for-visual-studio-2005-express-editions/
    # for the recipe
    w_call dotnet20

    # https://blogs.msdn.microsoft.com/astebner/2006/03/14/how-to-create-an-installable-layout-for-visual-studio-2005-express-editions/
    # https://go.microsoft.com/fwlink/?linkid=57034
    w_download https://download.microsoft.com/download/A/9/1/A91D6B2B-A798-47DF-9C7E-A97854B7DD18/VC.iso 5ae700d0285d94ec6df23828c7dc9f5634cd250363bed72e486916af22ff9545

    # Unpack ISO (how handy that 7z can do this!)
    w_try_7z "$W_TMP" "$W_CACHE"/vc2005express/VC.iso

    w_try_cd "$W_TMP"
    if [ -n "$W_UNATTENDED_SLASH_Q" ]; then
        chmod +x Ixpvc.exe
        # Add /qn after ReallySuppress for a really silent install (but then you won't see any errors)

        w_try "$WINE" Ixpvc.exe /t:"$W_TMP_WIN" /q:a /c:"msiexec /i vcsetup.msi VSEXTUI=1 ADDLOCAL=ALL REBOOT=ReallySuppress"

    else
        w_try "$WINE" setup.exe
        w_ahk_do "
            SetTitleMatchMode, 2
            WinWait, Visual C++ 2005 Express Edition Setup
            WinWaitClose, Visual C++ 2005 Express Edition Setup
        "
    fi
}

#----------------------------------------------------------------

w_metadata vc2005expresssp1 apps \
    title="MS Visual C++ 2005 Express SP1" \
    publisher="Microsoft" \
    year="2007" \
    media="download" \
    file1="VS80sp1-KB926748-X86-INTL.exe"

load_vc2005expresssp1()
{
    w_call vc2005express

    # https://www.microsoft.com/en-us/download/details.aspx?id=804
    if w_workaround_wine_bug 37375; then
            w_warn "Installer currently fails"
    fi
    w_download https://download.microsoft.com/download/7/7/3/7737290f-98e8-45bf-9075-85cc6ae34bf1/VS80sp1-KB926748-X86-INTL.exe a959d1ea52674b5338473be32a1370f9ec80df84629a2ed3471aa911b42d9e50
    w_try $WINE "$W_CACHE"/vc2005expresssp1/VS80sp1-KB926748-X86-INTL.exe
}

#----------------------------------------------------------------

w_metadata vc2005trial apps \
    title="MS Visual C++ 2005 Trial" \
    publisher="Microsoft" \
    year="2005" \
    media="download" \
    file1="En_vs_2005_vsts_180_Trial.img" \
    installed_exe1="$W_PROGRAMS_X86_WIN/Microsoft Visual Studio 8/Common7/IDE/devenv.exe"

load_vc2005trial()
{
    w_call dotnet20

    # Without mfc42.dll, pidgen.dll won't load, and the app claims "A trial edition is already installed..."
    w_call mfc42

    w_download https://download.microsoft.com/download/6/f/5/6f5f7a01-50bb-422d-8742-c099c8896969/En_vs_2005_vsts_180_Trial.img 3ae9f611c60c64d82e1fa9c94714aa6b6c10f6c2c05446e14b5afb5a257f86dc

    # Unpack ISO (how handy that 7z can do this!)
    # Only the windows version of 7z can handle .img files?
    WINETRICKS_OPT_SHAREDPREFIX=1 w_call 7zip
    w_try_cd "$W_PROGRAMS_X86_UNIX"/7-Zip
    w_try "$WINE" 7z.exe x -y -o"$W_TMP_WIN" "$W_CACHE_WIN\\vc2005trial\\En_vs_2005_vsts_180_Trial.img"

    w_try_cd "$W_TMP"

    # Sanity check...
    w_verify_sha256sum e1d5ddd4bad46c2efe8105f8d73bd62857f6218942d3b9ac5da0e1a6a0a217e0 vs/wcu/runmsi.exe

    w_try_cd vs/Setup
    w_ahk_do "
        SetTitleMatchMode 2
        run setup.exe
        winwait, Visual Studio, Setup is loading
        if ( w_opt_unattended > 0 ) {
            winwait, Visual Studio, Loading completed
            sleep 1000
            controlclick, button2
            winwait, Visual Studio, Select features
            sleep 1000
            controlclick, button38
            sleep 1000
            controlclick, button40
            winwait, Visual Studio, You have chosen
            sleep 1000
            controlclick, button1
            winwait, Visual Studio, Select features
            sleep 1000
            controlclick, button11
        }
        ; this can take a while
        winwait, Finish Page
        if ( w_opt_unattended > 0 ) {
            sleep 1000
            controlclick, button2
        }
        winwaitclose, Finish Page
    "
}

#----------------------------------------------------------------

w_metadata vc2008express apps \
    title="MS Visual C++ 2008 Express" \
    publisher="Microsoft" \
    year="2008" \
    media="download" \
    file1="VS2008ExpressENUX1397868.iso" \
    installed_exe1="$W_PROGRAMS_X86_WIN/Microsoft Visual Studio 9.0/Common7/IDE/VCExpress.exe"

load_vc2008express()
{
    w_verify_cabextract_available

    w_call dotnet35

    # This is the version without SP1 baked in.  (SP1 requires dotnet35sp1, which doesn't work yet.)
    w_download https://download.microsoft.com/download/8/B/5/8B5804AD-4990-40D0-A6AA-CE894CBBB3DC/VS2008ExpressENUX1397868.iso 632318ef0df5bad58fcb99852bd251243610e7a4d84213c45b4f693605a13ead

    # Unpack ISO
    w_try_7z "$W_TMP" "$W_CACHE"/vc2008express/VS2008ExpressENUX1397868.iso

    # See also https://blogs.msdn.microsoft.com/astebner/2008/04/25/a-simpler-way-to-silently-install-visual-studio-2008-express-editions-with-a-caveat/
    w_try_cd "$W_TMP"/VCExpress
    w_try "$WINE" setup.exe $W_UNATTENDED_SLASH_Q
}

#----------------------------------------------------------------

w_metadata vc2010express apps \
    title="MS Visual C++ 2010 Express" \
    publisher="Microsoft" \
    year="2010" \
    media="download" \
    file1="VS2010Express1.iso" \
    installed_exe1="$W_PROGRAMS_X86_WIN/Microsoft Visual Studio 10.0/Common7/IDE/VCExpress.exe"

load_vc2010express()
{
    # Originally at: https://download.microsoft.com/download/1/E/5/1E5F1C0A-0D5B-426A-A603-1798B951DDAE/VS2010Express1.iso
    # Mirror list at: http://www.filewatcher.com/_/?q=VS2010Express1.iso
    # Formerly at: ftp://www.daba.lv/pub/Programmeeshana/VisualStudio/VS2010Express1.iso a9d5dcdf55e539a06547a8ebbc63d55dc167113e09ee9e42096ab9098313039b
    w_download https://debian.fmi.uni-sofia.bg/~aangelov/VS2010Express1.iso a9d5dcdf55e539a06547a8ebbc63d55dc167113e09ee9e42096ab9098313039b

    # Unpack ISO
    w_try_7z "$W_TMP" "$W_CACHE"/vc2010express/VS2010Express1.iso
    w_try_cd "$W_TMP"/VCExpress

    # Uninstall wine-mono, installer doesn't attempt to install native .Net if mono is installed,
    # Then the installer throws an exception and fails
    # See https://github.com/Winetricks/winetricks/issues/1165
    w_call remove_mono

    # dotnet40 leaves winver at win2k, which causes vc2010 to abort on
    # start because it looks for c:\users\$LOGNAME\Application Data
    w_set_winver winxp

    if w_workaround_wine_bug 12501 "Installing mspatcha to work around bug in SQL Server install"; then
        w_call mspatcha
    fi

    if w_workaround_wine_bug 34627 "Installing Visual C++ 2005 managed runtime to work around bug in SQL Server install"; then
        w_call vcrun2005
    fi

    w_try $WINE setup.exe $W_UNATTENDED_SLASH_Q
}

#----------------------------------------------------------------

w_metadata vlc apps \
    title="VLC media player 2.2.1" \
    publisher="VideoLAN" \
    year="2015" \
    media="download" \
    file1="vlc-2.2.1-win32.exe" \
    installed_file1="$W_PROGRAMS_X86_WIN/VideoLAN/VLC/vlc.exe" \
    homepage="https://www.videolan.org/vlc/"

load_vlc()
{
    w_download https://get.videolan.org/vlc/2.2.1/win32/vlc-2.2.1-win32.exe 2eaa3881b01a2464d2a155ad49cc78162571dececcef555400666c719a60794d
    w_try_cd "$W_CACHE/$W_PACKAGE"
    w_try "$WINE" "$file1" ${W_OPT_UNATTENDED:+ /S}
}

#----------------------------------------------------------------

w_metadata winamp apps \
    title="Winamp" \
    publisher="Radionomy (AOL (Nullsoft))" \
    year="2013" \
    media="download" \
    file1="winamp5666_full_all_redux.exe" \
    installed_exe1="$W_PROGRAMS_X86_WIN/Winamp/winamp.exe" \
    homepage="https://www.winamp.com/"

load_winamp()
{
    w_info "may send information while installing, see https://www.microsoft.com/security/portal/Threat/Encyclopedia/Entry.aspx?threatid=159633"

    w_download https://winampplugins.co.uk/Winamp/winamp5666_full_all_redux.exe ea9a6ba81475d49876d0b8b300d93f28f7959b8e99ce4372dbde746567e14002
    w_try_cd "$W_CACHE/$W_PACKAGE"
    if test $W_OPT_UNATTENDED; then
        w_ahk_do "
            SetWinDelay 500
            SetTitleMatchMode, 2
            Run $file1
            WinWait, Installer Language, Please select
            Sleep 500
            ControlClick, Button1 ; OK
            WinWait, Winamp Installer, Welcome to the Winamp installer
            Sleep 500
            ControlClick, Button2 ; Next
            WinWait, Winamp Installer, License Agreement
            Sleep 500
            ControlClick, Button2 ; I Agree
            WinWait, Winamp Installer, Choose Install Location
            Sleep 500
            ControlClick, Button2 ; Next
            WinWait, Winamp Installer, Choose Components
            Sleep 500
            ControlClick, Button2 ; Next for Full install
            WinWait, Winamp Installer, Choose Start Options
            Sleep 500
            ControlClick, Button4 ; uncheck start menu entry
            Sleep 500
            ControlClick, Button5 ; uncheck ql icon
            Sleep 500
            ControlClick, Button6 ; uncheck deskto icon
            Sleep 500
            ControlClick, Button2 ; Install
            WinWait, Winamp Installer, Installation Complete
            Sleep 500
            ControlClick, Button4 ; uncheck launch when complete
            Sleep 500
            ControlClick, Button2 ; Finish
            WinWaitClose
        "
    else
        w_try "$WINE" "$file1"
    fi
}

#----------------------------------------------------------------

w_metadata wme9 apps \
    title="MS Windows Media Encoder 9 (broken in Wine)" \
    publisher="Microsoft" \
    year="2002" \
    media="download" \
    file1="WMEncoder.exe" \
    installed_file1="$W_PROGRAMS_X86_WIN/Windows Media Components/Encoder/wmenc.exe"

load_wme9()
{
    w_package_unsupported_win64

    # See also https://www.microsoft.com/en-us/download/details.aspx?id=17792
    # Formerly at: https://download.microsoft.com/download/8/1/f/81f9402f-efdd-439d-b2a4-089563199d47/WMEncoder.exe
    # Mirror list: http://www.filewatcher.com/_/?q=WMEncoder.exe
    w_download https://people.ok.ubc.ca/mberger/MiscSW/WMEncoder.exe 19d1610d12b51c969f64703c4d3a76aae30dee526bae715381b5f3369f717d76

    w_try_cd "$W_CACHE/$W_PACKAGE"
    w_try "$WINE" WMEncoder.exe $W_UNATTENDED_SLASH_Q
}

#----------------------------------------------------------------

# helper - not useful by itself
load_wm9codecs()
{
    # Note: must install WMP9 or 10 first, or installer will complain and abort.

    # See https://www.microsoft.com/en-us/download/details.aspx?id=507
    # Used by direct calls from load_wmp9, so we have to specify cache directory.
    # http://birds.camden.rutgers.edu/
    w_download_to wm9codecs http://birds.camden.rutgers.edu/WM9Codecs9x.exe f25adf6529745a772c4fdd955505e7fcdc598b8a031bb0ce7e5856da5e5fcc95
    w_try_cd "$W_CACHE/wm9codecs"
    w_set_winver win2k
    w_try "$WINE" WM9Codecs9x.exe $W_UNATTENDED_SLASH_Q
}

w_metadata wmp9 dlls \
    title="Windows Media Player 9" \
    publisher="Microsoft" \
    year="2003" \
    media="download" \
    file1="MPSetup.exe" \
    installed_file1="$W_SYSTEM32_DLLS_WIN"/l3codeca.acm

load_wmp9()
{
    w_skip_windows wmp9 && return

    # Not really expected to work well yet; see
    # https://appdb.winehq.org/appview.php?versionId=1449

    # This version of Windows Media Player can be installed only on Windows 98 Second Edition, Windows Millennium Edition, Windows 2000, Windows XP(32-bit), and Windows .NET Server(32-bit).
    w_package_unsupported_win64

    w_call wsh57

    w_set_winver win2k

    # See also https://support.microsoft.com/en-us/help/18612/windows-media-player
    w_download https://download.microsoft.com/download/1/b/c/1bc0b1a3-c839-4b36-8f3c-19847ba09299/MPSetup.exe 678c102847c18a92abf13c3fae404c3473a0770c871a046b45efe623c9938fc0

    # remove builtin placeholders to allow update
    rm -f "$W_SYSTEM32_DLLS"/wmvcore.dll "$W_SYSTEM32_DLLS"/wmp.dll
    rm -f "$W_PROGRAMS_X86_UNIX/Windows Media Player/wmplayer.exe"
    # need native overrides to allow update and later checks to succeed
    w_override_dlls native l3codeca.acm wmp wmplayer.exe wmvcore

    # FIXME: should we override quartz?  Builtin crashes when you play
    # anything, but maybe that's bug 30557 and only affects new systems?
    # Wine's pidgen is too stubby, crashes, see Wine bug 31111
    w_override_app_dlls MPSetup.exe native pidgen

    w_try_cd "$W_CACHE"/"$W_PACKAGE"
    w_try "$WINE" MPSetup.exe $W_UNATTENDED_SLASH_Q

    load_wm9codecs

    w_unset_winver
}

#----------------------------------------------------------------

w_metadata wmp10 dlls \
    title="Windows Media Player 10" \
    publisher="Microsoft" \
    year="2006" \
    media="download" \
    file1="MP10Setup.exe" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/l3codecp.acm"

load_wmp10()
{
    w_package_unsupported_win64

    # FIXME: what versions of Windows are really bundled with wmp10?
    w_skip_windows wmp10 && return

    # See https://appdb.winehq.org/appview.php?iVersionId=3212
    w_call wsh57

    # https://www.microsoft.com/en-us/download/details.aspx?id=20426
    w_download https://download.microsoft.com/download/1/2/a/12a31f29-2fa9-4f50-b95d-e45ef7013f87/MP10Setup.exe c1e71784c530035916aad5b09fa002abfbb7569b75208dd79351f29c6d197e03

    w_set_winver winxp

    # remove builtin placeholders to allow update
    rm -f "$W_SYSTEM32_DLLS"/wmvcore.dll "$W_SYSTEM32_DLLS"/wmp.dll
    rm -f "$W_PROGRAMS_X86_UNIX/Windows Media Player/wmplayer.exe"
    # need native overrides to allow update and later checks to succeed
    w_override_dlls native l3codeca.acm wmp wmplayer.exe wmvcore

    # Crashes on exit, but otherwise ok; see https://bugs.winehq.org/show_bug.cgi?id=12633
    w_try_cd "$W_CACHE/$W_PACKAGE"
    w_try "$WINE" MP10Setup.exe $W_UNATTENDED_SLASH_Q

    # Disable WMP's services, since they depend on unimplemented stuff, they trigger the GUI debugger several times
    w_try_regedit /D "HKEY_LOCAL_MACHINE\\System\\CurrentControlSet\\Services\\Cdr4_2K"
    w_try_regedit /D "HKEY_LOCAL_MACHINE\\System\\CurrentControlSet\\Services\\Cdralw2k"

    load_wm9codecs

    w_unset_winver
}

#----------------------------------------------------------------
# Benchmarks
#----------------------------------------------------------------

w_metadata 3dmark2000 benchmarks \
    title="3DMark2000" \
    publisher="MadOnion.com" \
    year="2000" \
    media="download" \
    file1="3dmark2000_v11_100308.exe" \
    installed_file1="$W_PROGRAMS_X86_WIN/MadOnion.com/3DMark2000/3DMark2000.exe"

load_3dmark2000()
{
    # https://www.futuremark.com/download/3dmark2000/
    if ! test -f "$W_CACHE/$W_PACKAGE/3dmark2000_v11_100308.exe"; then
        w_download http://www.ocinside.de/download/3dmark2000_v11_100308.exe 1b392776fd377de8cc6db7c1d8b1565485e20816d1b053de3f16a743e629048d
    fi

    w_try_unzip "$W_TMP/$W_PACKAGE" "$W_CACHE/$W_PACKAGE"/3dmark2000_v11_100308.exe
    w_try_cd "$W_TMP/$W_PACKAGE"
    w_ahk_do "
        SetTitleMatchMode, 2
        run Setup.exe
        WinWait Welcome
        ;ControlClick Button1  ; Next
        Sleep 1000
        Send {Enter}           ; Next
        WinWait License
        ;ControlClick Button2  ; Yes
        Sleep 1000
        Send {Enter}           ; Yes
        ;WinWaitClose ahk_class #32770 ; License
        WinWait ahk_class #32770, Destination
        ;ControlClick Button1  ; Next
        Sleep 1000
        Send {Enter}           ; Next
        ;WinWaitClose ahk_class #32770 ; Destination
        WinWait, Start
        ;ControlClick Button1  ; Next
        Sleep 1000
        Send {Enter}           ; Next
        WinWait Registration
        ControlClick Button1  ; Next
        WinWait Complete
        Sleep 1000
        ControlClick Button1  ; Unclick View Readme
        ;ControlClick Button4  ; Finish
        Send {Enter}           ; Finish
        WinWaitClose
    "
}

#----------------------------------------------------------------

w_metadata 3dmark2001 benchmarks \
    title="3DMark2001" \
    publisher="MadOnion.com" \
    year="2001" \
    media="download" \
    file1="3dmark2001se_330_100308.exe" \
    installed_file1="$W_PROGRAMS_X86_WIN/MadOnion.com/3DMark2001 SE/3DMark2001SE.exe"

load_3dmark2001()
{
    # https://www.futuremark.com/download/3dmark2001/
    if ! test -f "$W_CACHE/$W_PACKAGE"/3dmark2001se_330_100308.exe; then
        w_download http://www.ocinside.de/download/3dmark2001se_330_100308.exe e34dfd32ef8fe8018a6f41f33fc3ab6dba45f2e90881688ac75a18b97dcd8813
    fi

    w_try_cd "$W_CACHE/$W_PACKAGE"
    w_ahk_do "
        SetWinDelay 1000
        SetTitleMatchMode, 2
        run 3dmark2001se_330_100308.exe
        WinWait ahk_class #32770 ; welcome
        if ( w_opt_unattended > 0 ) {
            ControlClick Button2  ; Next
            sleep 5000
            WinWait ahk_class #32770 ; License
            ControlClick Button2  ; Next
            WinWait ahk_class #32770, Destination
            ControlClick Button1  ; Next
            WinWait ahk_class #32770, Start
            ControlClick Button1  ; Next
            WinWait,, Registration
            ControlClick Button2  ; Next
        }
        WinWait,, Complete
        if ( w_opt_unattended > 0 ) {
            ControlClick Button1  ; Unclick View Readme
            ControlClick Button4  ; Finish
        }
        WinWaitClose
    "
}

#----------------------------------------------------------------

w_metadata 3dmark03 benchmarks \
    title="3D Mark 03" \
    publisher="Futuremark" \
    year="2003" \
    media="manual_download" \
    file1="3DMark03_v360_1901.exe" \
    installed_exe1="$W_PROGRAMS_X86_WIN/Futuremark/3DMark03/3DMark03.exe"

load_3dmark03()
{
    # https://www.futuremark.com/benchmarks/3dmark03/download/
    if ! test -f "$W_CACHE/$W_PACKAGE/3DMark03_v360_1901.exe"; then
        w_download_manual https://www.futuremark.com/download/3dmark03/ 3DMark03_v360_1901.exe 86d7f73747944c553e47e6ab5a74138e8bbca07fab8216ae70a61ac7f9a1c468
    fi

    w_try_cd "$W_CACHE/$W_PACKAGE"
    w_warn "Don't use mouse while this installer is running.  Sorry..."
    # This old installer doesn't seem to be scriptable the usual way, so spray and pray.
    w_ahk_do "
        SetTitleMatchMode, 2
        run 3DMark03_v360_1901.exe
        WinWait 3DMark03 - InstallShield Wizard, Welcome
        if ( w_opt_unattended > 0 ) {
            WinActivate
            Send {Enter}
            Sleep 2000
            WinWait 3DMark03 - InstallShield Wizard, License
            WinActivate
            ; Accept license
            Send a
            Send {Enter}
            Sleep 2000
            ; Choose Destination
            Send {Enter}
            Sleep 2000
            ; Begin install
            Send {Enter}
            ; Wait for install to finish
            WinWait 3DMark03, Registration
            ; Purchase later
            Send {Tab}
            Send {Tab}
            Send {Enter}
        }
        WinWait, 3DMark03 - InstallShield Wizard, Complete
        if ( w_opt_unattended > 0 ) {
            ; Uncheck readme
            Send {Space}
            Send {Tab}
            Send {Tab}
            Send {Enter}
        }
        WinWaitClose, 3DMark03 - InstallShield Wizard, Complete
    "
}

#----------------------------------------------------------------

w_metadata 3dmark05 benchmarks \
    title="3D Mark 05" \
    publisher="Futuremark" \
    year="2005" \
    media="download" \
    file1="3dmark05_v130_1901.exe" \
    installed_exe1="$W_PROGRAMS_X86_WIN/Futuremark/3DMark05/3DMark05.exe"

load_3dmark05()
{
    # https://www.futuremark.com/download/3dmark05/
    if ! test -f "$W_CACHE/$W_PACKAGE/3DMark05_v130_1901.exe"; then
        w_download http://www.ocinside.de/download/3dmark05_v130_1901.exe af97f20665090985ee8a4ba83d137e796bfe12e0dfb7fe285712fae198b34334
    fi

    w_try_cd "$W_CACHE/$W_PACKAGE"
    w_ahk_do "
        run 3DMark05_v130_1901.exe
        WinWait ahk_class #32770, Welcome
        if ( w_opt_unattended > 0 ) {
            Send {Enter}
            WinWait, ahk_class #32770, License
            ControlClick Button1 ; Accept
            ControlClick Button4 ; Next
            WinWait, ahk_class #32770, Destination
            ControlClick Button1 ; Next
            WinWait, ahk_class #32770, Install
            ControlClick Button1 ; Install
            WinWait, ahk_class #32770, Purchase
            ControlClick Button4 ; Later
        }
        WinWait, ahk_class #32770, Complete
        if ( w_opt_unattended > 0 ) {
            ControlClick Button1 ; Uncheck view readme
            ControlClick Button3 ; Finish
        }
        WinWaitClose, ahk_class #32770, Complete
    "
    if w_workaround_wine_bug 22392; then
        w_warn "You must run the app with the -nosysteminfo option to avoid a crash on startup"
    fi
}

#----------------------------------------------------------------

w_metadata 3dmark06 benchmarks \
    title="3D Mark 06" \
    publisher="Futuremark" \
    year="2006" \
    media="manual_download" \
    file1="3DMark06_v121_installer.exe" \
    installed_exe1="$W_PROGRAMS_X86_WIN/Futuremark/3DMark06/3DMark06.exe"

load_3dmark06()
{
    w_download_manual https://www.futuremark.com/support/downloads 3DMark06_v121_installer.exe 362ebafd2b9c89a59a233e4328596438b74a32827feb65fe2837154c60a37da3

    w_try_cd "$W_CACHE/$W_PACKAGE"
    w_ahk_do "
        run $file1
        WinWait ahk_class #32770, Welcome
        if ( w_opt_unattended > 0 ) {
            Send {Enter}
            WinWait, ahk_class #32770, License
            ControlClick Button1 ; Accept
            ControlClick Button4 ; Next
            WinWait, ahk_class #32770, Destination
            ControlClick Button1 ; Next
            WinWait, ahk_class #32770, Install
            ControlClick Button1 ; Install
            WinWait ahk_class OpenAL Installer
            ControlClick Button2 ; OK
            WinWait ahk_class #32770
            ControlClick Button1 ; OK
        }
        WinWait, ahk_class #32770, Complete
        if ( w_opt_unattended > 0 ) {
            ControlClick Button1 ; Uncheck view readme
            ControlClick Button3 ; Finish
        }
        WinWaitClose, ahk_class #32770, Complete
    "

    if w_workaround_wine_bug 24417 "Installing shader compiler..."; then
        # "Demo" button doesn't work without this.  d3dcompiler_43 related.
        w_call d3dx9_28
        w_call d3dx9_36
    fi

    if w_workaround_wine_bug 22392; then
        w_warn "You must run the app with the -nosysteminfo option to avoid a crash on startup"
    fi
}

#----------------------------------------------------------------

w_metadata stalker_pripyat_bench benchmarks \
    title="S.T.A.L.K.E.R.: Call of Pripyat benchmark" \
    publisher="GSC Game World" \
    year="2009" \
    media="manual_download" \
    file1="stkcop-bench-setup.exe" \
    installed_exe1="$W_PROGRAMS_X86_WIN/Call Of Pripyat Benchmark/Benchmark.exe"

load_stalker_pripyat_bench()
{
    # Much faster
    w_download_manual http://www.bigdownload.com/games/stalker-call-of-pripyat/pc/stalker-call-of-pripyat-benchmark stkcop-bench-setup.exe 8c810fba1bbb9c58fc01f4f602479886680c9f4b491dd0afe935e27083f54845
    #w_download https://files.gsc-game.com/st/bench/stkcop-bench-setup.exe 8c810fba1bbb9c58fc01f4f602479886680c9f4b491dd0afe935e27083f54845

    w_try_cd "$W_CACHE/$W_PACKAGE"

    # FIXME: a bit fragile, if you're browsing the web while installing, it sometimes gets stuck.
    w_ahk_do "
        SetTitleMatchMode, 2
        run $file1
        WinWait,Setup - Call Of Pripyat Benchmark
        if ( w_opt_unattended > 0 ) {
            sleep 1000
            ControlClick TNewButton1 ; Next
            WinWait,Setup - Call Of Pripyat Benchmark,License
            sleep 1000
            ControlClick TNewRadioButton1 ; accept
            sleep 1000
            ControlClick TNewButton2 ; Next
            WinWait,Setup - Call Of Pripyat Benchmark,Destination
            sleep 1000
            ControlClick TNewButton3 ; Next
            WinWait,Setup - Call Of Pripyat Benchmark,shortcuts
            sleep 1000
            ControlClick TNewButton4 ; Next
            WinWait,Setup - Call Of Pripyat Benchmark,performed
            sleep 1000
            ControlClick TNewButton4 ; Next
            WinWait,Setup - Call Of Pripyat Benchmark,ready
            sleep 1000
            ControlClick, TNewButton4 ; Next  (nah, who reads doc?)
        }
        WinWait,Setup - Call Of Pripyat Benchmark,finished
        if ( w_opt_unattended > 0 ) {
            sleep 1000
            Send {Space}  ; uncheck launch
            sleep 1000
            ControlClick TNewButton4 ; Finish
        }
        WinWaitClose,Setup - Call Of Pripyat Benchmark,finished
    "

    if w_workaround_wine_bug 24868; then
        w_call d3dx9_31
        w_call d3dx9_42
    fi
}

#----------------------------------------------------------------

w_metadata unigine_heaven benchmarks \
    title="Unigen Heaven 2.1 Benchmark" \
    publisher="Unigen" \
    year="2010" \
    media="manual_download" \
    file1="Unigine_Heaven-2.1.msi"

load_unigine_heaven()
{
    w_download_manual "https://www.fileplanet.com/212489/210000/fileinfo/Unigine-'Heaven'-Benchmark-2.1-%28Windows%29" 47113b285253a1ebce04527a31d734c0dfce5724e8d2643c6c1b822a940e7073

    w_try_cd "$W_CACHE/$W_PACKAGE"
    w_ahk_do "
        SetWinDelay 1000
        SetTitleMatchMode, 2
        run msiexec /i $file1
        if ( w_opt_unattended > 0 ) {
            WinWait ahk_class MsiDialogCloseClass
            Send {Enter}
            WinWait ahk_class MsiDialogCloseClass, License
            ControlClick Button1 ; Accept
            ControlClick Button3 ; Accept
            WinWait ahk_class MsiDialogCloseClass, Choose
            ControlClick Button1 ; Typical
            WinWait ahk_class MsiDialogCloseClass, Ready
            ControlClick Button2 ; Install
            ; FIXME: on systems with OpenAL already (Win7?), the next four lines
            ; are not needed.  We should somehow wait for either OpenAL window
            ; *or* Completed window.
            WinWait ahk_class OpenAL Installer
            ControlClick Button2 ; OK
            WinWait ahk_class #32770
            ControlClick Button1 ; OK
        }
        WinWait ahk_class MsiDialogCloseClass, Completed
        if ( w_opt_unattended > 0 ) {
            ControlClick Button1 ; Finish
            Send {Enter}
        }
        winwaitclose
    "
}

#----------------------------------------------------------------

w_metadata wglgears benchmarks \
    title="wglgears" \
    publisher="Clinton L. Jeffery" \
    year="2005" \
    media="download" \
    file1="wglgears.exe" \
    installed_exe1="$W_SYSTEM32_DLLS_WIN/wglgears.exe"

load_wglgears()
{
    # Original site http://www2.cs.uidaho.edu/~jeffery/win32/wglgears.exe is 403 as of 2019/04/07
    w_download https://web.archive.org/web/20091001002702/http://www2.cs.uidaho.edu/~jeffery/win32/wglgears.exe 858ba95ea3c9af4ded1f4100e59b6e8e57024f3efef56304dbd48106e8f2f6f7
    cp "$W_CACHE"/wglgears/wglgears.exe "$W_SYSTEM32_DLLS"
    chmod +x "$W_SYSTEM32_DLLS/wglgears.exe"
}

#----------------------------------------------------------------
# Games
#----------------------------------------------------------------

w_metadata algodoo_demo games \
    title="Algodoo Demo" \
    publisher="Algoryx" \
    year="2009" \
    media="download" \
    file1="Algodoo_1_7_1-Win32.exe" \
    installed_exe1="$W_PROGRAMS_X86_WIN/Algodoo/Algodoo.exe"

load_algodoo_demo()
{
    w_download http://www.algodoo.com/download/Algodoo_1_7_1-Win32.exe 99d3704ac35028fbc74fdf7c59df3f6caf636009bba19bcddf4f7e7797c14d71

    w_try_cd "$W_CACHE/$W_PACKAGE"
    w_ahk_do "
        ; This one's funny... on Wine, keyboard works once you click manually, but until then, only ControlClick seems to work.
        run, Algodoo_1_7_1-Win32.exe
        SetTitleMatchMode, 2
        winwait, Algodoo, Welcome
        if ( w_opt_unattended > 0 ) {
            ControlClick, TNewButton1
            winwait, Algodoo, License
            ;send {Tab}a{Space}{Enter}
            ControlClick, TNewRadioButton1  ; Accept
            ControlClick, TNewButton2  ; Next
            winwait, Algodoo, Destination
            ;send {Enter}
            ControlClick, TNewButton3  ; Next
            winwait, Algodoo, Folder
            ;send {Enter}
            ControlClick, TNewButton4  ; Next
            winwait, Algodoo, Select Additional Tasks
            ;send {Enter}
            ControlClick, TNewButton4  ; Next
            winwait, Algodoo, Ready to Install
            ;send {Enter}
            ControlClick, TNewButton4  ; Next
        }
        winwait, Algodoo, Completing
        if ( w_opt_unattended > 0 ) {
            sleep 500
            send {Space}{Tab}{Space}{Tab}{Space}{Enter}   ; decline to run app or view tutorials
        }
        WinWaitClose, Algodoo, Completing
    "
}

#----------------------------------------------------------------

w_metadata amnesia_tdd_demo games \
    title="Amnesia: The Dark Descent Demo" \
    publisher="Frictional Games" \
    year="2010" \
    media="manual_download" \
    file1="amnesia_tdd_demo_1.0.1.exe" \
    installed_exe1="$W_PROGRAMS_X86_WIN/Amnesia - The Dark Descent Demo/redist/Amnesia.exe"

load_amnesia_tdd_demo()
{
    w_download_manual https://download.cnet.com/Amnesia-The-Dark-Descent-Demo/3000-2097_4-75312743.html amnesia_tdd_demo_1.0.1.exe ee4c07b40bfa59b506d2cee258c5c7a16028e11fc3a2bd243258c6bec8532dbc

    w_try_cd "$W_CACHE/$W_PACKAGE"

    w_ahk_do "
        SetTitleMatchMode, 2
        Run, amnesia_tdd_demo_1.0.1.exe
        if ( w_opt_unattended > 0 ) {
            WinWait,Select Setup Language, language
            ControlClick, TNewButton1
            WinWait, Amnesia - The Dark Descent Demo, Welcome
            ControlClick, TNewButton1
            WinWait, Amnesia - The Dark Descent Demo, License
            ControlClick, TNewRadioButton1
            ControlClick, TNewButton2
            WinWait, Amnesia - The Dark Descent Demo, installed?
            ControlClick, TNewButton3
            WinWait, Folder Does Not Exist, created
            ControlClick, Button1
            WinWait, Amnesia - The Dark Descent Demo, shortcuts
            ControlClick, TNewButton4
            WinWait, Amnesia - The Dark Descent Demo, additional tasks
            ControlClick, TNewButton4
            WinWait, Amnesia - The Dark Descent Demo, ready to begin installing
            ControlClick, TNewButton4
            WinWait, Amnesia - The Dark Descent Demo, finished
            ControlClick, TNewButton4
            WinWaitClose, Amnesia - The Dark Descent Demo, finished
        }
    "
}

#----------------------------------------------------------------

w_metadata aoe3_demo games \
    title="Age of Empires III Trial" \
    publisher="Microsoft" \
    year="2005" \
    media="download" \
    file1="aoe3trial.exe" \
    installed_exe1="$W_PROGRAMS_X86_WIN/Microsoft Games/Age of Empires III Trial/age3.exe"

load_aoe3_demo()
{

    w_download https://http.download.nvidia.com/downloads/nZone/demos/aoe3trial.exe 4ef69289dfa0817ec14942d85ef597835a9d2b09e1506c60b9938b20daa274ad

    w_try_cd "$W_CACHE/$W_PACKAGE"

    w_ahk_do "
        SetTitleMatchMode, 2
        run aoe3trial.exe
        WinWait,Empires,Welcome
        if ( w_opt_unattended > 0 ) {
            sleep 1000
            winactivate          ; else next button click ignored on vista?
            Sleep 500
            ControlClick Button1 ; Next
            WinWait,Empires,Please
            Sleep 500
            ControlClick Button4 ; Next
            WinWait,Empires,Complete
            Sleep 500
            ControlClick Button4 ; Finish
        }
        WinWaitClose
    "

    if w_workaround_wine_bug 24912; then
        # kill off lingering installer
        w_ahk_do "
            SetTitleMatchMode, 2
            WinKill,Empires
        "
        # or should we just do w_wineserver -k, like fable_tlc does?
        # shellcheck disable=SC2046
        kill $(pgrep -f IDriver)
    fi
}

#----------------------------------------------------------------

w_metadata acreedbro games \
    title="Assassin's Creed Brotherhood" \
    publisher="Ubisoft" \
    year="2011" \
    media="dvd" \
    file1="ACB.iso" \
    installed_exe1="$W_PROGRAMS_X86_WIN/Ubisoft/Assassin's Creed Brotherhood/AssassinsCreedBrotherhood.exe"

load_acreedbro()
{
    w_mount ACB
    w_read_key
    w_ahk_do "
        SetWinDelay 1000
        SetTitleMatchMode, 2
        run ${W_ISO_MOUNT_LETTER}:setup.exe
        winwait, Brotherhood, Choose
        if ( w_opt_unattended > 0 ) {
            WinActivate
            send {Enter}
            ;ControlClick, Button3   ; Accept default (english)
            winwait, Brotherhood, Welcome
            WinActivate
            send {Enter}   ; Next
            winwait, Brotherhood, License
            WinActivate
            send a         ; Agree
            sleep 500
            send {Enter}   ; Next
            winwait, Brotherhood, begin
            send {Enter}   ; Install
        }
        winwait, Brotherhood, Finish
        if ( w_opt_unattended > 0 ) {
            ControlClick Button4
            send {Enter}   ; Finish
        }
        WinWaitClose
    "

    w_download https://static3.cdn.ubi.com/ac_brotherhood/ac_brotherhood_1.01_ww.exe a8027b08840a7438a0bd1a1c17f962fcc386a2cb9fd1d3055de2486bf95778c2

    # FIXME: figure out why these executables don't exit, and do a proper workaround or fix
    sleep 10
    # shellcheck disable=SC2009
    if ps augxw | grep -i exe | grep -E 'winemenubuilder.exe|setup.exe|PnkBstrA.exe | grep -v grep'; then
        w_warn "Killing processes so patcher does not complain about game still running"
        w_wineserver -k
        sleep 10
    fi

    w_info "Applying patch $W_CACHE/$W_PACKAGE/ac_brotherhood_1.01_ww.exe..."

    w_try_cd "$W_CACHE/$W_PACKAGE"
    w_ahk_do "
        SetWinDelay 1000
        SetTitleMatchMode, 2
        run ac_brotherhood_1.01_ww.exe
        WinWait, Choose Setup Language, Select
        if ( w_opt_unattended > 0 ) {
            send {Enter}
            winwait, Brotherhood 1.01, License
            WinActivate
            send a         ; Agree
            sleep 500
            send {Enter}   ; Next
            winwait, Brotherhood 1.01, Details
            ControlClick Button1  ; Next
        }
        winwait, Brotherhood 1.01, Complete
        if ( w_opt_unattended > 0 ) {
            send {Enter}
        }
        WinWaitClose
    "
}

#----------------------------------------------------------------

w_metadata atmosphir games \
    title="Atmosphir" \
    publisher="Minor Studios" \
    year="2011" \
    media="manual_download" \
    file1="Atmosphir Installer v1.0.0 fixed.exe" \
    installed_exe1="$W_PROGRAMS_X86_WIN/Minor Studios/Atmosphir/Atmosphir.exe" \
    homepage="http://www.atmosphir.com"

load_atmosphir()
{
    w_download_manual https://download.cnet.com/Atmosphir/3000-7492_4-75335647.html atmosphir-installer-v1.0.2.exe a6b2c82a98d750014874f8ab445b38ebb127450e5a7a9350832cf3a8d3a

    w_try_cd "$W_CACHE/$W_PACKAGE"
    w_ahk_do "
        run Atmosphir Installer v1.0.0 fixed.exe
        winwait, Atmosphir Setup, Welcome
        if ( w_opt_unattended > 0 ) {
            sleep 1000
            ControlClick Button2
            winwait, Atmosphir Setup, License Agreement
            sleep 1000
            ControlClick Button2
            winwait, Atmosphir Setup, Choose Install Location
            sleep 1000
            ControlClick Button2
            winwait, Atmosphir Setup, Choose Start Menu Folder
            sleep 1000
            ControlClick Button2
        }
        winwait, Atmosphir Setup, Installation complete
        if ( w_opt_unattended > 0 ) {
            sleep 1000
            send {Space}  ; ControlClick Button4    # start
            sleep 1000
            ControlClick Button2
            ; Let the launcher do the initial full download
            winwait, Atmosphir Launcher
            winwaitclose
            ; then kill the game when it starts
            winwait, Atmosphir
            ;winkill          ; doesn't work, game traps it
            winclose
        }
        winwaitclose
    "
}

#----------------------------------------------------------------

w_metadata avatar_demo games \
    title="James Camerons Avatar: The Game Demo" \
    publisher="Ubisoft" \
    year="2009" \
    media="manual_download" \
    file1="Avatar_The_Game_Demo.exe" \
    installed_exe1="$W_PROGRAMS_X86_WIN/Ubisoft/Demo/James Cameron's AVATAR - THE GAME (Demo)/bin/AvatarDemo.exe"

load_avatar_demo()
{
    w_download_manual https://www.fileplanet.com/207386/200000/fileinfo/Avatar:-The-Game-Demo Avatar_The_Game_Demo.exe aec9cf718f9584edc23044ff94996d4e7309654d50fcea91cba4282576a1e9c8

    if w_workaround_wine_bug 23094 "Installing Visual C++ 2005 runtime to avoid installer crash"; then
        w_call vcrun2005
    fi

    w_try_cd "$W_TMP"
    w_try_unrar "$W_CACHE/$W_PACKAGE/Avatar_The_Game_Demo.exe"
    w_ahk_do "
        SetTitleMatchMode, 2
        SetWinDelay 500
        run, setup.exe
        winwait, Language
        u = $W_OPT_UNATTENDED
        if ( u > 0 ) {
            WinActivate
            controlclick, Button1
            winwait, AVATAR, Welcome
            controlclick, Button1
            winwait, AVATAR, License
            controlclick, Button5
            controlclick, Button2
            winwait, AVATAR, setup type
            controlclick, Button2
        }
        winwait AVATAR
        if ( u > 0 ) {
            ; Strange CRC error workaround. Will check this out. Stay tuned.
            loop
            {
                ifwinexist, CRC Error
                {
                    winactivate, CRC Error
                    controlclick, Button3, CRC Error ; ignore
                }
                ifwinexist, AVATAR, Complete
                {
                    controlclick, Button4
                    break
                }
                sleep 1000
            }
        }
        winwaitclose AVATAR
    "
}

#----------------------------------------------------------------

w_metadata bttf101 games \
    title="Back to the Future Episode 1" \
    publisher="Telltale" \
    year="2011" \
    media="manual_download" \
    file1="bttf_101_setup.exe" \
    installed_exe1="$W_PROGRAMS_X86_WIN/Telltale Games/Back to the Future The Game/Episode 1/BackToTheFuture101.exe"

load_bttf101()
{
    w_download_manual "https://www.fileplanet.com/220151/220000/fileinfo/Back-to-the-Future:-The-Game---Episode-1-Client-%28Free-Game%29" bttf_101_setup.exe 8ad05063c5dae096697665ac36578f885937829ec7dac6a3a3644c76820e999c

    w_try_cd "$W_CACHE/$W_PACKAGE"
    w_ahk_do "
        SetWinDelay 1000
        SetTitleMatchMode, 2
        run, bttf_101_setup.exe
        winwait, Back to the Future, Welcome
        if ( w_opt_unattended > 0 ) {
            ControlClick, Button2   ; Next
            winwait, Back to the Future, Checking DirectX
            ControlClick, Button5   ; Don't check
            ControlClick, Button2   ; Next
            winwait, Back to the Future, License
            ControlClick, Button2   ; Agree
            winwait, Back to the Future, Location
            ControlClick, Button2   ; Install
        }
        winwait, Back to the Future, has been installed
        if ( w_opt_unattended > 0 ) {
            ControlClick Button4    ; Don't start now
            ControlClick Button2    ; Finish
        }
        WinWaitClose
    "
}

#----------------------------------------------------------------

w_metadata bioshock_demo games \
    title="Bioshock Demo" \
    publisher="2K Games" \
    year="2007" \
    media="download" \
    file1="nzd_BioShockPC.zip" \
    installed_exe1="$W_PROGRAMS_X86_WIN/2K Games/BioShock Demo/Builds/Release/Bioshock.exe"

load_bioshock_demo()
{
    w_download https://us.download.nvidia.com/downloads/nZone/demos/nzd_BioShockPC.zip 36f73251c0c1c6f4b6a83af9b6e44c642b4fce127c2c28cb6d2b25bc95baa934

    w_info "Unzipping demo, installer will start in about 30 seconds."
    w_try unzip "$W_CACHE/$W_PACKAGE/nzd_BioShockPC.zip" -d "$W_TMP/$W_PACKAGE"
    w_try_cd "$W_TMP/$W_PACKAGE/BioShock PC Demo"

    w_ahk_do "
        SetTitleMatchMode, 2
        run setup.exe
        winwait, BioShock Demo - InstallShield Wizard, Choose Setup Language
        if ( w_opt_unattended > 0 ) {
            sleep 2000
            ControlClick, Button3
            ControlClick, Button3
            winwait, BioShock Demo - InstallShield Wizard, Welcome
            sleep 1000
            ControlClick, Button1
            winwait, BioShock Demo - InstallShield Wizard, Please read
            sleep 1000
            ControlClick, Button5
            sleep 1000
            ControlClick, Button2
            winwait, BioShock Demo - InstallShield Wizard, Select the setup type
            sleep 1000
            ControlClick, Button2
            winwait, BioShock Demo - InstallShield Wizard, Click Install to begin
            ControlClick, Button1
        }
        winwait, BioShock Demo - InstallShield Wizard, The InstallShield Wizard has successfully installed BioShock
        if ( w_opt_unattended > 0 ) {
            sleep 1000
            ControlClick, Button2     ; don't launch
            ControlClick, Button6     ; don't show readme
            send {Enter}              ; finish
        }
        winwaitclose
        sleep 3000 ; wait for splash screen to close
    "
}

#----------------------------------------------------------------

w_metadata bioshock2 games \
    title="Bioshock 2" \
    publisher="2K Games" \
    year="2010" \
    media="dvd" \
    file1="BIOSHOCK_2.iso" \
    installed_exe1="$W_PROGRAMS_X86_WIN/2K Games/BioShock 2/SP/Builds/Binaries/Bioshock2Launcher.exe" \
    installed_exe2="$W_PROGRAMS_X86_WIN/2K Games/BioShock 2/MP/Builds/Binaries/Bioshock2Launcher.exe"

load_bioshock2()
{
    w_mount BIOSHOCK_2
    w_ahk_do "
        SetWinDelay 1000
        SetTitleMatchMode, 2
        run ${W_ISO_MOUNT_LETTER}:setup.exe
        if ( w_opt_unattended > 0 ) {
            winwait BioShock 2, Language
            controlclick Button3
            winwait BioShock 2, Welcome
            controlclick Button1 ; Accept
            winwait BioShock 2, License
            controlclick Button3 ; Accept
            sleep 500
            controlclick Button1 ; Next
            winwait BioShock 2, Setup Type
            controlclick Button4 ; Next
            winwait BioShock 2, Ready to Install
            controlclick Button1 ; Install
        }
        winwait BioShock 2, Complete
        if ( w_opt_unattended > 0 ) {
            controlclick Button4 ; Finish
        }
    "
}

#----------------------------------------------------------------

w_metadata bfbc2 games \
    title="Battlefield Bad Company 2" \
    publisher="EA" \
    year="2010" \
    media="dvd" \
    file1="BFBC2.iso"

load_bfbc2()
{
    # Title of installer Window gets the TM symbol wrong, even in UTF-8 locales.
    # Is it like that in Windows, too?
    w_mount BFBC2
    w_read_key
    w_ahk_do "
        SetTitleMatchMode, 2
        run ${W_ISO_MOUNT_LETTER}:setup.exe
        winwait, Bad Company, English
        sleep 500
        ControlClick, Next, Bad Company
        winwait, Bad Company, Registration Code
        sleep 500
        send {RAW}$W_KEY
        ControlClick, Next, Bad Company, Registration Code
        winwait, Bad Company, Setup Wizard will install
        sleep 500
        ControlClick, Button1, Bad Company, Setup Wizard
        winwait, Bad Company, License Agreement
        sleep 500
        ControlClick, Button1, Bad Company, License Agreement
        ControlClick, Button3, Bad Company, License Agreement
        winwait, Bad Company, End-User License Agreement
        sleep 500
        ControlClick, Button1, Bad Company, License Agreement
        ControlClick, Button3, Bad Company, License Agreement
        winwait, Bad Company, Destination Folder
        sleep 500
        ControlClick, Button1, Bad Company, Destination Folder
        winwait, Bad Company, Ready to install
        sleep 500
        ControlClick, Install, Bad Company, Ready to install
        winwait, Authenticate Battlefield
        sleep 500
        ControlClick, Disc authentication, Authenticate Battlefield
        ControlClick, Button4, Authenticate Battlefield
        winwait, Bad Company, PunkBuster
        sleep 500
        ControlClick, Button4, Bad Company, PunkBuster
        ControlClick, Finish, Bad Company
        winwaitclose
    "

    w_warn "Patching to latest version..."

    w_try_cd "$W_PROGRAMS_X86_UNIX/Electronic Arts/Battlefield Bad Company 2"
    w_ahk_do "
        SetTitleMatchMode, 2
        run, BFBC2Updater.exe
        winwait, Updater, have to update to
        sleep 500
        ControlClick, Yes, Updater, have to update
        winwait, Updater, successfully updated
        sleep 500
        ControlClick,No, Updater, successfully updated  ; Button2
    "

    if w_workaround_wine_bug 22762; then
        # FIXME: does this directory name change in Windows 7?
        w_try_cd "$W_DRIVE_C/users/$LOGNAME/My Documents"
        if test -f BFBC2/settings.ini; then
            mv BFBC2/settings.ini BFBC2/oldsettings.ini
            sed 's,DxVersion=auto,DxVersion=9,;
                 s,Fullscreen=true,Fullscreen=false,' BFBC2/oldsettings.ini > BFBC2/settings.ini
        else
            mkdir -p BFBC2
            echo "[Graphics]" > BFBC2/settings.ini
            echo "DxVersion=9" >> BFBC2/settings.ini
        fi
    fi

    if w_workaround_wine_bug 22961; then
        # shellcheck disable=SC2016
        w_warn 'If the game says "No CD/DVD error", try "sudo mount -o remount,unhide,uid=$(uid -u)".  See https://bugs.winehq.org/show_bug.cgi?id=22961 for more info.'
    fi
}

#----------------------------------------------------------------

w_metadata cnc_redalert3_demo games \
    title="Command & Conquer Red Alert 3 Demo" \
    publisher="EA" \
    year="2008" \
    media="manual_download" \
    file1="RedAlert3Demo.exe" \
    installed_exe1="$W_PROGRAMS_X86_WIN/Electronic Arts/Red Alert 3 Demo/RA3Demo.exe"

load_cnc_redalert3_demo()
{
    w_download_manual 'https://www.fileplanet.com/194888/190000/fileinfo/Command-&-Conquer:-Red-Alert-3-Demo' RedAlert3Demo.exe 9c2fb15076830f0e11d89be1847f4777262d8e6ee3d51ae765535f812a8a8cb2

    w_try_cd "$W_CACHE/$W_PACKAGE"
    if test ! "$W_OPT_UNATTENDED"; then
        w_try "$WINE" "$file1"
    else
        w_ahk_do "
            SetWinDelay 1000
            SetTitleMatchMode, 2
            run $file1
            winwait, Demo, readme
            send {enter}                           ; Install button
            winwait, Demo, Agreement
            ControlFocus, TNewCheckListBox1, accept
            send {space}                           ; accept license
            sleep 1000
            send N                                 ; Next
            winwait, Demo, Agreement ; DirectX
            ControlFocus, TNewCheckListBox1, accept
            send {space}                           ; accept license
            sleep 1000
            send N                                 ; Next
            winwait, Demo, Next
            send N                                 ; Next
            winwait, Demo, Install
            send {enter}                           ; Really install
            winwait, Demo, Finish
            send F                                 ; finish
            WinWaitClose
        "
    fi
}

#----------------------------------------------------------------

# https://appdb.winehq.org/objectManager.php?sClass=version&iId=9320

w_metadata blobby_volley games \
    title="Blobby Volley" \
    publisher="Daniel Skoraszewsky" \
    year="2000" \
    media="manual_download" \
    file1="blobby.zip" \
    installed_exe1="c:/BlobbyVolley/volley.exe"

load_blobby_volley()
{
    w_download_manual https://www.chip.de/downloads/Blobby-Volley_12990993.html blobby.zip ef7d2e61fabe5ac6a556fa7c254edc667df5a6659ea262ee2bc97ed61abc3f64
    w_try_unzip "$W_DRIVE_C/BlobbyVolley" "$W_CACHE/$W_PACKAGE"/blobby.zip
}

#----------------------------------------------------------------

w_metadata cim_demo games \
    title="Cities In Motion Demo" \
    publisher="Paradox Interactive" \
    year="2010" \
    media="manual_download" \
    file1="cim-demo-1-0-8.exe" \
    installed_exe1="$W_PROGRAMS_X86_WIN/Cities In Motion Demo/Cities In Motion.exe"

load_cim_demo()
{
    # 29 Mar 2011 cf02066f496637c24f95cf0c4ddfae376951330802500fb11bd74cc6c8872995, Inno Setup installer
    #w_download https://www.pcgamestore.com/games/cities-in-motion-nbsp/trial/cim-demo-1-0-8.exe cf02066f496637c24f95cf0c4ddfae376951330802500fb11bd74cc6c8872995
    w_download_manual https://www.fileplanet.com/218762/210000/fileinfo/Cities-in-Motion-Demo cim-demo-1-0-8.exe cf02066f496637c24f95cf0c4ddfae376951330802500fb11bd74cc6c8872995
    w_try_cd "$W_CACHE/$W_PACKAGE"
    w_try "$WINE" cim-demo-1-0-8.exe ${W_OPT_UNATTENDED:+ /sp- /silent /norestart}
}

#----------------------------------------------------------------

w_metadata cod_demo games \
    title="Call of Duty demo" \
    publisher="Activision" \
    year="2003" \
    media="manual_download" \
    file1="call_of_duty_demo.exe" \
    installed_exe1="$W_PROGRAMS_X86_WIN/Call of Duty Single Player Demo/CoDSP.exe"

load_cod_demo()
{
    w_download_manual https://www.gamefront.com/files/968870/call_of_duty_demo_exe Call_Of_Duty_Demo.exe a7773f1ddb0c9928f738a2be34614d52bc07ecc42c0fe704ab5a596da5421b08

    w_try_cd "$W_CACHE/$W_PACKAGE"
    w_ahk_do "
        SetTitleMatchMode, 2
        run Call_Of_Duty_Demo.exe
        WinWait,Call of Duty Single Player Demo,Welcome
        if ( w_opt_unattended > 0 ) {
            sleep 1000
            ControlClick Button1 ; next
            WinWait,Call of Duty Single Player Demo,License
            sleep 1000
            WinActivate
            send A               ; I Agree
            WinWait,Call of Duty Single Player Demo,System
            sleep 1000
            send n               ; Next
            WinWait,Call of Duty Single Player Demo,Location
            sleep 1000
            send {Enter}
            WinWait,Call of Duty Single Player Demo,Select
            sleep 1000
            send n
            WinWait,Call of Duty Single Player Demo,Start
            sleep 1000
            send i               ; Install
            WinWait,Create Shortcut
            sleep 1000
            send n               ; No
        }
        WinWait,Call of Duty Single Player Demo, Complete
        if ( w_opt_unattended > 0 ) {
            sleep 1000
            send {Enter}         ; Finish
        }
        WinWaitClose
    "

    if w_workaround_wine_bug 21558; then
        # Work around a buffer overflow - not really Wine's fault
        w_warn "If you get a buffer overflow error, set __GL_ExtensionStringVersion=17700 before starting Wine.  See https://bugs.winehq.org/show_bug.cgi?id=21558."
    fi
}

#----------------------------------------------------------------

w_metadata cod1 games \
    title="Call of Duty" \
    publisher="Activision" \
    year="2003" \
    media="dvd" \
    file1="CoD1.iso" \
    file2="CoD2.iso"

load_cod1()
{
    # FIXME: port load_harder from winetricks and use it when caching first disc
    w_mount CoD1

    w_read_key

    __GL_ExtensionStringVersion=17700 w_ahk_do "
        SetTitleMatchMode, 2
        run ${W_ISO_MOUNT_LETTER}:setup.exe
        WinWait, w_try_cd Key, enter
        if ( w_opt_unattended > 0 ) {
            send {Raw}$W_KEY
            ControlClick Button1
            WinWait, w_try_cd Key, valid
            ControlClick Button1
            WinWait, Call of Duty, Welcome
            ControlClick Button1
            WinWait, Call of Duty, License
            ControlClick Button3
            WinWait, Call of Duty, Minimum
            ControlClick Button4
            WinWait, Call of Duty, Location
            ControlClick Button1
            WinWait, Call of Duty, Folder
            ControlClick Button1
            WinWait, Call of Duty, Start
            ControlClick Button1
        }
        WinWait, Insert CD, Please insert the Call of Duty cd 2
        "

    "$WINE" eject ${W_ISO_MOUNT_LETTER}:
    w_mount CoD2

    w_ahk_do "
        SetTitleMatchMode, 2
        if ( w_opt_unattended > 0 ) {
            Send {Enter}    ;continue installation
        }
        WinWait, Insert CD, Please insert the Call of Duty cd 1
    "

    "$WINE" eject ${W_ISO_MOUNT_LETTER}:
    w_mount CoD1

    w_ahk_do "
        SetTitleMatchMode, 2
        if ( w_opt_unattended > 0 ) {
            Send {Enter}    ;finalize install
            WinWait, Create Shortcut, Desktop
            ControlClick Button1
            WinWait, DirectX, Call    ;directx 9
            ControlClick Button6
            ControlClick Button1
            WinWait, Confirm DX settings, Are
            ControlClick Button2
        }
        ; handle crash here
        WinWait, Installation Complete, Congratulations!
        if ( w_opt_unattended > 0 ) {
            ControlClick Button1
        }
        WinWaitClose
    "
    "$WINE" eject ${W_ISO_MOUNT_LETTER}:

    if w_workaround_wine_bug 21558; then
        # Work around a buffer overflow - not really Wine's fault
        w_warn "If you get a buffer overflow error, set __GL_ExtensionStringVersion=17700 before starting Wine.  See https://bugs.winehq.org/show_bug.cgi?id=21558"
    fi
    w_warn "This game is copy-protected, and requires the real disc in a real drive to run."
}

#----------------------------------------------------------------

w_metadata cod4mw_demo games \
    title="Call of Duty 4: Modern Warfare" \
    publisher="Activision" \
    year="2007" \
    media="manual_download" \
    file1="CoD4MWDemoSetup_v2.exe" \
    installed_exe1="$W_PROGRAMS_X86_WIN/Activision/Call of Duty 4 - Modern Warfare Demo/iw3sp.exe"

load_cod4mw_demo()
{
    # 2017/03/28: Also at https://www.fileplanet.com/213663/210000/fileinfo/LEGO-Harry-Potter:-Years-1-4-Demo
    w_download_manual https://download.cnet.com/Call-of-Duty-4-Modern-Warfare/3000-7441_4-11277584.html CoD4MWDemoSetup_v2.exe 715710678394e9b0edda5dd3a560c9711557297aa2849c83e5c109db9830fbbb

    w_try_cd "$W_CACHE/$W_PACKAGE"
    w_ahk_do "
        SetTitleMatchMode, 2
        run, CoD4MWDemoSetup_v2.exe
        WinWait,Modern Warfare,Welcome
        if ( w_opt_unattended > 0 ) {
            Sleep 500
            ControlClick Button1 ; Next
            WinWait,Modern Warfare, License
            Sleep 500
            ControlClick Button5 ; accept
            Sleep 2000
            ControlClick Button2 ; Next
            WinWait,Modern Warfare, System Requirements
            Sleep 500
            ControlClick Button1 ; Next
            Sleep 500
            ControlClick Button4 ; Next
            WinWait,Modern Warfare, Typical
            Sleep 500
            ControlClick Button4 ; License
            Sleep 500
            ControlClick Button1 ; Next
            WinWait,Question, shortcut
            Sleep 500
            ControlClick Button1 ; Yes
            WinWait,Microsoft DirectX Setup, license
            Sleep 500
            ControlClick Button1 ; Yes
            WinWait,Modern Warfare, finished
            Sleep 500
            ControlClick Button1 ; Finished
        }
        WinWaitClose,WinZip Self-Extractor - CoD4MWDemoSetup_v2
    "
}

#----------------------------------------------------------------

w_metadata cod5_waw games \
    title="Call of Duty 5: World at War" \
    publisher="Activision" \
    year="2008" \
    media="dvd" \
    file1="5330161c7960f0770e6b05f498ab9fd13be4cfad.iso" \
    installed_exe1="$W_PROGRAMS_X86_WIN/Activision/Call of Duty - World at War/CoDWaW.exe"

load_cod5_waw()
{
    w_mount CODWAW

    w_read_key

    w_ahk_do "
        SetTitleMatchMode, 2
        run, ${W_ISO_MOUNT_LETTER}:setup.exe
        winwait, Call of Duty, Key Code
        sleep 1000
        Send $W_KEY
        sleep 1000
        ControlClick, Button1, Call of Duty, Key Code
        winwait, Key Code Check
        sleep 1000
        controlclick, Button1, Key Code Check
        winwait, Call of Duty, License Agreement
        sleep 1000
        controlclick, Button5, Call of Duty, License Agreement
        sleep 1000
        controlclick, Button2, Call of Duty, License Agreement
        ; It wants to install PunkBuster here...OH BOY! Luckily, we can say no (see below)
        winwait, PunkBuster, Anti-Cheat software system
        sleep 1000
        controlclick, Button1, PunkBuster, Anti-Cheat software system
        winwait, Call of Duty, install PunkBuster
        sleep 1000
        ; Punkbuster: both are scripted below, so you can toggle which one you want.
        ; No:
        ; controlclick, Button2, Call of Duty, install PunkBuster
        ; Yes:
        controlclick, Button1, Call of Duty, install PunkBuster
        winwait, PunkBuster, License
        sleep 1000
        controlclick, Button5, PunkBuster, License
        sleep 1000
        controlclick, Button2, PunkBuster, License
        ; /end punkbuster
        winwait, Call of Duty, Minimum System
        sleep 1000
        controlclick, Button1, Call of Duty, Minimum System
        winwait, Call of Duty, Setup Type
        sleep 1000
        controlclick, Button1, Call of Duty, Setup Type
        ; Exits silently after install
        ; Need to wait here else next verb will run before this one is done
        winwaitclose, Call of Duty
    "

    # FIXME: Install latest updates
    w_warn "This game is copy-protected, and requires the real disc in a real drive to run."
}

#----------------------------------------------------------------

w_metadata civ4_demo games \
    title="Civilization IV Demo" \
    publisher="Firaxis Games" \
    year="2005" \
    media="manual_download" \
    file1="Civilization4_Demo.zip" \
    installed_file1="$W_PROGRAMS_X86_WIN/Firaxis Games/Sid Meier's Civilization 4 Demo/Civilization4.exe"

load_civ4_demo()
{
    w_download_manual https://download.cnet.com/Civilization-IV-demo/3000-7489_4-10465206.html Civilization4_Demo.zip aaafc7fcbf0fc16c9b28c2422400721a40818b867e9291268877c5d3841122a2

    w_try_unzip "$W_TMP" "$W_CACHE/$W_PACKAGE"/Civilization4_Demo.zip
    w_try_cd "$W_TMP/$W_PACKAGE"
    chmod +x setup.exe
    w_ahk_do "
        SetTitleMatchMode, 2
        run, setup.exe
        winwait, Choose Setup Language
        if ( w_opt_unattended > 0 ) {
            sleep 1000
            Send {enter}
            winwait, Civilization 4, Welcome
            ControlClick &Next >, Civilization 4
            winwait, Civilization 4, I &accept the terms of the license agreement
            ControlClick I &accept, Civilization 4
            ControlClick &Next >, Civilization 4
            winwait, Civilization 4, Express Install
            ControlClick &Next >, Civilization 4
            winwait, Civilization 4, begin installation
            ControlClick &Install, Civilization 4
            winwait, Civilization 4, InstallShield Wizard Complete
            ControlClick Finish, Civilization 4
        }
        winwaitclose
    "
}

#----------------------------------------------------------------

w_metadata crayonphysics_demo games \
    title="Crayon Physics Deluxe demo" \
    publisher="Kloonigames" \
    year="2011" \
    media="download" \
    file1="crayon_release52demo.exe" \
    installed_exe1="$W_PROGRAMS_WIN/Crayon Physics Deluxe Demo/crayon.exe" \
    homepage="http://crayonphysics.com"

load_crayonphysics_demo()
{
    w_download https://crayonphysicsdeluxe.s3.amazonaws.com/crayon_release52demo.exe 3c221f4c4283d89c180337071b5d3f8b88b68cea0558e6f72abcb34ef954b923
    # Inno Setup installer
    w_try "$WINE" "$W_CACHE/$W_PACKAGE/$file1" ${W_OPT_UNATTENDED:+ /sp- /silent /norestart}
}

#----------------------------------------------------------------

w_metadata crysis2 games \
    title="Crysis 2" \
    publisher="EA" \
    year="2011" \
    media="dvd" \
    file1="Crysis2.exe" \
    installed_file1="$W_PROGRAMS_X86_WIN/Electronic Arts/Crytek/Crysis 2/bin32/Crysis2.exe"

load_crysis2()
{
    w_mount "Crysis 2"
    w_ahk_do "
        SetTitleMatchMode, 2
        SetWinDelay, 1000
        run ${W_ISO_MOUNT_LETTER}:EASetup.exe
        if ( w_opt_unattended > 0 ) {
            Loop {
                ; On Windows, this window does not pop up
                ifWinExist, Microsoft Visual C++ 2008 Redistributable Setup
                {
                    winwait, Microsoft Visual C++ 2008 Redistributable Setup
                    controlclick, Button12 ; Next
                    winwait, Visual C++, License
                    controlclick, Button11 ; Agree
                    controlclick, Button8 ; Install
                    winwait, Setup, configuring
                    winwaitclose
                    winwait, Visual C++, Complete
                    controlclick, Button2 ; Finish
                    break
                }
                ifWinExist, Setup, Please read the End User
                {
                    break
                }
                sleep 1000
            }
            winwait, Setup, Please read the End User
            controlclick, Button1     ; accept
            sleep 500
            ;controlclick, Button3     ; next
            send {Enter}
            ; Again for DirectX
            winwait, Setup, Please read the following End
            ;controlclick, Button1     ; accept
            send a
            sleep 1000
            ;controlclick, Button3     ; next
            send {Enter}
            winwait,Setup, Ready to install
            controlclick, Button1
        }
        winwait, Setup, Click the Finish button
        if ( w_opt_unattended > 0 ) {
            controlclick, Button5     ; Don't install EA Download Manager
            controlclick, Button1     ; Finish
        }
        winwaitclose
    "
}

#----------------------------------------------------------------

w_metadata csi6_demo games \
    title="CSI: Fatal Conspiracy Demo" \
    publisher="Ubisoft" \
    year="2010" \
    media="manual_download" \
    file1="CSI6_PC_Demo_05.exe" \
    installed_exe1="$W_PROGRAMS_X86_WIN/Ubisoft/Telltale Games/CSI - Fatal Conspiracy Demo/CSI6Demo.exe"

load_csi6_demo()
{
    w_download_manual https://www.fileplanet.com/217175/download/CSI:-Fatal-Conspiracy-Demo CSI6_PC_Demo_05.exe dd80e8e2ad2716a49ae292da99c4d069e2193d64ee62ca2941ce93fd7ee3b015

    w_try_cd "$W_CACHE/$W_PACKAGE"
    w_ahk_do "
        SetWinDelay 1000
        SetTitleMatchMode, 2
        run, CSI6_PC_Demo_05.exe
        winwait, Installer Language, Please select
        if ( w_opt_unattended > 0 ) {
            ControlClick, Button1   ; Accept default (english)
            ;send {Enter}   ; Accept default (english)
            winwait, CSI - Fatal Conspiracy Demo Setup
            send {Enter}   ; Next
            winwait, CSI - Fatal Conspiracy Demo Setup, License
            send {Enter}   ; Agree
            winwait, CSI - Fatal Conspiracy Demo Setup, Location
            send {Enter}   ; Install
        }
        winwait, CSI - Fatal Conspiracy Demo Setup, Finish
        if ( w_opt_unattended > 0 ) {
            ControlClick Button4
            send {Enter}   ; Finish
            WinWaitClose
        }
    "
}

#----------------------------------------------------------------

w_metadata darknesswithin2_demo games \
    title="Darkness Within 2 Demo" \
    publisher="Zoetrope Interactive" \
    year="2010" \
    media="manual_download" \
    file1="DarknessWithin2Demo.exe" \
    installed_exe1="$W_PROGRAMS_X86_WIN/Iceberg Interactive/Darkness Within 2 Demo/DarkLineage.exe"

load_darknesswithin2_demo()
{
    w_download_manual http://www.bigdownload.com/games/darkness-within-2-the-dark-lineage/pc/darkness-within-2-the-dark-lineage-demo DarknessWithin2Demo.exe

    w_try_cd "$W_CACHE/$W_PACKAGE"
    w_ahk_do "
        SetTitleMatchMode, 2
        run, DarknessWithin2Demo.exe
        winwait, Darkness Within, will install
        if ( w_opt_unattended > 0 ) {
            ControlClick, TNewButton1
            winwait, Darkness, License
            ControlClick, TNewRadioButton1
            ControlClick, TNewButton2
            winwait, Darkness, Location
            ControlClick, TNewButton3
            winwait, Darkness, shortcuts
            ControlClick, TNewButton4
            winwait, Darkness, additional
            ControlClick, TNewButton4
            winwait, Darkness, Ready to Install
            ControlClick, TNewButton4
            winwait, PhysX, License
            ControlClick, Button3
            ControlClick, Button4
            winwait, PhysX, successfully
            ControlClick, Button1
        }
        winwait, Darkness, Setup has finished
        if ( w_opt_unattended > 0 ) {
            ControlClick, TNewListBoxButton1
            ControlClick, TNewButton4
        }
        winwaitclose, Darkness, Setup has finished
    "

    if w_workaround_wine_bug 23041; then
        w_call d3dx9_36
    fi
}

#----------------------------------------------------------------

w_metadata darkspore games \
    title="Darkspore" \
    publisher="EA" \
    year="2011" \
    media="dvd" \
    file1="DARKSPORE.iso" \
    installed_exe1="$W_PROGRAMS_X86_WIN/Electronic Arts/Darkspore/DarksporeBin/Darkspore.exe" \
    homepage="http://darkspore.com/"

load_darkspore()
{
    # Mount disc, verify that expected file is present
    w_mount DARKSPORE Darkspore.ico
    w_ahk_do "
        SetWinDelay 1000
        SetTitleMatchMode, 2
        run ${W_ISO_MOUNT_LETTER}:setup.exe
        if ( w_opt_unattended > 0 ) {
            winwait, Choose Setup Language
            controlclick, Button1    ; ok (accept default, English)
            winwait, InstallShield Wizard, Welcome
            controlclick, Button1    ; Next
            winwait, InstallShield Wizard, License Agreement
            controlclick, Button3    ; Accept
            sleep 1000
            controlclick, Button1    ; Next
            winwait, InstallShield Wizard, Select Features
            controlclick, Button5    ; Next
            winwait, InstallShield Wizard, Ready to Install the Program
            controlclick, Button1    ; Install
            winwait, DirectX
            controlclick, Button1    ; Accept
            sleep 1000
            controlclick, Button4    ; Next
            winwait, DirectX, DirectX setup
            controlclick, Button4
            winwait, DirectX, components installed
            controlclick, Button5    ; Finish
        }
        winwait, InstallShield Wizard, You are now ready
        if ( w_opt_unattended > 0 ) {
            controlclick, Button1    ; Uncheck View Readme.txt
            controlclick, Button4    ; Finish
        }
        WinWaitClose, InstallShield Wizard
    "
}

#----------------------------------------------------------------

w_metadata dcuo games \
    title="DC Universe Online" \
    publisher="EA" \
    year="2011" \
    media="dvd" \
    file1="DCUO - Disc 1.iso" \
    file2="DCUO - Disc 2.iso" \
    installed_exe1="$W_PROGRAMS_X86_WIN/Sony Online Entertainment/Installed Games/DC Universe Online Live/LaunchPad.exe"

load_dcuo()
{
    # The installer would take care of this, but let's do it first
    w_call flash

    w_mount "DCUO - Disc 1"
    w_ahk_do "
        SetWinDelay 1000
        SetTitleMatchMode, 2
        run, ${W_ISO_MOUNT_LETTER}:setup.exe
        if ( w_opt_unattended > 0 ) {
            winwait, DC Universe, Anti-virus
            ControlClick, Button1   ; next
            winwait, DC Universe, License
            ControlClick, Button5   ; accept
            sleep 500
            ControlClick, Button2   ; next
            winwait, DC Universe, Shortcut
            ControlClick, Button3   ; next
            Loop
            {
                IfWinExist, DC Universe, not enough space
                {
                    exit 1          ; dang, have to quit
                }
                IfWinExist, DC Universe, Ready
                {
                    break
                }
                Sleep 1000
            }
            winwait, DC Universe, Ready
            ControlClick, Button1   ; next
        }
        winwait, Setup Needs The Next Disk, Please insert disk 2
    "

    w_mount "DCUO - Disc 2"
    w_ahk_do "
        SetWinDelay 1000
        SetTitleMatchMode, 2
        winwait, Setup Needs The Next Disk, Please insert disk 2
        if ( w_opt_unattended > 0 ) {
            ControlClick, Button2   ; next
            winwaitclose
            Loop
            {
                IfWinExist, DirectX, Welcome
                {
                    ControlClick, Button1   ; accept
                    Sleep 1000
                    ControlClick, Button4   ; next
                    WinWait, DirectX, Runtime Install
                    ControlClick, Button4   ; next
                    WinWait, DirectX, Complete
                    ControlClick, Button4   ; next
                    sleep 1000
                    process, close, dxsetup.exe   ; work around strange 'next button does nothing' bug
                }
                IfWinExist, Flash   ; a newer version of flash is already installed
                {
                    ControlClick, Button3   ; quit
                }
                IfWinExist, DC Universe, Complete
                {
                    break
                }
                Sleep 1000
            }
        }
        WinWait, DC Universe, Complete
        if ( w_opt_unattended > 0 ) {
            ControlClick, Button4   ; finish
        }
        winwaitclose
    "
    w_warn "Now let the wookie install itself, and then quit."
}

#----------------------------------------------------------------

w_metadata deadspace games \
    title="Dead Space" \
    publisher="EA" \
    year="2008" \
    media="dvd" \
    file1="DEADSPACE.iso" \
    installed_exe1="$W_PROGRAMS_X86_WIN/Electronic Arts/Dead Space/Dead Space.exe"

load_deadspace()
{
    w_mount DEADSPACE

    if w_workaround_wine_bug 23324; then
        msvcrun_me_harder="
            winwait, Microsoft
            controlclick, Button1
            "
    else
        msvcrun_me_harder=""
    fi

    w_read_key

    w_ahk_do "
        SetTitleMatchMode, 2
        ; note: if this is the second run, the installer skips the registration code prompt
        run, ${W_ISO_MOUNT_LETTER}:EASetup.exe
        winwait, Dead
        send {Enter}
        winwait, Dead, Registration Code
        send {RAW}$W_KEY
        Sleep 1000
        controlclick, Button2
        $msvcrun_me_harder
        winwait, Setup, License
        Sleep 1000
        controlclick, Button1
        Sleep 1000
        send {Enter}
        winwait, Setup, License
        Sleep 1000
        controlclick, Button1
        Sleep 1000
        send {Enter}
        winwait, Setup, Destination
        Sleep 1000
        controlclick, Button1
        winwait, Setup, begin
        Sleep 1000
        controlclick, Button1
        winwait, Setup, Finish
        Sleep 1000
        controlclick, Button5
        controlclick, Button1
    "
}

#----------------------------------------------------------------

w_metadata deadspace2 games \
    title="Dead Space 2" \
    publisher="EA" \
    year="2011" \
    media="dvd" \
    file1="Disc1.iso" \
    file2="Disc2.iso" \
    installed_exe1="$W_PROGRAMS_X86_WIN/EA Games/Dead Space 2/deadspace2.exe" \

load_deadspace2()
{
    w_read_key

    w_mount Disc1

    # FIXME: this bug was fixed in 1.3.36, so this is unneccessary
    #
    # Work around bug 25963 (fails to switch discs)
    w_warn "Copying discs to hard drive.  This will take a few minutes."
    w_try_cd "$W_TMP"
    # Copy takes a LONG time, so offer a way to avoid copy while debugging verb
    # You'll need to comment out the five "rm -rf"'s, too.
    if test ! -f easetup.exe; then
        w_try cp -R "$W_ISO_MOUNT_ROOT"/* .
        # Make the directories writable, else 2nd disc copy will fail.
        w_try chmod -R +w .
        w_mount Disc2
        # On Linux, use symlinks for disc 2.  (On Cygwin, we'd have to copy.)
        w_try ln -s "$W_ISO_MOUNT_ROOT"/*.dat .
        mkdir -p movies/en movies/fr
        w_try ln -s "$W_ISO_MOUNT_ROOT"/movies/en/* movies/en/
        w_try ln -s "$W_ISO_MOUNT_ROOT"/movies/fr/* movies/fr/
        # Make the files writable, otherwise you'll get errors when trying to remove the temp directory.
        chmod -R +w .
    fi

    # Install takes a long time, so offer a way to skip installation
    # and go straight to activation while debugging that
    if ! test -f "$W_PROGRAMS_X86_UNIX/EA Games/Dead Space 2/deadspace2.exe"; then
      w_ahk_do "
        run easetup.exe
        if ( w_opt_unattended > 0 ) {
            SetTitleMatchMode, 2
            ; Not all systems need the Visual C++ runtime
            loop
            {
                ifwinexist, Microsoft Visual C++ 2008 Redistributable Setup
                {
                    sleep 500
                    controlclick, Button12 ; Next
                    winwait, Visual C++, License
                    sleep 500
                    controlclick, Button11 ; Agree
                    sleep 500
                    controlclick, Button8 ; Install
                    winwait, Setup, configuring
                    winwaitclose
                    winwait, Visual C++, Complete
                    sleep 500
                    controlclick, Button2 ; Finish
                    break
                }
                ifwinexist, Setup, Dead Space
                {
                    break
                }
                sleep 1000
            }
            winwait, Setup, License        ; Dead Space license
            sleep 500
            controlclick Button1  ; accept
            controlclick Button3  ; next
            SetTitleMatchMode, slow        ; since word DirectX in next dialog can only be read 'slowly'
            winwait, Setup, DirectX        ; DirectX license
            sleep 500
            controlclick Button1  ; accept
            controlclick Button3  ; next
            winwait, Setup, Ready to install
            sleep 500
            controlclick Button1  ; Install
        }
        winwait, Setup, Completed
        if ( w_opt_unattended > 0 ) {
            controlclick Button5  ; (Don't) install EA Download Manager
            controlclick Button1  ; Finish
        }
        winwaitclose
        "
    fi

    # Activate the game
    w_try_cd "$W_PROGRAMS_X86/EA Games/Dead Space 2"
    w_ahk_do "
        run activation.exe
        if ( w_opt_unattended > 0 ) {
            SetTitleMatchMode, 2
            WinWait, Product activation
            sleep 500
            controlclick TBitBtn2  ; Next
            WinWait, Product activation, Serial
            sleep 500
            send $W_KEY
            controlclick TBitBtn3  ; Next
            WinWait, Information
            sleep 4000             ; let user see what happened
            send {Enter}
        }
        WinWaitClose, Product activation
    "
}

#----------------------------------------------------------------

w_metadata deusex2_demo games \
    title="Deus Ex 2 / Deus Ex: Invisible War Demo" \
    publisher="Eidos" \
    year="2003" \
    media="manual_download" \
    file1="dxiw_demo.zip" \
    installed_exe1="$W_PROGRAMS_X86_WIN/Deus Ex - Invisible War Demo/System/DX2.exe"

load_deusex2_demo()
{
    w_download_manual https://www.fileplanet.com/133479/130000/fileinfo/Deus-Ex:-INVISIBLE-WAR-Demo dxiw_demo.zip cd3804a03301afd582c9c9374a670944b8cc1470ad1c2e5f3cd602c60d70244f

    w_try unzip "$W_CACHE/$W_PACKAGE/dxiw_demo.zip" -d "$W_TMP"
    w_try_cd "$W_TMP"
    w_ahk_do "
        SetTitleMatchMode 2
        SetWinDelay 500
        run setup.exe
        winwait Deus Ex, Launch
        if ( w_opt_unattended > 0 ) {
            controlclick button2
            winwait Deus Ex, Welcome
            controlclick button1
            winwait Deus Ex, License
            controlclick button3 ;accept
            controlclick button1 ;next
            winwait Deus Ex, Setup Type
            controlclick button4
            winwait Deus Ex, Install
            controlclick button1
            winwait Question, Readme
            controlclick button2
            winwait Question, play
            controlclick button2
        }
        winwait Deus Ex, Complete
        if ( w_opt_unattended > 0 )
            controlclick button4
        winwaitclose Deus Ex, Complete
    "
}

#----------------------------------------------------------------

w_metadata diablo2 games \
    title="Diablo II" \
    publisher="Blizzard" \
    year="2000" \
    media="cd" \
    file1="INSTALL.iso" \
    file2="PLAYDISC.iso" \
    file3="CINEMATICS.iso" \
    installed_exe1="$W_PROGRAMS_X86_WIN/Diablo II/Diablo II.exe"

load_diablo2()
{
    w_download http://ftp.blizzard.com/pub/diablo2/patches/PC/D2Patch_113c.exe 3d7a488c2a76a12e5a21fc71ca313cf9440f67ded6f65dc6bc49e30f6f557672

    w_read_key

    w_mount INSTALL
    w_ahk_do "
        SetWinDelay 500
        run ${W_ISO_MOUNT_LETTER}:setup.exe
        winwait, Diablo II Setup
        send {i}
        winwait, Choose Installation Size
        send {u}
        send {Enter}
        send {Raw}$LOGNAME
        send {Tab}{Raw}$W_KEY
        send {Enter}
        winwait, Diablo II - choose install directory
        send {Enter}
        winwait, Desktop Shortcut
        send {N}
        winwait, Insert Disc"
    w_mount PLAYDISC
    # Needed by patch 1.13c to avoid disc swapping
    cp "$W_ISO_MOUNT_ROOT"/d2music.mpq "$W_PROGRAMS_UNIX/Diablo II/"
    w_ahk_do "
        send, {Enter}
        Sleep 1000
        winwait, Insert Disc"
    w_mount CINEMATICS
    w_ahk_do "
        send, {Enter}
        Sleep 1000
        winwait, Insert Disc"
    w_mount INSTALL
    w_ahk_do "
        send, {Enter}
        Sleep 1000
        winwait, View ReadMe?
        ControlClick &No, View ReadMe?
        winwait, Register Diablo II Electronically?
        send {N}
        winwait, Diablo II Setup - Video Test
        ControlClick &Cancel, Diablo II Setup - Video Test
        winclose, Diablo II Setup"

    w_try_cd "$W_CACHE/$W_PACKAGE"
    w_try "$WINE" D2Patch_113c.exe
    w_ahk_do "
        winwait, Blizzard Updater v2.72, has completed
        Sleep 1000
        send {Enter}
        winwait Diablo II
        Sleep 1000
        ControlClick &Cancel, Diablo II"
    # Dagnabbit, the darn updater starts the game after it updates, no matter what I do?
    w_killall "Game.exe"
}

w_metadata digitanks_demo games \
    title="Digitanks Demo" \
    publisher="Lunar Workshop" \
    year="2011" \
    media="download" \
    file1="digitanks.exe" \
    installed_exe1="$W_PROGRAMS_X86_WIN/Digitanks/digitanksdemo.exe" \
    homepage="http://www.digitanks.com"

load_digitanks_demo()
{
    # 2011/11/11: bc98de67680e907a30ee1ab5d062e098c07a87292e3fb82ae62ad2d7175e94ff
    w_download "http://static.digitanks.com/files/digitanks.exe" bc98de67680e907a30ee1ab5d062e098c07a87292e3fb82ae62ad2d7175e94ff
    w_try_cd "$W_CACHE/$W_PACKAGE"
    w_try "$WINE" "$file1" ${W_OPT_UNATTENDED:+ /S}
    if w_workaround_wine_bug 8060 "installing corefonts"; then
        w_call corefonts
    fi
}

w_metadata dirt2_demo games \
    title="Dirt 2 Demo" \
    publisher="Codemasters" \
    year="2009" \
    media="manual_download" \
    file1="Dirt2Demo.zip" \
    installed_exe1="$W_PROGRAMS_X86_WIN/Codemasters/DiRT2 Demo/dirt2.exe"

load_dirt2_demo()
{
    w_download_manual https://www.fileplanet.com/207823/200000/fileinfo/DiRT-2-Demo Dirt2Demo.zip fbae62d04e3e33790fe78803577efc8ef9ff7e552220c944023b53315e0db9de

    w_try_unzip "$W_TMP/$W_PACKAGE" "$W_CACHE/$W_PACKAGE/Dirt2Demo.zip"

    if w_workaround_wine_bug 23532; then
        w_call gfw
    fi

    if w_workaround_wine_bug 24868; then
        w_call d3dx9_36
    fi

    w_try_cd "$W_TMP/$W_PACKAGE"

    w_ahk_do "
        Run, Setup.exe
        WinWait, Choose Setup Language, Select
        if ( w_opt_unattended > 0 ) {
            sleep 500
            ControlClick Button1    ;next
            WinWait, DiRT2 Demo - InstallShield Wizard, Welcome
            sleep 500
            ControlClick Button1    ;next
            WinWait, DiRT2 Demo - InstallShield Wizard, License
            sleep 500
            ControlClick Button3    ;i accept
            sleep 500
            ControlClick Button1    ;next
            WinWait, DiRT2 Demo - InstallShield Wizard, Setup
            sleep 500
            ControlClick Button4    ;next
            WinWait, InstallShield Wizard, In order
            sleep 500
            ControlClick Button1    ;next
            WinWait, DiRT2 Demo - InstallShield Wizard, Ready
            sleep 500
            ControlClick Button1    ;next
        }
        WinWait, DiRT2 Demo - InstallShield Wizard, Complete
        if ( w_opt_unattended > 0 ) {
            sleep 500
            ControlClick Button4    ;finish
        }
        WinWaitClose, DiRT2 Demo - InstallShield Wizard, Complete
        "
}

#----------------------------------------------------------------

w_metadata demolition_company_demo games \
    title="Demolition Company demo" \
    publisher="Giants Software" \
    year="2010" \
    media="manual_download" \
    file1="DemolitionCompanyDemoENv2.exe" \
    installed_exe1="$W_PROGRAMS_X86_WIN/Demolition Company Demo/DemolitionCompany.exe"

load_demolition_company_demo()
{
    w_download_manual https://www.demolitioncompany-thegame.com/demo.php DemolitionCompanyDemoENv2.exe

    w_try_cd "$W_CACHE/$W_PACKAGE"
    w_ahk_do "
        SetTitleMatchMode, 2
        run, DemolitionCompanyDemoENv2.exe
        winwait, Setup - Demolition, This will install
        if ( w_opt_unattended > 0 ) {
            sleep 1000
            controlclick, TNewButton1, Setup - Demolition, This will install
            winwait, Setup - Demolition, License Agreement
            sleep 1000
            controlclick, TNewRadioButton1, Setup - Demolition, License Agreement
            sleep 1000
            controlclick, TNewButton2, Setup - Demolition, License Agreement
            winwait, Setup - Demolition, Setup Type
            sleep 1000
            controlclick, TNewButton2, Setup - Demolition, Setup Type
            winwait, Setup - Demolition, Ready to Install
            sleep 1000
            controlclick, TNewButton2, Setup - Demolition, Ready to Install
            winwait, Setup - Demolition, Completing
            sleep 1000
            controlclick, TNewButton2, Setup - Demolition, Completing
        }
        winwaitclose, Setup - Demolition
    "
}

#----------------------------------------------------------------

w_metadata dragonage games \
    title="Dragon Age: Origins" \
    publisher="Bioware / EA" \
    year="2009" \
    media="dvd" \
    file1="DragonAge.iso" \
    installed_exe1="$W_PROGRAMS_X86_WIN/Dragon Age/bin_ship/daorigins.exe"

load_dragonage()
{
    w_read_key

    # game can do this, why do we need to?
    w_call physx

    w_mount DragonAge

    w_ahk_do "
        SetWinDelay 1000
        Run, ${W_ISO_MOUNT_LETTER}:Setup.exe
        SetTitleMatchMode, 2
        winwait, Installer Language
        if ( w_opt_unattended > 0 ) {
            WinActivate
            send {Enter}
            winwait, Dragon Age: Origins Setup
            ControlClick Next, Dragon Age: Origins Setup
            winwait, Dragon Age: Origins Setup, End User License
            ;ControlClick Button4, Dragon Age: Origins Setup  ; agree
            send {Tab}a  ; agree
            ;ControlClick I agree, Dragon Age: Origins Setup
            send {Enter} ; continue
            SetTitleMatchMode, 1
            winwait, Dragon Age: Origins, Registration
            send $W_KEY
            send {Enter}
        }
        winwait, Dragon Age: Origins Setup, Install Type
        if ( w_opt_unattended > 0 )
            send {Enter}
        winwaitclose
    "
    # Since the installer explodes on exit, just wait for the
    # last file it's known to create
    while ! test -f "$W_PROGRAMS_X86_UNIX/Dragon Age/bin_ship/DAOriginsLauncher-MCE.png"
    do
        w_info "Waiting for installer to finish..."
        sleep 1
    done

    # FIXME: does this directory name change in Windows 7?
    ini="$W_DRIVE_C/users/$LOGNAME/My Documents/BioWare/Dragon Age/Settings/DragonAge.ini"
    if ! test -f "$ini"; then
        w_warn "$ini not found?"
    else
        cp -f "$ini" "$ini.old"
    fi
    if w_workaround_wine_bug 22383 "use strictdrawordering to avoid video problems"; then
        w_call strictdrawordering=enabled
    fi
    if w_workaround_wine_bug 22557 "Setting UseVSync=0 to avoid black menu"; then
        sed 's,UseVSync=1,UseVSync=0,' < "$ini" > "$ini.new"
        mv -f "$ini.new" "$ini"
    fi
}

#----------------------------------------------------------------

w_metadata dragonage_ue games \
    title="Dragon Age: Origins - Ultimate Edition" \
    publisher="Bioware / EA" \
    year="2010" \
    media="dvd" \
    file1="DRAGONAGE-1.iso" \
    file2="DRAGONAGE-2.iso"

load_dragonage_ue()
{
    w_read_key

    w_mount DRAGONAGE Setup.exe 1

    # Annoyingly, it runs a web browser so you can activate the extra stuff. Disable that, and w_warn the user after install:
    WINEDLLOVERRIDES="winebrowser.exe="
    export WINEDLLOVERRIDES

    w_ahk_do "
        SetTitleMatchMode, 2
        SetTitleMatchMode, slow
        SetWinDelay 1000
        Run, ${W_ISO_MOUNT_LETTER}:Setup.exe
        winwait, Installer, English
        if ( w_opt_unattended > 0 ) {
            ControlClick Button1, Installer, English
            winwait, Dragon Age: Origins Setup
            ControlClick Button2, Dragon Age: Origins Setup
            winwait, Dragon Age: Origins Setup, License Agreement
            ControlClick Button4, Dragon Age: Origins Setup
            ControlClick Button2, Dragon Age: Origins Setup
            winwait, Dragon Age: Origins, Registration
            controlclick, Edit1
            sleep 1000
            send $W_KEY
            send {Enter}
            winwait, Dragon Age: Origins Setup, Install Type
            controlclick, Button2, Dragon Age: Origins Setup, Install Type
            winwait, Dragon Age: Origins Setup, expanded content
            controlclick, Button1
        }
        winwait, Insert Disc...
    "
    w_mount DRAGONAGE data/ultimate_en.rar 2

    w_ahk_do "
        sleep 5000
        SetTitleMatchMode, 2
        if ( w_opt_unattended > 0 ) {
            controlclick, Button2, Insert Disc...
            winwait, Dragon Age, Setup was completed successfully
            controlclick, Button2, Dragon Age, Setup was completed successfully
        }
        winwait, Dragon Age, Click Finish to close
        if ( w_opt_unattended > 0 ) {
            controlclick, Button5, Dragon Age, Click Finish to close
            controlclick, Button2, Dragon Age, Click Finish to close
        }
        winwaitclose
    "

    if w_workaround_wine_bug 22383; then
        w_try_winetricks strictdrawordering=enabled
    fi

    if w_workaround_wine_bug 23730; then
        w_warn "Run with WINEDEBUG=-all to reduce flickering."
    fi

    if w_workaround_wine_bug 23081; then
        w_warn "If you still see flickering, try applying the patch from https://bugs.winehq.org/show_bug.cgi?id=23081"
    fi

    w_warn "To activate the additional content, visit https://social.bioware.com/redeem_code.php?path=/dragonage/pc/dlcactivate/en"
}

#----------------------------------------------------------------

w_metadata dragonage2_demo games \
    title="Dragon Age II demo" \
    publisher="EA/Bioware" \
    year="2011" \
    media="download" \
    file1="DragonAge2Demo_F93M2qCj_EnEsItPlRu.exe" \
    installed_exe1="$W_PROGRAMS_X86_WIN/Dragon Age 2 Demo/bin_ship/DragonAge2Demo.exe"

load_dragonage2_demo()
{
    w_download https://lvlt.bioware.cdn.ea.com/bioware/u/f/eagames/bioware/dragonage2/demo/DragonAge2Demo_F93M2qCj_EnEsItPlRu.exe 615c014deed9b97de5662774fe25074862a7873c430d5d3650d07c7ce2727e9d

    w_try_cd "$W_CACHE/$W_PACKAGE"
    w_ahk_do "
        SetWinDelay 500
        SetTitleMatchMode, 2
        run, DragonAge2Demo_F93M2qCj_EnEsItPlRu.exe
        winwait, Installer Language
        if ( w_opt_unattended > 0 ) {
            send {Enter}
            winwait, Dragon Age II Demo Setup
            send {Enter}
            winwait, Dragon Age II Demo Setup, License
            send !a
            send {Enter}
            winwait, Dragon Age II Demo Setup, Select
            send {Enter}
        }
        winwait, Dragon Age II Demo Setup, Complete, completed
        if ( w_opt_unattended > 0 ) {
            send {Enter}
            winwait, Dragon Age II Demo Setup, Completing
            send {Enter}
        }
        winwaitclose
    "
}

#----------------------------------------------------------------

w_metadata eve games \
    title="EVE Online Tyrannis" \
    publisher="CCP Games" \
    year="2017" \
    media="download" \
    file1="EveLauncher-1104888.exe" \
    installed_exe1="c:/EVE/eve.exe"

load_eve()
{
    # https://community.eveonline.com/support/download/
    w_download https://binaries.eveonline.com/EveLauncher-1104888.exe d1d66ea0a0e4a476a926307dcdb3d7b5e777d7cff7feb172ce7779dac9fdae8f

    if test "$W_OPT_UNATTENDED"; then
        w_warn "Quiet mode doesn't work with latest eve update, button names don't appear in AHK."
    fi

    w_try_cd "$W_CACHE/$W_PACKAGE"
    w_ahk_do "
        run, $file1
        WinWait, EVE Online
        if ( w_opt_unattended > 0 ) {
            WinActivate
            send {Enter}         ; Next
            WinWait, EVE,License Agreement
            WinActivate
            send {Enter}         ; Next
            WinWait, EVE,Choose Install
            WinActivate
            send {Enter}         ; Install
            WinWait, EVE,has been installed
            WinActivate
            ;Send {Tab}{Tab}{Tab} ; select Launch
            ;Send {Space}         ; untick Launch
            ControlClick Button4  ; untick Launch
            Send {Enter}         ; Finish (Button2)
        }
        WinWaitClose, EVE Online
    "
}

#----------------------------------------------------------------

w_metadata fable_tlc games \
    title="Fable: The Lost Chapters" \
    publisher="Microsoft" \
    year="2005" \
    media="cd" \
    file1="FABLE_DISC_1.iso" \
    file2="FABLE DISC 2.iso" \
    file3="FABLE DISC 3.iso" \
    file4="FABLE DISC 4.iso" \
    installed_exe1="$W_PROGRAMS_X86_WIN/Microsoft Games/Fable - The Lost Chapters/Fable.exe"

load_fable_tlc()
{
    w_read_key

    if w_workaround_wine_bug 657; then
        w_call mfc42
    fi

    w_mount FABLE_DISK_1
    w_ahk_do "
        SetTitleMatchMode, 2
        run, ${W_ISO_MOUNT_LETTER}:setup.exe
        WinWait,Fable,Welcome
        if ( w_opt_unattended > 0 ) {
            Sleep 500
            ControlClick Button1 ; Next
            WinWait,Fable,Please
            Sleep 500
            ControlClick Button4 ; Next
            WinWait,Fable,Product Key
            Sleep 500
            Send $W_KEY
            Send {Enter}
        }
        WinWait,Fable,Disk 2
        "
    w_mount "FABLE DISK 2"
    w_ahk_do "
        SetTitleMatchMode, 2
        WinWait,Fable,Disk 2
        if ( w_opt_unattended > 0 ) {
            Sleep 500
            ControlClick Button2 ; Retry
        }
        WinWait,Fable,Disk 3
        "

    w_mount "FABLE DISK 3"
    w_ahk_do "
        SetTitleMatchMode, 2
        WinWait,Fable,Disk 3
        if ( w_opt_unattended > 0 ) {
            Sleep 500
            ControlClick Button2 ; Retry
        }
        WinWait,Fable,Disk 4
        "

    w_mount "FABLE DISK 4"
    w_ahk_do "
        SetTitleMatchMode, 2
        WinWait,Fable,Disk 4
        if ( w_opt_unattended > 0 ) {
            Sleep 500
            ControlClick Button2 ; Retry
        }
        WinWait,Fable,Disk 1
        WinKill
        "

    # Now tell game what the real disc is so user can insert disc 1 and run the game!
    # FIXME: don't guess it's D:
    cat > "$W_TMP/${W_PACKAGE}.reg" <<_EOF_
REGEDIT4

[HKEY_LOCAL_MACHINE\\Software\\Microsoft\\Windows\\CurrentVersion\\Installer\\UserData\\S-1-5-18\\Products\\D3BE9C3CAF4226447B48E06CAACF2DDD\\InstallProperties]
"InstallSource"="D:\\"

_EOF_
    try_regedit "$W_TMP_WIN\\${W_PACKAGE}.reg"

    # Also accept EULA
    cat > "$W_TMP/${W_PACKAGE}.reg" <<_EOF_
REGEDIT4

[HKEY_CURRENT_USER\\Software\\Microsoft\\Microsoft Games\\Fable TLC]
"FIRSTRUN"=dword:00000001

_EOF_
    try_regedit "$W_TMP_WIN\\${W_PACKAGE}.reg"

    if w_workaround_wine_bug 24912; then
        # kill off lingering installer
        w_ahk_do "
            SetTitleMatchMode, 2
            WinKill,Fable
        "
        w_killall IDriverT.exe
        w_killall IDriver.exe
    fi

    if w_workaround_wine_bug 25352; then
        w_call devenum
        w_call quartz
        w_call wmp9
    fi

    if w_workaround_wine_bug 20074; then
        w_call d3dx9_36
    fi
}

#----------------------------------------------------------------

w_metadata fifa11_demo games \
    title="FIFA 11 Demo" \
    publisher="EA Sports" \
    year="2010" \
    media="download" \
    file1="fifa11_pc_demo_NA.zip" \
    installed_exe1="$W_PROGRAMS_X86_WIN/EA Sports/FIFA 11 Demo/Game/fifa.exe"

load_fifa11_demo()
{
    # From https://www.ea.com/uk/football/news/fifa11-download-2
    w_download "http://static.cdn.ea.com/fifa/u/f/fifa11_pc_demo_NA.zip" 8b51b5d7b017c4a198fdfae1c348666f99cd60271835d608357f2ad893e5be43

    w_try unzip -d "$W_TMP" "$W_CACHE/$W_PACKAGE/fifa11_pc_demo_NA.zip"
    w_try_cd "$W_TMP"

    w_ahk_do "
        SetTitleMatchMode, 2
        run, EASetup.exe
        winwait, Microsoft Visual C++ 2008, wizard
        if ( w_opt_unattended > 0 ) {
            sleep 1000
            controlclick, Button12, Microsoft Visual C++ 2008, wizard
            winwait, Microsoft Visual C++ 2008, License Terms
            sleep 1000
            controlclick, Button11, Microsoft Visual C++ 2008, License Terms
            sleep 1000
            controlclick, Button8, Microsoft Visual C++ 2008, License Terms
            winwait, Setup, is configuring
            winwaitclose
            winwait, Microsoft Visual C++ 2008, Setup Complete
            sleep 1000
            controlclick, Button2
            ; There are two license agreements...one is for Directx
            winwait, FIFA 11, I &accept the terms in the End User License Agreement
            sleep 1000
            controlclick, Button1
            sleep 1000
            controlclick, Button3
            winwaitclose
            winwait, FIFA 11, I &accept the terms in the End User License Agreement
            sleep 1000
            controlclick, Button1, FIFA 11, I &accept the terms in the End User License Agreement
            sleep 1000
            controlclick, Button3, FIFA 11, I &accept the terms in the End User License Agreement
            winwait, FIFA 11, Ready to install FIFA 11
            sleep 1000
            controlclick, Button1, FIFA 11, Ready to install FIFA 11
        }
        winwait, FIFA 11, Click the Finish button to exit the Setup Wizard.
        if ( w_opt_unattended > 0 ) {
            sleep 1000
            controlclick, Button5, FIFA 11, Click the Finish button to exit the Setup Wizard.
            sleep 1000
            controlclick, Button1, FIFA 11, Click the Finish button to exit the Setup Wizard.
        }
        WinWaitClose
    "
}

#----------------------------------------------------------------

w_metadata hon games \
    title="Heroes of Newerth" \
    publisher="S2 Games" \
    year="2018" \
    media="download" \
    file1="HoNClient.exe" \
    installed_exe1="$W_PROGRAMS_X86_WIN/Heroes of Newerth/hon.exe"

load_hon()
{
    # 2017/03/28: 0f3c3431a88964647fc4d9540490e43afedc2e48573c260892882ecf48172317
    # 2018/06/03: d4c82a3c5fdaee193675838e2fe6ade6b9fcdc4bdaf57848300c0eb09e71a945
    w_download http://dl.heroesofnewerth.com/installers/win32/HoNClient.exe d4c82a3c5fdaee193675838e2fe6ade6b9fcdc4bdaf57848300c0eb09e71a945

    w_try_cd "$W_CACHE/$W_PACKAGE"
    w_ahk_do "
        SetTitleMatchMode, 2
        run, $file1
        winwait, Installer Language
        if ( w_opt_unattended > 0 ) {
            send {Enter}
            winwait, Heroes of Newerth
            sleep 1000
            controlclick, Button2, Heroes of Newerth
            winwait, Heroes of Newerth, License
            sleep 1000
            controlclick, Button2, Heroes of Newerth, License
            winwait, Heroes of Newerth, Install Location
            sleep 1000
            controlclick, Button2, Heroes of Newerth, Install Location
            winwait, Heroes of Newerth, Start Menu
            sleep 1000
            controlclick, Button2, Heroes of Newerth, Start Menu
            winwait, Heroes of Newerth, Finish
            sleep 1000
            controlclick, Button2, Heroes of Newerth, Finish
        }
        winwaitclose, Heroes of Newerth, Finish
    "
}

#----------------------------------------------------------------

w_metadata hordesoforcs2_demo games \
    title="Hordes of Orcs 2 Demo" \
    publisher="Freeverse" \
    year="2010" \
    media="manual_download" \
    file1="HoO2Demo.exe" \
    installed_exe1="$W_PROGRAMS_X86_WIN/Hordes of Orcs 2 Demo/HoO2.exe"

load_hordesoforcs2_demo()
{
    w_download_manual https://www.fileplanet.com/216619/download/Hordes-of-Orcs-2-Demo HoO2Demo.exe 9c26e420c56268ca14e5cfa6552a9034fc2ea974714b5bfd427e611dfde197be

    w_try_cd "$W_CACHE/$W_PACKAGE"
    w_ahk_do "
        SetTitleMatchMode, 2
        SetWinDelay 500
        SetTitleMatchMode, slow
        run HoO2Demo.exe
        WinWait,Orcs
        if ( w_opt_unattended > 0 ) {
            WinActivate
            ControlFocus, Button1, Hordes ; Next
            sleep 500
            Send n       ; next
            WinWait,Orcs,conditions
            ControlFocus, Button4, Hordes, agree
            Send {Space}
            Send {Enter}  ; next
            WinWait,Orcs,files
            Send {Enter}  ; next
            WinWait,Orcs,exist              ; Destination does not exist, create?
            Send {Enter}  ; yes
            WinWait,Orcs,Start
            Send {Enter}  ; Start
        }
        WinWait,Orcs,successfully
        if ( w_opt_unattended > 0 ) {
            Send {Space}  ; Finish
        }
        winwaitclose Orcs
    "
}

#----------------------------------------------------------------

w_metadata mfsxde games \
    title="Microsoft Flight Simulator X: Deluxe Edition" \
    publisher="Microsoft" \
    year="2006" \
    media="dvd" \
    file1="FSX DISK 1.iso" \
    file2="FSX DISK 2.iso" \
    installed_exe1="$W_PROGRAMS_X86_WIN/Microsoft Games/Microsoft Flight Simulator X/fsx.exe"

load_mfsxde()
{
    if w_workaround_wine_bug 25139 "Setting virtual desktop so license screen shows up on first run."; then
        w_call vd=1024x768
    fi

    w_mount "FSX DISK 1"

    if w_workaround_wine_bug 25558 "Copying disc to hard drive.  This will take a few minutes."; then
        w_try_cd "$W_CACHE/$W_PACKAGE"
        # Copy takes a LONG time, so offer a way to avoid copy while debugging verb
        if test ! -f bothdiscs/setup.exe; then
            mkdir bothdiscs
            w_try_cd bothdiscs
            w_try cp -R "$W_ISO_MOUNT_ROOT"/* .

            # A few files are on both DVDs. Remove them manually so cp doesn't complain.
            rm -f DVDCheck.exe autorun.inf fsx.ico vcredist_x86.exe

            # Make the directories writable, else 2nd disc copy will fail.
            w_try chmod -R +w .

            w_mount "FSX DISK 2"

            # On Linux, use symlinks for disc 2.  (On Cygwin, we'd have to copy.)
            w_try ln -s "$W_ISO_MOUNT_ROOT"/* .

            # Make the files writable, otherwise you'll get errors when trying to remove bothdiscs.
            chmod -R +w .

            # If you leave it mounted, it doesn't ask for the second disk to be inserted.
            # If you mount it without extracting though, the install fails.
            # Apparently it uses the files from the cache, but does a disk check.
        else
            w_try_cd bothdiscs
        fi
    else
        w_die "non-broken case not yet supported for this game"
    fi

    w_ahk_do "
        SetWinDelay 1000
        SetTitleMatchMode, 2
        run setup.exe,,,mfs_pid
        winwait, Microsoft Flight Simulator X, To continue, click Install
        ControlClick, Button1, Microsoft Flight Simulator X, To continue
        ; Accept license:
        winwait, Flight Simulator X - End User License Agreement
        controlclick, Button1, Flight Simulator X - End User License Agreement
        winwait, Microsoft Flight Simulator X Product Activation Wizard
        ; Activate later, currently broken on Wine, see https://bugs.winehq.org/show_bug.cgi?id=25579
        controlclick, Button2, Microsoft Flight Simulator X Product Activation Wizard
        sleep 1000
        controlclick, Button5, Microsoft Flight Simulator X Product Activation Wizard
        ; Close main window:
        winwait, Microsoft Flight Simulator, LEARNING CENTER
        ; A winclose/winkill isn't forceful enough:
        process, close, fsx.exe
        ; Setup doesn't close on its own, because this process doesn't exit cleanly
        process, close, IDriver.exe
    "
}

#----------------------------------------------------------------

w_metadata mfsx_demo games \
    title="Microsoft Flight Simulator X Demo" \
    publisher="Microsoft" \
    year="2006" \
    media="download" \
    file1="FSXDemo.exe" \
    installed_exe1="$W_PROGRAMS_X86_WIN/Microsoft Games/Microsoft Flight Simulator X Demo/fsx.exe"

load_mfsx_demo()
{
    if w_workaround_wine_bug 25139 "Setting virtual desktop so license screen shows up on first run"; then
        w_call vd=1024x768
    fi

    # 2017/03/28: also available at http://www.gamewatcher.com/downloads/flight-simulator-x-download/flight-simulator-x-final-demo
    w_download_manual "https://www.fileplanet.com/166127/160000/fileinfo/Microsoft-Flight-Simulator-X-Demo-[Final]" fsxdemo.exe 0d616d8fb6315c15e9919a29968f98b1feda14a2a284721dad114395154e58be
    w_try_cd "$W_TMP"
    unzip "$W_CACHE/$W_PACKAGE"/FSXDemo.exe
    w_ahk_do "
        SetWinDelay 1000
        SetTitleMatchMode, 2
        run setup.exe,,,mfs_pid
        winwait, Microsoft Flight Simulator X, To continue, click Install
        ControlClick, Button1, Microsoft Flight Simulator X, To continue
        ; Accept license:
        winwait, Flight Simulator X - End User License Agreement
        controlclick, Button1, Flight Simulator X - End User License Agreement
        winwait, Microsoft Flight Simulator X Product Activation Wizard
        ; Activate later, currently broken on Wine, see https://bugs.winehq.org/show_bug.cgi?id=25579
        controlclick, Button2, Microsoft Flight Simulator X Product Activation Wizard
        sleep 1000
        controlclick, Button5, Microsoft Flight Simulator X Product Activation Wizard
        ; Close main window:
        winwait, Microsoft Flight Simulator, LEARNING CENTER
        ; A winclose/winkill isn't forceful enough:
        process, close, fsx.exe
        ; Setup doesn't close on its own, because this process doesn't exit cleanly
        process, close, IDriver.exe
    "
}

#----------------------------------------------------------------

w_metadata gta_vc games \
    title="Grand Theft Auto: Vice City" \
    publisher="Rockstar" \
    year="2003" \
    media="cd" \
    file1="GTA_VICE_CITY.iso" \
    file2="VICE_CITY_PLAY.iso" \
    installed_exe1="$W_PROGRAMS_X86_WIN/Rockstar Games/Grand Theft Auto Vice City/gta-vc.exe"

load_gta_vc()
{
    w_mount GTA_VICE_CITY
    w_ahk_do "
        SetWinDelay 1000
        SetTitleMatchMode, 2
        Run, ${W_ISO_MOUNT_LETTER}:Setup.exe
        winwait, Choose Setup Language
        if ( w_opt_unattended > 0 ) {
            Send {enter}
            winwait, Grand Theft Auto Vice City, Welcome to the InstallShield Wizard
            Send {enter}
            winwait, Grand Theft Auto Vice City, License Agreement
            Send !a
            send {enter}
            winwait, Grand Theft Auto Vice City, Customer Information
            controlclick, edit1
            send $LOGNAME
            send {tab}
            send company ; installer won't proceed without something here
            send {enter}
            winwait, Grand Theft Auto Vice City, Choose Destination Location
            controlclick, Button1
            winwait, Grand Theft Auto Vice City, Select Components
            controlclick, Button2
            winwait, Grand Theft Auto Vice City, Ready to Install the Program
            send {enter}
        }
        winwait, Setup Needs The Next Disk, Please insert disk 2
    "
    w_mount VICE_CITY_PLAY
    w_ahk_do "
        SetWinDelay 1000
        SetTitleMatchMode, 2
        winwait, Setup Needs The Next Disk, Please insert disk 2
        if ( w_opt_unattended > 0 ) {
            controlclick, Button2
        }
        winwait, Grand Theft Auto Vice City, InstallShield Wizard Complete
        if ( w_opt_unattended > 0 ) {
            send {enter}
        }
        winwaitclose
    "

    if w_workaround_wine_bug 26322 "Setting virtual desktop"; then
        w_call vd=800x600
    fi

    myexec="Exec=env WINEPREFIX=\"$WINEPREFIX\" wine cmd /c 'C:\\\\\\\\Run-gta_vc.bat'"
    mymenu="$XDG_DATA_HOME/applications/wine/Programs/Rockstar Games/Grand Theft Auto Vice City/Play GTA Vice City.desktop"
    if test -f "$mymenu" && w_workaround_wine_bug 26304 "Fixing system menu"; then
        # this is a hack, hopefully the wine bug will be fixed soon
        sed -i "s,Exec=.*,$myexec," "$mymenu"
    fi
}

#----------------------------------------------------------------

w_metadata kotor1 games \
    title="Star Wars: Knights of the Old Republic" \
    publisher="LucasArts" \
    year="2003" \
    media="cd" \
    file1="KOTOR_1.iso" \
    file2="KOTOR_2.iso" \
    file3="KOTOR_3.iso" \
    file4="KOTOR_4.iso" \
    installed_exe1="$W_PROGRAMS_X86_WIN/LucasArts/SWKotOR/swkotor.exe"

load_kotor1()
{
    w_mount "KOTOR_1"
    w_ahk_do "
        SetTitleMatchMode 2
        SetWinDelay 500
        run ${W_ISO_MOUNT_LETTER}:setup.exe
        winwait Star Wars, Welcome
        if ( w_opt_unattended > 0 ) {
            controlclick button1
            winwait Star Wars, Licensing Agreement
            controlclick button2
            winwait Question, Licensing Agreement
            controlclick button1
            winwait Star Wars, Destination Folder
            controlclick button1
            winwait Star Wars, Program Folder
            controlclick button2
            winwait Star Wars, Additional Shortcuts
            ;unselect start menu shortcuts
            controlclick button1
            controlclick button2
            controlclick button3
            controlclick button4
            controlclick button5
            controlclick button11
            winwait Star Wars, Review settings
            controlclick button1
        }
        winwait Next Disk, Please insert disk 2
    "
    w_mount "KOTOR_2"
    w_ahk_do "
        SetTitleMatchMode 2
        if ( w_opt_unattended > 0 ) {
            winwait Next Disk
            controlclick button2
        }
        winwait Next Disk, Please insert disk 3
    "
    w_mount "KOTOR_3"
    w_ahk_do "
        SetTitleMatchMode 2
        if ( w_opt_unattended > 0 ) {
            winwait Next Disk
            controlclick button2
        }
        winwait Next Disk, Please insert disk 4
    "
    w_mount "KOTOR_4"
    w_ahk_do "
        SetTitleMatchMode 2
        if ( w_opt_unattended > 0 ) {
            winwait Next Disk
            controlclick button2
            winwait Question, Desktop
            controlclick button2
            winwait Question, DirectX
            controlclick button2 ;don't install directx
        }
        winwait Star Wars, Complete
        if ( w_opt_unattended > 0 ) {
            controlclick button1 ;don't launch game
            controlclick button4
        }
        winwaitclose Star Wars, Complete
    "
}

#----------------------------------------------------------------

w_metadata losthorizon_demo games \
    title="Lost Horizon Demo" \
    publisher="Deep Silver" \
    year="2010" \
    media="manual_download" \
    file1="Lost_Horizon_Demo_EN.exe" \
    installed_exe1="$W_PROGRAMS_X86_WIN/Deep Silver/Lost Horizon Demo/fsasgame.exe"

load_losthorizon_demo()
{
    w_download_manual https://www.fileplanet.com/215704/download/Lost-Horizon-Demo Lost_Horizon_Demo_EN.exe

    w_try_cd "$W_CACHE/$W_PACKAGE"

    w_ahk_do "
        SetTitleMatchMode, 2
        run Lost_Horizon_Demo_EN.exe
        WinWait,Lost Horizon Demo, Destination
        # shellcheck disable=SC2086
        if ( w_opt_unattended > 0 ) {
            Sleep 500
            Send {RAW}${W_TMP}
            ControlClick Button2 ;Install
            WinWaitClose,Lost Horizon Demo,Installation
            Sleep 1000
            Click, Left, 169, 371
            WinWait,Lost Horizon Demo - InstallShield Wizard,Welcome
            Sleep 500
            ControlClick Button1 ;Next
            WinWait,Lost Horizon Demo - InstallShield Wizard,License
            ControlFocus,Button3,Lost Horizon Demo
            Sleep 500
            Send {Space}
            ControlClick Button1 ;Next
            WinWait,Lost Horizon Demo - InstallShield Wizard,program
            Sleep 500
            ControlClick Button2 ;Next
            WinWait,Lost Horizon Demo - InstallShield Wizard,features
            Sleep 500
            ControlClick Button4 ;Next
            WinWait,Lost Horizon Demo - InstallShield Wizard,begin
            Sleep 500
            ControlClick Button1 ;Next
        }
        WinWaitClose
        WinWait,Lost Horizon Demo - InstallShield Wizard,Complete
        if ( w_opt_unattended > 0 ) {
            ControlFocus,Button2,Lost Horizon
            Sleep 500
            Send {Space}
            Sleep 500
            ControlClick Button4 ; Finish
        }
        WinWaitClose
    "
}

#----------------------------------------------------------------

w_metadata lhp_demo games \
    title="LEGO Harry Potter Demo [Years 1-4]" \
    publisher="Travellers Tales / WB" \
    year="2010" \
    media="manual_download" \
    file1="LEGOHarryPotterDEMO.exe" \
    installed_exe1="$W_PROGRAMS_X86_WIN/WB Games/LEGO_Harry_Potter_DEMO/LEGOHarryPotterDEMO.exe"

load_lhp_demo()
{
    case "$LANG" in
        *UTF-8*|*utf8*) ;;
        *)
            w_warn "This installer fails in non-utf-8 locales. Doing 'export LANG=en_US.UTF-8' is a workaround."
            LANG=en_US.UTF-8
            export LANG
            ;;
    esac

    w_download_manual "https://www.fileplanet.com/213663/210000/fileinfo/LEGO-Harry-Potter:-Years-1-4-Demo" 01d8e88511d71f5dd1492034ea4b00eacdbbf891ef23cffa31413d232eee3647

    w_try_cd "$W_CACHE/$W_PACKAGE"
    w_ahk_do "
        SetTitleMatchMode, 2
        run, LEGOHarryPotterDEMO.exe
        winwait, LEGO, language
        if ( w_opt_unattended > 0 ) {
            controlclick, Button1
            winwait, LEGO, License
            controlclick, Button1
            controlclick, Button2
            winwait, LEGO, installation method
            controlclick, Button2
        }
        winwait, LEGO, Finish
        if ( w_opt_unattended > 0 )
            controlclick, Button1

        winwaitclose, LEGO, Finish
    "

    # Work around locale issues by symlinking the app's directory to not have a funny char
    # Won't really work on Cygwin, but that's ok.
    w_try_cd "$W_PROGRAMS_X86_UNIX/WB Games"
    ln -s LEGO*Harry\ Potter*DEMO LEGO_Harry_Potter_DEMO
}

#----------------------------------------------------------------

w_metadata lswcs games \
    title="Lego Star Wars Complete Saga" \
    publisher="Lucasarts" \
    year="2009" \
    media="dvd" \
    file1="LEGOSAGA.iso" \
    installed_file1="$W_PROGRAMS_X86_WIN/LucasArts/LEGO Star Wars - The Complete Saga/LEGOStarWarsSaga.exe"

load_lswcs()
{
    w_mount LEGOSAGA
    w_ahk_do "
        run ${W_ISO_MOUNT_LETTER}:setup.exe
        SetTitleMatchMode, 2
        winwait, Choose Setup Language
        if ( w_opt_unattended > 0 ) {
            send {Enter}
            winwait, LEGO, License Agreement
            send a{Enter}
        }
        winwait, LEGO, method
        if ( w_opt_unattended > 0 ) {
            ControlClick Easy Installation
            sleep 1000
        }
        winwaitclose, LEGO
    "
    w_warn "This game is copy-protected, and requires the real disc in a real drive to run."
}

#----------------------------------------------------------------

w_metadata lemonysnicket games \
    title="Lemony Snicket: A Series of Unfortunate Events" \
    publisher="Activision" \
    year="2004" \
    media="cd" \
    file1="Lemony Snicket.iso"

load_lemonysnicket()
{
    w_mount "Lemony Snicket"
    w_ahk_do "
        SetTitleMatchMode, 2
        Run, ${W_ISO_MOUNT_LETTER}:setup.exe
        WinWait, Lemony, Welcome
        if ( w_opt_unattended > 0 ) {
            sleep 1000
            ControlClick, Button1 ; Next
            WinWait, Lemony, License
            sleep 1000
            ControlClick, Button2 ; Accept
            WinWait, Lemony, Minimum System
            sleep 1000
            ControlClick, Button2 ; Yes
            WinWait, Lemony, Destination
            sleep 1000
            ControlClick, Button1 ; Next
            WinWait, Lemony, Select Program Folder
            sleep 1000
            ControlClick, Button2 ; Next
            WinWait, Lemony, Start Copying
            sleep 1000
            ControlClick, Button1 ; Next
            WinWait, Question, Would you like to add a desktop shortcut
            sleep 1000
            ControlClick, Button2 ; No
            WinWait, Question, Would you like to register
            sleep 1000
            ControlClick, Button2 ; No
            ;WinWait, Information, Please register
            ;sleep 1000
            ;ControlClick, Button1 ; OK
            WinWait, Lemony, Complete
            sleep 1000
            ControlClick, Button4 ; Finish
            WinWait, Lemony, Play
            sleep 1000
            ControlClick, Button6 ; Exit
            WinWait, Lemony, Are you sure
            sleep 1000
            ControlClick, Button1 ; Yes already
        }
        WinWaitClose, Lemony
    "
}

#----------------------------------------------------------------

w_metadata luxor_ar games \
    title="Luxor Amun Rising" \
    publisher="MumboJumbo" \
    year="2006" \
    media="cd" \
    file1="LUXOR_AMUNRISING.iso" \
    installed_exe1="$W_PROGRAMS_X86_WIN/MumboJumbo/Luxor Amun Rising/Luxor AR.exe"

load_luxor_ar()
{
    w_mount LUXOR_AMUNRISING

    w_ahk_do "
        SetWinDelay, 500
        SetTitleMatchMode, 2
        run, ${W_ISO_MOUNT_LETTER}:Luxor_AR_Setup.exe
        winwait, Luxor
        if ( w_opt_unattended > 0 ) {
            ControlClick, Button2   ; Agree
            winwait, Folder
            ControlClick, Button2   ; Install
            winwait, Completed
            ControlClick, Button2   ; Next
        }
        winwait, Success
        if ( w_opt_unattended > 0 ) {
            ControlClick, Button6   ; Uncheck Play
            ControlClick, Button2   ; Close
        }
        winwaitclose
    "
}

#----------------------------------------------------------------

w_metadata masseffect2 games \
    title="Mass Effect 2 (DRM broken on Wine)" \
    publisher="BioWare" \
    year="2010" \
    media="dvd" \
    file1="MassEffect2.iso" \
    file2="ME2_Disc2.iso" \
    installed_exe1="$W_PROGRAMS_X86_WIN/Mass Effect 2/Binaries/MassEffect2.exe"

load_masseffect2()
{
    w_mount MassEffect2
    w_read_key

    w_ahk_do "
        SetTitleMatchMode, 2
        run, ${W_ISO_MOUNT_LETTER}:Setup.exe
        winwait, Installer Language
        if ( w_opt_unattended > 0 ) {
            send {Enter}
            winwait, Mass Effect
            send {Enter}
            winwait, Mass Effect, License
            ControlClick, Button4
            ControlClick, Button2
            winwait, Mass Effect, Registration Code
            send $W_KEY
            ControlClick, Button2
            winwait, Mass Effect, Install Type
            ControlClick, Button2
        }
        winwait, Insert Disc
    "
    sleep 5
    w_mount ME2_Disc2
    w_ahk_do "
        SetTitleMatchMode, 2
        if ( w_opt_unattended > 0 ) {
            winwait, Insert Disc
            ControlClick, Button4
            ; on windows, the first click doesn't seem to do it, so press enter, too
            sleep 1000
            send {Enter}
        }
        ; Some installs may not get to this point due to an installer hang/crash (bug 22919)
        ; The hang/crash happens after the PhysX install but does not seem to affect gameplay
        loop
        {
            ifwinexist, Mass Effect, Finish
            {
                if ( w_opt_unattended > 0 ) {
                    winkill, Mass Effect
                }
                break
            }
            Process, exist, Installer.exe
            me2pid = %ErrorLevel%
            if me2pid = 0
                break
            sleep 1000
        }
    "
}

#----------------------------------------------------------------

w_metadata masseffect2_demo games \
    title="Mass Effect 2" \
    publisher="BioWare" \
    year="2010" \
    media="download" \
    file1="MassEffect2DemoEN.exe" \
    installed_exe1="$W_PROGRAMS_X86_WIN/Mass Effect 2 Demo/Binaries/MassEffect2.exe"

load_masseffect2_demo()
{
    w_download http://static.cdn.ea.com/bioware/u/f/eagames/bioware/masseffect2/ME2_DEMO/MassEffect2DemoEN.exe 4ec5ce1dc90c10512324d24cba2b5b9ba1e1872ed4c23e3ede0fc0accc7d2ff2

    # Don't let self-extractor write into $W_CACHE
    case "$W_PLATFORM" in
        windows_cmd|wine_cmd)
            cp "$W_CACHE/$W_PACKAGE/MassEffect2DemoEN.exe" "$W_TMP"
            chmod +x "$W_TMP"/MassEffect2DemoEN.exe ;;
        *)
            ln -sf "$W_CACHE/$W_PACKAGE/MassEffect2DemoEN.exe" "$W_TMP" ;;
    esac
    w_try_cd "$W_TMP"
    w_ahk_do "
        SetWinDelay 1000
        SetTitleMatchMode, 2
        run, MassEffect2DemoEN.exe
        winwait, Mass Effect 2 Demo
        if ( w_opt_unattended > 0 ) {
            send {Enter}
            winwait, Mass Effect 2 Demo, conflicts
            send {Enter}
            winwait, Mass Effect, License
            ControlClick, Button4
            ;ControlClick, Button2
            send {Enter}
            winwait, Mass Effect, Install Type
            ControlClick, Button2
        }
        ; Some installs may not get to this point due to an installer hang/crash (bug 22919)
        ; The hang/crash happens after the PhysX install but does not seem to affect gameplay
        loop
        {
            ifwinexist, Mass Effect, Finish
            {
                if ( w_opt_unattended > 0 ) {
                    winkill, Mass Effect
                }
                break
            }
            Process, exist, Installer.exe
            me2pid = %ErrorLevel%
            if me2pid = 0
                break
            sleep 1000
        }
    "
}

#----------------------------------------------------------------

w_metadata maxmagicmarker_demo games \
    title="Max & the Magic Marker Demo" \
    publisher="Press Play" \
    year="2010" \
    media="download" \
    file1="max_demo_pc.zip" \
    installed_exe1="$W_PROGRAMS_X86_WIN/maxmagicmarker_demo/max and the magic markerdemo pc.exe"

load_maxmagicmarker_demo()
{
    w_download https://www.maxandthemagicmarker.com/maxdemo/max_demo_pc.zip 6e2abd0cbd0ad04bfea9663402d7e9f24864d3f1c32df69eebf92dfc469fe6dd

    w_try_unzip "$W_PROGRAMS_X86_UNIX/$W_PACKAGE" "$W_CACHE/$W_PACKAGE"/max_demo_pc.zip
    # Work around bug in game?!
    w_try_cd "$W_PROGRAMS_X86_UNIX/$W_PACKAGE"
    mv "max and the magic markerdemo pc" "max and the magic markerdemo pc"_Data
}

#----------------------------------------------------------------

w_metadata mdk games \
    title="MDK (3dfx)" \
    publisher="Playmates International" \
    year="1997" \
    media="cd" \
    file1="MDK.iso" \
    installed_exe1="C:/SHINY/MDK/MDK3DFX.EXE"

load_mdk()
{
    # Needed even on Windows, some people say.  Haven't tried the D3D version on win7 yet.
    w_call glidewrapper

    w_download http://www.falconfly.de/downloads/patch-mdk3dfx.zip 9b9413609ed147944fa44bb5f51b35cf6baa7657e7e1a9891ad68d858275e00b

    w_mount MDK
    w_try_cd "$W_ISO_MOUNT_ROOT"
    w_ahk_do "
        SetTitleMatchMode, 2
        SetTitleMatchMode, slow
        run ${W_ISO_MOUNT_LETTER}:setup.exe
        winwait, MDK
        if ( w_opt_unattended > 0 ) {
            click, left, 80, 80   ; USA
            winwait, Welcome, purchasing MDK
            ControlClick, Button1    ; Next
            winwait, Select Target Platform
            ControlClick, Button6    ; Next
            winwait, Select Installation Options
            ControlClick, Button3    ; Large
            ControlClick, Button6    ; Next
            winwait, Destination
            ControlClick, Button1    ; Next
            winwait, Program Folder
            ControlClick, Button2    ; Next
            winwait, Start
            ControlClick, Button1    ; Next
            Loop {
                IfWinExist, Setup, ProgramFolder
                    send {Enter}
                IfWinExist, Setup Complete
                    break
                sleep 500
            }
        }
        WinWait, Setup Complete
        if ( w_opt_unattended > 0 ) {
            ControlClick, Button1  ; uncheck readme
            ControlClick, Button4  ; Finish
            WinWait, Question, DirectX
            ControlClick, Button2  ; No
            WinWait, Information, complete
            ControlClick, Button1  ; No
        }
        WinWaitClose
    "
    w_try_cd "$W_DRIVE_C/SHINY/MDK"
    w_try_unzip . "$W_CACHE/$W_PACKAGE"/patch-mdk3dfx.zip

    # TODO: Wine fails to install menu items, add a workaround for that
}

#----------------------------------------------------------------

w_metadata menofwar games \
    title="Men of War" \
    publisher="Aspyr Media" \
    year="2009" \
    media="dvd" \
    file1="Men of War.iso" \
    installed_exe1="$W_PROGRAMS_X86_WIN/Aspyr/Men of War/mow.exe"

load_menofwar()
{
    w_mount "Men of War"

    w_try_cd "$W_ISO_MOUNT_ROOT"
    w_ahk_do "
        SetTitleMatchMode, 2
        SetTitleMatchMode, slow
        run ${W_ISO_MOUNT_LETTER}:setup.exe
        winwait, Select Setup Language, Select the language
        if ( w_opt_unattended > 0 ) {
            sleep 1000
            ControlClick, TNewButton1, Select Setup Language, Select the language
            winwait, Men of War
            sleep 1000
            ControlClick, TButton4, Men of War
            winwait, Setup - Men of War, ACCEPTANCE OF AGREEMENT
            sleep 1000
            ControlClick, TNewRadioButton1, Setup - Men of War, ACCEPTANCE OF AGREEMENT
            ControlClick, TNewButton1, Setup - Men of War, ACCEPTANCE OF AGREEMENT
        }
        winwait, Setup - Men of War, Setup has finished installing
        if ( w_opt_unattended > 0 ) {
            sleep 1000
            ControlClick, x242 y254
            ControlClick, x242 y278
            ControlClick, TNewButton1, Setup - Men of War, Setup has finished
        }
    "
}

#----------------------------------------------------------------

w_metadata mise games \
    title="Monkey Island: Special Edition" \
    publisher="LucasArts" \
    year="2009" \
    media="dvd" \
    file1="SecretOfMonkeyIslandSE_ddsetup.zip" \
    installed_exe1="$W_PROGRAMS_X86_WIN/LucasArts/The Secret of Monkey Island Special Edition/MISE.exe"

load_mise()
{
    w_download_manual "https://www.direct2drive.com/8241/product/Buy-The-Secret-of-Monkey-Island(R):-Special-Edition-Download" SecretOfMonkeyIslandSE_ddsetup.zip 2e32458698c9ec7ebce94ae5c57531a3fe1dbb9e

    mkdir -p "$W_TMP/$W_PACKAGE"
    w_try_cd "$W_TMP/$W_PACKAGE"

    # Don't extract DirectX/dotnet35 installers, they just take up extra time and aren't needed. Luckily, MISE copes well and just skips them if they are missing:
    w_try unzip "$W_CACHE/$W_PACKAGE"/SecretOfMonkeyIslandSE_ddsetup.zip -x DirectX* dotnet*

    w_ahk_do "
        SetTitleMatchMode, 2
        run, setup.exe
        WinWait, The Secret of Monkey Island, This wizard will guide you
        sleep 1000
        ControlClick, Button2
        WinWait, The Secret of Monkey Island, License Agreement
        sleep 1000
        ControlSend, RichEdit20A1, {CTRL}{END}
        sleep 1000
        ControlClick, Button4
        sleep 1000
        ControlClick, Button2
        WinWait, The Secret of Monkey Island, Setup Type
        sleep 1000
        ControlClick, Button2
        WinWait, The Secret of Monkey Island, Click Finish
        sleep 1000
        ControlClick, Button2
        "

    # FIXME: This app has two different keys - you can use either one.  How do we handle that with w_read_key?
    if test -f "$W_CACHE/$W_PACKAGE/activationcode.txt"; then
        MISE_KEY=$(cat "$W_CACHE/$W_PACKAGE/activationcode.txt")
        w_ahk_do "
            SetTitleMatchMode, 2
            run, $W_PROGRAMS_X86_WIN\\LucasArts\\The Secret of Monkey Island Special Edition\\MISE.exe
            winwait, Product Activation
            ControlClick, Edit1 ; Activation Code
            send $MISE_KEY
            ControlClick Button4 ; Activate Online
            winwait, Product Activation, SUCCESSFUL
            winClose
            sleep 1000
            Process, Close, MISE.exe
        "
    elif test -f "$W_CACHE/$W_PACKAGE/unlockcode.txt"; then
        MISE_KEY=$(cat "$W_CACHE/$W_PACKAGE/unlockcode.txt")
        w_ahk_do "
            SetTitleMatchMode, 2
            run, $W_PROGRAMS_X86_WIN\\LucasArts\\The Secret of Monkey Island Special Edition\\MISE.exe
            winwait, Product Activation
            ControlClick, Edit3 ; Unlock Code
            send $MISE_KEY
            ControlClick Button6 ; Activate manual
            winClose
            sleep 1000
            Process, Close, MISE.exe
        "
    fi
}

#----------------------------------------------------------------

w_metadata myth2_demo games \
    title="Myth II demo 1.8.0" \
    publisher="Project Magma" \
    year="2011" \
    media="download" \
    file1="Myth2_Demo_180.exe" \
    installed_exe1="$W_PROGRAMS_X86_WIN/Myth II Demo/Myth II Demo.exe" \
    homepage="https://projectmagma.net/"

load_myth2_demo()
{
    # Originally a 1998 game by Bungie; according to Wikipedia, they handed the
    # source code to Project Magma for further development.

    # 2017/03/27: 1a5e11be25c43491e2b4da5291b646ffe5330a6289bef236f404906e3b4f5e96
    w_download https://tain.totalcodex.net/items/download/myth-ii-demo-windows 1a5e11be25c43491e2b4da5291b646ffe5330a6289bef236f404906e3b4f5e96 "${file1}"

    w_try_cd "${W_TMP}"
    w_try unzip "${W_CACHE}/${W_PACKAGE}/${file1}"

    w_ahk_do "
        SetTitleMatchMode, 2
        SetWinDelay 500
        run, $file1
        winwait, Setup, Welcome
        if ( w_opt_unattended > 0 ) {
            winactivate
            send {Enter} ; next
            winwait, Setup, Components
            send {Enter} ; next
            winwait, Setup, Location
            send {Enter} ; install
        }
        winwait, Setup, Complete
        if ( w_opt_unattended > 0 ) {
            controlclick, Button4   ; Do not run
            controlclick, Button2   ; Finish
        }
        winwaitclose
    "
}

#----------------------------------------------------------------

w_metadata nfsshift_demo games \
    title="Need for Speed: SHIFT Demo" \
    publisher="EA" \
    year="2009" \
    media="download" \
    file1="NFSSHIFTPCDEMO.exe" \
    installed_exe1="$W_PROGRAMS_X86_WIN/Electronic Arts/Need for Speed SHIFT Demo/shiftdemo.exe"

load_nfsshift_demo()
{
    #w_download http://cdn.needforspeed.com/data/downloads/shift/NFSSHIFTPCDEMO.exe 5ad011e7dd42e3404e3191009cd81c05b891e7c138d61f958fce9506ff8c9de3
    w_download http://www.legendaryreviews.com/download-center/demos/NFSSHIFTPCDEMO.exe 5ad011e7dd42e3404e3191009cd81c05b891e7c138d61f958fce9506ff8c9de3

    w_try cp "$W_CACHE/$W_PACKAGE/$file1" "$W_TMP"

    w_try_cd "$W_TMP"
    w_ahk_do "
        SetTitleMatchMode, 2
        SetTitleMatchMode, slow
        run, $file1
        winwait, WinRAR
        if ( w_opt_unattended > 0 ) {
            ControlClick, Button2
            winwait, SHIFT, View the readme
            controlclick, Button1
            ; Not all systems need the Visual C++ runtime
            loop
            {
                ifwinexist, Visual C++
                {
                    controlclick, Button1
                    break
                }
                ifwinexist, Setup, SHIFT Demo License
                {
                    break
                }
                sleep 1000
            }
            winwait, Setup, SHIFT Demo License
            Sleep 1000
            send {Space}
            Sleep 1000
            send {Enter}
            winwait, Setup, DirectX
            Sleep 1000
            send {Space}
            Sleep 1000
            send {Enter}
            winwait, Setup, Destination
            Sleep 1000
            send {Enter}
            winwait, Setup, begin
            Sleep 1000
            controlclick, Button1
        }
        winwait, Setup, Finish
        if ( w_opt_unattended > 0 ) {
            Sleep 1000
            controlclick, Button5
            controlclick, Button1
        }
        winwaitclose, Setup, Finish
    "
}

#----------------------------------------------------------------

w_metadata oblivion games \
    title="Elder Scrolls: Oblivion" \
    publisher="Bethesda Game Studios" \
    year="2006" \
    media="dvd" \
    file1="Oblivion.iso" \
    installed_exe1="$W_PROGRAMS_X86_WIN/Bethesda Softworks/Oblivion/Oblivion.exe"

load_oblivion()
{
    w_mount "Oblivion"

    w_try_cd "$W_ISO_MOUNT_ROOT"
    w_ahk_do "
        SetTitleMatchMode, 2
        run, Setup.exe
        winwait, Oblivion, Welcome to the
        if ( w_opt_unattended > 0 ) {
            sleep 500
            controlclick, Button1
            winwait, Oblivion, License Agreement
            sleep 500
            controlclick, Button3
            sleep 500
            controlclick, Button1
            winwait, Oblivion, Choose Destination
            sleep 500
            controlclick, Button1
            winwait, Oblivion, Ready to Install
            sleep 500
            controlclick, Button1
            winwait, Oblivion, Complete
            sleep 500
            controlclick, Button1
            sleep 500
            controlclick, Button2
            sleep 500
            controlclick, Button3
        }
        winwaitclose, Oblivion, Complete
    "

    if w_workaround_wine_bug 20074 "Installing native d3dx9_36"; then
        w_call d3dx9_36
    fi
}

#----------------------------------------------------------------

w_metadata penpenxmas games \
    title="Pen-Pen Xmas Olympics" \
    publisher="Army of Trolls / Black Cat" \
    year="2007" \
    media="download" \
    file1="PenPenXmasOlympics100.exe" \
    installed_exe1="$W_PROGRAMS_X86_WIN/PPO/PPO.exe"

load_penpenxmas()
{
    W_BROWSERAGENT=1 \
    w_download http://retrospec.sgn.net/download/files/PenPenXmasOlympics100.exe c35c5c6a9a3fa62d6b099713e72390d0490320534dba958b57b94f0a6ab458db

    w_try_cd "$W_CACHE/$W_PACKAGE"
    "$WINE" PenPenXmasOlympics100.exe $W_UNATTENDED_SLASH_S
}

#----------------------------------------------------------------

w_metadata popfs games \
    title="Prince of Persia: The Forgotten Sands" \
    publisher="Ubisoft" \
    year="2010" \
    media="dvd" \
    file1="PoP_TFS.iso" \
    installed_exe1="$W_PROGRAMS_X86_WIN/Ubisoft/Prince of Persia The Forgotten Sands/Prince of Persia.exe"

load_popfs()
{
    w_mount PoP_TFS

    w_ahk_do "
        SetTitleMatchMode, 2
        run, ${W_ISO_MOUNT_LETTER}:Setup.exe
        winwait, Prince of Persia, Language
        if ( w_opt_unattended > 0 ) {
            sleep 500
            ControlClick, Button3
            winwait, Prince of Persia, Welcome
            sleep 500
            ControlClick, Button1
            winwait, Prince of Persia, License
            sleep 500
            ControlClick, Button5
            sleep 500
            ControlClick, Button2
            winwait, Prince of Persia, Click Install
            sleep 500
            ControlClick, Button1
            ; Avoid error when creating desktop shortcut
            Loop
            {
                IfWinActive, Prince of Persia, Click Finish
                    break
                IfWinExist, Prince of Persia, desktop shortcut
                {
                sleep 500
                    ControlClick, Button1, Prince of Persia, desktop shortcut
                    break
                }
                sleep 5000
            }
        }
        winwait, Prince of Persia, Click Finish
        if ( w_opt_unattended > 0 ) {
            sleep 500
            ControlClick, Button4
        }
    "
}

#----------------------------------------------------------------

w_metadata rct3deluxe games \
    title="RollerCoaster Tycoon 3 Deluxe (DRM broken on Wine)" \
    publisher="Atari" \
    year="2004" \
    media="cd" \
    file1="RCT3.iso" \
    installed_exe1="$W_PROGRAMS_X86_WIN/Atari/RollerCoaster Tycoon 3/RCT3.EXE"

load_rct3deluxe()
{
    if w_workaround_wine_bug 21448; then
        w_warn "DRM doesn't work, see https://bugs.winehq.org/show_bug.cgi?id=21448"
    fi

    w_mount RCT3

    # FIXME: make videos and music work
    # Game still doesn't show .wmv logo videos nor play .wma background audio in menu
    # though it does in Jake's screencast.  Loading wmp9 and devenum gets it to
    # try to load the .wmv logos, but it crashes in quartz :-(
    # But at least it's playable without the logo videos and background.

    w_ahk_do "
        SetWinDelay 500
        SetTitleMatchMode, 2
        run ${W_ISO_MOUNT_LETTER}:setup-rtc3.exe
        if ( w_opt_unattended > 0 ) {
            WinWait, Select Setup Language
            controlclick, TButton1   ; accept
            WinWait Setup - RollerCoaster Tycoon 3, Welcome
            controlclick, TButton1   ; Next
            WinWait Setup - RollerCoaster Tycoon 3, License
            controlclick, TRadioButton1   ; Accept
            sleep 500
            controlclick, TButton2   ; Next
            WinWait Setup - RollerCoaster Tycoon 3, Destination
            controlclick, TButton3   ; Next
            WinWait Setup - RollerCoaster Tycoon 3, Start Menu
            controlclick, TButton4   ; Next
            WinWait Setup - RollerCoaster Tycoon 3, Additional
            controlclick, TButton4   ; Next
            WinWait Setup - RollerCoaster Tycoon 3, begin
            controlclick, TButton4   ; Install
            WinWait, Atari Product Registration
            controlclick, Button6   ; Close
            WinWait, Product Registration, skip
            controlclick, Button2   ; Yes, skip
        }
        WinWait Setup - RollerCoaster Tycoon 3, finished
        if ( w_opt_unattended > 0 ) {
            controlclick, TNewCheckListBox1   ; uncheck Launch
            controlclick, TButton4   ; Finish
        }
        WinWaitClose Setup - RollerCoaster Tycoon 3, finished
        "
}

#----------------------------------------------------------------

w_metadata riseofnations_demo games \
    title="Rise of Nations Trial" \
    publisher="Microsoft" \
    year="2003" \
    media="manual_download" \
    file1="RiseOfNationsTrial.exe" \
    installed_exe1="$W_PROGRAMS_X86_WIN/Microsoft Games/Rise of Nations Trial/nations.exe"

load_riseofnations_demo()
{
    w_download_manual https://download.cnet.com/Rise-of-Nations-Trial-Version/3000-7562_4-10730812.html RiseOfNationsTrial.exe f0bd8be3999164e669aad33583e372ca0f530b1a2ac0194a4c13b265e9cdf744

    w_try_cd "$W_CACHE/$W_PACKAGE"

    w_ahk_do "
        SetTitleMatchMode, 2
        run RiseOfNationsTrial.exe
        WinWait,Rise Of Nations Trial Setup
        if ( w_opt_unattended > 0 ) {
            sleep 2500
            ControlClick CButtonClassName2
            WinWait,Rise Of Nations Trial Setup, installed
            sleep 2500
            ControlClick CButtonClassName7
        }
        WinWaitClose
    "

    if w_workaround_wine_bug 9027; then
        w_call directmusic
    fi
}

#----------------------------------------------------------------

w_metadata secondlife games \
    title="Second Life Viewer" \
    publisher="Linden Labs" \
    year="2003-2011" \
    media="download" \
    file1="Second_Life_3-2-8-248931_Setup.exe" \
    installed_exe1="$W_PROGRAMS_X86_WIN/SecondLifeViewer/SecondLife.exe"

load_secondlife()
{
    w_download http://download.cloud.secondlife.com/Viewer-3/Second_Life_3-2-8-248931_Setup.exe d155366f16bfe23f33a6b6d63f366691be2d0554429916da875ea78d0e0de8a6

    w_try_cd "$W_CACHE/$W_PACKAGE"
    w_ahk_do "
        SetTitleMatchMode, 2
        SetWinDelay 500
        run, $file1
        if ( w_opt_unattended > 0 ) {
            winwait, Installer Language
            send {Enter}
            winwait, Installation Folder
            send {Enter}
        }
        winwait, Second Life, Start Second Life now
        if ( w_opt_unattended > 0 ) {
            send {Tab}{Enter}
        }
        winwaitclose
    "
}

#----------------------------------------------------------------

w_metadata sims3 games \
    title="The Sims 3 (DRM broken on Wine)" \
    publisher="EA" \
    year="2009" \
    media="dvd" \
    file1="Sims3.iso" \
    installed_exe1="$W_PROGRAMS_X86_WIN/Electronic Arts/The Sims 3/Game/Bin/TS3.exe"

load_sims3()
{
    w_read_key

    w_mount Sims3
    # Default lang, USA, accept defaults, uncheck EA dl mgr, uncheck readme
    w_ahk_do "
        run ${W_ISO_MOUNT_LETTER}:Sims3Setup.exe
        winwait, Choose Setup Language
        if ( w_opt_unattended > 0 ) {
            send {Enter}
            SetTitleMatchMode, 2
            winwait, - InstallShield Wizard
            sleep 1000
            ControlClick &Next >, - InstallShield Wizard
            sleep 1000
            send uuuuuu{Tab}{Tab}{Enter}
            sleep 1000
            send a{Enter}
            sleep 1000
            send {Raw}$W_KEY
            send {Enter}
            winwait, - InstallShield Wizard, Setup Type
            send {Enter}
            winwait, - InstallShield Wizard, Click Install to begin
            send {Enter}
            winwait, - InstallShield Wizard, EA Download Manager
            ControlClick Yes, - InstallShield Wizard
            send {Enter}
        }
        winwait, - InstallShield Wizard, Complete
        if ( w_opt_unattended > 0 ) {
            ControlClick View the readme file, - InstallShield Wizard
            ControlClick Finish, - InstallShield Wizard
        }
        winwaitclose
    "
    w_umount

    # DVD region code is last digit.
    # FIXME: download appropriate one rather than just US version.
    w_download http://akamai.cdn.ea.com/eadownloads/u/f/sims/sims3/patches/TS3_1.19.44.010001_Update.exe 9428b32638108e51e63455b60f3cfd5b5aca07b55ce58a200087631a02b5336c

    w_try_cd "$W_CACHE/$W_PACKAGE"
    w_ahk_do "
        run TS3_1.19.44.010001_Update.exe
        SetTitleMatchMode, 2
        winwait, - InstallShield Wizard, Complete
        if ( w_opt_unattended > 0 ) {
            ControlClick Finish, - InstallShield Wizard
        }
        winwaitclose
    "
}

#----------------------------------------------------------------

w_metadata simsmed games \
    title="The Sims Medieval (DRM broken on Wine)" \
    publisher="EA" \
    year="2011" \
    media="dvd" \
    file1="TSimsM.iso" \
    installed_exe1="$W_PROGRAMS_X86_WIN/Electronic Arts/The Sims Medieval/Game/Bin/TSM.exe"

load_simsmed()
{
    w_read_key

    w_mount TSimsM
    # Default lang, USA, accept defaults, uncheck EA dl mgr, uncheck readme
    w_ahk_do "
        SetTitleMatchMode, 2
        SetWinDelay 1000
        run ${W_ISO_MOUNT_LETTER}:SimsMedievalSetup.exe
        winwait, Choose Setup Language
        if ( w_opt_unattended > 0 ) {
            send {Enter}
            SetTitleMatchMode, 2
            winwait, - InstallShield Wizard
            ControlClick &Next >, - InstallShield Wizard
            sleep 1000
            send uuuuuu{Tab}{Tab}{Enter}
            WinWait, Sims, License
            ControlClick Button3   ; Accept
            sleep 1000
            ControlClick Button1   ; Next
            sleep 1000
            send {Raw}$W_KEY
            send {Enter}
            winwait, - InstallShield Wizard, Setup Type
            ControlClick &Complete    ; was not defaulting to complete?
            send {Enter}
            winwait, - InstallShield Wizard, Click Install to begin
            send {Enter}

            ; Handle optional dialogs
            ; In Wine-1.3.16 and lower, before
            ; https://www.winehq.org/pipermail/wine-cvs/2011-March/076262.html,
            ; wine didn't claim to already have .net 4 installed,
            ; and ran into bug 25535.
            Loop
            {
                ; .net 4 install sometimes fails nicely
                ifWinExist,, .NET Framework 4 has not been installed
                {
                    ControlClick Button3    ; Finish
                }
                ; .net 4 install sometimes explodes
                ifWinExist .NET Framework Initialization Error
                {
                    send {Enter}
                }
                ifWinExist, Sims, Customer Experience Improvement
                {
                    send {Enter}           ; Next
                }
                ifWinExist, - InstallShield Wizard, Complete
                    break
                sleep 1000
            }
        }
        winwait, - InstallShield Wizard, Complete
        if ( w_opt_unattended > 0 ) {
            ControlClick Button1   ; Do not view readme
            send {Enter}           ; Finish
        }
        winwaitclose
    "

    # DVD region code is last digit.
    # FIXME: download appropriate one rather than just US version.
    w_download http://akamai.cdn.ea.com/eadownloads/u/f/sims/sims/patches/TheSimsMedievalPatch_1.1.10.00001_Update.exe 01c0f9e3394d93869f67f1319b80a1257fe421bbdf911a15c8c7ab43f2e73683

    w_try_cd "$W_CACHE/$W_PACKAGE"
    w_ahk_do "
        SetTitleMatchMode, 2
        SetWinDelay 500
        run TheSimsMedievalPatch_1.1.10.00001_Update.exe
        winwait, Medieval, will reset any in-progress quests
        send {Enter}
        winwait, Medieval, Welcome
        if ( w_opt_unattended > 0 ) {
            send {Enter}
        }
        winwait, - InstallShield Wizard, Complete
        if ( w_opt_unattended > 0 ) {
            ControlClick Finish, - InstallShield Wizard
        }
        winwaitclose
    "
}

#----------------------------------------------------------------

w_metadata sims3_gen games \
    title="The Sims 3: Generations (DRM broken on Wine)" \
    publisher="EA" \
    year="2011" \
    media="dvd" \
    file1="Sims3EP04.iso" \
    installed_exe1="$W_PROGRAMS_X86_WIN/Electronic Arts/The Sims 3 Generations/Game/Bin/TS3EP04.exe"

load_sims3_gen()
{
    if [ ! -f "$W_PROGRAMS_X86_WIN/Electronic Arts/The Sims 3/Game/Bin/TS3.exe" ]; then
        w_die "You must have sims3 installed to install sims3_gen!"
    fi

    w_read_key
    w_mount Sims3EP04

    # Default lang, USA, accept defaults, uncheck EA dl mgr, uncheck readme
    w_ahk_do "
        SetTitleMatchMode, 2
        SetWinDelay 1000
        run ${W_ISO_MOUNT_LETTER}:Sims3EP04Setup.exe
        winwait, - InstallShield Wizard
        if ( w_opt_unattended > 0 ) {
            send {Enter}
            loop
            {
                SetTitleMatchMode, 2
                ifwinexist, - InstallShield Wizard, Setup will now attempt to update
                {
                    ControlClick, Button1, - InstallShield Wizard
                    sleep 1000
                    winwait, - InstallShield Wizard, Setup has finished updating The Sims
                    sleep 1000
                    controlclick, Button1, - InstallShield Wizard
                    sleep 1000
                }
                ifwinexist, Sims, License
                {
                    winactivate, Sims, License
                    sleep 1000
                    ControlClick, Button3
                    sleep 1000
                    ControlClick, Button1
                    sleep 1000
                    break
                }
                sleep 1000
            }
            winwait, Sims, Please enter the entire Registration Code
            sleep 1000
            send {Raw}$W_KEY
            send {Enter}
            winwait, - InstallShield Wizard, Setup Type
            ControlClick &Complete    ; was not defaulting to complete?
            send {Enter}
            winwait, - InstallShield Wizard, Click Install to begin
            send {Enter}
            winwait, - InstallShield Wizard, Would you like to install the latest
            sleep 1000
            ControlClick, Button4 ; No thanks
            sleep 1000
            ControlClick, Button1
            sleep 1000
        }
        winwait, - InstallShield Wizard, Complete
        if ( w_opt_unattended > 0 ) {
            ControlClick Button1   ; Do not view readme
            send {Enter}           ; Finish
        }
        winwaitclose
    "
}

#----------------------------------------------------------------

w_metadata splitsecond games \
    title="Split Second" \
    publisher="Disney" \
    year="2010" \
    media="dvd" \
    file1="SplitSecond.iso" \
    installed_exe1="$W_PROGRAMS_X86_WIN/Disney Interactive Studios/Split Second/SplitSecond.exe"

load_splitsecond()
{
    # Key is used in first run activation, no need to read it here.
    w_mount SplitSecond

    # Aborts with dialog about FirewallInstallHelper.dll if that's not on the path (e.g. in current dir)
    w_try_cd "$W_ISO_MOUNT_ROOT"
    w_ahk_do "
        SetTitleMatchMode, 2
        run setup.exe
        winwait, Split, Language
        sleep 500
        ControlClick, Next, Split, Language ; FIXME: Use button name
        winwait, Split, game installation
        sleep 500
        ControlClick, Button1, Split, game installation
        winwait, Split, license
        sleep 500
        ControlClick, Button5, Split, license
        sleep 500
        ControlClick, Button2, Split, license
        winwait, Split, DirectX
        sleep 500
        ControlClick, Button5, Split, DirectX
        sleep 500
        ControlClick, Button2, Split, DirectX
        winwait, Split, installation method
        sleep 500
        controlclick, Next, Split, installation method ; FIXME: Use button name
        winwait, DirectX needs to be updated
        sleep 500
        send {Enter}
        winwait, Split, begin
        sleep 500
        ControlClick, Button1
        winwait, Split, completed
        sleep 500
        ControlClick, Button1, Split
        sleep 500
        ControlClick, Button4, Split
    "
}

#----------------------------------------------------------------

w_metadata spore games \
    title="Spore" \
    publisher="EA" \
    year="2008" \
    media="dvd" \
    file1="SPORE.iso" \
    installed_exe1="$W_PROGRAMS_X86_WIN/Electronic Arts/SPORE/Sporebin/SporeApp.exe"

load_spore()
{
    w_mount SPORE

    w_read_key

    w_ahk_do "
        SetTitleMatchMode, 2
        run, ${W_ISO_MOUNT_LETTER}:SPORESetup.exe
        winwait, Language
        if ( w_opt_unattended > 0 ) {
            sleep 500
            controlclick, Button1
            winwait, SPORE, Welcome
            sleep 500
            controlclick, Button1
            winwait, SPORE, License
            sleep 500
            controlclick, Button3
            sleep 500
            controlclick, Button1
            winwait, SPORE, Registration Code
            send {RAW}$W_KEY
            sleep 500
            controlclick, Button2
            winwait, SPORE, Setup Type
            sleep 500
            controlclick, Button6
            winwait, SPORE, Shortcut
            sleep 500
            controlclick, Button6
            winwait, SPORE, begin
            sleep 500
            controlclick, Button1
            winwait, Question
            ; download managers are usually a pain, so always say no to such questions
            sleep 500
            controlclick, Button2
        }
        winwait, SPORE, complete
        sleep 500
        if ( w_opt_unattended > 0 ) {
            controlclick, Button1
            sleep 500
            controlclick, Button2
            sleep 500
            controlclick, Button4
        }
        winwaitclose, SPORE, complete
    "
}

#----------------------------------------------------------------

w_metadata spore_cc_demo games \
    title="Spore Creature Creator trial" \
    publisher="EA" \
    year="2008" \
    media="download" \
    file1="792248d6ad421d577132c2b648bbed45_scc_trial_na.exe" \
    installed_exe1="$W_PROGRAMS_X86_WIN/Electronic Arts/SPORE/Sporebin/SporeCreatureCreator.exe"

load_spore_cc_demo()
{
    w_download http://akamai.cdn.ea.com/eamaster/u/f/eagames/spore/scc/promo/792248d6ad421d577132c2b648bbed45_scc_trial_na.exe a7fbc5ca02a49be9772b54caf3ab1a60bdda16e43e14051de407ace527bece15

    w_info "The installer runs on for about a minute after it's done."

    w_try_cd "$W_CACHE/$W_PACKAGE"
    if test "$W_OPT_UNATTENDED"; then
        w_ahk_do "
            SetWinDelay 1000
            SetTitleMatchMode, 2
            run $file1
            winwait, Wizard, Welcome to the SPORE
            send N
            winwait, Wizard, Please read the following
            send a
            send N
            winwait, Wizard, your setup
            send N
            winwait, Wizard, options below
            send N
            winwait, Wizard, We're ready
            ;send i       ; didn't take once?
            ControlClick, Button1
            winwait, Question, do not install the latest
            send N        ; reject EA Download Manager
            winwait, Wizard, Launch
            send {SPACE}{DOWN}{SPACE}{ENTER}
            winwaitclose
        "
        while pgrep -f "$file1" > /dev/null
        do
            w_info "Waiting for installer to finish."
            sleep 2
        done
    else
        w_try "$WINE" "$file1"
    fi
}

#----------------------------------------------------------------

w_metadata starcraft2_demo games \
    title="Starcraft II Demo" \
    publisher="Blizzard" \
    year="2010" \
    media="manual_download" \
    file1="SC2-WingsOfLiberty-enUS-Demo-Installer.zip" \
    installed_exe1="$W_PROGRAMS_X86_WIN/StarCraft II Demo/StarCraft II.exe"

load_starcraft2_demo()
{
    w_download_manual https://www.fileplanet.com/217982/210000/fileinfo/Starcraft-2-Demo SC2-WingsOfLiberty-enUS-Demo-Installer.zip 6ba192a726fc8b58031a7de961ad9392f60df05cfb206342f02f7a80b57c0784

    w_try_cd "$W_TMP"
    w_try_unzip . "$W_CACHE/$W_PACKAGE"/SC2-WingsOfLiberty-enUS-Demo-Installer.zip

    w_ahk_do "
        SetTitleMatchMode, 2
        Run, Installer.exe
        WinWait, StarCraft II Installer
        if ( w_opt_unattended > 0 ) {
            sleep 500
            ControlClick, x300 y200
            winwait, End User License Agreement
            winactivate
            ;MouseMove, 300, 300
            ;Click WheelDown, 70
            Sleep, 1000
            ControlClick, Button2  ; Accept
            winwaitclose
            winwait, StarCraft II Installer
            sleep 1000
            ControlClick, x800 y500
            ; Is there any better wait to await completion?
            Loop {
                PixelGetColor, color, 473, 469   ; the 1 in 100%
                ; The digits are drawn white, but because the whole
                ; window is flickering, it cycles through about 20
                ; brightnesses.  Check a bunch of them to reduce
                ; chances of getting stuck for a long time.
                ifEqual, color, 0xffffff
                    break
                ifEqual, color, 0xf4f4f4
                    break
                ifEqual, color, 0xf1f1f1
                    break
                ifEqual, color, 0xf0f0f0
                    break
                ifEqual, color, 0xeeeeee
                    break
                ifEqual, color, 0xebebeb
                    break
                ifEqual, color, 0xe4e4e4
                    break
                sleep 500 ; changes rapidly, so sample often
            }
            ControlClick, x800 y500   ; Finish
            winwaitclose
            ; no way to tell game to not start?
            process, wait, SC2.exe
            sleep 2000
            process, close, SC2.exe
        }
        "
}

#----------------------------------------------------------------

w_metadata theundergarden_demo games \
    title="The UnderGarden Demo" \
    publisher="Atari" \
    year="2010" \
    media="manual_download" \
    file1="TheUnderGarden_PC_B34_SRTB.30_28OCT10.exe" \
    installed_exe1="$W_PROGRAMS_X86_WIN/The UnderGarden/TheUndergarden.exe"

load_theundergarden_demo()
{
    w_download_manual http://www.bigdownload.com/games/the-undergarden/pc/the-undergarden-demo TheUnderGarden_PC_B34_SRTB.30_28OCT10.exe acf90c422ac2f2f242100f39bedfe7df0c95f7a

    w_try_cd "$W_CACHE/$W_PACKAGE"

    w_ahk_do "
        SetTitleMatchMode, 2
        Run, TheUnderGarden_PC_B34_SRTB.30_28OCT10.exe
        WinWait,WinRAR
        if ( w_opt_unattended > 0 ) {
            Sleep 500
            ControlClick Button2 ; Install
            WinWait,Select Setup Language, during
            Sleep 500
            ControlClick TNewButton1 ;OK
            WinWait,Setup - The UnderGarden, your
            Sleep 500
            ControlClick TNewButton1 ;OK
            WinWait,Setup - The UnderGarden, License
            Sleep 500
            ControlClick TNewRadioButton1 ; accept
            Sleep 500
            ControlClick TNewButton2 ; Next
            WinWait,Setup - The UnderGarden, different
            Sleep 500
            ControlClick TNewButton3 ;Next
            WinWait,Setup - The UnderGarden, shortcuts
            Sleep 500
            ControlClick TNewButton4 ;OK
            WinWait,Setup - The UnderGarden, additional
            Sleep 500
            ControlFocus,TNewCheckListBox1,desktop
            Sleep 500
            Send {Space}
            Sleep 500
            ControlClick TNewButton4 ; Next
            WinWait,Setup - The UnderGarden, review
            Sleep 500
            ControlClick TNewButton4 ;Install
            WinWait,Microsoft Visual C, Visual
            Sleep 500
            ControlClick Button13 ;Cancel
            WinWait,Microsoft Visual C, want
            Sleep 500
            ControlClick Button1 ;Yes
            WinWait,Microsoft Visual C, chosen
            Sleep 500
            ControlClick Button2 ;Finish
            WinWait,Framework 3, Press
            Sleep 500
            ControlClick Button21 ;Cancel
            WinWait,Framework 3, want
            Sleep 500
            ControlClick Button1 ;Yes
            WinWait,Installing Microsoft, Runtime
            Sleep 500
            ControlClick Button6 ;Cancel
        }
        WinWait,Setup,launched
        if ( w_opt_unattended > 0 ) {
            Sleep 500
            ControlClick TNewButton4 ;Finish
        }
        WinWaitClose,Setup,launched
    "
}

#----------------------------------------------------------------

w_metadata tmnationsforever games \
    title="TrackMania Nations Forever" \
    publisher="Nadeo" \
    year="2009" \
    media="download" \
    file1="tmnationsforever_setup.exe" \
    installed_exe1="$W_PROGRAMS_X86_WIN/TmNationsForever/TmForever.exe"

load_tmnationsforever()
{
    # 2011/03/29: 2f659138ed4409da404970841e18f03d29921beaf6a424824c8312ddb20f6355
    w_download "http://files.trackmaniaforever.com/tmnationsforever_setup.exe" 2f659138ed4409da404970841e18f03d29921beaf6a424824c8312ddb20f6355

    w_try_cd "$W_CACHE/$W_PACKAGE"

    w_ahk_do "
        SetTitleMatchMode, 2
        Run, tmnationsforever_setup.exe
        WinWait,Select Setup Language
        if ( w_opt_unattended > 0 ) {
            Sleep 1000
            ControlClick TNewButton1 ; OK
            WinWait,Setup - TmNationsForever,Welcome
            Sleep 1000
            ControlClick TNewButton1 ; Next
            WinWait,Setup - TmNationsForever,License
            Sleep 1000
            ControlClick TNewRadioButton1 ; Accept
            Sleep 1000
            ControlClick TNewButton2 ; Next
            WinWait,Setup - TmNationsForever,Where
            Sleep 1000
            ControlClick TNewButton3 ; Next
            WinWait,Setup - TmNationsForever,shortcuts
            Sleep 1000
            ControlClick TNewButton4 ; Next
            WinWait,Setup - TmNationsForever,perform
            Sleep 1000
            ControlClick TNewButton4 ; Next
            WinWait,Setup - TmNationsForever,installing
            Sleep 1000
            ControlClick TNewButton4 ; Install
        }
        WinWait,Setup - TmNationsForever,finished
        if ( w_opt_unattended > 0 ) {
            Sleep 1000
            ControlFocus, TNewCheckListBox1, TmNationsForever, finished
            Sleep 1000
            Send {Space} ; don't start game
            ControlClick TNewButton4 ; Finish
        }
        WinWaitClose
    "
}

#----------------------------------------------------------------

w_metadata trainztcc_2004 games \
    title="Trainz: The Complete Collection: TRS2004" \
    publisher="Paradox Interactive" \
    year="2008" \
    media="dvd" \
    file1="TRS2006DVD.iso" \
    installed_exe1="$W_PROGRAMS_X86_WIN/Auran/TRS2004/TRS2004.exe"

load_trainztcc_2004()
{
    w_call mfc42

    w_read_key
    # yup, they got the volume name wrong
    w_mount TRS2006DVD
    w_try_cd ${W_ISO_MOUNT_ROOT}/TRS2004_SP4_DVD_Installer_BUILD_2370/Installer/Disk1
    w_ahk_do "
        SetTitleMatchMode, 2
        SetWinDelay 500
        run setup.exe
        if ( w_opt_unattended > 0 ) {
            winwait TRS2004 Setup, Please install the latest drivers
            send {Enter}
            winwait TRS2004, Welcome
            send {Enter}
            winwait TRS2004, License
            ControlClick Button2
            winwait TRS2004, serial
            winactivate
            send ${W_RAW_KEY}{Enter}
            winwait TRS2004, Destination
            send {Enter}
            winwait Install DirectX
            send n
            winwait Windows Update, Your computer already
            send {Enter}
        }
        winwait TRS2004, Complete
        if ( w_opt_unattended > 0 ) {
            send {Space}     ; uncheck View Readme
            send {Enter}     ; Finish
        }
        winwaitclose
    "

    # And, while we're at it, also install the accompanying paint shed app
    w_try_cd ${W_ISO_MOUNT_ROOT}/TRAINZ_PAINTSHED
    w_ahk_do "
        SetTitleMatchMode, 2
        SetWinDelay 500
        run Trainz_Paint_Shed_Setup.exe
        if ( w_opt_unattended > 0 ) {
            winwait Trainz Paint Shed, Welcome
            send {Enter}
            winwait Trainz Paint Shed, License
            send a           ; accept
            send {Enter}     ; Next
            winwait Trainz Paint Shed, Destination
            send {Enter}
            winwait Trainz Paint Shed, Install
            send {Enter}
        }
        winwait Trainz Paint Shed, Complete
        if ( w_opt_unattended > 0 ) {
            send {Enter}     ; Finish
        }
        winwaitclose
    "
}

#----------------------------------------------------------------

w_metadata sammax301_demo games \
    title="Sam & Max 301: The Penal Zone" \
    publisher="Telltale Games" \
    year="2010" \
    media="manual_download" \
    file1="SamMax301_PC_Setup.exe" \
    installed_exe1="$W_PROGRAMS_X86_WIN/Telltale Games/Sam and Max - The Devil's Playhouse/The Penal Zone/SamMax301.exe"

load_sammax301_demo()
{
    w_download_manual "https://www.fileplanet.com/211314/210000/fileinfo/Sam-&-Max:-Devil's-Playhouse---Episode-One-Demo" SamMax301_PC_Setup.exe bed2c16c0254881e7770743f936b8926fa202b91d281bb8c2dd34305d0c0a84a

    w_try_cd "$W_CACHE/$W_PACKAGE"
    w_ahk_do "
        SetTitleMatchMode, 2
        SetWinDelay 500
        run SamMax301_PC_Setup.exe
        winwait Sam and Max The Penal Zone Setup, Welcome
        if ( w_opt_unattended > 0 ) {
            controlclick button2 ; Next
            winwait Sam and Max The Penal Zone Setup, DirectX
            controlclick button5 ; Uncheck check directx
            controlclick button2 ; Next
            winwait Sam and Max The Penal Zone Setup, License
            controlclick button2 ; I Agree
            winwait Sam and Max The Penal Zone Setup, Location
            controlclick button2 ; Install
            winwait Sam and Max The Penal Zone Setup, Finish
            controlclick button4 ; Uncheck play now
            controlclick button5 ; Uncheck create shortcut
            controlclick button2 ; Finish
        }
        winwaitclose Sam and Max The Penal Zone Setup
    "
}

#----------------------------------------------------------------

w_metadata sammax304_demo games \
    title="Sam & Max 304: Beyond the Alley of the Dolls" \
    publisher="Telltale Games" \
    year="2010" \
    media="manual_download" \
    file1="SamMax304_PC_setup.exe" \
    installed_exe1="$W_PROGRAMS_X86_WIN/Telltale Games/Sam and Max - The Devil's Playhouse/Beyond the Alley of the Dolls/SamMax304.exe"

load_sammax304_demo()
{
    w_download_manual "https://www.fileplanet.com/214770/210000/fileinfo/Sam-&-Max:-The-Devi's-Playhouse---Beyond-the-Alley-of-the-Dolls-Demo" SamMax304_PC_setup.exe 51c85e98857d15c59d9bb808ee16794cc0caf39799c50545bffdf359eac4c70a

    w_try_cd "$W_CACHE/$W_PACKAGE"
    w_ahk_do "
        SetTitleMatchMode, 2
        Run, $file1
        WinWait,Sam and Max Beyond the Alley of the Dolls Setup
        if ( w_opt_unattended > 0 ) {
            ControlClick Button2 ; Next
            WinWait,Sam and Max Beyond the Alley of the Dolls Setup,DirectX
            ControlClick Button2 ; Next - Directx check defaulted
            WinWait,Sam and Max Beyond the Alley of the Dolls Setup,License
            ControlClick Button2 ; Agree
            WinWait,Sam and Max Beyond the Alley of the Dolls Setup,Location
            ControlClick Button2 ; Install
            WinWait,Sam and Max Beyond the Alley of the Dolls Setup,Finish
            ControlClick Button4 ; Uncheck Play Now
            ControlClick Button2 ; Finish
        }
        WinWaitClose
    "
}

#----------------------------------------------------------------

w_metadata tropico3_demo games \
    title="Tropico 3 Demo" \
    publisher="Kalypso Media GmbH" \
    year="2009" \
    media="manual_download" \
    file1="Tropico3Demo.exe" \
    installed_exe1="$W_PROGRAMS_X86_WIN/Kalypso/Tropico 3 Demo/Tropico3 Demo.exe"

load_tropico3_demo()
{
    w_download_manual https://www.fileplanet.com/204947/200000/fileinfo/Tropico-3-Demo Tropico3Demo.exe c4c06858cb1e0b9ff29dc8de6ecb8eb9cf699ce31609fbfa848d5dbc83c9d3e0

    w_try_cd "$W_CACHE/$W_PACKAGE"

    w_ahk_do "
        SetWinDelay 1000
        SetTitleMatchMode, 2
        Run, Tropico3Demo.exe
        WinWait,Installer
        if ( w_opt_unattended > 0 ) {
            ControlClick Button1 ; OK
            WinWait,Tropico,Welcome
            ControlClick Button2 ; Next
            WinWait,Tropico,License
            ControlClick Button2 ; Agree
            WinWait,Tropico,Typical
            ControlClick Button2 ; Next
        }
        WinWait,Tropico,Completing
        if ( w_opt_unattended > 0 ) {
            ControlClick Button4 ; Uncheck Run Now
            ControlClick Button2 ; Finish
        }
        WinWaitClose
    "
}

#----------------------------------------------------------------

w_metadata singularity games \
    title="Singularity" \
    publisher="Activision" \
    year="2010" \
    media="dvd" \
    file1="SNG_DVD.iso"

load_singularity()
{
    w_read_key
    w_mount SNG_DVD

    w_ahk_do "
        run ${W_ISO_MOUNT_LETTER}:setup.exe
        winwait, Activision(R) - InstallShield, Select the language for the installation from the choices below.
        if ( w_opt_unattended > 0 ) {
            sleep 1000
            controlclick, Button1, Activision(R) - InstallShield, Select the language for the installation from the choices below.
            sleep 1000
            winwait, Singularity(TM), Keycode Check
            sleep 1000
            Send $W_KEY
            sleep 1000
            Send {Enter}
            ; Well this is annoying...
            Winwait, Keycode Check, The Keycode you entered appears to be valid.
            sleep 1000
            Send {Enter}
            winwait, Singularity(TM), The InstallShield Wizard will install Singularity(TM) on your computer
            sleep 1000
            controlclick, Button1, Singularity(TM), The InstallShield Wizard will install Singularity(TM) on your computer
            winwait, Singularity(TM), Please read the following license agreement carefully
            sleep 1000
            controlclick, Button5, Singularity(TM), Please read the following license agreement carefully
            sleep 1000
            controlclick, Button2, Singularity(TM), Please read the following license agreement carefully
            winwait, Singularity(TM), Minimum System Requirements
            sleep 1000
            controlclick, Button1, Singularity(TM), Minimum System Requirements
            winwait, Singularity(TM), Select the setup type to install
            controlclick, Button4, Singularity(TM), Select the setup type to install
        }
        ; Loop until installer window has been gone for at least two seconds
        Loop
        {
            sleep 1000
            IfWinExist, Singularity
                continue
            IfWinExist, Activision
                continue
            sleep 1000
            IfWinExist, Singularity
                continue
            IfWinExist, Activision
                continue
            break
        }
        "

    # Clean up crap left over in c:\ when the installer runs the vc 2008 redistributable installer
    w_try_cd "$W_DRIVE_C"
    rm -f VC_RED.* eula.*.txt globdata.ini install.exe install.ini install.res.*.dll vcredist.bmp
}

#----------------------------------------------------------------

w_metadata torchlight games \
    title="Torchlight - boxed version" \
    publisher="Runic Games" \
    year="2009" \
    media="dvd" \
    file1="Torchlight.iso"

load_torchlight()
{
    w_mount "Torchlight"
    w_ahk_do "
        SetTitleMatchMode, 2
        Run, ${W_ISO_MOUNT_LETTER}:Torchlight.exe
        WinWait, Torchlight Setup, This wizard will guide
        if ( w_opt_unattended > 0 ) {
            sleep 1000
            ControlClick, Button2, Torchlight Setup, This wizard will guide
            WinWait, Torchlight Setup, Please review the license terms
            sleep 1000
            ControlClick, Button2, Torchlight Setup, Please review the license terms
            WinWait, Torchlight Setup, Choose Install Location
            sleep 1000
            ControlClick, Button2, Torchlight Setup, Choose Install Location
            WinWait, Torchlight Setup, Installation Complete
            sleep 1000
            ControlClick, Button2, Torchlight Setup, Installation Complete
            WinWait, Torchlight Setup, Completing the Torchlight Setup Wizard
            sleep 1000
            ControlClick, Button4, Torchlight Setup, Completing the Torchlight Setup Wizard
            ControlClick, Button2, Torchlight Setup, Completing the Torchlight Setup Wizard
        }
        WinWaitClose, Torchlight Setup
    "
}

#----------------------------------------------------------------

w_metadata twfc games \
    title="Transformers: War for Cybertron" \
    publisher="Activision" \
    year="2010" \
    media="dvd" \
    file1="TWFC_DVD.iso"

load_twfc()
{
    w_read_key
    w_mount TWFC_DVD

    w_ahk_do "
        run ${W_ISO_MOUNT_LETTER}:setup.exe
        SetTitleMatchMode, 2
        winwait, Activision, Select the language for the installation
        if ( w_opt_unattended > 0 ) {
            sleep 1000
            controlclick, Button1, Activision, Select the language for the installation
            winwait, Transformers, Press NEXT to verify your key
            sleep 1000
            send $W_KEY
            send {Enter}
            winwait, Keycode Check, The Keycode you entered appears to be valid
            sleep 1000
            send {Enter}
            winwait, Transformers, The InstallShield Wizard will install Transformers
            sleep 1000
            controlclick, Button1, Transformers, The InstallShield Wizard will install Transformers
            winwait, Transformers, License Agreement
            sleep 1000
            controlclick, Button5, Transformers, License Agreement
            sleep 1000
            controlclick, Button2, Transformers, License Agreement
            winwait, Transformers, Minimum System Requirements
            sleep 1000
            controlclick, Button1, Transformers, Minimum System Requirements
            winwait, Transformers, Select the setup type to install
            sleep 1000
            controlclick, Button4, Transformers, Select the setup type to install
        }
        ; Installer exits silently. Prevent an early umount
        Loop
        {
            sleep 1000
            IfWinExist, Transformers
                continue
            IfWinExist, Activision
                continue
            sleep 1000
            IfWinExist, Transformers
                continue
            IfWinExist, Activision
                continue
            break
        }
    "

    # Clean up crap left over in c:\ when the installer runs the vc 2008 redistributable installer
    w_try_cd "$W_DRIVE_C"
    rm -f VC_RED.* eula.*.txt globdata.ini install.exe install.ini install.res.*.dll vcredist.bmp
}

#----------------------------------------------------------------

w_metadata typingofthedead_demo games \
    title="Typing of the Dead Demo" \
    publisher="Sega" \
    year="1999" \
    media="manual_download" \
    file1="Tod_e_demo.exe" \
    installed_exe1="$W_PROGRAMS_X86_WIN/SEGA/TOD-Demo/Tod_e_demo.exe"

load_typingofthedead_demo()
{
    w_download_manual "https://www.fileplanet.com/54947/50000/fileinfo/The-Typing-of-the-Dead-Demo" tod-demo.zip feb0888b6cf1d51af2bf3d752e1727b5d248c2704ca053561f384b55e86267ea
    w_try_cd "$W_TMP"
    w_try_unzip . "$W_CACHE/$W_PACKAGE/tod-demo.zip"
    w_ahk_do "
        SetTitleMatchMode, 2
        run SETUP.EXE
        if ( w_opt_unattended > 0 ) {
            WinWait,InstallShield Wizard,where
            sleep 1000
            ControlClick Button1 ; Next
            WinWait,InstallShield Wizard,icons
            sleep 1000
            ControlClick Button2 ; Next
        }
        ; installer crashes here?
        Sleep 20000
    "
}

#----------------------------------------------------------------

w_metadata ut3 games \
    title="Unreal Tournament 3" \
    publisher="Midway Games" \
    year="2007" \
    media="dvd" \
    file1="UT3_RC7.iso" \
    file2="UT3Patch5.exe" \
    installed_exe1="$W_PROGRAMS_X86_WIN/Unreal Tournament 3/Binaries/UT3.exe"

load_ut3()
{
    w_download_manual "http://www.filefront.com/13709855/UT3Patch5.exe" UT3Patch5.exe
    w_try w_mount UT3_RC7

    w_ahk_do "
        run ${W_ISO_MOUNT_LETTER}:SetupUT3.exe
        SetTitleMatchMode, slow    ; else can't see EULA text
        SetTitleMatchMode, 2
        SetWinDelay 1000
        WinWait, Choose Setup Language
        if ( w_opt_unattended > 0 ) {
            ControlClick Button1   ; OK
            WinWait, Unreal Tournament 3, GAMESPY ; License Agreement
            ControlClick Button2   ; Yes
            WinWait, Unreal Tournament 3, UnrealEd ; License Agreement
            ControlClick Button2   ; Yes
            WinWait, , Choose Destination
            ControlClick Button1   ; Next
            WinWait, AGEIA PhysX v7.09.13 Setup, License
            ControlClick Button3   ; Accept
            sleep 1000
            ControlClick Button4   ; Next
            WinWait, AGEIA PhysX v7.09.13, Finish
            ControlClick Button1   ; Finish
            ; game now begins installing
        }
        WinWait, , InstallShield Wizard Complete
        if ( w_opt_unattended > 0 ) {
            ControlClick Button4   ; Finish
        }
        WinWaitClose
    "

    w_try_cd "$W_CACHE/$W_PACKAGE"

    w_ahk_do "
        SetTitleMatchMode, 2
        run UT3Patch5.exe
        WinWait, License
        if ( w_opt_unattended > 0 ) {
            ControlClick Button1   ; Accept
            WinWait, End User License Agreement
            ControlClick Button1   ; Accept
            WinWait, Patch UT3
            ControlClick Button1   ; Yes
        }
        WinWait, , UT3 was successfully patched!
        if ( w_opt_unattended > 0 ) {
            ControlClick Button1   ; OK
        }
        WinWaitClose
    "
}

#----------------------------------------------------------------

w_metadata wog games \
    title="World of Goo Demo" \
    publisher="2D Boy" \
    year="2008" \
    media="download" \
    file1="WorldOfGooDemo.1.0.exe" \
    installed_exe1="$W_PROGRAMS_X86_WIN/WorldOfGooDemo/WorldOfGoo.exe"

load_wog()
{
    if ! test -f "$W_CACHE/wog/WorldOfGooDemo.1.0.exe"; then
        # Get temporary download location
        w_download "https://www.worldofgoo.com/dl2.php?lk=demo&filename=WorldOfGooDemo.1.0.exe"
        URL=$(grep WorldOfGooDemo.1.0.exe "$W_CACHE/wog/dl2.php?lk=demo&filename=WorldOfGooDemo.1.0.exe" \
            | sed 's,.*http,http,;s,".*,,')
        w_try rm "$W_CACHE/wog/dl2.php?lk=demo&filename=WorldOfGooDemo.1.0.exe"

        w_download "$URL" 07892e927e0c403a178717b67928d3b4126dd0ed4f82afa20a4bd2496706c5e9
    fi

    w_try_cd "$W_CACHE/$W_PACKAGE"
    w_ahk_do "
        SetWinDelay 500
        run WorldOfGooDemo.1.0.exe
        winwait, World of Goo Setup, License Agreement
        if ( w_opt_unattended > 0 ) {
            sleep 1000
            WinActivate
            send {Enter}
            winwait, World of Goo Setup, Choose Components
            send {Enter}
            winwait, World of Goo Setup, Choose Install Location
            send {Enter}
            winwait, World of Goo Setup, Thank you
            ControlClick, Make me dirty right now, World of Goo Setup, Thank you
            send {Enter}
        }
        winwaitclose, World of Goo Setup
        "
}

#----------------------------------------------------------------
# Gog.com games
#----------------------------------------------------------------

w_metadata beneath_a_steel_sky_gog games \
    title="Beneath a Steel Sky (GOG.com, free)" \
    publisher="Virgin Interactive" \
    year="1994" \
    file1="setup_beneath_a_steel_sky.exe" \
    installed_exe1="$W_PROGRAMS_X86_WIN/GOG.com/Beneath a Steel Sky/ScummVM/scummvm.exe"

load_beneath_a_steel_sky_gog()
{
    winetricks_load_gog "beneath_a_steel_sky" "Beneath a Steel Sky" "" "TsCheckBox4" "ScummVM\\scummvm.exe -c \"C:\\Program Files\\GOG.com\\Beneath a Steel Sky\\beneath.ini\" beneath" "" "" "75176395,1f99e12643529baa91fecfb206139a8921d9589c"
}

w_metadata sacrifice_gog games \
    title="Sacrifice (GOG.com)" \
    publisher="Interplay" \
    year="2000" \
    media="manual_download" \
    file1="setup_sacrifice.exe" \
    installed_exe1="$W_PROGRAMS_X86_WIN/GOG.com/Sacrifice/Sacrifice.exe"

load_sacrifice_gog()
{
    winetricks_load_gog "sacrifice" "Sacrifice" "" "TsCheckBox2" "sacrifice" "" "" "591161642,63e77685599ce20c08b004a9fa3324e466ce1679"
}

w_metadata the_witcher_2_gog games \
    title="The Witcher 2: Assassins of Kings" \
    publisher="Atari" \
    year="2011" \
    media="manual_download" \
    file1="setup_the_witcher_2_ee_3.0.1.17.exe" \
    installed_exe1="$W_PROGRAMS_X86_WIN/GOG.com/The Witcher 2/bin/witcher2.exe"

load_the_witcher_2_gog()
{
    winetricks_load_gog "the_witcher_2" \
        "The Witcher 2 - Assassins of Kings" \
        "setup_the_witcher_2-1.bin,2048477,b826cd7b096fd98eab78517752522b2a3ca8af5e\
        setup_the_witcher_2-2.bin,2050788,a419926e4d02de81d79d586bf893150d3231833c \
        setup_the_witcher_2-3.bin,2050788,6974cadc29fb8a8795aa245c5f8bb24e5e0cff5e \
        setup_the_witcher_2-4.bin,2050788,ed79c1e9456801addf6fd6e687528fa01354b0d8 \
        setup_the_witcher_2-5.bin,1631852,354cb73ae3e73cb88dedc53dd472803862a654cf \
        setup_the_witcher_2.bin,129136,d3aa93bf147e155c5035ae15444916feabfd47b4" \
        "" "bin/witcher2.exe" "" "The Witcher 2" \
        "2308,9ca06383301f242143f69fe08974f9d4d713ac6b"
}

# Brief HOWTO for adding a GOG game:
# - "beneath_a_steel_sky" is the installer exe name, minus "setup_" and ".exe"
# - "Beneath a Steel Sky" is installer window title, minus "Setup - "
# - There are no other files for this game, so this parameter is empty.
#   Otherwise it should be of the following form:
#   file_name[,length[,sha1sum]] [...]
# - "TsCheckBox4" is the control name for the checkbox deciding whether it will
#   install some reader (Foxit in this case, could be Acrobat Reader). That
#   installation is enabled by default, and would just bloat the generic
#   AutoHotKey script, so it gets disabled.
# - "ScummVM\\[...]" is the command line to run the game, as fetched from the
#   shortcut/launcher installer/wine creates, which will be used in BAT scripts
#   created by wisotool
# - The part in the URL which is specific to this game is identical to its "id"
#   (first parameter), so this parameter is left out.
# - The install directory is the same as installer window title (second
#   parameter), so this parameter is left out.
# - Main installer size and sha1sum, separated by a comma.

#----------------------------------------------------------------
# Steam Games
#----------------------------------------------------------------

w_metadata alienswarm_steam games \
    title="Alien Swarm (Steam)" \
    publisher="Valve" \
    year="2010" \
    media="download" \
    installed_exe1="$W_PROGRAMS_X86_WIN/Steam/steamapps/common/alien swarm/swarm.exe"

load_alienswarm_steam()
{
    w_steam_install_game 630 "Alien Swarm"
}

#----------------------------------------------------------------

w_metadata bioshock2_steam games \
    title="Bioshock 2 (Steam)" \
    publisher="2k" \
    year="2010" \
    media="download" \
    installed_exe1="$W_PROGRAMS_X86_WIN/Steam/steamapps/common/bioshock2/blort.exe"

load_bioshock2_steam()
{
    w_steam_install_game 8850 "BioShock 2"
}

#----------------------------------------------------------------

w_metadata borderlands_steam games \
    title="Borderlands (Steam, non-free)" \
    publisher="2K Games" \
    year="2009" \
    media="download" \
    installed_exe1="$W_PROGRAMS_X86_WIN/Steam/steamapps/common/borderlands/Binaries/Borderlands.exe"

load_borderlands_steam()
{
    w_steam_install_game 8980 "Borderlands"
}

#----------------------------------------------------------------

w_metadata civ5_demo_steam games \
    title="Civilization V Demo (Steam)" \
    publisher="2K Games" \
    year="2010" \
    media="download" \
    installed_exe1="$W_PROGRAMS_X86_WIN/Steam/steamapps/common/sid meier's civilization v - demo/CivilizationV.exe"

load_civ5_demo_steam()
{
    # Start AutoHotKey watching for DirectX 9 option in the background, and select it when it comes up
    w_ahk_do  "
        SetWinDelay 500
        loop
        {
            ifWinExist, Sid Meier's Civilization V - Demo - Steam
            {
                winactivate
                click 26,108    ; select directx9
                sleep 500
                click 200,150   ; Play
            }
            ifWinExist, Updating Sid Meier's Civilization V - Demo
            {
                break
            }
            sleep 1000
        }
    " &
    _job=$!
        # While that's running, install the game.
        # You'll see *two* AutoHotKey icons until that first script
        # finds the dialog it's looking for, clicks, and exits.
        w_info "If you already own the full Civ 5 game on Steam, the installer won't even appear."
    w_steam_install_game 65900 "Sid Meier's Civilization V - Demo"
    kill -s HUP "$_job"   # just in case
}

#----------------------------------------------------------------

w_metadata ruse_demo_steam games \
    title="Ruse Demo (Steam)" \
    publisher="Ubisoft" \
    year="2010" \
    media="download" \
    installed_exe1="$W_PROGRAMS_X86_WIN/Steam/steamapps/common/r.u.s.e. demo/Ruse.exe"

load_ruse_demo_steam()
{
    w_steam_install_game 33310 "R.U.S.E."
}

#----------------------------------------------------------------

w_metadata supermeatboy_steam games \
    title="Super Meat Boy (Steam, non-free)" \
    publisher="Independent" \
    year="2010" \
    media="download" \
    installed_exe1="$W_PROGRAMS_X86_WIN/Steam/steamapps/common/super meat boy/SuperMeatBoy.exe"

load_supermeatboy_steam()
{
    w_steam_install_game 40800 "Super Meat Boy"
}

#----------------------------------------------------------------

w_metadata trine_steam games \
    title="Trine (Steam)" \
    publisher="Frozenbyte" \
    year="2009" \
    media="download" \
    installed_exe1="$W_PROGRAMS_X86_WIN/Steam/steamapps/common/trine/trine_launcher.exe"

load_trine_steam()
{
    w_steam_install_game 35700 "Trine"
}

#----------------------------------------------------------------

w_metadata trine_demo_steam games \
    title="Trine Demo (Steam)" \
    publisher="Frozenbyte" \
    year="2009" \
    media="download" \
    installed_exe1="$W_PROGRAMS_X86_WIN/Steam/steamapps/common/trine demo/trine_launcher.exe"

load_trine_demo_steam()
{
    w_steam_install_game 35710 "Trine Demo"
}

#----------------------------------------------------------------

w_metadata wormsreloaded_demo_steam games \
    title="Worms Reloaded Demo (Steam)" \
    publisher="Team17" \
    year="2010" \
    media="download" \
    installed_exe1="$W_PROGRAMS_X86_WIN/Steam/steamapps/common/worms reloaded/WormsReloaded.exe"

load_wormsreloaded_demo_steam()
{
    w_steam_install_game 22690 "Worms Reloaded Demo"
}

#######################
# settings
#######################

####
# settings->desktop
#----------------------------------------------------------------
# DirectInput settings

w_metadata mwo=force settings \
    title_uk="Встановити примусове DirectInput MouseWarpOverride (необхідно для деяких ігор)" \
    title="Set DirectInput MouseWarpOverride to force (needed by some games)"
w_metadata mwo=enabled settings \
    title_uk="Увімкнути DirectInput MouseWarpOverride (за замовчуванням)" \
    title="Set DirectInput MouseWarpOverride to enabled (default)"
w_metadata mwo=disable settings \
    title_uk="Вимкнути DirectInput MouseWarpOverride" \
    title="Set DirectInput MouseWarpOverride to disable"

load_mwo()
{
    # Filter out/correct bad or partial values
    # Confusing because dinput uses 'disable', but d3d uses 'disabled'
    # see alloc_device() in dlls/dinput/mouse.c
    case "$1" in
        enable*) arg=enabled;;
        disable*) arg=disable;;
        force) arg=force;;
    *) w_die "illegal value $1 for MouseWarpOverride";;
    esac

    echo "Setting MouseWarpOverride to $arg"
    cat > "$W_TMP"/set-mwo.reg <<_EOF_
REGEDIT4

[HKEY_CURRENT_USER\\Software\\Wine\\DirectInput]
"MouseWarpOverride"="$arg"

_EOF_
    w_try_regedit "$W_TMP"/set-mwo.reg
}

#----------------------------------------------------------------

w_metadata fontfix settings \
    title_uk="Перевірка шрифтів" \
    title="Check for broken fonts"

load_fontfix()
{
    # Focht says Samyak is bad news, and font substitution isn't a good workaround.
    # I've seen psdkwin7 setup crash because of this; the symptom was a messagebox saying
    # SDKSetup encountered an error: The type initializer for 'Microsoft.WizardFramework.WizardSettings' threw an exception
    # and WINEDEBUG=+relay,+seh shows an exception very quickly after
    # Call KERNEL32.CreateFileW(0c83b36c L"Z:\\USR\\SHARE\\FONTS\\TRUETYPE\\TTF-ORIYA-FONTS\\SAMYAK-ORIYA.TTF",80000000,00000001,00000000,00000003,00000080,00000000) ret=70d44091
    if [ -x "$(command -v xlsfonts 2>/dev/null)" ] ; then
        if xlsfonts 2>/dev/null | grep -E -i "samyak.*oriya" ; then
            w_die "Please uninstall the Samyak/Oriya font, e.g. 'sudo dpkg -r ttf-oriya-fonts', then log out and log in again.  That font causes strange crashes in .net programs."
        fi
    else
        w_warn "xlsfonts not found. If you have (older versions of) Samyak/Oriya fonts installed, you may get crashes/bugs. If so, uninstall, then logout/login again to resolve."
    fi
}

#----------------------------------------------------------------

w_metadata fontsmooth=disable settings \
    title_uk="Вимкнути згладжування шрифту" \
    title="Disable font smoothing"
w_metadata fontsmooth=bgr settings \
    title_uk="Увімкнути субпіксельне згладжування шрифту для BGR LCD моніторів" \
    title="Enable subpixel font smoothing for BGR LCDs"
w_metadata fontsmooth=rgb settings \
    title_uk="Увімкнути субпіксельне згладжування шрифту для RGB LCD моніторів" \
    title="Enable subpixel font smoothing for RGB LCDs"
w_metadata fontsmooth=gray settings \
    title_uk="Увімкнути субпіксельне згладжування шрифту" \
    title="Enable subpixel font smoothing"

load_fontsmooth()
{
    case "$1" in
        disable)   FontSmoothing=0; FontSmoothingOrientation=1; FontSmoothingType=0;;
        gray|grey) FontSmoothing=2; FontSmoothingOrientation=1; FontSmoothingType=1;;
        bgr)       FontSmoothing=2; FontSmoothingOrientation=0; FontSmoothingType=2;;
        rgb)       FontSmoothing=2; FontSmoothingOrientation=1; FontSmoothingType=2;;
        *) w_die "unknown font smoothing type $1";;
    esac

    echo "Setting font smoothing to $1"

    cat > "$W_TMP"/fontsmooth.reg <<_EOF_
REGEDIT4

[HKEY_CURRENT_USER\\Control Panel\\Desktop]
"FontSmoothing"="$FontSmoothing"
"FontSmoothingGamma"=dword:00000578
"FontSmoothingOrientation"=dword:0000000$FontSmoothingOrientation
"FontSmoothingType"=dword:0000000$FontSmoothingType

_EOF_
    w_try_regedit "$W_TMP_WIN"\\fontsmooth.reg
}

#----------------------------------------------------------------
# Mac Driver settings

w_metadata macdriver=mac settings \
    title_uk="Увімкнути рідний Mac Quartz драйвер (за замовчуванням)" \
    title="Enable the Mac native Quartz driver (default)"
w_metadata macdriver=x11 settings \
    title_uk="Вимкнути рідний Mac Quartz драйвер та використовувати замість нього X11" \
    title="Disable the Mac native Quartz driver, use X11 instead"

load_macdriver()
{
    echo "Setting MacDriver to $arg"
    cat > "$W_TMP"/set-mac.reg <<_EOF_
REGEDIT4

[HKEY_CURRENT_USER\\Software\\Wine\\Drivers]
"Graphics"="$arg"

_EOF_
    w_try_regedit "$W_TMP"/set-mac.reg
}

#----------------------------------------------------------------
# X11 Driver settings

w_metadata grabfullscreen=y settings \
    title_uk="Примусове захоплення курсору для повноекранних вікон (необхідно для деяких ігор)" \
    title="Force cursor clipping for full-screen windows (needed by some games)"
w_metadata grabfullscreen=n settings \
    title_uk="Вимкнути примусове захоплення курсору для повноекранних вікон (за замовчуванням)" \
    title="Disable cursor clipping for full-screen windows (default)"

load_grabfullscreen()
{
    case "$1" in
        y|n) arg=$1;;
        *) w_die "illegal value $1 for GrabFullscreen";;
    esac

    echo "Setting GrabFullscreen to $arg"
    cat > "$W_TMP"/set-gfs.reg <<_EOF_
REGEDIT4

[HKEY_CURRENT_USER\\Software\\Wine\\X11 Driver]
"GrabFullscreen"="$arg"

_EOF_
    w_try_regedit "$W_TMP"/set-gfs.reg
}

w_metadata windowmanagerdecorated=y settings \
    title_uk="Дозволити менеджеру вікон декорувати вікна (за замовчуванням)" \
    title="Allow the window manager to decorate windows (default)"
w_metadata windowmanagerdecorated=n settings \
    title_uk="Не дозволяти менеджеру вікон декорувати вікна" \
    title="Prevent the window manager from decorating windows"

load_windowmanagerdecorated()
{
    case "$1" in
        y|n) arg=$1;;
        *) w_die "illegal value $1 for Decorated";;
    esac

    echo "Setting Decorated to $arg"
    cat > "$W_TMP"/set-wmd.reg <<_EOF_
REGEDIT4

[HKEY_CURRENT_USER\\Software\\Wine\\X11 Driver]
"Decorated"="$arg"

_EOF_
    w_try_regedit "$W_TMP"/set-wmd.reg
}

w_metadata windowmanagermanaged=y settings \
    title_uk="Дозволити менеджеру вікон керування вікнами (за замовчуванням)" \
    title="Allow the window manager to control windows (default)"
w_metadata windowmanagermanaged=n settings \
    title_uk="Не дозволяти менеджеру вікон керування вікнами" \
    title="Prevent the window manager from controlling windows"

load_windowmanagermanaged()
{
    case "$1" in
        y|n) arg=$1;;
        *) w_die "illegal value $1 for Managed";;
    esac

    echo "Setting Managed to $arg"
    cat > "$W_TMP"/set-wmm.reg <<_EOF_
REGEDIT4

[HKEY_CURRENT_USER\\Software\\Wine\\X11 Driver]
"Managed"="$arg"

_EOF_
    w_try_regedit "$W_TMP"/set-wmm.reg
}

#----------------------------------------------------------------

w_metadata vd=off settings \
    title_uk="Вимкнути віртуальний робочий стіл" \
    title="Disable virtual desktop"
w_metadata vd=640x480 settings \
    title_uk="Увімкнути віртуальний робочий стіл та встановити розмір 640x480" \
    title="Enable virtual desktop, set size to 640x480"
w_metadata vd=800x600 settings \
    title_uk="Увімкнути віртуальний робочий стіл та встановити розмір 800x600" \
    title="Enable virtual desktop, set size to 800x600"
w_metadata vd=1024x768 settings \
    title_uk="Увімкнути віртуальний робочий стіл та встановити розмір 1024x768" \
    title="Enable virtual desktop, set size to 1024x768"
w_metadata vd=1280x1024 settings \
    title_uk="Увімкнути віртуальний робочий стіл та встановити розмір 1280x1024" \
    title="Enable virtual desktop, set size to 1280x1024"
w_metadata vd=1440x900 settings \
    title_uk="Увімкнути віртуальний робочий стіл та встановити розмір 1440x900" \
    title="Enable virtual desktop, set size to 1440x900"

load_vd()
{
    size="$1"
    case $size in
        off|disabled)
        cat > "$W_TMP"/vd.reg <<_EOF_
REGEDIT4

[HKEY_CURRENT_USER\\Software\\Wine\\Explorer]
"Desktop"=-
[HKEY_CURRENT_USER\\Software\\Wine\\Explorer\\Desktops]
"Default"=-

_EOF_
        ;;
        [1-9]*x[1-9]*)
        cat > "$W_TMP"/vd.reg <<_EOF_
REGEDIT4

[HKEY_CURRENT_USER\\Software\\Wine\\Explorer]
"Desktop"="Default"
[HKEY_CURRENT_USER\\Software\\Wine\\Explorer\\Desktops]
"Default"="$size"

_EOF_
        ;;
        *)
        w_die "you want a virtual desktop of $size? I don't understand."
        ;;
    esac
    w_try_regedit "$W_TMP_WIN"/vd.reg
}

#----------------------------------------------------------------
# MIME-type file associations settings

w_metadata mimeassoc=on settings \
    title="Enable exporting MIME-type file associations to the native desktop (default)"
w_metadata mimeassoc=off settings \
    title="Disable exporting MIME-type file associations to the native desktop"

load_mimeassoc()
{
    case "$1" in
        off) arg=N;;
        on)  arg=Y;;
        *) w_die "illegal value $1 for mimeassoc";;
    esac

    echo "Setting mimeassoc to $arg"
    cat > "$W_TMP"/set-mimeassoc.reg <<_EOF_
REGEDIT4

[HKEY_CURRENT_USER\\Software\\Wine\\FileOpenAssociations]
"Enable"="$arg"

_EOF_
    w_try_regedit "$W_TMP"/set-mimeassoc.reg
}

####
# settings->direct3d

winetricks_set_wined3d_var()
{
    # Filter out/correct bad or partial values
    # Confusing because dinput uses 'disable', but d3d uses 'disabled'
    # see wined3d_dll_init() in dlls/wined3d/wined3d_main.c
    # and DllMain() in dlls/ddraw/main.c
    case $2 in
        disable*) arg=disabled;;
        enable*) arg=enabled;;
        hard*) arg=hardware;;
        repack) arg=repack;;
        backbuffer|fbo|gdi|none|opengl|readdraw|readtex|texdraw|textex|auto) arg=$2;;
        [0-9]*) arg=$2;;
        *) w_die "illegal value $2 for $1";;
    esac

    echo "Setting Direct3D/$1 to $arg"
    cat > "$W_TMP"/set-wined3d.reg <<_EOF_
REGEDIT4

[HKEY_CURRENT_USER\\Software\\Wine\\Direct3D]
"$1"="$arg"

_EOF_
    w_try_regedit "$W_TMP_WIN"\\set-wined3d.reg
}

#----------------------------------------------------------------
# AlwaysOffscreen settings

w_metadata ao=enabled settings \
    title_uk="Увімкнути AlwaysOffscreen" \
    title="Enable AlwaysOffscreen"
w_metadata ao=disabled settings \
    title_uk="Вимкнути AlwaysOffscreen (за замовчуванням)" \
    title="Disable AlwaysOffscreen (default)"

load_ao()
{
    winetricks_set_wined3d_var AlwaysOffscreen "$1"
}

#----------------------------------------------------------------
# CheckFloatConstants settings

w_metadata cfc=enabled settings \
    title_uk="Увімкнути CheckFloatConstants" \
    title="Enable CheckFloatConstants"
w_metadata cfc=disable settings \
    title_uk="Вимкнути CheckFloatConstants (за замовчуванням)" \
    title="Disable CheckFloatConstants (default)"

load_cfc()
{
    winetricks_set_wined3d_var CheckFloatConstants "$1"
}
#----------------------------------------------------------------
# CSMT settings

w_metadata csmt=on settings \
    title_uk="Увімкнути Command Stream Multithreading (за замовчуванням)" \
    title="Enable Command Stream Multithreading (default)"
w_metadata csmt=off settings \
    title_uk="Вимкнути Command Stream Multithreading"\
    title="Disable Command Stream Multithreading"

load_csmt()
{
    case "$1" in
        off) arg=0;;
        on)  arg=1;;
        *) w_die "illegal value $1 for csmt";;
    esac

    echo "Setting csmt to $arg"
    cat > "$W_TMP"/set-csmt.reg <<_EOF_
REGEDIT4

[HKEY_CURRENT_USER\\Software\\Wine\\Direct3D]
"csmt"=dword:$arg

_EOF_
    w_try_regedit "$W_TMP"/set-csmt.reg
}

#----------------------------------------------------------------
# DirectDraw settings

w_metadata ddr=gdi settings \
    title_uk="Встановити DirectDrawRenderer на gdi" \
    title="Set DirectDrawRenderer to gdi"
w_metadata ddr=opengl settings \
    title_uk="Встановити DirectDrawRenderer на opengl" \
    title="Set DirectDrawRenderer to opengl"

load_ddr()
{
    winetricks_set_wined3d_var DirectDrawRenderer "$1"
}

#----------------------------------------------------------------

w_metadata glsl=enabled settings \
    title_uk="Увімкнути GLSL шейдери (за замовчуванням)" \
    title="Enable GLSL shaders (default)"
w_metadata glsl=disabled settings \
    title_uk="Вимкнути GLSL шейдери та використовувати ARB шейдери (іноді впливає на швидкодію)" \
    title="Disable GLSL shaders, use ARB shaders (faster, but sometimes breaks)"

load_glsl()
{
    winetricks_set_wined3d_var UseGLSL "$1"
}

#----------------------------------------------------------------

w_metadata gsm=0 settings \
    title_uk="Встановити MaxShaderModelGS на 0" \
    title="Set MaxShaderModelGS to 0"
w_metadata gsm=1 settings \
    title_uk="Встановити MaxShaderModelGS на 1" \
    title="Set MaxShaderModelGS to 1"
w_metadata gsm=2 settings \
    title_uk="Встановити MaxShaderModelGS на 2" \
    title="Set MaxShaderModelGS to 2"
w_metadata gsm=3 settings \
    title_uk="Встановити MaxShaderModelGS на 3" \
    title="Set MaxShaderModelGS to 3"

load_gsm()
{
    winetricks_set_wined3d_var MaxShaderModelGS "$1"
}

#----------------------------------------------------------------

w_metadata multisampling=enabled settings \
    title_uk="Увімкнути Direct3D мультисемплінг" \
    title="Enable Direct3D multisampling"
w_metadata multisampling=disabled settings \
    title_uk="Вимкнути Direct3D мультисемплінг" \
    title="Disable Direct3D multisampling"

load_multisampling()
{
    winetricks_set_wined3d_var Multisampling "$1"
}

#----------------------------------------------------------------

w_metadata npm=repack settings \
    title_uk="Встановити NonPower2Mode на repack" \
    title="Set NonPower2Mode to repack"

load_npm()
{
    winetricks_set_wined3d_var NonPower2Mode "$1"
}

#----------------------------------------------------------------

w_metadata orm=fbo settings \
    title_uk="Встановити OffscreenRenderingMode=fbo (за замовчуванням)" \
    title="Set OffscreenRenderingMode=fbo (default)"
w_metadata orm=backbuffer settings \
    title_uk="Встановити OffscreenRenderingMode=backbuffer" \
    title="Set OffscreenRenderingMode=backbuffer"

load_orm()
{
    winetricks_set_wined3d_var OffscreenRenderingMode "$1"
}

#----------------------------------------------------------------

w_metadata psm=0 settings \
    title_uk="Встановити MaxShaderModelPS на 0" \
    title="Set MaxShaderModelPS to 0"
w_metadata psm=1 settings \
    title_uk="Встановити MaxShaderModelPS на 1" \
    title="Set MaxShaderModelPS to 1"
w_metadata psm=2 settings \
    title_uk="Встановити MaxShaderModelPS на 2" \
    title="Set MaxShaderModelPS to 2"
w_metadata psm=3 settings \
    title_uk="Встановити MaxShaderModelPS на 3" \
    title="Set MaxShaderModelPS to 3"

load_psm()
{
    winetricks_set_wined3d_var MaxShaderModelPS "$1"
}

#----------------------------------------------------------------

w_metadata strictdrawordering=enabled settings \
    title_uk="Увімкнути StrictDrawOrdering" \
    title="Enable StrictDrawOrdering"
w_metadata strictdrawordering=disabled settings \
    title_uk="Вимкнути StrictDrawOrdering (за замовчуванням)" \
    title="Disable StrictDrawOrdering (default)"

load_strictdrawordering()
{
    winetricks_set_wined3d_var StrictDrawOrdering "$1"
}

#----------------------------------------------------------------

w_metadata rtlm=auto settings \
    title_uk="Встановити RenderTargetLockMode на авто (за замовчуванням)" \
    title="Set RenderTargetLockMode to auto (default)"
w_metadata rtlm=disabled settings \
    title_uk="Вимкнути RenderTargetLockMode" \
    title="Set RenderTargetLockMode to disabled"
w_metadata rtlm=readdraw settings \
    title_uk="Встановити RenderTargetLockMode на readdraw" \
    title="Set RenderTargetLockMode to readdraw"
w_metadata rtlm=readtex settings \
    title_uk="Встановити RenderTargetLockMode на readtex" \
    title="Set RenderTargetLockMode to readtex"
w_metadata rtlm=texdraw settings \
    title_uk="Встановити RenderTargetLockMode на texdraw" \
    title="Set RenderTargetLockMode to texdraw"
w_metadata rtlm=textex settings \
    title_uk="Встановити RenderTargetLockMode на textex" \
    title="Set RenderTargetLockMode to textex"

load_rtlm()
{
    winetricks_set_wined3d_var RenderTargetLockMode "$1"
}
#----------------------------------------------------------------

w_metadata videomemorysize=default settings \
    title_uk="Дати можливість Wine визначити розмір відеопам'яті" \
    title="Let Wine detect amount of video card memory"
w_metadata videomemorysize=512 settings \
    title_uk="Повідомити Wine про 512МБ відеопам'яті" \
    title="Tell Wine your video card has 512MB RAM"
w_metadata videomemorysize=1024 settings \
    title_uk="Повідомити Wine про 1024МБ відеопам'яті" \
    title="Tell Wine your video card has 1024MB RAM"
w_metadata videomemorysize=2048 settings \
    title_uk="Повідомити Wine про 2048МБ відеопам'яті" \
    title="Tell Wine your video card has 2048MB RAM"

load_videomemorysize()
{
    size="$1"
    echo "Setting video memory size to $size"

    case $size in
        default)

    cat > "$W_TMP"/set-video.reg <<_EOF_
REGEDIT4

[HKEY_CURRENT_USER\\Software\\Wine\\Direct3D]
"VideoMemorySize"=-

_EOF_
    ;;
        *)
    cat > "$W_TMP"/set-video.reg <<_EOF_
REGEDIT4

[HKEY_CURRENT_USER\\Software\\Wine\\Direct3D]
"VideoMemorySize"="$size"

_EOF_
    ;;
    esac
    w_try_regedit "$W_TMP_WIN"\\set-video.reg
}

#----------------------------------------------------------------

w_metadata vsm=0 settings \
    title_uk="Встановити MaxShaderModelVS на 0" \
    title="Set MaxShaderModelVS to 0"
w_metadata vsm=1 settings \
    title_uk="Встановити MaxShaderModelVS на 1" \
    title="Set MaxShaderModelVS to 1"
w_metadata vsm=2 settings \
    title_uk="Встановити MaxShaderModelVS на 2" \
    title="Set MaxShaderModelVS to 2"
w_metadata vsm=3 settings \
    title_uk="Встановити MaxShaderModelVS на 3" \
    title="Set MaxShaderModelVS to 3"

load_vsm()
{
    winetricks_set_wined3d_var MaxShaderModelVS "$1"
}

####
# settings->debug

#----------------------------------------------------------------

w_metadata autostart_winedbg=enable settings \
    title="Automatically launch winedbg when an unhandled exception occurs (default)"
w_metadata autostart_winedbg=disable settings \
    title="Prevent winedbg from launching when an unhandled exception occurs"

load_autostart_winedbg()
{
    case "$arg" in
        enable) _W_debugger_value="winedbg --auto %ld %ld";;
        disable) _W_debugger_value="false";;
        *) w_die "Unexpected argument '$arg'. Should be enable/disable";;
    esac

    echo "Setting HKLM\\Software\\Microsoft\\Windows NT\\CurrentVersion\\AeDebug\\Debugger to '$arg'"
    cat > "$W_TMP"/autostart_winedbg.reg <<_EOF_
REGEDIT4

[HKEY_LOCAL_MACHINE\\Software\\Microsoft\\Windows NT\\CurrentVersion\\AeDebug]
"Debugger"="${_W_debugger_value}"
_EOF_

    w_try_regedit "$W_TMP_WIN"\\autostart_winedbg.reg
    w_backup_reg_file "$W_TMP"/autostart_winedbg.reg

    unset _W_debugger_value
}

#----------------------------------------------------------------

w_metadata heapcheck settings \
    title_uk="Увімкнути накопичувальну перевірку GlobalFlag" \
    title="Enable heap checking with GlobalFlag"

load_heapcheck()
{
    cat > "$W_TMP"/heapcheck.reg <<_EOF_
REGEDIT4

[HKEY_LOCAL_MACHINE\\System\\CurrentControlSet\\Control\\Session Manager]
"GlobalFlag"=dword:00200030

_EOF_
    w_try_regedit "$W_TMP_WIN"\\heapcheck.reg
}

#----------------------------------------------------------------

w_metadata nocrashdialog settings \
    title_uk="Вимкнути діалог про помилку" \
    title="Disable crash dialog"

load_nocrashdialog()
{
    echo "Disabling graphical crash dialog"
    cat > "$W_TMP"/crashdialog.reg <<_EOF_
REGEDIT4

[HKEY_CURRENT_USER\\Software\\Wine\\WineDbg]
"ShowCrashDialog"=dword:00000000

_EOF_
    w_try_cd "$W_TMP"
    w_try_regedit crashdialog.reg
}

####
# settings->misc

w_metadata alldlls=default settings \
    title_uk="Видалити всі перевизначення DLL" \
    title="Remove all DLL overrides"
w_metadata alldlls=builtin settings \
    title_uk="Перевизначити найбільш поширені DLL на вбудовані" \
    title="Override most common DLLs to builtin"

load_alldlls()
{
    case "$1" in
        default) w_override_no_dlls ;;
        builtin) w_override_all_dlls ;;
    esac
}

#----------------------------------------------------------------

w_metadata bad settings \
    title="Fake verb that always returns false"

load_bad()
{
    w_die "$W_PACKAGE failed!"
}

#----------------------------------------------------------------

w_metadata forcemono settings \
    title_uk="Примусове використання mono замість .NET (для налагодження)" \
    title="Force using Mono instead of .NET (for debugging)"

load_forcemono()
{
    w_override_dlls native mscoree
    w_override_dlls disabled mscorsvw.exe
}

#----------------------------------------------------------------

w_metadata good settings \
    title="Fake verb that always returns true"

load_good()
{
    w_info "$W_PACKAGE succeeded!"
}

#----------------------------------------------------------------

w_metadata hidewineexports=enable settings \
    title="Enable hiding Wine exports from applications (wine-staging)"
w_metadata hidewineexports=disable settings \
    title="Disable hiding Wine exports from applications (wine-staging)"

load_hidewineexports()
{
    # Wine exports some functions allowing apps to query the Wine version and
    # information about the host environment. Using these functions, some apps
    # will intentionally terminate if they can detect that they are running in
    # a Wine environment.
    #
    # Hiding these Wine exports is only available in wine-staging.
    # See https://bugs.winehq.org/show_bug.cgi?id=38656
    case $arg in
        enable)
            _W_registry_value="\"Y\""
            ;;
        disable)
            _W_registry_value="-"
            ;;
        *) w_die "Unexpected argument, $arg";;
    esac

    cat > "$W_TMP"/set-wineexports.reg <<_EOF_
REGEDIT4

[HKEY_CURRENT_USER\\Software\\Wine]
"HideWineExports"=$_W_registry_value

_EOF_
    w_try_regedit "$W_TMP"/set-wineexports.reg
}

#----------------------------------------------------------------

w_metadata hosts settings \
    title_uk="Додати порожні файли у C:\\windows\\system32\\drivers\\etc\\{hosts,services}" \
    title="Add empty C:\\windows\\system32\\drivers\\etc\\{hosts,services} files"

load_hosts()
{
    # Create fake system32\drivers\etc\hosts and system32\drivers\etc\services files.
    # The hosts file is used to map network names to IP addresses without DNS.
    # The services file is used map service names to network ports.
    # Some apps depend on these files, but they're not implemented in Wine.
    # Fortunately, empty files in the correct location satisfy those apps.
    # See https://bugs.winehq.org/show_bug.cgi?id=12076

    # It's in system32 for both win32/win64
    mkdir -p "$W_WINDIR_UNIX"/system32/drivers/etc
    touch "$W_WINDIR_UNIX"/system32/drivers/etc/hosts
    touch "$W_WINDIR_UNIX"/system32/drivers/etc/services
}

#----------------------------------------------------------------

w_metadata isolate_home settings \
    title_uk="Видалити посилання на вино преміум на \$HOME" \
    title="Remove wineprefix links to \$HOME"

load_isolate_home()
{
    w_skip_windows isolate_home && return

    _olddir="$(pwd)"
    w_try_cd "$WINEPREFIX/drive_c/users/$USER"
    for x in *
    do
        if test -h "$x" && test -d "$x"; then
            rm -f "$x"
            mkdir -p "$x"
        fi
    done
    w_try_cd "$_olddir"
    unset _olddir

    # Workaround for:
    # https://bugs.winehq.org/show_bug.cgi?id=22450 (sandbox verb)
    # https://bugs.winehq.org/show_bug.cgi?id=22974 (isolate_home, sandbox verbs)
    echo disable > "$WINEPREFIX/.update-timestamp"
}

#----------------------------------------------------------------

w_metadata native_mdac settings \
    title_uk="Перевизначити odbc32, odbccp32 та oledb32" \
    title="Override odbc32, odbccp32 and oledb32"

load_native_mdac()
{
    # Set those overrides globally so user programs get MDAC's ODBC
    # instead of Wine's unixodbc
    w_override_dlls native,builtin mtxdm odbc32 odbccp32 oledb32
}

#----------------------------------------------------------------

w_metadata native_oleaut32 settings \
    title_uk="Перевизначити oleaut32" \
    title="Override oleaut32"

load_native_oleaut32()
{
    w_override_dlls native,builtin oleaut32
}

#----------------------------------------------------------------

w_metadata remove_mono settings \
    title_uk="Видалити вбудоване wine-mono" \
    title="Remove builtin wine-mono"

load_remove_mono()
{
    # wine-4.6 comes with two installers, removing "Wine Mono Runtime" will also remove "Wine Mono Windows Support"
    mono_uuid="$("${WINE_ARCH}" uninstaller --list | grep 'Wine Mono' | grep -v 'Wine Mono Windows Support' | cut -f1 -d\|)"
    if test "$mono_uuid"; then
         "${WINE_ARCH}" uninstaller --remove "$mono_uuid"
    else
        # Bail out if mono isn't installed, so we don't break .Net setups
        w_warn "Mono does not appear to be installed."
        return
    fi

    # FIXME: verify on pristine Windows XP:
    if w_workaround_wine_bug 34803; then
        "${WINE_ARCH}" reg delete 'HKLM\\Software\\Microsoft\\.NETFramework\\v2.0.50727\\SBSDisabled' /f
    fi

    "${WINE_ARCH}" reg delete "HKLM\\Software\\Microsoft\\NET Framework Setup\\NDP\\v3.5" /f || true
    "${WINE_ARCH}" reg delete "HKLM\\Software\\Microsoft\\NET Framework Setup\\NDP\\v4" /f || true

    w_try rm -f "$W_WINDIR_UNIX/system32/mscoree.dll"
    if [ "$W_ARCH" = "win64" ]; then
        w_try rm -f "$W_WINDIR_UNIX/syswow64/mscoree.dll"
    fi
}


#----------------------------------------------------------------

w_metadata sandbox settings \
    title_uk="Пісочниця wineprefix - видалити посилання до HOME" \
    title="Sandbox the wineprefix - remove links to \$HOME"

load_sandbox()
{
    w_skip_windows sandbox && return

    # Unmap drive Z
    rm -f "$WINEPREFIX/dosdevices/z:"

    # Disable unixfs
    # Unfortunately, when you run with a different version of Wine, Wine will recreate this key.
    # See https://bugs.winehq.org/show_bug.cgi?id=22450
    "$WINE" regedit /d 'HKEY_LOCAL_MACHINE\\Software\\Microsoft\Windows\CurrentVersion\Explorer\Desktop\Namespace\{9D20AAE8-0625-44B0-9CA7-71889C2254D9}'

    w_call isolate_home
}

####
# settings->sound

#----------------------------------------------------------------

w_metadata sound=alsa settings \
    title_uk="Встановити звуковий драйвер ALSA" \
    title="Set sound driver to ALSA"
w_metadata sound=coreaudio settings \
    title_uk="Встановити звуковий драйвер Mac CoreAudio" \
    title="Set sound driver to Mac CoreAudio"
w_metadata sound=disabled settings \
    title_uk="Вимкнути звуковий драйвер" \
    title="Set sound driver to disabled"
w_metadata sound=oss settings \
    title_uk="Встановити звуковий драйвер OSS" \
    title="Set sound driver to OSS"
w_metadata sound=pulse settings \
    title_uk="Встановити звуковий драйвер PulseAudio" \
    title="Set sound driver to PulseAudio"

load_sound()
{
    echo "Setting sound driver to $1"
    cat > "$W_TMP"/set-sound.reg <<_EOF_
REGEDIT4

[HKEY_CURRENT_USER\\Software\\Wine\\Drivers]
"Audio"="$1"

_EOF_
    w_try_regedit "$W_TMP_WIN"\\set-sound.reg
}

# settings->winversions
#----------------------------------------------------------------

w_metadata nt40 settings \
    title_uk="Встановити версію Windows NT 4.0" \
    title="Set windows version to Windows NT 4.0"

load_nt40()
{
    w_set_winver nt40
}

#----------------------------------------------------------------

w_metadata vista settings \
    title_uk="Встановити версію Windows Vista" \
    title="Set Windows version to Windows Vista"

load_vista()
{
    w_set_winver vista
}

#----------------------------------------------------------------

w_metadata win2k settings \
    title_uk="Встановити версію Windows 2000" \
    title="Set Windows version to Windows 2000"

load_win2k()
{
    w_set_winver win2k
}

#----------------------------------------------------------------

w_metadata win2k3 settings \
    title_uk="Встановити версію Windows 2003" \
    title="Set Windows version to Windows 2003"

load_win2k3()
{
    w_set_winver win2k3
}


#----------------------------------------------------------------

w_metadata win2k8 settings \
    title_uk="Встановити версію Windows 2008 R2" \
    title="Set Windows version to Windows 2008 R2"

load_win2k8()
{
    w_set_winver win2k8
}

#----------------------------------------------------------------

w_metadata win31 settings \
    title_uk="Встановити версію Windows 3.1" \
    title="Set Windows version to Windows 3.1"

load_win31()
{
    w_set_winver win31
}

#----------------------------------------------------------------

w_metadata win7 settings \
    title_uk="Встановити версію Windows 7" \
    title="Set Windows version to Windows 7"

load_win7()
{
    w_set_winver win7
}

#----------------------------------------------------------------

w_metadata win8 settings \
    title_uk="Встановити версію Windows 8" \
    title="Set Windows version to Windows 8"

load_win8()
{
    w_set_winver win8
}

#----------------------------------------------------------------

w_metadata win81 settings \
    title_uk="Встановити версію Windows 8.1" \
    title="Set Windows version to Windows 8.1"

load_win81()
{
    w_set_winver win81
}

#----------------------------------------------------------------

w_metadata win10 settings \
    title_uk="Встановити версію Windows 10" \
    title="Set Windows version to Windows 10"

load_win10()
{
    w_set_winver win10
}

#----------------------------------------------------------------

w_metadata win95 settings \
    title_uk="Встановити версію Windows 95" \
    title="Set Windows version to Windows 95"

load_win95()
{
    w_set_winver win95
}

#----------------------------------------------------------------

w_metadata win98 settings \
    title_uk="Встановити версію Windows 98" \
    title="Set Windows version to Windows 98"

load_win98()
{
    w_set_winver win98
}

#----------------------------------------------------------------

# Really, we should support other values, since winetricks did
w_metadata winver= settings \
    title_uk="Встановити версію Windows за замовчуванням (Windows 7)" \
    title="Set Windows version to default (win7)"

load_winver()
{
    w_set_winver win7
}

#----------------------------------------------------------------

w_metadata winxp settings \
    title_uk="Встановити версію Windows XP" \
    title="Set Windows version to Windows XP"

load_winxp()
{
    w_set_winver winxp
}

#---- Main Program ----

winetricks_stats_save()
{
    # Save opt-in status
    if test "$WINETRICKS_STATS_REPORT"; then
        if test ! -d "$W_CACHE"; then
            mkdir -p "$W_CACHE"
        fi
        echo "$WINETRICKS_STATS_REPORT" > "$W_CACHE"/track_usage
    fi
}

winetricks_stats_init()
{
    # Load opt-in status if not already set by a command-line option
    if test ! "$WINETRICKS_STATS_REPORT" && test -f "$W_CACHE"/track_usage; then
        WINETRICKS_STATS_REPORT=$(cat "$W_CACHE"/track_usage)
    fi

    if test ! "$WINETRICKS_STATS_REPORT"; then
        # No opt-in status found.  If GUI active, ask user whether they would like to opt in.
        case $WINETRICKS_GUI in
            zenity)
                case $LANG in
                de*)
                    title="Einmalige Frage zur Hilfe an der Winetricks Entwicklung"
                    question="Möchten Sie die Winetricks Entwicklung unterstützen indem Sie Winetricks Statistiken übermitteln lassen? Sie können die Übermittlung jederzeit mit 'winetricks --optout' ausschalten"
                    thanks="Danke! Sie bekommen diese Frage nicht mehr gestellt. Sie können die Übermittlung jederzeit mit 'winetricks --optout' wieder ausschalten"
                    declined="OK, Winetricks wird *keine* Statistiken übermitteln. Sie bekommen diese Frage nicht mehr gestellt."
                    ;;
                pl*)
                    title="Jednorazowe pytanie dotyczące pomocy w rozwoju Winetricks"
                    question="Czy chcesz pomóc w rozwoju Winetricks pozwalając na wysyłanie statystyk przez program? Możesz wyłączyć tą opcję w każdej chwili z użyciem komendy 'winetricks --optout'."
                    thanks="Dziękujemy! Nie otrzymasz już tego pytania. Pamiętaj, ze możesz wyłączyć tą opcję komendą 'winetricks --optout'"
                    declined="OK, Winetricks *nie* będzie wysyłać statystyk. Nie otrzymasz już tego pytania."
                    ;;
                ru*)
                    title="Помощь в разработке Winetricks"
                    question="Вы хотите помочь разработке winetricks, отправляя статистику? Вы можете отключить отправку статистики в любое время с помощью команды 'winetricks --optout'"
                    thanks="Спасибо! Этот вопрос больше не появится. Помните: вы можете отключить отправку статистики в любое время с помощью команды 'winetricks --optout'"
                    declined="OK, winetricks НЕ будет отправлять статистику. Этот вопрос больше не появится."
                    ;;
                uk*)
                    title="Допомога в розробці Winetricks"
                    question="Ви хочете допомогти в розробці Winetricks дозволивши звітувати статистику?\\nВи можете в будь-який час вимкнути цю опцію за допомогою команди 'winetricks --optout'"
                    thanks="Дякуємо! Ви більше не отримуватиме це питання знову. Пам'ятайте, що ви можете будь-коли вимкнути звітність за допомогою команди 'winetricks --optout'"
                    declined="Надсилання звітності Winetricks вимкнено. Ви більше не отримуватиме це питання знову."
                    ;;
                *)
                    title="One-time question about helping Winetricks development"
                    question="Would you like to help winetricks development by letting winetricks report statistics? You can turn reporting off at any time with the command 'winetricks --optout'"
                    thanks="Thanks! You won't be asked this question again. Remember, you can turn reporting off at any time with the command 'winetricks --optout'"
                    declined="OK, winetricks will *not* report statistics. You won't be asked this question again."
                    ;;
                esac
                if $WINETRICKS_GUI --question --text "$question" --title "$title"; then
                    $WINETRICKS_GUI --info --text "$thanks"
                    WINETRICKS_STATS_REPORT=1
                else
                    $WINETRICKS_GUI --info --text "$declined"
                    WINETRICKS_STATS_REPORT=0
                fi
                winetricks_stats_save
                ;;
        esac
    fi
}

# Retrieve a short string with the operating system name and version
winetricks_os_description()
{
    (
        case "$W_PLATFORM" in
            windows_cmd) echo "windows" ;;
            *)  echo "$WINETRICKS_WINE_VERSION" ;;
        esac
    ) | tr '\012' ' '
}

winetricks_stats_report()
{
    winetricks_download_setup

    # If user has opted in to usage tracking, report what he used (if anything)
    case "$WINETRICKS_STATS_REPORT" in
        1) ;;
        *) return;;
    esac

    test -f "$WINETRICKS_WORKDIR"/breadcrumbs || return

    WINETRICKS_STATS_BREADCRUMBS=$(tr '\012' ' ' < "$WINETRICKS_WORKDIR"/breadcrumbs)
    echo "You opted in, so reporting '$WINETRICKS_STATS_BREADCRUMBS' to the winetricks maintainer so he knows which winetricks verbs get used and which don't.  Use --optout to disable future reports."

    report="os=$(winetricks_os_description)&winetricks=$WINETRICKS_VERSION&breadcrumbs=$WINETRICKS_STATS_BREADCRUMBS"
    report="$(echo "$report" | sed 's/ /%20/g')"

    # Just do a HEAD request with the raw command line.
    # Yes, this can be fooled by caches.  That's ok.

    # Note: these downloads are expected to fail (the resource won't exist), so don't use w_try and use '|| true' to ignore the expected errors
    if [ "${WINETRICKS_DOWNLOADER}" = "wget" ] ; then
        $torify wget --timeout "${WINETRICKS_DOWNLOADER_TIMEOUT}" \
            --tries "$WINETRICKS_DOWNLOADER_RETRIES" \
            --spider "http://kegel.com/data/winetricks-usage?$report" > /dev/null 2>&1 || true
    elif [ "${WINETRICKS_DOWNLOADER}" = "curl" ] ; then
        $torify curl --connect-timeout "${WINETRICKS_DOWNLOADER_TIMEOUT}" \
           --retry "$WINETRICKS_DOWNLOADER_RETRIES" \
           -I "http://kegel.com/data/winetricks-usage?$report" > /dev/null 2>&1 || true
    elif [ "${WINETRICKS_DOWNLOADER}" = "aria2c" ] ; then
        $torify aria2c $aria2c_torify_opts \
                $aria2c_torify_opts \
                --connect-timeout="${WINETRICKS_DOWNLOADER_TIMEOUT}" \
                --daemon=false \
                --enable-rpc=false \
                --input-file='' \
                --max-tries="$WINETRICKS_DOWNLOADER_RETRIES" \
                --save-session='' \
                "http://kegel.com/data/winetricks-usage?$report" > /dev/null 2>&1 || true
    else
        w_die "Here be dragons"
    fi
}

winetricks_stats_log_command()
{
    # log what we execute for possible later statistics reporting
    echo "$*" >> "$WINETRICKS_WORKDIR"/breadcrumbs

    # and for the user's own reference later, when figuring out what he did
    case "$W_PLATFORM" in
        windows_cmd) _W_LOGDIR="$W_WINDIR_UNIX"/Temp ;;
        *) _W_LOGDIR="$WINEPREFIX" ;;
    esac

    mkdir -p "$_W_LOGDIR"
    echo "$*" >> "$_W_LOGDIR"/winetricks.log
    unset _W_LOGDIR
}

# Launch a new terminal window if in GUI, or
# spawn a shell in the current window if command line.
# New shell contains proper WINEPREFIX and WINE environment variables.
# May be useful when debugging verbs.
winetricks_shell()
{
    (
        w_try_cd "$W_DRIVE_C"
        export WINE

        case $WINETRICKS_GUI in
            none)
                $SHELL
                ;;
            *)
                for term in gnome-terminal konsole Terminal xterm
                do
                    if test "$(command -v $term 2>/dev/null)"; then
                        $term
                        break
                    fi
                done
                ;;
            esac
    )
}

# Usage: execute_command verb[=argument]
execute_command()
{
    case "$1" in
        *=*) arg=$(echo "$1" | sed 's/.*=//'); cmd=$(echo "$1" | sed 's/=.*//');;
        *) cmd="$1"; arg="" ;;
    esac

    case "$1" in
        # FIXME: avoid duplicated code
        apps|benchmarks|dlls|fonts|games|prefix|settings)
            WINETRICKS_CURMENU="$1"
            ;;

        # Late options
        -*)
            if ! winetricks_handle_option "$1"; then
                winetricks_usage
                exit 1
            fi
            ;;

        # Hard-coded verbs
        main) WINETRICKS_CURMENU=main ;;
        help) w_open_webpage https://github.com/Winetricks/winetricks/wiki ;;
        list) winetricks_list_all ;;
        list-cached) winetricks_list_cached ;;
        list-download) winetricks_list_download ;;
        list-manual-download) winetricks_list_manual_download ;;
        list-installed) winetricks_list_installed ;;
        list-all)
            old_menu="$WINETRICKS_CURMENU"
            for WINETRICKS_CURMENU in apps benchmarks dlls fonts games prefix settings
            do
                echo "===== $WINETRICKS_CURMENU ====="
                winetricks_list_all
            done
            WINETRICKS_CURMENU="$old_menu"
            ;;
        unattended) winetricks_set_unattended 1 ;;
        attended) winetricks_set_unattended 0 ;;
        arch=*) winetricks_set_winearch "$arg" ;;
        prefix=*) winetricks_set_wineprefix "$arg" ;;
        annihilate) winetricks_annihilate_wineprefix ;;
        folder) w_open_folder "$WINEPREFIX" ;;
        winecfg) "$WINE" winecfg ;;
        regedit) "$WINE" regedit ;;
        taskmgr) "$WINE" taskmgr & ;;
        explorer) "$WINE" explorer & ;;
        uninstaller) "$WINE" uninstaller ;;
        shell) winetricks_shell ;;

        # These have to come before *=disabled to avoid looking like DLLs
        fontsmooth=disable*) w_call fontsmooth=disable ;;
        glsl=disable*) w_call glsl=disabled ;;
        multisampling=disable*) w_call multisampling=disabled ;;
        mwo=disable*) w_call mwo=disable ;;   # FIXME: relax matching so we can handle these spelling differences in verb instead of here
        rtlm=disable*) w_call rtlm=disabled ;;
        sound=disable*) w_call sound=disabled ;;
        ao=disable*) w_call ao=disabled ;;
        strictdrawordering=disable*) w_call strictdrawordering=disabled ;;

        # Use winecfg if you want a GUI for plain old DLL overrides
        alldlls=*) w_call "$1" ;;
        *=native) w_do_call native "$cmd";;
        *=builtin) w_do_call builtin "$cmd";;
        *=default) w_do_call default "$cmd";;
        *=disabled) w_do_call disabled "$cmd";;
        vd=*) w_do_call "$cmd";;

        # Hacks for backwards compatibility
        # 2017/03/22: add deprecation notices
        cc580) w_warn "Calling cc580 is deprecated, please use comctl32 instead" ; w_call comctl32 ;;
        comdlg32.ocx) w_warn "Calling comdlg32.ocx is deprecated, please use comdlg32ocx instead" ; w_call comdlg32ocx ;;
        dotnet1) w_warn "Calling dotnet1 is deprecated, please use dotnet11 instead" ; w_call dotnet11 ;;
        dotnet2) w_warn "Calling dotnet2 is deprecated, please use dotnet20 instead" ; w_call dotnet20 ;;
        flash11) w_warn "Calling flash11 is deprecated, please use flash instead" ; w_call flash ;;
        # art2kmin also comes with fm20.dll
        fm20) w_warn "Calling fm20 is deprecated, please use controlpad instead" ; w_call controlpad ;;
        fontsmooth-bgr) w_warn "Calling fontsmooth-bgr is deprecated, please use fontsmooth=bgr instead" ; w_call fontsmooth=bgr ;;
        fontsmooth-disable) w_warn "Calling fontsmooth-disable is deprecated, please use fontsmooth=disable instead" ; w_call fontsmooth=disable ;;
        fontsmooth-gray) w_warn "Calling fontsmooth-gray is deprecated, please use fontsmooth=gray instead" ; w_call fontsmooth=gray ;;
        fontsmooth-rgb) w_warn "Calling fontsmooth-rgb is deprecated, please use fontsmooth=rgb instead" ; w_call fontsmooth=rgb ;;
        glsl-disable) w_warn "Calling glsl-disable is deprecated, please use glsl=disabled instead" ; w_call glsl=disabled ;;
        glsl-enable) w_warn "Calling glsl-enable is deprecated, please use glsl=enabled instead" ; w_call glsl=enabled ;;
        ie6_full) w_warn "Calling ie6_full is deprecated, please use ie6 instead" ; w_call ie6 ;;
        # FIXME: use wsh57 instead?
        jscript) w_warn "Calling jscript is deprecated, please use wsh56js instead" ; w_call wsh56js ;;
        npm-repack) w_warn "Calling npm-repack is deprecated, please use npm=repack instead" ; w_call npm=repack ;;
        oss) w_warn "Calling oss is deprecated, please use sound=oss instead" ; w_call sound=oss ;;
        python) w_warn "Calling python is deprecated, please use python26 instead" ; w_call python26 ;;
        vbrun60) w_warn "Calling vbrun60 is deprecated, please use vb6run instead" ; w_call vb6run ;;
        vcrun2005sp1) w_warn "Calling vcrun2005sp1 is deprecated, please use vcrun2005 instead" ; w_call vcrun2005 ;;
        vcrun2008sp1) w_warn "Calling vcrun2008sp1 is deprecated, please use vcrun2008 instead" ; w_call vcrun2008 ;;
        wsh56|wsh56jb|wsh56vb) w_warn "Calling wsh56 is deprecated, please use wsh57 instead" ; w_call wsh57 ;;
        # See https://github.com/Winetricks/winetricks/issues/747
        xact_jun2010) w_warn "Calling xact_jun2010 is deprecated, please use xact instead" ; w_call xact ;;
        xlive) w_warn "Calling xlive is deprecated, please use gfw instead" ; w_call gfw ;;

        # Normal verbs, with metadata and load_ functions
        *)
            if winetricks_metadata_exists "$1"; then
                w_call "$1"
            else
                echo "Unknown arg $1"
                winetricks_usage
                exit 1
            fi
            ;;
    esac
}

if ! test "$WINETRICKS_LIB"
then
    # If user opted out, save that preference now.
    winetricks_stats_save

    # If user specifies menu on command line, execute that command, but don't commit to command-line mode
    # FIXME: this code is duplicated several times; unify it
    if echo "$WINETRICKS_CATEGORIES" | grep -w "$1" > /dev/null; then
        WINETRICKS_CURMENU=$1
        shift
    fi

    case "$1" in
        die) w_die "we who are about to die salute you." ;;
        volnameof=*)
            # Debug code.  Remove later?
            # Since Linux's volname command can't handle DVDs, winetricks has its own,
            # implemented using dd, old gum, and some string I had laying around.
            # You can try it like this:
            #  winetricks volnameof=/dev/sr0
            # or
            #  winetricks volnameof=foo.iso
            # This will read the volname from the given image and put it to stdout.
            winetricks_volname "${1#volnameof=}"
            ;;
        "")
            if [ -z "$DISPLAY" ]; then
                if [ "$(uname -s)" = "Darwin" ]; then
                    echo "Running on OSX, but DISPLAY is not set...probably using Mac Driver."
                else
                    echo "DISPLAY not set, not defaulting to gui"
                    winetricks_usage
                    exit 0
                fi
            fi

            # GUI case
            # No non-option arguments given, so read them from GUI, and loop until user quits
            winetricks_detect_gui
            winetricks_detect_sudo
            test -z "$WINETRICKS_ISO_MOUNT" && winetricks_detect_iso_mount
            while true
            do
                case $WINETRICKS_CURMENU in
                    main) verbs=$(winetricks_mainmenu) ;;
                    prefix)
                        verbs=$(winetricks_prefixmenu);
                        # Cheezy hack: choosing 'attended' or 'unattended' leaves you in same menu
                        case "$verbs" in
                            attended) winetricks_set_unattended 0 ; continue;;
                            unattended) winetricks_set_unattended 1 ; continue;;
                        esac
                        ;;
                    mkprefix) verbs=$(winetricks_mkprefixmenu) ;;
                    settings) verbs=$(winetricks_settings_menu) ;;
                    *) verbs="$(winetricks_showmenu)" ;;
                esac

                if test "$verbs" = ""; then
                    # "user didn't pick anything, back up a level in the menu"
                    case "${WINETRICKS_CURMENU}-${WINETRICKS_OPT_SHAREDPREFIX}" in
                        apps-0|benchmarks-0|games-0|main-*) WINETRICKS_CURMENU=prefix ;;
                        prefix-*) break ;;
                        *) WINETRICKS_CURMENU=main ;;
                    esac
                elif echo "$WINETRICKS_CATEGORIES" | grep -w "$verbs" > /dev/null; then
                    WINETRICKS_CURMENU=$verbs
                else
                    winetricks_stats_init
                    # Otherwise user picked one or more real verbs.
                    case "$verbs" in
                        prefix=*|arch=*)
                            # prefix menu is special, it only returns one verb, and the
                            # verb can contain spaces. If a 32bit wineprefix is created via
                            # the GUI, this may have an "arch=* " prefix
                            _W_arch=$(echo "$verbs" | grep -o 'arch=.*' | cut -d' ' -f1)
                            _W_prefix=$(echo "$verbs" | grep -o 'prefix=.*')
                            if [ -n "$_W_arch" ]; then
                                execute_command "$_W_arch"
                            fi
                            execute_command "$_W_prefix"
                            # after picking a prefix, want to land in main.
                            WINETRICKS_CURMENU=main ;;
                        *)
                            for verb in $verbs
                            do
                                execute_command "$verb"
                            done

                            case "${WINETRICKS_CURMENU}-${WINETRICKS_OPT_SHAREDPREFIX}" in
                                prefix-*|apps-0|benchmarks-0|games-0)
                                    # After installing isolated app, return to prefix picker
                                    WINETRICKS_CURMENU=prefix
                                    ;;
                                *)
                                    # Otherwise go to main menu.
                                    WINETRICKS_CURMENU=main
                                    ;;
                            esac
                            ;;
                    esac
                fi
            done
            ;;
        *)
            winetricks_stats_init
            # Command-line case
            winetricks_detect_sudo
            test -z "$WINETRICKS_ISO_MOUNT" && winetricks_detect_iso_mount
            # User gave command-line arguments, so just run those verbs and exit
            for verb; do
                case $verb in
                    *.verb)
                        # Load the verb file
                        # shellcheck disable=SC1090
                        case $verb in
                            */*) . "$verb" ;;
                            *) . ./"$verb" ;;
                        esac

                        # And forget that the verb comes from a file
                        verb="$(echo "$verb" | sed 's,.*/,,;s,.verb,,')"
                        ;;
                esac
                execute_command "$verb"
            done
            ;;
    esac

    winetricks_stats_report
fi

# vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4
