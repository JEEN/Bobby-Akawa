{
    static_path   => 'static',
    template_path => 'templates',
    OAuth => {
        providers => {
            Foursquare => {
                client_id     => $ENV{'4SQ_CLIENT_ID'}     || '0Z5WKEHGKJYNM0Z1VRXNG3ZC1T02DLTH1JLK4SXCU5V4RFWS',
                client_secret => $ENV{'4SQ_CLIENT_SECRET'} || 'I1HN2BJ2EHYZT2HZD2GUYQVTQN55GURLJS1RHLYL1OBII1HC',
            },
        },
    },
};
