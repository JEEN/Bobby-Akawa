package Plack::Middleware::OAuth::UserInfo::Foursquare;
use strict;
use warnings;
use parent qw(Plack::Middleware::OAuth::UserInfo);
use LWP::UserAgent;
use JSON;

sub create_handle {
    my $self = shift;

}

sub query {
    my $self = shift;

    my $uri = URI->new('https://api.foursquare.com/v2/users/self');
    $uri->query_form( oauth_token => $self->token->access_token );
    my $res = LWP::UserAgent->new->get($uri);
    my $body = $res->decoded_content;
    return unless $body;

    my $obj = decode_json($body) || {};
    return $obj->{response}->{user};
}

1;
