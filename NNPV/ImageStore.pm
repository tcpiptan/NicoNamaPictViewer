package NNPV::ImageStore;

# ＵＴＦ－８

use NNPV::CommonSense;

use base qw(Class::Singleton Class::Accessor::Fast);
__PACKAGE__->mk_accessors( qw(store index count max init add delete get prev next first last) );

sub count { scalar @{ shift->store } }
sub max   { shift->count - 1 }

sub init {
    my $self = shift;
    
    $self->store([]);
    $self->index(-1);
    $self->count;
}

sub add {
    my $self = shift;
    my $data = shift;
    
    push @{ $self->store }, $data;
    $self->count;
}

sub delete {
    my $self = shift;
    
    return undef unless $self->count > 0;
    
    # 1個抜いて
    splice @{ $self->store }, $self->index, 1;
    
    # 抜いたので、indexが大きければ調整
    my $index = $self->max;
    if ($self->index > $index) {
        $self->index($index);
    }
    $self->count;
}

sub delete_all { shift->init } # returns $self->count

sub get {
    my $self = shift;
    
    return undef unless $self->count > 0;
    
    if (@_) {
        my $index = shift;
        return undef if $index > $self->max;
        $self->index($index);
    }
    
    @{ $self->store }[ $self->index ];
}

sub prev {
    my $self = shift;
    
    return undef unless $self->count > 0;
    $self->get($self->_dec);
}

sub next {
    my $self = shift;
    
    return undef unless $self->count > 0;
    $self->get($self->_inc);
}

sub first {
    my $self = shift;
    
    return undef unless $self->count > 0;
    $self->get(0);
}

sub last {
    my $self = shift;
    
    return undef unless $self->count > 0;
    $self->get($self->max);
}

sub _dec {
    my $self = shift;
    my $index = $self->index;
    if ($index > 0) {
        $index--;
    }
    else {
        $index = $self->max;
    }
    $index;
}

sub _inc {
    my $self = shift;
    my $index = $self->index;
    if ($index < $self->max) {
        $index++;
    }
    else {
        $index = 0;
    }
    $index;
}

1;
__END__

=encoding utf8

=head1 AUTHOR

Copyright 2010 tcpiptan, <ptan@ptan.info> All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
