package Mixin::Event::Dispatch;
# ABSTRACT: Mixin methods for simple event/message dispatch framework
use strict;
use warnings;
use List::UtilsBy qw(extract_by);
use Try::Tiny;

our $VERSION = 0.001;

=head1 NAME

Mixin::Event::Dispatch - mixin methods for simple event/message dispatch framework

=head1 SYNOPSIS

 my $obj = Some::Class->new;
 $obj->add_handler_for_event(some_event => sub { my $self = shift; warn "had some_event: @_"; });
 $obj->invoke_event(some_event => 'message here');

=head1 DESCRIPTION

=cut

=head1 METHODS

=cut


=head2 C<invoke_event>

Takes an C<event> parameter, and optional additional parameters that are passed to any callbacks.

Returns $self if a handler was found, undef if not.

=cut

sub invoke_event {
	my $self = shift;
	my $ev = shift;
	++$self->{event_count}->{$ev};

	my $run_event = sub {
		my $code = shift;
		try {
			!$code->($self, @_);
		} catch {
			die $_ if $ev eq 'event_error';
			$self->invoke_event(event_error => $_) or die "$_ and no event_error handler found";
		}
	};
	if(scalar @{$self->{event_stack}->{$ev} || [] }) {
		# Run all the queued code for this event, removing the handlers that return false.
		extract_by { $run_event->($_) } @{$self->{event_stack}->{$ev}};
		return $self;
	} elsif(my $code = $self->can("on_$ev")) {
		$run_event->($code);
		return $self;
	}
	return undef;
}

sub add_handler_for_event {
	my $self = shift;
	while(@_) {
		my ($ev, $code) = splice @_, 0, 2;
		push @{$self->{event_stack}->{$ev}}, $code;
	}
	return $self;
}

1;

__END__

=head1 AUTHOR

Tom Molesworth <cpan@entitymodel.com>

=head1 LICENSE

Copyright Tom Molesworth 2011. Licensed under the same terms as Perl itself.

