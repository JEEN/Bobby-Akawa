package Bobby::BaseHandler;
use Moose;
use namespace::autoclean;

extends 'Tatsumaki::Handler';

sub session {}
=pod
sub session {
    my ($self,$k,$v) = @_;

    !$k and !$v and return undef;

    my $session = Plack::Session->new($self->request->env);
    return $session->get($k) unless $v;
    $session->set($k, $v);
}

sub oauth_token {
    my ($self, $service) = @_;

    $self->session($service . "_token");
}
=cut
__PACKAGE__->meta->make_immutable;

1;
