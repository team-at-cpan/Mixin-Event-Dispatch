package Mixin::Event::Dispatch::Event;
use strict;
use warnings;
use List::UtilsBy ();
use Try::Tiny;

our $VERSION = 0.005;

use constant DEBUG => 0;

=head1 NAME

Mixin::Event::Dispatch::Event - an event object

=head1 SYNOPSIS

 my $ev = Mixin::Event::Dispatch::Event->new(
   name => 'some_event',
   instance => $self,
 );

=head1 DESCRIPTION

=head1 METHODS

=cut

=head2 new

Takes the following (named) parameters:

=over 4

=item * name - the name of this event

=item * instance - the originating instance

=item * parent - another L<Mixin::Event::Dispatch::Event>
object if we were invoked within an existing handler

=item * handlers - the list of handlers for this event

=back

Time is of the essence, hence the peculiar implementation.

Returns $self.

=cut

sub new { bless { @_[1..$#_] }, $_[0] }

=head1 READ-ONLY ACCESSORS

=cut

=head2 name

Returns the name of this event.

=cut

sub name { $_[0]->{name} }

=head2 is_deferred

Returns true if this event has been deferred. This means
another handler is active, and has allowed remaining handlers
to take over the event - once those other handlers have
finished the original handler will be resumed.

=cut

sub is_deferred { $_[0]->{is_deferred} ? 1 : 0 }

=head2 is_stopped

Returns true if this event has been stopped. This means
no further handlers will be called.

=cut

sub is_stopped { $_[0]->{is_deferred} ? 1 : 0 }

=head2 instance

Returns the original object instance upon which the
L<Mixin::Event::Dispatch/invoke_event> method was called.

This may be different from the instance we're currently
handling, for cases of event delegation for example.

=cut

sub instance { $_[0]->{instance} }

=head2 parent

Returns the parent L<Mixin::Event::Dispatch::Event>, if there
was one. Usually there wasn't.

=cut

sub parent { $_[0]->{parent} }

=head2 handlers

Returns a list of the remaining handlers for this event.
Any that have already been called will be removed from this
list.

=cut

sub handlers {
	my $self = shift;
	@{$self->{remaining}||[]}
}

=head1 METHODS

=cut

=head2 stop

Stop processing for this event. Prevents any further event
handlers from being called.

=cut

sub stop {
	my $self = shift;
	$self->debug_print('Stopping') if DEBUG;
	$self->{is_stopped} = 1;
	$self
}

=head2 dispatch

Dispatches this event.

Takes the following (named) parameters:

=over 4

=item *

=back

Returns $self.

=cut

sub dispatch {
	my $self = shift;
	$self->debug_print("Dispatch with [@_]") if DEBUG;
	# Support pre-5.14 Perl versions. The only reason for not using
	# Try::Tiny here is performance; 10k events/sec with Try::Tiny on
	# an underpowered system, vs. 30k+ with plain eval.
	eval {
		while(!$self->is_stopped && @{$self->{handlers}}) {
			($self->{current_handler} = shift @{$self->{handlers}})->($self, @_) 
		}
		1;
	} or do {
		$self->debug_print("Exception $@ from [@_]") if DEBUG;
		die $@ if $self->name eq 'event_error';
		$self->instance->invoke_event(event_error => $@) or die "$@ and no event_error handler found";
	};
	$self
}
sub play { shift }

=head2 defer

Defers this event.

Causes remaining handlers to be called, and marks as
L</is_deferred>.

 sub {
  my $ev = shift;
  print "Deferring\n";
  $ev->defer(@_);
  print "Finished deferring\n";
 }

Returns $self.

=cut

sub defer {
	my $self = shift;
	$self->debug_print("Deferring with [@_]") if DEBUG;
	$self->{is_deferred} = 1;
	my $handler = $self->{current_handler};
	$self->dispatch(@_);
	$self->{current_handler} = $handler;
	$self;
}

sub unsubscribe {
	my $self = shift;
	$self->debug_print("Unsubscribing") if DEBUG;
	die "Cannot unsubscribe if we have no handler" unless $self->{current_handler};
	$self->instance->unsubscribe_from_event(
		$self->name => $self->{current_handler}
	);
	$self
}

sub debug_print {
	my $self = shift;
	printf "[%s] %s\n", $self->name, join ' ', @_;
	$self
}

1;

__END__

=head1 AUTHOR

Tom Molesworth <cpan@entitymodel.com>

=head1 LICENSE

Copyright Tom Molesworth 2012. Licensed under the same terms as Perl itself.

