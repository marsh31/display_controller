#!/usr/bin/bash

Config_file="$HOME/.config/display.config"
Filter=(fzf +m --ansi)


set_filter() {
  local prompt="$1"
  Filter=(fzf --ansi --prompt="$prompt > ")
}

main_menu() {
  echo "Set a display"
  echo "Use config"
  echo "Remove a display"
  echo "Remove all display"
}

vec_list() {
  echo "left"
  echo "right"
  echo "above"
  echo "below"
}

connected_display_list() {
  for display in $(xrandr | grep " connected " | cut -d" " -f 1); do
    for except in "$@"; do
      [[ $display =~ $except ]] && continue || echo $display
    done
  done
}

set_display() {
  set_filter "Dest"
  dest=$(connected_display_list "LVDS" | "${Filter[@]}")
  if [[ "$target" = "" ]]; then
    echo "Other display was not connected."
    exit 0
  fi

  set_filter "Direction"
  vector=$(vec_list | "${Filter[@]}")

  set_filter "Src "
  src=$(connected_display_list "$dest" | "${Filter[@]}")
  set_display $dest $vector $src
}


config_menu() {
  text="${1}"
  for key in $(echo $text | jq -r ". | keys | @tsv"); do
    echo "$key"
  done
}


set_display() {
  dest="$1"
  direction="$2"
  src="$3"

  case $direction in
    "left")
      xrandr --output $dest --auto --left-of $src
      ;;

    "right")
      xrandr --output $dest --auto --right-of $src
      ;;

    "above")
      xrandr --output $dest --auto --above $src
      ;;

    "below")
      xrandr --output $dest --auto --below $src
      ;;
  esac
}


use_config() {
  text="$(toml2json ${Config_file})"
  selected_config=$(config_menu "$text" | "${Filter[@]}")
  setting_text=$(echo $text | jq ".$selected_config.settings")

  num_device=$(echo $setting_text | jq ". | length")
  for (( i = 0; i < $num_device; i++ )); do
    set_display $(echo $setting_text | jq -r ".[$i] | [.dest, .direction, .src] | @tsv")
  done
}


remove() {
  set_filter "Target"
  target=$(connected_display_list "LVDS" | "${Filter[@]}")

  if [[ "$target" = "" ]]; then
    echo "Other display was not connected."
    exit 0
  fi
  xrandr --output "$target" --auto --off
}


remove_all() {
  for display in $(connected_display_list); do
    xrandr --output "$display" --auto --off
  done
}


main() {
  res=$(main_menu | sort | "${Filter[@]}")

  case $res in
    Set*)
      set_display
      ;;

    Use*)
      use_config
      ;;

    Remove\ all*)
      remove_all
      ;;

    Remove\ a*)
      remove
      ;;
  esac
}

main $@
