
##  Copyright (c) 1997 by Steffen Beyer. All rights reserved.
##  This package is free software; you can redistribute and/or
##  modify it under the same terms as Perl itself.

package Locations;

use strict;

use Carp;

use vars qw(@ISA @EXPORT @EXPORT_OK $VERSION);

require Exporter;

@ISA = qw(Exporter);

@EXPORT = qw();

@EXPORT_OK = qw();

$VERSION = "1.1";

@Locations::List = ();  ##  sequential list of all existing locations

sub new
{
    croak "Usage: \$newlocation = {Locations,\$location}->new([\$filename]);"
      if ((@_ < 1) || (@_ > 2));

    my($outer) = shift;
    my($filename,$inner,$class);

    $filename = '';
    $filename = shift if (@_ > 0);

    if (ref($filename))
    {
        croak "Locations::new(): reference not allowed as filename";
    }

    $inner = { };
    $inner->{'file'}  = $filename;
    $inner->{'data'}  = [ ];
    $inner->{'outer'} = { };
    $inner->{'inner'} = { };
    $inner->{'top'}   = 0;

    ##  Note that $hash{$ref} is exactly the same as
    ##  $hash{"$ref"} because references are automatically
    ##  converted into strings when they are used as keys of a hash!!!

    if (ref($outer))  ##  object method
    {
        $class = ref($outer);
        bless($inner, $class);              ##  MUST come first!
        push(@{$outer->{'data'}}, $inner);
        $outer->{'inner'}->{$inner} = $inner;
        $inner->{'outer'}->{$outer} = $outer;
    }
    else              ##  class method
    {
        $class = $outer || 'Locations';
        bless($inner, $class);              ##  MUST come first!
        $inner->{'top'} = 1;
    }
    push(@Locations::List, $inner);
    return( $inner );
}

#################################################################
##                                                             ##
##  The following function is intended for internal use only!  ##
##  Use it only if you know exactly what you are doing!        ##
##                                                             ##
#################################################################

sub self_contained
{
    croak "Usage: if (self_contained(\$outer,\$inner))"
      if (@_ != 2);

    my($outer,$inner) = @_;
    my($list,$item);

    return(1) if ($outer eq $inner);
    $list = $inner->{'inner'};
    foreach $item (keys(%{$list}))
    {
        $inner = $list->{$item};
        return(1) if (self_contained($outer,$inner));
    }
    return(0);
}

sub print
{
    croak "Usage: \$location->print(\@items);"
      if (@_ < 1);

    my($outer) = shift;
    my($inner,$message);

    foreach $inner (@_)
    {
        if (ref($inner))
        {
            if (ref($inner) eq 'Locations')
            {
                if (self_contained($outer,$inner))
                {
                    croak
                  "Locations::print(): infinite recursion loop attempted";
                }
                else
                {
                    push(@{$outer->{'data'}}, $inner);
                    $outer->{'inner'}->{$inner} = $inner;
                    $inner->{'outer'}->{$outer} = $outer;
                }
            }
            else
            {
                $message =
            "Locations::print(): illegal reference '".ref($inner)."' ignored";
                carp $message;
            }
        }
        else
        {
            push(@{$outer->{'data'}}, $inner);
        }
    }
}

sub println
{
    croak "Usage: \$location->println(\@items);"
      if (@_ < 1);

    my($location) = shift;

    $location->print(@_,"\n");

    ##  We use a separate "\n" here (instead of concatenating it
    ##  with the last item) in case the last item is a reference!
}

###############################################################
##                                                           ##
##  The following method is intended for internal use only!  ##
##  Use it only if you know exactly what you are doing!      ##
##                                                           ##
###############################################################

sub dump_recursive
{
    croak "Usage: \$location->dump_recursive();"
      if (@_ != 1);

    my($location) = shift;
    my($item);

    foreach $item (@{$location->{'data'}})
    {
        if (ref($item))
        {
            if (ref($item) eq 'Locations')
            {
                $item->dump_recursive();
            }
        }
        else
        {
            print LOCATION $item;
        }
    }
}

###############################################################
##                                                           ##
##  The following method is intended for internal use only!  ##
##  Use it only if you know exactly what you are doing!      ##
##                                                           ##
###############################################################

sub dump_location
{
    croak "Usage: \$ok = \$location->dump_location([\$filename]);"
      if ((@_ < 1) || (@_ > 2));

    my($location) = shift;
    my($filename,$message);

    $filename = $location->{'file'};
    $filename = shift if (@_ > 0);

    if ($filename =~ /^\s*$/)
    {
        carp "Locations::dump_location(): no filename given";
        return(0);
    }

    unless ($filename =~ /^\s*[>\|+]/)
    {
        $filename = '>' . $filename;
    }

    unless (open(LOCATION, $filename))
    {
        $message =
      "Locations::dump_location(): can't open file '$filename': ".lc($!);
        carp $message;
        return(0);
    }
    $location->dump_recursive();
    close(LOCATION);
    return(1);
}

sub dump
{
    croak "Usage: \$ok = Locations->dump(); | \$ok = \$location->dump([\$filename]);"
      if ((@_ < 1) || (@_ > 2) || ((@_ == 2) && !ref($_[0])));

    my($location) = shift;
    my($ok);

    if (ref($location))  ##  object method
    {
        if (@_ > 0)
        {
            if (ref($_[0]))
            {
                croak "Locations::dump(): reference not allowed as filename";
            }
            return( $location->dump_location($_[0]) );
        }
        else
        {
            return( $location->dump_location() );
        }
    }
    else                 ##  class method
    {
        $ok = 1;
        foreach $location (@Locations::List)
        {
            if ($location->{'top'})
            {
                unless ($location->dump_location()) { $ok = 0; }
            }
        }
        return( $ok );
    }
}

sub set_filename
{
    croak "Usage: \$location->set_filename(\$filename);"
      if (@_ != 2);

    my($location,$filename) = @_;

    if (ref($filename))
    {
        croak "Locations::set_filename(): reference not allowed as filename";
    }

    $location->{'file'} = $filename;
}

sub get_filename
{
    croak "Usage: \$location->get_filename();"
      if (@_ != 1);

    my($location) = @_;

    return( $location->{'file'} );
}

###############################################################
##                                                           ##
##  The following method is intended for internal use only!  ##
##  Use it only if you know exactly what you are doing!      ##
##                                                           ##
###############################################################

sub traverse_recursive
{
    croak "Usage: \$location->traverse_recursive(\\&callback_function);"
      if (@_ != 2);

    my($location,$callback) = @_;
    my($item);

    if (ref($callback) ne 'CODE')
    {
        croak "Locations::traverse_recursive(): not a code reference";
    }

    foreach $item (@{$location->{'data'}})
    {
        if (ref($item))
        {
            if (ref($item) eq 'Locations')
            {
                $item->traverse_recursive($callback);
            }
        }
        else
        {
            &{$callback}($item);
        }
    }
}

####################################################################
##                                                                ##
##  The following method is intended for experienced users only!  ##
##  Use with extreme precaution!                                  ##
##                                                                ##
####################################################################

sub traverse
{
    croak "Usage: {Locations,\$location}->traverse(\\&callback_function);"
      if (@_ != 2);

    my($location,$callback) = @_;

    if (ref($callback) ne 'CODE')
    {
        croak "Locations::traverse(): not a code reference";
    }

    if (ref($location))  ##  object method
    {
        $location->traverse_recursive($callback);
    }
    else                 ##  class method
    {
        foreach $location (@Locations::List)
        {
            if ($location->{'top'})
            {
                &{$callback}($location);
            }
        }
    }
}

sub delete
{
    croak "Usage: {Locations,\$location}->delete();"
      if (@_ != 1);

    my($outer) = shift;
    my($list,$item,$inner,$link);

    if (ref($outer))  ##  object method
    {
        $list = $outer->{'inner'};
        foreach $item (keys(%{$list}))
        {
            $inner = $list->{$item};
            $link = $inner->{'outer'};
            delete $link->{$outer};
            unless (scalar(%{$link}))
            {
                $inner->{'top'} = 1;
            }
        }
        $outer->{'data'}  = [ ];
        $outer->{'inner'} = { };
    }
    else              ##  class method
    {
        foreach $outer (@Locations::List)
        {
            $outer->{'file'}  = '';   ##  We need to do this explicitly
            $outer->{'data'}  = [ ];  ##  in order to free memory because
            $outer->{'outer'} = { };  ##  the user might still be in
            $outer->{'inner'} = { };  ##  possession of references
            $outer->{'top'}   = 0;    ##  to these locations!

            bless($outer, "[Error: stale reference!]");
        }
        undef @Locations::List;
        @Locations::List = ();
    }
}

1;

__END__

=head1 NAME

Locations - recursive placeholders in the data you generate

"Locations" free you from the need to GENERATE data in the
same order in which it will be USED later.

They allow you to define insertion points in the middle of your
data which you can fill in later, at any time you want!

For instance you do not need to write output files in rigidly
sequential order anymore using this module.

Instead, write the data to locations in the order which is the most
appropriate and natural for you!

When you're finished, write your data to a file or process it otherwise,
purely in memory (faster!).

Most important: You can nest these placeholders in any way you want!

Potential infinite recursions are detected automatically and refused.

This means that you can GENERATE data ONLY ONCE in your program and
USE it MANY TIMES at different places, while the data itself is stored
in memory only once.

Maybe a picture will help to better understand this concept:

Think of "Locations" as folders (or drawers) containing papers
in a sequential order, most of which contain printable text or
data, while some may contain the name of another folder (or drawer).

When dumping a location to a file, the papers contained in it are
printed one after another in the order they were originally stored.
When a paper containing the name of another location is encountered,
however, the contents of that location are processed before continuing
to print the remaining papers of the current location. And so forth,
in a recursive descent.

Note that you are not confined to dumping locations to a file,
you can also process them directly in memory!

Note further that you may create as many locations with as many
embedded locations, as many nesting levels deep as your available
memory will permit.

Not even Clodsahamp's multidimensionally expanded tree house (see
Alan Dean Foster's fantasy novel "Spellsinger" for more details!)
can compare with this! C<:-)>

=head1 SYNOPSIS

=over 4

=item *

C<use Locations;>

=item *

C<$location = Locations-E<gt>new();>

=item *

C<$location = Locations-E<gt>new($filename);>

=item *

C<$sublocation = $location-E<gt>new();>

=item *

C<$sublocation = $location-E<gt>new($filename);>

=item *

C<$location-E<gt>print(@items);>

=item *

C<$location-E<gt>println(@items);>

=item *

C<$ok = Locations-E<gt>dump();>

=item *

C<$ok = $location-E<gt>dump();>

=item *

C<$ok = $location-E<gt>dump($filename);>

=item *

C<$location-E<gt>set_filename($filename);>

=item *

C<$filename = $location-E<gt>get_filename();>

=item *

C<Locations-E<gt>traverse(\&callback_function);>

=item *

C<$location-E<gt>traverse(\&callback_function);>

=item *

C<Locations-E<gt>delete();>

=item *

C<$location-E<gt>delete();>

=back

=head1 DESCRIPTION

=over 4

=item *

C<use Locations;>

Enables the use of locations in your program.

=item *

C<$location = Locations-E<gt>new();>

The CLASS METHOD "new()" creates a new top-level location
("top-level" means that it isn't embedded in any other location).

Note that CLASS METHODS are invoked using the NAME of their class,
i.e., "Locations" in this case, in contrast to OBJECT METHODS which
are invoked using an object reference such as returned by the class's
object constructor method (which "new()" happens to be).

Top-level locations need to have a filename associated with them
which you can either specify using the variant of the "new()" method
shown immediately below or using the method "set_filename()" (see
further below); otherwise an error occurs (in fact, a warning message
is printed to STDERR but program execution continues) when you try
to dump your top-level locations.

=item *

C<$location = Locations-E<gt>new($filename);>

This variant of the CLASS METHOD "new()" creates a new top-level
location ("top-level" means that it isn't embedded in any other
location) and assigns a default filename to it.

Note that this filename is simply passed through to the Perl "open()"
function later on (which is called internally when you dump your locations
to a file), which means that any legal Perl filename may be used such as
">-" (for writing to STDOUT) and "| more", to give you just two of the
more exotic examples!

See the section on "open()" in L<perlfunc> for more details!

=item *

C<$sublocation = $location-E<gt>new();>

The OBJECT METHOD "new()" creates a new location which is embedded
in the given location "$location" at the current position (defined
by what has been printed to the embedding location till this moment).

Such nested locations usually do not need a filename associated with
them (because they will be dumped to the same file as the location in
which they are embedded), unless you want to dump this location to a
file of its own, additionally.

In the latter case, use the variant of the "new()" method shown
immediately below or the method "set_filename()" (see further
below) to set this filename, or call the method "dump()"
(explained below) with an appropriate filename argument.

=item *

C<$sublocation = $location-E<gt>new($filename);>

This variant of the OBJECT METHOD "new()" creates a new location
which is embedded in the given location "$location" at the current
position (defined by what has been printed to the embedding location
till this moment) and assigns a default filename to it.

See the section on "open()" in L<perlfunc> for more details about
what filenames you may use (i.e., which filenames are legal)!

=item *

C<$location-E<gt>print(@items);>

This object method prints the given arguments to the indicated
location, i.e., appends the given items to the given location.

IMPORTANT FEATURE:

Note that you can EMBED any given location IN MORE THAN ONE surrounding
location using this method!

Simply use a statement similar to this one:

        $location->print($sublocation);

This embeds location "$sublocation" in location "$location" at the
current position (defined by what has been printed to location
"$location" till this moment).

This is especially useful if you are generating data once in your
program which you need at several places in your output files.

This saves a lot of memory because only a reference of the embedded
location is stored in every embedding location instead of all the
data, which is stored only once!

Note that other references than "Locations" object references are
illegal, trying to "print" such a reference to a location will result
in a warning message and the reference will simply be ignored.

Note also that potential infinite recursions (which would occur when
a given location contained itself, directly or indirectly!) are
detected automatically and refused (with an appropriate error message
and program abortion).

Because of the necessity for this check, it is more efficient to
embed locations using the object method "new()" (where possible)
than with this mechanism, because embedding an empty new location
is always possible without checking.

=item *

C<$location-E<gt>println(@items);>

Same as the "print()" method above, except that a "newline" character
("C<\n>") is appended at the end of the list of items to be printed
(just a newline character is printed if no arguments (= an empty
argument list) are given).

=item *

C<$ok = Locations-E<gt>dump();>

This CLASS METHOD dumps all top-level locations to their default
files (whose filenames must have been stored previously along with
each location using the method "new()" or "set_filename()").

Note that a warning message will be printed if any of the top-level
locations happens to lack a default filename and that the respective
location will simply not be dumped to a file!

(Program execution continues in order to facilitate debugging of
your program and to save a maximum of your data in memory which
would be lost otherwise!)

Moreover, should any problem arise with any of the top-level locations
(for instance no filename given or filename invalid or unable to open
the specified file), then this method returns "false" (0).

The method returns "true" (1) only if ALL top-level locations have
been written to their respective files successfully.

Note also that a ">" is prepended to this default filename just
before opening the file if the default filename does not begin
with ">", "|" or "+" (leading white space is ignored).

This does not change the filename which is stored along with the
location, however.

Finally, note that this method does not affect the contents of
the locations that are being dumped.

If you want to delete all your locations once they have been dumped
to their respective files, call the class method "delete()" (explained
further below) EXPLICITLY.

=item *

C<$ok = $location-E<gt>dump();>

The OBJECT METHOD "dump()" dumps the given location to its default
file (whose filename must have been stored previously along with
this location using the method "new()" or "set_filename()").

Note that a warning message will be printed if the location happens
to lack a default filename and that the location will simply not be
dumped to a file!

(Program execution continues in order to facilitate debugging of
your program and to save a maximum of your data in memory which
would be lost otherwise!)

Moreover, should any problem arise with the given location (for
instance no filename given or filename invalid or unable to open
the specified file), then this method returns "false" (0).

The method returns "true" (1) if the given location has been
successfully written to its respective file.

Note also that a ">" is prepended to this default filename just
before opening the file if the default filename does not begin
with ">", "|" or "+" (leading white space is ignored).

This does not change the filename which is stored along with the
location, however.

Finally, note that this method does not affect the contents of
the location being dumped.

If you want to delete this location once it has been dumped, call
the object method "delete()" (explained further below) EXPLICITLY.

=item *

C<$ok = $location-E<gt>dump($filename);>

This variant of the OBJECT METHOD "dump()" does the same as the
variant described immediately above, except that it overrides the
default filename stored along with the given location and uses the
indicated filename instead.

Note that the stored filename is just being overridden, BUT NOT
CHANGED.

I.e., if you call the method "dump()" again without a filename argument
after calling it with an explicit filename argument once, the initial
filename stored with the given location will be used, NOT the filename
that you specified explicitly the last time when you called "dump()"!

Should any problem arise with the given location (for instance if the
given filename is invalid or if Perl was unable to open the specified
file), then this method returns "false" (0).

The method returns "true" (1) if the given location has been
successfully written to the specified file.

(Note that if the given filename is empty or contains only white space,
the method does NOT fall back to the filename previously stored along
with the given location because doing so could overwrite valuable data!)

Note also that a ">" is prepended to the given filename if it does not
begin with ">", "|" or "+" (leading white space is ignored).

Finally, note that this method does not affect the contents of
the location being dumped.

If you want to delete this location once it has been dumped, call
the object method "delete()" (explained further below) EXPLICITLY.

=item *

C<$location-E<gt>set_filename($filename);>

This object method stores a filename along with the given location
which will be used as the default filename when dumping that location.

You may set the filename associated with any given location using this
method any number of times.

See the method "get_filename()" immediately below for retrieving
the default filename that has been stored along with a given location.

=item *

C<$filename = $location-E<gt>get_filename();>

This object method returns the default filename that has previously
been stored along with the given location, using either the method
"new()" or the method "set_filename()".

=item *

C<Locations-E<gt>traverse(\&callback_function);>

The CLASS METHOD "traverse()" cycles through all top-level locations
(in the order in which they were created) and calls the callback
function you specified once for each of them.

Expect one parameter handed over to your callback function which is
the reference to the location in question.

Since callback functions can do a lot of unwanted things, use this
method with great precaution!

=item *

C<$location-E<gt>traverse(\&callback_function);>

The OBJECT METHOD "traverse()" performs a recursive descent on the
given location just as the method "dump()" does internally, but
instead of printing the items of data contained in the location
to a file, this method calls the callback function you specified
once for each item stored in the location.

This way you can read what a given location contains without
having to dump it to a file and reading that file back in!

Expect one parameter handed over to your callback function which
is the next chunk of data contained in the given location (or the
locations embedded therein).

Since callback functions can do a lot of unwanted things, use this
method with great precaution!

=item *

C<Locations-E<gt>delete();>

The CLASS METHOD "delete()" deletes all locations and their contents,
which allows you to start over completely from scratch.

Note that you do not need to call this method in order to
initialize this class before using it; the "C<use Locations;>"
statement is sufficient.

BEWARE that any references to locations you might still be holding
in your program become invalid by invoking this method!

If you try to invoke a method using such an invalidated reference,
an error message (with program abortion) similar to this one will
occur:

C<Can't locate object method "method" via package "[Error: stale reference!]">
C<at program.pl line 65.>

=item *

C<$location-E<gt>delete();>

The OBJECT METHOD "delete()" deletes the CONTENTS of the given location -
the location CONTINUES TO EXIST and REMAINS EMBEDDED where it was!

The associated filename stored along with the given location is also
NOT AFFECTED by this.

Note that a complete removal of the given location itself INCLUDING all
references to this location which may still be embedded somewhere in other
locations is unnecessary if, subsequently, you do not print anything to
this location anymore!

If the given location is a top-level location, you might want to set the
associated filename to "/dev/null", though, using the method "set_filename()"
(before or after deleting the location, this makes no difference).

BEWARE that the locations that were previously embedded in the given
(now deleted) location may not be contained in any other location anymore
after invoking this method!

If this happens, the affected "orphant" locations will be transformed
into top-level locations automatically. Note however that you may have
to define a default filename for these locations (if you haven't done
so previously) before invoking "C<Locations-E<gt>dump();>" in order to
avoid data loss and the warning message that will occur otherwise!

=back

=head1 EXAMPLE #1

  #!/usr/local/bin/perl -w

  use strict;
  no strict "vars";

  use Locations;

  $head = Locations->new();  ##  E.g. for interface definitions
  $body = Locations->new();  ##  E.g. for implementation

  $head->set_filename("example.h");
  $body->set_filename("example.c");

  $common = $head->new();    ##  Embed a new location in "$head"
  $body->print($common);     ##  Embed this same location in "$body"

  ##  Create some more locations...

  $copyright = Locations->new("/dev/null");
  $includes  = Locations->new("/dev/null");
  $prototype = Locations->new("/dev/null");

  ##  ...and embed them in location "$common":

  $common->print($copyright,$includes,$prototype);

  ##  This is just to show you an alternate (though less efficient) way!
  ##  Normally you would use:
  ##      $copyright = $common->new();
  ##      $includes  = $common->new();
  ##      $prototype = $common->new();

  $head->println(";");  ##  The final ";" after a prototype
  $body->println();     ##  Just a newline after a function header

  $body->println("{");
  $body->println('    printf("Hello, world!\n");');
  $body->println("}");

  $includes->print("#include <");
  $library = $includes->new();     ##  Nesting even deeper still...
  $includes->println(">");

  $prototype->print("void hello(void)");

  $copyright->println("/*");
  $copyright->println("   Copyright (c) 1997 by Steffen Beyer.");
  $copyright->println("   All rights reserved.");
  $copyright->println("*/");

  $library->print("stdio.h");

  $copyright->set_filename("default.txt");

  $copyright->dump(">-");

  print "default filename = '", $copyright->get_filename(), "'\n";

  Locations->dump();

  __END__

When executed, this example will print

  /*
     Copyright (c) 1997 by Steffen Beyer.
     All rights reserved.
  */
  default filename = 'default.txt'

to the screen and create the following two files:

  ::::::::::::::
  example.c
  ::::::::::::::
  /*
     Copyright (c) 1997 by Steffen Beyer.
     All rights reserved.
  */
  #include <stdio.h>
  void hello(void)
  {
      printf("Hello, world!\n");
  }

  ::::::::::::::
  example.h
  ::::::::::::::
  /*
     Copyright (c) 1997 by Steffen Beyer.
     All rights reserved.
  */
  #include <stdio.h>
  void hello(void);

=head1 EXAMPLE #2

  #!/usr/local/bin/perl -w

  use strict;
  no strict "vars";

  use Locations;

  $html = Locations->new("example.html");

  $html->println("<HTML>");
  $head = $html->new();
  $body = $html->new();
  $html->println("</HTML>");

  $head->println("<HEAD>");
  $tohead = $head->new();
  $head->println("</HEAD>");

  $body->println("<BODY>");
  $tobody = $body->new();
  $body->println("</BODY>");

  $tohead->print("<TITLE>");
  $title = $tohead->new();
  $tohead->println("</TITLE>");

  $tohead->print('<META NAME="description" CONTENT="');
  $description = $tohead->new();
  $tohead->println('">');

  $tohead->print('<META NAME="keywords" CONTENT="');
  $keywords = $tohead->new();
  $tohead->println('">');

  $tobody->println("<CENTER>");

  $tobody->print("<H1>");
  $tobody->print($title);      ##  re-using this location!!
  $tobody->println("</H1>");

  $contents = $tobody->new();

  $tobody->println("</CENTER>");

  $title->print("Locations Example HTML-Page");

  $description->print("Example for generating HTML pages");
  $description->print(" using 'Locations'");

  $keywords->print("Locations, magic, recursive");

  $contents->println("This page was generated using the");
  $contents->println("<P>");
  $contents->println("&quot;<B>Locations</B>&quot;");
  $contents->println("<P>");
  $contents->println("module for Perl.");

  Locations->dump();

  __END__

When executed, this example will produce
the following file ("example.html"):

  <HTML>
  <HEAD>
  <TITLE>Locations Example HTML-Page</TITLE>
  <META NAME="description" CONTENT="Example for generating HTML pages using 'Locations'">
  <META NAME="keywords" CONTENT="Locations, magic, recursive">
  </HEAD>
  <BODY>
  <CENTER>
  <H1>Locations Example HTML-Page</H1>
  This page was generated using the
  <P>
  &quot;<B>Locations</B>&quot;
  <P>
  module for Perl.
  </CENTER>
  </BODY>
  </HTML>

=head1 EXAMPLE #3

The following code fragment is an example of how you can use the callback
mechanism of this class to collect the contents of all top-level locations
in a string (which is printed to the screen in this example):

  sub concat
  {
      $string .= $_[0];
  }

  sub list
  {
      $string .= $ruler;
      $string .= "\"" . $_[0]->get_filename() . "\":\n";
      $string .= $ruler;
      $_[0]->traverse(\&concat);
      $string .= "\n" unless ($string =~ /\n$/);
  }

  $ruler = '=' x 78 . "\n";

  $string = '';

  Locations->traverse(\&list);

  $string .= $ruler;

  print $string;

=head1 SEE ALSO

perl(1),
perlsub(1), perlmod(1), perlref(1),
perlobj(1), perlbot(1), perltoot(1).

=head1 VERSION

This man page documents "Locations" version 1.1.

=head1 AUTHOR

Steffen Beyer <sb@sdm.de>.

=head1 COPYRIGHT

Copyright (c) 1997 by Steffen Beyer. All rights reserved.

=head1 LICENSE

This package is free software; you can redistribute
and/or modify it under the same terms as Perl itself.

