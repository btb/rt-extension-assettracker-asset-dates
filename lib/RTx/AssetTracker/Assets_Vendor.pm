
package RTx::AssetTracker::Assets;

use strict;
no warnings qw(redefine);


my $Orig_FIELDS = \&FIELDS;
my %orig_fields = %{$Orig_FIELDS->()};
my %new_fields = (
    Told             => [ 'DATE'            => 'Told', ], #loc_left_pair
    Starts           => [ 'DATE'            => 'Starts', ], #loc_left_pair
    Started          => [ 'DATE'            => 'Started', ], #loc_left_pair
    Due              => [ 'DATE'            => 'Due', ], #loc_left_pair
    Resolved         => [ 'DATE'            => 'Resolved', ], #loc_left_pair
);

my %all_fields = (%orig_fields, %new_fields);

*FIELDS = sub {
    \%all_fields;
};


=head2 _DateLimit

Handle date fields.  (Created, LastTold..)

Meta Data:
  1: type of link.  (Probably not necessary.)

=cut

sub _DateLimit {
    my ( $sb, $field, $op, $value, @rest ) = @_;

    die "Invalid Date Op: $op"
        unless $op =~ /^(=|>|<|>=|<=)$/;

    my $meta = $all_fields{$field};
    die "Incorrect Meta Data for $field"
        unless ( defined $meta->[1] );

    my $date = RT::Date->new( $sb->CurrentUser );
    $date->Set( Format => 'unknown', Value => $value );

    if ( $op eq "=" ) {

        # if we're specifying =, that means we want everything on a
        # particular single day.  in the database, we need to check for >
        # and < the edges of that day.

        $date->SetToMidnight( Timezone => 'server' );
        my $daystart = $date->ISO;
        $date->AddDay;
        my $dayend = $date->ISO;

        $sb->_OpenParen;

        $sb->_SQLLimit(
            FIELD    => $meta->[1],
            OPERATOR => ">=",
            VALUE    => $daystart,
            @rest,
        );

        $sb->_SQLLimit(
            FIELD    => $meta->[1],
            OPERATOR => "<",
            VALUE    => $dayend,
            @rest,
            ENTRYAGGREGATOR => 'AND',
        );

        $sb->_CloseParen;

    }
    else {
        $sb->_SQLLimit(
            FIELD    => $meta->[1],
            OPERATOR => $op,
            VALUE    => $date->ISO,
            @rest,
        );
    }
}


1;
