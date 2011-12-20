package Bobby::Handler::Dashboard::MultipartPoll;
use Moose;
use namespace::autoclean;

extends 'Bobby::BaseHandler';
__PACKAGE__->asynchronous(1);

sub get {
    my($self, $channel) = @_;

    $channel ||= 1;

    my $client_id = $self->request->param('client_id') || rand(1);

    $self->multipart_xhr_push(1);

    my $mq = Tatsumaki::MessageQueue->instance($channel);

    $mq->poll($client_id, sub {
        my @events = @_;
        for my $event (@events) {
            $self->stream_write($event);
        }
    });
}

__PACKAGE__->meta->make_immutable;

1;