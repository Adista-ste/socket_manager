#!/usr/bin/env perl
use IO::Socket;
use IO::CaptureOutput qw/capture_exec/;
use Data::Dumper qw(Dumper);
use strict;
use warnings;


my %config = ( 
		"2" => {
			'name' => 'http',
			'desc' => 'check and restart httpd',
			'commands' => [	'service httpd configtest',
					'service httpd restart'
				]
		},
		"1" => {
			'name' => 'http',
			'desc' => 'check httpd',
			'commands' => [	'service httpd configtest',
				]
		},
		"3" => {
			'name' => 'http',
			'desc' => 'status httpd',
			'commands' => [	'service httpd status',
				]
		},
		"5" => { 
			'name' => 'php-fpm',
			'desc' => 'check and restart PHP FastCGI',
			'commands' => [	'service php-fpm configtest',
					'service php-fpm restart',
				]
		},
		"4" => { 
			'name' => 'php-fpm',
			'desc' => 'check PHP FastCGI',
			'commands' => [	'service php-fpm configtest',
				]
		},
		"6" => { 
			'name' => 'php-fpm',
			'desc' => 'status PHP FastCGI',
			'commands' => [	'service php-fpm status',
				]
		},
		"0" => { 'name' => 'end',
			 'desc' => 'end connection',
			 'commands' => [ 'sleep 5' ]
		}
);

sub printmenu {
	my $conf = shift;
	my @answers;
	push(@answers,"Menu :\n");
	foreach my $key ( sort keys %{$conf} ) {
		push(@answers, sprintf("%s - %s - %s \n", $key, $conf->{$key}{'name'}, $conf->{$key}{'desc'}) );
	}
	return @answers;
}

sub answer {
	my $choice = shift;
	my $conf = shift;
	 
	my @answers;
	my @commands; 
	my ($stdout, $stderr, $success, $exit_code);

	# Nettoyeeeer, astiqueeeer, balayeeeer ça s'rat toujou pimpan
	$choice =~ s/\W//g;

	return (0, "Bad choice !\n") if not exists $conf->{$choice};

	push(@commands, @{$conf->{$choice}{'commands'}});
	foreach my $com ( @commands ) {
		printf "commande execute : %s\n",$com;
		($stdout, $stderr, $success, $exit_code) = capture_exec( $com );
		$stdout =~ s/\W\s//g;
		$stderr =~ s/\W\s//g;
		push(@answers, $stdout, $stderr );
		printf "\n  commande results :\n--- stdout ---\n %s \n--------------\n--- stderr ---\n %s \n--------------\n    success %s\n    exit %s\n\n",$stdout, $stderr, $success, $exit_code;
		
		last if ($exit_code != "0"); 
	}
	return ($exit_code, @answers);
}
	


#####################################
# Server Script: 
# Copyright 2003 (c) Philip Yuson 
# this program is distributed according to 
# the terms of the Perl license
# Use at your own risk
#####################################
my $local = IO::Socket::INET->new(
                Proto     => 'tcp',             # protocol
                LocalAddr => 'localhost:8081',  
		# Host and port to listen to
                # Change the port if 8081 is being used
                Reuse     => 1
                ) or die "$!";

$local->listen();       # listen

$local->autoflush(1);   # To send response immediately

print "At your service. Waiting...\n";

#my $addr;       # Client handle

while (my $addr = $local->accept() ) {     # receive a request
	next if my $pid = fork;
	close($local);

        printf   "Connected from:  %s Port: %s\n", $addr->peerhost(), $addr->peerport();  

	print $addr $_ foreach printmenu(\%config);
	print $addr "\nyour choice : ";
	
       # my $result;             # variable for Result
        while (<$addr>) {       # Read all messages from client 


                last if m/^0/gi;      # if message is 'end' 
                                        # then exit loop
                print "Received: $_";   # Print received message
                print $addr "Received: $_";   # Print received message
	
		chomp($_);	
		my ($code, @answers ) = answer($_, \%config);         # Send received message back 
		print $addr $_ foreach @answers;
		print $addr "\nsomething go wrong, please contact admin\n" if ( $code != 0 );
	
		print $addr "\nyour choice : ";
        }
        chomp;                  # Remove the 
        if (m/^0/gi) {        # You need this. Otherwise if 
                                # the client terminates abruptly
                                # The server will encounter an 
                                # error when it sends the result back
                                # and terminate
                #print "Result: $send\n";        # Display sent message
        }
        printf "Closed connection from:  %s Port: %s\n", $addr->peerhost(), $addr->peerport();  
        close $addr;    # close client
        print "At your service. Waiting...\n";  
# Wait again for next request
}
#print Dumper \%config;
#printf "\n\nVALEUR CHOICE : %s###\n\n",$choice;
#print Dumper \$conf;
#print Dumper \$conf->{$choice};
#print Dumper \$conf->{'2'};
#print Dumper \$conf->{$choice};
#print Dumper \$conf->{$choice};
#print Dumper \%conf{$choice};
