package Bobby::Handler::Root;
use Moose;
use namespace::autoclean;

extends 'Bobby::BaseHandler';

sub get {
    my $self = shift;

    $self->response->redirect('/dashboard/');
}

__PACKAGE__->meta->make_immutable;

1;
