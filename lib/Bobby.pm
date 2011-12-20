package Bobby;
use Moose;
use namespace::autoclean;
use Plack::Builder;
extends 'Tatsumaki::Application';

has config => (
    is => 'ro',
    isa => 'HashRef',
    default => sub { {} },
);

sub BUILD {
    my $self = shift;

    $self->template_path( $self->config->{template_path} || 'templates' );
    $self->static_path( $self->config->{static_path} || 'static' );
    return $self;
}

sub BUILDARGS {
    my $class = shift;

    my $dispatch_rules;

    if (ref $_[0] eq 'ARRAY') {
        $dispatch_rules = shift @_;
    } else {
        $dispatch_rules = [];
    }

    push @{ $dispatch_rules }, (
        '/dashboard/poll'             => 'Bobby::Handler::Dashboard::Poll',
        '/dashboard/mxhrpoll'         => 'Bobby::Handler::Dashboard::MultipartPoll',
        '/dashboard/post'             => 'Bobby::Handler::Dashboard::Post',
        '/dashboard/update'           => 'Bobby::Handler::Dashboard::Update',
        '/dashboard/venue/(\w+)'      => 'Bobby::Handler::DashboardVenue',
        '/dashboard/'                 => 'Bobby::Handler::Dashboard',
        '/'                           => 'Bobby::Handler::Root',
    );

    map { Plack::Util::load_class($_) } grep { /^Bobby/ } @{ $dispatch_rules };
    unshift @_, $dispatch_rules;
 
    return $class->SUPER::BUILDARGS(@_);
}

sub to_psgi {
    my $self = shift;

    my $app = $self->psgi_app;
    $app = builder {
        mount '/oauth' => builder {
            enable 'Session';
            enable 'OAuth',
                on_success => sub { 
                    my ($mw, $token) = @_;
                    # ...
                },
                on_error   => sub { Tatsumaki::Error::HTTP->throw(500); },
                providers  => {
                	'Foursquare' => {
                		client_id     => $ENV{'4SQ_CLIENT_ID'} || '0Z5WKEHGKJYNM0Z1VRXNG3ZC1T02DLTH1JLK4SXCU5V4RFWS',
                		client_secret => $ENV{'4SQ_CLIENT_SECRET'} || 'I1HN2BJ2EHYZT2HZD2GUYQVTQN55GURLJS1RHLYL1OBII1HC',
                	},
                };
        };
        mount '/' => $app;
    };
    $app;
}

__PACKAGE__->meta->make_immutable;

1;
