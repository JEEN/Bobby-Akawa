package Bobby::BaseHandler;
use Moose;
use namespace::autoclean;

extends 'Tatsumaki::Handler';

sub session {}
sub oauth_token {}

__PACKAGE__->meta->make_immutable;

1;
