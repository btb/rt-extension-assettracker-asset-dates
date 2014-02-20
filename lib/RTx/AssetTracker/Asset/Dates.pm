package RTx::AssetTracker::Asset::Dates;
use strict;
use warnings;
use version; our $VERSION = version->declare("0.9.0");



{

package RTx::AssetTracker::Asset;

no warnings qw(redefine);

my $Orig__CoreAccessible = \&_CoreAccessible;
my %orig_fields = %{$Orig__CoreAccessible->()};
my %new_fields = (
        Told =>
		{read => 1, write => 1, sql_type => 11, length => 0,  is_blob => 0,  is_numeric => 0,  type => 'datetime', default => ''},
        Starts => 
                {read => 1, write => 1, sql_type => 11, length => 0,  is_blob => 0,  is_numeric => 0,  type => 'datetime', default => ''},
        Started =>
		{read => 1, write => 1, sql_type => 11, length => 0,  is_blob => 0,  is_numeric => 0,  type => 'datetime', default => ''},
        Due =>
		{read => 1, write => 1, sql_type => 11, length => 0,  is_blob => 0,  is_numeric => 0,  type => 'datetime', default => ''},
        Resolved =>
		{read => 1, write => 1, sql_type => 11, length => 0,  is_blob => 0,  is_numeric => 0,  type => 'datetime', default => ''},
);

my %all_fields = (%orig_fields, %new_fields);

*_CoreAccessible = sub {
    \%all_fields;
};



=head2 DueObj

  Returns an RT::Date object containing this asset's due date

=cut

sub DueObj {
    my $self = shift;

    my $time = RT::Date->new( $self->CurrentUser );

    # -1 is RT::Date slang for never
    if ( my $due = $self->Due ) {
        $time->Set( Format => 'sql', Value => $due );
    }
    else {
        $time->Set( Format => 'unix', Value => -1 );
    }

    return $time;
}



=head2 DueAsString

Returns this asset's due date as a human readable string

=cut

sub DueAsString {
    my $self = shift;
    return $self->DueObj->AsString();
}



=head2 ResolvedObj

  Returns an RT::Date object of this asset's 'resolved' time.

=cut

sub ResolvedObj {
    my $self = shift;

    my $time = RT::Date->new( $self->CurrentUser );
    $time->Set( Format => 'sql', Value => $self->Resolved );
    return $time;
}


=head2 SetStarted

Takes a date in ISO format or undef
Returns a transaction id and a message
The client calls "Start" to note that the asset was activated on the date in $date.
A null date means "now"

=cut

sub SetStarted {
    my $self = shift;
    my $time = shift || 0;

    unless ( $self->CurrentUserHasRight('ModifyAsset') ) {
        return ( 0, $self->loc("Permission Denied") );
    }

    #We create a date object to catch date weirdness
    my $time_obj = RT::Date->new( $self->CurrentUser() );
    if ( $time ) {
        $time_obj->Set( Format => 'ISO', Value => $time );
    }
    else {
        $time_obj->SetToNow();
    }

    # We need $AssetAsSystem, in case the current user doesn't have
    # ShowAsset
    my $AssetAsSystem = RTx::AssetTracker::Asset->new(RT->SystemUser);
    $AssetAsSystem->Load( $self->Id );
    # activate this asset
    # TODO: do we really want to force this as policy? it should be a scrip
    my $next = $AssetAsSystem->FirstActiveStatus;

    $self->SetStatus( $next ) if defined $next;

    return ( $self->_Set( Field => 'Started', Value => $time_obj->ISO ) );

}



=head2 StartedObj

  Returns an RT::Date object which contains this asset's 
'Started' time.

=cut

sub StartedObj {
    my $self = shift;

    my $time = RT::Date->new( $self->CurrentUser );
    $time->Set( Format => 'sql', Value => $self->Started );
    return $time;
}



=head2 StartsObj

  Returns an RT::Date object which contains this asset's 
'Starts' time.

=cut

sub StartsObj {
    my $self = shift;

    my $time = RT::Date->new( $self->CurrentUser );
    $time->Set( Format => 'sql', Value => $self->Starts );
    return $time;
}



=head2 ToldObj

  Returns an RT::Date object which contains this asset's 
'Told' time.

=cut

sub ToldObj {
    my $self = shift;

    my $time = RT::Date->new( $self->CurrentUser );
    $time->Set( Format => 'sql', Value => $self->Told );
    return $time;
}



=head2 ToldAsString

A convenience method that returns ToldObj->AsString

TODO: This should be deprecated

=cut

sub ToldAsString {
    my $self = shift;
    if ( $self->Told ) {
        return $self->ToldObj->AsString();
    }
    else {
        return ("Never");
    }
}


=head2 SetTold ISO  [TIMETAKEN]

Updates the told and records a transaction

=cut

sub SetTold {
    my $self = shift;
    my $told;
    $told = shift if (@_);
    my $timetaken = shift || 0;

    unless ( $self->CurrentUserHasRight('ModifyAsset') ) {
        return ( 0, $self->loc("Permission Denied") );
    }

    my $datetold = RT::Date->new( $self->CurrentUser );
    if ($told) {
        $datetold->Set( Format => 'iso',
                        Value  => $told );
    }
    else {
        $datetold->SetToNow();
    }

    return ( $self->_Set( Field           => 'Told',
                          Value           => $datetold->ISO,
                          TimeTaken       => $timetaken,
                          TransactionType => 'Told' ) );
}

=head2 _SetTold

Updates the told without a transaction or acl check. Useful when we're sending replies.

=cut

sub _SetTold {
    my $self = shift;

    my $now = RT::Date->new( $self->CurrentUser );
    $now->SetToNow();

    #use __Set to get no ACLs ;)
    return ( $self->__Set( Field => 'Told',
                           Value => $now->ISO ) );
}


}



{

package RTx::AssetTracker::Assets;

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


}



{

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


}


1;
