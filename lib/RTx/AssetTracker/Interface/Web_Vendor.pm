
use strict;
no warnings qw(redefine);

package RTx::AssetTracker::Interface::Web;

package HTML::Mason::Commands;

use vars qw/$r $m %session/;




=head2 ProcessAssetDates ( AssetObj => $Asset, ARGSRef => \%ARGS );

Returns an array of results messages.

=cut

sub ProcessAssetDates {
    my %args = (
        AssetObj => undef,
        ARGSRef   => undef,
        @_
    );

    my $Asset  = $args{'AssetObj'};
    my $ARGSRef = $args{'ARGSRef'};

    my (@results);

    # Set date fields
    my @date_fields = qw(
        Told
        Resolved
        Starts
        Started
        Due
    );

    #Run through each field in this list. update the value if apropriate
    foreach my $field (@date_fields) {
        next unless exists $ARGSRef->{ $field . '_Date' };
        next if $ARGSRef->{ $field . '_Date' } eq '';

        my ( $code, $msg );

        my $DateObj = RT::Date->new( $session{'CurrentUser'} );
        $DateObj->Set(
            Format => 'unknown',
            Value  => $ARGSRef->{ $field . '_Date' }
        );

        my $obj = $field . "Obj";
        if (    ( defined $DateObj->Unix )
            and ( $DateObj->Unix != $Asset->$obj()->Unix() ) )
        {
            my $method = "Set$field";
            my ( $code, $msg ) = $Asset->$method( $DateObj->ISO );
            push @results, "$msg";
        }
    }

    # }}}
    return (@results);
}



1;
