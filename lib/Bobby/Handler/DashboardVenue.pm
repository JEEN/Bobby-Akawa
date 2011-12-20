package Bobby::Handler::DashboardVenue;
use Moose;
use namespace::autoclean;
use Furl;
use JSON::XS;
extends 'Bobby::BaseHandler';

sub get {
    my ($self, $venue_id) = @_;

    return $self->write({ auth_required => 1 }) unless $self->oauth_token("4sq");

    my $v = $self->request->parameters;
    my $furl = Furl->new->get((sprintf 'https://api.foursquare.com/v2/venues/%s?oauth_token=%s', $venue_id, $self->oauth_token("4sq")));
    my $content = decode_json($furl->content);

    my $venue = $content->{response}->{venue};
    my $r = {
        url           => $venue->{url},
        foursquareUrl => $venue->{shortUrl},
        checkinCount  => $venue->{stats}->{checkinsCount},
        usersCount    => $venue->{stats}->{usersCount},
        contact  => $venue->{contact}->{formattedPhone},
        beenHere => $venue->{beenHere}->{count},
        photos   => [ 
            map { @{ $_->{items} } } 
                grep { scalar @{ $_->{items} } > 0 } @{ $venue->{photos}->{groups} }
        ]
    };

    $self->write($r);
}

__PACKAGE__->meta->make_immutable;

1;