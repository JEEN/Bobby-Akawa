package Bobby::Handler::Dashboard;
use Moose;
use namespace::autoclean;

extends 'Bobby::BaseHandler';

sub get {
    my ($self, $channel) = @_;

    $self->render('dashboard.html');
}

__PACKAGE__->meta->make_immutable;

1;