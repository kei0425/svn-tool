#!/usr/bin/perl
use strict;
use warnings;

use Tk;
use Tk::Table;
use Tk::Dialog;

my $top = MainWindow->new();
my $up   = $top->Frame();
my $down = $top->Frame();
my $buttonRefresh
    = $up->Button( -text => 'refresh', -command => \&get_status );
my $buttonRevert
    = $up->Button( -text => 'revert' , -command => \&revert );
my $buttonAdd
    = $up->Button( -text => 'add'    , -command => \&add );
my $buttonCommit
    = $up->Button( -text => 'commit' , -command => \&commit );
my $buttonExit
    = $up->Button( -text => 'EXIT'   , -command => \&exit );

# status取得
my @list;
get_status();

my $lis = $down->Scrolled('Listbox',
                          -background       => 'white',
                          -scrollbars       => 'osoe',
                          -selectforeground => 'brown',
                          -selectbackground => 'cyan',
                          -selectmode       => 'extended',
                          -listvariable     => \@list
                      );

my $diff_data = [];


=comment
テーブル
my $table = $down->Table(
    -columns    => 2,
    -rows       => 10,
    -fixedrows  => 1,
    -scrollbars => 'oe',
    -relief     => 'raised'
);

$table->put(0, 1, $table->Label(
    -text   => 'status',
    -relief => 'raised'
));

$table->put(0, 2, $table->Label(
    -text   => 'filename',
    -relief => 'raised'
));

foreach my $index (0..$#{@$diff_data}) {
    $table->put($index + 1, 1, $diff_data->[$index]{status});
    $table->put($index + 1, 2, $diff_data->[$index]{file});
}
$table->pack(-fill=>'both',
           -expand => 'yes');

=cut

$buttonRefresh->pack(-side => 'left');
$buttonRevert ->pack(-side => 'left');
$buttonAdd    ->pack(-side => 'left');
$buttonCommit ->pack(-side => 'left');
$buttonExit   ->pack(-side => 'left');
$up->pack();
$lis->pack(-fill=>'both',
           -expand => 'yes');
$down->pack(-fill=>'both',
           -expand => 'yes');

$lis->bind( '<Double-Button-1>', \&diff_exec);
MainLoop();

sub get_selectlist {
    map {
        my ($status, $file) = $list[$_] =~ /^([^ ]+) +(.+)/;
        {
            index  => $_,
            status => $status,
            file   => $file
        };
    }
    $lis->curselection();
}

sub get_status {
    @list = map {chomp;$_} `svn status`;
}

sub diff_exec {
    foreach my $diff (get_selectlist()) {
        my $command = 'tkdiff '
            . $diff->{file};
        system "$command &";
    }
}

sub svn_command {
    my ($command, $status_check) = @_;

    my @file_list = grep {&$status_check($_);} get_selectlist();

    if (!@file_list) {
        $top->Dialog( -title   => 'About',
                      -bitmap  => 'info',
                      -text    => "No $command file!",
                      -buttons => ['OK'],
                  )->Show();
        return;
    }

    my $exec_command = "svn $command "
        . join(' ',
               map {
                   $_->{file}
               } @file_list
           );
    print "$exec_command\n";
    my $result =
        $top->Dialog( -title   => 'About',
                      -bitmap  => 'info',
                      -text    => "Do you exec command?",
                      -buttons => ['Yes', 'No'],
                      -default_button
                               => 'Yes'
                  )->Show();

    return if $result ne 'Yes';
    # 実行
    system "$exec_command";

    # ちょっとまつ
    sleep(1);

    # ステータス取得しなおし
    get_status();
}

sub revert {
    svn_command('revert',
                sub {
                    my ($file) = @_;
                    $file->{status} ne '?'
                });
}

sub add {
    svn_command('add',
                sub {
                    my ($file) = @_;
                    $file->{status} eq '?'
                });
}

sub commit {
    svn_command('commit',
                sub {
                    my ($file) = @_;
                    $file->{status} ne '?'
                });
}

