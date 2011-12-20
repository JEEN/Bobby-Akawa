package Bobby;
use Moose;
use namespace::autoclean;
use Plack::Builder;
use Config::ZOMG;
extends 'Tatsumaki::Application';

has config => (
    is => 'ro',
    isa => 'HashRef',
    lazy_build => 1,
);

sub _build_config {
    my $self = shift;

    Config::ZOMG->new(
        name => __PACKAGE__,
    )->load;
}

sub BUILD {
    my $self = shift;

    $self->template_path( $self->config->{template_path} || 'templates' );
    $self->static_path( $self->config->{static_path} || 'static' );
    return $self;
}

sub BUILDARGS {
    my $class = shift;

    my $rules = [
        '/dashboard/poll'             => 'Bobby::Handler::Dashboard::Poll',
        '/dashboard/mxhrpoll'         => 'Bobby::Handler::Dashboard::MultipartPoll',
        '/dashboard/post'             => 'Bobby::Handler::Dashboard::Post',
        '/dashboard/update'           => 'Bobby::Handler::Dashboard::Update',
        '/dashboard/venue/(\w+)'      => 'Bobby::Handler::DashboardVenue',
        '/dashboard/'                 => 'Bobby::Handler::Dashboard',
        '/'                           => 'Bobby::Handler::Root',
    ];

    return $class->SUPER::BUILDARGS($rules);
}

sub to_psgi {
    my $self = shift;

    my $app = $self->psgi_app;
    $app = builder {
        enable 'Session';
        mount '/oauth' => builder {
            enable 'OAuth',
                on_success => sub { 
                    my ($mw, $token) = @_;

                    my $userinfo = Plack::Middleware::OAuth::UserInfo->new( config => $mw->config , token => $token );
                    if( $token->is_provider('Twitter')  || $token->is_provider('GitHub') || $token->is_provider('Foursquare') ) {
                      my $info = $userinfo->ask( $token->provider );
                      return $mw->to_yaml( $info );
                    }
                    return $mw->render( 'Error' );
                },
                on_error   => sub { Tatsumaki::Error::HTTP->throw(500); },
                providers  => $self->config->{OAuth}->{providers},
        };
        mount '/' => $app;
    };
    $app;
}

override dispatch => sub {
    my($self, $req) = @_;

    my $path = $req->path;
    for my $rule (@{$self->_rules}) {
        if ($path =~ $rule->{path}) {
            my $args = [ $1, $2, $3, $4, $5, $6, $7, $8, $9 ];
            my $handler = $rule->{handler};
            Class::MOP::load_class($handler);
            return $handler->new(@_, args => $args, request => $req, application => $self);
        }
    }

    return;
};

__PACKAGE__->meta->make_immutable;

1;
