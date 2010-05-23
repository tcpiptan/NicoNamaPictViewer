package NNPV::FileSystem::Unix;

# ＵＴＦ－８

use NNPV::CommonSense;
use File::Spec;
use File::MMagic;
use LWP::UserAgent;

sub new { bless {}, shift }

sub abspath {
    my $self = shift;
    my $file = shift;
    
    my $bound_file = undef;
    if (defined(&PerlApp::extract_bound_file)){
        $bound_file = PerlApp::extract_bound_file($file);
        $file = $bound_file if defined $bound_file;
    }
    elsif (defined $ENV{PAR_TEMP}) {
        my $test = File::Spec->catfile($ENV{PAR_TEMP}, 'inc', $file);
        $file = $test if -e $test;
    }
    if (!defined($bound_file)) {
        unless (File::Spec->file_name_is_absolute($file)) {
            $file = File::Spec->rel2abs($file);
        }
    }
    
    $file;
}

sub is_image {
    my $self = shift;
    my $file = shift;
    
    my $type = $self->mimetype($file);
    
    return ($type =~ m@^image/(bmp|gif|pjpeg|jpeg|x-png|png)$@);
}

sub mimetype {
    my $self = shift;
    my $file = shift;
    
    File::MMagic->new->checktype_filename($file);
}

sub get {
    my $self = shift;
    
    my $url = shift;
    my $method = shift || 'GET';
    
    my $ua = LWP::UserAgent->new;
    
    #タイムアウトを設定
    $ua->timeout(10);
    
    #ユーザエージェントを設定
    $ua->agent('Mozilla');
    
    #GET、PUT、POST、DELETE、HEADのいずれかを指定（httpsの場合はhttpsにするだけ）
    my $req = HTTP::Request->new($method => $url);
    
    #リクエスト結果を取得
    #requestメソッドではリダイレクトも自動的に処理するため、そうしたくない場合はsimple_requestメソッドを使用するとよい。
    my $res = $ua->request($req);
    
    #is_successの他にis_redirect、is_errorなどがある(is_redirectを判定する場合、 simple_requestメソッドを使用)
    if ($res->is_success) {
#        print "SUCCESS $method $url\n";
        my $type = $res->content_type;
        if ($type =~ m@^image/(bmp|gif|pjpeg|jpeg|x-png|png)$@) {
            my $file = File::Spec->catfile(File::Spec->tmpdir, $res->filename);
            open(my $fh, '>', $file);
            binmode $fh;
            print $fh $res->content;
            close $fh;
            return $file;
        }
    }
#    else {
#        print "FAILURE $method $url\n";
#        print $res->status_line . "\n";
#    }
    return undef;
}

sub _scan_files {
    my $self = shift;
    my $files = shift;
    my $results = shift;
    my $count_ref = shift;
    
    my $controller = NNPV::Controller->instance;
    
    for my $file (@$files) {
        if (-d -x $file->{path}) {
            opendir(my $dh, $file->{path}) or $controller->frame->status_bar->SetStatusText("ディレクトリが開けません");
            my @children = ();
            for my $f (readdir $dh) {
                next if $f =~ /^\.{1,2}$/;
                my $struct = {%$file};
                $struct->{path} = File::Spec->catfile($file->{path}, $f);
                push @children, $struct;
            }
            closedir $dh;
            @children = sort { $a->{path} <=> $b->{path} } @children;
            $self->_scan_files(\@children, $results, $count_ref);
        }
        elsif (-f -r -s $file->{path}) {
            if ($self->is_image($file->{path})) {
                ${$count_ref}++;
                my $num = sprintf("%5d", ${$count_ref});
                $controller->frame->status_bar->SetStatusText("画像ファイルを数えています... [${num}]");
                push @$results, $file;
            }
        }
    }
}

1;
__END__

=encoding utf8

=head1 AUTHOR

Copyright 2010 tcpiptan, <ptan@ptan.info> All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut