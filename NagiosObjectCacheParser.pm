#!/usr/bin/perl
#
#
#    Parsing program for Nagios Object Cache files
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

=head1 NAME

NagiosObjectCacheParser - Parses the Nagios Object Cache files

=head1 DESCRIPTION

This program monitors the Nagios Cache files, and reparses them when either the object or status files are updated. The module can return individual values and lists of values from the Nagiosn, as well as a JSON formatted list of the whole data set.  Anytime a request is made to an instance of the NOCP object the cache files are checked and reparsed if needed.

=head1 EXAMPLE

	use NagiosObjectCacheParser;
	my $nocp = new NagiosObjectCacheParser ({
		$NAGIOS_STAT_FILE => '~/nagios.status.dat', 
		$NAGIOS_OBJ_FILE => '~/nagios.objects.cache', 
	};
	
	# Turn on JSON sorting
	$nocp->sort_json(1);
	
	# Print a JSON formatted output
	print $nocp->get_pretty_json;

=cut

package NagiosObjectCacheParser;

#use Data::Dumper;
use base qw( Exporter );
use JSON;
use Readonly;
use Carp;
use strict;

Readonly our $NAGIOS_JSON            => 'NAGIOS_JSON';
Readonly our $NAGIOS_OBJ_FILE        => 'NAGIOS_OBJ_FILE';
Readonly our $NAGIOS_OBJ_LINE_COUNT  => 'NAGIOS_OBJ_LINE_COUNT';
Readonly our $NAGIOS_OBJ_REF         => 'NAGIOS_OBJ_REF';
Readonly our $NAGIOS_OBJ_TS          => 'NAGIOS_OBJ_TS';
Readonly our $NAGIOS_STAT_FILE       => 'NAGIOS_STAT_FILE';
Readonly our $NAGIOS_STAT_LINE_COUNT => 'NAGIOS_STAT_LINE_COUNT';
Readonly our $NAGIOS_STAT_REF        => 'NAGIOS_STAT_REF';
Readonly our $NAGIOS_STAT_TS         => 'NAGIOS_STAT_TS';

Readonly our $ACTION_URL                           => 'action_url';
Readonly our $ACKNOWLEDGEMENT_TYPE                 => 'acknowledgement_type';
Readonly our $ACTIVE_CHECKS_ENABLED                => 'active_checks_enabled';
Readonly our $ACTIVE_HOST_CHECKS_ENABLED           => 'active_host_checks_enabled';
Readonly our $ACTIVE_ONDEMAND_HOST_CHECK_STATS     => 'active_ondemand_host_check_stats';
Readonly our $ACTIVE_ONDEMAND_SERVICE_CHECK_STATS  => 'active_ondemand_service_check_stats';
Readonly our $ACTIVE_SCHECULED_HOST_CHECK_STATS    => 'active_scheduled_host_check_stats';
Readonly our $ACTIVE_SCHECULED_SERVICE_CHECK_STATS => 'active_scheduled_service_check_stats';
Readonly our $ACTIVE_SERVICE_CHCKES_ENABLED        => 'active_service_checks_enabled';
Readonly our $ADDRESS                              => 'address';
Readonly our $ALIAS                                => 'alias';
Readonly our $APRIL                                => 'april';
Readonly our $AUGUST                               => 'august';
Readonly our $AUTHOR                               => 'author';
Readonly our $CACHED_HOST_CHECK_STATS              => 'cached_host_check_stats';
Readonly our $CACHED_SERVICE_CHECK_STATS           => 'cached_service_check_stats';
Readonly our $CAN_SUBMIT_COMMANDS                  => 'can_submit_commands';
Readonly our $CHECK_COMMAND                        => 'check_command';
Readonly our $CHECK_EXECUTION_TIME                 => 'check_execution_time';
Readonly our $CHECK_FRESHNESS                      => 'check_freshness';
Readonly our $CHECK_HOST_FRESHNESS                 => 'check_host_freshness';
Readonly our $CHECK_INTERVAL                       => 'check_interval';
Readonly our $CHECK_LATENCY                        => 'check_latency';
Readonly our $CHECK_OPTIONS                        => 'check_options';
Readonly our $CHECK_PERIOD                         => 'check_period';
Readonly our $CHECK_SERVICE_FRESHNESS              => 'check_service_freshness';
Readonly our $CHECK_TYPE                           => 'check_type';
Readonly our $COMMAND                              => 'command';
Readonly our $COMMAND_LINE                         => 'command_line';
Readonly our $COMMAND_NAME                         => 'command_name';
Readonly our $COMMENT_DATA                         => 'comment_data';
Readonly our $COMMENT_ID                           => 'comment_id';
Readonly our $CONTACT                              => 'contact';
Readonly our $CONTACTGROUP                         => 'contactgroup';
Readonly our $CONTACTGROUP_NAME                    => 'contactgroup_name';
Readonly our $CONTACT_GROUPS                       => 'contact_groups';
Readonly our $CONTACT_NAME                         => 'contact_name';
Readonly our $CONTACTSTATUS                        => 'contactstatus';
Readonly our $CONTACTSTATUS_NAME                   => 'contactstatus_name';
Readonly our $CREATED                              => 'created';
Readonly our $CURRENT_ATTEMPT                      => 'current_attempt';
Readonly our $CURRENT_EVENT_ID                     => 'current_event_id';
Readonly our $CURRENT_NOTIFICATION_ID              => 'current_notification_id';
Readonly our $CURRENT_NOTIFICATION_NUMBER          => 'current_notification_number';
Readonly our $CURRENT_PROBLEM_ID                   => 'current_problem_id';
Readonly our $CURRENT_STATE                        => 'current_state';
Readonly our $DAEMON_MODE                          => 'daemon_mode';
Readonly our $DECEMBER                             => 'december';
Readonly our $EMAIL                                => 'email';
Readonly our $ENABLE_EVENT_HANDLERS                => 'enable_event_handlers';
Readonly our $ENABLE_FAILURE_PREDICTION            => 'enable_failure_prediction';
Readonly our $ENABLE_FLAP_DETECTION                => 'enable_flap_detection';
Readonly our $ENABLE_NOTIFICATIONS                 => 'enable_notifications';
Readonly our $ENTRY_TIME                           => 'entry_time';
Readonly our $ENTRY_TYPE                           => 'entry_type';
Readonly our $EVENT_HANDLER_ENABLED                => 'event_handler_enabled';
Readonly our $EVENT_HANDLER                        => 'event_handler';
Readonly our $EXPIRES                              => 'expires';
Readonly our $EXPIRE_TIME                          => 'expire_time';
Readonly our $EXTERNAL_COMMAND_STATS               => 'external_command_stats';
Readonly our $FAILURE_PREDICTION_ENABLED           => 'failure_prediction_enabled';
Readonly our $FEBUARY                              => 'febuary';
Readonly our $FIRST_NOTIFICATION_DELAY             => 'first_notification_delay';
Readonly our $FLAP_DETECTION_ENABLED               => 'flap_detection_enabled';
Readonly our $FLAP_DETECTION_OPTIONS               => 'flap_detection_options';
Readonly our $FRESHNESS_THRESHOLD                  => 'freshness_threshold';
Readonly our $FRIDAY                               => 'friday';
Readonly our $GLOBAL_HOST_EVENT_HANDLER            => 'global_host_event_handler';
Readonly our $GLOBAL_SERVICE_EVENT_HANDLER         => 'global_service_event_handler';
Readonly our $HAS_BEEN_CHECKED                     => 'has_been_checked';
Readonly our $HIGH_EXTERNAL_COMMAND_BUFFER_SLOTS   => 'high_external_command_buffer_slots';
Readonly our $HIGH_FLAP_THRESHOLD                  => 'high_flap_threshold';
Readonly our $HOSTCOMMENT                          => 'hostcomment';
Readonly our $HOSTCOMMENT_NAME                     => 'hostcomment_name';
Readonly our $HOSTGROUP                            => 'hostgroup';
Readonly our $HOSTGROUP_NAME                       => 'hostgroup_name';
Readonly our $HOST                                 => 'host';
Readonly our $HOST_NAME                            => 'host_name';
Readonly our $HOST_NOTIFICATION_COMMANDS           => 'host_notification_commands';
Readonly our $HOST_NOTIFICATION_OPTIONS            => 'host_notification_options';
Readonly our $HOST_NOTIFICATION_PERIOD             => 'host_notification_period';
Readonly our $HOST_NOTIFICATIONS_ENABLED           => 'host_notifications_enabled';
Readonly our $HOSTSTATUS                           => 'hoststatus';
Readonly our $HOSTSTATUS_NAME                      => 'hoststatus_name';
Readonly our $INFO                                 => 'info';
Readonly our $INFO_NAME                            => 'info_name';
Readonly our $INITIAL_STATE                        => 'initial_state';
Readonly our $IS_FLAPPING                          => 'is_flapping';
Readonly our $IS_VOLATILE                          => 'is_volatile';
Readonly our $JANUARY                              => 'january';
Readonly our $JULY                                 => 'july';
Readonly our $JUNE                                 => 'june';
Readonly our $LAST_CHECK                           => 'last_check';
Readonly our $LAST_COMMAND_CHECK                   => 'last_command_check';
Readonly our $LAST_EVENT_ID                        => 'last_event_id';
Readonly our $LAST_HARD_STATE_CHANGE               => 'last_hard_state_change';
Readonly our $LAST_HARD_STATE                      => 'last_hard_state';
Readonly our $LAST_HOST_NOTIFICATION               => 'last_host_notification';
Readonly our $LAST_LOG_ROTATION                    => 'last_log_rotation';
Readonly our $LAST_NOTIFICATION                    => 'last_notification';
Readonly our $LAST_PROBLEM_ID                      => 'last_problem_id';
Readonly our $LAST_SERVICE_NOTIFICATION            => 'last_service_notification';
Readonly our $LAST_STATE_CHANGE                    => 'last_state_change';
Readonly our $LAST_TIME_CRITICAL                   => 'last_time_critical';
Readonly our $LAST_TIME_DOWN                       => 'last_time_down';
Readonly our $LAST_TIME_OK                         => 'last_time_ok';
Readonly our $LAST_TIME_UNREACHABLE                => 'last_time_unreachable';
Readonly our $LAST_TIME_UNKNOWN                    => 'last_time_unknown';
Readonly our $LAST_TIME_UP                         => 'last_time_up';
Readonly our $LAST_TIME_WARNING                    => 'last_time_warning';
Readonly our $LAST_UPDATE_CHECK                    => 'last_update_check';
Readonly our $LAST_UPDATE                          => 'last_update';
Readonly our $LAST_VERSION                         => 'last_version';
Readonly our $LONG_PLUGIN_OUTPUT                   => 'long_plugin_output';
Readonly our $LOW_FLAP_THRESHOLD                   => 'low_flap_threshold';
Readonly our $MARCH                                => 'march';
Readonly our $MAX_ATTEMPTS                         => 'max_attempts';
Readonly our $MAX_CHECK_ATTEMPTS                   => 'max_check_attempts';
Readonly our $MAY                                  => 'may';
Readonly our $MEMBERS                              => 'members';
Readonly our $MODIFIED_ATTRIBUTES                  => 'modified_attributes';
Readonly our $MODIFIED_HOST_ATTRIBUTES             => 'modified_host_attributes';
Readonly our $MODIFIED_SERVICE_ATTRIBUTES          => 'modified_service_attributes';
Readonly our $MONDAY                               => 'monday';
Readonly our $NAGIOS_PID                           => 'nagios_pid';
Readonly our $NEW_VERSION                          => 'new_version';
Readonly our $NEXT_CHECK                           => 'next_check';
Readonly our $NEXT_COMMENT_ID                      => 'next_comment_id';
Readonly our $NEXT_DOWNTIME_ID                     => 'next_downtime_id';
Readonly our $NEXT_EVENT_ID                        => 'next_event_id';
Readonly our $NEXT_NOTIFICATION_ID                 => 'next_notification_id';
Readonly our $NEXT_NOTIFICATION                    => 'next_notification';
Readonly our $NEXT_RROBLEM_ID                      => 'next_problem_id';
Readonly our $NO_MORE_NOTIFICATIONS                => 'no_more_notifications';
Readonly our $NOTES                                => 'notes';
Readonly our $NOTES_URL                            => 'notes_url';
Readonly our $NOTIFICATION_INTERVAL                => 'notification_interval';
Readonly our $NOTIFICATION_OPTIONS                 => 'notification_options';
Readonly our $NOTIFICATION_PERIOD                  => 'notification_period';
Readonly our $NOTIFICATIONS_ENABLED                => 'notifications_enabled';
Readonly our $NOVEMBER                             => 'november';
Readonly our $OBSESS_OVER_HOST                     => 'obsess_over_host';
Readonly our $OBSESS_OVER_HOSTS                    => 'obsess_over_hosts';
Readonly our $OBSESS_OVER_SERVICE                  => 'obsess_over_service';
Readonly our $OBSESS_OVER_SERVICES                 => 'obsess_over_services';
Readonly our $OCTOBER                              => 'october';
Readonly our $PARALLEL_HOST_CHECK_STATS            => 'parallel_host_check_stats';
Readonly our $PARALLELIZE_CHECK                    => 'parallelize_check';
Readonly our $PARENTS                              => 'parents';
Readonly our $PASSIVE_CHECKS_ENABLED               => 'passive_checks_enabled';
Readonly our $PASSIVE_HOST_CHECKS_ENABLED          => 'passive_host_checks_enabled';
Readonly our $PASSIVE_HOST_CHECK_STATS             => 'passive_host_check_stats';
Readonly our $PASSIVE_SERVICE_CHCKES_ENABLED       => 'passive_service_checks_enabled';
Readonly our $PASSIVE_SERVICE_CHECK_STATS          => 'passive_service_check_stats';
Readonly our $PERCENT_STATE_CHANGE                 => 'percent_state_change';
Readonly our $PERFORMANCE_DATA                     => 'performance_data';
Readonly our $PERSISTENT                           => 'persistent';
Readonly our $PLUGIN_OUTPUT                        => 'plugin_output';
Readonly our $PROBLEM_HAS_BEEN_ACKNOWLEDGED        => 'problem_has_been_acknowledged';
Readonly our $PROCESS_PERF_DATA                    => 'process_perf_data';
Readonly our $PROCESS_PERFORMANCE_DATA             => 'process_performance_data';
Readonly our $PROGRAM_START                        => 'program_start';
Readonly our $PROGRAMSTATUS_NAME                   => 'programstatus_name';
Readonly our $PROGRAMSTATUS                        => 'programstatus';
Readonly our $RETAIN_NONSTATUS_INFORMATION         => 'retain_nonstatus_information';
Readonly our $RETAIN_STATUS_INFORMATION            => 'retain_status_information';
Readonly our $RETRY_INTERVAL                       => 'retry_interval';
Readonly our $SATURDAY                             => 'saturday';
Readonly our $SCHEDULED_DOWNTIME_DEPTH             => 'scheduled_downtime_depth';
Readonly our $SEPTEMBER                            => 'september';
Readonly our $SERIAL_HOST_CHECK_STATS              => 'serial_host_check_stats';
Readonly our $SERVCECOMMENT_NAME                   => 'servicecomment_name';
Readonly our $SERVICECOMMENT                       => 'servicecomment';
Readonly our $SERVICE_DESCRIPTION                  => 'service_description';
Readonly our $SERVICEGROUP_NAME                    => 'servicegroup_name';
Readonly our $SERVICEGROUP                         => 'servicegroup';
Readonly our $SERVICE_NAME                         => 'service_name';
Readonly our $SERVICE_NOTIFICATION_COMMANDS        => 'service_notification_commands';
Readonly our $SERVICE_NOTIFICATION_OPTIONS         => 'service_notification_options';
Readonly our $SERVICE_NOTIFICATION_PERIOD          => 'service_notification_period';
Readonly our $SERVICE_NOTIFICATIONS_ENABLED        => 'service_notifications_enabled';
Readonly our $SERVICE                              => 'service';
Readonly our $SERVICESTATUS_NAME                   => 'servicestatus_name';
Readonly our $SERVICESTATUS                        => 'servicestatus';
Readonly our $SHOULD_BE_SCHEDULED                  => 'should_be_scheduled';
Readonly our $SOURCE                               => 'source';
Readonly our $STALKING_OPTIONS                     => 'stalking_options';
Readonly our $STATE_TYPE                           => 'state_type';
Readonly our $SUNDAY                               => 'sunday';
Readonly our $THURSDAY                             => 'thursday';
Readonly our $TIMEPERIOD_NAME                      => 'timeperiod_name';
Readonly our $TIMEPERIOD                           => 'timeperiod';
Readonly our $TOTAL_EXTERNAL_COMMAND_BUFFER_SLOTS  => 'total_external_command_buffer_slots';
Readonly our $TUESDAY                              => 'tuesday';
Readonly our $UPDATE_AVAILABLE                     => 'update_available';
Readonly our $USED_EXTERNAL_COMMAND_BUFFER_SLOTS   => 'used_external_command_buffer_slots';
Readonly our $VERSION                              => 'version';
Readonly our $WEDNESDAY                            => 'wednesday';

#
#
#
#
Readonly our %VALUES => (
    $ACKNOWLEDGEMENT_TYPE                 => 1,
    $ACTION_URL                           => 1,
    $ACTIVE_CHECKS_ENABLED                => 1,
    $ACTIVE_HOST_CHECKS_ENABLED           => 1,
    $ACTIVE_ONDEMAND_HOST_CHECK_STATS     => 1,
    $ACTIVE_ONDEMAND_SERVICE_CHECK_STATS  => 1,
    $ACTIVE_SCHECULED_HOST_CHECK_STATS    => 1,
    $ACTIVE_SCHECULED_SERVICE_CHECK_STATS => 1,
    $ACTIVE_SERVICE_CHCKES_ENABLED        => 1,
    $ADDRESS                              => 1,
    $ALIAS                                => 1,
    $APRIL                                => 1,
    $AUGUST                               => 1,
    $AUTHOR                               => 1,
    $CACHED_HOST_CHECK_STATS              => 1,
    $CACHED_SERVICE_CHECK_STATS           => 1,
    $CAN_SUBMIT_COMMANDS                  => 1,
    $CHECK_COMMAND                        => 1,
    $CHECK_EXECUTION_TIME                 => 1,
    $CHECK_FRESHNESS                      => 1,
    $CHECK_HOST_FRESHNESS                 => 1,
    $CHECK_INTERVAL                       => 1,
    $CHECK_LATENCY                        => 1,
    $CHECK_OPTIONS                        => 1,
    $CHECK_PERIOD                         => 1,
    $CHECK_SERVICE_FRESHNESS              => 1,
    $CHECK_TYPE                           => 1,
    $COMMAND_LINE                         => 1,
    $COMMENT_DATA                         => 1,
    $COMMENT_ID                           => 1,
    $CONTACT_GROUPS                       => 1,
    $CONTACT_NAME                         => 1,
    $CREATED                              => 1,
    $CURRENT_ATTEMPT                      => 1,
    $CURRENT_EVENT_ID                     => 1,
    $CURRENT_NOTIFICATION_ID              => 1,
    $CURRENT_NOTIFICATION_NUMBER          => 1,
    $CURRENT_PROBLEM_ID                   => 1,
    $CURRENT_STATE                        => 1,
    $DAEMON_MODE                          => 1,
    $DECEMBER                             => 1,
    $EMAIL                                => 1,
    $ENABLE_EVENT_HANDLERS                => 1,
    $ENABLE_FAILURE_PREDICTION            => 1,
    $ENABLE_FLAP_DETECTION                => 1,
    $ENABLE_NOTIFICATIONS                 => 1,
    $ENTRY_TYPE                           => 1,
    $EVENT_HANDLER                        => 1,
    $EVENT_HANDLER_ENABLED                => 1,
    $EXPIRES                              => 1,
    $EXPIRE_TIME                          => 1,
    $EXTERNAL_COMMAND_STATS               => 1,
    $FAILURE_PREDICTION_ENABLED           => 1,
    $FEBUARY                              => 1,
    $FIRST_NOTIFICATION_DELAY             => 1,
    $FLAP_DETECTION_ENABLED               => 1,
    $FLAP_DETECTION_OPTIONS               => 1,
    $FRESHNESS_THRESHOLD                  => 1,
    $FRIDAY                               => 1,
    $GLOBAL_HOST_EVENT_HANDLER            => 1,
    $GLOBAL_SERVICE_EVENT_HANDLER         => 1,
    $HAS_BEEN_CHECKED                     => 1,
    $HIGH_EXTERNAL_COMMAND_BUFFER_SLOTS   => 1,
    $HIGH_FLAP_THRESHOLD                  => 1,
    $HOST_NAME                            => 1,
    $HOST_NOTIFICATION_COMMANDS           => 1,
    $HOST_NOTIFICATION_OPTIONS            => 1,
    $HOST_NOTIFICATION_PERIOD             => 1,
    $HOST_NOTIFICATIONS_ENABLED           => 1,
    $INITIAL_STATE                        => 1,
    $IS_FLAPPING                          => 1,
    $IS_VOLATILE                          => 1,
    $JANUARY                              => 1,
    $JULY                                 => 1,
    $JUNE                                 => 1,
    $LAST_CHECK                           => 1,
    $LAST_COMMAND_CHECK                   => 1,
    $LAST_EVENT_ID                        => 1,
    $LAST_HARD_STATE                      => 1,
    $LAST_HARD_STATE_CHANGE               => 1,
    $LAST_HOST_NOTIFICATION               => 1,
    $LAST_LOG_ROTATION                    => 1,
    $LAST_NOTIFICATION                    => 1,
    $LAST_PROBLEM_ID                      => 1,
    $LAST_SERVICE_NOTIFICATION            => 1,
    $LAST_STATE_CHANGE                    => 1,
    $LAST_TIME_CRITICAL                   => 1,
    $LAST_TIME_DOWN                       => 1,
    $LAST_TIME_OK                         => 1,
    $LAST_TIME_UNKNOWN                    => 1,
    $LAST_TIME_UNREACHABLE                => 1,
    $LAST_TIME_UP                         => 1,
    $LAST_TIME_WARNING                    => 1,
    $LAST_UPDATE                          => 1,
    $LAST_UPDATE_CHECK                    => 1,
    $LAST_VERSION                         => 1,
    $LONG_PLUGIN_OUTPUT                   => 1,
    $LOW_FLAP_THRESHOLD                   => 1,
    $MARCH                                => 1,
    $MAX_ATTEMPTS                         => 1,
    $MAX_CHECK_ATTEMPTS                   => 1,
    $MAY                                  => 1,
    $MODIFIED_ATTRIBUTES                  => 1,
    $MODIFIED_HOST_ATTRIBUTES             => 1,
    $MODIFIED_SERVICE_ATTRIBUTES          => 1,
    $MONDAY                               => 1,
    $NAGIOS_PID                           => 1,
    $NEW_VERSION                          => 1,
    $NEXT_CHECK                           => 1,
    $NEXT_COMMENT_ID                      => 1,
    $NEXT_DOWNTIME_ID                     => 1,
    $NEXT_EVENT_ID                        => 1,
    $NEXT_NOTIFICATION                    => 1,
    $NEXT_NOTIFICATION_ID                 => 1,
    $NEXT_RROBLEM_ID                      => 1,
    $NO_MORE_NOTIFICATIONS                => 1,
    $NOTES                                => 1,
    $NOTES_URL                            => 1,
    $NOTIFICATION_INTERVAL                => 1,
    $NOTIFICATION_OPTIONS                 => 1,
    $NOTIFICATION_PERIOD                  => 1,
    $NOTIFICATIONS_ENABLED                => 1,
    $NOVEMBER                             => 1,
    $OBSESS_OVER_HOST                     => 1,
    $OBSESS_OVER_HOSTS                    => 1,
    $OBSESS_OVER_SERVICE                  => 1,
    $OBSESS_OVER_SERVICES                 => 1,
    $OCTOBER                              => 1,
    $PARALLEL_HOST_CHECK_STATS            => 1,
    $PARALLELIZE_CHECK                    => 1,
    $PARENTS                              => 1,
    $PASSIVE_CHECKS_ENABLED               => 1,
    $PASSIVE_HOST_CHECKS_ENABLED          => 1,
    $PASSIVE_HOST_CHECK_STATS             => 1,
    $PASSIVE_SERVICE_CHCKES_ENABLED       => 1,
    $PASSIVE_SERVICE_CHECK_STATS          => 1,
    $PERCENT_STATE_CHANGE                 => 1,
    $PERFORMANCE_DATA                     => 1,
    $PERSISTENT                           => 1,
    $PLUGIN_OUTPUT                        => 1,
    $PROBLEM_HAS_BEEN_ACKNOWLEDGED        => 1,
    $PROCESS_PERF_DATA                    => 1,
    $PROCESS_PERFORMANCE_DATA             => 1,
    $PROGRAM_START                        => 1,
    $RETAIN_NONSTATUS_INFORMATION         => 1,
    $RETAIN_STATUS_INFORMATION            => 1,
    $RETRY_INTERVAL                       => 1,
    $SATURDAY                             => 1,
    $SCHEDULED_DOWNTIME_DEPTH             => 1,
    $SEPTEMBER                            => 1,
    $SERIAL_HOST_CHECK_STATS              => 1,
    $SERVICE_DESCRIPTION                  => 1,
    $SERVICE_NOTIFICATION_COMMANDS        => 1,
    $SERVICE_NOTIFICATION_OPTIONS         => 1,
    $SERVICE_NOTIFICATION_PERIOD          => 1,
    $SERVICE_NOTIFICATIONS_ENABLED        => 1,
    $SHOULD_BE_SCHEDULED                  => 1,
    $SOURCE                               => 1,
    $STALKING_OPTIONS                     => 1,
    $STATE_TYPE                           => 1,
    $SUNDAY                               => 1,
    $THURSDAY                             => 1,
    $TIMEPERIOD_NAME                      => 1,
    $TOTAL_EXTERNAL_COMMAND_BUFFER_SLOTS  => 1,
    $TUESDAY                              => 1,
    $UPDATE_AVAILABLE                     => 1,
    $USED_EXTERNAL_COMMAND_BUFFER_SLOTS   => 1,
    $VERSION                              => 1,
    $WEDNESDAY                            => 1,
);

#
#
#
#
Readonly our %COMMAND_OBJECT => (
    $COMMAND_NAME => 1,
    $COMMAND_LINE => 1,
);

#
#
#
#
Readonly our %CONTACT_OBJECT => (
    $ALIAS                         => 1,
    $CAN_SUBMIT_COMMANDS           => 1,
    $CONTACT_NAME                  => 1,
    $EMAIL                         => 1,
    $HOST_NOTIFICATION_COMMANDS    => 1,
    $HOST_NOTIFICATION_OPTIONS     => 1,
    $HOST_NOTIFICATION_PERIOD      => 1,
    $HOST_NOTIFICATIONS_ENABLED    => 1,
    $RETAIN_NONSTATUS_INFORMATION  => 1,
    $RETAIN_STATUS_INFORMATION     => 1,
    $SERVICE_NOTIFICATION_COMMANDS => 1,
    $SERVICE_NOTIFICATION_OPTIONS  => 1,
    $SERVICE_NOTIFICATION_PERIOD   => 1,
    $SERVICE_NOTIFICATIONS_ENABLED => 1,
);

#
#
#
#
Readonly our %CONTACTGROUP_OBJECT => (
    $ALIAS             => 1,
    $CONTACTGROUP_NAME => 1,
    $MEMBERS           => 1,
);

#
#
#
#
Readonly our %HOST_OBJECT => (
    $ACTION_URL                   => 1,
    $ACTIVE_CHECKS_ENABLED        => 1,
    $ADDRESS                      => 1,
    $ALIAS                        => 1,
    $CHECK_COMMAND                => 1,
    $CHECK_FRESHNESS              => 1,
    $CHECK_INTERVAL               => 1,
    $CHECK_PERIOD                 => 1,
    $CONTACT_GROUPS               => 1,
    $EVENT_HANDLER_ENABLED        => 1,
    $FAILURE_PREDICTION_ENABLED   => 1,
    $FIRST_NOTIFICATION_DELAY     => 1,
    $FLAP_DETECTION_ENABLED       => 1,
    $FLAP_DETECTION_OPTIONS       => 1,
    $FRESHNESS_THRESHOLD          => 1,
    $HIGH_FLAP_THRESHOLD          => 1,
    $HOST_NAME                    => 1,
    $INITIAL_STATE                => 1,
    $LOW_FLAP_THRESHOLD           => 1,
    $MAX_CHECK_ATTEMPTS           => 1,
    $NOTES                        => 1,
    $NOTES_URL                    => 1,
    $NOTIFICATION_INTERVAL        => 1,
    $NOTIFICATION_OPTIONS         => 1,
    $NOTIFICATION_PERIOD          => 1,
    $NOTIFICATIONS_ENABLED        => 1,
    $OBSESS_OVER_HOST             => 1,
    $PARENTS                      => 1,
    $PASSIVE_CHECKS_ENABLED       => 1,
    $PROCESS_PERF_DATA            => 1,
    $RETAIN_NONSTATUS_INFORMATION => 1,
    $RETAIN_STATUS_INFORMATION    => 1,
    $RETRY_INTERVAL               => 1,
    $STALKING_OPTIONS             => 1,
);

#
#
#
#
Readonly our %HOSTGROUP_OBJECT => (
    $ALIAS          => 1,
    $HOSTGROUP_NAME => 1,
    $MEMBERS        => 1,
);

#
#
#
#
Readonly our %SERVICE_OBJECT => (
    $ACTIVE_CHECKS_ENABLED        => 1,
    $ALIAS                        => 1,
    $CHECK_COMMAND                => 1,
    $CHECK_FRESHNESS              => 1,
    $CHECK_INTERVAL               => 1,
    $CHECK_PERIOD                 => 1,
    $CONTACT_GROUPS               => 1,
    $EVENT_HANDLER_ENABLED        => 1,
    $FAILURE_PREDICTION_ENABLED   => 1,
    $FIRST_NOTIFICATION_DELAY     => 1,
    $FLAP_DETECTION_ENABLED       => 1,
    $FLAP_DETECTION_OPTIONS       => 1,
    $FRESHNESS_THRESHOLD          => 1,
    $HIGH_FLAP_THRESHOLD          => 1,
    $HOST_NAME                    => 1,
    $INITIAL_STATE                => 1,
    $IS_VOLATILE                  => 1,
    $LOW_FLAP_THRESHOLD           => 1,
    $MAX_CHECK_ATTEMPTS           => 1,
    $NOTIFICATION_INTERVAL        => 1,
    $NOTIFICATION_OPTIONS         => 1,
    $NOTIFICATION_PERIOD          => 1,
    $NOTIFICATIONS_ENABLED        => 1,
    $OBSESS_OVER_SERVICE          => 1,
    $PARALLELIZE_CHECK            => 1,
    $PASSIVE_CHECKS_ENABLED       => 1,
    $PROCESS_PERF_DATA            => 1,
    $RETAIN_NONSTATUS_INFORMATION => 1,
    $RETAIN_STATUS_INFORMATION    => 1,
    $RETRY_INTERVAL               => 1,
    $SERVICE_DESCRIPTION          => 1,
    $STALKING_OPTIONS             => 1,
);

#
#
#
#
Readonly our %SERVICEGROUP_OBJECT => (
    $ALIAS             => 1,
    $MEMBERS           => 1,
    $SERVICEGROUP_NAME => 1,
);

#
#
#
#
Readonly our %TIMEPERIOD_OBJECT => (
    $ALIAS           => 1,
    $APRIL           => 1,
    $AUGUST          => 1,
    $DECEMBER        => 1,
    $FEBUARY         => 1,
    $FRIDAY          => 1,
    $JANUARY         => 1,
    $JULY            => 1,
    $JUNE            => 1,
    $MARCH           => 1,
    $MAY             => 1,
    $MONDAY          => 1,
    $NOVEMBER        => 1,
    $OCTOBER         => 1,
    $SATURDAY        => 1,
    $SEPTEMBER       => 1,
    $SUNDAY          => 1,
    $THURSDAY        => 1,
    $TIMEPERIOD_NAME => 1,
    $TUESDAY         => 1,
    $WEDNESDAY       => 1,
);

#
#
#
#
Readonly our %OBJECTS => (
    $COMMAND      => \%COMMAND_OBJECT,
    $CONTACT      => \%CONTACT_OBJECT,
    $CONTACTGROUP => \%CONTACTGROUP_OBJECT,
    $HOST         => \%HOST_OBJECT,
    $HOSTGROUP    => \%HOSTGROUP_OBJECT,
    $SERVICE      => \%SERVICE_OBJECT,
    $SERVICEGROUP => \%SERVICEGROUP_OBJECT,
    $TIMEPERIOD   => \%TIMEPERIOD_OBJECT,
);

#
#
#
#
Readonly our %OBJECT_NAMES => (
    $COMMAND      => $COMMAND_NAME,
    $CONTACT      => $CONTACT_NAME,
    $CONTACTGROUP => $CONTACTGROUP_NAME,
    $HOST         => $HOST_NAME,
    $HOSTGROUP    => $HOSTGROUP_NAME,
    $SERVICE      => undef,
    $SERVICEGROUP => $SERVICEGROUP_NAME,
    $TIMEPERIOD   => $TIMEPERIOD_NAME,
);

#
#
#
#
Readonly our %CONTACTSTATUS_STATUS => (
    $CONTACT_NAME                  => 1,
    $HOST_NOTIFICATION_PERIOD      => 1,
    $HOST_NOTIFICATIONS_ENABLED    => 1,
    $LAST_HOST_NOTIFICATION        => 1,
    $LAST_SERVICE_NOTIFICATION     => 1,
    $MODIFIED_ATTRIBUTES           => 1,
    $MODIFIED_HOST_ATTRIBUTES      => 1,
    $MODIFIED_SERVICE_ATTRIBUTES   => 1,
    $SERVICE_NOTIFICATION_PERIOD   => 1,
    $SERVICE_NOTIFICATIONS_ENABLED => 1,
);

#
#
#
#
Readonly our %HOSTCOMMENT_STATUS => (
    $AUTHOR       => 1,
    $COMMENT_DATA => 1,
    $COMMENT_ID   => 1,
    $ENTRY_TIME   => 1,
    $ENTRY_TYPE   => 1,
    $EXPIRES      => 1,
    $EXPIRE_TIME  => 1,
    $HOST_NAME    => 1,
    $PERSISTENT   => 1,
    $SOURCE       => 1,
);

#
#
#
#
Readonly our %HOSTSTATUS_STATUS => (
    $ACKNOWLEDGEMENT_TYPE          => 1,
    $ACTIVE_CHECKS_ENABLED         => 1,
    $CHECK_COMMAND                 => 1,
    $CHECK_EXECUTION_TIME          => 1,
    $CHECK_INTERVAL                => 1,
    $CHECK_LATENCY                 => 1,
    $CHECK_OPTIONS                 => 1,
    $CHECK_PERIOD                  => 1,
    $CHECK_TYPE                    => 1,
    $CURRENT_ATTEMPT               => 1,
    $CURRENT_EVENT_ID              => 1,
    $CURRENT_NOTIFICATION_ID       => 1,
    $CURRENT_NOTIFICATION_NUMBER   => 1,
    $CURRENT_PROBLEM_ID            => 1,
    $CURRENT_STATE                 => 1,
    $EVENT_HANDLER                 => 1,
    $EVENT_HANDLER_ENABLED         => 1,
    $FAILURE_PREDICTION_ENABLED    => 1,
    $FLAP_DETECTION_ENABLED        => 1,
    $HAS_BEEN_CHECKED              => 1,
    $HOST_NAME                     => 1,
    $IS_FLAPPING                   => 1,
    $LAST_CHECK                    => 1,
    $LAST_EVENT_ID                 => 1,
    $LAST_HARD_STATE               => 1,
    $LAST_HARD_STATE_CHANGE        => 1,
    $LAST_NOTIFICATION             => 1,
    $LAST_PROBLEM_ID               => 1,
    $LAST_STATE_CHANGE             => 1,
    $LAST_TIME_DOWN                => 1,
    $LAST_TIME_UNREACHABLE         => 1,
    $LAST_TIME_UP                  => 1,
    $LAST_UPDATE                   => 1,
    $LONG_PLUGIN_OUTPUT            => 1,
    $MAX_ATTEMPTS                  => 1,
    $MODIFIED_ATTRIBUTES           => 1,
    $NEXT_CHECK                    => 1,
    $NEXT_NOTIFICATION             => 1,
    $NO_MORE_NOTIFICATIONS         => 1,
    $NOTIFICATION_PERIOD           => 1,
    $NOTIFICATIONS_ENABLED         => 1,
    $OBSESS_OVER_HOST              => 1,
    $OBSESS_OVER_SERVICE           => 1,
    $PASSIVE_CHECKS_ENABLED        => 1,
    $PERCENT_STATE_CHANGE          => 1,
    $PERFORMANCE_DATA              => 1,
    $PLUGIN_OUTPUT                 => 1,
    $PROBLEM_HAS_BEEN_ACKNOWLEDGED => 1,
    $PROCESS_PERFORMANCE_DATA      => 1,
    $RETRY_INTERVAL                => 1,
    $SCHEDULED_DOWNTIME_DEPTH      => 1,
    $SERVICE_DESCRIPTION           => 1,
    $SHOULD_BE_SCHEDULED           => 1,
    $STATE_TYPE                    => 1,
);

#
#
#
#
Readonly our %INFO_STATUS => (
    $CREATED           => 1,
    $VERSION           => 1,
    $LAST_UPDATE_CHECK => 1,
    $UPDATE_AVAILABLE  => 1,
    $LAST_VERSION      => 1,
    $NEW_VERSION       => 1,
);

#
#
#
#
Readonly our %PROGRAMSTATUS_STATUS => (
    $ACTIVE_HOST_CHECKS_ENABLED           => 1,
    $ACTIVE_ONDEMAND_HOST_CHECK_STATS     => 1,
    $ACTIVE_ONDEMAND_SERVICE_CHECK_STATS  => 1,
    $ACTIVE_SCHECULED_HOST_CHECK_STATS    => 1,
    $ACTIVE_SCHECULED_SERVICE_CHECK_STATS => 1,
    $ACTIVE_SERVICE_CHCKES_ENABLED        => 1,
    $CACHED_HOST_CHECK_STATS              => 1,
    $CACHED_SERVICE_CHECK_STATS           => 1,
    $CHECK_HOST_FRESHNESS                 => 1,
    $CHECK_SERVICE_FRESHNESS              => 1,
    $DAEMON_MODE                          => 1,
    $ENABLE_EVENT_HANDLERS                => 1,
    $ENABLE_FAILURE_PREDICTION            => 1,
    $ENABLE_FLAP_DETECTION                => 1,
    $ENABLE_NOTIFICATIONS                 => 1,
    $EXTERNAL_COMMAND_STATS               => 1,
    $GLOBAL_HOST_EVENT_HANDLER            => 1,
    $GLOBAL_SERVICE_EVENT_HANDLER         => 1,
    $HIGH_EXTERNAL_COMMAND_BUFFER_SLOTS   => 1,
    $LAST_COMMAND_CHECK                   => 1,
    $LAST_LOG_ROTATION                    => 1,
    $MODIFIED_HOST_ATTRIBUTES             => 1,
    $MODIFIED_SERVICE_ATTRIBUTES          => 1,
    $NAGIOS_PID                           => 1,
    $NEXT_COMMENT_ID                      => 1,
    $NEXT_DOWNTIME_ID                     => 1,
    $NEXT_EVENT_ID                        => 1,
    $NEXT_NOTIFICATION_ID                 => 1,
    $NEXT_RROBLEM_ID                      => 1,
    $OBSESS_OVER_HOSTS                    => 1,
    $OBSESS_OVER_SERVICES                 => 1,
    $PARALLEL_HOST_CHECK_STATS            => 1,
    $PASSIVE_HOST_CHECKS_ENABLED          => 1,
    $PASSIVE_HOST_CHECK_STATS             => 1,
    $PASSIVE_SERVICE_CHCKES_ENABLED       => 1,
    $PASSIVE_SERVICE_CHECK_STATS          => 1,
    $PROCESS_PERFORMANCE_DATA             => 1,
    $PROGRAM_START                        => 1,
    $SERIAL_HOST_CHECK_STATS              => 1,
    $TOTAL_EXTERNAL_COMMAND_BUFFER_SLOTS  => 1,
    $USED_EXTERNAL_COMMAND_BUFFER_SLOTS   => 1,
);

#
#
#
#
Readonly our %SERVCECOMMENT_STATUS => (
    $AUTHOR              => 1,
    $COMMENT_DATA        => 1,
    $COMMENT_ID          => 1,
    $ENTRY_TIME          => 1,
    $ENTRY_TYPE          => 1,
    $EXPIRES             => 1,
    $EXPIRE_TIME         => 1,
    $HOST_NAME           => 1,
    $PERSISTENT          => 1,
    $SERVICE_DESCRIPTION => 1,
    $SOURCE              => 1,
);

#
#
#
#
Readonly our %SERVICESTATUS_STATUS => (
    $ACKNOWLEDGEMENT_TYPE          => 1,
    $ACTIVE_CHECKS_ENABLED         => 1,
    $CHECK_COMMAND                 => 1,
    $CHECK_EXECUTION_TIME          => 1,
    $CHECK_INTERVAL                => 1,
    $CHECK_LATENCY                 => 1,
    $CHECK_OPTIONS                 => 1,
    $CHECK_PERIOD                  => 1,
    $CHECK_TYPE                    => 1,
    $CURRENT_ATTEMPT               => 1,
    $CURRENT_EVENT_ID              => 1,
    $CURRENT_NOTIFICATION_ID       => 1,
    $CURRENT_NOTIFICATION_NUMBER   => 1,
    $CURRENT_PROBLEM_ID            => 1,
    $CURRENT_STATE                 => 1,
    $EVENT_HANDLER                 => 1,
    $EVENT_HANDLER_ENABLED         => 1,
    $FAILURE_PREDICTION_ENABLED    => 1,
    $FLAP_DETECTION_ENABLED        => 1,
    $HAS_BEEN_CHECKED              => 1,
    $HOST_NAME                     => 1,
    $IS_FLAPPING                   => 1,
    $LAST_CHECK                    => 1,
    $LAST_EVENT_ID                 => 1,
    $LAST_HARD_STATE               => 1,
    $LAST_HARD_STATE_CHANGE        => 1,
    $LAST_NOTIFICATION             => 1,
    $LAST_PROBLEM_ID               => 1,
    $LAST_STATE_CHANGE             => 1,
    $LAST_TIME_CRITICAL            => 1,
    $LAST_TIME_DOWN                => 1,
    $LAST_TIME_OK                  => 1,
    $LAST_TIME_UP                  => 1,
    $LAST_TIME_UNKNOWN             => 1,
    $LAST_TIME_WARNING             => 1,
    $LAST_UPDATE                   => 1,
    $LONG_PLUGIN_OUTPUT            => 1,
    $MAX_ATTEMPTS                  => 1,
    $MODIFIED_ATTRIBUTES           => 1,
    $NEXT_CHECK                    => 1,
    $NEXT_NOTIFICATION             => 1,
    $NO_MORE_NOTIFICATIONS         => 1,
    $NOTIFICATION_PERIOD           => 1,
    $NOTIFICATIONS_ENABLED         => 1,
    $OBSESS_OVER_SERVICE           => 1,
    $PASSIVE_CHECKS_ENABLED        => 1,
    $PERCENT_STATE_CHANGE          => 1,
    $PERFORMANCE_DATA              => 1,
    $PLUGIN_OUTPUT                 => 1,
    $PROBLEM_HAS_BEEN_ACKNOWLEDGED => 1,
    $PROCESS_PERFORMANCE_DATA      => 1,
    $RETRY_INTERVAL                => 1,
    $SCHEDULED_DOWNTIME_DEPTH      => 1,
    $SERVICE_DESCRIPTION           => 1,
    $SHOULD_BE_SCHEDULED           => 1,
    $STATE_TYPE                    => 1,
);

#
#
#
#
Readonly our %STATUS => (
    $CONTACTSTATUS  => \%CONTACTSTATUS_STATUS,
    $HOSTCOMMENT    => \%HOSTCOMMENT_STATUS,
    $HOSTSTATUS     => \%HOSTSTATUS_STATUS,
    $INFO           => \%INFO_STATUS,
    $PROGRAMSTATUS  => \%PROGRAMSTATUS_STATUS,
    $SERVICECOMMENT => \%SERVCECOMMENT_STATUS,
    $SERVICESTATUS  => \%SERVICESTATUS_STATUS,
);

#
#
#
#
Readonly our %STATUS_NAMES => (
    $INFO           => undef,
    $PROGRAMSTATUS  => undef,
    $CONTACTSTATUS  => $CONTACT_NAME,
    $HOSTCOMMENT    => $HOST_NAME,
    $HOSTSTATUS     => $HOST_NAME,
    $SERVICECOMMENT => $HOST_NAME,
    $SERVICESTATUS  => $HOST_NAME,
);

#
#
#
#
Readonly our %TABLES => (
    $COMMAND        => \%COMMAND_OBJECT,
    $CONTACT        => \%CONTACT_OBJECT,
    $CONTACTGROUP   => \%CONTACTGROUP_OBJECT,
    $CONTACTSTATUS  => \%CONTACTSTATUS_STATUS,
    $HOSTCOMMENT    => \%HOSTCOMMENT_STATUS,
    $HOSTGROUP      => \%HOSTGROUP_OBJECT,
    $HOST           => \%HOST_OBJECT,
    $HOSTSTATUS     => \%HOSTSTATUS_STATUS,
    $INFO           => \%INFO_STATUS,
    $PROGRAMSTATUS  => \%PROGRAMSTATUS_STATUS,
    $SERVICECOMMENT => \%SERVCECOMMENT_STATUS,
    $SERVICEGROUP   => \%SERVICEGROUP_OBJECT,
    $SERVICE        => \%SERVICE_OBJECT,
    $SERVICESTATUS  => \%SERVICESTATUS_STATUS,
    $TIMEPERIOD     => \%TIMEPERIOD_OBJECT,
);

#
#
#
#
our @EXPORT = qw(
  $NAGIOS_STAT_FILE
  $NAGIOS_OBJ_FILE
  $ACKNOWLEDGEMENT_TYPE
  $ACTION_URL
  $ACTIVE_CHECKS_ENABLED
  $ACTIVE_HOST_CHECKS_ENABLED
  $ACTIVE_ONDEMAND_HOST_CHECK_STATS
  $ACTIVE_ONDEMAND_SERVICE_CHECK_STATS
  $ACTIVE_SCHECULED_HOST_CHECK_STATS
  $ACTIVE_SCHECULED_SERVICE_CHECK_STATS
  $ACTIVE_SERVICE_CHCKES_ENABLED
  $ADDRESS
  $ALIAS
  $APRIL
  $AUGUST
  $AUTHOR
  $CACHED_HOST_CHECK_STATS
  $CACHED_SERVICE_CHECK_STATS
  $CAN_SUBMIT_COMMANDS
  $CHECK_COMMAND
  $CHECK_EXECUTION_TIME
  $CHECK_FRESHNESS
  $CHECK_HOST_FRESHNESS
  $CHECK_INTERVAL
  $CHECK_LATENCY
  $CHECK_OPTIONS
  $CHECK_PERIOD
  $CHECK_SERVICE_FRESHNESS
  $CHECK_TYPE
  $COMMAND_LINE
  $COMMENT_DATA
  $COMMENT_ID
  $CONTACT_GROUPS
  $CONTACT_NAME
  $CREATED
  $CURRENT_ATTEMPT
  $CURRENT_EVENT_ID
  $CURRENT_NOTIFICATION_ID
  $CURRENT_NOTIFICATION_NUMBER
  $CURRENT_PROBLEM_ID
  $CURRENT_STATE
  $DAEMON_MODE
  $DECEMBER
  $EMAIL
  $ENABLE_EVENT_HANDLERS
  $ENABLE_FAILURE_PREDICTION
  $ENABLE_FLAP_DETECTION
  $ENABLE_NOTIFICATIONS
  $ENTRY_TYPE
  $EVENT_HANDLER
  $EVENT_HANDLER_ENABLED
  $EXPIRES
  $EXPIRE_TIME
  $EXTERNAL_COMMAND_STATS
  $FAILURE_PREDICTION_ENABLED
  $FEBUARY
  $FIRST_NOTIFICATION_DELAY
  $FLAP_DETECTION_ENABLED
  $FLAP_DETECTION_OPTIONS
  $FRESHNESS_THRESHOLD
  $FRIDAY
  $GLOBAL_HOST_EVENT_HANDLER
  $GLOBAL_SERVICE_EVENT_HANDLER
  $HAS_BEEN_CHECKED
  $HIGH_EXTERNAL_COMMAND_BUFFER_SLOTS
  $HIGH_FLAP_THRESHOLD
  $HOST_NAME
  $HOST_NOTIFICATION_COMMANDS
  $HOST_NOTIFICATION_OPTIONS
  $HOST_NOTIFICATION_PERIOD
  $HOST_NOTIFICATIONS_ENABLED
  $INITIAL_STATE
  $IS_FLAPPING
  $IS_VOLATILE
  $JANUARY
  $JULY
  $JUNE
  $LAST_CHECK
  $LAST_COMMAND_CHECK
  $LAST_EVENT_ID
  $LAST_HARD_STATE
  $LAST_HARD_STATE_CHANGE
  $LAST_HOST_NOTIFICATION
  $LAST_LOG_ROTATION
  $LAST_NOTIFICATION
  $LAST_PROBLEM_ID
  $LAST_SERVICE_NOTIFICATION
  $LAST_STATE_CHANGE
  $LAST_TIME_CRITICAL
  $LAST_TIME_DOWN
  $LAST_TIME_OK
  $LAST_TIME_UNKNOWN
  $LAST_TIME_UNREACHABLE
  $LAST_TIME_UP
  $LAST_TIME_WARNING
  $LAST_UPDATE
  $LAST_UPDATE_CHECK
  $LAST_VERSION
  $LONG_PLUGIN_OUTPUT
  $LOW_FLAP_THRESHOLD
  $MARCH
  $MAX_ATTEMPTS
  $MAX_CHECK_ATTEMPTS
  $MAY
  $MODIFIED_ATTRIBUTES
  $MODIFIED_HOST_ATTRIBUTES
  $MODIFIED_SERVICE_ATTRIBUTES
  $MONDAY
  $NAGIOS_PID
  $NEW_VERSION
  $NEXT_CHECK
  $NEXT_COMMENT_ID
  $NEXT_DOWNTIME_ID
  $NEXT_EVENT_ID
  $NEXT_NOTIFICATION
  $NEXT_NOTIFICATION_ID
  $NEXT_RROBLEM_ID
  $NO_MORE_NOTIFICATIONS
  $NOTES
  $NOTES_URL
  $NOTIFICATION_INTERVAL
  $NOTIFICATION_OPTIONS
  $NOTIFICATION_PERIOD
  $NOTIFICATIONS_ENABLED
  $NOVEMBER
  $OBSESS_OVER_HOST
  $OBSESS_OVER_HOSTS
  $OBSESS_OVER_SERVICE
  $OBSESS_OVER_SERVICES
  $OCTOBER
  $PARALLEL_HOST_CHECK_STATS
  $PARALLELIZE_CHECK
  $PARENTS
  $PASSIVE_CHECKS_ENABLED
  $PASSIVE_HOST_CHECKS_ENABLED
  $PASSIVE_HOST_CHECK_STATS
  $PASSIVE_SERVICE_CHCKES_ENABLED
  $PASSIVE_SERVICE_CHECK_STATS
  $PERCENT_STATE_CHANGE
  $PERFORMANCE_DATA
  $PERSISTENT
  $PLUGIN_OUTPUT
  $PROBLEM_HAS_BEEN_ACKNOWLEDGED
  $PROCESS_PERF_DATA
  $PROCESS_PERFORMANCE_DATA
  $PROGRAM_START
  $RETAIN_NONSTATUS_INFORMATION
  $RETAIN_STATUS_INFORMATION
  $RETRY_INTERVAL
  $SATURDAY
  $SCHEDULED_DOWNTIME_DEPTH
  $SEPTEMBER
  $SERIAL_HOST_CHECK_STATS
  $SERVICE_DESCRIPTION
  $SERVICE_NOTIFICATION_COMMANDS
  $SERVICE_NOTIFICATION_OPTIONS
  $SERVICE_NOTIFICATION_PERIOD
  $SERVICE_NOTIFICATIONS_ENABLED
  $SHOULD_BE_SCHEDULED
  $SOURCE
  $STALKING_OPTIONS
  $STATE_TYPE
  $SUNDAY
  $THURSDAY
  $TIMEPERIOD_NAME
  $TOTAL_EXTERNAL_COMMAND_BUFFER_SLOTS
  $TUESDAY
  $UPDATE_AVAILABLE
  $USED_EXTERNAL_COMMAND_BUFFER_SLOTS
  $VERSION
  $WEDNESDAY
);

my $nagios_status_filename = '/dev/shm/nagios.status.dat';
my $nagios_object_filename = '/dev/shm/nagios.objects.cache';

=head1 METHODS

=cut

# -------------------------------------------------------------
#
# -------------------------------------------------------------

=head2 $nocp = new()

Create a new NOCP object

=cut

sub new {
    my ( $class, $parmref ) = @_;
    my $self = {
        $NAGIOS_JSON      => new JSON,
        $NAGIOS_STAT_FILE => $nagios_status_filename,
        $NAGIOS_OBJ_FILE  => $nagios_object_filename,
        $NAGIOS_STAT_REF  => \(),
        $NAGIOS_OBJ_REF   => \(),
        $NAGIOS_STAT_TS   => 0,
        $NAGIOS_OBJ_TS    => 0,
        $COMMAND          => {},
        $CONTACT          => {},
        $CONTACTGROUP     => {},
        $HOST             => {},
        $HOSTGROUP        => {},
        $SERVICE          => {},
        $SERVICEGROUP     => {},
        $TIMEPERIOD       => {},
        $CONTACTSTATUS    => {},
        $HOSTCOMMENT      => {},
        $HOSTSTATUS       => {},
        $INFO             => {},
        $PROGRAMSTATUS    => {},
        $SERVICECOMMENT   => {},
        $SERVICESTATUS    => {},
    };

    if ( defined $parmref ) {
        if ( $parmref->{$NAGIOS_STAT_FILE} ) {
            $self->{$NAGIOS_STAT_FILE} = $parmref->{$NAGIOS_STAT_FILE};
        }
        if ( $parmref->{$NAGIOS_OBJ_FILE} ) {
            $self->{$NAGIOS_OBJ_FILE} = $parmref->{$NAGIOS_OBJ_FILE};
        }
    }

    bless $self, $class;

    $self->_get_object_file();
    $self->_get_status_file();

    $self;
}

# -------------------------------------------------------------
# Set JSON sort option (consumes lots of CPU)
# -------------------------------------------------------------

=head2 $nocp->sort_json()

Sets the JSON sort option on or off 

=cut

sub sort_json {
    my ( $self, $sort ) = @_;
    $sort = ( defined $sort && $sort ) ? 1 : 0;
    return $self->{NAGIOS_JSON}->canonical( [$sort] )
}

# -------------------------------------------------------------
# Get JSON output of all NAGIOS data
# -------------------------------------------------------------

=head2 $nocp->get_json()

Returns a sorted JSON text structure of all of the Nagios object and status data

=cut

sub get_json {
    my ($self) = @_;
    $self->update();
    return $self->{NAGIOS_JSON}->encode( $self->_get_json_vals );
}

# -------------------------------------------------------------
# Get pretty JSON output of all NAGIOS data
# -------------------------------------------------------------

=head2 $nocp->get_pretty_json()

Returns a "pretty" sorted JSON text structure of all of the Nagios object and status data

=cut

sub get_pretty_json {
    my ($self) = @_;
    $self->update();
    return $self->{NAGIOS_JSON}->pretty->encode( $self->_get_json_vals );
}

# -------------------------------------------------------------
# Update cached data strucs if either files have been updated
# -------------------------------------------------------------

=head2 $nocp->update()

Call the update routine that will reparse the cache files if needed

=cut

sub update {
    my ($self) = @_;
    $self->_update_object_file() || $self->_update_status_file();
}

# -------------------------------------------------------------
#
# -------------------------------------------------------------

=head2 $nocp->get_commands()

Returns a list of the Nagios configured "commands"

=cut

sub get_commands {
    my ($self) = @_;
    $self->_get_table_keys($COMMAND);
}

# -------------------------------------------------------------
#
# -------------------------------------------------------------

=head2 $nocp->get_command_value()

Returns a value for the specific "command" name

=cut

sub get_command_value {
    my ( $self, $command, $name ) = @_;
    __verify_value_name($name);
    $self->_get_table_key_value( $COMMAND, $command, $name );
}

# -------------------------------------------------------------
#
# -------------------------------------------------------------

=head2 $nocp->get_contacts()

Returns a list of "contact" names

=cut

sub get_contacts {
    my ($self) = @_;
    $self->_get_table_keys($CONTACT);
}

# -------------------------------------------------------------
#
# -------------------------------------------------------------

=head2 $nocp->get_contact_value()

Returns a value for the specific "contact" name

=cut

sub get_contact_value {
    my ( $self, $contact, $name ) = @_;
    __verify_value_name($name);
    $self->_get_table_key_value( $CONTACT, $contact, $name );
}

# -------------------------------------------------------------
#
# -------------------------------------------------------------

=head2 $nocp->get_contactgroups()

Returns a list of "contactgroup" names

=cut

sub get_contactgroups {
    my ($self) = @_;
    $self->_get_table_keys($CONTACTGROUP);
}

# -------------------------------------------------------------
#
# -------------------------------------------------------------

=head2 $nocp->get_contactgroup_value()

Returns a value for the specific "contactgroup" name

=cut

sub get_contactgroup_value {
    my ( $self, $group, $name ) = @_;
    __verify_value_name($name);
    $self->_get_table_key_value( $CONTACTGROUP, $group, $name );
}

# -------------------------------------------------------------
#
# -------------------------------------------------------------

=head2 $nocp->get_hosts()

Returns a list "host" names

=cut

sub get_hosts {
    my ($self) = @_;
    $self->_get_table_keys($HOST);
}

# -------------------------------------------------------------
#
# -------------------------------------------------------------

=head2 $nocp->get_host_value()

Returns a value for the specific "host" name

=cut

sub get_host_value {
    my ( $self, $host, $name ) = @_;
    __verify_value_name($name);
    if ( $self->_verify_host($host) ) {
        $self->_get_table_key_value( $HOST, $host, $name );
    }
}

# -------------------------------------------------------------
#
# -------------------------------------------------------------

=head2 $nocp->get_hostcomments()

Returns a list "hostcomments" names

=cut

sub get_hostcomments {
    my ($self) = @_;
    $self->_get_table_keys($HOSTCOMMENT);
}

# -------------------------------------------------------------
#
# -------------------------------------------------------------

=head2 $nocp->get_host_hostcomment_value()

Returns a value for the specific "hostcomment" name

=cut

sub get_host_hostcomment_value {
    my ( $self, $host, $name ) = @_;
    __verify_value_name($name);
    if ( $self->_verify_host($host) ) {
        $self->_get_table_key_value( $HOSTCOMMENT, $host, $name );
    }
}

# -------------------------------------------------------------
#
# -------------------------------------------------------------

=head2 $nocp->hostgroups()

Returns a list "hostgroup" names

=cut

sub get_hostgroups {
    my ($self) = @_;
    $self->_get_table_keys($HOSTGROUP);
}

# -------------------------------------------------------------
#
# -------------------------------------------------------------

=head2 $nocp->get_hostgroup_value()

Returns a value for the specific "hostgroup" name

=cut

sub get_hostgroup_value {
    my ( $self, $hostgroup, $name ) = @_;
    __verify_value_name($name);
    $self->_get_table_key_value( $HOSTGROUP, $hostgroup, $name );
}

# -------------------------------------------------------------
#
# -------------------------------------------------------------

=head2 $nocp->get_hoststatus()

Returns a list "hoststatus" names

=cut

sub get_hoststatuses {
    my ($self) = @_;
    $self->_get_table_keys($HOSTSTATUS);
}

# -------------------------------------------------------------
#
# -------------------------------------------------------------

=head2 $nocp->get_host_hoststatus_value()

Returns a value for the specific "hoststatus" name

=cut

sub get_host_hoststatus_value {
    my ( $self, $host, $name ) = @_;
    __verify_value_name($name);
    if ( $self->_verify_host($host) ) {
        $self->_get_table_key_key_value( $HOSTSTATUS, $host, $name );
    }
}

# -------------------------------------------------------------
#
# -------------------------------------------------------------

=head2 $nocp->get_hostservices()

Returns a list "hostservice" names

=cut

sub get_hostservices {
    my ($self) = @_;
    $self->_get_table_keys($SERVICE);
}

# -------------------------------------------------------------
#
# -------------------------------------------------------------

=head2 $nocp->get_host_hostservice_value()

Returns a value for the specific "hostservice" name

=cut

sub get_host_hostservice_value {
    my ( $self, $host, $service, $name ) = @_;
    __verify_value_name($name);
    if ( $self->_verify_host($host) ) {
        $self->_get_table_key_key_value( $SERVICE, $service, $host, $name );
    }
}

# -------------------------------------------------------------
#
# -------------------------------------------------------------

=head2 $nocp->get_hostservicecomments()

Returns a list "hostservicecomment" names

=cut

sub get_hostservicecomments {
    my ($self) = @_;
    $self->_get_table_keys($SERVICECOMMENT);
}

# -------------------------------------------------------------
#
# -------------------------------------------------------------

=head2 $nocp->get_host_hostservicecomment_value()

Returns a value for the specific "hostservicecomment" name

=cut

sub get_host_hostservicecomment_value {
    my ( $self, $host, $servicecomment, $name ) = @_;
    __verify_value_name($name);
    if ( $self->_verify_host($host) ) {
        $self->_get_table_key_key_value( $SERVICECOMMENT, $servicecomment, $host, $name );
    }
}

# -------------------------------------------------------------
#
# -------------------------------------------------------------

=head2 $nocp->servicegroups()

Returns a list "servicegroup" names

=cut

sub get_servicegroups {
    my ($self) = @_;
    $self->_get_table_keys($SERVICEGROUP);
}

# -------------------------------------------------------------
#
# -------------------------------------------------------------

=head2 $nocp->get_servicegroup_value()

Returns a value for the specific "servicegroup" name

=cut

sub get_servicegroup_value {
    my ( $self, $servicegroup, $name ) = @_;
    __verify_value_name($name);
    $self->_get_table_key_value( $SERVICEGROUP, $servicegroup, $name );
}

# -------------------------------------------------------------
#
# -------------------------------------------------------------

=head2 $nocp->hostservicestatus()

Returns a list "hostservicestatus" names

=cut

sub get_hostservicestatuses {
    my ($self) = @_;
    $self->_get_table_keys($SERVICESTATUS);
}

# -------------------------------------------------------------
#
# -------------------------------------------------------------

=head2 $nocp->get_host_hostservicestatuses_value()

Returns a value for the specific "hostservicestatus" name

=cut

sub get_host_hostservicestatuses_value {
    my ( $self, $host, $servicestatus, $name ) = @_;
    __verify_value_name($name);
    if ( $self->_verify_host($host) ) {
        $self->_get_table_key_key_value( $SERVICESTATUS, $servicestatus, $host, $name );
    }
}

# -------------------------------------------------------------
#
# -------------------------------------------------------------

=head2 $nocp->get_timeperiods()

Returns a list "timeperiod" names

=cut

sub get_timepreiods {
    my ($self) = @_;
    $self->_get_table_keys($TIMEPERIOD);
}

# -------------------------------------------------------------
#
# -------------------------------------------------------------

=head2 $nocp->get_timeperiod_value()

Returns a value for the specific "timeperiod" name

=cut

sub get_timeperiod_value {
    my ( $self, $timeperiod, $name ) = @_;
    __verify_value_name($name);
    $self->_get_table_key_value( $TIMEPERIOD, $timeperiod, $name );
}

# -------------------------------------------------------------
#
# -------------------------------------------------------------
sub _get_table_key_key_value {
    my ( $self, $table, $key1, $key2, $name ) = @_;
    my $ret = undef;

    confess if !defined $table;
    confess if !defined $TABLES{$table};
    confess if !defined $key1;
    confess if !defined $key2;
    __verify_value_name($name);

    if ( defined $self->{$table}
        && defined $self->{$table}->{$key1}
        && defined $self->{$table}->{$key1}->{$key2}
        && defined $self->{$table}->{$key1}->{$key2}->{$name}
      ) {
        $ret = $self->{$table}->{$key1}->{$key2}->{$name};
    }

    $ret;
}

# -------------------------------------------------------------
#
# -------------------------------------------------------------
sub _get_table_key_value {
    my ( $self, $table, $key, $name ) = @_;
    my $ret = undef;

    confess if !defined $table;
    confess if !defined $TABLES{$table};
    confess if !defined $key;
    __verify_value_name($name);

    if ( defined $self->{$table}
        && defined $self->{$table}->{$key}
        && defined $self->{$table}->{$key}->{$name}
      ) {
        $ret = $self->{$table}->{$key}->{$name};
    }

    $ret;
}

# -------------------------------------------------------------
#
# -------------------------------------------------------------
sub _get_table_value {
    my ( $self, $table, $name ) = @_;
    my $ret = undef;

    confess if !defined $table;
    confess if !defined $TABLES{$table};
    __verify_value_name($name);

    if ( defined $self->{$table}
        && defined $self->{$table}->{$name}
      ) {
        $ret = $self->{$table}->{$name};
    }

    $ret;
}

# -------------------------------------------------------------
# -------------------------------------------------------------
# -------------------------------------------------------------

# -------------------------------------------------------------
#
# -------------------------------------------------------------
sub _get_table_keys {
    my ( $self, $table ) = @_;
    $self->update();
    confess if !defined $table;
    confess if !defined $TABLES{$table};

    sort( keys( %{ $self->{$table} } ) );

}

# -------------------------------------------------------------
#
# -------------------------------------------------------------
sub _verify_host {
    my ( $self, $host ) = @_;
    confess if !defined $host;
    return ( defined $self->{$HOST}->{$host} ) ? 1 : 0;
}

# -------------------------------------------------------------
#
# -------------------------------------------------------------
sub __verify_value_name {
    my ($name) = @_;
    confess("BAD VALUE '$name'\n") if !defined $VALUES{$name};
}

# -------------------------------------------------------------
#
# -------------------------------------------------------------
sub _get_json_vals {
    my ($self) = @_;

    my %vals = (
        $COMMAND        => $self->{$COMMAND},
        $CONTACT        => $self->{$CONTACT},
        $CONTACTGROUP   => $self->{$CONTACTGROUP},
        $HOST           => $self->{$HOST},
        $HOSTGROUP      => $self->{$HOSTGROUP},
        $SERVICE        => $self->{$SERVICE},
        $SERVICEGROUP   => $self->{$SERVICEGROUP},
        $TIMEPERIOD     => $self->{$TIMEPERIOD},
        $CONTACTSTATUS  => $self->{$CONTACTSTATUS},
        $HOSTCOMMENT    => $self->{$HOSTCOMMENT},
        $HOSTSTATUS     => $self->{$HOSTSTATUS},
        $INFO           => $self->{$INFO},
        $PROGRAMSTATUS  => $self->{$PROGRAMSTATUS},
        $SERVICECOMMENT => $self->{$SERVICECOMMENT},
        $SERVICESTATUS  => $self->{$SERVICESTATUS},
    );

    \%vals;
}

# -------------------------------------------------------------
#
# -------------------------------------------------------------
sub _reset_object {
    my ($self) = @_;
    $self->{NAGIOS_OBJ_TS} = 0;
    $self->{$COMMAND}      = {};
    $self->{$CONTACT}      = {};
    $self->{$CONTACTGROUP} = {};
    $self->{$HOST}         = {};
    $self->{$HOSTGROUP}    = {};
    $self->{$SERVICE}      = {};
    $self->{$SERVICEGROUP} = {};
    $self->{$TIMEPERIOD}   = {};
    $self->_reset_status();
}

# -------------------------------------------------------------
#
# -------------------------------------------------------------
sub _reset_status {
    my ($self) = @_;
    $self->{NAGIOS_STAT_TS}  = 0;
    $self->{$CONTACTSTATUS}  = {};
    $self->{$HOSTCOMMENT}    = {};
    $self->{$HOSTSTATUS}     = {};
    $self->{$INFO}           = {};
    $self->{$PROGRAMSTATUS}  = {};
    $self->{$SERVICECOMMENT} = {};
    $self->{$SERVICESTATUS}  = {};
}

# -------------------------------------------------------------
#
# -------------------------------------------------------------
sub _update_object_file {
    my ($self) = @_;
    my $ret = 0;

    my $ts = $self->_get_object_ts;
    if ( $ts > $self->{NAGIOS_OBJ_TS} ) {
        $self->_get_object_file();
        $self->_get_status_file();
        $ret = 1;
    }
    else {

        # print "NO OBJECT UPDATE NEEDED\n";
    }

    $ret;
}

# -------------------------------------------------------------
#
# -------------------------------------------------------------
sub _update_status_file {
    my ($self) = @_;
    my $ret = 0;

    my $ts = $self->_get_object_ts;
    if ( $ts > $self->{NAGIOS_STAT_TS} || $self->{NAGIOS_STAT_TS} < $self->{$NAGIOS_OBJ_TS} ) {
        $self->_get_status_file();
        $ret = 1;
    }
    else {

        # print "NO STATUS UPDATE NEEDED\n";
    }

    $ret;
}

# -------------------------------------------------------------
#
# -------------------------------------------------------------
sub _get_object_ts {
    my ($self) = @_;
    $self->_get_ts( $self->{NAGIOS_OBJ_FILE} );
}

# -------------------------------------------------------------
#
# -------------------------------------------------------------
sub _get_status_ts {
    my ($self) = @_;
    $self->_get_ts( $self->{NAGIOS_STAT_FILE} );
}

# -------------------------------------------------------------
#
# -------------------------------------------------------------
sub _get_ts {
    my ( $self, $filename ) = @_;

    if ( !-f $filename ) { confess "Cannot stat file '$filename'\n"; }
    ( stat($filename) )[9];
}

# -------------------------------------------------------------
#
# -------------------------------------------------------------
sub _get_object_file {
    my ($self) = @_;
    my $filename = $self->{NAGIOS_OBJ_FILE};

    $self->_reset_object;
    if ( !-f $filename ) { confess "Cannot stat file '$filename'\n"; }
    my $line_ref = $self->_get_cache_file($filename);
    $self->{NAGIOS_OBJ_REF} = $self->_get_cache_file($filename);
    $self->{NAGIOS_OBJ_TS}  = $self->_get_object_ts;
    $self->_parse_objects;
}

# -------------------------------------------------------------
#
# -------------------------------------------------------------
sub _get_status_file {
    my ($self) = @_;
    my $filename = $self->{NAGIOS_STAT_FILE};

    $self->_reset_status;
    if ( !-f $filename ) { confess "Cannot stat file '$filename'\n"; }
    $self->{NAGIOS_STAT_REF} = $self->_get_cache_file($filename);
    $self->{NAGIOS_STAT_TS}  = $self->_get_status_ts;
    $self->_parse_status;
}

# -------------------------------------------------------------
# Opens the file name passed in, returns an array of lines
# -------------------------------------------------------------
sub _get_cache_file {
    my ( $self, $filename ) = @_;
    my $file;
    my @lines;

    if ( !-f $filename ) { confess "Cannot stat file: '$filename'\n"; }

    open( $file, "<", $filename ) || confess "Cannot read $filename [$!]\n";
    while (<$file>) {
        my $line = $_;
        chomp $line;
        $line =~ s/^\s+//;
        $line =~ s/^\t+//;
        $line =~ s/\s+$//;

        push( @lines, $line );
    }
    close $file;

    \@lines;
}

# -------------------------------------------------------------
#
# -------------------------------------------------------------
sub _reset_status_line {
    my ($self) = @_;
    $self->{NAGIOS_STAT_LINE_COUNT} = 0;
}

# -------------------------------------------------------------
#
# -------------------------------------------------------------
sub _get_next_status_line {
    my ($self) = @_;
    $self->{NAGIOS_STAT_REF}->[ $self->{NAGIOS_STAT_LINE_COUNT}++ ];
}

# -------------------------------------------------------------
#
# contactstatus {
# hostcomment {
# hoststatus {
# info {
# programstatus {
# servicecomment {
# servicestatus {
#
# -------------------------------------------------------------
sub _parse_status {
    my ($self) = @_;

    $self->_reset_status_line;
    while ( defined( my $line = $self->_get_next_status_line ) ) {

        if ( $line =~ /^#/ ) { next; }
        if ( $line =~ /^$/ ) { next; }
        if ( $line eq '' ) { next; }

        if ( $line =~ /^\w+/ ) {
            if ( !( $line =~ /^(\w+) / ) ) {
                confess "BAD FORMAT\n";
            }
            my $status = $1;

            my $o = $self->_parse_stat($status);
            if ( defined $STATUS{$status} ) {

                if ( $status eq $SERVICESTATUS ) {
                    my $name = $o->{ $STATUS_NAMES{$status} };
                    my $desc = $o->{$SERVICE_DESCRIPTION};
                    if ( !defined $self->{$status}->{$name} ) {
                        my %h;
                        $self->{$status}->{$name} = \%h;
                    }

                    $self->{$status}->{$name}->{$desc} = $o;
                }
                elsif ( defined $STATUS_NAMES{$status} ) {
                    my $name = $o->{ $STATUS_NAMES{$status} };
                    $self->{$status}->{$name} = $o;
                }
                else {
                    $self->{$status} = $o;
                }

            }
            else {
                confess "UNKNOWN STATUS:'$status'\n";
            }

        }
        else {
            confess "Unknown Object Line: '$line'\n";
        }

    }

}

# -------------------------------------------------------------
#
# -------------------------------------------------------------
sub _parse_stat {
    my ( $self, $stat ) = @_;
    my $ref  = $STATUS{$stat};
    my $name = '';
    my %stat = ();

    my $line;
    while ( defined( my $line = $self->_get_next_status_line ) ) {
        if ( $line =~ /^}/ ) { last; }
        if ( $line =~ /^#/ ) { next; }
        if ( $line =~ /^$/ ) { next; }
        if ( $line eq '' ) { next; }

        if ( !( $line =~ /^\s*(\w+)=(.+)*/ ) ) {
            confess "Unknown status Line: '$line'\n";
        }

        my $status = $1;
        my $data   = $2;

        if ( !defined $ref->{$status} ) {
            confess "Unknown Sub-Status Line: '$line'\n";
        }

        $stat{$status} = $data;

    }

    \%stat;
}

# -------------------------------------------------------------
#
# -------------------------------------------------------------
sub _reset_object_line {
    my ($self) = @_;
    $self->{NAGIOS_OBJ_LINE_COUNT} = 0;
}

# -------------------------------------------------------------
#
# -------------------------------------------------------------
sub _get_next_object_line {
    my ($self) = @_;
    $self->{NAGIOS_OBJ_REF}->[ $self->{NAGIOS_OBJ_LINE_COUNT}++ ];
}

# -------------------------------------------------------------
#
# define command {
# define contact {
# define contactgroup {
# define host {
# define hostgroup {
# define service {
# define servicegroup {
# define timeperiod {
#
# -------------------------------------------------------------
sub _parse_objects {
    my ($self) = @_;

    $self->_reset_object_line;
    while ( defined( my $line = $self->_get_next_object_line ) ) {

        if ( $line =~ /^#/ ) { next; }
        if ( $line =~ /^$/ ) { next; }
        if ( $line eq '' ) { next; }

        if ( $line =~ /^define / ) {
            if ( !( $line =~ /^define\s+(\w+) / ) ) {
                confess "BAD FORMAT\n";
            }
            my $obj = $1;
            my $o   = $self->_parse_object($obj);

            if ( $obj eq $SERVICE ) {
                my $name = $o->{$HOST_NAME};
                my $desc = $o->{$SERVICE_DESCRIPTION};

                if ( !defined $self->{$SERVICE}->{$name} ) {
                    my %h;
                    $self->{$SERVICE}->{$name} = \%h;
                }

                $self->{$SERVICE}->{$name}->{$desc} = $o;
            }
            elsif ( defined $OBJECTS{$obj} ) {
                $self->{$obj}->{ $o->{ $OBJECT_NAMES{$obj} } } = $o;
            }
            else {
                confess "UNKNOWN OBJECT:'$obj'\n";
            }

        }
        else {
            confess "Unknown Object Line: '$line'\n";
        }

    }

}

# -------------------------------------------------------------
#
# -------------------------------------------------------------
sub _parse_object {
    my ( $self, $obj_type ) = @_;
    my %obj = ();
    my $ref = $OBJECTS{$obj_type};

    my $line;
    while ( defined( my $line = $self->_get_next_object_line ) ) {
        if ( $line =~ /^}/ ) { last; }
        if ( $line =~ /^#/ ) { next; }
        if ( $line =~ /^$/ ) { next; }
        if ( $line eq '' ) { next; }

        if ( !( $line =~ /^(\w+)[\t\s]+(.+)/ ) ) {
            confess "Unknown Object Line: '$line'\n";
        }
        my $obj  = $1;
        my $data = $2;

        if ( !defined $ref->{$obj} ) {
            confess "Unknown Sub-Object Line: '$line'\n";
        }

        $obj{$obj} = $data;

    }

    \%obj;
}

1;

