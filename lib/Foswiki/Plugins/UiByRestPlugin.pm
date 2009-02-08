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

    # do-some-UI-action rest handlers
    # 2-letter shortcuts for limited-url-length environments
    Foswiki::Func::registerRESTHandler('login',             \&_login);
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

    # request-a-UI-form ( template ) rest handlers
    Foswiki::Func::registerRESTHandler('trform',                \&_renameTopicForm);
    return 1;
}

sub _showTemplate {
    my ( $topic, $web, $skin, $templatename ) = @_;

    my $template = Foswiki::Func::loadTemplate( $templatename, $skin, undef );
    return Foswiki::Func::expandCommonVariables( $template, $topic, $web, undef );
}

=begin TML

---++ _login( $session )
Perform a login and return eventually a login form

=cut

sub _login {
    my $session = shift;
    return Foswiki::Plugins::UiByRestPlugin::Login::do( $session );
}

=begin TML

---++ _renameTopicForm( $session )
Return the template which is defined for renaming a topic ( renametopic.YOURSKIN.tmpl )
=cut

sub _renameTopicForm {
    my $session = shift;
    use Foswiki::Plugins::UiByRestPlugin::TopicRename;
    return Foswiki::Plugins::UiByRestPlugin::TopicRename::template( $session );
}


=begin TML

---++ _renameTopic( $session )
This is a wrapper substitute for the rename bin script.

It checks the prerequisites and sets the following status codes:
400 : url parameter(s) are missing
400 : newtopic is not valid (non) wikiword
401 : access denied for unauthorized user
403 : the user is not allowed to RENAME the topic
404 : the source topic does not exist
409 : the target topic already exists

newweb url parameter will be replaces with source webname.

Return:
In case of an error, the renametopic template is returned.
In case of no error, the Manage:rename() method is invoked,
which will take further (url) parameters and may end in a redirect.

=cut

sub _renameTopic {
    my $session = shift;
    return Foswiki::Plugins::UiByRestPlugin::TopicRename::do($session);
}

=begin TML

---++ _moveTopic( $session )
This is a wrapper substitute for the rename bin script.

It checks the prerequisites and sets the following status codes:
400 : url parameter(s) are missing
400 : newtopic is not valid (non) wikiword
401 : access denied for unauthorized user
403 : the user is not allowed to RENAME the topic
404 : the source topic does not exist
409 : the target topic already exists

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
      $session->{response}->header( -status => "400 Missing parameter: ".join(",", @missing) );
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
      if ( $theUser eq $Foswiki::cfg{DefaultUserWikiName} ) {
        $session->{response}->header( -status => "401 Unauthorized" );
      } else {
        $session->{response}->header( -status => "403 Forbidden to rename this topic" );
      }
      return _showTemplate( $theTopic, $theWeb, $theSkin, $templatename );
    }

    # does the newtopic met the optional nonwikiword requirement?
    if ( !Foswiki::Func::isValidTopicName( $theNewTopic, Foswiki::isTrue( $query->param('nonwikiword') ) ) ) {
      $session->{response}->header( -status => "400 Not valid: newtopic" );
      return _showTemplate( $theTopic, $theWeb, $theSkin, $templatename );
    }

    # does newtopic already exists?
    if ( Foswiki::Func::topicExists( $theNewWeb, $theNewTopic ) ) {
      $session->{response}->header( -status => "409 Conflict Target topic already exists" );
      return _showTemplate( $theTopic, $theWeb, $theSkin, $templatename );
    }

    # if everything is fine, we can do the actual renaming now
    Foswiki::UI::Manage::rename( $session );

    return "";
}

=begin TML

---++ _moveAttachment( $session )
This is a wrapper substitute for the rename bin script.

It checks the prerequisites and sets the following status codes:
400 : url parameter(s) are missing
400 : newtopic is not valid (non) wikiword
401 : access denied for unauthorized user
403 : the user is not allowed to CHANGE on attachment topic
404 : attachment does not exist
409 : the target topic already exists

Return:
In case of an error, the moveattachment template is returned.
In case of no error, the Manage:rename() method is invoked,
which will take further (url) parameters and may end in a redirect.

=cut

sub _moveAttachment {
    my $session       = shift;
    my $query         = $session->{cgiQuery};
    my $theTopic      = $session->{topicName}; # set by topic-url-param (rest handler)
    my $theWeb        = $session->{webName};   # set by topic-url-param (rest handler)
    my $theUser       = Foswiki::Func::getWikiName();
    my $theSkin       = $query->param("skin")       || undef; # SMELL: should be sanatized
    my $theNewWeb     = $query->param("newweb")     || undef; # SMELL: should be sanatized
    my $theNewTopic   = $query->param("newtopic")   || undef; # SMELL: should be sanatized
    my $theAttachment = $query->param("attachment") || undef; # SMELL: should be sanatized
    my $isSetTopic    = $query->param("topic")      || 0;
    my $templatename  = "moveattachment";

    # check topic parameter first; if not set, the rest is irrelevant
    my @missing = ();
    if (!$isSetTopic)             { push( @missing, "topic") };
    if (!defined($theAttachment)) { push( @missing, "attachment") };
    if (!defined($theNewTopic))   { push( @missing, "newtopic") };
    if (!defined($theNewWeb))     { push( @missing, "newweb") };
    if ( scalar(@missing) > 0 ) {
      $session->{response}->header( -status => "400 Missing parameter: ".join(",", @missing) );
      return _showTemplate( $theTopic, $theWeb, $theSkin, $templatename );
    }

    # check if attachment exists
    if ( !Foswiki::Func::attachmentExists( $theWeb, $theTopic, $theAttachment ) ) {
      $session->{response}->header( -status => "404 Attachment not found" );
      return _showTemplate( $theTopic, $theWeb, $theSkin, $templatename );
    }

    # check permissions
    # ...on old location
    if ( !Foswiki::Func::checkAccessPermission( "CHANGE", $theUser, undef, $theTopic, $theWeb, undef ) ) {
      if ( $theUser eq $Foswiki::cfg{DefaultUserWikiName} ) {
        $session->{response}->header( -status => "401 Unauthorized" );
      } else {
        $session->{response}->header( -status => "403 Forbidden: Current location is write protected" );
      }
      return _showTemplate( $theTopic, $theWeb, $theSkin, $templatename );
    }
    # ...on new location
    if ( !Foswiki::Func::checkAccessPermission( "CHANGE", $theUser, undef, $theNewTopic, $theNewWeb, undef ) ) {
      if ( $theUser eq $Foswiki::cfg{DefaultUserWikiName} ) {
        $session->{response}->header( -status => "401 Unauthorized" );
      } else {
        $session->{response}->header( -status => "403 Forbidden: New location is write protected" );
      }
      return _showTemplate( $theTopic, $theWeb, $theSkin, $templatename );
    }

    # does newtopic exists?
    if ( !Foswiki::Func::topicExists( $theNewWeb, $theNewTopic ) ) {
      $session->{response}->header( -status => "404 New location not found" );
      return _showTemplate( $theTopic, $theWeb, $theSkin, $templatename );
    }

    # does attachment in new location already exists?
    if ( Foswiki::Func::attachmentExists( $theNewWeb, $theNewTopic, $theAttachment ) ) {
      $session->{response}->header( -status => "409 Conflict Target attachment already exists" );
      return _showTemplate( $theTopic, $theWeb, $theSkin, $templatename );
    }

    # if everything is fine, we can do the actual renaming now
    use Foswiki::UI::Manage;
    Foswiki::UI::Manage::rename( $session );

    return "done";
}

=begin TML

---++ _renameWeb( $session )
%X% *Untested yet* %X%

This is a wrapper substitute for the rename bin script.

It checks the prerequisites and sets the following status codes:
400 : url parameter(s) are missing
400 : newparentweb or newsubweb is not a valid webname
401 : access denied for unauthorized user
403 : the user is not allowed to CHANGE the topic
404 : the old web does not exist
409 : the newweb already exists

Return:
In case of an error, the renametopic template is returned.
In case of no error, the Manage:rename() method is invoked,
which will take further (url) parameters and may end in a redirect.

=cut

sub _renameWeb {
    my $session         = shift;
    my $query           = $session->{cgiQuery};
    my $theTopic        = $session->{topicName}; # set by topic-url-param (rest handler)
    my $theOldWeb       = $session->{webName};   # set by topic-url-param (rest handler)
    my $theUser         = Foswiki::Func::getWikiName();
    my $theSkin         = $query->param("skin")         || undef; # SMELL: should be sanatized
    my $theNewSubWeb    = $query->param("newsubweb")    || undef; # SMELL: should be sanatized
    my $theNewParentWeb = $query->param("newparentweb") || undef; # SMELL: should be sanatized
    my $isSetTopic      = $query->param("topic")        || 0;
    my $templatename    = "renameweb";

    # check topic parameter first; if not set, the rest is irrelevant
    my @missing = ();
    if (!$isSetTopic)               { push( @missing, "topic") };
    if (!defined($theNewSubWeb))    { push( @missing, "newsubweb") };
    if (!defined($theNewParentWeb)) { push( @missing, "newparentweb") };
    if ( scalar(@missing) > 0 ) {
      $session->{response}->header( -status => "400 Missing parameter: ".join(",", @missing) );
      return _showTemplate( $theTopic, $theOldWeb, $theSkin, $templatename );
    }

    # check if old web exists
    if ( !Foswiki::Func::webExists( $theOldWeb ) ) {
      $session->{response}->header( -status => "404 File not found" );
      return _showTemplate( $theTopic, $theOldWeb, $theSkin, $templatename );
    }

    # is the newparentweb a valid webname?
    if ( !Foswiki::Func::isValidWebName( $theNewParentWeb, 1 ) ) {
      $session->{response}->header( -status => "400 Not valid: newparentweb" );
      return _showTemplate( $theTopic, $theOldWeb, $theSkin, $templatename );
    }

    # is the newsubweb a valid webname?
    if ( !Foswiki::Func::isValidWebName( $theNewSubWeb, 1 ) ) {
      $session->{response}->header( -status => "400 Not valid: newnewsubweb" );
      return _showTemplate( $theTopic, $theOldWeb, $theSkin, $templatename );
    }

    # calculate the new webname
    my $newWeb;
    if ($theNewSubWeb) {
      if ($theNewParentWeb) {
        $newWeb = $theNewParentWeb . '/' . $theNewSubWeb;
      } else {
        $newWeb = $theNewSubWeb;
      }
    }
    my @tmp = split( /[\/\.]/, $theOldWeb );
    pop(@tmp);
    my $oldParentWeb = join( '/', @tmp );

    # check if new web exists
    if ( !Foswiki::Func::webExists( $newWeb ) ) {
      $session->{response}->header( -status => "409 Conflict. New web already exists." );
      return _showTemplate( $theTopic, $theOldWeb, $theSkin, $templatename );
    }

    # If the user is not allowed to rename anything in the parent web - stop here
    # This also ensures we check root webs for ALLOWROOTRENAME and DENYROOTRENAME
    if ( !Foswiki::Func::checkAccessPermission( 'RENAME', $theUser, undef, undef, $oldParentWeb || undef, undef ) ) {
      if ( $theUser eq $Foswiki::cfg{DefaultUserWikiName} ) {
        $session->{response}->header( -status => "401 Unauthorized" );
      } else {
        $session->{response}->header( -status => "403 Forbidden to rename in old parent web" );
      }
      return _showTemplate( $theTopic, $theOldWeb, $theSkin, $templatename );
    }

    # If old web is a root web then also stop if ALLOW/DENYROOTCHANGE prevents access
    if ( !$oldParentWeb && !Foswiki::Func::checkAccessPermission( 'CHANGE', $theUser, undef, undef, $oldParentWeb || undef, undef ) ) {
      if ( $theUser eq $Foswiki::cfg{DefaultUserWikiName} ) {
        $session->{response}->header( -status => "401 Unauthorized" );
      } else {
        $session->{response}->header( -status => "403 Forbidden to change old root parent web" );
      }
      return _showTemplate( $theTopic, $theOldWeb, $theSkin, $templatename );
    }

    # prepare the action for rename
    $query->param( "action", "renameweb" );

    # if everything is fine, we can do the actual renaming now
    use Foswiki::UI::Manage;
    Foswiki::UI::Manage::rename( $session );

    return "";
}
