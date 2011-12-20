package Bobby::Handler::Dashboard::Update;
use Moose;
use namespace::autoclean;
use JSON::XS;
use Tatsumaki::HTTPClient;
extends 'Bobby::BaseHandler';

__PACKAGE__->asynchronous(1);

sub get {
    my ($self, $oauth_token) = @_;

    return $self->write({ auth_required => 1 }) unless $self->oauth_token("4sq");
    my $client = Tatsumaki::HTTPClient->new;
    my $offset = $self->session("offset") || 0;
    $self->session("offset", $offset);
    my $url = sprintf 'https://api.foursquare.com/v2/users/self/checkins?oauth_token=%s&limit=100&offset=%d', $self->oauth_token("4sq"), $self->session("offset");
    $client->get($url, $self->async_cb(sub { $self->on_response(@_) } ));
}

sub on_response {
    my ($self, $res) = @_;

    if ($res->is_error) {
        Tatsumaki::Error::HTTP->throw(500);
    }

    my $data = JSON::XS::decode_json($res->content);

    my $mq = Tatsumaki::MessageQueue->instance(1);

    my $count = 0;
    for my $item (@{ $data->{response}->{checkins}->{items} }) {
        my @people = ();
        @people =  map { $_  } $item->{shout} =~ /(\@[^ ]+)/g if $item->{shout};

        my $v = {
            id   => $item->{venue}->{id},
            name => $item->{venue}->{name},
            lat        => $item->{venue}->{location}->{lat},
            lng        => $item->{venue}->{location}->{lng},
            icon       => $item->{venue}->{categories} ? $item->{venue}->{categories}->[0]->{icon} : '',
            people     => join(" ", @people),
            created_at => $item->{createdAt},
        };

        $mq->publish({
            type => "message", id => $v->{id}, name => Encode::decode_utf8($v->{name}),
            lat => $v->{lat}, lng => $v->{lng}, icon => $v->{icon}, people => $v->{people},
            created_at => $v->{created_at}, address => $self->request->address,
            time => scalar Time::HiRes::gettimeofday,
        });

        $count++;
    }

    if ($count == 100) {
        my $offset = $self->session("offset");
        $self->session("offset", $offset + 100);
        $self->get();
    } else {
        $self->write({ success => 1 });
        $self->finish;
    }
}

__PACKAGE__->meta->make_immutable;

1;