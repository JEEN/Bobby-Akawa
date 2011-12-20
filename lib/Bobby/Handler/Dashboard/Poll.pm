package Bobby::Handler::Dashboard::Poll;
use Moose;
use namespace::autoclean;
use Tatsumaki::MessageQueue;
extends 'Bobby::BaseHandler';

__PACKAGE__->asynchronous(1);
$Tatsumaki::MessageQueue::BacklogLength = 1000;

sub get {
    my($self, $channel) = @_;

    $channel ||= 1;

    my $mq = Tatsumaki::MessageQueue->instance($channel);
    my $client_id = $self->request->param('client_id')
        or Tatsumaki::Error::HTTP->throw(500, "'client_id' needed");
    $mq->poll_once($client_id, sub { $self->on_new_event(@_) });
}

sub on_new_event {
    my($self, @events) = @_;
    $self->write(\@events);
    $self->finish;
}

__PACKAGE__->meta->make_immutable;

1;