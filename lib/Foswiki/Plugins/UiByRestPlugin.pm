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
# Author: Eugen Mayer, Oliver Krueger

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

    # 2-letter shortcuts for limited-url-length environments
    Foswiki::Func::registerRESTHandler('topic_rename',      \&_renameTopic);
    Foswiki::Func::registerRESTHandler('tr',                \&_renameTopic);
    Foswiki::Func::registerRESTHandler('topic_move',        \&_moveTopic);
    Foswiki::Func::registerRESTHandler('tm',                \&_moveTopic);
    Foswiki::Func::registerRESTHandler('attachment_move',   \&_moveAttachment);
    Foswiki::Func::registerRESTHandler('am',                \&_moveAttachment);
    Foswiki::Func::registerRESTHandler('attachment_rename', \&_renameAttachment);
    Foswiki::Func::registerRESTHandler('ar',                \&_renameAttachment);
    Foswiki::Func::registerRESTHandler('revision_list',     \&_listRevisions);
    Foswiki::Func::registerRESTHandler('rl',                \&_listRevisions);
    Foswiki::Func::registerRESTHandler('revision_compare',  \&_compareRevisions);
    Foswiki::Func::registerRESTHandler('rc',                \&_compareRevisions);
    Foswiki::Func::registerRESTHandler('revision_restore',  \&_restoreRevision);
    Foswiki::Func::registerRESTHandler('rs',                \&_restoreRevision);
    Foswiki::Func::registerRESTHandler('parent_set',        \&_setParent);
    Foswiki::Func::registerRESTHandler('pa',                \&_setParent);
    Foswiki::Func::registerRESTHandler('preference_set',    \&_setPreference);
    Foswiki::Func::registerRESTHandler('ps',                \&_setPreference);
    Foswiki::Func::registerRESTHandler('preference_get',    \&_getPreference);
    Foswiki::Func::registerRESTHandler('pg',                \&_getPreference);
    Foswiki::Func::registerRESTHandler('child_get',         \&_getChildTopics);
    Foswiki::Func::registerRESTHandler('cg',                \&_getChildTopics);
    Foswiki::Func::registerRESTHandler('backlink_get',      \&_getBacklinks);
    Foswiki::Func::registerRESTHandler('bg',                \&_getBacklinks);
    Foswiki::Func::registerRESTHandler('web_rename',        \&_renameWeb);
    Foswiki::Func::registerRESTHandler('wr',                \&_renameWeb);
    Foswiki::Func::registerRESTHandler('web_move',          \&_moveWeb);
    Foswiki::Func::registerRESTHandler('wm',                \&_moveWeb);
    Foswiki::Func::registerRESTHandler('web_create',        \&_createWeb);
    Foswiki::Func::registerRESTHandler('wc',                \&_createWeb);

    return 1;
}

sub _showTemplate {
    my ( $topic, $web, $skin, $templatename ) = @_;
    my $template = Foswiki::Func::loadTemplate( $templatename, $skin, undef );
    return Foswiki::Func::expandCommonVariables( $template, $topic, $web, undef );
}

=begin TML

---++ _renameTopic( $session )

This is a wrapper substitute for the rename bin script. The main difference is,
that this method sets proper status codes.

It checks the prerequisites and sets the following status codes:
403 : the user is not allowed to CHANGE the topic
404 : the source topic does not exist
500 : url parameter(s) are missing
500 : newtopic is not valid (non) wikiword

newweb url parameter will be replaces with source webname.

Return:
In case of an error, the renametopic template is returned.
In case of no error, the Manage:rename() method is invoked,
which will take further (url) parameters and may end in a redirect.

=cut

sub _renameTopic {
    my $session      = shift;
    my $query        = $session->{cgiQuery};
    my $theTopic     = $session->{topicName}; # set by topic-url-param (rest handler)
    my $theWeb       = $session->{webName};   # set by topic-url-param (rest handler)
    my $theUser      = Foswiki::Func::getWikiName();
    my $theSkin      = $query->param("skin")     || undef; # SMELL: should be sanatized
    my $theNewTopic  = $query->param("newtopic") || undef; # SMELL: should be sanatized
    my $isSetTopic   = $query->param("topic")    || 0;
    my $templatename = "renametopic";

    # check topic parameter first; if not set, the rest is irrelevant
    my @missing = ();
    if (!$isSetTopic)           { push( @missing, "topic") };
    if (!defined($theNewTopic)) { push( @missing, "newtopic") };
    if ( scalar(@missing) > 0 ) {
      $session->{response}->header( -status => "500 Missing parameter: ".join(",", @missing) );
      return _showTemplate( $theTopic, $theWeb, $theSkin, $templatename );
    }

    use Foswiki::UI::Manage;
    $theNewTopic = Foswiki::UI::Manage::_safeTopicName( $theNewTopic );

    # check if topic exists
    if ( !Foswiki::Func::topicExists( $theWeb, $theTopic ) ) {
      $session->{response}->header( -status => "404 File not found" );
      return _showTemplate( $theTopic, $theWeb, $theSkin, $templatename );
    }

    # check permission
    if ( !Foswiki::Func::checkAccessPermission( "RENAME", $theUser, undef, $theTopic, $theWeb, undef ) ) {
      $session->{response}->header( -status => "403 Forbidden to rename this topic" );
      return _showTemplate( $theTopic, $theWeb, $theSkin, $templatenam );
    }

    # does the newtopic met the optional nonwikiword requirement?
    if ( !Foswiki::Func::isValidTopicName( $theNewTopic, Foswiki::isTrue( $query->param('nonwikiword') ) ) ) {
      $session->{response}->header( -status => "500 Not valid: newtopic" );
      return _showTemplate( $theTopic, $theWeb, $theSkin, $templatename );
    }

    # does newtopic already exists?
    if ( Foswiki::Func::topicExists( $theWeb, $theNewTopic ) ) {
      $session->{response}->header( -status => "500 Target topic already exists" );
      return _showTemplate( $theTopic, $theWeb, $theSkin );
    }

    # if everything is fine, we can do the actual renaming now
    $query->param( "newweb", $theWeb );
    Foswiki::UI::Manage::rename( $session );

    return "";
}

=begin TML

---++ _moveTopic( $session )

This is a wrapper substitute for the rename bin script. The main difference is,
that this method sets proper status codes.

It checks the prerequisites and sets the following status codes:
403 : the user is not allowed to CHANGE the topic
404 : the source topic does not exist
500 : url parameter(s) are missing
500 : newtopic is not valid (non) wikiword

Return:
In case of an error, the movetopic template is returned.
In case of no error, the Manage:rename() method is invoked,
which will take further (url) parameters and may end in a redirect.

=cut

sub _moveTopic {
    my $session      = shift;
    my $query        = $session->{cgiQuery};
    my $theTopic     = $session->{topicName}; # set by topic-url-param (rest handler)
    my $theWeb       = $session->{webName};   # set by topic-url-param (rest handler)
    my $theUser      = Foswiki::Func::getWikiName();
    my $theSkin      = $query->param("skin")     || undef; # SMELL: should be sanatized
    my $theNewWeb    = $query->param("newweb")   || undef; # SMELL: should be sanatized
    my $theNewTopic  = $query->param("newtopic") || undef; # SMELL: should be sanatized
    my $isSetTopic   = $query->param("topic")    || 0;
    my $templatename = "movetopic";

    # check topic parameter first; if not set, the rest is irrelevant
    my @missing = ();
    if (!$isSetTopic)           { push( @missing, "topic") };
    if (!defined($theNewTopic)) { push( @missing, "newtopic") };
    if (!defined($theNewWeb))   { push( @missing, "newweb") };
    if ( scalar(@missing) > 0 ) {
      $session->{response}->header( -status => "500 Missing parameter: ".join(",", @missing) );
      return _showTemplate( $theTopic, $theWeb, $theSkin, $templatename );
    }

    use Foswiki::UI::Manage;
    $theNewTopic = Foswiki::UI::Manage::_safeTopicName( $theNewTopic );

    # check if topic exists
    if ( !Foswiki::Func::topicExists( $theWeb, $theTopic ) ) {
      $session->{response}->header( -status => "404 File not found" );
      return _showTemplate( $theTopic, $theWeb, $theSkin, $templatename );
    }

    # check permission
    if ( !Foswiki::Func::checkAccessPermission( "RENAME", $theUser, undef, $theTopic, $theWeb, undef ) ) {
      $session->{response}->header( -status => "403 Forbidden to rename this topic" );
      return _showTemplate( $theTopic, $theWeb, $theSkin, $templatenam );
    }

    # does the newtopic met the optional nonwikiword requirement?
    if ( !Foswiki::Func::isValidTopicName( $theNewTopic, Foswiki::isTrue( $query->param('nonwikiword') ) ) ) {
      $session->{response}->header( -status => "500 Not valid: newtopic" );
      return _showTemplate( $theTopic, $theWeb, $theSkin, $templatename );
    }

    # does newtopic already exists?
    if ( Foswiki::Func::topicExists( $theNewWeb, $theNewTopic ) ) {
      $session->{response}->header( -status => "500 Target topic already exists" );
      return _showTemplate( $theTopic, $theWeb, $theSkin );
    }

    # if everything is fine, we can do the actual renaming now
    Foswiki::UI::Manage::rename( $session );

    return "";
}