#!/usr/bin/perl

use DBI;
use Image::Size;

# utilities to escape for URIs and for HTML
use CGI qw(escape escapeHTML);

# don't execute from the web
if( $ENV{'DOCUMENT_ROOT'} ){
	print "Content-type:text/plain\n\nGo away.";
	exit();
}

# set the current directory to the directory containing the script
# so our relative path references (images, etc) work regardless of
# where the script was invoked. (the primary reason for this is that
# we intend to run it periodically via crontab.) $0 gives us the path
# to the script.

# grab everything up to the last slash.
@pathToScript = $0 =~ /.*\//gi;

# change to that directory.
chdir $pathToScript[0];


my $dsn = 'DBI:mysql:themaxx:mysql.rocketsheep.com';
my $db_user_name = 'db_themaxx';
my $db_password = 'db_password_goes_here';
$dbh = DBI->connect($dsn, $db_user_name, $db_password);

if (! $dbh) {										#<-- Make sure we got a valid connection
	print "No database handle\n";
	exit(0);
}

my $sql = "CREATE temporary TABLE recent_uploads (
			id int(11) NOT NULL,
			userid int(11) NOT NULL default '0',
			filename varchar(255) NOT NULL default '',
			timestamp timestamp(19) NOT NULL,
			nsfw tinyint(4) default NULL,
			tmbo tinyint(4) NOT NULL default '0',
			type enum('image','topic') NOT NULL default 'image',
		PRIMARY KEY  (id),
		KEY timestamp (timestamp),
		KEY filename (filename),
		KEY userid (userid),
		KEY type (type)
);";

	my $statement = $dbh->prepare( $sql );
	$statement->execute();


$sql = "insert into recent_uploads( id, filename, userid, timestamp, nsfw, tmbo, type )
			select id, filename, userid, timestamp, nsfw, tmbo, type
				from offensive_uploads where type='image' AND status='normal'
			order by timestamp desc limit 100;";

	$statement = $dbh->prepare( $sql );
	$statement->execute();


$sql = "SELECT up.id, up.userid, up.filename, up.timestamp, up.nsfw, up.tmbo, 
		users.username, counts.comments, counts.good, counts.bad
			FROM (recent_uploads up, users)
			LEFT JOIN offensive_count_cache counts ON (up.id = counts.threadid)
			WHERE up.userid = users.userid
			AND type='image'
			AND users.account_status != 'locked'
			ORDER BY up.timestamp DESC";

	$statement = $dbh->prepare( $sql );
	$statement->execute();

	$THUMBS_PER_ROW = 4;
	
	open( LIST_FILE, ">indexList.txt" ) or die("couldn't create indexList.txt file.\n");
	open( THUMB_FILE, ">indexListThumbnails.txt" ) or die("couldn't create indexListThumbnails.txt file.\n");
	print LIST_FILE qq ^<table width="100%">\n^;
	print THUMB_FILE qq ^<table width="100%" class="thumbnails">\n^;

	my $css = "evenfile";
	my $output = 0;
	while( (my( $id, $userid, $filename, $timestamp, $nsfw, $tmbo, $username, $comments, $good, $bad ) = $statement->fetchrow_array()) && $output < 101) {

		$css = ($css eq "odd_row") ? "even_row" : "odd_row";
		$nsfwMarker = $nsfw == 1 ? "[nsfw]" : "";

		# HTML escape 
		my $newFilename = escapeHTML(substr( $nsfwMarker . " " . $filename, 0, 80));
		$comments = $comments == null ? 0 : $comments;
		$good = $good == null ? 0 : $good;
		$bad = $bad == null ? 0 : $bad;
		
		print LIST_FILE qq ^
		<tr class="$css">
			<td class="$css"><div class="clipper"><a href="pages/pic.php?id=$id" class="$css" title="uploaded by $username">$newFilename</a></div></td>
			<td class="$css" style="text-align:right;white-space:nowrap"><a href="./?c=comments&fileid=$id" class="$css">$comments comments</a> (+$good -$bad)</td>
		</tr>^;

		if( $output % $THUMBS_PER_ROW == 0 ) {
			print THUMB_FILE "<tr>";
		}
		emitThumbnailRow( $id, $filename, $comments, $good, $bad, $nsfw );
		if( $output % $THUMBS_PER_ROW == $THUMBS_PER_ROW - 1  ) {
			print THUMB_FILE "</tr>";
		}

		$output++;


	}

	print LIST_FILE qq ^</table>\n^;
	close( LIST_FILE );
	
	if( $output % $THUMBS_PER_ROW != $THUMBS_PER_ROW - 1 ) {
		print THUMB_FILE "</tr>";
	}

	print THUMB_FILE qq ^</table>\n^;
	close( THUMB_FILE );	


sub emitThumbnailRow {
	my( $id, $filename, $comments, $good, $bad, $nsfw ) = @_;	
	my $css = $nsfw == 1 ? "nsfw" : "";

	my ($width, $height) = imgsize("images/thumbs/th-$filename");

	# URI escape filename
	$filename = escape($filename);

	print THUMB_FILE qq^ 
	<td>
		<a href="pages/pic.php?id=$id"><span class="$css"><img src="images/thumbs/th-$filename" width="$width" height="$height" border="0"/></span></a><br/>
		<a href="?c=comments&fileid=$id">$comments comments (+$good -$bad)</a>
	</td>^;

}
