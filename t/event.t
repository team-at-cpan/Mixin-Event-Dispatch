use strict;
use warnings;
package EventTest;
use parent qw(Mixin::Event::Dispatch);

sub new { bless {}, shift }
sub test_event_count { shift->{seen_test_event} }
sub on_test_event {
	my $self = shift;
	++$self->{seen_test_event};
}

package main;
use Test::More tests => 10;

my $obj = new_ok('EventTest');
ok($obj->invoke_event('test_event'), 'can invoke event with method available');
is($obj->test_event_count, 1, 'event count correct');
my $second = 0;
ok($obj->add_handler_for_event('second_test' => sub { ++$second; 0 }), 'can add handler for event');
is($second, 0, 'count is zero before invoking event');
ok($obj->invoke_event('second_test'), 'can invoke event with queued handler');
is($second, 1, 'count is 1 after invoking event');
ok(!$obj->invoke_event('second_test'), 'fails when handler no longer present');
is($second, 1, 'count is 1 after invoking event again');
is($obj->test_event_count, 1, 'event count correct');

