#!/bin/sh

# activity_null_check is for Freeciv bug #22700.
# freeciv_segfauls_fix is a workaround some segfaults in the Freeciv server. Freeciv bug #23884.
# message_escape is a patch for protecting against script injection in the message texts.
# json_memory is Freeciv patch #6634 (SVN r30802)
# missing_trade_partner is Freeciv patch #6814 (SVN r31453)
# spaceship_post_launch is Freeciv bug #24309 (SVN r31476)
# metamessage is Freeciv patch #6876 (SVN r31682)
# settings_access_level_metamessage is replaced by Freeciv patch #6967
# metamessage_setting is Freeciv bug #24415

PATCHLIST="freeciv_web_all_packets_def_changes caravan_fixes1 city_fixes city_impr_fix2 city-naming-change city_fixes2 citytools_changes metachange text_fixes unithand-change2 current_research_cost freeciv-svn-webclient-changes network-rewrite-1 fcnet_packets misc_devversion_sync scenario_ruleset savegame maphand_ch serverside_extra_assign libtoolize_no_symlinks ai_traits_crash ruleset-capability worklists server_password aifill barbarian-names activity_null_check add_rulesets message_escape freeciv_segfauls_fix scorelog_filenames scorelog_set_to_client json_memory missing_trade_partner spaceship_post_launch metamessage settings_access_level_metamessage metamessage_setting disable_global_warming"

apply_patch() {
  echo "*** Applying $1.patch ***"
  if ! patch -u -p1 -d freeciv < patches/$1.patch ; then
    echo "APPLYING PATCH $1.patch FAILED!"
    return 1
  fi
  echo "=== $1.patch applied ==="
}

# APPLY_UNTIL feature is used when rebasing the patches, and the working directory
# is needed to get to correct patch level easily.
if test "x$1" != "x" ; then
  APPLY_UNTIL="$1"
  au_found=false

  for patch in $PATCHLIST
  do
    if test "x$patch" = "x$APPLY_UNTIL" ; then
      au_found=true
    fi
  done
  if test "x$au_found" != "xtrue" ; then
    echo "There's no such patch as \"$APPLY_UNTIL\"" >&2
    exit 1
  fi
else
  APPLY_UNTIL=""
fi

. ./version.txt

if ! grep "NETWORK_CAPSTRING_MANDATORY=\"$ORIGCAPSTR\"" freeciv/fc_version 2>/dev/null >/dev/null ; then
  echo "Capstring to be replaced does not match one given in version.txt" >&2
  exit 1
fi

sed "s/$ORIGCAPSTR/$WEBCAPSTR/" freeciv/fc_version > freeciv/fc_version.tmp
mv freeciv/fc_version.tmp freeciv/fc_version
chmod a+x freeciv/fc_version

for patch in $PATCHLIST
do
  if test "x$patch" = "x$APPLY_UNTIL" ; then
    echo "$patch not applied as requested to stop"
    break
  fi
  if ! apply_patch $patch ; then
    echo "Patching failed ($patch.patch)" >&2
    exit 1
  fi
done

# have Freeciv's "make install" add the Freeciv-web rulesets
cp -Rf data/fcweb data/webperimental freeciv/data/
