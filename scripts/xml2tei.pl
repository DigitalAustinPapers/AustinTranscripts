#!/usr/bin/perl
use File::Basename;

my $outDir = shift(@ARGV);;
sub getPersonKey
{
    my $name = shift(@_);
    return "TODO:Key values for people";
}

sub getLocationKey
{
    my $name = shift(@_);
    return "TODO:Key values for locations";
}

#Dates any text that describes a date
#Does the best it can to convert that to a set of standard date attributes.
#Returns ' when="yyyy-mm-dd"' or '' or similar
sub dateAttributes
{
    my $dateText = shift(@_);
    if ($dateText =~ m/([\dxX]+)-([\dxX]+)-(\d+)/)
    {
        my $year = $3;
        my $month = $1;
        my $day = $2;
        my $normalized;
        $month = sprintf("%02s", $month);
        $day = sprintf("%02s", $day);
        if ($year =~ m/\d+/)
        {
            $normalized = "$year";
        }
        else
        {
            $normalized = "-";
        }
        if ($month =~ m/\d+/)
        {
            $normalized = "$normalized-$month";
            if ($day =~ m/\d+/)
            {
                $normalized = "$normalized-$day";
            }
        }
        $attributeText = " when=\"$normalized\"";
    }
    return $attributeText;
}

sub createDateTag
{
    my $dateText = shift(@_);
    my $attributeText = dateAttributes($dateText);
    return "<date$attributeText>$dateText</date>";
}

if (scalar(@ARGV) == 0)
{
    print "Error: No file given\n";
    print "\nUsage: xml2tei.pl <output directory> <xml file 1> <xml file 2> <xml file 3> ...\n";
    exit();
}

while (scalar(@ARGV) != 0)
{
    my $fileName = shift(@ARGV);
    print "Processing file: $fileName\n";
    local $/=undef;
    open(FILE, $fileName) or die("Couldn't open file: $!");
    $fileContents = <FILE>;
    close FILE;

    $fileContents =~ s/\r//g;
    $fileContents =~ s/&/&amp;/g;
    $fileContents =~ s/&amp;amp;/&amp;/g;
    
    $windows_dash = chr(151);
    $fileContents =~ s/$windows_dash/&#8212;/g;
    $fileContents =~ s/<\/p><p>/<\/p>\n<p>/g;
    $fileContents =~ s/<\/p>(.*)/$1<\/p>/g;
    
    # Two common patterns in the source files:
    #</</location_mentioned>person_mentioned>
    #</</location_mentioned>p>
    $fileContents =~ s/<\/<\/location_mentioned>person_mentioned>/<\/location_mentioned><\/person_mentioned>/g;
    $fileContents =~ s/<\/<\/location_mentioned>p>/<\/location_mentioned><\/p>/g;
    # And more:
    # <</date_mentioned>/p>
    # <</person_mentioned>/p>
    $fileContents =~ s/<<\/date_mentioned>\/p>/<\/date_mentioned><\/p>/g;
    #$fileContents =~ s/<<\/person_mentioned>\/p>/<\/person_mentioned><\/p>/g;
    
    
    my $textId="TODO";
    my $title ="TODO";
    my $summary = "TODO";
    my $author="TODO";
    my $authorKey="TODO";
    my $origin="TODO";
    my $originKey="TODO";
    my $destin="TODO";
    my $destinKey="TODO";
    my $citation="TODO";
    my $oldDateTag="TODO";
    my $body="TODO";
    my $docType="TODO";
    my $domain="TODO";
    my $recipientsBlock="";
    my $sendersBlock="";
    my $digitalDateTag="TODO";
    my $changeTag="TODO";

    if ($fileContents =~ m/\<TEI.2 id\=\"([^"]*)\"/)
    {   
        $textId = $1;
    }
    if ($fileContents =~ m/\<document_title\>([^<]*)\<\/document_title\>/)
    {
        $title = $1;
    }
    if ($fileContents =~ m/\<document_type\>([^<]*)\<\/document_type\>/)
    {
        $docType = $1;
    }
    if ($fileContents =~ m/\<document_status\>([^<]*)\<\/document_status\>/)
    {
        $domain = $1;
        %domainHash = ("Public" => "public", "Private" => "domestic");
        if (exists $domainHash{$domain})
        {
            $domain = $domainHash{$1};
        }
        else
        {
            print "Warning!  Non-standard domain!\n";
        }
    }
    if ($fileContents =~ m/\<barker_summary\>(.*)\<\/barker_summary\>/s)
    {
        $summary = $1;
    }
    if ($fileContents =~ m/\<document_author\>([^<]*)\<\/document_author\>/)
    {
        $author = $1;
        $authorKey = getPersonKey($author);
    }
    if ($fileContents =~ m/\<sent_from\>([^<]*)\<\/sent_from\>/)
    {
        $origin = $1;
        $originKey = getLocationKey($origin);
    }
    if ($fileContents =~ m/\<sent_to\>([^<]*)\<\/sent_to\>/)
    {
        $destin = $1;
        $destinKey = getLocationKey($destin);
    }
    if ($fileContents =~ m/\<document_creation\>([^<]*)\<\/document_creation\>/)
    {
        $oldDateTag = createDateTag($1);
    }
    if ($fileContents =~ m/\<document_digital_creation\>([^<]*)\<\/document_digital_creation\>/)
    {
        my $dateText = $1;
        $digitalDateTag = createDateTag($dateText);
        my $attributes = dateAttributes($dateText);
        $changeTag = "<change$attributes who=\"#DL\">Digital creation of XML file</change>";
        #$digitalDate =~ m/(\d+)-(\d+)-(\d+)/;
        #$digitalDate = "$3-$1-$2";
    }

    if ($fileContents =~ m/\<barker_citation\>(.*)\<\/barker_citation\>/s)
    {
        $citation = $1;
    }

    if ($fileContents =~ m/\<div1 type\=\"body\"\>(.*)\<\/div1\>/s)
    {
        $body = $1;
        $body =~ s/\<(\/?)location_mentioned\>/\<$1placeName\>/sg;
        $body =~ s/\<(\/?)date_mentioned/\<$1date/sg;
        $body =~ s/\<date n="(\d\d)-(\d\d)-(\d\d\d\d)"/<date when="$3-$1-$2"/sg;
        $body =~ s/\<(\/?)person_mentioned/\<$1persName/sg;
        $body =~ s/\<barker_pb/\<pb/sg;
        $body =~ s/\<\/p\>\./\.\<\/p\>/sg;
    }


    if ($fileContents =~ m/\<document_sender\>([^<]*)\<\/document_sender\>/)
    {
        my $senders = $1;
        foreach my $name(split(/,| and /, $senders))
        {
            my $key = getPersonKey($name);
    $sendersBlock .= <<SGMR29HEREDOCTOKEN424;
                <person>
                    <persName type="sender">
                        $name
                    </persName>
                </person>

SGMR29HEREDOCTOKEN424
        }
    }

    if ($fileContents =~ m/\<document_recipient\>(.*)\<\/document_recipient\>/s)
    {
        my $recipients = $1;
        
        # handle special cases
        if($recipients =~ m/Editor/)
        {
		    $recipientsBlock .= <<BWB29HEREDOCTOKEN511
                <person>
                    <persName type="recipient">
                        $recipients
                    </persName>
                </person>		
BWB29HEREDOCTOKEN511
        	
        } else {
	        foreach my $name (split(/,|and /, $recipients))
	        {
	            my $key = getPersonKey($name);
			    $recipientsBlock .= <<SGMR29HEREDOCTOKEN511
                <person>
                    <persName type="recipient">
                        $name
                    </persName>
                </person>

SGMR29HEREDOCTOKEN511
        }        	
        }
        

    }
    
    print "textId:$textId\n";
    print "title:$title\n";
    print "summary:$summary\n";
    print "author:$author\n";
    print "authorKey:$authorKey\n";
    print "origin:$origin\n";
    print "originKey:$originKey\n";
    print "destin:$destin\n";
    print "destinKey:$destinKey\n";
    print "citation:$citation\n";
    print "oldDateTag:$oldDateTag\n";
    print "body:$body\n";
    print "sendersBlock:$sendersBlock\n";
    print "recipientsBlock:$recipientsBlock\n";
    print "digitalDateTag:$digitalDateTag\n";
    print "domain:$domain\n";

    my $newContents = <<SGMR29HEREDOCTOKEN124;
<?xml version="1.0" encoding="Windows-1252"?>
<TEI xmlns="http://www.tei-c.org/ns/1.0"
xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
xsi:schemaLocation="http://www.tei-c.org/ns/1.0 /home/sgmr29/code/digital-austin-papers/tei-2.0.2/xml/tei/custom/schema/xsd/tei_all.xsd "
xml:lang="EN"
xml:id="$textId">
<teiHeader>
    <fileDesc>
        <titleStmt>
            <title>$title</title>
            <author>
                <persName>$author</persName>
            </author>
            <respStmt xml:id="AJT">
                <resp>Project Director and Editor</resp> 
                <persName>Andrew J. Torget</persName>
            </respStmt>
            <respStmt xml:id="DL">
                <resp>Creation of XML version</resp>
                <persName>Debbie Liles</persName>
            </respStmt>
            <respStmt xml:id="SGM">
                <resp>TEI Formatting</resp>
                <persName>Stephen Mues</persName>
            </respStmt>
        </titleStmt>
        <publicationStmt>
            <publisher>Digital Stephen F. Austin Papers</publisher>
            $digitalDateTag
        </publicationStmt>
        <sourceDesc>
            <listPerson>
$sendersBlock
$recipientsBlock
            </listPerson>
            <listPlace>
                <place>
                    <placeName type="origin">$origin</placeName>
                </place>
                <place>
                    <placeName type="destination">$destin</placeName>
                </place>
            </listPlace>
            <bibl>
                $citation
            </bibl>
        </sourceDesc>
    </fileDesc>
    <profileDesc>
        <handNotes>
            <handNote xml:id="barker" scope="minor">
                Eugene Barker's summaries and footnotes
            </handNote>
        </handNotes>
        <textDesc>
            <channel mode="w">$docType</channel>
            <constitution type="single"/>
            <derivation type="original"/>
            <domain type="$domain"/>
            <factuality type="fact"/>
            <interaction type="none"/>
            <preparedness type="prepared"/>
            <purpose type="inform"/>
        </textDesc>
        <creation>
            $oldDateTag
        </creation>
    </profileDesc>
    <revisionDesc>
        <change when="2012-02-15" who="#SGM">Restructured to meet TEI P5 standards</change>
        $changeTag
    </revisionDesc>
</teiHeader>

<text>
    <body>
        <div1 type="summary">
            <p><add hand="#barker">$summary</add></p>
        </div1>
        <div1 type="body">
            $body
        </div1>
    </body>
</text>
</TEI>
SGMR29HEREDOCTOKEN124

#print $newContents;
#print "$title\n";
my $outFilePath = $outDir . basename($fileName);
print "$outFilePath\n";
open (OUTFILE, ">$outFilePath");
print OUTFILE $newContents;
close (OUTFILE); 

}

