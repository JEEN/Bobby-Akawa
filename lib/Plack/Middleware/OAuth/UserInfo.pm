package Plack::Middleware::OAuth::UserInfo;
use warnings;
use strict;
use Plack::Util::Accessor qw(token config);

sub new {
    my $class = shift;
    my %args = @_;
    bless \%args, $class;
}

# config: provider config hashref
# token:  access token object

sub create_inf {
    my ($self,$class) = @_;
    return $class->new( token => $self->token , config => $self->config );
}

sub ask {
    my ($self,$provider_name) = @_;
    my $info_class = Plack::Util::load_class( $provider_name );
    return $self->create_inf( $info_class )->query;
}

sub query { ... }

1;
