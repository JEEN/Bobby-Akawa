package Plack::Middleware::OAuth::Foursquare;
use strict;
use warnings;

sub config {
    +{
        version          => 2,
        authorize_url    => 'https://foursquare.com/oauth2/authenticate',
        access_token_url => 'https://foursquare.com/oauth2/access_token',
        response_type    => 'code',
        grant_type       => 'authorization_code',
    };
}

1;
