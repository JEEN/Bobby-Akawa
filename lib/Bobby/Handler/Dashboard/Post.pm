package Bobby::Handler::Dashboard::Post;
use Moose;
use namespace::autoclean;
use Encode;

extends 'Bobby::BaseHandler';

sub post {
    my($self, $channel) = @_;

    $channel ||= 1;

    my $v = $self->request->parameters;
    my $mq = Tatsumaki::MessageQueue->instance($channel);

    $mq->publish({
        type => "message", id => $v->{id}, name => Encode::decode_utf8($v->{name}),
        lat => $v->{lat}, lng => $v->{lng}, icon => $v->{icon}, people => $v->{people},
        created_at => $v->{created_at}, address => $self->request->address,
        time => scalar Time::HiRes::gettimeofday,
    });
    $self->write({ success => 1 });
}

__PACKAGE__->meta->make_immutable;

1;