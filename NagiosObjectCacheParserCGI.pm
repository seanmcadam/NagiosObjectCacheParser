#!/usr/bin/perl
#
#
#    Parsing program for interfacing with NagiosObjectCacheParser
#    Copyright (C) 2015  R. Sean McAdam
#
#    This program is free software; you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation; either version 2 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License along
#    with this program; if not, write to the Free Software Foundation, Inc.,
#    51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
#
#

package NagiosObjectCacheParserCGI;

use NagiosObjectCacheParser;
use APR::Const;
use Apache2::Const -compile => qw(OK :log);
use Apache2::Log;
use Apache2::ServerRec;
use Apache2::RequestRec;
use Apache2::ServerUtil;
use Data::Dumper;
use Readonly;
use Carp;
use JSON;
use strict;

=head1 NAME

NagiosObjectCacheParserCGI - mod_perl Handler that interfaces with NagiosObjectCacheParser

=head1 DESCRIPTION

This program is a perl handler that takes requests and interfaces them to the NagiosObjectCacheParser.


=head1 EXAMPLE

	The URI constsis of the path  /uri_path and the command. An example command is GET_HOSTS, so you could use http://localhost/uri_path/GET_HOSTS.  You can set various options

=head1 COMMANDS


=head2 GET_COMMANDS

Get a list of all command names 

=head2 GET_COMMAND_VALUE 
	
Get some of all values for a specific command
	 

=head2 GET_CONTACTS 

Get a list of all contact names 
	 

=head2 GET_CONTACT_VALUE 
	
Get some of all values for a specific contact
	 

=head2 GET_CONTACTGROUPS 

Get a list of all contact group names 
	 

=head2 GET_CONTACTGROUP_VALUE 
	
Get some of all values for a specific contact group
	 

=head2 GET_HOSTS 

Get a list of all host names 
	 

=head2 GET_HOST_VALUE 
	
Get some of all values for a specific host
	 

=head2 GET_HOSTCOMMENTS 

Get a list of all host comments names 
	 

=head2 GET_HOST_HOSTCOMMENT_VALUE 
	
Get some of all values for a specific host comments
	 

=head2 GET_HOSTGROUPS 

Get a list of all host group names 
	 

=head2 GET_HOSTGROUP_VALUE 
	
Get some of all values for a specific host group
	 

=head2 GET_HOSTSTATUSES 

Get a list of all host status names 
	 

=head2 GET_HOSTSTATUS_VALUE 
	
Get some of all values for a specific host status
	 

=head2 GET_HOSTSERVICES 

Get a list of all host service names 
	 

=head2 GET_HOST_HOSTSERVICE_VALUE 
	
Get some of all values for a specific host service
	 

=head2 GET_HOSTSERVICECOMMENTS 

Get a list of all host service comment names 
	 

=head2 GET_HOST_HOSTSERVICECOMMENT_VALUE 
	
Get some of all values for a specific host service comment
	 

=head2 GET_SERVICEGROUPS 

Get a list of all service group names 
	 

=head2 GET_SERVICEGROUP_VALUE 
	
Get some of all values for a specific service group
	 

=head2 GET_HOSTSERVICESTATUSES 

Get a list of all host service status names 
	 

=head2 GET_HOST_HOSTSERVICESTATUSES_VALUE 
	
Get some of all values for a specific host service status
	 

=head2 GET_TIMEPERIODS 

Get a list of all timeperiod names 

=head2 GET_TIMEPERIOD_VALUE 
	
Get some of all values for a specific timeperiod

=head2 GET_JSON 
	 
Get a full JSON dump of the Object and Status cache files


=head1 OPTIONS

=head2 FORMAT

	JSON return value
	

=cut

Readonly our $GET_COMMANDS                       => 'GET_COMMANDS';
Readonly our $GET_COMMAND_VALUE                  => 'GET_COMMAND_VALUE';
Readonly our $GET_CONTACTS                       => 'GET_CONTACTS';
Readonly our $GET_CONTACT_VALUE                  => 'GET_CONTACT_VALUE';
Readonly our $GET_CONTACTGROUPS                  => 'GET_CONTACTGROUPS';
Readonly our $GET_CONTACTGROUP_VALUE             => 'GET_CONTACTGROUP_VALUE ';
Readonly our $GET_HOSTS                          => 'GET_HOSTS';
Readonly our $GET_HOST_VALUE                     => 'GET_HOST_VALUE';
Readonly our $GET_HOSTCOMMENTS                   => 'GET_HOSTCOMMENTS';
Readonly our $GET_HOST_HOSTCOMMENT_VALUE         => 'GET_HOST_HOSTCOMMENT_VALUE';
Readonly our $GET_HOSTGROUPS                     => 'GET_HOSTGROUPS';
Readonly our $GET_HOSTGROUP_VALUE                => 'GET_HOSTGROUP_VALUE';
Readonly our $GET_HOSTSTATUSES                   => 'GET_HOSTSTATUSES';
Readonly our $GET_HOSTSTATUS_VALUE               => 'GET_HOSTSTATUS_VALUE';
Readonly our $GET_HOSTSERVICES                   => 'GET_HOSTSERVICES';
Readonly our $GET_HOST_HOSTSERVICE_VALUE         => 'GET_HOST_HOSTSERVICE_VALUE';
Readonly our $GET_HOSTSERVICECOMMENTS            => 'GET_HOSTSERVICECOMMENTS';
Readonly our $GET_HOST_HOSTSERVICECOMMENT_VALUE  => 'GET_HOST_HOSTSERVICECOMMENT_VALUE';
Readonly our $GET_SERVICEGROUPS                  => 'GET_SERVICEGROUPS';
Readonly our $GET_SERVICEGROUP_VALUE             => 'GET_SERVICEGROUP_VALUE';
Readonly our $GET_HOSTSERVICESTATUSES            => 'GET_HOSTSERVICESTATUSES';
Readonly our $GET_HOST_HOSTSERVICESTATUSES_VALUE => 'GET_HOST_HOSTSERVICESTATUSES_VALUE';
Readonly our $GET_TIMEPERIODS                    => 'GET_TIMEPERIODS';
Readonly our $GET_TIMEPERIOD_VALUE               => 'GET_TIMEPERIOD_VALUE';
Readonly our $GET_JSON                           => 'GET_JSON';
Readonly our $RETURN_ERROR                       => 'ERROR';
Readonly our $RETURN_ERROR_VALUE                 => 'ERROR_VALUE';
Readonly our $RETURN_COMMAND                     => 'COMMAND';
Readonly our $RETURN_RETURN                      => 'RETURN';

Readonly our %COMMANDS => (
    $GET_COMMANDS                       => \&get_commands,
    $GET_COMMAND_VALUE                  => \&get_command_value,
    $GET_CONTACTS                       => \&get_contacts,
    $GET_CONTACT_VALUE                  => \&get_contact_value,
    $GET_CONTACTGROUPS                  => \&get_contactgroups,
    $GET_CONTACTGROUP_VALUE             => \&get_contactgroup_value,
    $GET_HOSTS                          => \&get_hosts,
    $GET_HOST_VALUE                     => \&get_host_value,
    $GET_HOSTCOMMENTS                   => \&get_hostcomments,
    $GET_HOST_HOSTCOMMENT_VALUE         => \&get_host_hostcomment_value,
    $GET_HOSTGROUPS                     => \&get_hostgroups,
    $GET_HOSTGROUP_VALUE                => \&get_hostgroup_value,
    $GET_HOSTSTATUSES                   => \&get_hoststatuses,
    $GET_HOSTSTATUS_VALUE               => \&get_hoststatu_value,
    $GET_HOSTSERVICES                   => \&get_hostservices,
    $GET_HOST_HOSTSERVICE_VALUE         => \&get_host_hostservice_value,
    $GET_HOSTSERVICECOMMENTS            => \&get_hostservicecomments,
    $GET_HOST_HOSTSERVICECOMMENT_VALUE  => \&get_host_hostservicecomment_value,
    $GET_SERVICEGROUPS                  => \&get_servicegroups,
    $GET_SERVICEGROUP_VALUE             => \&get_servicegroup_value,
    $GET_HOSTSERVICESTATUSES            => \&get_hostservicestatuses,
    $GET_HOST_HOSTSERVICESTATUSES_VALUE => \&get_host_hostservicestatus_value,
    $GET_TIMEPERIODS                    => \&get_timeperiods,
    $GET_TIMEPERIOD_VALUE               => \&get_timeperiod_value,
    $GET_JSON                           => \&get_pretty_json,
);

my $s          = Apache2::ServerUtil->server();
my $log_handle = $s->log;

#
# Over Ride LogLevel Settings in Apache config Here
#
# $s->loglevel( Apache2::Const::LOG_ERROR );
# $s->loglevel( Apache2::Const::LOG_WARNING );
# $s->loglevel( Apache2::Const::LOG_INFO );
# $s->loglevel(Apache2::Const::LOG_DEBUG);

my $NOCP = new NagiosObjectCacheParser( {
        $NAGIOS_APACHE_LOG_HANDLE => \$log_handle,
        $NAGIOS_SHARED_MEMORY     => 1,
} );

my $json = new JSON;

# -----------------------------------
#
# -----------------------------------
sub handler {
    my $r      = shift;
    my %return = ();

    $return{$RETURN_ERROR}       = 0;
    $return{$RETURN_ERROR_VALUE} = '';
    $return{$RETURN_COMMAND}     = '';
    $return{$RETURN_RETURN}      = 0;

    $r->content_type('application/json');
    my $command = $r->path_info;
    $command =~ s/^\///;
    $command =~ tr/a-z/A-Z/;
    $return{$RETURN_COMMAND} = $command;

    if ( !defined $COMMANDS{$command} ) {

        # Error routine here
        $return{$RETURN_ERROR}       = 1;
        $return{$RETURN_ERROR_VALUE} = "Command:'$command' not found"
          . "Acceptable Commands:\n"
          . "\t" . join( "\n\t", sort( keys(%COMMANDS) ) ) . "\n";
    }
    else {

        my @args = split( '&', $r->args() );

        # print "ARGS:" . Dumper $r->args;
        # print "\n\n";
        # print "URI:" . Dumper $r->uri;
        # print "\n\n";
        # print "COMMAND:'" . $command . "'";
        # print "\n\n";
        # print "REQUEST:" . Dumper $r->the_request;
        # print "\n\n";
        $return{$RETURN_RETURN} = $COMMANDS{$command}->( \@args );
    }

    print $json->pretty->encode( \%return );
    return Apache2::Const::OK;
}

# --------------------------------------------------------
#
# --------------------------------------------------------
sub get_commands {
    my ($arr_ref) = @_;
    my $ret = '';
    $ret = $NOCP->get_commands();
    $ret;
}

# --------------------------------------------------------
#
# --------------------------------------------------------
sub get_command_value {
    my ($arr_ref) = @_;
    my $ret = $NOCP->get_command_value($arr_ref);
    $ret;
}

# --------------------------------------------------------
#
# --------------------------------------------------------
sub get_contacts {
    my ($arr_ref) = @_;
    my $ret = $NOCP->get_contacts();
    $ret;
}

# --------------------------------------------------------
#
# --------------------------------------------------------
sub get_contact_value {
    my ($arr_ref) = @_;
    my $ret = $NOCP->get_contact_value($arr_ref);
    $ret;
}

# --------------------------------------------------------
#
# --------------------------------------------------------
sub get_contactgroups {
    my ($arr_ref) = @_;
    my $ret = $NOCP->get_contactgroups();
    $ret;
}

# --------------------------------------------------------
#
# --------------------------------------------------------
sub get_contactgroup_value {
    my ($arr_ref) = @_;
    my $ret = $NOCP->get_contactgroup_value($arr_ref);
    $ret;
}

# --------------------------------------------------------
#
# --------------------------------------------------------
sub get_hosts {
    my ($arr_ref) = @_;
    my $ret = $NOCP->get_hosts();
    $ret;
}

# --------------------------------------------------------
#
# --------------------------------------------------------
sub get_host_value {
    my ($arr_ref) = @_;
    my $ret = $NOCP->get_host_value($arr_ref);
    $ret;
}

# --------------------------------------------------------
#
# --------------------------------------------------------
sub get_hostcomments {
    my ($arr_ref) = @_;
    my $ret = $NOCP->get_hostcomments();
    $ret;
}

# --------------------------------------------------------
#
# --------------------------------------------------------
sub get_host_hostcomment_value {
    my ($arr_ref) = @_;
    my $ret = $NOCP->get_host_hostcomment_value($arr_ref);
    $ret;
}

# --------------------------------------------------------
#
# --------------------------------------------------------
sub get_hostgroups {
    my ($arr_ref) = @_;
    my $ret = $NOCP->get_hostgroups();
    $ret;
}

# --------------------------------------------------------
#
# --------------------------------------------------------
sub get_hostgroup_value {
    my ($arr_ref) = @_;
    my $ret = $NOCP->get_hostgroup_value($arr_ref);
    $ret;
}

# --------------------------------------------------------
#
# --------------------------------------------------------
sub get_hoststatuses {
    my ($arr_ref) = @_;
    my $ret = $NOCP->get_hoststatuses();
    $ret;
}

# --------------------------------------------------------
#
# --------------------------------------------------------
sub get_hoststatus_value {
    my ($arr_ref) = @_;
    my $ret = $NOCP->get_hoststatus_value($arr_ref);
    $ret;
}

# --------------------------------------------------------
#
# --------------------------------------------------------
sub get_hostservices {
    my ($arr_ref) = @_;
    my $ret = $NOCP->get_hostservices();
    $ret;
}

# --------------------------------------------------------
#
# --------------------------------------------------------
sub get_host_hostservice_value {
    my ($arr_ref) = @_;
    my $ret = $NOCP->get_hostservice_value($arr_ref);
    $ret;
}

# --------------------------------------------------------
#
# --------------------------------------------------------
sub get_hostservicecomments {
    my ($arr_ref) = @_;
    my $ret = $NOCP->get_hostservicecomments();
    $ret;
}

# --------------------------------------------------------
#
# --------------------------------------------------------
sub get_host_hostservicecomment_value {
    my ($arr_ref) = @_;
    my $ret = $NOCP->get_host_hostservicecomment_value($arr_ref);
    $ret;
}

# --------------------------------------------------------
#
# --------------------------------------------------------
sub get_servicegroups {
    my ($arr_ref) = @_;
    my $ret = $NOCP->get_servicegroups();
    $ret;
}

# --------------------------------------------------------
#
# --------------------------------------------------------
sub get_servicegroup_value {
    my ($arr_ref) = @_;
    my $ret = $NOCP->get_servicegroup_value($arr_ref);
    $ret;
}

# --------------------------------------------------------
#
# --------------------------------------------------------
sub get_hostservicestatuses {
    my ($arr_ref) = @_;
    my $ret = $NOCP->get_hostservicestatuses();
    $ret;
}

# --------------------------------------------------------
#
# --------------------------------------------------------
sub get_host_hostservicestatuses_value {
    my ($arr_ref) = @_;
    my $ret = $NOCP->get_host_hostservicestatuse_value();
    $ret;
}

# --------------------------------------------------------
#
# --------------------------------------------------------
sub get_timeperiods {
    my ($arr_ref) = @_;
    my $ret = $NOCP->get_timeperiods();
    $ret;
}

# --------------------------------------------------------
#
# --------------------------------------------------------
sub get_timeperiod_value {
    my ($arr_ref) = @_;
    my $ret = $NOCP->get_timeperiod_value();
    $ret;
}

# --------------------------------------------------------
#
# --------------------------------------------------------
sub get_json {
    my ($arr_ref) = @_;
    my $ret = $NOCP->get_json();
    $ret;
}

# --------------------------------------------------------
#
# --------------------------------------------------------
sub get_pretty_json {
    my ($arr_ref) = @_;
    my $ret = $NOCP->get_pretty_json();
    $ret;
}

# --------------------------------------------------------
#
# --------------------------------------------------------
sub log_error {
    my ($msg) = @_;
    $log_handle->error($msg);
}

1;

