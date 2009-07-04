# ITEMAN Dynamic Publishing - A Perl based dynamic publishing extension for Moveble Type
# Copyright (c) 2009 ITEMAN, Inc. All rights reserved.
#
# This file is part of ITEMAN Dynamic Publishing.
# 
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# This file is based on MT::WeblogPublisher by Six Apart, Ltd.
# The following is the original copyright notice:
#
# Movable Type (r) Open Source (C) 2001-2009 Six Apart, Ltd.
# This program is distributed under the terms of the
# GNU General Public License, version 2.

package ITEMAN::DynamicPublishing::MT::RuntimePublisher;

use strict;
use warnings;

use base 'MT::WeblogPublisher';

use File::Basename;
use MT::PublishOption;

sub rebuild_file {
    my $mt = shift;
    my ( $blog, $root_path, $map, $at, $ctx, $cond, $build_static, %args )
      = @_;
    my $finfo;
    my $archiver = $mt->archiver($at);
    my ( $entry, $start, $end, $category, $author );

    if ( $finfo = $args{FileInfo} ) {
        $args{Author}   = $finfo->author_id   if $finfo->author_id;
        $args{Category} = $finfo->category_id if $finfo->category_id;
        $args{Entry}    = $finfo->entry_id    if $finfo->entry_id;
        $map ||= MT::TemplateMap->load( $finfo->templatemap_id );
        $at  ||= $finfo->archive_type;
        if ( $finfo->startdate ) {
            if ( ( $start, $end ) = $archiver->date_range($finfo->startdate) ) {
                $args{StartDate} = $start;
                $args{EndDate}   = $end;
            }
        }
    }

    # Calculate file path and URL for the new entry.
    my $file = File::Spec->catfile( $root_path, $map->{__saved_output_file} );

    ## Untaint. We have to assume that we can trust the user's setting of
    ## the archive_path, and nothing else is based on user input.
    ($file) = $file =~ /(.+)/s;

    my $fmgr = $blog->file_mgr;

    # compare file modification time to start of build process. if it
    # is greater than the start_time, then we shouldn't need to build this
    # file again
    unless ( $map->build_type == MT::PublishOption::DYNAMIC() ) {
        if (my $mod_time = $fmgr->file_mod_time($file)) {
            return $fmgr->get_data($file) if $mod_time >= $mt->start_time;
        }
    }

    if ( $archiver->category_based ) {
        $category = $args{Category};
        die "Category archive type requires Category parameter"
          unless $args{Category};
        $category = MT::Category->load($category)
          unless ref $category;
        $ctx->var( 'category_archive', 1 );
        $ctx->{__stash}{archive_category} = $category;
    }
    if ( $archiver->entry_based ) {
        $entry = $args{Entry};
        die "$at archive type requires Entry parameter"
          unless $entry;
        require MT::Entry;
        $entry = MT::Entry->load($entry) if !ref $entry;
        $ctx->var( 'entry_archive', 1 );
        $ctx->{__stash}{entry} = $entry;
    }
    if ( $archiver->date_based ) {
        # Date-based archive type
        $start = $args{StartDate};
        $end   = $args{EndDate};
        Carp::confess("Date-based archive types require StartDate parameter")
          unless $args{StartDate};
        $ctx->var( 'datebased_archive', 1 );
    }
    if ( $archiver->author_based ) {

        # author based archive type
        $author = $args{Author};
        die "Author-based archive type requires Author parameter"
          unless $args{Author};
        require MT::Author;
        $author = MT::Author->load($author)
          unless ref $author;
        $ctx->var( 'author_archive', 1 );
        $ctx->{__stash}{author} = $author;
    }
    local $ctx->{current_timestamp}     = $start if $start;
    local $ctx->{current_timestamp_end} = $end   if $end;

    $ctx->{__stash}{blog} = $blog;
    $ctx->{__stash}{local_blog_id} = $blog->id;

    require MT::FileInfo;

    my $url = $blog->archive_url;
    $url = $blog->site_url
      if $archiver->entry_based && $archiver->entry_class eq 'page';
    $url .= '/' unless $url =~ m|/$|;
    $url .= $map->{__saved_output_file};

    my $tmpl_id = $map->template_id;

    # template specific for this entry (or page, as the case may be)
    if ( $entry && $entry->template_id ) {

        # allow entry to override *if* we're publishing an individual
        # page, and this is the 'preferred' one...
        if ( $archiver->entry_based ) {
            if ( $map->is_preferred ) {
                $tmpl_id = $entry->template_id;
            }
        }
    }

    my $tmpl = MT::Template->load($tmpl_id);
    $tmpl->context($ctx);

    # From Here
    if ( my $tmpl_param = $archiver->template_params ) {
        $tmpl->param($tmpl_param);
    }

    my ($rel_url) = ( $url =~ m|^(?:[^:]*\:\/\/)?[^/]*(.*)| );
    $rel_url =~ s|//+|/|g;

    # Clear out all the FileInfo records that might point at the page
    # we're about to create
    # FYI: if it's an individual entry, we don't use the date as a
    #      criterion, since this could actually have changed since
    #      the FileInfo was last built. When the date does change,
    #      the old date-based archive doesn't necessarily get fixed,
    #      but if another comes along it will get corrected
    unless ($finfo) {
        my %terms;
        $terms{blog_id}     = $blog->id;
        $terms{category_id} = $category->id if $archiver->category_based;
        $terms{author_id}   = $author->id if $archiver->author_based;
        $terms{entry_id}    = $entry->id if $archiver->entry_based;
        $terms{startdate}   = $start
          if $archiver->date_based && ( !$archiver->entry_based );
        $terms{archive_type}   = $at;
        $terms{templatemap_id} = $map->id;
        my @finfos = MT::FileInfo->load( \%terms );

        if (   ( scalar @finfos == 1 )
            && ( $finfos[0]->file_path eq $file )
            && ( ( $finfos[0]->url || '' ) eq $rel_url )
            && ( $finfos[0]->template_id == $tmpl_id ) )
        {

            # if the shoe fits, wear it
            $finfo = $finfos[0];
        }
        else {

           # if the shoe don't fit, remove all shoes and create the perfect shoe
            foreach (@finfos) { $_->remove(); }

            $finfo = MT::FileInfo->set_info_for_url(
                $rel_url, $file, $at,
                {
                    Blog        => $blog->id,
                    TemplateMap => $map->id,
                    Template    => $tmpl_id,
                    ( $archiver->entry_based && $entry )
                    ? ( Entry => $entry->id )
                    : (),
                    StartDate => $start,
                    ( $archiver->category_based && $category )
                    ? ( Category => $category->id )
                    : (),
                    ( $archiver->author_based )
                    ? ( Author => $author->id )
                    : (),
                }
              )
              || die "Couldn't create FileInfo because "
              . MT::FileInfo->errstr();
        }
    }

    if ($entry && $entry->status != MT::Entry::RELEASE() || !$map->build_type) {
        require ITEMAN::DynamicPublishing::MT::RuntimePublisher::EntryNotReleasedException;
        die ITEMAN::DynamicPublishing::MT::RuntimePublisher::EntryNotReleasedException->new;
    }

    my $timer = MT->get_timer;
    if ($timer) {
        $timer->pause_partial;
    }
    local $timer->{elapsed} = 0 if $timer;

    my $html = undef;

    if (
        $build_static
        && MT->run_callbacks(
            'build_file_filter',
            Context      => $ctx,
            context      => $ctx,
            ArchiveType  => $at,
            archive_type => $at,
            TemplateMap  => $map,
            template_map => $map,
            Blog         => $blog,
            blog         => $blog,
            Entry        => $entry,
            entry        => $entry,
            FileInfo     => $finfo,
            file_info    => $finfo,
            File         => $file,
            file         => $file,
            Template     => $tmpl,
            template     => $tmpl,
            PeriodStart  => $start,
            period_start => $start,
            Category     => $category,
            category     => $category,
            force        => ($args{Force} ? 1 : 0),
        )
      )
    {

        if ( $archiver->group_based ) {
            require MT::Promise;
            my $entries = sub { $archiver->archive_group_entries($ctx) };
            $ctx->stash( 'entries', MT::Promise::delay($entries) );
        }

        $ctx->stash( 'blog', $blog );
        $ctx->stash( 'entry', $entry ) if $entry;

        require MT::Request;
        MT::Request->instance->cache('build_template', $tmpl);

        $html = $tmpl->build( $ctx, $cond );
        unless (defined($html)) {
            $timer->unpause if $timer;
            require MT::I18N;
            die $category ? ('An error occurred publishing ' . MT::I18N::lowercase( $category->class_label ) . " '" . $category->id . "': " . $tmpl->errstr)
                          : $entry ? ('An error occurred publishing ' . MT::I18N::lowercase( $entry->class_label ) . " '" . $entry->title . "': " . $tmpl->errstr)
                                   : ("An error occurred publishing date-based archive '" . $at . $start . "': " . $tmpl->errstr)
        }
        my $orig_html = $html;
        MT->run_callbacks(
            'build_page',
            Context      => $ctx,
            context      => $ctx,
            ArchiveType  => $at,
            archive_type => $at,
            TemplateMap  => $map,
            template_map => $map,
            Blog         => $blog,
            blog         => $blog,
            Entry        => $entry,
            entry        => $entry,
            FileInfo     => $finfo,
            file_info    => $finfo,
            PeriodStart  => $start,
            period_start => $start,
            Category     => $category,
            category     => $category,
            RawContent   => \$orig_html,
            raw_content  => \$orig_html,
            Content      => \$html,
            content      => \$html,
            BuildResult  => \$orig_html,
            build_result => \$orig_html,
            Template     => $tmpl,
            template     => $tmpl,
            File         => $file,
            file         => $file
        );

        unless ( $map->build_type == MT::PublishOption::DYNAMIC() ) {

            ## First check whether the content is actually
            ## changed. If not, we won't update the published
            ## file, so as not to modify the mtime.
            unless ($fmgr->content_is_updated( $file, \$html )) {
                $timer->unpause if $timer;
                return $html;
            }

            ## Determine if we need to build directory structure,
            ## and build it if we do. DirUmask determines
            ## directory permissions.
            require File::Spec;
            my $path = dirname($file);
            $path =~ s!/$!!
              unless $path eq '/'; ## OS X doesn't like / at the end in mkdir().
            unless ( $fmgr->exists($path) ) {
                if (!$fmgr->mkpath($path)) {
                    $timer->unpause if $timer;
                    die "Error making path '" . $path . "': " . $fmgr->errstr;
                }
            }

            ## By default we write all data to temp files, then rename
            ## the temp files to the real files (an atomic
            ## operation). Some users don't like this (requires too
            ## liberal directory permissions). So we have a config
            ## option to turn it off (NoTempFiles).
            my $use_temp_files = !$mt->{NoTempFiles};
            my $temp_file = $use_temp_files ? "$file.new" : $file;
            unless ( defined $fmgr->put_data( $html, $temp_file ) ) {
                $timer->unpause if $timer;
                die "Writing to '" . $temp_file . "' failed: " . $fmgr->errstr;
            }
            if ($use_temp_files) {
                if (!$fmgr->rename( $temp_file, $file )) {
                    $timer->unpause if $timer;
                    die "Renaming tempfile '" . $temp_file . "' failed: " . $fmgr->errstr;
                }
            }
        }
        MT->run_callbacks(
            'build_file',
            Context      => $ctx,
            context      => $ctx,
            ArchiveType  => $at,
            archive_type => $at,
            TemplateMap  => $map,
            template_map => $map,
            FileInfo     => $finfo,
            file_info    => $finfo,
            Blog         => $blog,
            blog         => $blog,
            Entry        => $entry,
            entry        => $entry,
            PeriodStart  => $start,
            period_start => $start,
            RawContent   => \$orig_html,
            raw_content  => \$orig_html,
            Content      => \$html,
            content      => \$html,
            BuildResult  => \$orig_html,
            build_result => \$orig_html,
            Template     => $tmpl,
            template     => $tmpl,
            Category     => $category,
            category     => $category,
            File         => $file,
            file         => $file
        );
    }
    $timer->mark("total:rebuild_file[template_id:" . $tmpl->id . "]")
        if $timer;

    return $html;
}

sub rebuild_indexes {
    my $mt    = shift;
    my %param = @_;
    require MT::Template;
    require MT::Template::Context;
    require MT::Entry;

    my $blog;
    $blog = $param{Blog}
        if defined $param{Blog};
    if (!$blog && defined $param{BlogID}) {
        my $blog_id = $param{BlogID};
        $blog = MT::Blog->load($blog_id)
          or die "Load of blog '" . $blog_id . "' failed: " .  MT::Blog->errstr;
    }
    my $tmpl = $param{Template};
    if ($tmpl && (!$blog || $blog->id != $tmpl->blog_id)) {
        $blog = MT::Blog->load( $tmpl->blog_id );
    }

    die 'Blog, BlogID or Template param must be specified.' unless $blog;

    my $force = $param{Force};

    local *FH;
    my $site_root = $blog->site_path;
    die 'You did not set your blog publishing path' unless $site_root;
    my $fmgr = $blog->file_mgr;

    ## Skip index templates that the user has designated not to be
    ## rebuilt automatically. We need to do the defined-ness check
    ## because we added the flag in 2.01, and for templates saved
    ## before that time, the rebuild_me flag will be undefined. But
    ## we assume that these templates should be rebuilt, since that
    ## was the previous behavior.
    ## Note that dynamic templates do need to be "rebuilt"--the
    ## FileInfo table needs to be maintained.
    if ( !$tmpl->build_dynamic && !$force ) {
        next if ( defined $tmpl->rebuild_me && !$tmpl->rebuild_me );
    }
    next if ( defined $tmpl->build_type && !$tmpl->build_type );

    my $file = $tmpl->outfile;
    $file = '' unless defined $file;
    if ( $tmpl->build_dynamic && ( $file eq '' ) ) {
        next;
    }
    die "Template '" . $tmpl->name . "' does not have an Output File." unless $file ne '';
    my $url = join( '/', $blog->site_url, $file );
    unless ( File::Spec->file_name_is_absolute($file) ) {
        $file = File::Spec->catfile( $site_root, $file );
    }

    # Everything from here out is identical with rebuild_file
    my ($rel_url) = ( $url =~ m|^(?:[^:]*\:\/\/)?[^/]*(.*)| );
    $rel_url =~ s|//+|/|g;
    ## Untaint. We have to assume that we can trust the user's setting of
    ## the site_path and the template outfile.
    ($file) = $file =~ /(.+)/s;
    my $finfo = $param{FileInfo};  # available for single template calls
    unless ( $finfo ) {
        require MT::FileInfo;
        my @finfos = MT::FileInfo->load(
            {
                blog_id     => $tmpl->blog_id,
                template_id => $tmpl->id
            }
        );
        if (   ( scalar @finfos == 1 )
            && ( $finfos[0]->file_path eq $file )
            && ( ( $finfos[0]->url || '' ) eq $rel_url ) )
        {
            $finfo = $finfos[0];
        }
        else {
            foreach (@finfos) { $_->remove(); }
            $finfo = MT::FileInfo->set_info_for_url(
                $rel_url, $file, 'index',
                {
                    Blog     => $tmpl->blog_id,
                    Template => $tmpl->id,
                }
              )
              || die "Couldn't create FileInfo because " . MT::FileInfo->errstr;
        }
    }

    next unless ( $tmpl->build_type );

    my $timer = MT->get_timer;
    if ($timer) {
        $timer->pause_partial;
    }
    local $timer->{elapsed} = 0 if $timer;

    my $ctx = MT::Template::Context->new;
    next
      unless (
        MT->run_callbacks(
            'build_file_filter',
            Context      => $ctx,
            context      => $ctx,
            ArchiveType  => 'index',
            archive_type => 'index',
            Blog         => $blog,
            blog         => $blog,
            FileInfo     => $finfo,
            file_info    => $finfo,
            Template     => $tmpl,
            template     => $tmpl,
            File         => $file,
            file         => $file,
            force        => $force,
        )
      );
    $ctx->stash( 'blog', $blog );

    require MT::Request;
    MT::Request->instance->cache('build_template', $tmpl);

    my $html = $tmpl->build($ctx);
    unless (defined $html) {
        $timer->unpause if $timer;
        die $tmpl->errstr;
    }

    my $orig_html = $html;
    MT->run_callbacks(
        'build_page',
        Context      => $ctx,
        context      => $ctx,
        Blog         => $blog,
        blog         => $blog,
        FileInfo     => $finfo,
        file_info    => $finfo,
        ArchiveType  => 'index',
        archive_type => 'index',
        RawContent   => \$orig_html,
        raw_content  => \$orig_html,
        Content      => \$html,
        content      => \$html,
        BuildResult  => \$orig_html,
        build_result => \$orig_html,
        Template     => $tmpl,
        template     => $tmpl,
        File         => $file,
        file         => $file
    );

    unless ( $tmpl->build_type == MT::PublishOption::DYNAMIC() ) {
        {
            ## First check whether the content is actually changed. If not,
            ## we won't update the published file, so as not to modify the mtime.
            last unless $fmgr->content_is_updated( $file, \$html );

            ## Determine if we need to build directory structure,
            ## and build it if we do. DirUmask determines
            ## directory permissions.
            require File::Spec;
            my $path = dirname($file);
            $path =~ s!/$!!
              unless $path eq '/';    ## OS X doesn't like / at the end in mkdir().
            unless ( $fmgr->exists($path) ) {
                if (! $fmgr->mkpath($path) ) {
                    $timer->unpause if $timer;
                    die "Error making path '" . $path . "': " . $fmgr->errstr;
                }
            }

            ## Update the published file.
            my $use_temp_files = !$mt->{NoTempFiles};
            my $temp_file = $use_temp_files ? "$file.new" : $file;
            unless (defined( $fmgr->put_data( $html, $temp_file ) )) {
                $timer->unpause if $timer;
                die "Writing to '" . $temp_file . "' failed: " . $fmgr->errstr;
            }
            if ($use_temp_files) {
                if (!$fmgr->rename( $temp_file, $file )) {
                    $timer->unpause if $timer;
                    die "Renaming tempfile '" . $temp_file . "' failed: " . $fmgr->errstr;
                }
            }
        }
    }

    MT->run_callbacks(
        'build_file',
        Context      => $ctx,
        context      => $ctx,
        ArchiveType  => 'index',
        archive_type => 'index',
        FileInfo     => $finfo,
        file_info    => $finfo,
        Blog         => $blog,
        blog         => $blog,
        RawContent   => \$orig_html,
        raw_content  => \$orig_html,
        Content      => \$html,
        content      => \$html,
        BuildResult  => \$orig_html,
        build_result => \$orig_html,
        Template     => $tmpl,
        template     => $tmpl,
        File         => $file,
        file         => $file
    );

    $timer->mark("total:rebuild_indexes[template_id:" . $tmpl->id . ";file:$file]")
        if $timer;

    return $html;
}

sub rebuild_from_fileinfo {
    my $pub = shift;
    my ($fi) = @_;

    require MT::Blog;
    require MT::Entry;
    require MT::Category;
    require MT::Template;
    require MT::TemplateMap;
    require MT::Template::Context;

    my $at = $fi->archive_type
      or die "Parameter 'ArchiveType' is required";

    # callback for custom archive types
    MT->run_callbacks('build_archive_filter', archive_type => $at, file_info => $fi)
        or die MT->errstr;

    if ( $at eq 'index' ) {
        return
            $pub->rebuild_indexes(
                BlogID   => $fi->blog_id,
                Template => MT::Template->load( $fi->template_id ),
                FileInfo => $fi,
                Force    => 1,
            );
    }

    die 'Unknown archive type' if $at eq 'None';

    my ( $start, $end );
    my $blog = MT::Blog->load( $fi->blog_id )
      if $fi->blog_id;
    my $entry = MT::Entry->load( $fi->entry_id )
      or die "Parameter 'Entry' is required"
      if $fi->entry_id;
    if ( $fi->startdate ) {
        my $archiver = $pub->archiver($at);

        if ( ( $start, $end ) = $archiver->date_range( $fi->startdate ) ) {
            $entry = MT::Entry->load( { authored_on => [ $start, $end ] },
                { range_incl => { authored_on => 1 }, limit => 1 } )
              or die "Parameter 'Entry' is required";
        }
    }
    my $cat = MT::Category->load( $fi->category_id )
      if $fi->category_id;
    my $author = MT::Author->load( $fi->author_id )
      if $fi->author_id;

    ## Load the template-archive-type map entries for this blog and
    ## archive type. We do this before we load the list of entries, because
    ## we will run through the files and check if we even need to rebuild
    ## anything. If there is nothing to rebuild at all for this entry,
    ## we save some time by not loading the list of entries.
    my $map = MT::TemplateMap->load( $fi->templatemap_id );
    my $file = $pub->archive_file_for( $entry, $blog, $at, $cat, $map,
        undef, $author );
    if ( !defined($file) ) {
        die $blog->errstr();
    }
    $map->{__saved_output_file} = $file;

    my $ctx = MT::Template::Context->new;
    $ctx->{current_archive_type} = $at;
    if ( $start && $end ) {
        $ctx->{current_timestamp} = $start;
        $ctx->{current_timestamp_end} = $end;
    }

    my $arch_root =
      ( $at eq 'Page' ) ? $blog->site_path : $blog->archive_path;
    die 'You did not set your blog publishing path' unless $arch_root;

    my %cond;
    $pub->rebuild_file( $blog, $arch_root, $map, $at, $ctx, \%cond, 1,
        FileInfo => $fi, );
}

1;

# Local Variables:
# mode: perl
# coding: iso-8859-1
# tab-width: 4
# c-basic-offset: 4
# c-hanging-comment-ender-p: nil
# indent-tabs-mode: nil
# End:
