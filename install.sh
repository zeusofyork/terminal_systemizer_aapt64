##########################################################################################
#
# Magisk Module Installer Script
#
##########################################################################################
##########################################################################################
#
# Instructions:
#
# 1. Place your files into system folder (delete the placeholder file)
# 2. Fill in your module's info into module.prop
# 3. Configure and implement callbacks in this file
# 4. If you need boot scripts, add them into common/post-fs-data.sh or common/service.sh
# 5. Add your additional or modified system properties into common/system.prop
#
##########################################################################################

##########################################################################################
# Config Flags
##########################################################################################

# Set to true if you do *NOT* want Magisk to mount
# any files for you. Most modules would NOT want
# to set this flag to true
SKIPMOUNT=false

# Set to true if you need to load system.prop
PROPFILE=false

# Set to true if you need post-fs-data script
POSTFSDATA=false

# Set to true if you need late_start service script
LATESTARTSERVICE=false

##########################################################################################
# Replace list
##########################################################################################

# List all directories you want to directly replace in the system
# Check the documentations for more info why you would need this

# Construct your list in the following format
# This is an example
REPLACE_EXAMPLE="
/system/app/Youtube
/system/priv-app/SystemUI
/system/priv-app/Settings
/system/framework
"

# Construct your own list here
REPLACE="
"

##########################################################################################
#
# Function Callbacks
#
# The following functions will be called by the installation framework.
# You do not have the ability to modify update-binary, the only way you can customize
# installation is through implementing these functions.
#
# When running your callbacks, the installation framework will make sure the Magisk
# internal busybox path is *PREPENDED* to PATH, so all common commands shall exist.
# Also, it will make sure /data, /system, and /vendor is properly mounted.
#
##########################################################################################
##########################################################################################
#
# The installation framework will export some variables and functions.
# You should use these variables and functions for installation.
#
# ! DO NOT use any Magisk internal paths as those are NOT public API.
# ! DO NOT use other functions in util_functions.sh as they are NOT public API.
# ! Non public APIs are not guranteed to maintain compatibility between releases.
#
# Available variables:
#
# MAGISK_VER (string): the version string of current installed Magisk
# MAGISK_VER_CODE (int): the version code of current installed Magisk
# BOOTMODE (bool): true if the module is currently installing in Magisk Manager
# MODPATH (path): the path where your module files should be installed
# TMPDIR (path): a place where you can temporarily store files
# ZIPFILE (path): your module's installation zip
# ARCH (string): the architecture of the device. Value is either arm, arm64, x86, or x64
# IS64BIT (bool): true if $ARCH is either arm64 or x64
# API (int): the API level (Android version) of the device
#
# Availible functions:
#
# ui_print <msg>
#     print <msg> to console
#     Avoid using 'echo' as it will not display in custom recovery's console
#
# abort <msg>
#     print error message <msg> to console and terminate installation
#     Avoid using 'exit' as it will skip the termination cleanup steps
#
# set_perm <target> <owner> <group> <permission> [context]
#     if [context] is empty, it will default to "u:object_r:system_file:s0"
#     this function is a shorthand for the following commands
#       chown owner.group target
#       chmod permission target
#       chcon context target
#
# set_perm_recursive <directory> <owner> <group> <dirpermission> <filepermission> [context]
#     if [context] is empty, it will default to "u:object_r:system_file:s0"
#     for all files in <directory>, it will call:
#       set_perm file owner group filepermission context
#     for all directories in <directory> (including itself), it will call:
#       set_perm dir owner group dirpermission context
#
##########################################################################################
##########################################################################################
# If you need boot scripts, DO NOT use general boot scripts (post-fs-data.d/service.d)
# ONLY use module scripts as it respects the module status (remove/disable) and is
# guaranteed to maintain the same behavior in future Magisk releases.
# Enable boot scripts by setting the flags in the config section above.
##########################################################################################

# Set what you want to display when installing your module

print_modname() {
  ui_print "*******************************"
  ui_print "   Terminal App Systemizer     "
  ui_print "  by zeus0fyork @ xda-developers   "
  ui_print "*******************************"
}

# Copy the module files into $MODPATH during installation

on_install() {
  # By default, extract the system directory from the ZIP into $MODPATH
  # You can modify this section to handle more complex install logic

  no_app=0
  no_privapp=0
  no_xml=0
  additional_size=0

  mkdir -p $TMPDIR/$MODID
  COPYPATH=$NVBASE/modules/$MODID

  if [ -d $COPYPATH/system/app ]; then
    cp -af $COPYPATH/system/app $TMPDIR/$MODID
    # Uncomment to add size to calculation
    additional_size=$((additional_size+$(du -ks $COPYPATH/system/app | awk '{print $1}')))
  else
    no_app=1
  fi

  if [ -d $COPYPATH/system/priv-app ]; then
    cp -af $COPYPATH/system/priv-app $TMPDIR/$MODID
    # Uncomment to add size to calculation
    additional_size=$((additional_size+$(du -ks $COPYPATH/system/priv-app | awk '{print $1}')))
  else
    no_privapp=1
  fi

  if [ -d $COPYPATH/system/etc/permissions ]; then
    cp -af $COPYPATH/system/etc/permissions $TMPDIR/$MODID
    # Uncomment to add size to calculation
    additional_size=$((additional_size+$(du -ks $COPYPATH/system/etc/permissions | awk '{print $1}')))
  else
    no_xml=1
  fi

  # Optionally include extra size in required module space
  #additional_size=$((additional_size / 1024 + 1))
  #reqSizeM=$((reqSizeM+additional_size))

  # Check if SELinux flag is present in module.prop
  se_value=$(grep_prop selinux $COPYPATH/module.prop)
  if [ "$se_value" != "true" ]; then
    se_value=false
  fi

  ui_print "- Extracting module files"
  unzip -o "$ZIPFILE" 'system/*' -d $MODPATH >&2

  if [ $no_app == 0 ]; then
    cp -af $TMPDIR/$MODID/app $MODPATH/system
  fi
  if [ $no_privapp == 0 ]; then
    cp -af $TMPDIR/$MODID/priv-app $MODPATH/system
  fi
  if [ $no_xml == 0 ]; then
    mkdir -p $MODPATH/system/etc
    cp -af $TMPDIR/$MODID/permissions $MODPATH/system/etc
  fi
}

# Set file and directory permissions as needed after install
# Default permissions will be used unless overridden here

set_permissions() {
  # Apply default recursive permissions
  set_perm_recursive $MODPATH 0 0 0755 0644

  # Example permission settings if needed:
  # set_perm_recursive  $MODPATH/system/lib       0     0       0755      0644
  # set_perm  $MODPATH/system/bin/app_process32   0     2000    0755      u:object_r:zygote_exec:s0
  # set_perm  $MODPATH/system/bin/dex2oat         0     2000    0755      u:object_r:dex2oat_exec:s0
  # set_perm  $MODPATH/system/lib/libart.so       0     0       0644

  cp -af $TMPDIR/aapt $MODPATH/aapt
  cp -af $TMPDIR/mod-util.sh $MODPATH/mod-util.sh

  bin=xbin
  if [ ! -d /system/xbin ]; then
    bin=bin
    mkdir $MODPATH/system/$bin
    mv $MODPATH/system/xbin/systemize $MODPATH/system/$bin
    rm -rf $MODPATH/system/xbin/*
    rmdir $MODPATH/system/xbin
  fi

  set_perm $MODPATH/system/$bin/systemize 0 0 0777
  set_perm $MODPATH/aapt 0 0 0777
  set_perm $MODPATH/mod-util.sh 0 0 0777

  echo "selinux=${se_value}" >> $MODPATH/module.prop
}     

# Add any additional helper functions below as needed
