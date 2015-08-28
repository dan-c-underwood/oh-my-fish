# SYNOPSIS
#   Oh My Fish CLI
#
# ENV
#   OMF_VERSION   Version
#   OMF_CONFIG    Oh My Fish configuration
#
# OVERVIEW
#   Provides options to list, download and remove packages, update
#   the framework, create / submit a new package, etc.

set -g OMF_MISSING_ARG   1
set -g OMF_UNKNOWN_OPT   2
set -g OMF_INVALID_ARG   3
set -g OMF_UNKNOWN_ERR   4

set -g OMF_VERSION "1.0.0"

function omf::em
  if set -q fish_color_match
    set_color $fish_color_match
  else
    set_color cyan
  end
end
function omf::dim
  if set -q fish_color_autosuggestion
    set_color $fish_color_autosuggestion
  else
    set_color 555
  end
end
function omf::err
  if set -q fish_color_error
    set_color $fish_color_error
  else
    set_color red --bold
  end
end
function omf::off
  set_color normal
end

function init -a path --on-event init_omf
  autoload $path/cli $path/util
end

function omf -d "Oh My Fish"
  if test (count $argv) -eq 0
    omf.help; and return 0
  end

  switch $argv[1]
    case "v" "ver" "version"
      omf.version

    case "q" "query"
      switch (count $argv)
        case 1
          omf.query_env
        case 2
          omf.query_env "$argv[2]"
        case "*"
          echo (omf::err)"Invalid number of arguments"(omf::off) 1^&2
          echo "Usage: $_ "(omf::em)"$argv[1]"(omf::off)" [<variable name>]" 1^&2
          return $OMF_INVALID_ARG
      end

    case "h" "help"
      omf.help

    case "l" "li" "lis" "lst" "list"
      omf.list_local_packages | column

    case "i" "install" "get"
      if test (count $argv) -eq 1
        omf.list_db_packages | column
      else
        omf.install_package $argv[2..-1]
        refresh
      end

    case "t" "theme"
      if test (count $argv) -eq 1
        set -l theme (cat $OMF_CONFIG/theme)
        set -l regex "[[:<:]]($theme)[[:>:]]"
        test "$OSTYPE" != "Darwin"; and set regex "\b($theme)\b"

        omf.list_themes | column | sed -E "s/$regex/"(omf::em)"\1"(omf::off)"/"
        omf::off

      else if test (count $argv) -eq 2
        omf.theme $argv[2]
        refresh
      else
        echo (omf::err)"Invalid number of arguments"(omf::off) 1^&2
        echo "Usage: $_ "(omf::em)"$argv[1]"(omf::off)" [<theme name>]" 1^&2
        return $OMF_INVALID_ARG
      end

    case "r" "rem" "rm" "remove" "uninstall"
      if test (count $argv) -ne 2
        echo (omf::err)"Invalid number of arguments"(omf::off) 1^&2
        echo "Usage: $_ "(omf::em)"$argv[1]"(omf::off)" <[package|theme] name>" 1^&2
        return $OMF_INVALID_ARG
      end
      omf.remove_package $argv[2..-1]

    case "u" "up" "upd" "update"
      pushd $OMF_PATH
      echo (omf::em)"Updating Oh My Fish..."(omf::off)
      if omf.update
        echo (omf::em)"Oh My Fish is up to date."(omf::off)
      else
        echo (omf::err)"Oh My Fish failed to update."(omf::off)
        echo "Please open a new issue here → "(omf::em)"git.io/omf-issues"(omf::off)
      end
      omf.theme (cat $OMF_CONFIG/theme)
      omf.install_package (omf.list_installed_packages)
      popd
      refresh

    case "s" "su" "sub" "submit"
      switch (count $argv)
        case 3
          omf.submit $argv[2] $argv[3]
        case "*"
          echo (omf::err)"Argument missing"(omf::off) 1^&2
          echo "Usage: $_ "(omf::em)"$argv[1]"(omf::off)" "(omf::em)"pkg|themes"(omf::off)"/<name> <url>" 1^&2
          return $OMF_MISSING_ARG
      end

    case "n" "nw" "new"
      if test (count $argv) -ne 3
        echo (omf::err)"Package type or name missing"(omf::off) 1^&2
        echo "Usage: $_ "(omf::em)"$argv[1]"(omf::off)" "(omf::em)"pkg|theme"(omf::off)" <name>" 1^&2
        return $OMF_MISSING_ARG
      end
      omf.new $argv[2..-1]

    case "destroy"
      omf.destroy

    case "*"
      echo (omf::err)"$argv[1] option not recognized"(omf::off) 1^&2
      return $OMF_UNKNOWN_OPT
  end
end
