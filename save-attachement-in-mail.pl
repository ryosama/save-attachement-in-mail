#!/usr/bin/perl

# recupere les PJ dans les mails destiné à la boite AR et les enregistre dans un répertoire bien précis

$| = 1;
use strict;
use Email::MIME;
use Email::MIME::Attachment::Stripper;
use Net::POP3;
use Getopt::Long;
use File::Path;
use POSIX qw(strftime);
use DateTime::Format::Natural;

# options management
my ($directory, $pop3, $user, $port, $ssl, $password, $filter, $nodelete, $nosave, $quiet, $debug, $help);
GetOptions(
	'directory=s'=>\$directory,
	'pop3|host=s'=>\$pop3,
	'port=i'=>\$port,
	'ssl!'=>\$ssl,
	'user=s'=>\$user,
	'password=s'=>\$password,
	'filter=s'=>\$filter,

	'no-delete|nodelete!'=>\$nodelete,
	'no-save|nosave!'=>\$nosave,
	'quiet!'=>\$quiet,
	'debug!'=>\$debug ,
	'help|usage!'=>\$help) or die ;

die <<EOT if ($help);
Parameters :
--pop3=host		Host of the POP3 serveur (require)
--port=port 	Port of the POP3 serveur (default is 110)
--ssl 			If the POP3 serverr require SSL connexion
--user=user		User for the POP3 account (require)
--password=pass	Password for the POP3 account (require)

--directory=dir	Directory where to save the attachements (require)
	Example :
	--directory=my_attachements
	--directory=attachements/{fromName}
	--directory=attachements/{fromEmail}/{date=%Y/%m/%d}/{subject}/{date=%H}
	Possible values are :
	{fromName}                 Sender name
	{fromEmail}                Sender email
	{subject}                  Subject of the mail
	{filename}                 Filename of the attachement
	{date=strftime expression} For syntax reads : https://metacpan.org/pod/POSIX::strftime::GNU

--filter=filter Perl regex filter for the attachement filename (ignore case)
	Example :
	--filter=\.pdf\$                     Filename end with pdf
	--filter=\.(pdf|odt|docx?|txt)\$     Filename end with pdf, odf, doc, docx, txt
	--filter=^Invitation\b.*\.jpe?g\$    Filename start with "Invitation" and end with .jpeg or .jpg
	Complete documentation here https://perldoc.perl.org/perlre.html

--no-delete		Don't delete emails
--no-save		Don't save the attachements files
--quiet 		Don't display anything
--debug 		Active Net::POP3 debug messages
--help			Display this message
EOT

# required options
die("Option --directory is required") 	unless length($directory)>0;
die("Option --pop3 is required") 		unless length($pop3)>0;
die("Option --user is required") 		unless length($user)>0;
die("Option --password is required") 	unless length($password)>0;

$port = 110 unless length($port)>0;
$directory = $directory.'/' ; # add trailing slash to the direcory

printf("%s START\n", get_time()) unless $quiet;

my $pop = Net::POP3->new($pop3, Port=>$port, SSL=>$ssl, Timeout => 60, Debug => $debug);

if ($pop->login($user, $password) > 0) {
	my $msgnums = $pop->list; # hashref of msgnum => size
	foreach my $msgnum (keys %$msgnums) {
		my $msg = $pop->get($msgnum);
		
		my $stripper 	= Email::MIME::Attachment::Stripper->new( Email::MIME->new( join('',@$msg) ) );
		my $msg_only 	= $stripper->message;
		my @attachments = $stripper->attachments;

		my @tmp = @{$msg_only->{'header'}->{'headers'}};
		my %tmp = @tmp;

		# who send this mail ?
		my $from 		= $tmp{'From'}->[0];
		printf("%s Found from %s\n", get_time(), $from) unless $quiet;

		$from =~ m/^(.*?)\s*<(.+@.+\..+)>$/i;
		my $fromName 	= $1;
		my $fromEmail 	= $2;

		my $subject = $tmp{'Subject'}->[0];
		my $parser 	= DateTime::Format::Natural->new;
		my $dt;
		if ($tmp{'Date'}->[0]) {
			$dt = $parser->parse_datetime($tmp{'Date'}->[0]);
		}

		# foreach attachement
		my ($keep_attach, $skip_attach) = (0,0);
		foreach my $attachment (@attachments) {
			if ($attachment->{'filename'} =~ /$filter/i) { # attachement match the filter
				printf("%s Found attachement '%s' (%0.1f Ko)\n",
						get_time(),	$attachment->{'filename'}, length($attachment->{'payload'}/1024)) unless $quiet;
				my $filename = $attachment->{'filename'};

				unless ($nosave) {
					my $final_directory = $directory;
					$final_directory =~ s/{subject}/$subject/gi;
					$final_directory =~ s/{fromName}/$fromName/gi;
					$final_directory =~ s/{fromEmail}/$fromEmail/gi;
					$final_directory =~ s/{filename}/$filename/gi;

					if ($dt) {
						$final_directory =~ s/{date=(.*?)}/$dt->strftime($1)/gie;
					}					

					my $final_filename 	= $final_directory.$attachment->{'filename'};
					mkpath($final_directory);
					open(F,"+>$final_filename") or warn "Unable to create file '$final_filename' ($!)";
					binmode(F);
					print F $attachment->{'payload'};
					close F;
					printf("%s File save to %s\n", get_time(), $final_filename) unless $quiet;
				}

				$keep_attach++;
			} else {
				$skip_attach++;
			}
		}
		printf("%s Found %d attachements, skip %d files\n", get_time(), $keep_attach, $skip_attach) unless $quiet;

		unless ($nodelete) {
			printf("%s Delete message %d\n", get_time(), $msgnum)  unless $quiet;
			$pop->delete($msgnum);
		}

		printf("\n") unless $quiet;
	} # for each message
} # if login success
$pop->quit;

printf("%s END\n\n", get_time())  unless $quiet;



##################################

sub get_time {
	return strftime("[%Y-%m-%d %H:%M:%S]", localtime);
}