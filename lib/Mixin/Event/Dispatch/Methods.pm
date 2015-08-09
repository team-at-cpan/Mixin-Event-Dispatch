package Mixin::Event::Dispatch::Methods;

use strict;
use warnings;

use parent qw(Exporter);

use Mixin::Event::Dispatch;

my @functions = qw(
	invoke_event
	subscribe_to_event
	unsubscribe_from_event
	add_handler_for_event
	event_handlers
	clear_event_handlers
);

our @EXPORT;

our @EXPORT_OK = @functions;

our %EXPORT_TAGS = (
	all   => [ @functions ],
	basic => [ qw(invoke_event subscribe_to_event unsubscribe_from_event event_handlers) ],
);

{
	no strict 'refs';
	*$_ = *{'Mixin::Event::Dispatch::' . $_ } for @functions;
}

1;

