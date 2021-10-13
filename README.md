# save-attachement-in-mail
Command line tools to save attachement in mails on pop3 server to local drive

# Require
External used librairies :
- Email::MIME
- Email::MIME::Attachment::Stripper
- Getopt::Long
- File::Path
- DateTime::Format::Natural

# Options
```
--pop3=host		Host of the POP3 serveur (require)
--port=port 	Port of the POP3 serveur (default is 110)
--ssl 			If the POP3 serverr require SSL connexion
--user=user		User for the POP3 account (require)
--password=pass	Password for the POP3 account (require)

--directory=dir	Directory where to save the attachements (require)
				You can specify multi directories using this options many times.
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
	--filter=\.pdf$                     Filename end with pdf
	--filter=\.(pdf|odt|docx?|txt)$     Filename end with pdf, odf, doc, docx, txt
	--filter=^Invitation\b.*\.jpe?g$    Filename start with "Invitation" and end with .jpeg or .jpg
	Complete documentation here https://perldoc.perl.org/perlre.html

--no-delete		Don't delete emails
--no-save		Don't save the attachements files
--quiet 		Don't display anything
--debug 		Active Net::POP3 debug messages
--help			Display this message
```

# Examples
```
perl save-attachement-in-mail.pl --host=pop3.host.net --user=john.smith --password=xxx "--filter=\.pdf|odt|ods|csv|xlsx?$" --directory=attachement/{fromName}/{date=%Y/%m/%d}/
```