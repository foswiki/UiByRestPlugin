# This script Copyright (c) 2009 Collaborganize  ( www.collaborganize.com )
# and distributed under the GPL (see below)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details, published at
# http://www.gnu.org/copyleft/gpl.html
#
# Author: Eugen Mayer

# =========================
package Foswiki::Plugins::UiByRestPlugin;

# =========================
use strict;
use warnings;
use Error qw(:try);


# $VERSION is referred to by Foswiki, and is the only global variable that
# *must* exist in this package.
use vars
  qw( $VERSION $RELEASE $SHORTDESCRIPTION $debug $pluginName $NO_PREFS_IN_TOPIC );

# This should always be $Rev: 12445$ so that Foswiki can determine the checked-in
# status of the plugin. It is used by the build automation tools, so
# you should leave it alone.
$VERSION = '$Rev: 12445$';

# This is a free-form string you can use to "name" your own plugin version.
# It is *not* used by the build automation tools, but is reported as part
# of the version number in PLUGINDESCRIPTIONS.
$RELEASE = '0.1';

# Short description of this plugin
# One line description, is shown in the %FoswikiWEB%.TextFormattingRules topic:
$SHORTDESCRIPTION = 'Provides rest handler for the common UI actions like rename/login/attach etc.';

# Name of this Plugin, only used in this module
$pluginName = 'UiByRestPlugin';

# =========================
my $jqPluginName = "JQueryCompatibilityModePlugin";
sub initPlugin {
    my ( $topic, $web, $user, $installWeb ) = @_;
    Foswiki::Func::registerRESTHandler('renametopic', \&_renameTopic);
}

sub _renameTopic {    
   my $session = shift;
   my $query = $session->{cgiQuery};

   # Initialize Foswiki
   my $topic = $session->{topicName};
   my $webName = $session->{webName};
   my $userName = Foswiki::Func::getWikiName();
   my $theUrl = $query->url;
}