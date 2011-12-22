{
    static_path   => 'static',
    template_path => 'templates',
    OAuth => {
        providers => {
            Foursquare => {
                version          => 2,
                authorize_url    => 'https://foursquare.com/oauth2/authenticate',
                access_token_url => 'https://foursquare.com/oauth2/access_token',
                response_type    => 'code',
                grant_type       => 'authorization_code',
                client_id     => $ENV{'4SQ_CLIENT_ID'}     || '0Z5WKEHGKJYNM0Z1VRXNG3ZC1T02DLTH1JLK4SXCU5V4RFWS',
                client_secret => $ENV{'4SQ_CLIENT_SECRET'} || 'I1HN2BJ2EHYZT2HZD2GUYQVTQN55GURLJS1RHLYL1OBII1HC',
            },
        },
    },
};
